extends RefCounted
## Automation probe for the Act 0 Cabinet route (dev/QA only; release builds exclude this folder).
## Duck-typed contract with core/automation/scenario_runner.gd (see its header). No class_name.
##
## Ids (lower-case, never display text) and their allow-listed props; scalars only:
##   cabinet/game      state (lower-case enum name), stage_index, stage_id (CabinetStage.id, lower-case string e.g. "a0_3"; never display text), demo
##   cabinet/score     score, lives
##   cabinet/record    grubs_destroyed, glass_mined, charges_thrown, glass_carried
##   cabinet/vigil     alive, shield, pos_x, pos_y, use_scripted, killer_kind ("none"|"entity"|"shot", from the LATEST
##                     S6 death mark), killer_dx, killer_dy (torus delta death spot -> mark killer_pos), killer_on_screen, death_marks,
##                     death_outline, death_arrow (0..1 chalk draw progress of the latest mark; 0 with no mark),
##                     shooter_id (latest mark's shooter Acolyte id, -1 none), shooter_alive, shooter_on_screen (the LIVE shooter; false when none / gone)
##   cabinet/world     acolytes, grubs, geodes, shots, hostile_shots, charges, paused_sim, sim_scale, hitstop_left, time,
##                     death_marks, entity_awake, entity_dx, entity_dy (torus delta Vigil -> entity; 0 unless awake),
##                     last_spawned_acolyte_id (id of the Acolyte the latest `spawn acolyte` made; -1 none)
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
	"cabinet/game": ["state", "stage_index", "stage_id", "demo"],
	"cabinet/score": ["score", "lives"],
	"cabinet/record": ["grubs_destroyed", "glass_mined", "charges_thrown", "glass_carried"],
	"cabinet/vigil": ["alive", "shield", "pos_x", "pos_y", "use_scripted", "killer_kind", "killer_dx", "killer_dy", "killer_on_screen", "death_marks",
		"death_outline", "death_arrow", "shooter_id", "shooter_alive", "shooter_on_screen"],
	"cabinet/world": ["acolytes", "grubs", "geodes", "shots", "hostile_shots", "charges", "paused_sim", "sim_scale", "hitstop_left", "time",
		"death_marks", "entity_awake", "entity_dx", "entity_dy", "last_spawned_acolyte_id"],
}
const ENTITIES: Dictionary = {
	"cabinet/acolyte/*": ["alive", "hp", "pos_x", "pos_y", "on_screen", "dx", "dy"],
	"cabinet/grub/*": ["alive", "carrying", "hp", "pos_x", "pos_y"],
	"cabinet/geode/*": ["alive", "faces_left"],
}
const EVENTS: Array[String] = ["vigil_destroyed", "score_awarded", "hitstop_started", "slowmo_changed",
	"sepulchre_cleared", "entity_unmade", "phase_changed", "segments_changed", "charges_changed"]
const DEV_OPS: Array[String] = ["set_stage", "set_lives", "teleport", "spawn", "shoot_vigil", "kill_all", "pause_sim", "step_sim",
	"wake_entity", "place_entity", "kill_acolyte"]

var _root: Node
var _world: ArcadeWorld
var _sink: Callable = Callable()
var _links: Array = []   ## [Signal, Callable] pairs to undo
var _last_acolyte_id: int = -1   ## id of the Acolyte the latest `spawn acolyte` made


## The route root and its world still exist (the probe can outlive them across a route change).
func _alive() -> bool:
	return is_instance_valid(_world) and is_instance_valid(_root)


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
	if not _alive():
		return _err("the cabinet is not ready")
	var props: Dictionary = _props_of(id)
	if props.is_empty():
		return _err(("no entity '%s' in the cabinet" if _is_entity_id(id) else "unknown id '%s'") % id)
	if not props.has(prop):
		return _err("property '%s' is not readable on '%s' (allowed: %s)" % [prop, id, ", ".join(PackedStringArray(props.keys()))])
	return {"ok": true, "value": props[prop], "error": ""}


