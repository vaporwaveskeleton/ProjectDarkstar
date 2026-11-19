extends RefCounted
## Automation probe for the Act 0 Cabinet route (dev/QA only; release builds exclude this folder).
## Duck-typed contract with core/automation/scenario_runner.gd (see its header). No class_name.
##
## Ids (lower-case, never display text) and their allow-listed props; scalars only:
##   cabinet/game      state (lower-case enum name), stage_index, demo
##   cabinet/score     score, lives
##   cabinet/record    grubs_destroyed, glass_mined, charges_thrown, glass_carried
##   cabinet/vigil     alive, shield, pos_x, pos_y, use_scripted
##   cabinet/world     acolytes, grubs, geodes, shots, hostile_shots, charges, paused_sim, sim_scale, hitstop_left, time
##   cabinet/acolyte/<id>    alive, hp, pos_x, pos_y, on_screen, dx, dy (torus delta from the Vigil)
##   cabinet/grub/<id>       alive, carrying, hp, pos_x, pos_y
##   cabinet/geode/<index>   alive, faces_left
## A step_sim runs ArcadeWorld.step() only: it never advances the CabinetGame state machine (death
## timer, respawn, stage flow) because that runs from CabinetGame._process.

const UiView := preload("res://core/automation/ui_view.gd")

const ROUTE := "cabinet"
const MAX_LIST := 200            ## ✱ entries per list in snapshot()
const MAX_OFFSET := 4000.0       ## ✱ |dx|, |dy|, |x|, |y| limit for dev ops
const MAX_STEPS := 3600          ## ✱ step_sim frames per call
const SPAWN_KINDS: Array[String] = ["acolyte", "geode", "shard"]
const SINGLETONS: Dictionary = {
	"cabinet/game": ["state", "stage_index", "demo"],
	"cabinet/score": ["score", "lives"],
	"cabinet/record": ["grubs_destroyed", "glass_mined", "charges_thrown", "glass_carried"],
	"cabinet/vigil": ["alive", "shield", "pos_x", "pos_y", "use_scripted"],
	"cabinet/world": ["acolytes", "grubs", "geodes", "shots", "hostile_shots", "charges", "paused_sim", "sim_scale", "hitstop_left", "time"],
}
const ENTITIES: Dictionary = {
	"cabinet/acolyte/*": ["alive", "hp", "pos_x", "pos_y", "on_screen", "dx", "dy"],
	"cabinet/grub/*": ["alive", "carrying", "hp", "pos_x", "pos_y"],
	"cabinet/geode/*": ["alive", "faces_left"],
}
const EVENTS: Array[String] = ["vigil_destroyed", "score_awarded", "hitstop_started", "slowmo_changed",
	"sepulchre_cleared", "entity_unmade", "phase_changed", "segments_changed", "charges_changed"]
const DEV_OPS: Array[String] = ["set_stage", "set_lives", "teleport", "spawn", "shoot_vigil", "kill_all", "pause_sim", "step_sim"]

var _root: Node
var _world: ArcadeWorld
var _sink: Callable = Callable()
var _links: Array = []   ## [Signal, Callable] pairs to undo


func setup(route_root: Node) -> void:
	_root = route_root
	_world = route_root.get("world") as ArcadeWorld if route_root != null else null


# --- contract: describe / has / read / snapshot -----------------------------------------------

func describe() -> Dictionary:
	var ids: Array = SINGLETONS.keys() + ENTITIES.keys()
	var props := {}
	for k: Variant in SINGLETONS.keys():
		props[k] = SINGLETONS[k]
	for k: Variant in ENTITIES.keys():
		props[k] = ENTITIES[k]
	return {"ids": ids, "props": props, "events": EVENTS.duplicate(), "dev_ops": DEV_OPS.duplicate()}


func has(id: String) -> bool:
	return not _props_of(id).is_empty()


## {"ok": bool, "value": Variant, "error": String}
func read(id: String, prop: String) -> Dictionary:
	if _world == null:
		return _err("the cabinet is not ready")
	var props: Dictionary = _props_of(id)
	if props.is_empty():
		return _err(("no entity '%s' in the cabinet" if _is_entity_id(id) else "unknown id '%s'") % id)
	if not props.has(prop):
		return _err("property '%s' is not readable on '%s' (allowed: %s)" % [prop, id, ", ".join(PackedStringArray(props.keys()))])
	return {"ok": true, "value": props[prop], "error": ""}


func snapshot() -> Dictionary:
	var out := {"route": ROUTE}
	if _world == null:
		return out
	for id: Variant in SINGLETONS.keys():
		out[str(id).get_slice("/", 1)] = _props_of(str(id))
	var acolytes: Array = []
	for a in _world.acolytes.items:
		if acolytes.size() >= MAX_LIST:
			break
		var d := _acolyte_props(a)
		d["id"] = a.id
		acolytes.append(d)
	var grubs: Array = []
	for g in _world.grubs.items:
		if grubs.size() >= MAX_LIST:
			break
		var d := _grub_props(g)
		d["id"] = g.id
		grubs.append(d)
	var geodes: Array = []
	var items: Array = _world.geodes.items
	for i in mini(items.size(), MAX_LIST):
		var d := _geode_props(items[i])
		d["index"] = i
		geodes.append(d)
	out["acolytes"] = acolytes
	out["grubs"] = grubs
	out["geodes"] = geodes
	return out


