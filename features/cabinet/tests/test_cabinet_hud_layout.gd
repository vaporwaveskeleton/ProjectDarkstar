extends GdUnitTestSuite
## Act 0 HUD readability helpers: score scale fits the readout windows; every lit readout sits
## inside the window cut for it in the bezel print; Sepulchre readout text.


func test_short_score_draws_at_double_scale() -> void:
	assert_int(CabinetHud.score_scale("12,345", CabinetHud.READOUT_W)).is_equal(2)
	assert_int(CabinetHud.score_scale("0", CabinetHud.READOUT_W)).is_equal(2)


func test_wide_score_falls_back_to_single_scale() -> void:
	assert_int(CabinetHud.score_scale("123,456", CabinetHud.READOUT_W)).is_equal(1)
	assert_int(CabinetHud.score_scale("1,234,567", CabinetHud.READOUT_W)).is_equal(1)


func test_widest_double_scale_readout_fits_a_window() -> void:
	# a window is 74 wide with a 1 px bevel each side; the readout starts MARGIN in and keeps 1 px clear
	var inner_right := CabinetBezel.LEFT_SCORE.end.x - 1.0
	assert_bool(CabinetBezel.MARGIN + CabinetBezel.READOUT_W + 1.0 <= inner_right).is_true()
	assert_float(float(PixelText.width("12,345", 2))).is_less_equal(CabinetBezel.READOUT_W)


func test_label_fits_the_window() -> void:
	assert_int(PixelText.width("SEPULCHRE", 1)).is_equal(53)


func test_sepulchre_text_count_and_awake() -> void:
	assert_str(CabinetHud.sepulchre_text(7, 20, false)).is_equal("7/20")
	assert_str(CabinetHud.sepulchre_text(20, 20, false)).is_equal("20/20")
	assert_str(CabinetHud.sepulchre_text(20, 20, true)).is_equal("")


func test_sepulchre_count_fits_at_double_scale() -> void:
	assert_int(CabinetHud.score_scale(CabinetHud.sepulchre_text(20, 20, false), CabinetHud.READOUT_W)).is_equal(2)


func test_every_readout_fits_inside_its_window() -> void:
	for texts: Array in [["0", "0", "0/20"], ["12,345", "12,345", "20/20"], ["99,999,999", "99,999,999", tr("CAB_SEP_AWAKE")]]:
		for entry in CabinetHud.readout_boxes(texts[0], texts[1], texts[2]):
			var window: Rect2 = entry["window"]
			var box: Rect2 = entry["box"]
			assert_bool(window.grow(-1.0).encloses(box)) \
				.override_failure_message("%s %s is outside its window %s" % [entry["name"], box, window]).is_true()


func test_credit_text_fits_the_credit_window() -> void:
	for s in [tr("CAB_CREDIT"), tr("CAB_CREDIT_COUNT") % 0, tr("CAB_CREDIT_COUNT") % 1]:
		var boxes := CabinetBezel.credit_boxes(s)
		assert_int(boxes.size()).is_greater(0)
		for box in boxes:
			assert_bool(CabinetBezel.LEFT_CREDIT.grow(-1.0).encloses(box)) \
				.override_failure_message("'%s' %s is outside the credit window" % [s, box]).is_true()


func test_insert_credit_wraps_to_two_lines() -> void:
	assert_int(CabinetBezel.credit_lines("INSERT CREDIT").size()).is_equal(2)
	assert_int(CabinetBezel.credit_lines("CREDIT 0").size()).is_equal(1)


func test_windows_lie_inside_their_column_and_do_not_overlap() -> void:
	var by_column := {&"left": [], &"right": []}
	for w in CabinetBezel.windows():
		var r: Rect2 = w["rect"]
		assert_bool(Rect2(0, 10, 78, 340).encloses(r)).is_true()
		(by_column[w["column"]] as Array).append(r)
	for column: StringName in by_column:
		var rects: Array = by_column[column]
		for i in rects.size():
			for j in range(i + 1, rects.size()):
				assert_bool((rects[i] as Rect2).intersects(rects[j] as Rect2)).is_false()


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
	assert_float(left.position.x).is_equal(-0.5 * (CabinetBezel.SIDE + 20.0))
	assert_float(right.position.x).is_equal(CabinetBezel.RIGHT_X + 0.5 * (CabinetBezel.SIDE + 20.0))
	left.peel = 1.0
	assert_bool(left.visible).is_false()
