extends SceneTree
## Support script for test_live_logger.gd; it is NOT a test and is never run by the suite directly.
## Run by a child Godot process (--headless --path <project> -s res://core/automation/tests/support/live_logger_probe.gd):
## attaches ErrorCapture with OS.add_logger exactly as ScenarioRunner does, raises one real warning and
## one real error through the engine, then prints what the logger captured as JSON between markers and quits 0.
## Lives under core/automation/tests/, so it is excluded from the release preset (core/automation/*) and from
## the QA preset (core/automation/tests/*, core/*/tests/*); test_export_presets.gd guards both filters.
## No class_name (release builds may exclude core/automation).

const ErrorCapture := preload("res://core/automation/error_capture.gd")
const BEGIN := "LIVE_LOGGER_BEGIN"
const END := "LIVE_LOGGER_END"

var _done := false


func _process(_delta: float) -> bool:
	if _done:
		return true
	_done = true
	var logger := ErrorCapture.new()
	OS.add_logger(logger)
	push_warning("probe-warning")
	push_error("probe-error")
	OS.remove_logger(logger)
	var out := {"error_count": logger.error_count, "warning_count": logger.warning_count, "entries": logger.snapshot()}
	print(BEGIN)
	print(JSON.stringify(out))
	print(END)
	quit(0)
	return true
