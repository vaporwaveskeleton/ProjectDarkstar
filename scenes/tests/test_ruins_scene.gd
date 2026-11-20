extends GdUnitTestSuite
## The Ruins scene (scenes/ruins/ruins.tscn): arrival through RunSession, the first-visit Hourglass
## hold (Q-T162), the dark-mouth gate and the walk-in launch (LOOP-001 §10.5).

const RUINS := "res://scenes/ruins/ruins.tscn"
const STATS := preload("res://data/run/run_session.tres")
const SpySaver := preload("res://features/run/tests/run_spy_saver.gd")
const TREE_X := 392.0
const CODEX_X := 300.0


class RouterSpy:
	extends RefCounted
	var calls: Array = []

	func go_to(id: StringName, params: Dictionary = {}) -> bool:
		calls.append([id, params])
		return true


var saver: SpySaver


func before_test() -> void:
	AudioService.muted_for_tests = true
	saver = SpySaver.new()


func after_test() -> void:
	AudioService.muted_for_tests = false
	saver.free_service()


func _ruins(core: RunSessionCore, router: RouterSpy, params: Dictionary) -> Node:
	var ruins: Node = (load(RUINS) as PackedScene).instantiate()
	ruins.set("session", core)
	ruins.set("router", router)
	add_child(ruins)
	auto_free(ruins)
	ruins.on_route_entered(params)
	await get_tree().process_frame   # the deferred arrival
	return ruins


## Drive the visit's rules frame by frame through the scene (as _process does).
func _drive(ruins: Node, axis: float, cond: Callable, max_s := 40.0) -> void:
	var ob: RuinsOnboarding = ruins.get("onboarding")
	var t := 0.0
	while not bool(cond.call()) and t < max_s:
		ruins.call("_react", ob.step(1.0 / 60.0, axis))
		t += 1.0 / 60.0


func test_first_visit_banks_act0_and_holds_the_sand() -> void:
	var core := RunSessionCore.new(STATS, saver)
	var ruins := await _ruins(core, RouterSpy.new(), {"act0_vigil_index": 12000, "first_visit": true})
	assert_int(int(ruins.get("paid_ember"))).is_equal(60)
	assert_bool(bool(ruins.get("first_visit"))).is_true()
	assert_bool(core.pause_reasons().has(RunSessionCore.PAUSE_FIRST_GLASS)).is_true()
	var full := core.loop_min_left()
	core.tick(30.0)
	assert_float(core.loop_min_left()).is_equal(full)


func test_a_bank_alone_marks_the_first_visit() -> void:
	var core := RunSessionCore.new(STATS, saver)
	var ruins := await _ruins(core, RouterSpy.new(), {"act0_vigil_index": 400})
	assert_bool(bool(ruins.get("first_visit"))).is_true()
	assert_bool(bool(ruins.get("clock_held"))).is_true()


func test_a_later_visit_lets_the_clock_run() -> void:
	var core := RunSessionCore.new(STATS, saver)
	core.arrive_at_ruins({"act0_vigil_index": 1200})
	core.buy_tree_node(preload("res://data/lantern_tree/tier1_stock.tres"))   # the first visit's lamp (Q-T191)
	var ruins := await _ruins(core, RouterSpy.new(), {})
	assert_bool(bool(ruins.get("first_visit"))).is_false()
	assert_bool(bool(ruins.get("clock_held"))).is_false()
	assert_bool(core.is_clock_paused()).is_false()
	assert_bool(bool(ruins.get("gate_open"))).is_true()


func test_the_walk_into_the_lit_mouth_launches_seam_one_and_starts_the_sand() -> void:
	var core := RunSessionCore.new(STATS, saver)
	var router := RouterSpy.new()
	var ruins := await _ruins(core, router, {"act0_vigil_index": 12000, "first_visit": true})
	var ob: RuinsOnboarding = ruins.get("onboarding")
	_drive(ruins, 0.0, func() -> bool: return ob.tickets_landed)
	assert_bool(bool(ruins.get("gate_open"))).is_false()
	_drive(ruins, 1.0, func() -> bool: return false, 4.0)
	assert_int(router.calls.size()).is_equal(0)                  # the dark stopped the lamp
	ob.walk_to(TREE_X)
	_drive(ruins, 0.0, func() -> bool: return is_nan(ob.walk_target))
	ruins.call("_react", ob.use())
	assert_bool(bool(ruins.get("gate_open"))).is_true()
	_drive(ruins, 1.0, func() -> bool: return bool(ruins.get("launched")))
	assert_int(router.calls.size()).is_equal(1)
	assert_str(String(router.calls[0][0])).is_equal("sector")
	assert_int(core.run().seam_index).is_equal(1)
	assert_bool(core.pause_reasons().has(RunSessionCore.PAUSE_FIRST_GLASS)).is_false()


