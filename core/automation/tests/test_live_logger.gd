extends GdUnitTestSuite
## End-to-end proof that ErrorCapture really receives engine errors through OS.add_logger (the other
## suites only call _log_error directly). A child Godot process (same binary the suite runs under) runs
## support/live_logger_probe.gd, which raises a real push_warning and push_error and prints the captured
## entries between markers. Whatever the child's engine prints for those calls is the child's own output,
## not this suite's log. The child uses the player's normal user dir read-only (it writes nothing).

const PROBE := "res://core/automation/tests/support/live_logger_probe.gd"
const BEGIN := "LIVE_LOGGER_BEGIN"
const END := "LIVE_LOGGER_END"


func test_a_real_push_warning_and_push_error_are_captured_live() -> void:
	var exe := OS.get_executable_path()
	var looks_godot := exe.get_file().to_lower().contains("godot")
	assert_bool(looks_godot).override_failure_message(
		"cannot run the live logger probe: '%s' is not a Godot binary (run the suite with the Godot console/editor exe)" % exe).is_true()
	if not looks_godot:
		return
	var project := ProjectSettings.globalize_path("res://").trim_suffix("/")
	var out: Array = []
	var code := OS.execute(exe, ["--headless", "--path", project, "-s", PROBE], out, true)
	var text := "\n".join(PackedStringArray(out.map(func(x: Variant) -> String: return str(x))))
	assert_int(code).override_failure_message("child exited %d; output: %s" % [code, text.substr(0, 600)]).is_equal(0)
	var a := text.find(BEGIN)
	var b := text.find(END)
	assert_bool(a >= 0 and b > a).override_failure_message("markers missing; child output: %s" % text.substr(0, 600)).is_true()
	var json := text.substr(a + BEGIN.length(), b - a - BEGIN.length()).strip_edges()
	var parsed: Variant = JSON.parse_string(json)
	assert_bool(typeof(parsed) == TYPE_DICTIONARY).override_failure_message("not JSON: %s" % json.substr(0, 300)).is_true()
	var d: Dictionary = parsed
	assert_int(int(d.warning_count)).is_equal(1)
	assert_int(int(d.error_count)).is_equal(1)
	var entries: Array = d.entries
	assert_int(entries.size()).is_equal(2)
	var warn: Dictionary = entries.filter(func(e: Dictionary) -> bool: return e.type == "warning")[0]
	var err: Dictionary = entries.filter(func(e: Dictionary) -> bool: return e.type == "error")[0]
	assert_str(str(warn.message)).is_equal("probe-warning")
	assert_str(str(err.message)).is_equal("probe-error")
	# push_warning/push_error report the engine call site (variant_utility.cpp), not the GDScript line.
	assert_str(str(warn.file)).is_not_empty()
	assert_str(str(err.file)).is_not_empty()
	assert_int(int(warn.line)).is_greater(0)
	assert_int(int(err.line)).is_greater(0)
