extends RefCounted
## Scenario validator. Step names and argument shapes come from step_catalog.json (shared with the
## Node CLI); comparator and range rules are coded here and in tools/automation/darkstar_auto.js.
## No class_name: release builds may exclude core/automation.

const CATALOG_PATH := "res://core/automation/step_catalog.json"
const FORMAT := "darkstar.scenario"
const VERSION := 1
const MAX_STEPS := 2000            ## ✱ engineering-only limits
const MAX_TIMEOUT_FRAMES := 216000 ## ✱ one hour at 60 fps
const MAX_SCREENSHOTS := 100       ## ✱
const SUITE_TIMEOUT_FRAMES := 1200 ## ✱ scenarios run inside GdUnit must fit this
const MAX_WAIT := 216000           ## ✱ cap for any single frames/within value
const COMPARATORS: Array[String] = ["eq", "ne", "lt", "lte", "gt", "gte", "in"]
const TOP_KEYS: Array[String] = ["format", "version", "id", "args", "fixtures", "timeout_frames", "steps", "profile", "fail_on_errors", "allow_errors"]
const SLOTS: Array[String] = ["profile", "iteration", "run"]
const MAX_OFFSET := 4000.0          ## ✱ |x|, |y|, |dx|, |dy| limit for cabinet dev steps
const MAX_STEP_SIM := 3600          ## ✱
const SPAWN_KINDS: Array[String] = ["acolyte", "geode", "shard"]
const NAME_RE := "^[a-z0-9_]+$"
const MOUSE_BUTTONS: Array[String] = ["left", "right", "middle"]
const TARGETS: Array[String] = ["arcade", "window"]
## Profiles: a scenario may declare `profile` "qa" or "dev" and can only ask for LESS than the build
## offers. A "qa" scenario run on a dev build is held to the qa rules (dev steps and unapproved
## fixtures are refused); a "dev" scenario on a qa build is refused. Omitted = the build's profile.
const PROFILES: Array[String] = ["qa", "dev"]

static var _catalog: Dictionary = {}


static func catalog() -> Dictionary:
	if _catalog.is_empty():
		var parsed: Variant = JSON.parse_string(FileAccess.get_file_as_string(CATALOG_PATH))
		if typeof(parsed) == TYPE_DICTIONARY:
			_catalog = parsed
	return _catalog


## True when the catalog marks the step dev-only (single source: step_catalog.json "dev": true).
static func is_dev_step(step_name: String) -> bool:
	var def: Variant = (catalog().get("steps", {}) as Dictionary).get(step_name)
	return typeof(def) == TYPE_DICTIONARY and bool((def as Dictionary).get("dev", false))


## Names of the dev-only steps a scenario uses (unique, in order of first use).
static func dev_steps_used(scenario: Dictionary) -> Array[String]:
	var out: Array[String] = []
	var steps: Variant = scenario.get("steps")
	if typeof(steps) != TYPE_ARRAY:
		return out
	for s: Variant in steps as Array:
		if typeof(s) == TYPE_DICTIONARY:
			var n := str((s as Dictionary).get("do", ""))
			if is_dev_step(n) and not out.has(n):
				out.append(n)
	return out


static func is_name(s: String) -> bool:
	return RegEx.create_from_string(NAME_RE).search(s) != null


