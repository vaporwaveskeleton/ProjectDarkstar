class_name VigilShip
extends ArcadeLayer
## The Vigil in its cabinet costume: a small vector lantern-skiff (ART-001 §7 Act 0 layer).
## Movement reuses VigilMotor's pure step with the real SYS-001 §1.1 numbers, so the arcade
## ship and the Act 1 ship feel identical under the costume. One hit kills (GDD §8.1).

var pos := Vector2.ZERO
var vel := Vector2.ZERO
var facing := -PI / 2.0
var alive := true
var radius := 6.0
var shield := 0.0                ## respawn invulnerability (s)
var input_enabled := true

## Visual-only gun feedback, counted in DRAWN frames (hit-stop skips tick but still draws).
var muzzle_frames_left := 0
var recoil_frames_left := 0
var _recoil_dir := Vector2.ZERO

var _fire_cooldown := 0.0
var _surge := 0.0
var _surge_cooldown := 0.0
var _thrusting := false
var used_surgelight := false     ## for the Pretence Kept condition (LOOP-001 §11.6)

## Position trail (S5): one sample per tick() so it freezes in hit-stop; feeds the Surgelight
## afterimage and the thrust wake. Fixed-size ring buffer, draw-only, never read by the sim.
var _trail_pos := PackedVector2Array()
var _trail_face := PackedFloat32Array()
var _trail_head := 0
var _trail_count := 0
var _ghost_hold := 0.0           ## s of sim time the ghosts linger after a surge

## Test / demo hooks: when set, these replace device input.
var scripted_move := Vector2.ZERO
var scripted_aim := Vector2.ZERO
var scripted_fire := false
var use_scripted := false


func reset() -> void:
	radius = world.tuning.hitbox_radius
	pos = world.torus.size * 0.5 + Vector2(-260, 0)
	vel = Vector2.ZERO
	alive = true
	shield = world.tuning.respawn_shield
	_clear_trail()


func respawn(at: Vector2) -> void:
	pos = at
	vel = Vector2.ZERO
	alive = true
	shield = world.tuning.respawn_shield
	_clear_trail()


func tick(delta: float) -> void:
	shield = maxf(0.0, shield - delta)
	_fire_cooldown = maxf(0.0, _fire_cooldown - delta)
	_surge_cooldown = maxf(0.0, _surge_cooldown - delta)
	if not alive:
		return
	var move := Vector2.ZERO
	var aim := Vector2.ZERO
	var fire := false
	var braking := false
	if use_scripted:
		move = scripted_move
		aim = scripted_aim
		fire = scripted_fire
	elif input_enabled:
		move = Input.get_vector(&"move_left", &"move_right", &"move_up", &"move_down")
		braking = Input.is_action_pressed(&"brake")
		fire = Input.is_action_pressed(&"fire_lance")
		var stick := Input.get_vector(&"aim_left", &"aim_right", &"aim_up", &"aim_down")
		if stick.length() > 0.3:
			aim = stick
		else:
			var vp := get_viewport()
			if vp:
				aim = vp.get_mouse_position() - world.to_screen(pos)
		if Input.is_action_just_pressed(&"deploy_charge"):
			var dir := aim if aim != Vector2.ZERO else Vector2.from_angle(facing)
			world.glass.launch(pos, dir)
		if Input.is_action_just_pressed(&"surgelight") and _surge_cooldown <= 0.0 and move != Vector2.ZERO:
			_surge = world.tuning.surgelight_time
			_surge_cooldown = world.tuning.surgelight_cooldown
			used_surgelight = true
			world.sfx(&"charge_fire", -8.0)
	_thrusting = move != Vector2.ZERO
	vel = VigilMotor.step_velocity(vel, move, braking, delta, world.move_stats)
	if _surge > 0.0:
		_surge -= delta
		vel += move.normalized() * world.tuning.surgelight_impulse * delta / world.tuning.surgelight_time
		if _surge <= 0.0:
			_ghost_hold = world.fx_tuning.ghost_hold_s
	elif _ghost_hold > 0.0:
		_ghost_hold = maxf(0.0, _ghost_hold - delta)
	pos = world.torus.wrap(pos + vel * delta)
	if aim.length() > 1.0:
		facing = VigilMotor.step_facing(facing, aim.angle(), delta, world.move_stats)
	if fire and _fire_cooldown <= 0.0:
		_fire_cooldown = 1.0 / world.tuning.lance_rate
		var dir := Vector2.from_angle(facing)
		world.shots.fire_lance(pos + dir * 9.0, dir, vel)
		if SettingsService.get_value(&"muzzle_flash") and not SettingsService.get_value(&"photosensitivity"):
			muzzle_frames_left = world.fx_tuning.muzzle_star_frames
		if not SettingsService.get_value(&"reduced_motion"):
			recoil_frames_left = world.fx_tuning.recoil_frames
			_recoil_dir = dir
	# bump off geodes (they never kill; GDD keeps death for the Choir and the entity)
	var g := world.geodes.hit_test(pos, radius)
	if g != null:
		var away := world.torus.delta(g.pos, pos).normalized()
		pos = world.torus.wrap(g.pos + away * (g.radius + radius + 0.5))
		vel = vel.bounce(away) * 0.5 if vel.dot(away) < 0.0 else vel
	_record_trail()


