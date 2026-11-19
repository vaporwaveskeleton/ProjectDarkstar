extends Node
## In-process scenario interpreter (dev/QA builds only; D-09: no sockets, no HTTP).
## Child of Boot. Plays tests/scenarios/<id>.scenario.json with real input, frame-counted waits and
## assertions, then writes result.json (+ screenshots) and quits with an exit code:
##   0 pass, 1 fail/timeout, 2 invalid, 3 refused.
## All waiting is physics frames; there is no wall-clock time anywhere in here.
## No class_name: release builds may exclude core/automation.
##
## Probe contract. Game knowledge lives in one probe per route, loaded by path from PROBES only if the
## script exists (release builds exclude it, so they simply have none). A probe is a RefCounted with
## no class_name and these duck-typed methods:
##   setup(route_root: Node)                       called when the route is mounted
##   describe() -> {ids, props, events, dev_ops}   for caps.json
##   has(id: String) -> bool                       does the entity exist right now
##   read(id, prop) -> {ok, value, error}          allow-listed scalar props only
##   snapshot() -> Dictionary                      scalars; lists capped by the probe
##   dev_op(op: String, args: Dictionary) -> String   "" on success, else a plain failure message
##   event_names() -> PackedStringArray; connect_events(sink: Callable); disconnect_events()
##                                                 sink(event_id: String, args: Array), scalars only
## Catalog steps with "probe_op": true are dispatched to dev_op (the catalog "route" must be current).

signal scenario_finished(outcome: StringName)

const Schema := preload("res://core/automation/scenario_schema.gd")
const InputDriver := preload("res://core/automation/input_driver.gd")
const UiView := preload("res://core/automation/ui_view.gd")
const Capture := preload("res://core/automation/capture.gd")
const ErrorCapture := preload("res://core/automation/error_capture.gd")

## route id -> probe script (loaded only if present in the build)
const PROBES := {"cabinet": "res://features/cabinet/automation/cabinet_probe.gd"}

const FIXTURE_DIR := "res://tests/fixtures/saves/"
const APPROVED_FIXTURES := "res://tests/fixtures/saves/approved.json"
const RESET_ROUTE_FRAMES := 240  ## ✱ the reset step waits this long for attract
const MAX_DETAIL := 300        ## ✱ characters kept per step detail
const COIN_PEEL_FRAMES := 300  ## ✱ give up peeling the tape after this many frames
const COIN_STEP_FRAMES := 240  ## ✱ per phase of the coin sequence
const MAX_SNAPSHOTS := 50        ## ✱ snapshot steps per run
const MAX_EVENTS := 256          ## ✱ events kept in result.events
const MAX_PERF := 200            ## ✱ perf samples kept
const FEATURE_TAGS: Array[String] = ["editor", "automation_dev", "automation_qa"]

var done := false
var result: Dictionary = {}
var frames := 0
var input := InputDriver.new()

var _scenario: Dictionary = {}
var _opts: Dictionary = {}
var _view: UiView
var _step_log: Array = []
var _checkpoints: Array = []
var _shots: Array = []
var _preset: Dictionary = {}   ## a failure decided before _ready (by the gate)
var _timed_out := false
var _detail := ""
var _profile := ""   ## effective profile this run is held to ("dev" or "qa")
var _probe: RefCounted
var _probe_route := ""
var _probe_root: Node
var _events: Array = []
var _event_counts: Dictionary = {}
var _snapshots: Array = []
var _perf: Array = []
var _logger: ErrorCapture
var _detail_do := "preflight"


## The build's profile: "dev" in the editor or an automation_dev build, "qa" in an automation_qa
## build, "" otherwise. Single resolution point; tests inject opts.profile instead.
static func build_profile() -> String:
	if OS.has_feature("editor") or OS.has_feature("automation_dev"):
		return "dev"
	return "qa" if OS.has_feature("automation_qa") else ""


