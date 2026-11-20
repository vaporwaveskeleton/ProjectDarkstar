class_name AcolyteSquad
extends ArcadeLayer
## Acolytes — Censer Knights (GDD §8.5, SYS-001 §3). Pale spikes with a censer turret that swings
## to face you but lags 0.25 s behind the body (the teachable tell: lead your own movement and the
## censer fires where you were). Every shot has a 21-frame tell. When the Vigil is far they guard
## the Sepulchre and mine geodes at half the Vigil's rate. At the Guard phase more arrive.
## P2 stage switches (CabinetStage): censer-bell reinforcements from beyond the view edge, and
## escorts that trail laden Grubs instead of mining.

const HOLD_DISTANCE := 170.0   ## ✱ preferred range when engaging
const GUARD_ORBIT := 110.0     ## ✱ Litany Ring radius around the Sepulchre

class Acolyte:
	var pos: Vector2
	var vel: Vector2
	var hp: int
	var aim_history: Array[float] = []   ## desired angles, one per tick
	var turret: float = 0.0
	var cycle: float = 0.0
	var flash: float = 0.0
	var mine_timer: float = 0.0
	var alive: bool = true
	var slot: float = 0.0                 ## orbit angle around the Sepulchre
	var id: int = 0                       ## stable id, never reused (automation addresses Acolytes by it)
	var guard: bool = false               ## joined at the Guard phase: holds the Litany Ring, never escorts
	var escorting: bool = false           ## trails a laden Grub this tick (Neighbourhood never moves it)
	var hold: float = 0.0                 ## s of entry hold left: just entered the view, holds fire before its tell (SYS-001 §1.7)
	var in_view: bool = false             ## was inside the play view last tick (entry detection)
	var mining: bool = false              ## flying to or lancing a geode (CabinetStage.acolyte_mine)

## The view edges a reinforcement can come through, as inward unit normals (top, bottom, left, right).
const REINFORCE_EDGES: Array[Vector2] = [Vector2.DOWN, Vector2.UP, Vector2.RIGHT, Vector2.LEFT]

var items: Array[Acolyte] = []
var _guard_spawned := false
var _next_id: int = 1                     ## NOT reset in reset(), like GrubFlock's ids

# Censer bells (P2, CabinetStage.acolyte_reinforce_s). All sim time: frozen in hit-stop, slowed by slow-mo.
var _reinforce_clock := 0.0               ## s of play since the last bell interval closed
var _reinforce_left := -1.0               ## s of warning left; < 0 = no reinforcement pending
var _reinforce_edge := Vector2.ZERO       ## inward normal of the edge it comes through
var _reinforce_along := 0.0               ## 0..1 position along that edge (left→right / top→bottom)


func reset() -> void:
	items.clear()
	_guard_spawned = false
	_reinforce_clock = 0.0
	_reinforce_left = -1.0
	_reinforce_edge = Vector2.ZERO
	_reinforce_along = 0.0
	for i in world.stage.acolytes:
		spawn(world.neighbourhood.random_spot(world.tuning.size_acolyte_px))   # SYS-001 §1.7: in the box, off view


## Hurt radius: half the drawn extent, minus 1 (CabinetTuning.size_acolyte_px, SYS-001 §1.7).
func radius() -> float:
	return world.tuning.size_acolyte_px * 0.5 - 1.0


## The outermost drawn reach (spike tip / censer): sizes the S6 shooter ring.
func drawn_radius() -> float:
	return world.tuning.size_acolyte_px * 0.5


func spawn(at: Vector2) -> Acolyte:
	var a := Acolyte.new()
	a.pos = at
	a.hp = world.tuning.acolyte_hp
	a.cycle = world.tuning.acolyte_cycle * world.rng.randf_range(0.5, 1.0)
	a.slot = world.rng.randf() * TAU
	a.id = _next_id
	a.in_view = world.on_screen(at, 0.0)
	_next_id += 1
	items.append(a)
	return a


func on_guard_phase() -> void:
	if _guard_spawned:
		return
	_guard_spawned = true
	for i in world.stage.guard_acolytes:
		var a := spawn(world.torus.wrap(world.ritual.pos + Vector2.from_angle(TAU * i / maxi(1, world.stage.guard_acolytes)) * GUARD_ORBIT))
		a.guard = true
		world.fx.ring(a.pos, Look.c(Pal.CHOIR_4), world.fx_tuning.acolyte_guard_ring_radius)


