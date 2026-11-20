class_name CabinetAutopilot
extends Node
## A competent, unremarkable Vigil pilot for the attract-mode demo loop (WARP-001 W0-03), visual
## captures, and the end-to-end tests that prove the Act 0 shift can be won. It reads the world
## like a player would and writes the Vigil's scripted inputs; it never touches rules.
## Every tick it picks a goal (where to go, what to shoot), then a safety layer bends the move:
## sidestep censer shots that would hit, keep moving across an Acolyte's line before it fires, and
## keep the hunting entity at arm's length.
## Goals, by stage kind:
## - cold Sepulchre (clear it): shoot Acolytes and laden Grubs, throw Charges at the Sepulchre.
## - waking Sepulchre (unmake the entity): let it build — never knock modules off or shoot laden
##   Grubs; fill the magazine, then mine for the Choir, give the Grubs room and put down a Grub
##   stuck fleeing — then dump the magazine into the entity while it forms, kite it, throw each
##   Charge as it closes, and rebuild the magazine away from it: over-fire geodes (it eats the ones
##   it reaches and heals) and chase loose glass anywhere (no Grub races it after the wake).
## Own glass is mined calmly (it stops before the over-fire window fills).
## The bot's own numbers below are behaviour, not game rules (✱, autopilot only).

const THREAT_RANGE := 260.0       ## px ✱ shoot an Acolyte nearer than this
const GRUB_RANGE := 200.0         ## px ✱ shoot a laden Grub nearer than this
const THROW_RANGE := 260.0        ## px ✱ throw a Charge at a target nearer than this
const THROW_CD := 0.5             ## s ✱ between the bot's Charge throws
const ENTITY_KEEP := 200.0        ## px ✱ kite the hunting entity at about this distance
const DODGE_LOOKAHEAD := 0.9      ## s ✱ how far ahead a censer shot's path is checked
const DODGE_MARGIN := 9.0         ## px ✱ extra clearance beyond the Vigil's radius
const SHOT_DODGE_WEIGHT := 2.5    ## ✱ how hard a shot on course pushes the Vigil aside
const LINE_TELL := 0.45           ## s ✱ an Acolyte this close to firing gets strafed
const STANDOFF_MINE := 190.0      ## px ✱ mine from here when the glass is for the Choir (Grubs flee the lamp)
const GRUB_ROOM := 90.0           ## px ✱ beyond the Grubs' flee radius the bot keeps clear while the Choir builds
const FEED_ENOUGH := 3            ## ✱ loose shards that keep the Grubs busy: the bot stops mining for them
const CULL_RANGE := 600.0         ## px ✱ how far the bot goes to put down a stuck Grub
const SEPULCHRE_FAR := 1000.0      ## px ✱ farther than this from the Sepulchre the bot heads for it (the field is 65,536 px wide; Grubs would carry glass the whole way)
const SEPULCHRE_NEAR := 450.0       ## px ✱ …and keeps heading for it until it is this close (hysteresis: no tug-of-war with the geodes)

@export var world: ArcadeWorld
var enabled := false
var _launch_cd := 0.0
var _strafe := 1.0                ## which way the bot circles (flips now and then, deterministically)
var _strafe_t := 0.0
var _homing := false              ## heading for a far Sepulchre (hysteresis between SEPULCHRE_FAR and SEPULCHRE_NEAR)