func setup(scenario: Dictionary, opts: Dictionary) -> void:
	_scenario = scenario
	_opts = opts


## The gate uses this for a scenario it cannot even hand over (bad id, missing file, refused path).
func preset_failure(outcome: StringName, code: int, detail: String, opts: Dictionary) -> void:
	_opts = opts
	_preset = {"outcome": outcome, "code": code, "detail": detail}


func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	_view = UiView.new(get_parent().get_node_or_null("%RouteHost") if get_parent() != null else null)
	SceneRouter.route_changed.connect(_on_route_changed)
	if not _preset.is_empty():
		_finish(int(_preset.code), StringName(_preset.outcome), str(_preset.detail))
		return
	var errs := Schema.validate(_scenario, str(_opts.get("source", "")) == "suite")
	if not errs.is_empty():
		_finish(2, &"invalid", "; ".join(errs))
		return
	var refusal := _profile_refusal()
	if refusal != "":
		_finish(3, &"refused", refusal)
		return
	if not SaveService.backend is MemorySaveBackend:
		_finish(3, &"refused", "SaveService is not using an in-memory backend (pass --no-save)")
		return
	SettingsService.persist = false
	SettingsService.reset_to_defaults()
	_logger = ErrorCapture.new()
	OS.add_logger(_logger)
	_current_probe()
	var fx := _write_fixtures()
	if fx != "":
		_finish(3 if fx.begins_with("fixture not approved") else 2, &"refused" if fx.begins_with("fixture not approved") else &"invalid", fx)
		return
	_run.call_deferred()


## Resolves the effective profile (a scenario can only ask for less) and returns a refusal text,
## or "" when the scenario may run. Dev steps are checked here, before frame 0.
func _profile_refusal() -> String:
	var build := str(_opts.get("profile", build_profile()))
	var asked := str(_scenario.get("profile", build))
	if build == "":
		return "this build has no automation profile"
	if asked == "dev" and build != "dev":
		return "scenario asks for the dev profile but this build is '%s'" % build
	_profile = "qa" if (asked == "qa" or build == "qa") else "dev"
	if _profile == "qa":
		var dev := Schema.dev_steps_used(_scenario)
		if not dev.is_empty():
			return "dev-only steps are not allowed in the qa profile: %s" % ", ".join(dev)
	return ""


func _exit_tree() -> void:
	input.release_all()
	_detach_probe()
	_remove_logger()
	if SceneRouter.route_changed.is_connected(_on_route_changed):
		SceneRouter.route_changed.disconnect(_on_route_changed)
	done = true


func _on_route_changed(_route: StringName) -> void:
	input.release_all()
	_current_probe()


## The probe for the current route (attached on demand; replaced when the route or its root changes).
func _current_probe() -> RefCounted:
	var route := str(SceneRouter.current_route)
	var root: Node = _view.route_root() if _view != null else null
	if _probe != null and _probe_route == route and _probe_root == root:
		return _probe
	_detach_probe()
	if root == null or not PROBES.has(route) or not ResourceLoader.exists(str(PROBES[route])):
		return null
	var script := load(str(PROBES[route])) as GDScript
	if script == null:
		return null
	_probe = script.new() as RefCounted
	_probe_route = route
	_probe_root = root
	_probe.setup(root)
	_probe.connect_events(_on_probe_event)
	return _probe


func _detach_probe() -> void:
	if _probe != null:
		_probe.disconnect_events()
	_probe = null
	_probe_route = ""
	_probe_root = null


func _on_probe_event(event_id: String, args: Array) -> void:
	_event_counts[event_id] = int(_event_counts.get(event_id, 0)) + 1
	_events.append({"frame": frames, "id": event_id, "args": args})
	if _events.size() > MAX_EVENTS:
		_events.remove_at(0)


func _remove_logger() -> void:
	if _logger != null:
		OS.remove_logger(_logger)
		_logger = null


