extends GdUnitTestSuite
## ScenarioRunner under a minimal fake Boot (a node with a %RouteHost child), in-memory saves.
## quit_on_finish is always false here: a test must never quit the engine.

const Runner := preload("res://core/automation/scenario_runner.gd")
const OUT := "user://automation_test/"

var _boot: Node
var _prev_backend: SaveBackend
var _prev_persist: bool


func before_test() -> void:
	_prev_backend = SaveService.backend
	_prev_persist = SettingsService.persist
	SaveService.set_backend(MemorySaveBackend.new())
	_boot = Node.new()
	var host := Node.new()
	host.name = "RouteHost"
	_boot.add_child(host)
	host.unique_name_in_owner = true
	host.owner = _boot
	add_child(_boot)


func after_test() -> void:
	_boot.free()
	SaveService.set_backend(_prev_backend)
	SettingsService.persist = _prev_persist


func _scenario(steps: Array, timeout := 200, extra: Dictionary = {}) -> Dictionary:
	var d := {"format": "darkstar.scenario", "version": 1, "id": "t_run", "timeout_frames": timeout, "steps": steps}
	d.merge(extra, true)
	return d


func _start(sc: Dictionary, wait := true) -> Node:
	var r: Node = Runner.new()
	r.setup(sc, {"out_dir": OUT + "t_run", "quit_on_finish": false, "source": "cli"})
	_boot.add_child(r)
	if wait:
		await _until_done(r)
	return r


func _until_done(r: Node) -> void:
	if not r.done:
		await await_signal_on(r, "scenario_finished", [], 20000)


func _frames(n: int) -> void:
	for _i in n:
		await get_tree().physics_frame


func test_pass_path_stops_at_quit() -> void:
	var r := await _start(_scenario([
		{"do": "wait_frames", "frames": 3}, {"do": "checkpoint", "name": "mid"}, {"do": "quit"},
		{"do": "wait_frames", "frames": 150}]))
	assert_str(r.result.outcome).is_equal("pass")
	assert_int(r.result.exit_code).is_equal(0)
	assert_int(r.result.steps.size()).is_equal(3)
	assert_int(r.result.checkpoints.size()).is_equal(1)
	assert_int(r.frames).is_equal(3)


func test_step_failure_records_detail_and_stops() -> void:
	var r := await _start(_scenario([
		{"do": "assert", "id": "cabinet/game", "prop": "state", "eq": "play"}, {"do": "quit"}]))
	assert_str(r.result.outcome).is_equal("fail")
	assert_int(r.result.exit_code).is_equal(1)
	assert_int(r.result.steps.size()).is_equal(1)
	assert_str(r.result.steps[0].outcome).is_equal("fail")
	assert_str(r.result.steps[0].detail).contains("no route is mounted")


func test_wait_until_expiry_reports_last_value() -> void:
	var r := await _start(_scenario([
		{"do": "wait_until", "id": "cabinet/game", "prop": "state", "eq": "play", "within": 3}]))
	assert_str(r.result.outcome).is_equal("fail")
	assert_str(r.result.steps[0].detail).contains("last value")
	assert_str(r.result.steps[0].detail).contains("within 3 frames")


func test_global_timeout() -> void:
	var r := await _start(_scenario([{"do": "wait_frames", "frames": 100}], 5))
	assert_str(r.result.outcome).is_equal("timeout")
	assert_int(r.result.exit_code).is_equal(1)
	assert_int(r.frames).is_less(10)


func test_invalid_scenario_runs_nothing() -> void:
	var r := await _start({"format": "darkstar.scenario"})
	assert_str(r.result.outcome).is_equal("invalid")
	assert_int(r.result.exit_code).is_equal(2)
	assert_int(r.frames).is_equal(0)


func test_refused_without_memory_backend() -> void:
	SaveService.set_backend(FileSaveBackend.new())
	var r := await _start(_scenario([{"do": "quit"}]))
	assert_str(r.result.outcome).is_equal("refused")
	assert_int(r.result.exit_code).is_equal(3)


