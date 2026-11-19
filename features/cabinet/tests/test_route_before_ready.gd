extends GdUnitTestSuite
## A route host may call on_route_entered before the cabinet is in the tree (the tests' FakeRouteHost
## mounts and frees without adding it). The params must wait for _ready, never touch an @onready node
## that is not set yet (the null autopilot that made test_attract_mode flaky), and apply in the
## router's own order: stage 0 starts, then the params decide demo, continue or fresh.

const SCENE := preload("res://features/cabinet/cabinet_game.tscn")
const GAME_PATH := "res://features/cabinet/cabinet_game.tscn"

var game: CabinetGame


func before_test() -> void:
	AudioService.muted_for_tests = true
	SaveService.set_backend(MemorySaveBackend.new())
	game = SCENE.instantiate() as CabinetGame


func after_test() -> void:
	if is_instance_valid(game):
		game.free()
	AudioService.muted_for_tests = false
	SaveService.set_backend(FileSaveBackend.new())
	get_tree().paused = false


func _enter() -> void:
	add_child(game)
	game.set_process(false)
	(game.get_node("%World") as ArcadeWorld).paused_sim = true
	(game.get_node("%Messages") as CabinetMessages).set_process(false)


func test_demo_params_before_ready_wait_and_apply_on_ready() -> void:
	game.on_route_entered({"demo": true})
	assert_bool(game.demo).is_false()                 # nothing applied while the scene is not ready
	_enter()
	assert_bool(game.demo).is_true()
	assert_bool(game.autopilot.enabled).is_true()
	assert_bool(game.messages.demo).is_true()


func test_continue_params_before_ready_start_the_continued_stage() -> void:
	game.on_route_entered({"continue_stage": 2, "shift_total": 500})
	_enter()
	assert_bool(game.demo).is_false()
	assert_int(game.stage_index).is_equal(2)


func test_no_early_params_is_a_fresh_stage_zero() -> void:
	_enter()
	assert_bool(game.demo).is_false()
	assert_int(game.stage_index).is_equal(0)


func test_a_scene_freed_before_the_tree_takes_the_params_quietly() -> void:
	game.on_route_entered({"demo": true})
	game.free()
	assert_bool(is_instance_valid(game)).is_false()


## The flaky path itself: the attract screen routes the demo while the FakeRouteHost is installed.
func test_routing_the_demo_through_a_host_that_never_adds_the_scene() -> void:
	game.free()
	var host := FakeRouteHost.install(self)
	assert_bool(SceneRouter.go_to(&"cabinet", {"demo": true})).is_true()
	await await_millis(100)
	assert_array(host.mounted_routes).is_equal([GAME_PATH])
	assert_bool(SceneRouter.is_busy).is_false()
	FakeRouteHost.uninstall(host)
