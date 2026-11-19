extends GdUnitTestSuite
## RuinsOnboarding (LOOP-001 §10.5): the first Ruins visit as diegetic onboarding, beats 7–11.

const STATS := preload("res://data/interactions/ruins_onboarding.tres")
const STATIONS := {&"chalk_desk": 204.0, &"codex_desk": 300.0, &"tree": 392.0, &"hourglass": 438.0}
const LINES: Array[String] = ["You return.", "Stays.", "Counted: 9."]
## P-5 noun budget: no word on screen during the first visit may name these (LOOP-001 §10.5).
const NOT_YET: Array[String] = ["pact", "entropy", "thread", "composure", "sigil", "seam", "choir", "warp",
	"iteration", "lantern tree", "loop"]


func _first(paid := 60) -> RuinsOnboarding:
	var o := RuinsOnboarding.new(STATS)
	o.begin(true, paid, PackedStringArray(LINES), STATIONS, 484.0)
	return o


## Steps until `cond` holds (or `max_s` passes). Returns every event seen.
func _run(o: RuinsOnboarding, cond: Callable, axis := 0.0, max_s := 60.0) -> Array[StringName]:
	var seen: Array[StringName] = []
	var t := 0.0
	while not bool(cond.call()) and t < max_s:
		seen.append_array(o.step(1.0 / 60.0, axis))
		t += 1.0 / 60.0
	return seen


func _walk_to(o: RuinsOnboarding, x: float) -> Array[StringName]:
	o.walk_to(x)
	return _run(o, func() -> bool: return is_nan(o.walk_target), 0.0, 10.0)


func test_the_cold_open_has_no_movement_until_the_first_chalk_stroke() -> void:
	var o := _first()
	assert_str(String(o.phase)).is_equal("cold_open")
	o.step(STATS.chalk_start_s * 0.5, 1.0)
	assert_bool(o.can_move).is_false()
	assert_float(o.lamp_x).is_equal(STATS.lamp_start_x)
	var ev := _run(o, func() -> bool: return o.can_move)
	assert_bool(ev.has(RuinsOnboarding.EV_CHALK_STROKE)).is_true()
	assert_str(o.chalk_text(0)).is_not_empty()


func test_sable_writes_in_order_then_the_cabinet_pays_out() -> void:
	var o := _first()
	var ev := _run(o, func() -> bool: return o.phase == RuinsOnboarding.PHASE_PAYOUT)
	assert_bool(o.chalk_done()).is_true()
	for i in LINES.size():
		assert_str(o.chalk_text(i)).is_equal(LINES[i])
	assert_int(ev.count(RuinsOnboarding.EV_CHALK_LINE)).is_equal(LINES.size())
	assert_bool(ev.has(RuinsOnboarding.EV_PAYOUT)).is_true()
	assert_bool(o.tickets_landed).is_false()
	ev = _run(o, func() -> bool: return o.tickets_landed)
	assert_bool(ev.has(RuinsOnboarding.EV_TICKETS_LANDED)).is_true()
	assert_str(String(o.phase)).is_equal("free")


func test_any_press_finishes_the_line_being_written() -> void:
	var o := _first()
	_run(o, func() -> bool: return o.can_move)
	var ev := o.use()
	assert_bool(ev.has(RuinsOnboarding.EV_CHALK_LINE)).is_true()
	assert_str(o.chalk_text(0)).is_equal(LINES[0])
	assert_int(o.line_index).is_equal(1)


func test_the_tree_waits_for_its_tickets() -> void:
	var o := _first()
	_run(o, func() -> bool: return o.phase == RuinsOnboarding.PHASE_PAYOUT)
	_walk_to(o, 392.0)
	assert_bool(o.usable(RuinsOnboarding.TREE)).is_false()
	assert_bool(o.use().has(RuinsOnboarding.EV_TREE_LIT)).is_false()
	_run(o, func() -> bool: return o.tickets_landed)
	assert_str(String(o.focus())).is_equal("tree")
	assert_bool(o.use().has(RuinsOnboarding.EV_TREE_LIT)).is_true()
	assert_bool(o.gate_open()).is_true()


func test_the_dark_mouth_will_not_let_the_lamp_pass() -> void:
	var o := _first()
	_run(o, func() -> bool: return o.tickets_landed)
	var ev := _run(o, func() -> bool: return false, 1.0, 6.0)
	assert_float(o.lamp_x).is_equal(STATS.dark_threshold_x)
	assert_int(ev.count(RuinsOnboarding.EV_GUTTER)).is_equal(1)
	assert_bool(ev.has(RuinsOnboarding.EV_LAUNCH)).is_false()
	assert_str(String(o.phase)).is_equal("free")