func test_reading_the_codex_pauses_the_clock() -> void:
	var core := RunSessionCore.new(STATS, saver)
	core.arrive_at_ruins({})
	var ruins := await _ruins(core, RouterSpy.new(), {})
	var ob: RuinsOnboarding = ruins.get("onboarding")
	ob.walk_to(CODEX_X)
	_drive(ruins, 0.0, func() -> bool: return is_nan(ob.walk_target))
	ruins.call("_react", ob.use())
	assert_bool(bool(ruins.get("codex_open"))).is_true()
	assert_bool(core.pause_reasons().has(RunSessionCore.PAUSE_CODEX)).is_true()
	ruins.call("_react", ob.use())
	assert_bool(core.is_clock_paused()).is_false()


func test_leaving_releases_every_hold() -> void:
	var core := RunSessionCore.new(STATS, saver)
	var ruins := await _ruins(core, RouterSpy.new(), {"act0_vigil_index": 12000, "first_visit": true})
	remove_child(ruins)
	assert_bool(core.is_clock_paused()).is_false()


## Q-T190 (ruled): Esc opens the pause screen; the tree and the clock hold; leaving goes to the title.
func test_pause_holds_the_clock_and_can_leave_for_the_title() -> void:
	var core := RunSessionCore.new(STATS, saver)
	core.arrive_at_ruins({})
	var router := RouterSpy.new()
	var ruins := await _ruins(core, router, {})
	var pause: Screen = ruins.call("open_pause")
	assert_object(pause).is_not_null()
	assert_bool(get_tree().paused).is_true()
	assert_bool(core.pause_reasons().has(RunSessionCore.PAUSE_RUINS_MENU)).is_true()
	assert_object(ruins.call("open_pause")).is_null()          # one at a time
	pause.emit_signal(&"title_requested")
	assert_bool(get_tree().paused).is_false()
	assert_bool(core.pause_reasons().has(RunSessionCore.PAUSE_RUINS_MENU)).is_false()
	assert_str(String(router.calls[-1][0])).is_equal("attract")


func test_closing_the_pause_resumes() -> void:
	var core := RunSessionCore.new(STATS, saver)
	core.arrive_at_ruins({})
	var ruins := await _ruins(core, RouterSpy.new(), {})
	var pause: Screen = ruins.call("open_pause")
	pause.close()
	await get_tree().process_frame
	assert_bool(get_tree().paused).is_false()
	assert_bool(core.is_clock_paused()).is_false()


func test_the_tree_station_buys_the_next_node_with_each_use() -> void:
	var core := RunSessionCore.new(STATS, saver)
	var ruins := await _ruins(core, RouterSpy.new(), {"act0_vigil_index": 20_000, "first_visit": true})   # 100 Ember
	var ob: RuinsOnboarding = ruins.get("onboarding")
	_drive(ruins, 0.0, func() -> bool: return ob.tickets_landed)
	ob.walk_to(TREE_X)
	_drive(ruins, 0.0, func() -> bool: return is_nan(ob.walk_target))
	ruins.call("_react", ob.use())
	assert_bool(bool(ruins.get("gate_open"))).is_true()
	assert_int(core.profile().ember_banked).is_equal(60)
	assert_array(core.profile().tree_nodes).is_equal([&"LANTERN-1"])
	ruins.call("_react", ob.use())   # the station stays usable: the next node
	assert_array(core.profile().tree_nodes).is_equal([&"LANTERN-1", &"HULL-1"])
	assert_int(core.profile().ember_banked).is_equal(20)
	ruins.call("_react", ob.use())   # 20 Ember: nothing bought, the gate stays open
	assert_int(core.profile().tree_nodes.size()).is_equal(2)
	assert_bool(bool(ruins.get("gate_open"))).is_true()


func test_a_later_visit_lights_the_tree_from_the_bought_nodes() -> void:
	var core := RunSessionCore.new(STATS, saver)
	core.arrive_at_ruins({"act0_vigil_index": 20_000})
	core.buy_tree_node(preload("res://data/lantern_tree/tier1_stock.tres"))
	var ruins := await _ruins(core, RouterSpy.new(), {})
	assert_bool(bool(ruins.get("gate_open"))).is_true()