func _write_fixtures() -> String:
	var fixtures: Dictionary = _scenario.get("fixtures", {})
	if _profile == "qa" and not fixtures.is_empty():
		var approved: Variant = JSON.parse_string(FileAccess.get_file_as_string(APPROVED_FIXTURES)) if FileAccess.file_exists(APPROVED_FIXTURES) else null
		var names: Array = approved as Array if typeof(approved) == TYPE_ARRAY else []
		for slot: Variant in fixtures.keys():
			if not names.has(str(fixtures[slot])):
				return "fixture not approved for QA: '%s'" % fixtures[slot]
	for slot: Variant in fixtures.keys():
		var path := FIXTURE_DIR + str(fixtures[slot]) + ".json"
		if not SaveService.is_known_slot(StringName(str(slot))) or not FileAccess.file_exists(path):
			return "fixture '%s' for slot '%s' not found" % [fixtures[slot], slot]
		var parsed: Variant = JSON.parse_string(FileAccess.get_file_as_string(path))
		if typeof(parsed) != TYPE_DICTIONARY:
			return "fixture '%s' is not a JSON object" % fixtures[slot]
		var env := SaveEnvelope.create(str(slot), parsed as Dictionary)
		SaveService.backend.write_text(str(slot), env.to_json())
	return ""


func _run() -> void:
	var steps: Array = _scenario.steps
	for i in steps.size():
		var step: Dictionary = steps[i]
		var rec := {"i": i, "do": step.do, "outcome": "pass", "frame_start": frames, "frame_end": frames, "detail": ""}
		_detail = ""
		var failed: bool = not await _exec(step)
		if done:
			return
		rec.frame_end = frames
		if failed:
			rec.outcome = "fail"
			rec.detail = _detail.substr(0, MAX_DETAIL)
			_step_log.append(rec)
			_finish(1, &"timeout" if _timed_out else &"fail", "")
			return
		_step_log.append(rec)
		if step.do == "quit":
			break
	_finish(0, &"pass", "")


## One physics frame. False means stop the step: the run ended, or the global frame budget ran out.
func _tick() -> bool:
	await get_tree().physics_frame
	if done:
		return false
	frames += 1
	if frames > int(_scenario.timeout_frames):
		_timed_out = true
		_detail = "global timeout_frames (%d) exceeded" % int(_scenario.timeout_frames)
		return false
	return true


func _wait(n: int) -> bool:
	for _i in n:
		if not await _tick():
			return false
	return true


func _fail(msg: String) -> bool:
	_detail = msg
	return false


## Polls `probe` (returns {ok, text}) every frame for up to `within` frames.
func _wait_for(probe: Callable, within: int) -> bool:
	var last := ""
	for _i in within + 1:
		var r: Dictionary = probe.call()
		last = str(r.text)
		if r.ok:
			return true
		if _i == within or not await _tick():
			break
	if not _timed_out and not done:
		_detail = "not met within %d frames; last value: %s" % [within, last]
	return false