# --- S5 trail -------------------------------------------------------------------------------

func _trail_len() -> int:
	var ft := world.fx_tuning
	return maxi(ft.ghost_count * ft.ghost_spacing_ticks, ft.wake_dots * ft.wake_spacing_ticks) + 1


func _clear_trail() -> void:
	_trail_pos.resize(_trail_len())
	_trail_face.resize(_trail_len())
	_trail_head = 0
	_trail_count = 0
	_ghost_hold = 0.0


func _record_trail() -> void:
	if _trail_pos.size() != _trail_len():
		_clear_trail()
	_trail_pos[_trail_head] = pos
	_trail_face[_trail_head] = facing
	_trail_head = (_trail_head + 1) % _trail_pos.size()
	_trail_count = mini(_trail_count + 1, _trail_pos.size())


## Is there a sample `k` ticks back (0 = this tick's)?
func trail_has(k: int) -> bool:
	return k >= 0 and k < _trail_count


## World position written `k` ticks back (call trail_has first).
func trail_pos(k: int) -> Vector2:
	return _trail_pos[posmod(_trail_head - 1 - k, _trail_pos.size())]


func trail_facing(k: int) -> float:
	return _trail_face[posmod(_trail_head - 1 - k, _trail_pos.size())]


## Offset of the sample `k` ticks back from the ship, via the torus delta so a wrap of `pos`
## never throws a ghost across the field.
func trail_offset(k: int) -> Vector2:
	return world.torus.delta(pos, trail_pos(k))


func afterimage_active() -> bool:
	return alive and (_surge > 0.0 or _ghost_hold > 0.0)


func wake_active() -> bool:
	return alive and _thrusting


## Open polyline of the hull outline for ghost number `i` (1 = nearest). Only the live hull is a
## closed shape: ghost 1 keeps 3 of the 4 edges, ghost 2 keeps 2, ghost 3+ keeps 1. Fixed pattern.
func ghost_outline(hull: PackedVector2Array, i: int) -> PackedVector2Array:
	var edges := clampi(4 - i, 1, 3)
	return hull.slice(0, edges + 1)


func ghost_color(i: int) -> Color:
	var ramp: Array[Color] = [Pal.GAS_3, Pal.GAS_2, Pal.GAS_1]
	return Look.c(ramp[clampi(i - 1, 0, ramp.size() - 1)])


func _hull(c: Vector2, ang: float) -> PackedVector2Array:
	var f := Vector2.from_angle(ang)
	var r := f.orthogonal()
	return PackedVector2Array([c + f * 9.0, c - f * 6.0 + r * 6.0, c - f * 3.0, c - f * 6.0 - r * 6.0])


