extends RefCounted
## Real input for the scenario runner: every event goes through Input.parse_input_event, so polled
## is_action_pressed and _unhandled_input handlers both see it. Tracks what is held so
## release_all() can guarantee nothing survives a failure, a quit or a route change.
## No class_name: release builds may exclude core/automation.

const MIN_HOLD_FRAMES := 2   ## ✱ a press must span a physics frame so polling code and just_pressed see it

## Held input. Keys are action names / keycodes / mouse button indices; values are true.
var held_actions: Dictionary = {}
var held_keys: Dictionary = {}
var held_buttons: Dictionary = {}
var _mouse_pos := Vector2.ZERO


static func clamp_frames(frames: int) -> int:
	return maxi(frames, MIN_HOLD_FRAMES)


func is_idle() -> bool:
	return held_actions.is_empty() and held_keys.is_empty() and held_buttons.is_empty()


func press(action: StringName) -> void:
	held_actions[action] = true
	_send_action(action, true)


func release(action: StringName) -> void:
	held_actions.erase(action)
	_send_action(action, false)


func key_press(keycode: int) -> void:
	held_keys[keycode] = true
	_send_key(keycode, true)


func key_release(keycode: int) -> void:
	held_keys.erase(keycode)
	_send_key(keycode, false)


## `pos` is in the root viewport's logical (canvas) space, like the 640x360 bezel layout.
func mouse_move(pos: Vector2) -> void:
	_mouse_pos = _to_window(pos)
	var ev := InputEventMouseMotion.new()
	ev.position = _mouse_pos
	ev.global_position = _mouse_pos
	ev.button_mask = _button_mask()
	Input.parse_input_event(ev)
	Input.flush_buffered_events()   # deliver now: parse_input_event alone waits for the next process frame


func mouse_button(button: int, pressed: bool) -> void:
	if pressed:
		held_buttons[button] = true
	else:
		held_buttons.erase(button)
	_send_button(button, pressed)


func release_all() -> void:
	for a: Variant in held_actions.keys():
		_send_action(a as StringName, false)
	for k: Variant in held_keys.keys():
		_send_key(k as int, false)
	for b: Variant in held_buttons.keys():
		_send_button(b as int, false)
	held_actions.clear()
	held_keys.clear()
	held_buttons.clear()
	Input.flush_buffered_events()


func _send_action(action: StringName, pressed: bool) -> void:
	var ev := InputEventAction.new()
	ev.action = action
	ev.pressed = pressed
	ev.strength = 1.0 if pressed else 0.0
	Input.parse_input_event(ev)
	Input.flush_buffered_events()   # deliver now: parse_input_event alone waits for the next process frame


func _send_key(keycode: int, pressed: bool) -> void:
	var ev := InputEventKey.new()
	ev.keycode = keycode as Key
	ev.physical_keycode = keycode as Key
	ev.pressed = pressed
	Input.parse_input_event(ev)
	Input.flush_buffered_events()   # deliver now: parse_input_event alone waits for the next process frame


func _send_button(button: int, pressed: bool) -> void:
	var ev := InputEventMouseButton.new()
	ev.button_index = button as MouseButton
	ev.pressed = pressed
	ev.position = _mouse_pos
	ev.global_position = _mouse_pos
	ev.button_mask = _button_mask()
	Input.parse_input_event(ev)
	Input.flush_buffered_events()   # deliver now: parse_input_event alone waits for the next process frame


func _button_mask() -> int:
	var mask := 0
	for b: Variant in held_buttons.keys():
		mask |= 1 << ((b as int) - 1)
	return mask


func _to_window(logical: Vector2) -> Vector2:
	var tree := Engine.get_main_loop() as SceneTree
	return tree.root.get_final_transform() * logical
