class_name InputModeTracker
extends Node
## Tracks whether the player is using keyboard+mouse or a gamepad, so glyphs and the
## mouse cursor follow the last device used (D-01 full gamepad parity). One per UI scene.

signal input_mode_changed(mode: Mode)

enum Mode { KEYBOARD_MOUSE, GAMEPAD }

const STICK_THRESHOLD := 0.5   ## ✱ ignore stick drift below this

var mode: Mode = Mode.KEYBOARD_MOUSE


func _input(event: InputEvent) -> void:
	feed(event)


## Public so tests can inject events.
func feed(event: InputEvent) -> void:
	var next := mode
	if event is InputEventJoypadButton:
		next = Mode.GAMEPAD
	elif event is InputEventJoypadMotion and absf((event as InputEventJoypadMotion).axis_value) >= STICK_THRESHOLD:
		next = Mode.GAMEPAD
	elif event is InputEventKey or event is InputEventMouseButton:
		next = Mode.KEYBOARD_MOUSE
	elif event is InputEventMouseMotion and (event as InputEventMouseMotion).relative.length() > 0.0:
		next = Mode.KEYBOARD_MOUSE
	if next != mode:
		mode = next
		input_mode_changed.emit(mode)