func _physics_process(delta: float) -> void:
	if not enabled or world == null or world.stage == null:
		return
	var v := world.vigil
	v.use_scripted = true
	v.scripted_fire = false
	v.scripted_move = Vector2.ZERO
	_launch_cd = maxf(0.0, _launch_cd - delta)
	_strafe_t += delta
	if _strafe_t > 2.3:
		_strafe_t = 0.0
		_strafe = -_strafe
	if not v.alive:
		return
	var t := world.torus
	var r := world.ritual
	var wake_goal := r.wakes and world.stage.goal == CabinetStage.Goal.UNMAKE_ENTITY
	var forming := r.phase == SepulchreRitual.Phase.AWAKENING
	var hunting := r.awake
	var building := wake_goal and not hunting and not forming and r.phase != SepulchreRitual.Phase.UNMADE
	var full := world.glass.charges >= world.tuning.magazine

	var move := Vector2.ZERO
	var aim := Vector2.ZERO
	var fire := false

	# 1 — threats: the nearest Acolyte in range; a laden Grub when its glass is ours to take
	var threat := _nearest_acolyte(v.pos, THREAT_RANGE)
	var culling := false
	if threat == Vector2.INF and building:
		# a Grub that fled the lamp and kept its claim runs away for good (it never re-seeks): put
		# it down, so the Sepulchre births a fresh one
		threat = _nearest_stuck_grub(v, CULL_RANGE)
		culling = threat != Vector2.INF
	if threat == Vector2.INF and not building:
		threat = _nearest_laden_grub(v.pos, GRUB_RANGE)
	if threat != Vector2.INF:
		aim = t.delta(v.pos, threat)
		fire = true
		if culling:
			move = aim.normalized() * clampf((aim.length() - 120.0) / 60.0, -1.0, 1.0)
		elif aim.length() > 140.0 and not building:
			move = aim.normalized()
		else:
			move = aim.normalized().orthogonal() * _strafe   # circle it, never sit on its line

	# 2 — Charges
	var target: Variant = r.charge_target()
	if target != null and world.glass.charges > 0 and not building:
		var to_t := t.delta(v.pos, target as Vector2)
		# a cold Sepulchre is cleared with a full magazine in hand (a0_2: mine first, then push to it); a waking one as soon as 3 are held
		var keen := hunting or forming or (world.glass.charges >= (2 if not wake_goal else 3))
		if keen:
			if to_t.length() < THROW_RANGE and _launch_cd <= 0.0 and _line_clear(v.pos, target as Vector2):
				v.scripted_aim = to_t
				world.glass.launch(v.pos, to_t)
				_launch_cd = THROW_CD
			elif (threat == Vector2.INF or not wake_goal) and not hunting:   # armed and clearing a cold Sepulchre: press on, shooting on the way
				move = to_t.normalized() * clampf((to_t.length() - 120.0) / 60.0, -1.0, 1.0)

	# 2b — far from the Sepulchre: head for it by world knowledge and mine on the way. The Neighbourhood keeps
	# geodes, glass and Grubs round the Vigil, so working beside the Sepulchre keeps the Grubs' trips short.
	var to_sep := t.delta(v.pos, r.pos)
	if hunting or r.phase == SepulchreRitual.Phase.UNMADE or to_sep.length() < SEPULCHRE_NEAR:
		_homing = false
	elif to_sep.length() > SEPULCHRE_FAR:
		_homing = true
	if _homing and move == Vector2.ZERO:
		move = to_sep.normalized()

	# 3 — glass on the field, while the magazine has room
	if move == Vector2.ZERO and not full:
		var shard := _nearest_free_shard(v.pos)
		if shard != Vector2.INF and (hunting or t.distance(v.pos, shard) < 400.0):   # after the wake no Grub races it
			move = t.delta(v.pos, shard).normalized()

	# 4 — mine. Calm fire for our own glass; with a full magazine on a waking stage the glass is the
	# Choir's: over-fire from a stand-off (Grubs flee the lamp), and stop while loose glass waits.
	if threat == Vector2.INF:
		var feed_choir := building and full
		# hunting, mine away from the entity: it eats the geode it reaches and heals
		var g := _nearest_geode(v.pos, r.entity_pos, ENTITY_KEEP + 60.0) if hunting else _nearest_geode(v.pos)
		if feed_choir and world.glass.free_shards().size() >= FEED_ENOUGH:
			g = null       # the Grubs have glass to carry: stay out of their way
		if g != null:
			var to_g := t.delta(v.pos, g.pos)
			aim = to_g
			var in_flight := ceili(to_g.length() / world.tuning.lance_speed * world.tuning.lance_rate)
			# feeding the Choir, or starved after the wake (no Grub competes then), it over-fires on
			# purpose: a detonation frees 4–6 glass at once, more and sooner than calm mining
			var hot := not (feed_choir or hunting) and _recent_hits(g) + in_flight >= world.tuning.overfire_hits - 1
			fire = not hot and to_g.length() < 280.0
			if move == Vector2.ZERO:
				var stand_d := g.radius + (STANDOFF_MINE if feed_choir else 50.0)
				move = to_g.normalized() * clampf((to_g.length() - stand_d) / 60.0, -1.0, 1.0)
	# while the Choir builds, never put a bolt into a Grub
	if fire and building and not culling and _grub_on_line(v.pos, aim):
		fire = false

	# 5 — safety: shots on course, lines about to fire, the entity
	var safe := _shot_dodge(v) + _line_strafe(v)
	if hunting:
		safe += _kite(v)
	if building:
		safe += _give_grubs_room(v)
	if v.shield > 0.3:
		safe = Vector2.ZERO
	if safe != Vector2.ZERO:
		move = move.limit_length(1.0) * 0.5 + safe
	v.scripted_move = move.limit_length(1.0)
	if aim != Vector2.ZERO:
		v.scripted_aim = aim
	v.scripted_fire = fire


