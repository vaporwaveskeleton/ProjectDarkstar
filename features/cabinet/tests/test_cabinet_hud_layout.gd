extends GdUnitTestSuite
## Act 0 HUD readability helpers: score scale fits the 80 px side panel; Sepulchre readout text.


func test_short_score_draws_at_double_scale() -> void:
	assert_int(CabinetHud.score_scale("12,345", CabinetHud.READOUT_W)).is_equal(2)
	assert_int(CabinetHud.score_scale("0", CabinetHud.READOUT_W)).is_equal(2)


func test_wide_score_falls_back_to_single_scale() -> void:
	assert_int(CabinetHud.score_scale("123,456", CabinetHud.READOUT_W)).is_equal(1)
	assert_int(CabinetHud.score_scale("1,234,567", CabinetHud.READOUT_W)).is_equal(1)


func test_label_fits_the_panel() -> void:
	assert_int(PixelText.width("SEPULCHRE", 1)).is_equal(53)
	assert_bool(CabinetHud.MARGIN + 53.0 <= CabinetHud.SIDE - 2.0).is_true()


func test_sepulchre_text_count_and_awake() -> void:
	assert_str(CabinetHud.sepulchre_text(7, 20, false)).is_equal("7/20")
	assert_str(CabinetHud.sepulchre_text(20, 20, false)).is_equal("20/20")
	assert_str(CabinetHud.sepulchre_text(20, 20, true)).is_equal("")


func test_sepulchre_count_fits_at_double_scale() -> void:
	assert_int(CabinetHud.score_scale(CabinetHud.sepulchre_text(20, 20, false), CabinetHud.READOUT_W)).is_equal(2)
