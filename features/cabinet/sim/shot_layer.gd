class_name ShotLayer
extends ArcadeLayer
## Arc-Lance bolts (the Vigil's one gun, SYS-001 §1.3) and Acolyte censer shots (SYS-001 §3).
## Every shot is swept segment-vs-circle from its last position to its new one, so nothing
## tunnels at any frame rate (TECH-001 §2.6). Capped at SYS-001 §9's active-shot ceiling.

const MAX_SHOTS := 180          ## SYS-001 §9 ✱ ceiling, both sides

class Shot:
	var pos: Vector2
	var vel: Vector2
	var life: float
	var hostile: bool
	var alive: bool = true

var shots: Array[Shot] = []


func reset() -> void:
	shots.clear()


func fire_lance(from: Vector2, dir: Vector2, carrier_vel: Vector2) -> void:
	if shots.size() >= MAX_SHOTS:
		return
	var s := Shot.new()
	s.pos = from
	s.vel = dir.normalized() * world.tuning.lance_speed + carrier_vel * 0.5
	s.life = world.tuning.lance_life
	s.hostile = false
	shots.append(s)
	world.sfx(&"lance", -10.0)


func fire_censer(from: Vector2, dir: Vector2) -> void:
	if shots.size() >= MAX_SHOTS:
		return
	var s := Shot.new()
	s.pos = from
	s.vel = dir.normalized() * world.tuning.acolyte_shot_speed
	s.life = world.tuning.acolyte_shot_life
	s.hostile = true
	shots.append(s)
	if world.on_screen(from, 32.0):
		world.sfx(&"acolyte_fire", -8.0)


func tick(delta: float) -> void:
	for s in shots:
		if not s.alive:
			continue
		var step := s.vel * delta
		var samples := maxi(1, ceili(step.length() / 4.0))   # sweep in ≤ 4 px steps
		for k in samples:
			s.pos = world.torus.wrap(s.pos + step / samples)
			if _resolve(s):
				break
		s.life -= delta
		if s.life <= 0.0:
			s.alive = false
	shots.assign(shots.filter(func(s: Shot) -> bool: return s.alive))


## Returns true if the shot was consumed.
func _resolve(s: Shot) -> bool:
	if s.hostile:
		var v := world.vigil
		if v.alive and world.torus.distance(s.pos, v.pos) <= v.radius + 2.0:
			s.alive = false
			v.kill()
			return true
		return false
	var g := world.geodes.hit_test(s.pos, 1.0)
	if g != null:
		s.alive = false
		world.geodes.lance_hit(g)
		return true
	if world.grubs.lance_test(s.pos):
		s.alive = false
		return true
	if world.acolytes.lance_test(s.pos):
		s.alive = false
		return true
	if world.ritual.lance_test(s.pos):
		s.alive = false
		return true
	return false


func _draw() -> void:
	if world == null:
		return
	for s in shots:
		if not visible_at(s.pos, 16.0):
			continue
		var p := world.to_screen(s.pos)
		if s.hostile:
			draw_circle(p.round(), 3.0, Look.c(Pal.CHOIR_2))
			draw_circle(p.round(), 1.5, Look.c(Pal.CHOIR_5))
		else:
			var tail := p - s.vel.normalized() * world.tuning.lance_length
			draw_line(tail.round(), p.round(), Look.c(Pal.GAS_2), 3.0)
			draw_line(tail.round(), p.round(), Look.c(Pal.GAS_5), 1.0)