## Sidestep every censer shot whose path passes the Vigil within DODGE_LOOKAHEAD seconds.
func _shot_dodge(v: VigilShip) -> Vector2:
	var out := Vector2.ZERO
	var t := world.torus
	var hit_r := v.radius + ShotLayer.HOSTILE_SHOT_RADIUS + DODGE_MARGIN
	for s in world.shots.shots:
		if not s.alive or not s.hostile:
			continue
		var rel := t.delta(v.pos, s.pos)
		if rel.length() > 320.0:
			continue
		var w := s.vel - v.vel
		var w2 := w.length_squared()
		if w2 < 1.0:
			continue
		var tc := -rel.dot(w) / w2
		if tc < 0.0 or tc > DODGE_LOOKAHEAD:
			continue
		var miss := rel + w * tc            # the shot, relative to the Vigil, at closest approach
		if miss.length() > hit_r:
			continue
		var side := -miss
		if side.length() < 0.5:
			side = s.vel.orthogonal()
		side = side.normalized()
		# move across the shot's path, not along it
		side = (side - s.vel.normalized() * side.dot(s.vel.normalized())).normalized() if absf(side.dot(s.vel.normalized())) < 0.99 else s.vel.normalized().orthogonal()
		out += side * SHOT_DODGE_WEIGHT * (1.2 - tc / DODGE_LOOKAHEAD)
	return out


## An engaged Acolyte about to fire aims where the Vigil was a moment ago: keep moving across it.
func _line_strafe(v: VigilShip) -> Vector2:
	var out := Vector2.ZERO
	var t := world.torus
	for a in world.acolytes.items:
		if not a.alive or a.cycle > LINE_TELL:
			continue
		var from_a := t.delta(a.pos, v.pos)
		if from_a.length() > world.tuning.acolyte_range or not world.on_screen(a.pos, 0.0):
			continue
		var across := from_a.normalized().orthogonal()
		if v.vel.dot(across) < 0.0:
			across = -across                  # keep the way it is already going
		out += across * 0.8
	return out


## Keep the hunting entity at ENTITY_KEEP: back off and circle when it is close.
func _kite(v: VigilShip) -> Vector2:
	var r := world.ritual
	var away := world.torus.delta(r.entity_pos, v.pos)
	var d := away.length()
	if d > ENTITY_KEEP + 60.0:
		return Vector2.ZERO
	var n := away.normalized() if d > 0.1 else Vector2.UP
	var push := clampf((ENTITY_KEEP + 60.0 - d) / 60.0, 0.0, 3.0)
	return (n * 1.2 + n.orthogonal() * _strafe * 0.6) * push


## While the Choir builds: Grubs flee the lamp and carry nothing, so stay out of their way.
func _give_grubs_room(v: VigilShip) -> Vector2:
	var out := Vector2.ZERO
	var room := world.tuning.grub_flee_radius + GRUB_ROOM
	for g in world.grubs.items:
		if not g.alive or g.carrying or _stuck(g, v):
			continue
		var away := world.torus.delta(g.pos, v.pos)
		var d := away.length()
		if d < room and d > 0.1:
			out += away / d * (room - d) / GRUB_ROOM
	return out