# --- props -------------------------------------------------------------------------------------

func _is_entity_id(id: String) -> bool:
	var parts := id.split("/")
	return parts.size() == 3 and parts[0] == ROUTE and ["acolyte", "grub", "geode"].has(parts[1])


## All allow-listed props for an id, or {} when the id is unknown or the entity is gone.
func _props_of(id: String) -> Dictionary:
	if _world == null or _root == null:
		return {}
	match id:
		"cabinet/game":
			return {"state": UiView.enum_name_of(_root, "State", int(_root.get("state"))),
				"stage_index": int(_root.get("stage_index")), "demo": bool(_root.get("demo"))}
		"cabinet/score":
			var sk: Object = _root.get("score") as Object
			return {} if sk == null else {"score": int(sk.get("score")), "lives": int(sk.get("lives"))}
		"cabinet/record":
			var rec: Object = _root.get("record") as Object
			if rec == null:
				return {}
			var d := {}
			for k: String in SINGLETONS[id]:
				d[k] = int(rec.get(k))
			return d
		"cabinet/vigil":
			var v := _world.vigil
			return {"alive": v.alive, "shield": v.shield, "pos_x": v.pos.x, "pos_y": v.pos.y, "use_scripted": v.use_scripted}
		"cabinet/world":
			return _world_props()
	var parts := id.split("/")
	if not _is_entity_id(id) or not parts[2].is_valid_int():
		return {}
	var key := parts[2].to_int()
	match parts[1]:
		"acolyte":
			for a in _world.acolytes.items:
				if a.id == key:
					return _acolyte_props(a)
		"grub":
			for g in _world.grubs.items:
				if g.id == key:
					return _grub_props(g)
		"geode":
			var items: Array = _world.geodes.items
			if key >= 0 and key < items.size():
				return _geode_props(items[key])
	return {}


func _world_props() -> Dictionary:
	var shots := 0
	var hostile := 0
	for s in _world.shots.shots:
		if s.alive:
			shots += 1
			if s.hostile:
				hostile += 1
	return {
		"acolytes": _alive_count(_world.acolytes.items), "grubs": _alive_count(_world.grubs.items),
		"geodes": _alive_count(_world.geodes.items), "shots": shots, "hostile_shots": hostile,
		"charges": _world.glass.charges, "paused_sim": _world.paused_sim, "sim_scale": _world.sim_scale,
		"hitstop_left": _world.hitstop_left, "time": _world.time,
	}


static func _alive_count(items: Array) -> int:
	var n := 0
	for e: Variant in items:
		if bool((e as Object).get("alive")):
			n += 1
	return n


func _acolyte_props(a: AcolyteSquad.Acolyte) -> Dictionary:
	var d := _world.torus.delta(_world.vigil.pos, a.pos)
	return {"alive": a.alive, "hp": a.hp, "pos_x": a.pos.x, "pos_y": a.pos.y,
		"on_screen": _world.on_screen(a.pos, 0.0), "dx": d.x, "dy": d.y}


func _grub_props(g: GrubFlock.Grub) -> Dictionary:
	return {"alive": g.alive, "carrying": g.carrying, "hp": g.hp, "pos_x": g.pos.x, "pos_y": g.pos.y}


func _geode_props(g: GeodeField.Geode) -> Dictionary:
	return {"alive": g.alive, "faces_left": g.faces_left}


static func _err(msg: String) -> Dictionary:
	return {"ok": false, "value": null, "error": msg}


# --- events ------------------------------------------------------------------------------------

func event_names() -> PackedStringArray:
	return PackedStringArray(EVENTS)


## `sink` is called as sink(event_id: String, args: Array); args are scalars only.
func connect_events(sink: Callable) -> void:
	disconnect_events()
	if _world == null:
		return
	_sink = sink
	_link(_world.vigil_destroyed, func() -> void: _emit("vigil_destroyed", []))
	_link(_world.score_awarded, func(points: int, at: Vector2) -> void: _emit("score_awarded", [points, at.x, at.y]))
	_link(_world.hitstop_started, func(beat: StringName) -> void: _emit("hitstop_started", [String(beat)]))
	_link(_world.slowmo_changed, func(scale: float) -> void: _emit("slowmo_changed", [scale]))
	_link(_world.sepulchre_cleared, func() -> void: _emit("sepulchre_cleared", []))
	_link(_world.entity_unmade, func() -> void: _emit("entity_unmade", []))
	_link(_world.phase_changed, func(phase: int) -> void: _emit("phase_changed", [UiView.enum_name_of(_world.ritual, "Phase", phase)]))
	_link(_world.segments_changed, func(count: int) -> void: _emit("segments_changed", [count]))
	_link(_world.charges_changed, func(count: int) -> void: _emit("charges_changed", [count]))


