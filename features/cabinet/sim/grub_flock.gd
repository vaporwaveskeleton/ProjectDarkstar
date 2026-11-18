class_name GrubFlock
extends ArcadeLayer
## Oubliette Grubs (GDD §8.5, SYS-001 §3): harmless larvae that never attack. They claim free
## Mourning Glass, carry it to the Sepulchre and deposit it — every deposit builds the god.
## They flee the Vigil's lamp unless they are carrying (devotion beats fear), mourn a lost
## deposit (keening), and the Sepulchre births a replacement for every Grub you kill.

const RADIUS := 6.0
const SEEK_SPEED := 160.0     ## ✱ between the carry (130) and flee (190) speeds of SYS-001 §3

enum State { SEEK, CARRY, FLEE, IDLE, WORSHIP }

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
		_spawn(world.ritual.pos + Vector2.from_angle(TAU * i / maxi(1, world.stage.grubs)) * 60.0)


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
				target = world.torus.wrap(world.ritual.pos + Vector2.from_angle(world.time * 0.3 + g.id) * 90.0)
				speed = 70.0
			State.WORSHIP:
				target = world.torus.wrap(world.ritual.pos + Vector2.from_angle(world.time * 0.6 + g.id * 1.3) * 70.0)
				speed = 90.0
		var d := world.torus.delta(g.pos, target)
		var want := d.normalized() * speed if d.length() > 2.0 else Vector2.ZERO
		g.vel = g.vel.lerp(want, clampf(delta * 5.0, 0.0, 1.0))
		g.pos = world.torus.wrap(g.pos + g.vel * delta)
		if g.state == State.SEEK and g.shard != null and world.torus.distance(g.pos, g.shard.pos) < RADIUS + 4.0:
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
			if not world.ritual.awake:
				_spawn(world.ritual.pos)


func _claim(g: Grub) -> void:
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


func hit_test(p: Vector2, r: float) -> Grub:
	for g in items:
		if g.alive and world.torus.distance_sq(p, g.pos) <= (RADIUS + r) * (RADIUS + r):
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
		world.award(world.tuning.score_grub, g.pos)
		world.sfx(&"grub_die", -4.0)
		world.fx.burst(g.pos, Look.c(Pal.CHOIR_4), 12, 70.0)
	_respawn_timers.append(world.tuning.grub_respawn)


func _draw() -> void:
	if world == null:
		return
	for g in items:
		if not visible_at(g.pos, 16.0):
			continue
		var c := world.to_screen(g.pos)
		var heading := g.vel.normalized() if g.vel.length() > 1.0 else Vector2.RIGHT
		var side := heading.orthogonal()
		var body := Look.c(Pal.CHOIR_5) if g.flash > 0.4 else Look.c(Pal.CHOIR_3)
		for k in 3:
			var q := c - heading * (k * 4.0) + side * sin(g.wiggle - k * 1.1) * 1.5
			draw_arc(q.round(), 3.0 - k * 0.6, 0.0, TAU, 8, body, 1.0)
		draw_rect(Rect2((c + heading * 2.0).round(), Vector2.ONE), Look.c(Pal.CHOIR_5))
		if g.carrying:
			var s := (c - side * 6.0).round()
			draw_colored_polygon(PackedVector2Array([s + Vector2(0, -3), s + Vector2(2, 0), s + Vector2(0, 3), s + Vector2(-2, 0)]), Look.c(Pal.PHOS_4))
