extends GdUnitTestSuite
## ScreenFit (TECH-001 §1.3): the integer step, the centred screen and the window ↔ screen mapping.

const GRID := Vector2i(640, 360)
const PORTRAIT := Vector2i(240, 320)   # the grid PR B moves to; the maths must already hold for it

# window → [k, screen display size, physical origin]
const CASES := [
	[Vector2i(1280, 720), 2, Vector2i(1280, 720), Vector2i(0, 0)],
	[Vector2i(1366, 768), 2, Vector2i(1280, 720), Vector2i(43, 24)],
	[Vector2i(1280, 800), 2, Vector2i(1280, 720), Vector2i(0, 40)],
	[Vector2i(1600, 900), 2, Vector2i(1280, 720), Vector2i(160, 90)],
	[Vector2i(1920, 1080), 3, Vector2i(1920, 1080), Vector2i(0, 0)],
	[Vector2i(2560, 1440), 4, Vector2i(2560, 1440), Vector2i(0, 0)],
	[Vector2i(3840, 2160), 6, Vector2i(3840, 2160), Vector2i(0, 0)],
	[Vector2i(320, 180), 1, Vector2i(640, 360), Vector2i(-160, -90)],   # tiny: never below 1x
]


func test_integer_scale_table() -> void:
	for c in CASES:
		assert_int(ScreenFit.integer_scale(c[0])).override_failure_message("k at %s" % c[0]).is_equal(c[1])


func test_screen_is_the_grid_times_k_and_centred() -> void:
	for c in CASES:
		var r := ScreenFit.screen_rect_physical(c[0], GRID)
		assert_object(r.size).override_failure_message("size at %s" % c[0]).is_equal(c[2])
		assert_object(r.position).override_failure_message("origin at %s" % c[0]).is_equal(c[3])


func test_screen_stays_inside_the_window_when_the_window_is_big_enough() -> void:
	for c in CASES:
		if c[0].x >= 640 and c[0].y >= 360:
			var r := ScreenFit.screen_rect_physical(c[0], GRID)
			assert_bool(Rect2i(Vector2i.ZERO, c[0]).encloses(r)).override_failure_message("%s" % c[0]).is_true()


func test_content_scale_matches_the_canvas_items_expand_rule() -> void:
	assert_float(ScreenFit.content_scale(Vector2i(1920, 1080))).is_equal(3.0)
	assert_float(ScreenFit.content_scale(Vector2i(1280, 800))).is_equal(2.0)
	assert_float(ScreenFit.content_scale(Vector2i(1366, 768))).is_equal_approx(2.13333, 0.0001)


func test_hole_is_the_grid_at_one_x_centred_in_the_reference() -> void:
	assert_object(ScreenFit.hole_rect(GRID)).is_equal(Rect2(0, 0, 640, 360))
	assert_object(ScreenFit.hole_rect(PORTRAIT)).is_equal(Rect2(200, 20, 240, 320))


func test_rig_lands_the_hole_on_the_screen() -> void:
	for win in [Vector2i(1280, 720), Vector2i(1366, 768), Vector2i(1280, 800), Vector2i(1920, 1080), Vector2i(3840, 2160)]:
		for grid in [GRID, PORTRAIT]:
			var t := ScreenFit.rig_transform(win, grid)
			var s := ScreenFit.content_scale(win)
			var hole := ScreenFit.hole_rect(grid)
			var r := ScreenFit.screen_rect_physical(win, grid)
			assert_vector(t * hole.position * s).override_failure_message("%s %s" % [win, grid]) \
				.is_equal_approx(Vector2(r.position), Vector2(0.01, 0.01))
			assert_vector(t * hole.end * s).is_equal_approx(Vector2(r.end), Vector2(0.01, 0.01))


func test_window_screen_round_trip() -> void:
	for c in CASES:
		for grid in [GRID, PORTRAIT]:
			var p := Vector2(37.0, 91.0)
			var w := ScreenFit.screen_to_window(c[0], grid, p)
			assert_vector(ScreenFit.window_to_screen(c[0], grid, w)).is_equal_approx(p, Vector2(0.001, 0.001))


func test_window_to_screen_corners() -> void:
	var win := Vector2i(1366, 768)
	var r := ScreenFit.screen_rect_physical(win, GRID)
	assert_vector(ScreenFit.window_to_screen(win, GRID, Vector2(r.position))).is_equal(Vector2.ZERO)
	assert_vector(ScreenFit.window_to_screen(win, GRID, Vector2(r.end))).is_equal(Vector2(GRID))