static func validate(scenario: Dictionary, for_suite: bool) -> Array[String]:
	var errs: Array[String] = []
	var steps_def: Dictionary = catalog().get("steps", {})
	if steps_def.is_empty():
		errs.append("step catalog missing or unreadable")
		return errs
	for k: Variant in scenario.keys():
		if not TOP_KEYS.has(str(k)):
			errs.append("unknown top-level key '%s'" % str(k))
	if scenario.get("format") != FORMAT:
		errs.append("format must be '%s'" % FORMAT)
	if not _is_int(scenario.get("version")) or int(scenario.get("version")) != VERSION:
		errs.append("version must be %d" % VERSION)
	var id: Variant = scenario.get("id")
	if typeof(id) != TYPE_STRING or not is_name(id as String):
		errs.append("id must match %s" % NAME_RE)
	var args: Variant = scenario.get("args", [])
	if not _type_ok(args, "string_array"):
		errs.append("args must be an array of strings")
	elif for_suite and not (args as Array).is_empty():
		errs.append("suite scenarios must have args == []")
	if scenario.has("fixtures"):
		errs.append_array(_check_fixtures(scenario.get("fixtures")))
	if scenario.has("profile") and (typeof(scenario.get("profile")) != TYPE_STRING or not PROFILES.has(str(scenario.get("profile")))):
		errs.append("profile must be 'qa' or 'dev'")
	if scenario.has("fail_on_errors") and typeof(scenario.get("fail_on_errors")) != TYPE_BOOL:
		errs.append("fail_on_errors must be a bool")
	if scenario.has("allow_errors") and not _type_ok(scenario.get("allow_errors"), "string_array"):
		errs.append("allow_errors must be an array of strings")
	var timeout: Variant = scenario.get("timeout_frames")
	if not _is_int(timeout) or int(timeout) < 1 or int(timeout) > MAX_TIMEOUT_FRAMES:
		errs.append("timeout_frames must be an int in 1..%d" % MAX_TIMEOUT_FRAMES)
	elif for_suite and int(timeout) > SUITE_TIMEOUT_FRAMES:
		errs.append("suite scenarios must have timeout_frames <= %d" % SUITE_TIMEOUT_FRAMES)
	var steps: Variant = scenario.get("steps")
	if typeof(steps) != TYPE_ARRAY or (steps as Array).is_empty():
		errs.append("steps must be a non-empty array")
		return errs
	var list: Array = steps
	if list.size() > MAX_STEPS:
		errs.append("too many steps (%d > %d)" % [list.size(), MAX_STEPS])
		return errs
	var shots := 0
	for i in list.size():
		var step: Variant = list[i]
		if typeof(step) != TYPE_DICTIONARY:
			errs.append("step %d: must be an object" % i)
			continue
		var sd: Dictionary = step
		if sd.get("do") == "screenshot":
			shots += 1
		errs.append_array(_check_step(i, sd, steps_def))
	if shots > MAX_SCREENSHOTS:
		errs.append("too many screenshots (%d > %d)" % [shots, MAX_SCREENSHOTS])
	return errs


static func _check_fixtures(fx: Variant) -> Array[String]:
	var errs: Array[String] = []
	if typeof(fx) != TYPE_DICTIONARY:
		errs.append("fixtures must be an object")
		return errs
	var d: Dictionary = fx
	for slot: Variant in d.keys():
		if not SLOTS.has(str(slot)):
			errs.append("fixtures: unknown slot '%s'" % str(slot))
		elif typeof(d[slot]) != TYPE_STRING or not is_name(d[slot] as String):
			errs.append("fixtures: name for '%s' must match %s" % [str(slot), NAME_RE])
	return errs


