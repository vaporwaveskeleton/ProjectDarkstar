class_name GrubFlock
extends ArcadeLayer
## Oubliette Grubs (GDD §8.5, SYS-001 §3): harmless larvae that never attack. They claim free
## Mourning Glass, carry it to the Sepulchre and deposit it — every deposit builds the god.
## They flee the Vigil's lamp unless they are carrying (devotion beats fear), mourn a lost
## deposit (keening), and the Sepulchre births a replacement for every Grub you kill.
## P2 stage switches (CabinetStage): grubs_after_wake keeps the births going after the wake;
## grub_pilfer makes them snatch nearby loose glass.

const SEEK_SPEED := 160.0     ## ✱ between the carry (130) and flee (190) speeds of SYS-001 §3

enum State { SEEK, CARRY, FLEE, IDLE, WORSHIP, INTERCEPT }

class Grub:
	var pos: Vector2
	var vel: Vector2
	var hp: int
	var state: int = 0
	var shard: GlassField.Shard = null
	var carrying: bool = false
	var wiggle: float = 0.0
	var flash: float = 0.0
	var alive: bool = true
	var id: int = 0
	var think: float = 0.0

var items: Array[Grub] = []
var _respawn_timers: Array[float] = []
var _next_id := 1


func reset() -> void:
	items.clear()
	_respawn_timers.clear()
	for i in world.stage.grubs:
		_spawn(world.neighbourhood.random_spot(world.tuning.size_grub_px))


## Hurt radius: half the drawn extent, minus 1 (CabinetTuning.size_grub_px, SYS-001 §1.7).
func radius() -> float:
	return world.tuning.size_grub_px * 0.5 - 1.0


func _spawn(at: Vector2) -> Grub:
	var g := Grub.new()
	g.pos = world.torus.wrap(at)
	g.hp = world.tuning.grub_hp
	g.id = _next_id
	_next_id += 1
	g.wiggle = world.rng.randf() * TAU
	items.append(g)
	return g


func tick(delta: float) -> void:
	var t := world.tuning
	for g in items:
		if not g.alive:
			continue
		g.wiggle += delta * 8.0
		g.flash = maxf(0.0, g.flash - delta * 5.0)
		g.think -= delta
		var to_vigil := world.torus.delta(g.pos, world.vigil.pos)
		var scared := world.vigil.alive and to_vigil.length() < t.grub_flee_radius and not g.carrying
		if world.ritual.awake:
			g.state = State.WORSHIP
		elif not g.carrying and _charge_to_intercept(g) != null:
			g.state = State.INTERCEPT           # F-3: dive into a Charge flying at the Sepulchre (devotion beats fear)
		elif scared:
			g.state = State.FLEE
		elif g.carrying:
			g.state = State.CARRY
		elif g.shard == null or not g.shard.alive or g.shard.carried:
			g.shard = null
			if g.think <= 0.0:
				g.think = 0.4
				_claim(g)
			g.state = State.SEEK if g.shard != null else State.IDLE
		else:
			if world.stage.grub_pilfer and g.think <= 0.0:
				g.think = 0.4
				_pilfer(g)          # P2: a nearer loose shard beats the one it is heading for
			g.state = State.SEEK    # still holds a live claim: back to it once the lamp has passed (was stuck in FLEE)
		var target := g.pos
		var speed := SEEK_SPEED
		match g.state:
			State.FLEE:
				target = world.torus.wrap(g.pos - to_vigil.normalized() * 80.0)
				speed = t.grub_speed_flee
			State.CARRY:
				target = world.ritual.pos
				speed = t.grub_speed_carry
			State.SEEK:
				target = g.shard.pos
			State.IDLE:
				# shadow the Vigil: circle it at about grub_shadow_radius, each Grub with its own phase, direction and radius
				var ring := t.grub_shadow_radius + t.grub_shadow_band * sin(g.id * 1.7)
				var dir := 1.0 if g.id % 2 == 0 else -1.0
				target = world.torus.wrap(world.vigil.pos + Vector2.from_angle(g.id * 2.4 + dir * world.time * 0.35) * ring)
				speed = clampf(60.0 + 1.5 * world.torus.distance(g.pos, target), 70.0, 200.0)   # catches up with a Vigil on the move, settles to a slow orbit
			State.INTERCEPT:
				var c := _charge_to_intercept(g)
				if c != null:
					target = world.torus.wrap(c.pos + c.dir * 40.0)     # aim a little ahead of the Charge
				speed = t.grub_intercept_speed
			State.WORSHIP:
				if not world.neighbourhood.outside(world.ritual.pos):
					target = world.torus.wrap(world.ritual.pos + Vector2.from_angle(world.time * 0.6 + g.id * 1.3) * 70.0)
				speed = 90.0
		var d := world.torus.delta(g.pos, target)
		var want := d.normalized() * speed if d.length() > 2.0 else Vector2.ZERO
		g.vel = g.vel.lerp(want, clampf(delta * t.grub_ease_rate, 0.0, 1.0))
		g.pos = world.torus.wrap(g.pos + g.vel * delta)
		if g.state == State.SEEK and g.shard != null and world.torus.distance(g.pos, g.shard.pos) < radius() + 4.0:
			g.carrying = true
			g.shard.carried = true
		if g.carrying and g.shard != null:
			g.shard.pos = g.pos
			if world.ritual.accepts_deposits() and world.torus.distance(g.pos, world.ritual.pos) < world.ritual.radius:
				g.shard.alive = false
				g.shard = null
				g.carrying = false
				world.ritual.deposit()
	items.assign(items.filter(func(g: Grub) -> bool: return g.alive))
	# the Sepulchre births replacements while it is still a Sepulchre
	for i in range(_respawn_timers.size() - 1, -1, -1):
		_respawn_timers[i] -= delta
		if _respawn_timers[i] <= 0.0:
			_respawn_timers.remove_at(i)
			if not world.ritual.awake or world.stage.grubs_after_wake:   # P2: some stages keep birthing after the wake
				_spawn(world.neighbourhood.random_spot(world.tuning.size_grub_px))   # SYS-001 §1.7: births land in the box, off view