func snapshot() -> Dictionary:
	var out := {"route": ROUTE}
	if not _alive():
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
	if not _alive():
		return {}
	match id:
		"cabinet/game":
			return {"state": UiView.enum_name_of(_root, "State", int(_root.get("state"))),
				"stage_index": int(_root.get("stage_index")), "stage_id": _stage_id(), "demo": bool(_root.get("demo"))}
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
			var vd := {"alive": v.alive, "shield": v.shield, "pos_x": v.pos.x, "pos_y": v.pos.y, "use_scripted": v.use_scripted}
			vd.merge(_killer_props())
			return vd
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


## The current CabinetStage's id as a lower-case string ("" when out of range).
func _stage_id() -> String:
	var stages: Array = _root.get("stages")
	var i: int = int(_root.get("stage_index"))
	if i < 0 or i >= stages.size():
		return ""
	var st: Object = stages[i] as Object
	return "" if st == null else String(st.get("id")).to_lower()


func _world_props() -> Dictionary:
	var shots := 0
	var hostile := 0
	for s in _world.shots.shots:
		if s.alive:
			shots += 1
			if s.hostile:
				hostile += 1
	var rit := _world.ritual
	var ent := Vector2.ZERO
	if rit != null and rit.awake:
		ent = _world.torus.delta(_world.vigil.pos, rit.entity_pos)
	return {
		"death_marks": _world.fx.death_marks.size(), "entity_awake": rit != null and rit.awake,
		"entity_dx": ent.x, "entity_dy": ent.y, "last_spawned_acolyte_id": _last_acolyte_id,
		"acolytes": _alive_count(_world.acolytes.items), "grubs": _alive_count(_world.grubs.items),
		"geodes": _alive_count(_world.geodes.items), "shots": shots, "hostile_shots": hostile,
		"charges": _world.glass.charges, "paused_sim": _world.paused_sim, "sim_scale": _world.sim_scale,
		"hitstop_left": _world.hitstop_left, "time": _world.time,
	}


