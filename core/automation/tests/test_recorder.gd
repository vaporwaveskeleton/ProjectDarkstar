extends GdUnitTestSuite
## Recorder under a fake Boot with in-memory saves. Never quits the engine: the file is written by
## an explicit stop_and_write().

const Recorder := preload("res://core/automation/recorder.gd")
const Runner := preload("res://core/automation/scenario_runner.gd")
const Schema := preload("res://core/automation/scenario_schema.gd")
const InputDriver := preload("res://core/automation/input_driver.gd")
const OUT := "user://automation_test/rec"

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


func _frames(n: int) -> void:
	for _i in n:
		await get_tree().physics_frame


func _recorder(profile := "dev", refusal := "") -> Node:
	var r: Node = Recorder.new()
	r.setup("t_rec", OUT, PackedStringArray(["--record=t_rec", "--out=x", "--autopilot"]), refusal, profile)
	_boot.add_child(r)
	return r


func test_refuses_outside_dev_profile() -> void:
	var r := _recorder("qa")
	await _frames(3)
	assert_bool(r.recording).is_false()
	assert_str(r.stop_and_write()).is_empty()


func test_refuses_without_memory_backend() -> void:
	SaveService.set_backend(FileSaveBackend.new())
	var r := _recorder()
	await _frames(3)
	assert_bool(r.recording).is_false()


func test_gate_refusal_records_nothing() -> void:
	var r := _recorder("dev", "bad id")
	await _frames(3)
	assert_bool(r.recording).is_false()


func test_recorded_session_validates_and_replays_on_the_same_frames() -> void:
	var r := _recorder()
	await _frames(2)
	var drv := InputDriver.new()
	drv.press(&"move_right")
	await _frames(5)
	drv.press(&"fire_lance")
	await _frames(3)
	drv.release(&"move_right")
	await _frames(4)
	drv.release(&"fire_lance")
	await _frames(2)
	var path: String = r.stop_and_write()
	assert_str(path).is_not_empty()
	var sc: Variant = JSON.parse_string(FileAccess.get_file_as_string(path))
	assert_bool(sc is Dictionary).is_true()
	var scenario: Dictionary = sc
	assert_array(Schema.validate(scenario, false)).is_empty()
	assert_array(scenario.args).contains_exactly(["--autopilot"])
	assert_str(scenario.profile).is_equal("dev")
	# Frame offset of every press/release in the recording, relative to its first event.
	var rec_offsets := _offsets(scenario.steps)
	assert_int(rec_offsets.size()).is_equal(4)
	# Replay it: the runner presses the same actions; sample Input every frame to see when.
	var replay: Dictionary = scenario.duplicate(true)
	assert_str(replay.steps[0].do).is_equal("wait_route")
	(replay.steps as Array).remove_at(0)   # the fake Boot has no routes
	var runner: Node = Runner.new()
	runner.setup(replay, {"out_dir": OUT + "/replay", "quit_on_finish": false, "source": "cli", "profile": "dev"})
	_boot.add_child(runner)
	var seen := {}
	var base := -1
	var f := 0
	while not runner.done and f < 400:
		await get_tree().physics_frame
		f += 1
		for a: StringName in [&"move_right", &"fire_lance"]:
			var now := Input.is_action_pressed(a)
			if now != bool(seen.get(a, false)):
				seen[a] = now
				if base < 0:
					base = f
				var key := "%s%s" % ["press " if now else "release ", a]
				seen[key] = f - base
	for k in rec_offsets.keys():
		assert_bool(seen.has(k)).override_failure_message("replay never did '%s'" % k).is_true()
		assert_int(absi(int(seen[k]) - int(rec_offsets[k]))).override_failure_message("%s: replay %s vs recorded %s" % [k, seen[k], rec_offsets[k]]).is_less_equal(2)
	assert_str(runner.result.outcome).is_equal("pass")


## "press move_right" -> frames after the first recorded event (wait_route consumes none).
func _offsets(steps: Array) -> Dictionary:
	var out := {}
	var t := 0
	var first := true
	for s: Dictionary in steps:
		match s.do:
			"wait_frames":
				t += int(s.frames)
			"press", "release":
				if first:
					t = 0
					first = false
				out["%s %s" % [s.do, s.action]] = t
	return out