func disconnect_events() -> void:
	for pair: Array in _links:
		var sig: Signal = pair[0]
		var cb: Callable = pair[1]
		if sig.is_connected(cb):
			sig.disconnect(cb)
	_links.clear()
	_sink = Callable()


func _link(sig: Signal, cb: Callable) -> void:
	sig.connect(cb)
	_links.append([sig, cb])


func _emit(event_id: String, args: Array) -> void:
	if _sink.is_valid():
		_sink.call(event_id, args)


# --- dev ops (the runner has already checked profile, route and the schema) ---------------------

## "" on success, else a plain failure message.
func dev_op(op: String, args: Dictionary) -> String:
	if _world == null or _root == null or _world.stage == null:
		return "the cabinet is not ready"
	match op:
		"set_stage":
			var i := _int_arg(args, "index")
			var stages: Array = _root.get("stages")
			if i < 0 or i >= stages.size():
				return "set_stage: index %d is outside 0..%d" % [i, stages.size() - 1]
			_root.call("start_stage", i)
			return ""
		"set_lives":
			var n := _int_arg(args, "lives")
			if n < 0 or n > 9:
				return "set_lives: lives must be 0..9"
			var sk: Object = _root.get("score") as Object
			sk.set("lives", n)
			sk.emit_signal("lives_changed", n)
			return ""
		"teleport":
			var p := _vec_arg(args, "x", "y")
			if not _in_range(p):
				return "teleport: x and y must be finite numbers with |v| <= %d" % int(MAX_OFFSET)
			_world.vigil.pos = _world.torus.wrap(p)
			_world.vigil.vel = Vector2.ZERO
			_world.view_centre = _world.vigil.pos
			return ""
		"spawn":
			return _spawn(args)
		"shoot_vigil":
			var off := _vec_arg(args, "dx", "dy")
			if not _in_range(off):
				return "shoot_vigil: dx and dy must be finite numbers with |v| <= %d" % int(MAX_OFFSET)
			if off.is_zero_approx():
				return "shoot_vigil: dx and dy cannot both be 0"
			var from := _world.torus.wrap(_world.vigil.pos + off)
			var dir := _world.torus.delta(from, _world.vigil.pos).normalized()
			if dir == Vector2.ZERO:
				return "shoot_vigil: the origin is on the Vigil"
			var before := _world.shots.shots.size()
			_world.shots.fire_censer(from, dir)
			return "" if _world.shots.shots.size() > before else "shoot_vigil: the shot cap is reached"
		"kill_all":
			_kill_all()
			return ""
		"pause_sim":
			_world.paused_sim = bool(args.get("on", false))
			return ""
		"step_sim":
			var frames := _int_arg(args, "frames")
			if not _world.paused_sim:
				return "step_sim needs paused_sim (run pause_sim on first)"
			if frames < 1 or frames > MAX_STEPS:
				return "step_sim: frames must be 1..%d" % MAX_STEPS
			for _i in frames:
				_world.step(1.0 / 60.0)
			return ""
	return "unknown cabinet op '%s'" % op


func _spawn(args: Dictionary) -> String:
	var kind := str(args.get("kind", ""))
	if not SPAWN_KINDS.has(kind):
		return "spawn: unknown kind '%s' (allowed: %s)" % [kind, ", ".join(PackedStringArray(SPAWN_KINDS))]
	var off := _vec_arg(args, "dx", "dy")
	if not _in_range(off):
		return "spawn: dx and dy must be finite numbers with |v| <= %d" % int(MAX_OFFSET)
	var at := _world.torus.wrap(_world.vigil.pos + off)
	match kind:
		"acolyte":
			_world.acolytes.spawn(at)
		"geode":
			_world.geodes.add_geode(at, 1)
		"shard":
			_world.glass.spawn_shard(at, Vector2.ZERO)
	return ""


## Acolytes, Grubs and hostile shots only. The ritual and geodes are untouched.
func _kill_all() -> void:
	for a in _world.acolytes.items:
		a.alive = false
	_world.acolytes.items.clear()
	for g in _world.grubs.items:
		g.alive = false
	_world.grubs.items.clear()
	for sh in _world.glass.shards:
		sh.claimed_by = 0
		sh.carried = false
	for s in _world.shots.shots:
		if s.hostile:
			s.alive = false
	_world.shots.shots.assign(_world.shots.shots.filter(func(s: ShotLayer.Shot) -> bool: return s.alive))


static func _int_arg(args: Dictionary, key: String) -> int:
	var v: Variant = args.get(key, 0)
	return int(v) if typeof(v) in [TYPE_INT, TYPE_FLOAT] else 0


static func _vec_arg(args: Dictionary, kx: String, ky: String) -> Vector2:
	var x: Variant = args.get(kx, 0.0)
	var y: Variant = args.get(ky, 0.0)
	var ok := typeof(x) in [TYPE_INT, TYPE_FLOAT] and typeof(y) in [TYPE_INT, TYPE_FLOAT]
	return Vector2(float(x), float(y)) if ok else Vector2(INF, INF)


static func _in_range(v: Vector2) -> bool:
	return is_finite(v.x) and is_finite(v.y) and absf(v.x) <= MAX_OFFSET and absf(v.y) <= MAX_OFFSET