func _exec(step: Dictionary) -> bool:
	match str(step.do):
		"wait_frames":
			return await _wait(int(step.frames))
		"wait_route":
			var want := StringName(str(step.route))
			return await _wait_for(func() -> Dictionary:
				return {"ok": SceneRouter.current_route == want and not SceneRouter.is_busy,
					"text": "route=%s busy=%s" % [SceneRouter.current_route, SceneRouter.is_busy]}, int(step.within))
		"wait_until":
			return await _wait_for(func() -> Dictionary: return _check(step), int(step.within))
		"assert":
			if step.has("exists"):
				var found := _exists(str(step.id))
				return true if found == bool(step.exists) else _fail("'%s' exists=%s, expected %s" % [step.id, found, step.exists])
			var p := _check(step)
			return true if p.ok else _fail("assert failed; last value: %s" % p.text)
		"checkpoint":
			_checkpoints.append({"name": step.name, "frame": frames})
			return true
		"quit":
			return true
		"screenshot":
			return await _screenshot(step)
		"coin":
			return await _coin()
		"activate":
			return await _activate(str(step.id))
		"focus":
			var c := _control(str(step.id))
			if c == null:
				return false
			c.grab_focus()
			return true if c.has_focus() else _fail("'%s' did not take focus" % step.id)
		"cancel":
			return await _tap(&"ui_cancel")
		"goto":
			return true if SceneRouter.go_to(StringName(str(step.route))) else _fail("go_to('%s') was refused" % step.route)
		"autopilot":
			return _autopilot(bool(step.on))
		"press":
			input.press(StringName(str(step.action)))
			return true
		"release":
			input.release(StringName(str(step.action)))
			return true
		"hold":
			return await _tap(StringName(str(step.action)), int(step.frames))
		"key":
			var code: int = OS.find_keycode_from_string(str(step.keycode))
			input.key_press(code)
			var ok := await _wait(InputDriver.clamp_frames(int(step.frames)))
			input.key_release(code)
			return ok
		"mouse_move":
			input.mouse_move(Vector2(float(step.x), float(step.y)))
			return true
		"reset":
			return await _reset()
		"set_setting":
			return _set_setting(str(step.key), step.value)
		"snapshot":
			return _snapshot(str(step.name))
		"perf_sample":
			return _perf_sample()
		"wait_event":
			return await _wait_event(step)
		"mouse_button":
			input.mouse_button({"left": MOUSE_BUTTON_LEFT, "right": MOUSE_BUTTON_RIGHT, "middle": MOUSE_BUTTON_MIDDLE}[str(step.button)], bool(step.pressed))
			return true
	var def: Variant = (Schema.catalog().get("steps", {}) as Dictionary).get(str(step.do))
	if typeof(def) == TYPE_DICTIONARY and bool((def as Dictionary).get("probe_op", false)):
		return _probe_op(step, def as Dictionary)
	return _fail("step '%s' is not implemented" % step.do)


## A catalog step with "probe_op": true is run by the current route's probe.
func _probe_op(step: Dictionary, def: Dictionary) -> bool:
	if _profile == "qa" and bool(def.get("dev", false)):
		return _fail("step '%s' is dev-only" % step.do)
	var need := str(def.get("route", ""))
	if need != "" and str(SceneRouter.current_route) != need:
		return _fail("step '%s' needs route '%s' (current: '%s')" % [step.do, need, SceneRouter.current_route])
	var p := _current_probe()
	if p == null:
		return _fail("step '%s': no probe is attached for route '%s'" % [step.do, SceneRouter.current_route])
	var args := step.duplicate()
	args.erase("do")
	var msg: String = p.dev_op(str(step.do), args)
	return true if msg == "" else _fail(msg)


func _exists(id: String) -> bool:
	if not _is_probe_id(id):
		return _view.resolve(id).ok
	if _view.route_root() == null or id.get_slice("/", 0) != str(SceneRouter.current_route):
		return false
	var p := _current_probe()
	return p != null and p.has(id)


static func _is_probe_id(id: String) -> bool:
	var parts := id.split("/")
	# Routes without a probe (sector) keep their state ids in ui_view.STATE_IDS.
	return parts.size() >= 2 and parts[1] != "ui" and PROBES.has(parts[0])


## Reads an id through the UI view (ui ids) or the route's probe (state ids).
func _read(id: String, prop: String) -> Dictionary:
	if not _is_probe_id(id):
		var parts := id.split("/")
		if parts.size() >= 2 and parts[1] != "ui" and not UiView.STATE_IDS.has(id):
			return {"ok": false, "value": null, "error": "no probe is attached for route '%s' (id '%s')" % [parts[0], id]}
		return _view.read(id, prop)
	var fail := {"ok": false, "value": null, "error": ""}
	if _view.route_root() == null:
		fail.error = "no route is mounted"
		return fail
	if id.get_slice("/", 0) != str(SceneRouter.current_route):
		fail.error = "id '%s' needs route '%s' (current: '%s')" % [id, id.get_slice("/", 0), SceneRouter.current_route]
		return fail
	var p := _current_probe()
	if p == null:
		fail.error = "no probe is attached for route '%s' (id '%s')" % [SceneRouter.current_route, id]
		return fail
	return p.read(id, prop)


