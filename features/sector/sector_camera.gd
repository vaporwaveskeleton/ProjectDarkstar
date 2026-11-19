class_name SectorCamera
extends Camera2D
## The sector camera component (TECH-001 §2.5 "Camera follow, shake, zoom"). Follows `target`
## with a deadzone, a critically damped spring and a small lookahead toward the target's aim;
## owns screen shake under the SYS-001 §9 ceiling. Numbers live in SectorCameraStats (ds_camera).
## Runs in the physics tick, like the VigilMotor it follows, so the two never drift a frame apart.
## The static helpers are pure so tests can check deadzone, convergence, lookahead and the cap.

@export var stats: SectorCameraStats
## What to follow. If it has `get_aim_dir() -> Vector2` the camera leans toward that direction.
@export var target: Node2D
## The wrapping sector (Q-T58), injected by the sector host. Null = a plain plane. With a torus the
## camera follows the target's nearest image (Torus.delta) and, when the target wraps, rebases its
## focus and position by the same whole-field shift, so the view never jumps at the seam.
var torus: Torus

## Where the deadzone is centred (the follow anchor, before lookahead).
var focus: Vector2 = Vector2.ZERO
var follow_velocity: Vector2 = Vector2.ZERO
## Extra framing lean (world px) added to the follow goal: the RaceFramer leans the camera toward the
## race (Charge, Grub, Sepulchre) without zoom (Q-T25 Z1). Zero = plain follow. Set every tick.
var frame_offset: Vector2 = Vector2.ZERO

var _shake_amp: float = 0.0     # peak amplitude of the current shake (px), already capped
var _shake_dur: float = 0.0     # its full duration (s), already capped
var _shake_left: float = 0.0    # time remaining (s)
var _rng := RandomNumberGenerator.new()


func _ready() -> void:
	process_callback = Camera2D.CAMERA2D_PROCESS_PHYSICS
	position_smoothing_enabled = false
	if stats != null:
		# Q-T25 resolved as Z1: zoom 1 is the 640×360 frame and stays fixed (SYS-001 §9 T0 = 1.0).
		zoom = Vector2.ONE * stats.zoom
	snap_to_target()


## Jump to the target with no motion (spawn, respawn, route entry).
func snap_to_target() -> void:
	follow_velocity = Vector2.ZERO
	if not is_instance_valid(target):
		focus = global_position
		return
	focus = target.global_position
	global_position = focus + _current_lookahead()


func _physics_process(delta: float) -> void:
	step(delta)


## One camera tick: deadzone, spring, shake. Public so tests can drive it frame by frame.
func step(delta: float) -> void:
	if stats == null:
		return
	if is_instance_valid(target):
		var goal := target.global_position
		if torus != null:
			rebase_to(goal)
			goal = focus + torus.delta(focus, goal)
		focus = apply_deadzone(focus, goal, stats.deadzone_px)
	var desired := focus + _current_lookahead() + frame_offset
	if torus != null:
		desired = global_position + torus.delta(global_position, desired)
	var r := spring_step(global_position, follow_velocity, desired, omega_for(stats.follow_time_s), delta)
	global_position = r[0]
	follow_velocity = r[1]
	offset = _step_shake(delta)


## Move focus and position by the whole-field shift that puts the focus on the image of the torus
## nearest `world_pos`. Velocity is unchanged. Returns the shift (zero when nothing moved).
func rebase_to(world_pos: Vector2) -> Vector2:
	if torus == null:
		return Vector2.ZERO
	var shift := (world_pos + torus.delta(world_pos, focus)) - focus
	if shift != Vector2.ZERO:
		focus += shift
		global_position += shift
	return shift


