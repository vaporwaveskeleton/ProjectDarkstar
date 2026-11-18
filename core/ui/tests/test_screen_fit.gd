extends GdUnitTestSuite
## ScreenFit (TECH-001 §1.3): the integer step, the centred screen and the window ↔ screen mapping.

const GRID := Vector2i(640, 360)
const PORTRAIT := Vector2i(256, 304)   # the Act 0 grid (owner, 2026-11-18): the Williams 304×256 circuit, rotated

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
	assert_object(ScreenFit.hole_rect(PORTRAIT)).is_equal(Rect2(192, 28, 256, 304))


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


# Steam Hardware Survey targets (Oct 2026): window → [k, portrait screen display size]
const STEAM := [
	[Vector2i(1920, 1080), 3, Vector2i(768, 912)],
	[Vector2i(2560, 1440), 4, Vector2i(1024, 1216)],
	[Vector2i(2560, 1600), 4, Vector2i(1024, 1216)],
	[Vector2i(3840, 2160), 6, Vector2i(1536, 1824)],
	[Vector2i(3440, 1440), 4, Vector2i(1024, 1216)],
	[Vector2i(1920, 1200), 3, Vector2i(768, 912)],
	[Vector2i(1366, 768), 2, Vector2i(512, 608)],
	[Vector2i(1280, 800), 2, Vector2i(512, 608)],
]


func test_portrait_screen_is_integer_scaled_centred_and_fits_every_steam_size() -> void:
	for c in STEAM:
		var win: Vector2i = c[0]
		assert_int(ScreenFit.integer_scale(win)).override_failure_message("k at %s" % win).is_equal(c[1])
		var r := ScreenFit.screen_rect_physical(win, PORTRAIT)
		assert_object(r.size).override_failure_message("size at %s" % win).is_equal(c[2])
		assert_bool(Rect2i(Vector2i.ZERO, win).encloses(r)).override_failure_message("hole outside window %s" % win).is_true()
		# centred to within half a display px (the origin is a whole px)
		var centre := Vector2(r.position) + Vector2(r.size) * 0.5
		assert_vector(centre).is_equal_approx(Vector2(win) * 0.5, Vector2(0.5, 0.5))
		assert_int(r.size.x % int(c[1])).is_equal(0)


## No bars: the bezel rect is the whole window in rig units, the hole sits centred in it, and the
## rig transform maps it onto exactly the window rect.
func test_bezel_rect_covers_the_whole_window_with_the_hole_centred() -> void:
	for c in STEAM + CASES:
		var win: Vector2i = c[0]
		if win.x < 640 or win.y < 360:
			continue   # below the reference the screen itself overflows the window; not a target
		for grid in [PORTRAIT]:
			var b := ScreenFit.bezel_rect(win, grid)
			var k := float(ScreenFit.integer_scale(win))
			assert_vector(b.size * k).is_equal_approx(Vector2(win), Vector2(0.001, 0.001))
			var hole := ScreenFit.hole_rect(grid)
			assert_bool(b.encloses(hole)).override_failure_message("hole outside bezel rect at %s" % win).is_true()
			# the hole's centre is the window's centre (half a px of rounding at odd sizes)
			assert_vector((hole.get_center() - b.position) * k).is_equal_approx(Vector2(win) * 0.5, Vector2(0.5, 0.5))
			# rig transform of the bezel rect = the window
			var t := ScreenFit.rig_transform(win, grid)
			var s := ScreenFit.content_scale(win)
			assert_vector(t * b.position * s).is_equal_approx(Vector2.ZERO, Vector2(0.01, 0.01))
			assert_vector(t * b.end * s).is_equal_approx(Vector2(win), Vector2(0.01, 0.01))


func test_bezel_rect_is_the_reference_at_16_9_integer_sizes() -> void:
	for win in [Vector2i(1920, 1080), Vector2i(2560, 1440), Vector2i(3840, 2160), Vector2i(1280, 720)]:
		assert_object(ScreenFit.bezel_rect(win, PORTRAIT)).is_equal(Rect2(0, 0, 640, 360))