func test_result_json_is_written_with_documented_keys() -> void:
	await _start(_scenario([{"do": "wait_frames", "frames": 2}]))
	var d: Variant = JSON.parse_string(FileAccess.get_file_as_string(OUT + "t_run/result.json"))
	assert_bool(d is Dictionary).is_true()
	var res: Dictionary = d
	for k in ["format", "version", "scenario", "source", "build", "outcome", "exit_code", "frames", "steps", "checkpoints", "screenshots"]:
		assert_bool(res.has(k)).override_failure_message("result.json lacks " + k).is_true()
	assert_str(res.format).is_equal("darkstar.result")
	for k in ["godot", "game_version", "features", "headless"]:
		assert_bool((res.build as Dictionary).has(k)).is_true()


func test_held_input_is_released_on_failure() -> void:
	var r := await _start(_scenario([
		{"do": "press", "action": "move_right"}, {"do": "wait_frames", "frames": 3},
		{"do": "assert", "id": "x/ui/y", "prop": "visible", "eq": true}]))
	assert_str(r.result.outcome).is_equal("fail")
	assert_bool(r.input.is_idle()).is_true()
	await _frames(4)
	assert_bool(Input.is_action_pressed(&"move_right")).is_false()


func test_held_input_is_released_on_quit() -> void:
	var r := await _start(_scenario([{"do": "press", "action": "move_right"}, {"do": "wait_frames", "frames": 3}, {"do": "quit"}]))
	assert_str(r.result.outcome).is_equal("pass")
	assert_bool(r.input.is_idle()).is_true()
	await _frames(4)
	assert_bool(Input.is_action_pressed(&"move_right")).is_false()


func test_held_input_is_released_on_exit_tree() -> void:
	var r := await _start(_scenario([{"do": "press", "action": "move_right"}, {"do": "wait_frames", "frames": 150}]), false)
	await _frames(5)
	assert_bool(Input.is_action_pressed(&"move_right")).is_true()
	var drv: RefCounted = r.input
	_boot.remove_child(r)   # fires _exit_tree
	assert_bool(drv.is_idle()).is_true()
	await _frames(4)
	assert_bool(Input.is_action_pressed(&"move_right")).is_false()
	r.free()


func test_held_input_is_released_on_route_change() -> void:
	var r := await _start(_scenario([{"do": "press", "action": "move_right"}, {"do": "wait_frames", "frames": 150}]), false)
	await _frames(5)
	assert_bool(r.input.is_idle()).is_false()
	SceneRouter.route_changed.emit(&"elsewhere")
	assert_bool(r.input.is_idle()).is_true()
	await _frames(4)
	assert_bool(Input.is_action_pressed(&"move_right")).is_false()
	_boot.remove_child(r)
	await _frames(2)   # the aborted run unwinds
	r.free()


func test_settings_are_reset_and_not_persisted() -> void:
	SettingsService.persist = false
	SettingsService.set_value(&"reduced_motion", true)
	SettingsService.persist = true
	await _start(_scenario([{"do": "quit"}]))
	assert_bool(SettingsService.persist).is_false()
	assert_bool(bool(SettingsService.get_value(&"reduced_motion"))).is_false()


func test_fixture_is_readable_through_save_service() -> void:
	var r := await _start(_scenario([{"do": "quit"}], 200, {"fixtures": {"profile": "profile_fresh"}}))
	assert_str(r.result.outcome).is_equal("pass")
	var loaded := SaveService.load_slot(&"profile")
	assert_bool(loaded.ok).is_true()
	assert_int(int(loaded.payload.cabinet_hi_score)).is_equal(1234)


func test_bad_fixture_names_are_invalid() -> void:
	var r := await _start(_scenario([{"do": "quit"}], 200, {"fixtures": {"profile": "../evil"}}))
	assert_str(r.result.outcome).is_equal("invalid")
	var r2 := await _start(_scenario([{"do": "quit"}], 200, {"fixtures": {"profile": "no_such_fixture"}}))
	assert_str(r2.result.outcome).is_equal("invalid")
	assert_int(r2.result.exit_code).is_equal(2)