## F-3 (Sinibomb-intercept analogue): the nearest Charge in flight at the not-yet-awake Sepulchre
## within grub_intercept_range of `g`, or null. Once the entity wakes the Grubs worship instead.
func _charge_to_intercept(g: Grub) -> GlassField.Charge:
	var r := world.ritual
	if r.awake or r.phase >= SepulchreRitual.Phase.AWAKENING or r.segments <= 0:
		return null
	var range_px := world.tuning.grub_intercept_range
	var best: GlassField.Charge = null
	var best_d := range_px
	for c in world.glass.charges_flying:
		if not c.alive:
			continue
		var d := world.torus.distance(g.pos, c.pos)
		if d < best_d:
			best_d = d
			best = c
	return best


## F-3: a Grub took a Charge meant for the Sepulchre. The Grub dies (no score, no service-record kill:
## it chose it), the Charge is lost, and the cabinet says so (CAB_CAPTION_GRUB_INTERCEPT).
func sacrifice(g: Grub) -> void:
	kill(g, false)
	world.sfx(&"grub_die", -4.0)
	world.fx.burst(g.pos, Look.c(Pal.CHOIR_4), world.fx_tuning.grub_death_burst_count, world.fx_tuning.grub_death_burst_speed)
	world.caption.emit("CAB_CAPTION_GRUB_INTERCEPT")


func _claim(g: Grub) -> void:
	if world.stage.grub_pilfer and _pilfer(g):
		return
	var best: GlassField.Shard = null
	var best_d := INF
	for s in world.glass.free_shards():
		var dd := world.torus.distance_sq(g.pos, s.pos)
		if dd < best_d:
			best_d = dd
			best = s
	if best != null:
		best.claimed_by = g.id
		g.shard = best


## P2 pilfer (CabinetStage.grub_pilfer): claim the nearest loose shard (unclaimed, not in the Vigil's
## magnet) within grub_pilfer_radius when it is nearer than the shard this Grub already heads for,
## releasing that one. Pickup, carry, deposit and the drop on death are the ordinary Grub rules.
## Returns true when it claimed one.
func _pilfer(g: Grub) -> bool:
	var r := world.tuning.grub_pilfer_radius
	var best_d := r * r
	if g.shard != null and g.shard.alive and not g.shard.carried:
		best_d = minf(best_d, world.torus.distance_sq(g.pos, g.shard.pos))
	var best: GlassField.Shard = null
	for s in world.glass.shards:
		if not world.glass.pilferable(s):
			continue
		var dd := world.torus.distance_sq(g.pos, s.pos)
		if dd < best_d:
			best_d = dd
			best = s
	if best == null:
		return false
	if g.shard != null and g.shard.claimed_by == g.id:
		g.shard.claimed_by = 0
	best.claimed_by = g.id
	g.shard = best
	return true