func tick(delta: float) -> void:
	var t := world.tuning
	var lag_ticks := maxi(1, roundi(t.acolyte_turret_lag * Engine.physics_ticks_per_second))
	var escorted := {}                    # Grub id → true: at most one escort per laden Grub (this tick)
	for a in items:
		if not a.alive:
			continue
		a.flash = maxf(0.0, a.flash - delta * 5.0)
		# entry hold (SYS-001 §1.7): an Acolyte that enters the view holds fire before it starts its tell
		var in_view := world.on_screen(a.pos, 0.0)
		if in_view and not a.in_view:
			a.hold = t.acolyte_enter_hold_s
			a.cycle = maxf(a.cycle, t.acolyte_tell)
		a.in_view = in_view
		a.hold = maxf(0.0, a.hold - delta)
		var v := world.vigil
		var to_v := world.torus.delta(a.pos, v.pos)
		var engaged := v.alive and to_v.length() < t.acolyte_range and not world.ritual.awake
		var target := a.pos
		var aim_angle := to_v.angle()
		var geode: GeodeField.Geode = null
		a.escorting = false
		a.mining = false
		if engaged:
			# hold range and circle: approach if far, back off if close
			var radial := to_v.normalized()
			var dist := to_v.length()
			var want := radial * (dist - HOLD_DISTANCE) + radial.orthogonal() * 40.0
			target = world.torus.wrap(a.pos + want)
		else:
			var ward: GrubFlock.Grub = null
			if world.stage.acolyte_escort and not a.guard:
				ward = _escort_ward(a, escorted)
			if ward != null:
				a.escorting = true
				escorted[ward.id] = true
				target = _trail_point(a, ward)
			else:
				if world.stage.acolyte_mine and not a.guard:
					geode = _mine_target(a)
				if geode != null:
					a.mining = true
					var away := world.torus.delta(geode.pos, a.pos).normalized()
					target = world.torus.wrap(geode.pos + away * (geode.radius + t.acolyte_mine_standoff_px))
					aim_angle = world.torus.delta(a.pos, geode.pos).angle()
				elif a.guard or not world.neighbourhood.outside(world.ritual.pos):
					a.slot += delta * 0.4
					target = world.torus.wrap(world.ritual.pos + Vector2.from_angle(a.slot) * GUARD_ORBIT)
				elif v.alive:
					target = v.pos     # the Sepulchre is out of the box: an idle Acolyte closes on the Vigil instead
		var d := world.torus.delta(a.pos, target)
		var desired_vel := d.normalized() * minf(t.acolyte_speed, d.length() * 2.0)
		a.vel = a.vel.lerp(desired_vel, clampf(delta * 3.0, 0.0, 1.0))
		a.pos = world.torus.wrap(a.pos + a.vel * delta)
		# censer turret: aims where the Vigil WAS `turret_lag` seconds ago (SYS-001 §3, 🔒)
		a.aim_history.append(aim_angle)
		while a.aim_history.size() > lag_ticks:
			a.aim_history.remove_at(0)
		a.turret = a.aim_history[0]
		if engaged:
			# owner ruling (Q5, 2026-11-18): an Acolyte never fires from off-screen; its cycle waits until it is in the play view
			if in_view and a.hold <= 0.0:
				a.cycle -= delta
				if a.cycle <= 0.0:
					a.cycle = t.acolyte_cycle
					world.shots.fire_censer(a.pos + Vector2.from_angle(a.turret) * 8.0, Vector2.from_angle(a.turret), a.id)
		elif a.mining:
			_lance_geode(a, geode, delta)
		elif not a.escorting:
			_mine(a, delta)
	items.assign(items.filter(func(a: Acolyte) -> bool: return a.alive))
	_tick_reinforcements(delta)


## The nearest live geode within acolyte_mine_range_px (CabinetStage.acolyte_mine), or null.
func _mine_target(a: Acolyte) -> GeodeField.Geode:
	var best: GeodeField.Geode = null
	var best_d := world.tuning.acolyte_mine_range_px * world.tuning.acolyte_mine_range_px
	for g in world.geodes.items:
		if not g.alive:
			continue
		var dd := world.torus.distance_sq(a.pos, g.pos)
		if dd < best_d:
			best_d = dd
			best = g
	return best