func test_a_lit_tree_opens_the_mouth_and_walking_in_launches() -> void:
	var o := _first()
	_run(o, func() -> bool: return o.tickets_landed)
	_walk_to(o, 392.0)
	o.use()
	assert_bool(o.clock_held()).is_true()
	var ev := _run(o, func() -> bool: return o.phase == RuinsOnboarding.PHASE_LAUNCHED, 1.0, 10.0)
	assert_int(ev.count(RuinsOnboarding.EV_LAUNCH)).is_equal(1)
	assert_float(o.lamp_x).is_greater_equal(STATS.launch_x)
	assert_bool(o.clock_held()).is_false()


func test_the_codex_page_opens_and_closes_and_holds_the_lamp() -> void:
	var o := _first()
	_run(o, func() -> bool: return o.tickets_landed)
	_walk_to(o, 300.0)
	assert_bool(o.use().has(RuinsOnboarding.EV_CODEX_OPEN)).is_true()
	assert_bool(o.codex_read).is_true()
	var x := o.lamp_x
	o.step(0.5, 1.0)
	assert_float(o.lamp_x).is_equal(x)
	assert_str(String(o.focus())).is_equal("")
	assert_bool(o.use().has(RuinsOnboarding.EV_CODEX_CLOSED)).is_true()
	assert_bool(o.codex_open).is_false()


func test_a_visit_without_payout_goes_free_after_the_chalk() -> void:
	var o := _first(0)
	_run(o, func() -> bool: return o.chalk_done())
	o.step(0.02, 0.0)
	assert_str(String(o.phase)).is_equal("free")
	assert_bool(o.tickets_landed).is_true()


func test_a_later_visit_runs_the_clock_and_keeps_the_lamp_lit() -> void:
	var o := RuinsOnboarding.new(STATS)
	o.begin(false, 0, PackedStringArray(["You return."]), STATIONS, 484.0)
	assert_bool(o.can_move).is_true()
	assert_bool(o.gate_open()).is_true()
	assert_bool(o.clock_held()).is_false()
	var ev := _run(o, func() -> bool: return o.phase == RuinsOnboarding.PHASE_LAUNCHED, 1.0, 10.0)
	assert_bool(ev.has(RuinsOnboarding.EV_LAUNCH)).is_true()


func test_lamp_down_reveals_the_hidden_chalk() -> void:
	var o := _first()
	_run(o, func() -> bool: return o.can_move)
	o.toggle_lamp()
	var ev := _run(o, func() -> bool: return o.dark_revealed, 0.0, STATS.dark_reveal_s + 1.0)
	assert_bool(ev.has(RuinsOnboarding.EV_DARK_REVEAL)).is_true()
	o.toggle_lamp()
	o.step(0.1, 0.0)
	assert_float(o.dark_t).is_equal(0.0)


func test_each_station_is_reached_once() -> void:
	var o := _first(0)
	_run(o, func() -> bool: return o.can_move)
	var ev := _walk_to(o, 440.0)
	ev.append_array(_walk_to(o, 200.0))
	ev.append_array(_walk_to(o, 440.0))
	assert_int(ev.count(RuinsOnboarding.EV_REACHED)).is_equal(4)


## P-5: the first visit's on-screen words stay inside the noun budget (Ember, Codex; the Tree and the
## Hourglass are objects, never named on screen).
func test_first_visit_words_keep_the_noun_budget() -> void:
	var keys: Array[String] = ["NARR_SABLE_FIRST_1", "NARR_SABLE_FIRST_2", "NARR_SABLE_TALLY", "NARR_SABLE_TREE",
		"NARR_SABLE_GLASS", "NARR_SABLE_DARK_1", "NARR_CAB_SCORE_BANKED", "RUINS_TICKET_PLATE",
		"RUINS_CODEX_HEADER", "CX_PLACE_ACT0_3_TITLE", "CX_PLACE_ACT0_3_BODY"]
	for k: String in keys:
		var s := String(TranslationServer.translate(k)).to_lower()
		assert_str(s).override_failure_message("%s missing" % k).is_not_equal(k.to_lower())
		for word: String in NOT_YET:
			assert_bool(s.contains(word)).override_failure_message("%s names '%s'" % [k, word]).is_false()
	assert_str(String(TranslationServer.translate("RUINS_TICKET_PLATE"))).contains("EMBER")
	assert_str(String(TranslationServer.translate("RUINS_CODEX_HEADER"))).contains("CODEX")
