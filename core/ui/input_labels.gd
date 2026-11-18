class_name InputLabels
extends RefCounted
## Player-facing name of an action's binding for the device in use (D-01 gamepad parity), read
## from the live InputMap so rebinding changes what the cabinet prints. Keyboard keys use the
## engine's key name; mouse and pad names are tr() keys. Upper case: the cabinet face has no
## lower case (ART-001 §11).

const PAD_BUTTONS := {
	JOY_BUTTON_A: "ATTRACT_PAD_A", JOY_BUTTON_B: "ATTRACT_PAD_B", JOY_BUTTON_X: "ATTRACT_PAD_X",
	JOY_BUTTON_Y: "ATTRACT_PAD_Y", JOY_BUTTON_BACK: "ATTRACT_PAD_BACK", JOY_BUTTON_START: "ATTRACT_PAD_START",
	JOY_BUTTON_LEFT_STICK: "ATTRACT_PAD_LS", JOY_BUTTON_RIGHT_STICK: "ATTRACT_PAD_RS",
	JOY_BUTTON_LEFT_SHOULDER: "ATTRACT_PAD_LB", JOY_BUTTON_RIGHT_SHOULDER: "ATTRACT_PAD_RB",
}
const PAD_AXES := {
	JOY_AXIS_LEFT_X: "ATTRACT_PAD_LSTICK", JOY_AXIS_LEFT_Y: "ATTRACT_PAD_LSTICK",
	JOY_AXIS_RIGHT_X: "ATTRACT_PAD_RSTICK", JOY_AXIS_RIGHT_Y: "ATTRACT_PAD_RSTICK",
	JOY_AXIS_TRIGGER_LEFT: "ATTRACT_PAD_LT", JOY_AXIS_TRIGGER_RIGHT: "ATTRACT_PAD_RT",
}
const MOUSE_BUTTONS := {
	MOUSE_BUTTON_LEFT: "ATTRACT_MOUSE_LEFT", MOUSE_BUTTON_RIGHT: "ATTRACT_MOUSE_RIGHT",
	MOUSE_BUTTON_MIDDLE: "ATTRACT_MOUSE_MIDDLE",
}


## The first binding of `action` for the device; "" when the device has none.
static func action(action_name: StringName, gamepad: bool) -> String:
	if not InputMap.has_action(action_name):
		return ""
	for ev in InputMap.action_get_events(action_name):
		var s := event_label(ev, gamepad)
		if s != "":
			return s
	return ""


## The accept button. Godot's built-in `ui_accept` carries no pad binding here, so the pad's
## bottom face button stands in (see `is_accept`).
static func accept(gamepad: bool) -> String:
	var s := action(&"ui_accept", gamepad)
	return s if s != "" or not gamepad else _t(PAD_BUTTONS[JOY_BUTTON_A])


## True for `ui_accept` or the pad's bottom face button (pressed or released).
static func is_accept(event: InputEvent) -> bool:
	if event.is_action(&"ui_accept"):
		return true
	return event is InputEventJoypadButton and (event as InputEventJoypadButton).button_index == JOY_BUTTON_A


## The four directions of a move/aim vector as one label: "WASD" on keys, "LEFT STICK" on a pad.
static func vector(left: StringName, right: StringName, up: StringName, down: StringName, gamepad: bool) -> String:
	if gamepad:
		return action(left, true)
	var keys := ""
	for a: StringName in [up, left, down, right]:
		var k := action(a, false)
		if k.length() != 1:
			return "%s %s %s %s" % [action(up, false), action(left, false), action(down, false), action(right, false)]
		keys += k
	return keys


static func event_label(ev: InputEvent, gamepad: bool) -> String:
	if gamepad:
		if ev is InputEventJoypadButton and PAD_BUTTONS.has((ev as InputEventJoypadButton).button_index):
			return _t(PAD_BUTTONS[(ev as InputEventJoypadButton).button_index])
		if ev is InputEventJoypadMotion and PAD_AXES.has((ev as InputEventJoypadMotion).axis):
			return _t(PAD_AXES[(ev as InputEventJoypadMotion).axis])
		return ""
	if ev is InputEventKey:
		var k := ev as InputEventKey
		var code := k.keycode
		if k.physical_keycode != KEY_NONE:
			code = k.physical_keycode
			if DisplayServer.get_name() != "headless":   # the layout-aware name where a keyboard exists
				code = DisplayServer.keyboard_get_keycode_from_physical(k.physical_keycode)
		return OS.get_keycode_string(code).to_upper()
	if ev is InputEventMouseButton and MOUSE_BUTTONS.has((ev as InputEventMouseButton).button_index):
		return _t(MOUSE_BUTTONS[(ev as InputEventMouseButton).button_index])
	return ""


static func _t(key: String) -> String:
	return String(TranslationServer.translate(key))