## Mining Acolyte: once within reach of its geode it lances it on its normal fire cycle (acolyte_cycle),
## through the same GeodeField.lance_hit the Vigil's bolts use. The shards are ordinary loose glass.
func _lance_geode(a: Acolyte, g: GeodeField.Geode, delta: float) -> void:
	var reach := g.radius + world.tuning.acolyte_mine_standoff_px + radius()
	if world.torus.distance(a.pos, g.pos) > reach:
		return
	a.cycle -= delta
	if a.cycle <= 0.0:
		a.cycle = world.tuning.acolyte_cycle
		world.geodes.lance_hit(g, false)


## Living Acolytes, the guard ring included (the reinforcement cap counts them all).
func living_count() -> int:
	var n := 0
	for a in items:
		if a.alive:
			n += 1
	return n


# --- Censer bells: Acolyte reinforcements (P2, PM Q-T105) -------------------------------------
# The interval clock runs on sim time (this tick's delta: frozen in hit-stop, slowed by slow-mo) and
# only while the Vigil is alive and under control (not dead, not on the READY card or after the
# stage ends). A bell rung before the Vigil died still brings its Acolyte. Off when the stage's
# acolyte_reinforce_s is 0: then Acolytes never respawn.

func _tick_reinforcements(delta: float) -> void:
	var st := world.stage
	if st.acolyte_reinforce_s <= 0.0:
		return
	if not st.reinforce_after_wake and world.ritual.awake:   # the bells fall silent at the wake
		_reinforce_left = -1.0
		_reinforce_edge = Vector2.ZERO
		return
	if _reinforce_left >= 0.0:
		_reinforce_left -= delta
		if _reinforce_left <= 0.0:
			var at := _entry_point()
			_reinforce_left = -1.0
			_reinforce_edge = Vector2.ZERO
			if living_count() < st.acolyte_cap:   # the guard ring may have filled the cap meanwhile
				spawn(at)
	if not (world.vigil.alive and world.vigil.input_enabled):
		return
	_reinforce_clock += delta
	if _reinforce_clock < st.acolyte_reinforce_s:
		return
	_reinforce_clock -= st.acolyte_reinforce_s
	if _reinforce_left < 0.0 and living_count() < st.acolyte_cap:
		_ring_bell()


## Warning start: choose the edge and the spot along it (spawn decisions: world.rng), ring the bell.
func _ring_bell() -> void:
	_reinforce_edge = REINFORCE_EDGES[world.rng.randi_range(0, REINFORCE_EDGES.size() - 1)]
	_reinforce_along = world.rng.randf()
	_reinforce_left = world.tuning.reinforce_tell_s
	world.sfx(&"censer_bell")


## Read-only schedule for the tell (fx_layer draws it; never writes). True during the warning.
func reinforcement_pending() -> bool:
	return _reinforce_left >= 0.0


## Sim seconds of warning left (0 when nothing is pending).
func reinforcement_time_left() -> float:
	return maxf(0.0, _reinforce_left) if reinforcement_pending() else 0.0


## World-space arrival point: `reinforce_entry_px` outside the chosen edge of the CURRENT view, at
## the chosen spot along it. It follows the camera, so the Acolyte always arrives just off-view.
## Vector2.ZERO when nothing is pending.
func reinforcement_entry() -> Vector2:
	return _entry_point() if reinforcement_pending() else Vector2.ZERO


func _entry_point() -> Vector2:
	var half := world.view_size * 0.5
	var n := _reinforce_edge
	var tangent := n.orthogonal().abs()
	var depth := absf(n.x) * half.x + absf(n.y) * half.y + world.tuning.reinforce_entry_px
	var span := tangent.x * half.x + tangent.y * half.y
	return world.torus.wrap(world.view_centre - n * depth + tangent * (_reinforce_along * 2.0 - 1.0) * span)


## Unit normal of the view edge it comes through, pointing into the view (ZERO when none pending).
func reinforcement_edge() -> Vector2:
	return _reinforce_edge if reinforcement_pending() else Vector2.ZERO


# --- Escort (P2, CabinetStage.acolyte_escort) --------------------------------------------------

