extends GdUnitTestSuite
## The golden path (TECH-001 §2.1): THE PRETENCE → &"aether" (first Unmaking) → &"ruins" → &"sector"
## (PM-01 with the Aether far layer). Route ids only; the Ruins launch goes through RunSession
## (start_run, enter_seam, §4.2a). The full chain from a coin is the scenario a1_golden_path.

const RUINS := "res://scenes/ruins/ruins.tscn"
const SECTOR := "res://scenes/sector/sector_stub.tscn"
const STATS := preload("res://data/run/run_session.tres")
const SpySaver := preload("res://features/run/tests/run_spy_saver.gd")
const PM01_LOOK := "ds_aether.pm01_pale_marches_t1"


## Records go_to calls instead of routing.
class RouterSpy:
	extends RefCounted
	var calls: Array = []
	var accept := true

	func go_to(id: StringName, params: Dictionary = {}) -> bool:
		calls.append([id, params])
		return accept


var saver: SpySaver


func before_test() -> void:
	AudioService.muted_for_tests = true
	saver = SpySaver.new()


func after_test() -> void:
	AudioService.muted_for_tests = false
	get_tree().paused = false
	saver.free_service()


func _ruins(core: RunSessionCore, router: RouterSpy) -> Node:
	var ruins: Node = (load(RUINS) as PackedScene).instantiate()
	ruins.set("session", core)
	ruins.set("router", router)
	add_child(ruins)
	auto_free(ruins)
	return ruins


func test_every_route_of_the_chain_is_shipped() -> void:
	var table := load("res://data/routes/route_table.tres") as RouteTable
	for id: StringName in [&"cabinet", &"aether", &"ruins", &"sector"]:
		assert_bool(table.has_route(id)).override_failure_message("route %s" % id).is_true()


func test_the_ruins_bank_act0_then_launch_seam_one() -> void:
	var core := RunSessionCore.new(STATS, saver)
	var router := RouterSpy.new()
	var ruins := _ruins(core, router)
	ruins.on_route_entered({"act0_vigil_index": 4000, "shift_total": 4000, "first_visit": true})
	await get_tree().process_frame   # the deferred arrival
	assert_bool(core.profile().act0_banked).is_true()
	assert_int(core.profile().ember_banked).is_greater(0)
	assert_bool(ruins.launch()).is_true()
	assert_int(router.calls.size()).is_equal(1)
	assert_str(String(router.calls[0][0])).is_equal("sector")
	var params: Dictionary = router.calls[0][1]
	assert_object(params.get("session")).is_same(core)
	assert_int(int(params.get("seam_index"))).is_equal(1)
	assert_bool(core.run().is_active()).is_true()


func test_the_ruins_launch_only_once() -> void:
	var core := RunSessionCore.new(STATS, saver)
	var router := RouterSpy.new()
	var ruins := _ruins(core, router)
	assert_bool(ruins.launch()).is_true()
	assert_bool(ruins.launch()).is_false()
	assert_int(router.calls.size()).is_equal(1)


func test_a_live_run_is_re_entered_not_replaced() -> void:
	var core := RunSessionCore.new(STATS, saver)
	var run := core.start_run(7)
	var ruins := _ruins(core, RouterSpy.new())
	assert_bool(ruins.launch()).is_true()
	assert_object(core.run()).is_same(run)
	assert_int(core.run().seed_value).is_equal(7)


func test_a_refused_route_is_not_a_launch() -> void:
	var router := RouterSpy.new()
	router.accept = false
	var ruins := _ruins(RunSessionCore.new(STATS, saver), router)
	assert_bool(ruins.launch()).is_false()
	assert_bool(ruins.get("launched")).is_false()


func test_the_sector_shows_pm01_aether_behind_the_play_layer() -> void:
	var core := RunSessionCore.new(STATS, saver)
	core.arrive_at_ruins({})
	core.start_run(5)
	var runner := scene_runner(SECTOR)
	var sector: Node = runner.scene()
	assert_bool(sector.run_session).is_false()   # throwaway until the route hands a run in
	sector.on_route_entered(core.enter_seam())
	assert_bool(sector.run_session).is_true()
	assert_int(sector.seam_index).is_equal(1)
	assert_str(sector.far_look).is_equal(PM01_LOOK)
	var far := sector.get_node("Far") as CanvasLayer
	assert_int(far.layer).is_less(0)                          # behind the play layer
	assert_object(sector.find_child("Floor")).is_null()   # no M1 grid over the Aether (Q-T163)


func test_the_far_centre_is_continuous_across_a_rebase() -> void:
	var runner := scene_runner(SECTOR)
	var sector: Node = runner.scene()
	var cam := sector.get_node("%SectorCamera") as Camera2D
	var torus: Torus = sector.torus
	var start: Vector2 = sector.far_centre
	cam.global_position += Vector2(10, 0)
	sector._step_far()
	cam.global_position -= Vector2(torus.size.x, 0)   # a whole-field rebase: no travel
	sector._step_far()
	assert_vector(sector.far_centre).is_equal_approx(start + Vector2(10, 0), Vector2(0.01, 0.01))


func test_the_ruins_wear_ruins_look_and_open_cold_on_first_visit() -> void:
	var ruins := _ruins(RunSessionCore.new(STATS, saver), RouterSpy.new())
	var look: RuinsLook = ruins.get("look")
	assert_object(look).is_not_null()
	assert_bool(look.first_visit).is_false()                  # a later visit until the route says so
	assert_bool((ruins.get_node("%Aether") as CanvasItem).visible).is_false()
	ruins.on_route_entered({"first_visit": true})              # from the Unmaking (AetherArrival)
	assert_bool(look.first_visit).is_true()
	ruins.on_route_entered({"first_visit": "yes"})             # mistyped counts as false
	assert_bool(look.first_visit).is_false()
