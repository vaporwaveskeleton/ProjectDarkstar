extends GdUnitTestSuite
## Phase 2 runner features against the real cabinet probe: snapshot, wait_event, perf_sample, probe dev
## steps, error capture, profile refusal, caps.json. The cabinet scene is mounted under a fake RouteHost
## (no frame-driven sim: world.paused_sim), events are emitted straight from the world's signals.

const Runner := preload("res://core/automation/scenario_runner.gd")
const ErrorCapture := preload("res://core/automation/error_capture.gd")
const CapsWriter := preload("res://core/automation/caps_writer.gd")
const GAME := preload("res://features/cabinet/cabinet_game.tscn")
const OUT := "user://automation_test_p2/"
const ID_RE := "^[a-z0-9_]+(/[a-z0-9_*]+)+$"
const NAME_RE := "^[a-z0-9_]+$"

var _NOBT: Array[ScriptBacktrace] = []
var _boot: Node
var _host: Node
var _game: Node
var _world: ArcadeWorld
var _prev_backend: SaveBackend
var _prev_persist: bool
var _prev_route: StringName


func before_test() -> void:
	_prev_backend = SaveService.backend
	_prev_persist = SettingsService.persist
	_prev_route = SceneRouter.current_route
	AudioService.muted_for_tests = true
	SaveService.set_backend(MemorySaveBackend.new())
	_boot = Node.new()
	_host = Node.new()
	_host.name = "RouteHost"
	_boot.add_child(_host)
	_host.unique_name_in_owner = true
	_host.owner = _boot
	add_child(_boot)
	_game = GAME.instantiate()
	_host.add_child(_game)
	_game.set_process(false)
	_world = _game.get_node("%World")
	_world.paused_sim = true
	SceneRouter.current_route = &"cabinet"


func after_test() -> void:
	_boot.free()
	SceneRouter.current_route = _prev_route
	AudioService.muted_for_tests = false
	SaveService.set_backend(_prev_backend)
	SettingsService.persist = _prev_persist
	get_tree().paused = false


func _scenario(steps: Array, extra: Dictionary = {}) -> Dictionary:
	var d := {"format": "darkstar.scenario", "version": 1, "id": "t_p2", "timeout_frames": 300, "steps": steps}
	d.merge(extra, true)
	return d


func _start(sc: Dictionary, profile := "dev", wait := true) -> Node:
	var r: Node = Runner.new()
	r.setup(sc, {"out_dir": OUT + "t_p2", "quit_on_finish": false, "source": "cli", "profile": profile})
	_boot.add_child(r)
	if wait and not r.done:
		await await_signal_on(r, "scenario_finished", [], 20000)
	return r


func _frames(n: int) -> void:
	for _i in n:
		await get_tree().physics_frame


func test_snapshot_writes_a_file_and_records_the_path() -> void:
	var r := await _start(_scenario([{"do": "snapshot", "name": "first"}, {"do": "quit"}]))
	assert_str(r.result.outcome).is_equal("pass")
	assert_int(r.result.snapshots.size()).is_equal(1)
	var d: Variant = JSON.parse_string(FileAccess.get_file_as_string(OUT + "t_p2/snapshots/first.json"))
	assert_bool(d is Dictionary).is_true()
	var snap: Dictionary = d
	for k in ["frame", "route", "ui", "probe"]:
		assert_bool(snap.has(k)).override_failure_message(k).is_true()
	assert_str(snap.route).is_equal("cabinet")
	assert_str(snap.probe.route).is_equal("cabinet")
	assert_bool(snap.probe.has("vigil")).is_true()


func test_snapshot_is_capped_at_50_per_run() -> void:
	var steps: Array = []
	for i in 51:
		steps.append({"do": "snapshot", "name": "s%d" % i})
	var r := await _start(_scenario(steps))
	assert_str(r.result.outcome).is_equal("fail")
	assert_int(r.result.snapshots.size()).is_equal(50)
	assert_str(r.result.steps.back().detail).contains("snapshot limit")


func test_wait_event_passes_when_the_event_fires_after_the_step_starts() -> void:
	_world.vigil_destroyed.emit()   # before the run: must not count
	var r := await _start(_scenario([{"do": "wait_event", "event": "vigil_destroyed", "within": 60}, {"do": "quit"}]), "dev", false)
	await _frames(5)
	_world.vigil_destroyed.emit()
	await await_signal_on(r, "scenario_finished", [], 20000)
	assert_str(r.result.outcome).is_equal("pass")
	var ids: Array = r.result.events.map(func(e: Dictionary) -> String: return str(e.id))
	assert_array(ids).contains(["vigil_destroyed"])


func test_wait_event_count() -> void:
	var r := await _start(_scenario([{"do": "wait_event", "event": "charges_changed", "within": 60, "count": 2}]), "dev", false)
	await _frames(3)
	_world.charges_changed.emit(1)
	await _frames(3)
	_world.charges_changed.emit(2)
	await await_signal_on(r, "scenario_finished", [], 20000)
	assert_str(r.result.outcome).is_equal("pass")