## The nearest laden Grub no other Acolyte escorts this tick, or null.
func _escort_ward(a: Acolyte, taken: Dictionary) -> GrubFlock.Grub:
	var best: GrubFlock.Grub = null
	var best_d := INF
	for g in world.grubs.items:
		if not g.alive or not g.carrying or taken.has(g.id):
			continue
		var d := world.torus.distance_sq(a.pos, g.pos)
		if d < best_d:
			best_d = d
			best = g
	return best


## `escort_distance` behind the Grub (along its heading; from the Acolyte's side when it is still).
func _trail_point(a: Acolyte, g: GrubFlock.Grub) -> Vector2:
	var back := -g.vel.normalized() if g.vel.length() > 1.0 else world.torus.delta(g.pos, a.pos).normalized()
	return world.torus.wrap(g.pos + back * world.tuning.escort_distance)


## Acolytes mine too, at 50 % of the Vigil's lance rate (SYS-001 §3).
func _mine(a: Acolyte, delta: float) -> void:
	a.mine_timer -= delta
	if a.mine_timer > 0.0:
		return
	a.mine_timer = 2.0 / world.tuning.lance_rate
	var g := world.geodes.hit_test(a.pos, 48.0)
	if g != null:
		world.geodes.lance_hit(g, false)


func telling(a: Acolyte) -> bool:
	return a.hold <= 0.0 and a.cycle <= world.tuning.acolyte_tell


## The live Acolyte with this id, or null (killed, despawned, never existed, or id < 0).
func find_by_id(id: int) -> Acolyte:
	if id < 0:
		return null
	for a in items:
		if a.alive and a.id == id:
			return a
	return null


func hit_test(p: Vector2, r: float) -> Acolyte:
	for a in items:
		if a.alive and world.torus.distance_sq(p, a.pos) <= (radius() + r) * (radius() + r):
			return a
	return null


func lance_test(p: Vector2) -> bool:
	var a := hit_test(p, 1.0)
	if a == null:
		return false
	a.hp -= 1
	a.flash = 1.0
	world.sfx(&"geode_hit", -9.0)
	if a.hp <= 0:
		kill(a)
	return true


func kill(a: Acolyte) -> void:
	a.alive = false
	world.award(world.tuning.score_acolyte, a.pos)
	world.sfx(&"acolyte_die", -2.0)
	world.fx.burst(a.pos, Look.c(Pal.CHOIR_4), world.fx_tuning.acolyte_death_burst_count, world.fx_tuning.acolyte_death_burst_speed)
	world.fx.ring(a.pos, Look.c(Pal.CHOIR_3), world.fx_tuning.acolyte_death_ring_radius)
	world.shake(world.fx_tuning.acolyte_death_shake_amp, world.fx_tuning.acolyte_death_shake_dur)


func _draw() -> void:
	if world == null:
		return
	var size := world.tuning.size_acolyte_px
	var u := size / 15.0                   # drawing scale: the line art below is laid out for a 15 px extent
	for a in items:
		if not visible_at(a.pos, size + 5.0):
			continue
		var c := world.to_screen(a.pos).round()
		var body := Look.c(Pal.CHOIR_5) if a.flash > 0.4 else Look.c(Pal.CHOIR_3)
		var spike := PackedVector2Array([c + Vector2(0, -7) * u, c + Vector2(5, 7) * u, c + Vector2(-5, 7) * u])
		Pal.glow_polyline(self, spike, body, Look.c(Pal.CHOIR_1))
		# inner robe fold and hem: more line detail, never a solid fill
		draw_line((c + Vector2(0, -3) * u).round(), (c + Vector2(0, 7) * u).round(), Look.c(Pal.CHOIR_2))
		draw_line((c + Vector2(-3, 4) * u).round(), (c + Vector2(3, 4) * u).round(), Look.c(Pal.CHOIR_2))
		draw_rect(Rect2((c + Vector2(-1, -4) * u).round(), Vector2(2, 2)), Look.c(Pal.BONE_4))              # the pale face
		var arm := (c + Vector2.from_angle(a.turret) * size * 0.37).round()
		draw_line(c, arm, Look.c(Pal.CHOIR_2))
		var tell := telling(a) and world.vigil.alive and world.torus.distance(a.pos, world.vigil.pos) < world.tuning.acolyte_range
		draw_circle(arm, size * 0.13, Look.c(Pal.SIGNAL) if tell else Look.c(Pal.CHOIR_4))
