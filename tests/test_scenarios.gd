extends GdUnitTestSuite
## Runs every suite-eligible tests/scenarios/*.scenario.json inside GdUnit, on the real Boot scene
## with an in-memory SaveService. Asserts the outcome only, never frame counts.
## Scenarios that are not valid for the suite (args, long timeout) are skipped with a message.

const Schema := preload("res://core/automation/scenario_schema.gd")
const Runner := preload("res://core/automation/scenario_runner.gd")
const DIR := "res://tests/scenarios/"
const REAL_TIME_LIMIT_MS := 90000   ## ✱ generous real-time guard; the run itself is frame-counted

var _prev_backend: SaveBackend
var _prev_persist: bool
var _boot: Node


func before_test() -> void:
	_prev_backend = SaveService.backend
	_prev_persist = SettingsService.persist


func after_test() -> void:
	if is_instance_valid(_boot):
		_boot.free()
	get_tree().paused = false
	SaveService.set_backend(_prev_backend)
	SettingsService.persist = _prev_persist


## One test case per suite-eligible scenario (TECH-001 §9.1): each case gets its own GdUnit timeout,
## so the sum of all scenarios can no longer hit the 5 min per-case limit (it had reached 4 min 59 s).
## Scenarios that are not suite-eligible (args, long timeout) are left to the CLI runner.
static func suite_scenarios() -> Array:
	var out: Array = []
	for f in DirAccess.get_files_at(DIR):
		if not f.ends_with(".scenario.json"):
			continue
		var parsed: Variant = JSON.parse_string(FileAccess.get_file_as_string(DIR + f))
		if typeof(parsed) == TYPE_DICTIONARY and Schema.validate(parsed as Dictionary, true).is_empty():
			out.append([f])
	return out


func test_scenario_passes(file: String, test_parameters := suite_scenarios()) -> void:
	var sc: Dictionary = JSON.parse_string(FileAccess.get_file_as_string(DIR + file))
	await _play(file, sc)


func test_the_suite_has_scenarios() -> void:
	assert_int(suite_scenarios().size()).is_greater(20)


func _play(file: String, sc: Dictionary) -> void:
	SaveService.set_backend(MemorySaveBackend.new())
	var runner: Node = Runner.new()
	runner.setup(sc, {"out_dir": "user://automation_suite/" + str(sc.id), "quit_on_finish": false, "source": "suite"})
	_boot = (load("res://scenes/boot/boot.tscn") as PackedScene).instantiate()
	_boot.set("automation_runner", runner)
	add_child(_boot)
	if not runner.get("done"):
		await await_signal_on(runner, "scenario_finished", [], REAL_TIME_LIMIT_MS)
	var res: Dictionary = runner.get("result")
	var bad: Array = (res.get("steps", []) as Array).filter(func(s: Dictionary) -> bool: return s.outcome != "pass")
	assert_str(str(res.get("outcome"))).override_failure_message("%s: %s" % [file, JSON.stringify(bad)]).is_equal("pass")
	_boot.free()
	_boot = null
	get_tree().paused = false
