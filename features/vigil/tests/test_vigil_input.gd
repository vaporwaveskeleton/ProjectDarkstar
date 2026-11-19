extends GdUnitTestSuite
## VigilInput mouse aim: the viewport -> canvas conversion, the motion-event path (what automation
## and replays inject), and right-stick priority. TECH-001 §9.1.

const EPS := 0.0001   ## ✱


func _make_input() -> VigilInput:
	var input: VigilInput = auto_free(VigilInput.new())
	add_child(input)
	return input


func test_conversion_matches_the_canvas_inverse() -> void:
	# A camera scrolled to (500, 300) at zoom 1: the viewport centre (320, 180) is world (820, 480).
	var canvas := Transform2D(0.0, Vector2(-500, -300))
	var world := VigilInput.viewport_to_canvas(Vector2(320, 180), canvas)
	assert_vector(world).is_equal_approx(Vector2(820, 480), Vector2(EPS, EPS))
	# Zoom 2 about the origin, then scrolled: inverse undoes both.
	var zoomed := Transform2D(0.0, Vector2(2, 2), 0.0, Vector2(-100, -40))
	var back := zoomed * VigilInput.viewport_to_canvas(Vector2(64, 36), zoomed)
	assert_vector(back).is_equal_approx(Vector2(64, 36), Vector2(EPS, EPS))


func test_conversion_matches_the_viewport_read_for_the_same_point() -> void:
	# The fallback read and the event path must agree: same viewport point -> same world point.
	var input := _make_input()
	var vp := input.get_viewport()
	var before := vp.get_canvas_transform().affine_inverse() * vp.get_mouse_position()
	input.note_pointer(vp.get_mouse_position())
	assert_vector(input.mouse_canvas_position()).is_equal_approx(before, Vector2(EPS, EPS))


func test_injected_motion_event_steers_aim() -> void:
	var input := _make_input()
	var vp := input.get_viewport()
	var to_world := vp.get_canvas_transform().affine_inverse()
	var ship := to_world * Vector2(320, 180)
	# Event in viewport coordinates, delivered through the viewport's input path to _input.
	var ev := InputEventMouseMotion.new()
	ev.position = Vector2(100, 60)
	ev.global_position = ev.position
	vp.push_input(ev, true)
	var want := (to_world * Vector2(100, 60) - ship).normalized()
	assert_vector(input.aim_dir(ship)).is_equal_approx(want, Vector2(EPS, EPS))
	assert_float(input.aim_dir(ship).x).is_less(0.0)
	assert_float(input.aim_dir(ship).y).is_less(0.0)


func test_parsed_window_event_lands_in_viewport_space() -> void:
	# The automation InputDriver path: window coordinates through Input.parse_input_event. Godot
	# undoes the root stretch before _input, so the Vigil sees the logical (640x360-space) point.
	var input := _make_input()
	var root := get_tree().root
	var logical := Vector2(123, 45)
	var ev := InputEventMouseMotion.new()
	ev.position = root.get_final_transform() * logical
	ev.global_position = ev.position
	Input.parse_input_event(ev)
	Input.flush_buffered_events()
	var want := VigilInput.viewport_to_canvas(logical, root.get_canvas_transform())
	assert_vector(input.mouse_canvas_position()).is_equal_approx(want, Vector2(0.01, 0.01))


class MotionListener extends Node:
	var seen: int = 0

	func _input(event: InputEvent) -> void:
		if event is InputEventMouseMotion:
			seen += 1


func test_motion_event_is_not_consumed() -> void:
	# _input runs in reverse tree order: a sibling added before VigilInput hears the event after it.
	var listener: MotionListener = auto_free(MotionListener.new())
	add_child(listener)
	var input := _make_input()
	var ev := InputEventMouseMotion.new()
	ev.position = Vector2(10, 10)
	input.get_viewport().push_input(ev, true)
	assert_int(listener.seen).is_equal(1)


func test_right_stick_overrides_mouse() -> void:
	var input := _make_input()
	input.note_pointer(Vector2.ZERO)
	input.stick_aim = Vector2(0.0, 0.9)
	assert_vector(input.aim_dir(Vector2(1000, 1000))).is_equal_approx(Vector2.DOWN, Vector2(EPS, EPS))


func test_no_aim_when_devices_are_off() -> void:
	var input := _make_input()
	input.note_pointer(Vector2.ZERO)
	input.read_devices = false
	assert_vector(input.aim_dir(Vector2(500, 500))).is_equal(Vector2.ZERO)
