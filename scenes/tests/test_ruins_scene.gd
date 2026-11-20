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
	get_tree().paused = false
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
	ruins.call("_react", ob.use())   # the first visit: no menu, the suggested lamp lights (noun budget)
	assert_bool(bool(ruins.get("tree_open"))).is_false()
	assert_array(core.profile().tree_nodes).is_equal([&"LANTERN-1"])
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
	# The Codex record (Q-T350): the page is stamped on arrival and now read; reading saves nothing.
	assert_bool(core.codex_known().has(CodexRecord.ACT0_PAGE)).is_true()
	assert_array(core.profile().codex_read).is_equal([CodexRecord.ACT0_PAGE])
	assert_bool(saver.calls.all(func(c: Dictionary) -> bool: return c.reason in [&"ruins_entry", &"tree_purchase"])).is_true()
	ruins.call("_react", ob.use())
	assert_bool(core.is_clock_paused()).is_false()


## Q-T353: after the Chronicle's third run the Ruins arrival stamps the tier-1 gating entries, and the
## Tree screen it opens shows the four gated lamps as buyable.
func test_after_run_three_the_tree_screen_sells_the_gated_lamps() -> void:
	var core := RunSessionCore.new(STATS, saver)
	core.arrive_at_ruins({"act0_vigil_index": 1200})
	core.buy_tree_node(preload("res://data/lantern_tree/tier1_stock.tres"))
	for i in STATS.codex_backstop_tier1_runs:
		core.start_run(3)
		core.enter_seam()
		core.die()
	var ruins := await _ruins(core, RouterSpy.new(), {})
	assert_bool(core.codex_known().has(&"cx_rule_gaze")).is_true()
	var screen: LanternTreeScreen = ruins.call("open_tree")
	assert_object(screen).is_not_null()
	await get_tree().process_frame
	for id: StringName in [&"LANTERN-4", &"WARD-1", &"MADNESS-2", &"MADNESS-3"]:
		assert_str(String(screen.state_of(id))).is_equal(String(LanternTreeRules.BUYABLE))


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


## Q-T326: on a later visit, using the Tree opens the station screen (the clock holds, `ruins_menu`);
## each confirmed lamp is bought through RunSessionCore (one `tree_purchase` write), and the screen
## is shown the new Ember. Closing the screen lets the clock run again.
func test_a_later_visit_opens_the_tree_and_buys_the_chosen_lamps() -> void:
	var core := RunSessionCore.new(STATS, saver)
	core.arrive_at_ruins({"act0_vigil_index": 20_000})   # 100 Ember banked on an earlier visit
	var ruins := await _ruins(core, RouterSpy.new(), {})
	var ob: RuinsOnboarding = ruins.get("onboarding")
	assert_bool(ob.first_visit).is_false()
	_drive(ruins, 0.0, func() -> bool: return ob.tickets_landed)
	ob.walk_to(TREE_X)
	_drive(ruins, 0.0, func() -> bool: return is_nan(ob.walk_target))
	ruins.call("_react", ob.use())
	assert_bool(bool(ruins.get("tree_open"))).is_true()
	assert_array(core.profile().tree_nodes).is_empty()   # opening buys nothing
	assert_bool(core.pause_reasons().has(RunSessionCore.PAUSE_RUINS_MENU)).is_true()
	var screen: LanternTreeScreen = ruins.call("_tree_screen")
	saver.calls.clear()
	screen.purchase_confirmed.emit(&"HULL-4")   # any tier-1 lamp, not only the old sale order
	assert_bool(bool(ruins.get("gate_open"))).is_true()
	assert_int(core.profile().ember_banked).is_equal(60)
	assert_array(core.profile().tree_nodes).is_equal([&"HULL-4"])
	assert_array(saver.slots_and_reasons()).is_equal(["profile:tree_purchase"])
	assert_str((screen.find_child("Ember", true, false) as VectorLabel).shown_text()).is_equal("60 EMBER")
	screen.purchase_confirmed.emit(&"LANTERN-5")   # a dark tier-2 lamp: refused, nothing spent
	screen.purchase_confirmed.emit(&"HULL-1")
	assert_array(core.profile().tree_nodes).is_equal([&"HULL-4", &"HULL-1"])
	assert_int(core.profile().ember_banked).is_equal(20)
	screen.purchase_confirmed.emit(&"HULL-3")      # 20 Ember: nothing bought
	assert_int(core.profile().tree_nodes.size()).is_equal(2)
	screen.close()
	assert_bool(bool(ruins.get("tree_open"))).is_false()
	assert_bool(core.pause_reasons().has(RunSessionCore.PAUSE_RUINS_MENU)).is_false()
	assert_bool(get_tree().paused).is_false()
	assert_bool(bool(ruins.get("gate_open"))).is_true()


func test_a_later_visit_lights_the_tree_from_the_bought_nodes() -> void:
	var core := RunSessionCore.new(STATS, saver)
	core.arrive_at_ruins({"act0_vigil_index": 20_000})
	core.buy_tree_node(preload("res://data/lantern_tree/tier1_stock.tres"))
	var ruins := await _ruins(core, RouterSpy.new(), {})
	assert_bool(bool(ruins.get("gate_open"))).is_true()