func test_wait_event_failure_names_the_events_seen() -> void:
	var r := await _start(_scenario([{"do": "wait_event", "event": "entity_unmade", "within": 8}]), "dev", false)
	await _frames(3)
	_world.sepulchre_cleared.emit()
	await await_signal_on(r, "scenario_finished", [], 20000)
	assert_str(r.result.outcome).is_equal("fail")
	assert_str(r.result.steps[0].detail).contains("sepulchre_cleared x1")
	assert_str(r.result.steps[0].detail).contains("'entity_unmade' seen 0 of 1")


func test_wait_event_unknown_event_fails_plainly() -> void:
	var r := await _start(_scenario([{"do": "wait_event", "event": "nope", "within": 3}]))
	assert_str(r.result.outcome).is_equal("fail")
	assert_str(r.result.steps[0].detail).contains("unknown event 'nope'")


func test_probe_ids_work_through_the_runner() -> void:
	_world.start(_game.stages[0])
	var r := await _start(_scenario([
		{"do": "assert", "id": "cabinet/vigil", "prop": "alive", "eq": true},
		{"do": "assert", "id": "cabinet/acolyte/9999", "exists": false},
		{"do": "spawn", "kind": "acolyte", "dx": 0, "dy": -90},
		{"do": "assert", "id": "cabinet/world", "prop": "acolytes", "gte": 1},
		{"do": "assert", "id": "cabinet/vigil", "prop": "hp", "eq": 1}]))
	assert_str(r.result.outcome).is_equal("fail")
	assert_int(r.result.steps.size()).is_equal(5)
	assert_str(r.result.steps[4].detail).contains("not readable")


func test_events_are_recorded_for_all_runs_with_a_probe() -> void:
	var r := await _start(_scenario([{"do": "wait_frames", "frames": 10}]), "dev", false)
	await _frames(3)
	_world.score_awarded.emit(100, Vector2(1, 2))
	await await_signal_on(r, "scenario_finished", [], 20000)
	var e: Dictionary = r.result.events[0]
	assert_str(e.id).is_equal("score_awarded")
	assert_array(e.args).is_equal([100, 1.0, 2.0])
	assert_bool(e.frame is int).is_true()


func test_perf_sample_fields() -> void:
	var r := await _start(_scenario([{"do": "perf_sample"}, {"do": "perf_sample"}]))
	assert_int(r.result.perf.size()).is_equal(2)
	for k in ["frame", "fps", "process_ms", "physics_ms", "objects", "nodes", "orphan_nodes", "static_mem_mb"]:
		assert_bool((r.result.perf[0] as Dictionary).has(k)).override_failure_message(k).is_true()


func test_error_capture_records_errors_and_warnings() -> void:
	var cap := ErrorCapture.new()
	cap._log_error("fn", "res://x.gd", 7, "code", "boom " + "x".repeat(400), false, Logger.ERROR_TYPE_ERROR, _NOBT)
	cap._log_error("fn", "res://y.gd", 9, "code", "careful", false, Logger.ERROR_TYPE_WARNING, _NOBT)
	cap._log_error("fn", "res://z.gd", 3, "code", "script bug", false, Logger.ERROR_TYPE_SCRIPT, _NOBT)
	assert_int(cap.error_count).is_equal(2)
	assert_int(cap.warning_count).is_equal(1)
	var e: Array = cap.snapshot()
	assert_str(e[0].type).is_equal("error")
	assert_int(str(e[0].message).length()).is_equal(300)
	assert_str(e[1].type).is_equal("warning")
	assert_str(e[2].type).is_equal("script")
	assert_int(e[0].line).is_equal(7)
	assert_int(cap.blocking(["boom"]).size()).is_equal(1)   # the script error remains


func test_runner_reports_captured_errors_and_fails_on_them() -> void:
	var r := await _start(_scenario([{"do": "wait_frames", "frames": 10}, {"do": "quit"}], {"fail_on_errors": true}), "dev", false)
	await _frames(3)
	r._logger._log_error("f", "res://a.gd", 1, "c", "first problem", false, Logger.ERROR_TYPE_ERROR, _NOBT)
	r._logger._log_error("f", "res://a.gd", 2, "c", "just a warning", false, Logger.ERROR_TYPE_WARNING, _NOBT)
	await await_signal_on(r, "scenario_finished", [], 20000)
	assert_str(r.result.outcome).is_equal("fail")
	assert_int(r.result.exit_code).is_equal(1)
	assert_int(r.result.error_count).is_equal(1)
	assert_int(r.result.warning_count).is_equal(1)
	assert_int(r.result.errors.size()).is_equal(2)
	assert_str(r.result.steps.back().detail).contains("first problem")