# --- the return chalk (NARR-001 §5.7a; Q-T284) ---------------------------------------------------

## A core that has finished one run (seed 4242) and is back at the Ruins with the lamp lit.
func _core_after_run(runs_before := 0) -> RunSessionCore:
	var core := RunSessionCore.new(STATS, saver)
	core.arrive_at_ruins({"act0_vigil_index": 1200})
	core.buy_tree_node(preload("res://data/lantern_tree/tier1_stock.tres"))
	core.start_run(4242)
	core.die()
	core.profile().extra["runs_ended"] = runs_before
	return core


func test_each_outcome_writes_a_line_from_its_pool() -> void:
	for outcome: StringName in RuinsReturnChalk.PREFIXES.keys():
		var ruins := await _ruins(_core_after_run(), RouterSpy.new(), {"run_outcome": String(outcome)})
		assert_str(String(ruins.get("return_outcome"))).is_equal(String(outcome))
		var key: StringName = ruins.call("return_chalk_key")
		assert_bool(RuinsReturnChalk.pool(outcome).has(key)).is_true()
		var ob: RuinsOnboarding = ruins.get("onboarding")
		assert_int(ob.lines.size()).is_equal(2)
		assert_str(ob.lines[1]).is_equal(tr(key))
		assert_str(ob.lines[1]).is_not_equal(String(key))   # translated, not the raw key
		_drive(ruins, 0.0, func() -> bool: return ob.line_index >= ob.lines.size())
		assert_str(ob.chalk_text(1)).is_equal(tr(key))      # written on the slate


func test_the_choice_is_deterministic_for_a_seed() -> void:
	var a := RuinsReturnChalk.key_for(&"died", 4242, 1)
	assert_str(String(RuinsReturnChalk.key_for(&"died", 4242, 1))).is_equal(String(a))
	var seen := {}
	for s in range(1, 60):
		seen[RuinsReturnChalk.key_for(&"abandoned", s, 1)] = true
	assert_int(seen.size()).is_equal(RuinsReturnChalk.POOL_SIZE)   # the whole pool is reachable
	var one := await _ruins(_core_after_run(), RouterSpy.new(), {"run_outcome": "died"})
	var two := await _ruins(_core_after_run(), RouterSpy.new(), {"run_outcome": "died"})
	assert_str(String(one.call("return_chalk_key"))).is_equal(String(two.call("return_chalk_key")))


func test_rare_lines_wait_for_several_runs() -> void:
	for s in range(1, 200):
		for outcome: StringName in RuinsReturnChalk.PREFIXES.keys():
			assert_bool(RuinsReturnChalk.pool(outcome).has(RuinsReturnChalk.key_for(outcome, s, 1))).is_true()
	var rare := 0
	for s in range(1, 200):
		if RuinsReturnChalk.rare_pool().has(RuinsReturnChalk.key_for(&"returned", s, 6)):
			rare += 1
	assert_int(rare).is_greater(0)
	assert_int(rare).is_less(100)


func test_won_and_no_outcome_keep_the_plain_line() -> void:
	var won := await _ruins(_core_after_run(), RouterSpy.new(), {"run_outcome": "won"})
	assert_int((won.get("onboarding") as RuinsOnboarding).lines.size()).is_equal(1)
	var plain := await _ruins(_core_after_run(), RouterSpy.new(), {})
	assert_int((plain.get("onboarding") as RuinsOnboarding).lines.size()).is_equal(1)


func test_a_run_end_records_its_seed_and_count() -> void:
	var core := _core_after_run()
	assert_int(core.last_run_seed).is_equal(4242)
	assert_int(core.runs_ended()).is_equal(0)   # the helper reset the count after the die()
	core.start_run(7)
	core.die()
	assert_int(core.runs_ended()).is_equal(1)


func test_every_return_chalk_key_has_a_line() -> void:
	var keys: Array[StringName] = RuinsReturnChalk.rare_pool()
	for o: StringName in RuinsReturnChalk.PREFIXES.keys():
		keys.append_array(RuinsReturnChalk.pool(o))
	assert_int(keys.size()).is_equal(20)
	for k in keys:
		assert_str(tr(k)).is_not_equal(String(k))
