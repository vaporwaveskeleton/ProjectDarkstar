extends GdUnitTestSuite
## HudLiar T1 slice (TECH-001 §5.2; WARP-001 §4.2 class table, caps, §4.4, §4.7): Smear and Glyph
## only, never a Lie; the Vigil's own position never moves; Steady Ledger on = the honest model.

var _was_steady: bool = true
var _was_persist: bool = true


func before_test() -> void:
	_was_persist = SettingsService.persist
	_was_steady = bool(SettingsService.get_value(&"steady_ledger"))
	SettingsService.persist = false


func after_test() -> void:
	SettingsService.set_value(&"steady_ledger", _was_steady)
	SettingsService.persist = _was_persist


func _model(p: Array[Vector2]) -> HudModel:
	var m := HudModel.new()
	m.marker_world = PackedVector2Array(p)
	m.own_position = p[0]
	m.has_own_position = true
	var kinds: Array[StringName] = [&"vigil"]
	for i in range(1, p.size()):
		kinds.append(&"grub")
	m.marker_kinds = kinds
	return m


func test_t1_caps_two_deviations_and_no_lies() -> void:
	var l := HudLiar.new()
	l.tier = 1
	assert_int(l.cap()).is_equal(2)
	assert_int(l.lie_cap()).is_equal(0)
	assert_bool(l.begin_smear(1, 0.5, 5.0)).is_true()
	assert_bool(l.begin_glyph(0, 5.0)).is_true()
	l.end_all()
	assert_bool(l.begin_smear(1, 0.5, 5.0)).is_false()   # cap spent for the sector
	assert_bool(l.has_method(&"begin_lie")).is_false()


func test_smear_never_takes_the_own_position() -> void:
	var l := HudLiar.new()
	assert_bool(l.begin_smear(0, 0.5, 5.0)).is_false()


func test_smear_shows_the_lagged_position_with_a_tail_to_the_truth() -> void:
	SettingsService.set_value(&"steady_ledger", false)
	var l := HudLiar.new()
	var m := _model([Vector2(10, 10), Vector2(100, 100)])
	m.liar = l
	for i in 30:
		l.now_s = float(i) * 0.1
		m.marker_world[1] = Vector2(100 + i * 10, 100)
		m.presented()
	assert_bool(l.begin_smear(1, 1.0, 5.0)).is_true()
	l.now_s = 3.0
	m.marker_world[1] = Vector2(400, 100)
	var shown := m.presented()
	assert_int(shown.smear_slot).is_equal(1)
	assert_vector(shown.smear_tail).is_equal(Vector2(400, 100))
	assert_float(shown.marker_world[1].x).is_less(400.0)
	assert_vector(shown.own_position).is_equal(m.own_position)
	assert_vector(shown.marker_world[0]).is_equal(m.marker_world[0])
	assert_vector(m.marker_world[1]).is_equal(Vector2(400, 100))   # the model itself is untouched


func test_steady_ledger_on_presents_the_honest_model_even_with_a_liar() -> void:
	SettingsService.set_value(&"steady_ledger", true)
	var l := HudLiar.new()
	var m := _model([Vector2(10, 10), Vector2(100, 100)])
	m.liar = l
	l.begin_smear(1, 0.1, 5.0)
	l.begin_glyph(0, 5.0)
	assert_object(m.presented()).is_same(m)
	assert_that(l.glyph_for("3", 5, 6)).is_null()


func test_glyph_swaps_one_digit_for_a_neighbour() -> void:
	SettingsService.set_value(&"steady_ledger", false)
	var l := HudLiar.new()
	assert_bool(l.begin_glyph(1, 5.0)).is_true()
	assert_that(l.glyph_for("3", 4, 6)).is_equal("8")   # second digit from the right
	assert_that(l.glyph_for("3", 5, 6)).is_null()
	l.now_s = 6.0
	assert_that(l.glyph_for("3", 4, 6)).is_null()       # over


func test_vigil_index_value_stays_true_under_the_glyph() -> void:
	SettingsService.set_value(&"steady_ledger", false)
	var strip: VigilIndexStrip = auto_free(VigilIndexStrip.new())
	strip.size = Vector2(80, 12)
	add_child(strip)
	var l := HudLiar.new()
	strip.liar = l
	strip.value = 1234
	l.begin_glyph(0, 5.0)
	strip._process(0.0)
	assert_bool(strip.smudged()).is_true()
	assert_int(strip.value).is_equal(1234)
	assert_str(strip.shown_text()).is_equal("001234")