## What killed the Vigil, from the latest S6 death mark (FxLayer.death_marks). "entity" when the mark's
## drawn radius is over the death_big_killer_px tuning value (FxLayer.death_is_big, the same cutoff).
func _killer_props() -> Dictionary:
	var marks: Array[FxLayer.DeathMark] = _world.fx.death_marks
	var out := {"killer_kind": "none", "killer_dx": 0.0, "killer_dy": 0.0, "killer_on_screen": false, "death_marks": marks.size(),
		"death_outline": 0.0, "death_arrow": 0.0, "shooter_id": -1, "shooter_alive": false, "shooter_on_screen": false}
	if marks.is_empty():
		return out
	var m: FxLayer.DeathMark = marks.back()
	var d := _world.torus.delta(m.vigil_pos, m.killer_pos)
	out["killer_kind"] = "entity" if _world.fx.death_is_big(m) else "shot"
	out["killer_dx"] = d.x
	out["killer_dy"] = d.y
	out["killer_on_screen"] = _world.on_screen(m.killer_pos, 0.0)
	out["death_outline"] = _world.fx.death_outline_frac(m)   # 0..1 chalk draw progress; 1 at once after the delay under Reduced Motion
	out["death_arrow"] = _world.fx.death_arrow_frac(m)
	out["shooter_id"] = m.shooter_id
	var sh := _world.acolytes.find_by_id(m.shooter_id)
	out["shooter_alive"] = sh != null
	out["shooter_on_screen"] = sh != null and _world.on_screen(sh.pos, 0.0)
	return out


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
	if not _alive():
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
		# After a route change the cabinet is already freed and its connections went with it;
		# asking a freed object's signal logs an error (fail_on_errors scenarios across routes).
		if not is_instance_valid(sig.get_object()):
			continue
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
	if not _alive() or _world.stage == null:
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
			var limit := _world.torus.size.x + MAX_OFFSET          # absolute field coordinates: the whole torus plus a margin
			if not _in_range(p, limit):
				return "teleport: x and y must be finite numbers with |v| <= %d" % int(limit)
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
			var shooter := -1
			if args.has("acolyte_id"):
				shooter = _resolve_acolyte_id(args["acolyte_id"])
				if shooter < 0:
					return "shoot_vigil: acolyte_id must be an int >= 0, or \"last\" after a spawn acolyte step"
			var before := _world.shots.shots.size()
			_world.shots.fire_censer(from, dir, shooter)
			return "" if _world.shots.shots.size() > before else "shoot_vigil: the shot cap is reached"
		"kill_acolyte":
			var kid := _resolve_acolyte_id(args.get("acolyte_id", null))
			if kid < 0:
				return "kill_acolyte: acolyte_id must be an int >= 0, or \"last\" after a spawn acolyte step"
			var victim := _world.acolytes.find_by_id(kid)
			if victim == null:
				return "kill_acolyte: no live Acolyte with id %d" % kid
			_world.acolytes.kill(victim)   # the game's own death path; the squad purges it on its next tick
			return ""
		"kill_all":
			_kill_all()
			return ""
		"wake_entity":
			return _wake_entity()
		"place_entity":
			var eo := _vec_arg(args, "dx", "dy")
			if not _in_range(eo):
				return "place_entity: dx and dy must be finite numbers with |v| <= %d" % int(MAX_OFFSET)
			if _world.ritual == null or not _world.ritual.awake:
				return "the Sepulchre entity is not awake"
			_world.ritual.entity_pos = _world.torus.wrap(_world.vigil.pos + eo)
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


## Starts the Awakening through the ritual's public deposit(): one shard short of the last segment,
## then the deposit. The entity is awake after awakening_silence + stagger_window of sim time.
func _wake_entity() -> String:
	var rit := _world.ritual
	if rit == null or not rit.wakes:
		return "wake_entity: this Sepulchre does not wake"
	if rit.awake or rit.phase >= SepulchreRitual.Phase.AWAKENING:
		return "wake_entity: the entity is already waking or gone"
	rit.segments = _world.tuning.segments_total - 1
	rit.shard_points = _world.tuning.shards_per_segment - 1
	rit.deposit()
	return ""


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
			_last_acolyte_id = _world.acolytes.spawn(at).id
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


## An `acolyte_id` arg to an id: an int >= 0 (any id, live or not), or "last" (the latest probe spawn).
## -1 when the arg is malformed or "last" has nothing to resolve to.
func _resolve_acolyte_id(v: Variant) -> int:
	if typeof(v) == TYPE_STRING and str(v) == "last":
		return _last_acolyte_id
	if typeof(v) in [TYPE_INT, TYPE_FLOAT] and is_finite(float(v)) and floorf(float(v)) == float(v) and float(v) >= 0.0:
		return int(v)
	return -1


static func _int_arg(args: Dictionary, key: String) -> int:
	var v: Variant = args.get(key, 0)
	return int(v) if typeof(v) in [TYPE_INT, TYPE_FLOAT] else 0


static func _vec_arg(args: Dictionary, kx: String, ky: String) -> Vector2:
	var x: Variant = args.get(kx, 0.0)
	var y: Variant = args.get(ky, 0.0)
	var ok := typeof(x) in [TYPE_INT, TYPE_FLOAT] and typeof(y) in [TYPE_INT, TYPE_FLOAT]
	return Vector2(float(x), float(y)) if ok else Vector2(INF, INF)


static func _in_range(v: Vector2, limit: float = MAX_OFFSET) -> bool:
	return is_finite(v.x) and is_finite(v.y) and absf(v.x) <= limit and absf(v.y) <= limit
