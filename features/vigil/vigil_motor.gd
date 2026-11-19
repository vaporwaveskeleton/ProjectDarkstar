class_name VigilMotor
extends Node
## Owns the Vigil's velocity and facing. Runs in the physics tick only (TECH-001 §2.5).
## `step_velocity` / `step_facing` are pure so tests can check frame-rate independence.
## With `aether_stats` assigned and enabled the Aether handling profile (SYS-001 §1.1a) flies
## instead of the Cabinet one; the static Cabinet steps are unchanged.

## Float slack for "above max_speed" (limit_length can land a hair over the cap) ✱.
const OVER_CAP_EPSILON := 0.5

@export var body: CharacterBody2D
@export var stats: VigilMoveStats
## Aether handling profile. Assigned and `enabled` = Aether mode; otherwise Cabinet.
@export var aether_stats: VigilAetherStats
@export var lantern: VigilLantern
@export var input: VigilInput
## Node rotated to face the aim direction (the visual + any muzzle). Collision is a circle, so
## the body itself never rotates.
@export var facing_node: Node2D

var enabled: bool = true

# Aether state exposed for the art rig.
var hull_heading: float = 0.0
var last_accel: Vector2 = Vector2.ZERO
var thrust_amount: float = 0.0
var braking: bool = false
var surging: bool = false
var surge_charges_left: int = 0

var _surge_left: float = 0.0
var _surge_dir: Vector2 = Vector2.RIGHT
var _surge_target: float = 0.0
var _recharge: float = 0.0
var _charges_init: bool = false

## True when the Aether profile is flown.
var aether_active: bool:
	get:
		return aether_stats != null and aether_stats.enabled


func _physics_process(delta: float) -> void:
	if not enabled or body == null or stats == null or input == null:
		return
	var wants_surge := input.consume_surge()
	if lantern != null and input.consume_lantern_toggle():
		lantern.toggle()
	if aether_active:
		body.velocity = tick_aether(body.velocity, input.move_dir, input.braking, wants_surge,
			lantern == null or lantern.is_up, delta)
	else:
		body.velocity = step_velocity(body.velocity, input.move_dir, input.braking, delta, stats)
	body.move_and_slide()
	if facing_node:
		var aim := input.aim_dir(body.global_position)
		if aim != Vector2.ZERO:
			facing_node.rotation = step_facing(facing_node.rotation, aim.angle(), delta, stats)


## One integration step. move_dir length <= 1.
static func step_velocity(v: Vector2, move_dir: Vector2, braking: bool, dt: float, s: VigilMoveStats) -> Vector2:
	if braking:
		var speed := maxf(0.0, v.length() - s.brake * dt)
		return v.normalized() * speed if v != Vector2.ZERO else Vector2.ZERO
	if move_dir != Vector2.ZERO:
		v += move_dir.limit_length(1.0) * s.accel * dt
		return v.limit_length(s.max_speed)
	# coasting: exponential drag, exact for any dt
	return v * exp(-s.drag * dt)


static func step_facing(current: float, target: float, dt: float, s: VigilMoveStats) -> float:
	var max_step := deg_to_rad(s.snap_turn) * dt
	var diff := wrapf(target - current, -PI, PI)
	return current + clampf(diff, -max_step, max_step)


# --- Aether profile (SYS-001 §1.1a) -------------------------------------------------------------

## Re-arms the Surgelight charges (call after aether_stats changes).
func reset_surge() -> void:
	surge_charges_left = aether_stats.surge_charges if aether_stats != null else 0
	_recharge = 0.0
	_surge_left = 0.0
	surging = false
	_charges_init = true


