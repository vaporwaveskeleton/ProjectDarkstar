extends GdUnitTestSuite
## Sector hand-off (TECH-001 §4.2a): a handed-in `session` seeds Composure and Charges at entry;
## Seam clear writes back only through a SeamReport (`end_seam`); a hull breach calls `die()`;
## the pause menu holds the clock; no `session` → a throwaway core that never saves.

const SCENE := "res://scenes/sector/sector_stub.tscn"
const STATS := preload("res://data/run/run_session.tres")
const SpySaver := preload("res://features/run/tests/run_spy_saver.gd")

var saver: SpySaver


func before_test() -> void:
	saver = SpySaver.new()


func after_test() -> void:
	get_tree().paused = false
	saver.free_service()


func _session_core() -> RunSessionCore:
	var core := RunSessionCore.new(STATS, saver)
	core.arrive_at_ruins({})
	core.start_run(5)
	return core


func test_injected_session_seeds_composure_and_charges() -> void:
	var core := _session_core()
	core.run().composure = 5.5
	core.run().charges = 3
	var params := core.enter_seam()
	var runner := scene_runner(SCENE)
	var sector: Node = runner.scene()
	sector.on_route_entered(params)
	assert_object(sector.session).is_same(core)
	assert_bool(sector.throwaway_session).is_false()
	assert_float(sector.composure).is_equal(5.5)
	assert_int(sector.charges).is_equal(3)


func test_new_run_keeps_the_sector_start_values() -> void:
	var core := _session_core()
	var runner := scene_runner(SCENE)
	var sector: Node = runner.scene()
	sector.on_route_entered(core.enter_seam())
	assert_float(sector.composure).is_equal(10.0)
	assert_int(sector.charges).is_equal(0)


func test_seam_clear_writes_back_through_the_report() -> void:
	var core := _session_core()
	core.run().charges = 2
	var runner := scene_runner(SCENE)
	var sector: Node = runner.scene()
	sector.on_route_entered(core.enter_seam())
	(sector.get_node("%Composure") as Composure).change(-3.0)
	saver.clear()
	assert_bool(sector.clear_seam()).is_true()
	assert_float(core.run().composure).is_equal(7.0)
	assert_int(core.run().charges).is_equal(2)
	assert_int(core.run().seam_index).is_equal(2)
	assert_int(core.run().ember_in_run).is_equal(40)
	assert_array(saver.slots_and_reasons()).is_equal(["run:seam_boundary"])


func test_run_state_does_not_change_mid_seam() -> void:
	var core := _session_core()
	var runner := scene_runner(SCENE)
	var sector: Node = runner.scene()
	sector.on_route_entered(core.enter_seam())
	(sector.get_node("%Composure") as Composure).change(-4.0)
	(sector.get_node("%ChargeMagazine") as ChargeMagazine).count = 4
	await runner.simulate_frames(5)
	assert_float(core.run().composure).is_less(0.0)
	assert_int(core.run().charges).is_equal(0)


func test_hull_breach_calls_die() -> void:
	var core := _session_core()
	var runner := scene_runner(SCENE)
	var sector: Node = runner.scene()
	sector.on_route_entered(core.enter_seam())
	saver.clear()
	(sector.vigil as Vigil).hull_breached.emit()
	assert_bool(core.run().is_active()).is_false()
	assert_float(core.loop_min_left()).is_equal(110.0)
	assert_array(saver.slots_and_reasons()).is_equal(["run:run_end", "iteration:run_end"])


## Records route requests instead of routing (Q-T247: no stray routed scene in the suite).
class FakeRouter:
	extends RefCounted
	var calls: Array = []

	func go_to(id: StringName, params: Dictionary = {}) -> bool:
		calls.append([String(id), params])
		return true


func _live_sector(runner: GdUnitSceneRunner, core: RunSessionCore, router: FakeRouter) -> Node:
	var sector: Node = runner.scene()
	sector.on_route_entered(core.enter_seam())
	sector.router = router
	(sector.vigil as Vigil).input.read_devices = false
	return sector


