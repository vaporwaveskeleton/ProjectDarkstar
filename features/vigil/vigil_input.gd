class_name VigilInput
extends Node
## Turns device input into intent (D-01: WASD + mouse aim, full gamepad parity).
## Holds no physics. Other code may write the fields directly (AI, replays, tests).

const AIM_STICK_DEADZONE := 0.3   ## ✱

var move_dir: Vector2 = Vector2.ZERO
var braking: bool = false
var firing: bool = false
var stick_aim: Vector2 = Vector2.ZERO
var read_devices: bool = true


func _physics_process(_delta: float) -> void:
	if not read_devices:
		return
	move_dir = Input.get_vector(&"move_left", &"move_right", &"move_up", &"move_down")
	braking = Input.is_action_pressed(&"brake")
	firing = Input.is_action_pressed(&"fire_lance")
	stick_aim = Input.get_vector(&"aim_left", &"aim_right", &"aim_up", &"aim_down")


## Aim direction: right stick if pushed, else toward the mouse.
func aim_dir(from_global: Vector2) -> Vector2:
	if stick_aim.length() >= AIM_STICK_DEADZONE:
		return stick_aim.normalized()
	if not read_devices:
		return Vector2.ZERO
	var vp := get_viewport()
	if vp == null:
		return Vector2.ZERO
	var mouse := vp.get_canvas_transform().affine_inverse() * vp.get_mouse_position()
	var d := mouse - from_global
	return d.normalized() if d.length() > 1.0 else Vector2.ZERO