func _snapshot(snap_name: String) -> bool:
	if _snapshots.size() >= MAX_SNAPSHOTS:
		return _fail("snapshot limit (%d per run) reached" % MAX_SNAPSHOTS)
	var dir := str(_opts.get("out_dir", ""))
	if dir == "":
		return _fail("snapshot needs an output directory")
	var p := _current_probe()
	var data := {"frame": frames, "route": str(SceneRouter.current_route),
		"ui": _view.list_focusable(), "probe": p.snapshot() if p != null else null}
	var folder := dir.path_join("snapshots")
	DirAccess.make_dir_recursive_absolute(folder)
	var path := folder.path_join(snap_name + ".json")
	var f := FileAccess.open(path, FileAccess.WRITE)
	if f == null:
		return _fail("could not write %s" % path)
	f.store_string(JSON.stringify(data, "\t"))
	f.close()
	_snapshots.append(path)
	return true


## Appends one Performance sample to result.perf (extra samples beyond MAX_PERF are dropped).
func _perf_sample() -> bool:
	if _perf.size() < MAX_PERF:
		_perf.append({"frame": frames,
			"fps": Performance.get_monitor(Performance.TIME_FPS),
			"process_ms": Performance.get_monitor(Performance.TIME_PROCESS) * 1000.0,
			"physics_ms": Performance.get_monitor(Performance.TIME_PHYSICS_PROCESS) * 1000.0,
			"objects": int(Performance.get_monitor(Performance.OBJECT_COUNT)),
			"nodes": int(Performance.get_monitor(Performance.OBJECT_NODE_COUNT)),
			"orphan_nodes": int(Performance.get_monitor(Performance.OBJECT_ORPHAN_NODE_COUNT)),
			"static_mem_mb": Performance.get_monitor(Performance.MEMORY_STATIC) / 1048576.0})
	return true


## Waits for `count` (default 1) occurrences of a probe event that happen after this step starts.
func _wait_event(step: Dictionary) -> bool:
	var p := _current_probe()
	var ev := str(step.event)
	if p == null:
		return _fail("wait_event: no probe is attached for route '%s'" % SceneRouter.current_route)
	var known: PackedStringArray = p.event_names()
	if not known.has(ev):
		return _fail("wait_event: unknown event '%s' (known: %s)" % [ev, ", ".join(known)])
	var want := int(step.get("count", 1))
	var base := _event_counts.duplicate()
	return await _wait_for(func() -> Dictionary:
		var seen: PackedStringArray = []
		var got := 0
		for k: Variant in _event_counts.keys():
			var n := int(_event_counts[k]) - int(base.get(k, 0))
			if n > 0:
				seen.append("%s x%d" % [k, n])
			if str(k) == ev:
				got = n
		return {"ok": got >= want, "text": "'%s' seen %d of %d; events seen: %s" % [ev, got, want, ", ".join(seen) if not seen.is_empty() else "none"]}, int(step.within))


## Evaluate a wait_until / assert comparator against the current value.
func _check(step: Dictionary) -> Dictionary:
	var r := _read(str(step.id), str(step.prop))
	if not r.ok:
		return {"ok": false, "text": str(r.error)}
	for op: String in Schema.COMPARATORS:
		if step.has(op):
			return {"ok": _compare(op, r.value, step[op]), "text": "%s.%s = %s (wanted %s %s)" % [step.id, step.prop, r.value, op, step[op]]}
	return {"ok": false, "text": "no comparator"}