static func _check_step(i: int, step: Dictionary, defs: Dictionary) -> Array[String]:
	var errs: Array[String] = []
	var name: String = str(step.get("do"))
	if typeof(step.get("do")) != TYPE_STRING or not defs.has(name):
		errs.append("step %d: unknown step '%s'" % [i, name])
		return errs
	var def: Dictionary = defs[name]
	var req: Dictionary = def.get("args", {})
	var opt: Dictionary = def.get("optional", {})
	for k: Variant in req.keys():
		if not step.has(k):
			errs.append("step %d (%s): missing arg '%s'" % [i, name, str(k)])
	for k: Variant in step.keys():
		if k == "do":
			continue
		var type: Variant = req.get(k, opt.get(k))
		if type == null:
			errs.append("step %d (%s): unknown arg '%s'" % [i, name, str(k)])
		elif not _type_ok(step[k], str(type)):
			errs.append("step %d (%s): arg '%s' must be %s" % [i, name, str(k), str(type)])
	if not errs.is_empty():
		return errs
	var cmps: Array = COMPARATORS.filter(func(c: String) -> bool: return step.has(c))
	match name:
		"wait_until":
			if cmps.size() != 1:
				errs.append("step %d (wait_until): exactly one comparator of %s required" % [i, ", ".join(COMPARATORS)])
		"assert":
			if step.has("exists"):
				if step.has("prop") or not cmps.is_empty():
					errs.append("step %d (assert): exists cannot combine with prop or a comparator" % i)
			elif not step.has("prop") or cmps.size() != 1:
				errs.append("step %d (assert): needs exists, or prop plus exactly one comparator" % i)
		"press", "release", "hold":
			if not InputMap.has_action(str(step.action)):
				errs.append("step %d (%s): unknown action '%s'" % [i, name, str(step.action)])
		"key":
			if OS.find_keycode_from_string(str(step.keycode)) == KEY_NONE:
				errs.append("step %d (key): unknown keycode '%s'" % [i, str(step.keycode)])
		"screenshot":
			if not is_name(str(step.name)):
				errs.append("step %d (screenshot): name must match %s" % [i, NAME_RE])
			if not TARGETS.has(str(step.target)):
				errs.append("step %d (screenshot): target must be arcade or window" % i)
		"mouse_button":
			if not MOUSE_BUTTONS.has(str(step.button)):
				errs.append("step %d (mouse_button): button must be left, right or middle" % i)
		"checkpoint":
			if not is_name(str(step.name)):
				errs.append("step %d (checkpoint): name must match %s" % [i, NAME_RE])
		"set_setting":
			if str(step.key).is_empty():
				errs.append("step %d (set_setting): key must not be empty" % i)
		"snapshot":
			if not is_name(str(step.name)):
				errs.append("step %d (snapshot): name must match %s" % [i, NAME_RE])
		"wait_event":
			if str(step.event).is_empty():
				errs.append("step %d (wait_event): event must not be empty" % i)
			if step.has("count") and (int(step.count) < 1 or int(step.count) > 1000):
				errs.append("step %d (wait_event): count must be in 1..1000" % i)
		"set_stage":
			if int(step.index) < 0 or int(step.index) > 99:
				errs.append("step %d (set_stage): index must be in 0..99" % i)
		"set_lives":
			if int(step.lives) < 0 or int(step.lives) > 9:
				errs.append("step %d (set_lives): lives must be in 0..9" % i)
		"teleport":
			errs.append_array(_offsets(i, name, step, ["x", "y"]))
		"spawn":
			if not SPAWN_KINDS.has(str(step.kind)):
				errs.append("step %d (spawn): kind must be one of %s" % [i, ", ".join(SPAWN_KINDS)])
			errs.append_array(_offsets(i, name, step, ["dx", "dy"]))
		"place_entity":
			errs.append_array(_offsets(i, name, step, ["dx", "dy"]))
		"shoot_vigil":
			errs.append_array(_offsets(i, name, step, ["dx", "dy"]))
			if is_zero_approx(float(step.dx)) and is_zero_approx(float(step.dy)):
				errs.append("step %d (shoot_vigil): dx and dy cannot both be 0" % i)
		"step_sim":
			if int(step.frames) > MAX_STEP_SIM:
				errs.append("step %d (step_sim): frames must be in 1..%d" % [i, MAX_STEP_SIM])
	for k in ["frames", "within"]:
		if step.has(k) and (int(step[k]) < 1 or int(step[k]) > MAX_WAIT):
			errs.append("step %d (%s): %s must be in 1..%d" % [i, name, k, MAX_WAIT])
	return errs


static func _offsets(i: int, name: String, step: Dictionary, keys: Array) -> Array[String]:
	var errs: Array[String] = []
	for k: String in keys:
		if absf(float(step[k])) > MAX_OFFSET:
			errs.append("step %d (%s): |%s| must be <= %d" % [i, name, k, int(MAX_OFFSET)])
	return errs


static func _is_int(v: Variant) -> bool:
	if typeof(v) == TYPE_INT:
		return true
	return typeof(v) == TYPE_FLOAT and is_finite(v as float) and floorf(v as float) == (v as float)


static func _is_scalar(v: Variant) -> bool:
	return typeof(v) in [TYPE_STRING, TYPE_INT, TYPE_FLOAT, TYPE_BOOL]


static func _type_ok(v: Variant, type: String) -> bool:
	match type:
		"string":
			return typeof(v) == TYPE_STRING
		"int":
			return _is_int(v)
		"number":
			return typeof(v) in [TYPE_INT, TYPE_FLOAT] and is_finite(float(v))
		"bool":
			return typeof(v) == TYPE_BOOL
		"string_array":
			return typeof(v) == TYPE_ARRAY and (v as Array).all(func(e: Variant) -> bool: return typeof(e) == TYPE_STRING)
		"scalar":
			return _is_scalar(v)
		"array":
			return typeof(v) == TYPE_ARRAY and (v as Array).all(_is_scalar)
	return false