func _start_with(sc: Dictionary, profile: String) -> Node:
	var r: Node = Runner.new()
	r.setup(sc, {"out_dir": OUT + "t_run", "quit_on_finish": false, "source": "cli", "profile": profile})
	_boot.add_child(r)
	await _until_done(r)
	return r


func test_qa_profile_refuses_dev_steps_before_frame_zero() -> void:
	var r := await _start_with(_scenario([{"do": "set_setting", "key": "reduced_motion", "value": true}, {"do": "quit"}]), "qa")
	assert_str(r.result.outcome).is_equal("refused")
	assert_int(r.result.exit_code).is_equal(3)
	assert_int(r.frames).is_equal(0)
	assert_str(r.result.steps[0].detail).contains("set_setting")
	assert_bool(bool(SettingsService.get_value(&"reduced_motion"))).is_false()


func test_dev_profile_allows_set_setting_and_unknown_keys_fail() -> void:
	var r := await _start_with(_scenario([{"do": "set_setting", "key": "reduced_motion", "value": true}, {"do": "quit"}]), "dev")
	assert_str(r.result.outcome).is_equal("pass")
	assert_str(r.result.profile).is_equal("dev")
	assert_bool(bool(SettingsService.get_value(&"reduced_motion"))).is_true()
	assert_bool(SettingsService.persist).is_false()
	var r2 := await _start_with(_scenario([{"do": "set_setting", "key": "volume", "value": 1}]), "dev")
	assert_str(r2.result.outcome).is_equal("fail")
	assert_str(r2.result.steps[0].detail).contains("unknown setting")
	SettingsService.reset_to_defaults()


func test_qa_scenario_on_dev_build_is_held_to_qa() -> void:
	var r := await _start_with(_scenario([{"do": "set_setting", "key": "reduced_motion", "value": true}], 200, {"profile": "qa"}), "dev")
	assert_str(r.result.outcome).is_equal("refused")
	assert_str(r.result.build.profile).is_equal("dev")


func test_dev_scenario_on_qa_build_is_refused() -> void:
	var r := await _start_with(_scenario([{"do": "quit"}], 200, {"profile": "dev"}), "qa")
	assert_str(r.result.outcome).is_equal("refused")
	assert_int(r.result.exit_code).is_equal(3)


func test_qa_refuses_unapproved_fixture_and_accepts_approved() -> void:
	var ok := await _start_with(_scenario([{"do": "quit"}], 200, {"fixtures": {"profile": "profile_fresh"}}), "qa")
	assert_str(ok.result.outcome).is_equal("pass")
	assert_str(ok.result.profile).is_equal("qa")
	var bad := await _start_with(_scenario([{"do": "quit"}], 200, {"fixtures": {"profile": "no_such_fixture"}}), "qa")
	assert_str(bad.result.outcome).is_equal("refused")
	assert_int(bad.result.exit_code).is_equal(3)
	assert_str(bad.result.steps[0].detail).contains("not approved")
	var dev := await _start_with(_scenario([{"do": "quit"}], 200, {"fixtures": {"profile": "no_such_fixture"}}), "dev")
	assert_str(dev.result.outcome).is_equal("invalid")


func test_reset_clears_memory_saves_and_settings() -> void:
	SaveService.save_slot(&"profile", {"cabinet_hi_score": 5}, &"cabinet_score")
	assert_bool(SaveService.has_slot(&"profile")).is_true()
	SettingsService.persist = false
	SettingsService.set_value(&"reduced_motion", true)
	# No route table host here, so the wait for attract fails; clearing has already happened.
	var r := await _start_with(_scenario([{"do": "reset"}], 400), "dev")
	assert_bool(SaveService.has_slot(&"profile")).is_false()
	assert_bool(bool(SettingsService.get_value(&"reduced_motion"))).is_false()
	assert_bool(r.input.is_idle()).is_true()
