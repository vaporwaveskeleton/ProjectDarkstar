class_name AcolyteSquad
extends ArcadeLayer
## Acolytes — Censer Knights (GDD §8.5, SYS-001 §3). Pale spikes with a censer turret that swings
## to face you but lags 0.25 s behind the body (the teachable tell: lead your own movement and the
## censer fires where you were). Every shot has a 21-frame tell. When the Vigil is far they guard
## the Sepulchre and mine geodes at half the Vigil's rate. At the Guard phase more arrive.

const RADIUS := 7.0
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

var items: Array[Acolyte] = []
var _guard_spawned := false


func reset() -> void:
	items.clear()
	_guard_spawned = false
	for i in world.stage.acolytes:
		spawn(world.torus.wrap(world.ritual.pos + Vector2.from_angle(world.rng.randf() * TAU) * GUARD_ORBIT))


func spawn(at: Vector2) -> Acolyte:
	var a := Acolyte.new()
	a.pos = at
	a.hp = world.tuning.acolyte_hp
	a.cycle = world.tuning.acolyte_cycle * world.rng.randf_range(0.5, 1.0)
	a.slot = world.rng.randf() * TAU
	items.append(a)
	return a


func on_guard_phase() -> void:
	if _guard_spawned:
		return
	_guard_spawned = true
	for i in world.stage.guard_acolytes:
		var a := spawn(world.torus.wrap(world.ritual.pos + Vector2.from_angle(TAU * i / maxi(1, world.stage.guard_acolytes)) * GUARD_ORBIT))
		world.fx.ring(a.pos, Pal.CHOIR_4, 24.0)


func tick(delta: float) -> void:
	var t := world.tuning
	var lag_ticks := maxi(1, roundi(t.acolyte_turret_lag * Engine.physics_ticks_per_second))
	for a in items:
		if not a.alive:
			continue
		a.flash = maxf(0.0, a.flash - delta * 5.0)
		var v := world.vigil
		var to_v := world.torus.delta(a.pos, v.pos)
		var engaged := v.alive and to_v.length() < t.acolyte_range and not world.ritual.awake
		var target := a.pos
		if engaged:
			# hold range and circle: approach if far, back off if close
			var radial := to_v.normalized()
			var dist := to_v.length()
			var want := radial * (dist - HOLD_DISTANCE) + radial.orthogonal() * 40.0
			target = world.torus.wrap(a.pos + want)
		else:
			a.slot += delta * 0.4
			target = world.torus.wrap(world.ritual.pos + Vector2.from_angle(a.slot) * GUARD_ORBIT)
		var d := world.torus.delta(a.pos, target)
		var desired_vel := d.normalized() * minf(t.acolyte_speed, d.length() * 2.0)
		a.vel = a.vel.lerp(desired_vel, clampf(delta * 3.0, 0.0, 1.0))
		a.pos = world.torus.wrap(a.pos + a.vel * delta)
		# censer turret: aims where the Vigil WAS `turret_lag` seconds ago (SYS-001 §3, 🔒)
		a.aim_history.append(to_v.angle())
		while a.aim_history.size() > lag_ticks:
			a.aim_history.remove_at(0)
		a.turret = a.aim_history[0]
		if engaged:
			a.cycle -= delta
			if a.cycle <= 0.0:
				a.cycle = t.acolyte_cycle
				world.shots.fire_censer(a.pos + Vector2.from_angle(a.turret) * 8.0, Vector2.from_angle(a.turret))
		else:
			_mine(a, delta)
	items.assign(items.filter(func(a: Acolyte) -> bool: return a.alive))


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
	return a.cycle <= world.tuning.acolyte_tell


func hit_test(p: Vector2, r: float) -> Acolyte:
	for a in items:
		if a.alive and world.torus.distance_sq(p, a.pos) <= (RADIUS + r) * (RADIUS + r):
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
	world.fx.burst(a.pos, Pal.CHOIR_4, 22, 110.0)
	world.fx.ring(a.pos, Pal.CHOIR_3, 30.0)
	world.shake(2.0, 0.15)


func _draw() -> void:
	if world == null:
		return
	for a in items:
		if not visible_at(a.pos, 20.0):
			continue
		var c := world.to_screen(a.pos).round()
		var body := Pal.CHOIR_5 if a.flash > 0.4 else Pal.CHOIR_3
		var spike := PackedVector2Array([c + Vector2(0, -11), c + Vector2(5, 7), c + Vector2(-5, 7)])
		Pal.glow_polyline(self, spike, body, Pal.CHOIR_1)
		draw_rect(Rect2(c + Vector2(-1, -5), Vector2(2, 2)), Pal.BONE_4)              # the pale face
		var arm := (c + Vector2.from_angle(a.turret) * 9.0).round()
		draw_line(c, arm, Pal.CHOIR_2)
		var tell := telling(a) and world.vigil.alive and world.torus.distance(a.pos, world.vigil.pos) < world.tuning.acolyte_range
		draw_circle(arm, 2.5, Pal.SIGNAL if tell else Pal.CHOIR_4)