## Q-T276, Q-T278: at the slice frontier the throat banks the clear and returns to the Ruins.
func test_exit_throat_at_the_frontier_banks_and_returns_to_the_ruins() -> void:
	var core := _session_core()
	var router := FakeRouter.new()
	var runner := scene_runner(SCENE)
	var sector := _live_sector(runner, core, router)
	saver.clear()
	(sector.seam_exit as SeamExit).open()
	(sector.vigil as Vigil).global_position = (sector.exit_stats as SeamExitStats).throat_pos
	await runner.simulate_frames(3)
	assert_bool(sector.exit_taken).is_true()
	assert_bool(core.run().is_active()).is_false()
	assert_int(core.profile().ember_banked).is_equal(40)   # Seam clear; score 0 at the start
	assert_float(core.loop_min_left()).is_equal(120.0)      # no death lump, no refund
	assert_array(saver.slots_and_reasons()).is_equal(["run:run_end", "iteration:run_end"])
	assert_array(router.calls).is_equal([["ruins", {"run_outcome": "returned"}]])


func test_a_shut_throat_is_not_an_exit() -> void:
	var core := _session_core()
	var router := FakeRouter.new()
	var runner := scene_runner(SCENE)
	var sector := _live_sector(runner, core, router)
	(sector.vigil as Vigil).global_position = (sector.exit_stats as SeamExitStats).throat_pos
	await runner.simulate_frames(3)
	assert_bool(sector.seam_cleared).is_false()
	assert_bool(core.run().is_active()).is_true()
	assert_array(router.calls).is_empty()


## Q-T279: a breached hull returns to the Ruins after the hold (D-08 stays data).
func test_hull_breach_returns_to_the_ruins() -> void:
	var core := _session_core()
	var router := FakeRouter.new()
	var runner := scene_runner(SCENE)
	var sector := _live_sector(runner, core, router)
	var quick := (sector.exit_stats as SeamExitStats).duplicate() as SeamExitStats
	quick.return_hold_s = 0.0
	sector.exit_stats = quick
	(sector.vigil as Vigil).hull_breached.emit()
	assert_array(router.calls).is_empty()                  # the breach plays first
	await runner.simulate_frames(2)
	assert_array(router.calls).is_equal([["ruins", {"run_outcome": "died"}]])
	await runner.simulate_frames(2)
	assert_int(router.calls.size()).is_equal(1)


## Q-T277, Q-T279: Abandon Run mid-Seam is priced as a death and goes to the Ruins, not the title.
func test_abandon_run_goes_to_the_ruins_at_the_death_price() -> void:
	var core := _session_core()
	var router := FakeRouter.new()
	var runner := scene_runner(SCENE)
	var sector := _live_sector(runner, core, router)
	saver.clear()
	sector._on_abandon_requested()
	assert_bool(core.run().is_active()).is_false()
	assert_float(core.loop_min_left()).is_equal(110.0)
	assert_array(saver.slots_and_reasons()).is_equal(["run:run_end", "iteration:run_end"])
	assert_array(router.calls).is_equal([["ruins", {"run_outcome": "abandoned"}]])


func test_throwaway_exit_reports_in_memory_and_stays() -> void:
	var router := FakeRouter.new()
	var runner := scene_runner(SCENE)
	var sector: Node = runner.scene()
	sector.on_route_entered({})
	sector.router = router
	(sector.seam_exit as SeamExit).open()
	assert_bool(sector.take_exit()).is_true()
	assert_array(router.calls).is_empty()
	assert_array(saver.calls).is_empty()


func test_pause_menu_holds_the_clock_and_releases_it() -> void:
	var core := _session_core()
	var runner := scene_runner(SCENE)
	var sector: Node = runner.scene()
	sector.on_route_entered(core.enter_seam())
	sector.open_pause()
	assert_array(core.pause_reasons()).contains([RunSessionCore.PAUSE_MENU])
	(sector.get_node("%Overlays") as ScreenStack).pop()
	await runner.simulate_frames(2)
	assert_bool(core.is_clock_paused()).is_false()


func test_no_session_uses_a_throwaway_core_that_never_saves() -> void:
	var runner := scene_runner(SCENE)
	var sector: Node = runner.scene()
	sector.on_route_entered({})
	assert_bool(sector.throwaway_session).is_true()
	var core: RunSessionCore = sector.session
	assert_int(core.run().seam_index).is_equal(1)
	assert_int(core.run().seed_value).is_equal(STATS.dev_seed)
	assert_bool(sector.clear_seam()).is_true()
	(sector.vigil as Vigil).hull_breached.emit()
	assert_array(saver.calls).is_empty()
	assert_bool(core.iteration().started).is_false()