## A re-wrapped loose shard: whoever claimed it lets it go (Neighbourhood).
func release_shard(s: GlassField.Shard) -> void:
	s.claimed_by = 0
	for g in items:
		if g.shard == s and not g.carrying:
			g.shard = null
			g.think = 0.0


## A re-wrapped empty-handed Grub drops its claim on a shard it has not picked up yet (Neighbourhood).
func release_claim(g: Grub) -> void:
	if g.shard != null and not g.carrying:
		if g.shard.claimed_by == g.id:
			g.shard.claimed_by = 0
		g.shard = null
		g.think = 0.0


func hit_test(p: Vector2, r: float) -> Grub:
	for g in items:
		if g.alive and world.torus.distance_sq(p, g.pos) <= (radius() + r) * (radius() + r):
			return g
	return null


## A lance bolt at `p`: damages the first Grub there. Returns true if it hit one.
func lance_test(p: Vector2) -> bool:
	var g := hit_test(p, 1.0)
	if g == null:
		return false
	g.hp -= 1
	g.flash = 1.0
	if g.hp <= 0:
		kill(g, true)
	return true


func kill(g: Grub, by_player: bool) -> void:
	g.alive = false
	if g.shard != null:
		if g.carrying:
			g.shard.carried = false
			world.sfx(&"grub_keen", -4.0)     # a deposit dies: the Choir mourns (SYS-001 §3)
		g.shard.claimed_by = 0
		g.shard.vel = g.vel * 0.3
		g.shard = null
	if by_player:
		if world.record != null:
			world.record.grubs_destroyed += 1
		world.award(world.tuning.score_grub, g.pos)
		world.sfx(&"grub_die", -4.0)
		world.fx.burst(g.pos, Look.c(Pal.CHOIR_4), world.fx_tuning.grub_death_burst_count, world.fx_tuning.grub_death_burst_speed)
	_respawn_timers.append(world.tuning.grub_respawn)


func _draw() -> void:
	if world == null:
		return
	var size := world.tuning.size_grub_px
	for g in items:
		if not visible_at(g.pos, size + 4.0):
			continue
		var c := world.to_screen(g.pos)
		var heading := g.vel.normalized() if g.vel.length() > 1.0 else Vector2.RIGHT
		var side := heading.orthogonal()
		var body := Look.c(Pal.CHOIR_5) if g.flash > 0.4 else Look.c(Pal.CHOIR_3)
		# four line-art segments, head to tail, spanning the drawn extent (size_grub_px, SYS-001 §1.7)
		var r0 := size * 0.22
		var r_last := size * 0.1
		var span := size - r0 - r_last
		for k in 4:
			var rk := lerpf(r0, r_last, k / 3.0)
			var q := c + heading * (size * 0.5 - r0) - heading * (span * k / 3.0) + side * sin(g.wiggle - k * 1.1) * 1.5
			draw_arc(q.round(), rk, 0.0, TAU, 10, body, 1.0)
			if k == 1 or k == 2:     # stub legs on the middle segments
				draw_line((q + side * rk).round(), (q + side * (rk + 1.5)).round(), Look.c(Pal.CHOIR_2))
				draw_line((q - side * rk).round(), (q - side * (rk + 1.5)).round(), Look.c(Pal.CHOIR_2))
		var head := c + heading * (size * 0.5 - r0)
		draw_rect(Rect2((head + heading * 2.0).round(), Vector2.ONE), Look.c(Pal.CHOIR_5))                 # the eye
		draw_line(head.round(), (head - heading * span).round(), Look.c(Pal.CHOIR_1))                    # the spine
		if g.carrying:
			var s := (c - side * (size * 0.5 + 1.0)).round()
			draw_colored_polygon(PackedVector2Array([s + Vector2(0, -3), s + Vector2(2, 0), s + Vector2(0, 3), s + Vector2(-2, 0)]), Look.c(Pal.PHOS_4))