## One Aether tick (instance state: keel heading, Surgelight). Returns the new velocity.
func tick_aether(v: Vector2, move_dir: Vector2, is_braking: bool, wants_surge: bool,
		lantern_up: bool, dt: float) -> Vector2:
	var s := aether_stats
	if not _charges_init:
		reset_surge()
	hull_heading = step_heading(hull_heading, move_dir, dt, s)
	# Surgelight charges recharge one per cooldown.
	if surge_charges_left < s.surge_charges:
		_recharge += dt
		var cd := maxf(s.surge_cooldown, s.surge_cooldown_floor)
		if _recharge >= cd:
			_recharge -= cd
			surge_charges_left += 1
	else:
		_recharge = 0.0
	if wants_surge and surge_charges_left > 0 and _surge_left <= 0.0:
		surge_charges_left -= 1
		_surge_dir = move_dir.normalized() if move_dir != Vector2.ZERO else Vector2.from_angle(hull_heading)
		_surge_target = maxf(v.dot(_surge_dir), 0.0) + s.surge_impulse
		_surge_left = s.surge_time
	var old := v
	if _surge_left > 0.0:
		_surge_left -= dt
		var along := v.dot(_surge_dir)
		if along < _surge_target:
			v += _surge_dir * (_surge_target - along)
	else:
		v = step_aether(v, move_dir, is_braking, hull_heading, lantern_up, dt, s)
	surging = _surge_left > 0.0
	braking = is_braking
	last_accel = (v - old) / dt if dt > 0.0 else Vector2.ZERO
	thrust_amount = 0.0
	if move_dir != Vector2.ZERO and not is_braking:
		thrust_amount = clampf(move_dir.length() * thrust_factor(move_dir, hull_heading, s), 0.0, 1.0)
	return v


## The keel turns toward the input direction at `hull_turn` (deg/s). No input = no turn.
static func step_heading(heading: float, move_dir: Vector2, dt: float, s: VigilAetherStats) -> float:
	if move_dir == Vector2.ZERO:
		return heading
	var max_step := deg_to_rad(s.hull_turn) * dt
	var diff := wrapf(move_dir.angle() - heading, -PI, PI)
	return heading + clampf(diff, -max_step, max_step)


## Thrust factor by the angle between the input and the keel: 1.0 forward, thrust_lateral at 90°,
## thrust_reverse at 180°, interpolated on the cosine (piecewise) ✱.
static func thrust_factor(move_dir: Vector2, heading: float, s: VigilAetherStats) -> float:
	if move_dir == Vector2.ZERO:
		return 0.0
	var c := clampf(move_dir.normalized().dot(Vector2.from_angle(heading)), -1.0, 1.0)
	if c >= 0.0:
		return lerpf(s.thrust_lateral, 1.0, c)
	return lerpf(s.thrust_lateral, s.thrust_reverse, -c)


## One Aether velocity step. Above max_speed (after a surge) the excess decays by drag and
## thrust adds nothing, so the ship never snaps to the cap.
static func step_aether(v: Vector2, move_dir: Vector2, is_braking: bool, heading: float,
		lantern_up: bool, dt: float, s: VigilAetherStats) -> Vector2:
	var drag_mul: float = 1.0 if lantern_up else s.lantern_down_drag
	var thrust_mul: float = 1.0 if lantern_up else s.lantern_down_thrust
	if is_braking:
		var speed := maxf(0.0, v.length() - s.brake * dt)
		return v.normalized() * speed if v != Vector2.ZERO else Vector2.ZERO
	var spd := v.length()
	if spd > s.max_speed + OVER_CAP_EPSILON:
		# Above the cap (after a surge): the excess decays by drag, and thrust still steers
		# inside that shrinking cap, so the keel can turn while surging.
		var cap := s.max_speed + (spd - s.max_speed) * exp(-s.drag * drag_mul * dt)
		if move_dir != Vector2.ZERO:
			v += move_dir.limit_length(1.0) * s.accel * thrust_mul * thrust_factor(move_dir, heading, s) * dt
		return v.limit_length(cap)
	if move_dir != Vector2.ZERO:
		v += move_dir.limit_length(1.0) * s.accel * thrust_mul * thrust_factor(move_dir, heading, s) * dt
		return v.limit_length(s.max_speed)
	return v * exp(-s.drag * drag_mul * dt)
