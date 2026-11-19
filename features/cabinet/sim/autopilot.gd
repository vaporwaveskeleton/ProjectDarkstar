class_name CabinetAutopilot
extends Node
## A competent, unremarkable Vigil pilot for the attract-mode demo loop (WARP-001 W0-03), visual
## captures, and the end-to-end test that proves an Act 0 stage can be won. It reads the world
## like a player would and writes the Vigil's scripted inputs; it never touches rules.
## Priorities: survive the entity → shoot what threatens → spend Charges on the target → collect
## glass → mine calmly (it stops firing before the over-fire window fills).

@export var world: ArcadeWorld
var enabled := false
var _launch_cd := 0.0


func _physics_process(delta: float) -> void:
	if not enabled or world == null or world.stage == null:
		return
	var v := world.vigil
	v.use_scripted = true
	v.scripted_fire = false
	v.scripted_move = Vector2.ZERO
	_launch_cd = maxf(0.0, _launch_cd - delta)
	if not v.alive:
		return
	var t := world.torus
	var r := world.ritual
	var move := Vector2.ZERO
	var aim := Vector2.ZERO
	var fire := false

	var target: Variant = r.charge_target()
	var target_d := t.distance(v.pos, target as Vector2) if target != null else INF

	# 1 — the entity hunts: keep it at arm's length and keep moving
	if r.awake:
		var away := t.delta(r.entity_pos, v.pos)
		if away.length() < 170.0:
			move = away.normalized() + away.normalized().orthogonal() * 0.6
	# 2 — threats: the nearest Acolyte in range, or a Grub carrying glass
	var threat := Vector2.INF
	var best := 260.0
	for a in world.acolytes.items:
		var d := t.distance(v.pos, a.pos)
		if d < best:
			best = d
			threat = a.pos
	if threat == Vector2.INF:
		best = 200.0
		for g in world.grubs.items:
			if g.carrying:
				var d := t.distance(v.pos, g.pos)
				if d < best:
					best = d
					threat = g.pos
	if threat != Vector2.INF:
		aim = t.delta(v.pos, threat)
		fire = true
		if move == Vector2.ZERO and aim.length() > 140.0:
			move = aim.normalized()
	# 3 — Charges: close in and throw them at the Sepulchre / the entity
	var g_charges := world.glass.charges
	var want_throw := target != null and g_charges > 0 and (r.awake or g_charges >= 3 or g_charges == world.tuning.magazine)
	if want_throw:
		var to_t := t.delta(v.pos, target as Vector2)
		if target_d < 260.0 and _launch_cd <= 0.0:
			v.scripted_aim = to_t
			world.glass.launch(v.pos, to_t)
			_launch_cd = 0.7
		elif move == Vector2.ZERO and not r.awake:
			move = to_t.normalized()
	# 4 — glass on the field
	if move == Vector2.ZERO and world.glass.charges < world.tuning.magazine:
		var shard := _nearest_free_shard(v.pos)
		if shard != Vector2.INF and t.distance(v.pos, shard) < 400.0:
			move = t.delta(v.pos, shard).normalized()
	# 5 — mine calmly
	if threat == Vector2.INF:
		var g := _nearest_geode(v.pos)
		if g != null:
			var to_g := t.delta(v.pos, g.pos)
			aim = to_g
			# count the bolts already in flight, so the window never fills to the over-fire threshold
			var in_flight := ceili(to_g.length() / world.tuning.lance_speed * world.tuning.lance_rate)
			var hot := g.recent.size() + in_flight >= world.tuning.overfire_hits - 1
			fire = not hot and to_g.length() < 240.0
			if move == Vector2.ZERO:
				var dist := to_g.length() - (g.radius + 50.0)
				move = to_g.normalized() * clampf(dist / 60.0, -1.0, 1.0)
	v.scripted_move = move.limit_length(1.0)
	if aim != Vector2.ZERO:
		v.scripted_aim = aim
	v.scripted_fire = fire


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


func _nearest_geode(from: Vector2) -> GeodeField.Geode:
	var best: GeodeField.Geode = null
	var bd := INF
	for g in world.geodes.items:
		var d := world.torus.distance_sq(from, g.pos)
		if d < bd:
			bd = d
			best = g
	return best
