extends GdUnitTestSuite
## SceneRouter `skip_curtain` on the real Boot host (TECH-001 §2.1, Q-T60): the curtain never shows,
## the old scene leaves and the new one arrives in the same frame, and RouteHost is never empty.
## The control proves the default route change still draws the curtain.

const BOOT := "res://scenes/boot/boot.tscn"
const ARRIVAL := "res://features/aether/aether_arrival.tscn"
const FRAME_GUARD := 300   ## ✱ frames to wait for a route change before failing

var _boot: Node
var _prev_backend: SaveBackend
var _prev_persist: bool
var _prev_reduced: bool


func before_test() -> void:
	_prev_backend = SaveService.backend
	_prev_persist = SettingsService.persist
	SettingsService.persist = false
	_prev_reduced = bool(SettingsService.get_value(&"reduced_motion"))
	SettingsService.set_value(&"reduced_motion", false)
	SaveService.set_backend(MemorySaveBackend.new())


func after_test() -> void:
	if is_instance_valid(_boot):
		_boot.free()
	_boot = null
	SceneRouter.is_busy = false
	get_tree().paused = false
	SettingsService.set_value(&"reduced_motion", _prev_reduced)
	SettingsService.persist = _prev_persist
	SaveService.set_backend(_prev_backend)


func test_skips_curtain_reads_only_a_bool_true() -> void:
	assert_bool(SceneRouter.skips_curtain({})).is_false()
	assert_bool(SceneRouter.skips_curtain({"skip_curtain": true})).is_true()
	assert_bool(SceneRouter.skips_curtain({&"skip_curtain": true})).is_true()
	assert_bool(SceneRouter.skips_curtain({"skip_curtain": false})).is_false()
	assert_bool(SceneRouter.skips_curtain({"skip_curtain": 1})).is_false()
	assert_bool(SceneRouter.skips_curtain({"skip_curtain": "true"})).is_false()


func test_skip_curtain_swaps_in_one_frame_without_the_curtain() -> void:
	await _boot_to_attract()
	var curtain := _boot.get_node("CurtainLayer/Curtain") as ColorRect
	var host := _boot.get_node("RouteHost")
	assert_float(curtain.color.a).is_equal(0.0)
	var exits: Array[int] = []
	var enters: Array[int] = []
	host.child_exiting_tree.connect(func(_n: Node) -> void: exits.append(Engine.get_process_frames()))
	host.child_entered_tree.connect(func(_n: Node) -> void: enters.append(Engine.get_process_frames()))
	assert_bool(SceneRouter.go_to(&"aether", {"skip_curtain": true, "aether_time_s": 3.0, "tier": 1,
		"camera_centre": Vector2(320, 180), "camera_zoom": 1.0})).is_true()
	var samples := await _sample_until_route(&"aether", curtain, host)
	var alphas: Array = samples[0]
	var fewest: int = samples[1]
	assert_array(alphas).is_not_empty()
	for a: Variant in alphas:
		assert_float(float(a)).override_failure_message("curtain showed during a skip_curtain change: %s" % [alphas]).is_equal(0.0)
	assert_int(exits.size()).is_equal(1)
	assert_int(enters.size()).is_equal(1)
	assert_int(enters[0]).is_equal(exits[0])
	assert_int(fewest).is_greater_equal(1)
	assert_str(host.get_child(0).scene_file_path).is_equal(ARRIVAL)
	assert_str(String(SceneRouter.current_route)).is_equal("aether")


func test_default_route_change_still_draws_the_curtain() -> void:
	await _boot_to_attract()
	var curtain := _boot.get_node("CurtainLayer/Curtain") as ColorRect
	var host := _boot.get_node("RouteHost")
	assert_bool(SceneRouter.go_to(&"aether")).is_true()
	var samples := await _sample_until_route(&"aether", curtain, host)
	var alphas: Array = samples[0]
	var peak := 0.0
	for a: Variant in alphas:
		peak = maxf(peak, float(a))
	assert_float(peak).is_greater(0.0)
	assert_float(curtain.color.a).is_equal(0.0)


func _boot_to_attract() -> void:
	_boot = (load(BOOT) as PackedScene).instantiate()
	add_child(_boot)
	await await_signal_on(SceneRouter, "route_changed", [&"attract"], 10000)


## Samples the curtain alpha and RouteHost child count every process frame until `route` lands.
## Returns [alphas, fewest children seen].
func _sample_until_route(route: StringName, curtain: ColorRect, host: Node) -> Array:
	var arrived := [false]
	var on_changed := func(id: StringName) -> void:
		if id == route:
			arrived[0] = true
	SceneRouter.route_changed.connect(on_changed)
	var alphas: Array = []
	var fewest := host.get_child_count()
	var frames := 0
	while not bool(arrived[0]) and frames < FRAME_GUARD:
		await get_tree().process_frame
		alphas.append(curtain.color.a)
		fewest = mini(fewest, host.get_child_count())
		frames += 1
	SceneRouter.route_changed.disconnect(on_changed)
	assert_bool(bool(arrived[0])).override_failure_message("route %s never landed" % route).is_true()
	return [alphas, fewest]