func test_allow_errors_and_default_do_not_fail_the_run() -> void:
	var r := await _start(_scenario([{"do": "wait_frames", "frames": 10}], {"fail_on_errors": true, "allow_errors": ["expected noise"]}), "dev", false)
	await _frames(3)
	r._logger._log_error("f", "res://a.gd", 1, "c", "some expected noise here", false, Logger.ERROR_TYPE_ERROR, _NOBT)
	await await_signal_on(r, "scenario_finished", [], 20000)
	assert_str(r.result.outcome).is_equal("pass")
	assert_int(r.result.error_count).is_equal(1)
	var r2 := await _start(_scenario([{"do": "wait_frames", "frames": 10}]), "dev", false)
	await _frames(3)
	r2._logger._log_error("f", "res://a.gd", 1, "c", "ignored unless asked", false, Logger.ERROR_TYPE_ERROR, _NOBT)
	await await_signal_on(r2, "scenario_finished", [], 20000)
	assert_str(r2.result.outcome).is_equal("pass")


func test_logger_is_removed_at_finish() -> void:
	var r := await _start(_scenario([{"do": "quit"}]))
	assert_object(r.get("_logger")).is_null()
	assert_bool(r.result.has("errors")).is_true()


func test_qa_profile_refuses_every_new_dev_step_before_frame_zero() -> void:
	var steps := {
		"set_stage": {"index": 0}, "set_lives": {"lives": 1}, "teleport": {"x": 1, "y": 1},
		"spawn": {"kind": "geode", "dx": 1, "dy": 1}, "shoot_vigil": {"dx": 1, "dy": 1, "acolyte_id": "last"}, "kill_acolyte": {"acolyte_id": 1},
		"kill_all": {}, "pause_sim": {"on": true}, "step_sim": {"frames": 1},
		"wake_entity": {}, "place_entity": {"dx": 1, "dy": 1}}
	for n: String in steps.keys():
		var step: Dictionary = (steps[n] as Dictionary).duplicate()
		step["do"] = n
		var r := await _start(_scenario([step]), "qa")
		assert_str(r.result.outcome).override_failure_message(n).is_equal("refused")
		assert_int(r.result.exit_code).is_equal(3)
		assert_int(r.frames).is_equal(0)
		assert_str(r.result.steps[0].detail).contains(n)
		r.queue_free()


func test_qa_profile_still_allows_snapshot_and_perf() -> void:
	var r := await _start(_scenario([{"do": "snapshot", "name": "q"}, {"do": "perf_sample"}, {"do": "assert", "id": "cabinet/vigil", "prop": "alive", "eq": true}]), "qa")
	assert_str(r.result.outcome).is_equal("pass")


func test_probe_step_on_another_route_fails_plainly() -> void:
	SceneRouter.current_route = &"attract"
	var r := await _start(_scenario([{"do": "set_lives", "lives": 2}]))
	assert_str(r.result.outcome).is_equal("fail")
	assert_str(r.result.steps[0].detail).contains("needs route 'cabinet'")


func test_state_ids_without_a_probe_fail_plainly() -> void:
	SceneRouter.current_route = &"attract"
	var r := await _start(_scenario([{"do": "assert", "id": "cabinet/game", "prop": "state", "eq": "play"}]))
	assert_str(r.result.outcome).is_equal("fail")
	assert_str(r.result.steps[0].detail).contains("needs route 'cabinet'")
	var r2 := await _start(_scenario([{"do": "assert", "id": "attract/game", "prop": "state", "eq": "play"}]))
	assert_str(r2.result.steps[0].detail).contains("no probe is attached for route 'attract'")


func test_caps_json_has_the_documented_keys() -> void:
	var w: Node = CapsWriter.new()
	w.out_dir = OUT + "caps"
	w.quit_on_finish = false
	auto_free(w)
	var caps: Dictionary = w.write()
	var d: Variant = JSON.parse_string(FileAccess.get_file_as_string(OUT + "caps/caps.json"))
	assert_bool(d is Dictionary).is_true()
	for k in ["format", "version", "protocol", "profile", "steps", "comparators", "screenshot_targets", "probes", "fixtures", "build"]:
		assert_bool((d as Dictionary).has(k)).override_failure_message(k).is_true()
	assert_str(caps.format).is_equal("darkstar.caps")
	assert_str(caps.profile).is_equal(Runner.build_profile())
	assert_bool(caps.probes.has("cabinet")).is_true()
	assert_array(caps.fixtures).contains(["profile_fresh"])
	var names: Array = caps.steps.map(func(s: Dictionary) -> String: return str(s.name))
	assert_array(names).contains(["snapshot", "wait_event", "perf_sample", "step_sim"])
	for k in ["godot", "game_version"]:
		assert_bool((caps.build as Dictionary).has(k)).is_true()


func test_every_catalog_and_probe_id_is_lower_snake_with_slashes() -> void:
	var id_re := RegEx.create_from_string(ID_RE)
	var name_re := RegEx.create_from_string(NAME_RE)
	var caps := CapsWriter.build()
	for route: Variant in caps.probes.keys():
		for id: String in (caps.probes[route] as Dictionary).ids:
			assert_bool(id_re.search(id) != null).override_failure_message(id).is_true()
		for ev: String in (caps.probes[route] as Dictionary).events:
			assert_bool(name_re.search(ev) != null).override_failure_message(ev).is_true()
	for s: Dictionary in caps.steps:
		assert_bool(name_re.search(str(s.name)) != null).override_failure_message(str(s.name)).is_true()
