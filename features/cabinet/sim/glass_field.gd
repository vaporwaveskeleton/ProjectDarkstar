class_name GlassField
extends ArcadeLayer
## Mourning Glass shards and Null-Iron Charges (GDD §8.3, SYS-001 §1.4).
## Shards drift; the Vigil's magnet pulls them in; each collected shard is one Charge up to the
## magazine; overflow shards stay in the world. Grubs claim and carry shards to the Sepulchre.
## Charges home on the ritual's target and can be intercepted by Grubs, Acolytes and geodes.

const SHARD_RADIUS := 4.0
const SHARD_DRAG := 1.2        ## ✱ 1/s, visual drift settle
const MAGNET_PULL := 170.0     ## ✱ px/s once inside the magnet radius
const CHARGE_RADIUS := 4.0

class Shard:
	var pos: Vector2
	var vel: Vector2
	var claimed_by: int = 0     ## instance id of the Grub that claimed it, 0 = free
	var carried: bool = false
	var alive: bool = true
	var spin: float = 0.0

class Charge:
	var pos: Vector2
	var dir: Vector2
	var age: float = 0.0
	var alive: bool = true
	var trail: PackedVector2Array = PackedVector2Array()

var shards: Array[Shard] = []
var charges_flying: Array[Charge] = []
var charges: int = 0


func reset() -> void:
	shards.clear()
	charges_flying.clear()
	set_charges(0)


func set_charges(n: int) -> void:
	charges = clampi(n, 0, world.tuning.magazine)
	world.charges_changed.emit(charges)


func spawn_shard(at: Vector2, vel: Vector2) -> Shard:
	var s := Shard.new()
	s.pos = world.torus.wrap(at)
	s.vel = vel
	s.spin = world.rng.randf() * TAU
	shards.append(s)
	return s


func free_shards() -> Array[Shard]:
	var out: Array[Shard] = []
	for s in shards:
		if s.alive and s.claimed_by == 0:
			out.append(s)
	return out


func tick(delta: float) -> void:
	var t := world.tuning
	var v := world.vigil
	for s in shards:
		if not s.alive or s.carried:
			continue
		s.spin += delta * 3.0
		s.vel *= exp(-SHARD_DRAG * delta)
		if v.alive and charges < t.magazine:
			var d := world.torus.delta(s.pos, v.pos)
			var dist := d.length()
			if dist < t.magnet_radius:
				s.vel = s.vel.lerp(d.normalized() * MAGNET_PULL, clampf(delta * 6.0, 0.0, 1.0))
			if dist < v.radius + SHARD_RADIUS + 2.0:
				_collect(s)
				continue
		s.pos = world.torus.wrap(s.pos + s.vel * delta)
	shards.assign(shards.filter(func(s: Shard) -> bool: return s.alive))
	_tick_charges(delta)


func _collect(s: Shard) -> void:
	s.alive = false
	set_charges(charges + 1)
	world.award(world.tuning.score_shard, s.pos)
	world.sfx(&"shard_chime", -3.0 + charges)
	world.fx.ring(s.pos, Pal.PHOS_4, 14.0)


## Fire one Charge from the Vigil toward `dir`. Returns false with an empty magazine.
func launch(from: Vector2, dir: Vector2) -> bool:
	if charges <= 0:
		return false
	set_charges(charges - 1)
	var c := Charge.new()
	c.pos = from
	c.dir = dir.normalized()
	charges_flying.append(c)
	world.sfx(&"charge_fire", -2.0)
	return true


func _tick_charges(delta: float) -> void:
	var t := world.tuning
	var turn_rate := PI / t.charge_turn_authority
	for c in charges_flying:
		if not c.alive:
			continue
		c.age += delta
		var target: Variant = world.ritual.charge_target()
		if target != null:
			var want := world.torus.delta(c.pos, target as Vector2).normalized()
			var ang := c.dir.angle_to(want)
			c.dir = c.dir.rotated(clampf(ang, -turn_rate * delta, turn_rate * delta))
		c.pos = world.torus.wrap(c.pos + c.dir * t.charge_speed * delta)
		c.trail.append(c.pos)
		if c.trail.size() > 10:
			c.trail.remove_at(0)
		# interception (SYS-001 §1.4: Grubs, Acolytes and geodes take a Charge)
		if world.grubs.hit_test(c.pos, CHARGE_RADIUS) != null or world.acolytes.hit_test(c.pos, CHARGE_RADIUS) != null \
				or world.geodes.hit_test(c.pos, CHARGE_RADIUS) != null:
			_lose(c, true)
			continue
		if world.ritual.charge_contact(c.pos, CHARGE_RADIUS):
			c.alive = false
			continue
		if c.age > t.charge_life:
			_lose(c, false)
	charges_flying.assign(charges_flying.filter(func(c: Charge) -> bool: return c.alive))


## A Charge lost to interception or guttering out: the glass chime (AUDIO-001 B06).
func _lose(c: Charge, intercepted: bool) -> void:
	c.alive = false
	world.sfx(&"charge_lost", 0.0)
	world.fx.burst(c.pos, Pal.PHOS_5, 10, 50.0)
	if intercepted:
		world.fx.ring(c.pos, Pal.BONE_5, 18.0)


func _draw() -> void:
	if world == null:
		return
	for s in shards:
		if not s.alive or not visible_at(s.pos, 8.0):
			continue
		var p := world.to_screen(s.pos).round()
		var k := 3.0 + sin(s.spin) * 1.0
		var pts := PackedVector2Array([p + Vector2(0, -k - 1), p + Vector2(k * 0.6, 0), p + Vector2(0, k + 1), p + Vector2(-k * 0.6, 0)])
		draw_colored_polygon(pts, Pal.PHOS_3)
		draw_rect(Rect2(p, Vector2.ONE), Pal.PHOS_5)
	for c in charges_flying:
		var prev := Vector2.INF
		for i in c.trail.size():
			var q := world.to_screen(c.trail[i])
			if prev != Vector2.INF and prev.distance_to(q) < 40.0:
				draw_line(prev, q, Pal.PHOS_2 if i < c.trail.size() - 4 else Pal.PHOS_4, 1.0)
			prev = q
		var p := world.to_screen(c.pos).round()
		draw_rect(Rect2(p - Vector2(2, 2), Vector2(5, 5)), Pal.PHOS_1)
		draw_rect(Rect2(p - Vector2(1, 1), Vector2(3, 3)), Pal.BONE_5)