static func _compare(op: String, a: Variant, b: Variant) -> bool:
	if op == "in":
		return (b as Array).any(func(e: Variant) -> bool: return _compare("eq", a, e))
	var numeric := typeof(a) in [TYPE_INT, TYPE_FLOAT] and typeof(b) in [TYPE_INT, TYPE_FLOAT]
	match op:
		"eq":
			return is_equal_approx(float(a), float(b)) if numeric else a == b
		"ne":
			return not _compare("eq", a, b)
	if not numeric:
		return false
	var x := float(a)
	var y := float(b)
	match op:
		"lt":
			return x < y
		"lte":
			return x <= y
		"gt":
			return x > y
	return x >= y


func _control(id: String) -> Control:
	var r := _view.resolve(id)
	if not r.ok:
		_detail = str(r.error)
		return null
	if not r.node is Control:
		_detail = "'%s' is not a Control" % id
		return null
	return r.node as Control


## Press then release an action for `n` frames (at least 2).
func _tap(action: StringName, n: int = 2) -> bool:
	input.press(action)
	var ok := await _wait(InputDriver.clamp_frames(n))
	input.release(action)
	return ok


func _activate(id: String) -> bool:
	var c := _control(id)
	if c == null:
		return false
	if not c.is_visible_in_tree():
		return _fail("'%s' is not visible" % id)
	if c is BaseButton and (c as BaseButton).disabled:
		return _fail("'%s' is disabled" % id)
	if c.focus_mode == Control.FOCUS_NONE:
		return _fail("'%s' cannot take focus" % id)
	c.grab_focus()
	if not await _tick():
		return false
	if not await _tap(&"ui_accept"):
		return false
	return await _tick()


## Dev-only. SettingsService only, and only the keys it declares (the four accessibility settings).
func _set_setting(key: String, value: Variant) -> bool:
	var k := StringName(key)
	if not SettingsService.DEFAULTS.has(k):
		return _fail("unknown setting '%s' (allowed: %s)" % [key, ", ".join((SettingsService.DEFAULTS.keys() as Array).map(func(x: Variant) -> String: return str(x)))])
	var want: Variant = SettingsService.DEFAULTS[k]
	if typeof(want) == TYPE_FLOAT and typeof(value) in [TYPE_INT, TYPE_FLOAT]:
		value = float(value)
	if typeof(value) != typeof(want):
		return _fail("setting '%s' needs a %s value" % [key, type_string(typeof(want))])
	SettingsService.set_value(k, value)
	return true


## Clean slate between phases of a long scenario: empty memory saves, default settings, attract.
func _reset() -> bool:
	for slot: Variant in SaveService.ALLOWED_REASONS.keys():
		SaveService.clear_slot(slot as StringName)
	SettingsService.reset_to_defaults()
	input.release_all()
	if not SceneRouter.go_to(&"attract"):
		return _fail("go_to('attract') was refused (router busy)")
	return await _wait_for(func() -> Dictionary:
		return {"ok": SceneRouter.current_route == &"attract" and not SceneRouter.is_busy,
			"text": "route=%s busy=%s" % [SceneRouter.current_route, SceneRouter.is_busy]}, RESET_ROUTE_FRAMES)


func _autopilot(on: bool) -> bool:
	var root := _view.route_root()
	var ap: Node = root.get_node_or_null("%Autopilot") if root != null else null
	if SceneRouter.current_route != &"cabinet" or ap == null or not "enabled" in ap:
		return _fail("autopilot needs the cabinet route (current: '%s')" % SceneRouter.current_route)
	ap.set("enabled", on)
	return true


