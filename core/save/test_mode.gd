class_name TestMode
extends RefCounted
## Keeps test runs away from the player's real user:// files. Inert in release builds.
## Test mode = debug build AND (env DARKSTAR_TEST_MODE=1 OR a "gdunit" command-line arg).
## In test mode settings and saves live under user://_test, wiped once per process.

const ROOT := "user://_test"
const REAL_SETTINGS := "user://settings.cfg"
const REAL_SAVES := "user://saves"

static var _cached: int = -1   # -1 unknown, 0 off, 1 on
static var blocked_writes: Array[String] = []


static func decide(debug_build: bool, env: String, args: PackedStringArray) -> bool:
	if not debug_build:
		return false
	if env == "1":
		return true
	for a in args:
		if a.to_lower().contains("gdunit"):
			return true
	return false


static func active() -> bool:
	if _cached < 0:
		var args := PackedStringArray(OS.get_cmdline_args())
		args.append_array(OS.get_cmdline_user_args())
		force(decide(OS.is_debug_build(), OS.get_environment("DARKSTAR_TEST_MODE"), args))
	return _cached == 1


## Override detection (other runners, tests). Entering test mode wipes user://_test once.
static func force(on: bool) -> void:
	var was_on: bool = _cached == 1
	_cached = 1 if on else 0
	if on and not was_on:
		_wipe(ProjectSettings.globalize_path(ROOT))


static func settings_path() -> String:
	return ROOT + "/settings.cfg" if active() else REAL_SETTINGS


static func saves_root() -> String:
	return ROOT + "/saves" if active() else REAL_SAVES


## Write guard for the REAL player files. Silent unless it refuses: in test mode a write to the
## real settings.cfg or anything under the real saves folder is recorded and refused.
static func allow_write(path: String) -> bool:
	if not active():
		return true
	var p: String = _abs(path)
	var real_cfg: String = _abs(REAL_SETTINGS)
	var real_saves: String = _abs(REAL_SAVES)
	if p == real_cfg or p == real_saves or p.begins_with(real_saves + "/"):
		blocked_writes.append(path)
		return false
	return true


static func _abs(path: String) -> String:
	return ProjectSettings.globalize_path(path).simplify_path()


static func _wipe(abs_dir: String) -> void:
	var d := DirAccess.open(abs_dir)
	if d == null:
		return
	for sub in d.get_directories():
		_wipe(abs_dir.path_join(sub))
		DirAccess.remove_absolute(abs_dir.path_join(sub))
	for f in d.get_files():
		DirAccess.remove_absolute(abs_dir.path_join(f))