## No geode, Grub or Acolyte sits on the straight line from `from` to `to` (they eat Charges).
func _line_clear(from: Vector2, to: Vector2) -> bool:
	var t := world.torus
	var seg := t.delta(from, to)
	var len := seg.length()
	if len < 1.0:
		return true
	var dir := seg / len
	for g in world.geodes.items:
		if g.alive and _blocks(t.delta(from, g.pos), dir, len, g.radius + GlassField.CHARGE_RADIUS + 2.0):
			return false
	for gr in world.grubs.items:
		if gr.alive and _blocks(t.delta(from, gr.pos), dir, len, world.grubs.radius() + GlassField.CHARGE_RADIUS + 2.0):
			return false
	for a in world.acolytes.items:
		if a.alive and _blocks(t.delta(from, a.pos), dir, len, world.acolytes.radius() + GlassField.CHARGE_RADIUS + 2.0):
			return false
	return true


## A Grub sits on the Arc-Lance's line (its full reach) from `from` along `dir`.
func _grub_on_line(from: Vector2, dir: Vector2) -> bool:
	if dir == Vector2.ZERO:
		return false
	var d := dir.normalized()
	var reach := world.tuning.lance_speed * world.tuning.lance_life
	for gr in world.grubs.items:
		if gr.alive and _blocks(world.torus.delta(from, gr.pos), d, reach, world.grubs.radius() + 6.0):
			return true
	return false


func _blocks(rel: Vector2, dir: Vector2, len: float, r: float) -> bool:
	var along := rel.dot(dir)
	if along < 0.0 or along > len:
		return false
	return absf(rel.cross(dir)) < r


func _nearest_acolyte(from: Vector2, within: float) -> Vector2:
	var best := Vector2.INF
	var bd := within
	for a in world.acolytes.items:
		if not a.alive:
			continue
		var d := world.torus.distance(from, a.pos)
		if d < bd:
			bd = d
			best = _lead(from, a.pos, a.vel)
	return best


func _nearest_laden_grub(from: Vector2, within: float) -> Vector2:
	var best := Vector2.INF
	var bd := within
	for g in world.grubs.items:
		if g.alive and g.carrying:
			var d := world.torus.distance(from, g.pos)
			if d < bd:
				bd = d
				best = _lead(from, g.pos, g.vel)
	return best


func _nearest_free_shard(from: Vector2) -> Vector2:
	var best := Vector2.INF
	var bd := INF
	for s in world.glass.shards:
		if s.alive and not s.carried:
			var d := world.torus.distance_sq(from, s.pos)
			if d < bd:
				bd = d
				best = s.pos
	return best


## The nearest live geode to `from`, skipping any within `clear` of `avoid`.
func _nearest_geode(from: Vector2, avoid: Vector2 = Vector2.INF, clear: float = 0.0) -> GeodeField.Geode:
	var best: GeodeField.Geode = null
	var bd := INF
	for g in world.geodes.items:
		if not g.alive or (avoid.is_finite() and world.torus.distance(g.pos, avoid) < clear):
			continue
		var d := world.torus.distance_sq(from, g.pos)
		if d < bd:
			bd = d
			best = g
	return best


## Hits on `g` still inside the over-fire window (GeodeField only prunes its list on the next hit, so the raw list goes stale).
func _recent_hits(g: GeodeField.Geode) -> int:
	var n := 0
	for x in g.recent:
		if world.time - x <= world.tuning.overfire_window:
			n += 1
	return n


## Where to aim a bolt at a mover: where it will be when the bolt arrives (one look ahead).
func _lead(from: Vector2, at: Vector2, vel: Vector2) -> Vector2:
	var flight := world.torus.distance(from, at) / world.tuning.lance_speed
	return world.torus.wrap(at + (vel - world.vigil.vel * 0.5) * flight)


## A Grub stuck fleeing: in FLEE although the lamp is out of its flee radius (GrubFlock keeps the
## state while its claimed shard lives, so it never turns back).
func _stuck(g: GrubFlock.Grub, v: VigilShip) -> bool:
	return g.state == GrubFlock.State.FLEE and not g.carrying \
			and world.torus.distance(g.pos, v.pos) > world.tuning.grub_flee_radius + 10.0


func _nearest_stuck_grub(v: VigilShip, within: float) -> Vector2:
	var best := Vector2.INF
	var bd := within
	for g in world.grubs.items:
		if g.alive and _stuck(g, v):
			var d := world.torus.distance(v.pos, g.pos)
			if d < bd:
				bd = d
				best = _lead(v.pos, g.pos, g.vel)
	return best