## Peel the tape and drop a coin using only real input (accept held, then tapped).
func _coin() -> bool:
	var root := _view.route_root()
	var slot: Control = root.get_node_or_null("%CoinSlot") as Control if root != null else null
	if SceneRouter.current_route != &"attract" or slot == null:
		return _fail("coin needs the attract route (current: '%s')" % SceneRouter.current_route)
	slot.grab_focus()
	var phase := func() -> String: return UiView.enum_name_of(slot, "Phase", int(slot.get("phase")))
	if phase.call() == "credited":
		return true
	if phase.call() == "taped":
		input.press(&"ui_accept")
		if not await _wait_for(func() -> Dictionary: return {"ok": phase.call() != "taped", "text": "phase=%s" % phase.call()}, COIN_PEEL_FRAMES):
			input.release(&"ui_accept")
			return false
		input.release(&"ui_accept")
		if not await _wait(2):
			return false
	if not await _wait_for(func() -> Dictionary: return {"ok": phase.call() == "open", "text": "phase=%s" % phase.call()}, COIN_STEP_FRAMES):
		return false
	slot.grab_focus()
	if not await _tap(&"ui_accept"):
		return false
	return await _wait_for(func() -> Dictionary: return {"ok": bool(slot.call("has_credit")), "text": "phase=%s" % phase.call()}, COIN_STEP_FRAMES)


func _screenshot(step: Dictionary) -> bool:
	if DisplayServer.get_name() != "headless":
		await RenderingServer.frame_post_draw
	if done:
		return false
	var r := Capture.take(get_tree(), _view.route_root(), str(step.name), str(step.target), str(_opts.get("out_dir", "")))
	_shots.append(r.record)
	if not r.ok:
		return _fail(str(r.detail))
	return true


func _finish(code: int, outcome: StringName, detail: String) -> void:
	if done:
		return
	input.release_all()
	if code == 0 and _logger != null and bool(_scenario.get("fail_on_errors", false)):
		var bad: Array = _logger.blocking(_scenario.get("allow_errors", []) as Array)
		if not bad.is_empty():
			code = 1
			outcome = &"fail"
			_detail_do = "errors"
			detail = "fail_on_errors: %d error(s): %s" % [bad.size(), " | ".join(bad.slice(0, 3).map(func(e: Dictionary) -> String: return str(e.message)))]
	if detail != "" and _detail == "":
		_detail = detail
	var steps_out := _step_log.duplicate()
	if detail != "":
		steps_out.append({"i": -1, "do": _detail_do, "outcome": "fail", "frame_start": 0, "frame_end": 0, "detail": detail.substr(0, MAX_DETAIL * 3)})
	var tags: Array = []
	for t in FEATURE_TAGS:
		if OS.has_feature(t):
			tags.append(t)
	result = {
		"format": "darkstar.result", "version": 1,
		"scenario": str(_scenario.get("id", "")),
		"source": str(_opts.get("source", "")),
		"profile": _profile,
		"build": {
			"profile": str(_opts.get("profile", build_profile())),
			"godot": Engine.get_version_info().string,
			"game_version": str(ProjectSettings.get_setting("application/config/version", "")),
			"features": tags,
			"headless": DisplayServer.get_name() == "headless",
		},
		"outcome": str(outcome), "exit_code": code, "frames": frames,
		"steps": steps_out, "checkpoints": _checkpoints, "screenshots": _shots,
		"snapshots": _snapshots, "events": _events, "perf": _perf,
		"errors": _logger.snapshot() if _logger != null else [],
		"error_count": _logger.error_count if _logger != null else 0,
		"warning_count": _logger.warning_count if _logger != null else 0,
	}
	_detach_probe()
	_remove_logger()
	var dir := str(_opts.get("out_dir", ""))
	if dir != "":
		DirAccess.make_dir_recursive_absolute(dir)
		var f := FileAccess.open(dir.path_join("result.json"), FileAccess.WRITE)
		if f != null:
			f.store_string(JSON.stringify(result, "\t"))
			f.close()
	done = true
	scenario_finished.emit(outcome)
	if bool(_opts.get("quit_on_finish", false)) and is_inside_tree():
		get_tree().quit(code)
