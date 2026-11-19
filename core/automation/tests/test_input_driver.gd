extends GdUnitTestSuite
## InputDriver: real events reach both polled input and _unhandled_input; release_all leaves nothing held.

const Driver := preload("res://core/automation/input_driver.gd")


class _Probe extends Node:
	var presses := 0
	func _unhandled_input(event: InputEvent) -> void:
		if event.is_action_pressed(&"move_right"):
			presses += 1


var drv: RefCounted
var probe: _Probe


func before_test() -> void:
	drv = Driver.new()
	probe = auto_free(_Probe.new())
	add_child(probe)


func after_test() -> void:
	drv.release_all()


func _frames(n: int) -> void:
	for _i in n:
		await get_tree().physics_frame


func test_action_is_polled_and_delivered_as_event() -> void:
	drv.press(&"move_right")
	await _frames(3)
	assert_bool(Input.is_action_pressed(&"move_right")).is_true()
	assert_int(probe.presses).is_equal(1)
	drv.release(&"move_right")
	await _frames(3)
	assert_bool(Input.is_action_pressed(&"move_right")).is_false()
	assert_bool(drv.is_idle()).is_true()


func test_release_all_clears_every_kind() -> void:
	drv.press(&"move_right")
	drv.press(&"fire_lance")
	drv.key_press(KEY_SHIFT)
	drv.mouse_button(MOUSE_BUTTON_LEFT, true)
	await get_tree().physics_frame
	assert_bool(drv.is_idle()).is_false()
	drv.release_all()
	assert_bool(drv.is_idle()).is_true()
	await _frames(3)
	assert_bool(Input.is_action_pressed(&"move_right")).is_false()
	assert_bool(Input.is_action_pressed(&"fire_lance")).is_false()
	assert_bool(Input.is_key_pressed(KEY_SHIFT)).is_false()
	assert_bool(Input.is_mouse_button_pressed(MOUSE_BUTTON_LEFT)).is_false()


func test_hold_is_clamped_to_two_frames() -> void:
	assert_int(Driver.clamp_frames(0)).is_equal(2)
	assert_int(Driver.clamp_frames(1)).is_equal(2)
	assert_int(Driver.clamp_frames(30)).is_equal(30)


func test_mouse_move_updates_the_viewport_mouse() -> void:
	drv.mouse_move(Vector2(120, 40))
	await _frames(3)
	assert_vector(get_viewport().get_mouse_position()).is_equal_approx(Vector2(120, 40), Vector2(0.5, 0.5))
