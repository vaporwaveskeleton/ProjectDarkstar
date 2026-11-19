extends GdUnitTestSuite
## Act 0 HUD strip (owner 2026-11-18, Q-T31): every live readout sits inside the 40-px strip at the top
## of the 256×304 screen, none overlap, the compass is honest and inside, a 2× score that does not fit
## drops to 1×, the demo credit line and the Sepulchre AWAKE text fit. The bezel carries no readouts.

const SPEC := "res://data/cabinet/cabinet_screen.tres"

const TEXTS := [["0", "0", "0/20"], ["12,345", "12,345", "20/20"], ["123,456", "99,999,999", "20/20"], ["99,999,999", "99,999,999", "AWAKE"]]


func _spec() -> CabinetScreenSpec:
	return load(SPEC) as CabinetScreenSpec


func test_short_score_draws_at_double_scale() -> void:
	assert_int(CabinetScreenHud.score_scale("12,345", CabinetScreenHud.SCORE_MAX_W)).is_equal(2)
	assert_int(CabinetScreenHud.score_scale("0", CabinetScreenHud.SCORE_MAX_W)).is_equal(2)


func test_wide_score_falls_back_to_single_scale() -> void:
	assert_int(CabinetScreenHud.score_scale("123,456", CabinetScreenHud.SCORE_MAX_W)).is_equal(1)
	assert_int(CabinetScreenHud.score_scale("99,999,999", CabinetScreenHud.SCORE_MAX_W)).is_equal(1)


func test_a_double_scale_score_never_reaches_the_compass() -> void:
	var score_right := CabinetScreenHud.LEFT_X + CabinetScreenHud.SCORE_MAX_W
	assert_bool(score_right <= CabinetScreenHud.COMPASS.position.x - 4.0).is_true()
	assert_float(float(PixelText.width("12,345", 2))).is_less_equal(CabinetScreenHud.SCORE_MAX_W)


func test_sepulchre_text_count_and_awake() -> void:
	assert_str(CabinetScreenHud.sepulchre_text(7, 20, false)).is_equal("7/20")
	assert_str(CabinetScreenHud.sepulchre_text(20, 20, false)).is_equal("20/20")
	assert_str(CabinetScreenHud.sepulchre_text(20, 20, true)).is_equal("")


func test_every_readout_sits_inside_the_strip() -> void:
	var strip := _spec().strip_rect()
	for texts: Array in TEXTS:
		for entry in CabinetScreenHud.readout_boxes(texts[0], texts[1], texts[2] if texts[2] != "AWAKE" else tr("CAB_SEP_AWAKE"), 6, 5):
			var box: Rect2 = entry["box"]
			assert_bool(strip.grow(-1.0).encloses(box)) \
				.override_failure_message("%s %s is outside the strip %s" % [entry["name"], box, strip]).is_true()


func test_no_two_readouts_overlap() -> void:
	for texts: Array in TEXTS:
		var boxes := CabinetScreenHud.readout_boxes(texts[0], texts[1], texts[2] if texts[2] != "AWAKE" else tr("CAB_SEP_AWAKE"), 6, 5)
		for i in boxes.size():
			for j in range(i + 1, boxes.size()):
				var a: Rect2 = boxes[i]["box"]
				var b: Rect2 = boxes[j]["box"]
				assert_bool(a.intersects(b)).override_failure_message("%s %s overlaps %s %s" % [boxes[i]["name"], a, boxes[j]["name"], b]).is_false()


func test_the_compass_is_inside_the_strip_and_centred() -> void:
	var spec := _spec()
	assert_bool(spec.strip_rect().grow(-1.0).encloses(CabinetScreenHud.COMPASS)).is_true()
	assert_float(CabinetScreenHud.COMPASS.get_center().x).is_equal(float(spec.grid.x) * 0.5)
	assert_float(CabinetScreenHud.COMPASS.end.y).is_less(CabinetScreenHud.SEPARATOR_Y)


func test_awake_fits_left_of_the_first_lamp_and_clear_of_the_compass() -> void:
	var w := float(PixelText.width(tr("CAB_SEP_AWAKE")))
	var left := CabinetScreenHud.SEPULCHRE_END_X - w
	assert_float(left).is_greater_equal(CabinetScreenHud.COMPASS.end.x + 2.0)
	assert_float(CabinetScreenHud.SEPULCHRE_END_X).is_less(CabinetScreenHud.lamp_centre(0, 5).x - 4.0)


func test_lamps_end_at_the_right_block_and_step_evenly() -> void:
	var last := CabinetScreenHud.lamp_centre(4, 5)
	assert_float(last.x + 4.0).is_equal(CabinetScreenHud.LAMP_END_X)
	assert_float(CabinetScreenHud.lamp_centre(1, 5).x - CabinetScreenHud.lamp_centre(0, 5).x).is_equal(CabinetScreenHud.LAMP_STEP)
	assert_float(last.y).is_equal(CabinetScreenHud.LAMP_Y)
	assert_int(CabinetScreenHud.lamp_count(9)).is_equal(CabinetScreenHud.MAX_LAMPS)


func test_spare_vigil_icons_stay_left_of_the_compass() -> void:
	assert_int(CabinetScreenHud.icon_count(1)).is_equal(0)
	assert_int(CabinetScreenHud.icon_count(4)).is_equal(3)
	var most := CabinetScreenHud.icon_count(99)
	var right := CabinetScreenHud.ICON_X + CabinetScreenHud.ICON_STEP * (most - 1) + 8.0
	assert_float(right).is_less_equal(CabinetScreenHud.ICON_LIMIT_X)
	assert_float(CabinetScreenHud.ICON_LIMIT_X).is_less(CabinetScreenHud.COMPASS.position.x)


func test_demo_credit_line_is_inside_the_play_view() -> void:
	var spec := _spec()
	for s in [tr("CAB_CREDIT"), tr("CAB_CREDIT_COUNT") % 0, tr("CAB_CREDIT_COUNT") % 1]:
		var box := CabinetScreenHud.credit_box(s, Vector2(spec.grid))
		assert_bool(spec.play_rect().grow(-1.0).encloses(box)).override_failure_message("'%s' %s is outside the play view" % [s, box]).is_true()
		# and the maker mark under it is clear of it
		var maker := Rect2(0, spec.grid.y - CabinetScreenHud.MAKER_ABOVE_FOOT, spec.grid.x, CabinetScreenHud.TEXT_H)
		assert_bool(box.intersects(maker)).is_false()


func test_the_bezel_has_no_readout_windows() -> void:
	for id in ["score", "vigils", "credit", "hi", "glass", "sepulchre"]:
		for p in BezelArt.build_left() + BezelArt.build_right():
			assert_bool(String(p.id).contains("_%s_cut" % id)).override_failure_message("window %s still on the bezel" % id).is_false()


func test_peel_slides_the_print_columns_apart() -> void:
	var left := BezelPrint.new()
	var right := BezelPrint.new()
	right.column = &"right"
	add_child(left)
	add_child(right)
	auto_free(left)
	auto_free(right)
	left.peel = 0.5
	right.peel = 0.5
	assert_float(left.position.x).is_equal(CabinetBezel.left_x() - 0.5 * (CabinetBezel.SIDE + 20.0))
	assert_float(right.position.x).is_equal(CabinetBezel.right_x() + 0.5 * (CabinetBezel.SIDE + 20.0))
	left.peel = 1.0
	assert_bool(left.visible).is_false()
