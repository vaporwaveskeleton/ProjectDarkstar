extends GdUnitTestSuite
## Input map matches GDD-001 §4.1 (keyboard + mouse) and §4.3 (gamepad), ruling R-12.

const KEYS := {
	&"move_up": KEY_W, &"move_left": KEY_A, &"move_down": KEY_S, &"move_right": KEY_D,
	&"surgelight": KEY_SHIFT, &"lantern_toggle": KEY_E, &"ward_pulse": KEY_Q,
	&"unravel_focus": KEY_R, &"brake": KEY_SPACE, &"open_codex": KEY_TAB, &"pause": KEY_ESCAPE,
	&"relic_1": KEY_1, &"relic_2": KEY_2, &"relic_3": KEY_3,
}
const MOUSE := { &"fire_lance": MOUSE_BUTTON_LEFT, &"deploy_charge": MOUSE_BUTTON_RIGHT }
const PAD_BUTTONS := {
	&"surgelight": JOY_BUTTON_A, &"lantern_toggle": JOY_BUTTON_X, &"ward_pulse": JOY_BUTTON_B,
	&"unravel_focus": JOY_BUTTON_Y, &"brake": JOY_BUTTON_LEFT_STICK, &"pause": JOY_BUTTON_START,
}
const PAD_AXES := { &"fire_lance": JOY_AXIS_TRIGGER_RIGHT, &"deploy_charge": JOY_AXIS_TRIGGER_LEFT }


func _events(action: StringName) -> Array[InputEvent]:
	assert_bool(InputMap.has_action(action)).override_failure_message("missing action %s" % action).is_true()
	return InputMap.action_get_events(action) if InputMap.has_action(action) else ([] as Array[InputEvent])


func test_keyboard_bindings_match_gdd_4_1() -> void:
	for action in KEYS:
		var found := false
		for e in _events(action):
			if e is InputEventKey and (e as InputEventKey).physical_keycode == KEYS[action]:
				found = true
		assert_bool(found).override_failure_message("%s not on key %s" % [action, KEYS[action]]).is_true()


func test_mouse_bindings_match_gdd_4_1() -> void:
	for action in MOUSE:
		var found := false
		for e in _events(action):
			if e is InputEventMouseButton and (e as InputEventMouseButton).button_index == MOUSE[action]:
				found = true
		assert_bool(found).override_failure_message("%s not on mouse %s" % [action, MOUSE[action]]).is_true()


func test_gamepad_bindings_match_gdd_4_3() -> void:
	for action in PAD_BUTTONS:
		var found := false
		for e in _events(action):
			if e is InputEventJoypadButton and (e as InputEventJoypadButton).button_index == PAD_BUTTONS[action]:
				found = true
		assert_bool(found).override_failure_message("%s not on pad button %s" % [action, PAD_BUTTONS[action]]).is_true()
	for action in PAD_AXES:
		var found := false
		for e in _events(action):
			if e is InputEventJoypadMotion and (e as InputEventJoypadMotion).axis == PAD_AXES[action]:
				found = true
		assert_bool(found).override_failure_message("%s not on pad axis %s" % [action, PAD_AXES[action]]).is_true()


func test_no_two_gameplay_actions_share_a_key() -> void:
	var seen := {}
	var clashes: Array[String] = []
	for action in KEYS:
		for e in _events(action):
			if e is InputEventKey:
				var k := (e as InputEventKey).physical_keycode
				if seen.has(k) and seen[k] != action:
					clashes.append("%s/%s" % [seen[k], action])
				seen[k] = action
	assert_array(clashes).is_empty()
