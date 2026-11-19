extends Logger
## Captures engine errors and warnings (push_error, push_warning, script and shader errors) for the
## scenario runner (OS.add_logger). Thread-safe: Godot may call a Logger from any thread.
## Keeps a capped list plus exact totals. No class_name: release builds may exclude core/automation.

const MAX_ENTRIES := 200   ## ✱ entries kept per run
const MAX_MESSAGE := 300   ## ✱ characters kept per message

var entries: Array[Dictionary] = []
var error_count := 0
var warning_count := 0
var _mutex := Mutex.new()


func _log_error(function: String, file: String, line: int, code: String, rationale: String, _editor_notify: bool, error_type: int, _script_backtraces: Array[ScriptBacktrace]) -> void:
	var kind := "error"
	match error_type:
		ERROR_TYPE_WARNING:
			kind = "warning"
		ERROR_TYPE_SCRIPT:
			kind = "script"
		ERROR_TYPE_SHADER:
			kind = "shader"
	var msg := rationale if rationale != "" else code
	if msg == "":
		msg = function
	_mutex.lock()
	if kind == "warning":
		warning_count += 1
	else:
		error_count += 1
	if entries.size() < MAX_ENTRIES:
		entries.append({"type": kind, "message": msg.substr(0, MAX_MESSAGE), "file": file, "line": line})
	_mutex.unlock()


## A copy of the captured entries (safe to read while the logger is still attached).
func snapshot() -> Array:
	_mutex.lock()
	var out: Array = entries.duplicate(true)
	_mutex.unlock()
	return out


## Entries of an error kind (not warnings) whose message contains none of `allowed`.
func blocking(allowed: Array) -> Array:
	return snapshot().filter(func(e: Dictionary) -> bool:
		if e.type == "warning":
			return false
		for a: Variant in allowed:
			if str(e.message).contains(str(a)):
				return false
		return true)
