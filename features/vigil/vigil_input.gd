class_name VigilInput
extends Node
## Turns device input into intent (D-01: WASD + mouse aim, full gamepad parity).
## Holds no physics. Other code may write the fields directly (AI, replays, tests).
##
## Mouse aim follows the last InputEventMouseMotion this node saw (TECH-001 §9.1). The root
## Viewport's get_mouse_position() asks the OS for the cursor in a windowed run, so it ignores
## motion injected through Input.parse_input_event (automation, replays). For a real mouse both
## give the same point: Godot hands _input the event already in this viewport's coordinates.

const AIM_STICK_DEADZONE := 0.3   ## ✱

var move_dir: Vector2 = Vector2.ZERO
var braking: bool = false
var firing: bool = false
var stick_aim: Vector2 = Vector2.ZERO
var read_devices: bool = true

## Last pointer position from a motion event, in this viewport's (stretched, logical) coordinates.
var _pointer_pos: Vector2 = Vector2.ZERO
var _pointer_seen: bool = false


func _physics_process(_delta: float) -> void:
	if not read_devices:
		return
	move_dir = Input.get_vector(&"move_left", &"move_right", &"move_up", &"move_down")
	braking = Input.is_action_pressed(&"brake")
	firing = Input.is_action_pressed(&"fire_lance")
	stick_aim = Input.get_vector(&"aim_left", &"aim_right", &"aim_up", &"aim_down")


## Observes mouse motion; never marks it handled, so UI and other nodes still get it.
func _input(event: InputEvent) -> void:
	if event is InputEventMouseMotion:
		note_pointer((event as InputEventMouseMotion).position)


## Records a pointer position in viewport coordinates (as _input receives it).
func note_pointer(viewport_pos: Vector2) -> void:
	_pointer_pos = viewport_pos
	_pointer_seen = true


## Viewport coordinates -> canvas (world) coordinates of the nodes drawn with `canvas_xform`.
static func viewport_to_canvas(viewport_pos: Vector2, canvas_xform: Transform2D) -> Vector2:
	return canvas_xform.affine_inverse() * viewport_pos


## Where the mouse points in the Vigil's canvas (world) space. Uses the last motion event, or the
## viewport's own read before any motion event has arrived.
func mouse_canvas_position() -> Vector2:
	var vp := get_viewport()
	if vp == null:
		return Vector2.ZERO
	var pos := _pointer_pos if _pointer_seen else vp.get_mouse_position()
	return viewport_to_canvas(pos, vp.get_canvas_transform())


## Aim direction: right stick if pushed, else toward the mouse.
func aim_dir(from_global: Vector2) -> Vector2:
	if stick_aim.length() >= AIM_STICK_DEADZONE:
		return stick_aim.normalized()
	if not read_devices or get_viewport() == null:
		return Vector2.ZERO
	var d := mouse_canvas_position() - from_global
	return d.normalized() if d.length() > 1.0 else Vector2.ZERO
