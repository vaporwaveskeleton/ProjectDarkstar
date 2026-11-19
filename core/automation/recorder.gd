extends Node
## Scenario recorder (`-- --record=<id>`, dev profile only; D-09: in-process, no sockets).
## Child of Boot. Samples input once per physics frame and writes <out>/<id>.scenario.json when it
## leaves the tree (quit) so the session can be replayed by the scenario runner.
## No class_name: release builds may exclude core/automation.
##
## Limits: only InputMap actions, the three mouse buttons and mouse motion are captured (raw
## keyboard keys that no action uses are not). Replay is faithful only with the same stage seed,
## the same saves state and `--fixed-fps 60`; the recorder does not verify determinism.

const Schema := preload("res://core/automation/scenario_schema.gd")
const Runner := preload("res://core/automation/scenario_runner.gd")

const EXTRA_FRAMES := 600   ## ✱ headroom added to the recorded length for timeout_frames
const START_WAIT := 240     ## ✱ within-frames for the opening wait_route
const BUTTONS := {MOUSE_BUTTON_LEFT: "left", MOUSE_BUTTON_RIGHT: "right", MOUSE_BUTTON_MIDDLE: "middle"}

var recording := false
var frames := 0
var steps: Array = []

var _id := ""
var _out := ""
var _args := PackedStringArray()
var _profile := ""
var _held: Dictionary = {}       ## action -> bool (last sampled)
var _buttons: Dictionary = {}    ## mouse button -> bool
var _mouse := Vector2.ZERO
var _last_event_tick := 0
var _start_route := ""
var _written := false
var _capped := false
var _started := false


## `refusal` is a failure decided by the gate (bad id / bad --out). `profile` is injectable for tests.
func setup(id: String, out_dir: String, args: PackedStringArray, refusal: String, profile: String = "") -> void:
	_id = id
	_out = out_dir
	_args = args
	_profile = profile if profile != "" else Runner.build_profile()
	if refusal != "":
		print("automation: recorder refused: %s" % refusal)
		_out = ""


func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	set_physics_process(false)
	if _out == "":
		return
	if _profile != "dev":
		print("automation: recording is available in the dev profile only")
		return
	if not SaveService.backend is MemorySaveBackend:
		print("automation: recording needs in-memory saves (pass --no-save)")
		return
	for a in InputMap.get_actions():
		_held[a] = Input.is_action_pressed(a)
	for b: Variant in BUTTONS.keys():
		_buttons[b] = Input.is_mouse_button_pressed(b as MouseButton)
	_mouse = _logical_mouse()
	var route := str(SceneRouter.current_route)
	if route == "" and SceneRouter.table != null:
		route = str(SceneRouter.table.initial_route)
	_start_route = route
	if route != "":
		steps.append({"do": "wait_route", "route": route, "within": START_WAIT})
	recording = true
	_started = true
	set_physics_process(true)
	print("automation: recording '%s' to %s" % [_id, _out])


func _exit_tree() -> void:
	stop_and_write()


func _logical_mouse() -> Vector2:
	return get_viewport().get_mouse_position() if is_inside_tree() else Vector2.ZERO


func _physics_process(_delta: float) -> void:
	if not recording:
		return
	frames += 1
	var events: Array = []
	var actions := InputMap.get_actions()
	actions.sort()
	for a in actions:
		var now := Input.is_action_pressed(a)
		if now != bool(_held.get(a, false)):
			_held[a] = now
			events.append({"do": "press" if now else "release", "action": str(a)})
	var pos := _logical_mouse()
	if not pos.is_equal_approx(_mouse):
		_mouse = pos
		events.append({"do": "mouse_move", "x": snappedf(pos.x, 0.1), "y": snappedf(pos.y, 0.1)})
	for b: Variant in BUTTONS.keys():
		var now := Input.is_mouse_button_pressed(b as MouseButton)
		if now != bool(_buttons.get(b, false)):
			_buttons[b] = now
			events.append({"do": "mouse_button", "button": BUTTONS[b], "pressed": now})
	if events.is_empty():
		return
	if steps.size() + events.size() + 2 > Schema.MAX_STEPS:
		_capped = true
		recording = false
		set_physics_process(false)
		print("automation: recording stopped, the scenario step limit (%d) was reached" % Schema.MAX_STEPS)
		return
	var gap := frames - _last_event_tick
	if gap > 0:
		steps.append({"do": "wait_frames", "frames": mini(gap, Schema.MAX_WAIT)})
	_last_event_tick = frames
	steps.append_array(events)


## Builds the scenario dictionary from what was recorded so far.
func build_scenario() -> Dictionary:
	var out_steps := steps.duplicate(true)
	var trailing := frames - _last_event_tick
	if not _capped and trailing > 0:
		out_steps.append({"do": "wait_frames", "frames": mini(trailing, Schema.MAX_WAIT)})
	out_steps.append({"do": "quit"})
	var user_args: Array = []
	for a in _args:
		if not (a.begins_with("--record=") or a.begins_with("--out=")):
			user_args.append(a)
	return {
		"format": Schema.FORMAT, "version": Schema.VERSION, "id": _id, "profile": "dev",
		"args": user_args, "fixtures": {},
		"timeout_frames": mini(frames + EXTRA_FRAMES, Schema.MAX_TIMEOUT_FRAMES),
		"steps": out_steps,
	}


## Writes <out>/<id>.scenario.json once. Returns the path, or "" when nothing was recorded.
func stop_and_write() -> String:
	if _written or not _started:
		return ""
	_written = true
	recording = false
	set_physics_process(false)
	DirAccess.make_dir_recursive_absolute(_out)
	var path := _out.path_join(_id + ".scenario.json")
	var f := FileAccess.open(path, FileAccess.WRITE)
	if f == null:
		print("automation: could not write %s" % path)
		return ""
	f.store_string(JSON.stringify(build_scenario(), "\t"))
	f.close()
	print("automation: recorded %d steps over %d frames to %s" % [steps.size(), frames, path])
	return path