## killer_pos / from_dir / killer_radius feed the chalk death mark (S6): from_dir points from the
## Vigil toward what hit it. Defaults (INF) keep old callers working and draw no mark.
func kill(killer_pos: Vector2 = Vector2.INF, from_dir: Vector2 = Vector2.ZERO, killer_radius: float = 0.0) -> void:
	if not alive or shield > 0.0:
		return
	alive = false
	if killer_pos.is_finite():
		world.fx.death_mark(killer_pos, killer_radius, from_dir, pos)
	world.sfx(&"vigil_die")
	world.fx.burst(pos, Look.c(Pal.GAS_4), world.fx_tuning.vigil_death_burst_a_count, world.fx_tuning.vigil_death_burst_a_speed)
	world.fx.burst(pos, Look.c(Pal.GAS_2), world.fx_tuning.vigil_death_burst_b_count, world.fx_tuning.vigil_death_burst_b_speed)
	world.fx.ring(pos, Look.c(Pal.GAS_3), world.fx_tuning.vigil_death_ring_radius)
	world.shake(world.fx_tuning.vigil_death_shake_amp, world.fx_tuning.vigil_death_shake_dur)
	world.hitstop(world.fx_tuning.hitstop_vigil_death_frames, &"vigil_death")
	world.vigil_destroyed.emit()


func _draw() -> void:
	_draw_ship()
	advance_draw_frame()


## Draw-only nudge opposite the aim; never touches pos, vel or facing (SYS-001 §1.3: no recoil).
func recoil_offset() -> Vector2:
	if recoil_frames_left <= 0:
		return Vector2.ZERO
	return -_recoil_dir * float(world.fx_tuning.recoil_px)


## One drawn frame has passed (end of _draw; tests call it directly).
func advance_draw_frame() -> void:
	muzzle_frames_left = maxi(0, muzzle_frames_left - 1)
	recoil_frames_left = maxi(0, recoil_frames_left - 1)


func _draw_ship() -> void:
	if world == null or not alive:
		return
	if shield > 0.0 and int(shield * 12.0) % 2 == 0:
		return
	var c := (world.to_screen(pos).round() + recoil_offset()).round()
	var f := Vector2.from_angle(facing)
	var r := f.orthogonal()
	var hull := PackedVector2Array([c + f * 9.0, c - f * 6.0 + r * 6.0, c - f * 3.0, c - f * 6.0 - r * 6.0])
	_draw_trail(c)
	Pal.glow_polyline(self, hull, Look.c(Pal.GAS_4), Look.c(Pal.GAS_1))
	draw_rect(Rect2((c + f * 1.0).round() - Vector2(1, 1), Vector2(3, 3)), Look.c(Pal.GAS_5))   # the lamp
	if _thrusting and int(world.time * 30.0) % 2 == 0:
		var tail := c - f * (8.0 + (3.0 if _surge > 0.0 else 0.0))
		draw_line((c - f * 4.0).round(), tail.round(), Look.c(Pal.GAS_3) if _surge <= 0.0 else Look.c(Pal.GAS_5), 2.0)
	if muzzle_frames_left > 0:
		var m := (c + f * 9.0).round()
		var arm := float(world.fx_tuning.muzzle_star_px)
		draw_line(m - Vector2(arm, 0), m + Vector2(arm, 0), Look.c(Pal.GAS_5), 1.0)
		draw_line(m - Vector2(0, arm), m + Vector2(0, arm), Look.c(Pal.GAS_5), 1.0)


## S5: stepped-palette afterimage (open hull outlines, no glow) and thrust wake (1x1 dots).
func _draw_trail(c: Vector2) -> void:
	var ft := world.fx_tuning
	if afterimage_active():
		for i in range(ft.ghost_count, 0, -1):   # farthest first so the nearest sits on top
			var k := i * ft.ghost_spacing_ticks
			if not trail_has(k):
				continue
			var gc := (c + trail_offset(k)).round()
			var line := ghost_outline(_hull(gc, trail_facing(k)), i)
			draw_polyline(line, ghost_color(i), 1.0)
	if wake_active():
		for j in range(ft.wake_dots, 0, -1):
			var k := j * ft.wake_spacing_ticks
			if not trail_has(k):
				continue
			var col := Look.c(Pal.GAS_2) if j * 2 <= ft.wake_dots else Look.c(Pal.GAS_1)
			draw_rect(Rect2((c + trail_offset(k)).round(), Vector2.ONE), col)
