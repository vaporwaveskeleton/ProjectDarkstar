class_name VigilMotor
extends Node
## Owns the Vigil's velocity and facing. Runs in the physics tick only (TECH-001 §2.5).
## `step_velocity` / `step_facing` are pure so tests can check frame-rate independence.

@export var body: CharacterBody2D
@export var stats: VigilMoveStats
@export var input: VigilInput
## Node rotated to face the aim direction (the visual + any muzzle). Collision is a circle, so
## the body itself never rotates.
@export var facing_node: Node2D

var enabled: bool = true


func _physics_process(delta: float) -> void:
	if not enabled or body == null or stats == null or input == null:
		return
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