## Request a shake. Amplitude and duration are clamped to the SYS-001 §9 ceiling; overlapping
## shakes take the larger remaining amplitude, never the sum. Returns false when suppressed.
func shake(amplitude_px: float, duration_s: float) -> bool:
	if stats == null or shake_suppressed():
		return false
	var amp := clampf(amplitude_px, 0.0, stats.shake_max_px)
	var dur := clampf(duration_s, 0.0, stats.shake_max_s)
	if amp <= 0.0 or dur <= 0.0:
		return false
	var now := shake_amp_at(_shake_amp, _shake_left, _shake_dur)
	if amp >= now:
		_shake_amp = amp
		_shake_dur = dur
		_shake_left = dur
	return true


## D-3: no screen shake under Settings `reduced_motion` (the flag lives in the data).
func shake_suppressed() -> bool:
	return stats != null and stats.shake_off_under_reduced_motion \
		and bool(SettingsService.get_value(&"reduced_motion"))


func is_shaking() -> bool:
	return _shake_left > 0.0


func _step_shake(delta: float) -> Vector2:
	if _shake_left <= 0.0:
		return Vector2.ZERO
	if shake_suppressed():
		_shake_left = 0.0
		return Vector2.ZERO
	_shake_left = maxf(0.0, _shake_left - delta)
	var amp := minf(shake_amp_at(_shake_amp, _shake_left, _shake_dur), stats.shake_max_px)
	return Vector2.from_angle(_rng.randf() * TAU) * amp * sqrt(_rng.randf())


func _current_lookahead() -> Vector2:
	if stats == null or not is_instance_valid(target) or not target.has_method("get_aim_dir"):
		return Vector2.ZERO
	var aim: Vector2 = target.call("get_aim_dir")
	return lookahead(aim, visible_size(), stats.aim_lookahead_frac)


## The visible world size (viewport size / zoom).
func visible_size() -> Vector2:
	var z := zoom if zoom.x > 0.0 and zoom.y > 0.0 else Vector2.ONE
	return get_viewport_rect().size / z


# --- pure helpers --------------------------------------------------------------------------------

## Move `focus` only as far as needed to keep `goal` within `radius` of it (circular deadzone,
## accepted reading Q-T57). On a torus the caller passes the goal's nearest image (Torus.delta).
static func apply_deadzone(focus_pos: Vector2, goal: Vector2, radius: float) -> Vector2:
	var d := goal - focus_pos
	var dist := d.length()
	if dist <= radius or dist == 0.0:
		return focus_pos
	return goal - d / dist * radius


## "1.5 % aim lookahead" (SYS-001 §9). Accepted reading (Q-T55, resolved): a fraction of the visible
## viewport size, per axis, along the normalised aim direction. At 640×360 and frac 0.015 that is
## at most 9.6 px horizontally and 5.4 px vertically. No other number is invented here.
static func lookahead(aim: Vector2, view_size: Vector2, frac: float) -> Vector2:
	if aim == Vector2.ZERO:
		return Vector2.ZERO
	var a := aim.normalized()
	return Vector2(a.x * view_size.x, a.y * view_size.y) * frac


## Spring stiffness for a smoothing time T (SmoothDamp convention, omega = 2 / T).
## Accepted reading of "0.12 s critically damped" (Q-T56, resolved).
static func omega_for(follow_time: float) -> float:
	return 2.0 / follow_time if follow_time > 0.0 else INF


## Exact critically damped spring step toward a fixed goal (frame-rate independent).
## Returns [position, velocity].
static func spring_step(pos: Vector2, vel: Vector2, goal: Vector2, omega: float, dt: float) -> Array[Vector2]:
	if is_inf(omega):
		return [goal, Vector2.ZERO]
	var x := pos - goal
	var k := vel + x * omega
	var e := exp(-omega * dt)
	return [goal + (x + k * dt) * e, (vel - k * (omega * dt)) * e]


## Linear decay of a shake's amplitude over its duration.
static func shake_amp_at(peak: float, left: float, duration: float) -> float:
	if duration <= 0.0 or left <= 0.0:
		return 0.0
	return peak * clampf(left / duration, 0.0, 1.0)
