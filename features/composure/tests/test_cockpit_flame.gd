extends GdUnitTestSuite
## CockpitFlame (WARP-001 §4.1, §4.2 L10): the Composure band by shape only, one colour in every
## band (never brightness, never a luminance flash), deterministic motion capped at 3 Hz, and a
## static but still distinct shape per band under reduced motion.

const STATS := preload("res://data/composure/cockpit_flame.tres")
const COMP_STATS := preload("res://data/composure/composure.tres")
const VIGIL_SCENE := preload("res://features/vigil/vigil.tscn")
const BANDS := [Composure.Band.CLEAR, Composure.Band.FRAYED, Composure.Band.UNMOORED, Composure.Band.HOLLOWED]

var _saved_persist: bool
var _saved_reduced: Variant
var _saved_photo: Variant


func before_test() -> void:
	_saved_persist = SettingsService.persist
	SettingsService.persist = false
	_saved_reduced = SettingsService.get_value(&"reduced_motion")
	_saved_photo = SettingsService.get_value(&"photosensitivity")
	SettingsService.set_value(&"reduced_motion", false)
	SettingsService.set_value(&"photosensitivity", false)


func after_test() -> void:
	SettingsService.set_value(&"reduced_motion", _saved_reduced)
	SettingsService.set_value(&"photosensitivity", _saved_photo)
	SettingsService.persist = _saved_persist


func _flame_with(band_value: float) -> CockpitFlame:
	var comp := auto_free(Composure.new()) as Composure
	comp.stats = COMP_STATS
	comp.sfx = Callable()
	add_child(comp)
	comp.set_physics_process(false)
	comp.change(band_value - comp.value)
	var f := auto_free(CockpitFlame.new()) as CockpitFlame
	f.stats = STATS
	f.composure = comp
	add_child(f)
	return f


func test_every_band_has_its_own_shape_at_rest() -> void:
	for i in BANDS.size():
		for j in range(i + 1, BANDS.size()):
			var a := CockpitFlame.shape_points(BANDS[i], 0.0, STATS)
			var b := CockpitFlame.shape_points(BANDS[j], 0.0, STATS)
			var same := a == b and CockpitFlame.fill_color(BANDS[i]) == CockpitFlame.fill_color(BANDS[j])
			assert_bool(same).override_failure_message("bands %d and %d look the same" % [i, j]).is_false()


func test_steady_and_hollow_do_not_move() -> void:
	for b: Composure.Band in [Composure.Band.CLEAR, Composure.Band.HOLLOWED]:
		assert_bool(CockpitFlame.is_animated(b)).is_false()
		assert_that(CockpitFlame.shape_points(b, 0.13, STATS)).is_equal(CockpitFlame.shape_points(b, 0.0, STATS))


func test_flickering_and_guttering_move_by_time_phase() -> void:
	for b: Composure.Band in [Composure.Band.FRAYED, Composure.Band.UNMOORED]:
		assert_bool(CockpitFlame.is_animated(b)).is_true()
		var a := CockpitFlame.shape_points(b, 0.0, STATS)
		var c := CockpitFlame.shape_points(b, 0.125, STATS)
		assert_bool(a == c).override_failure_message("band %d did not move" % b).is_false()
		# deterministic: the same time gives the same shape
		assert_that(CockpitFlame.shape_points(b, 0.125, STATS)).is_equal(c)


func test_motion_rate_is_capped_at_three_hz() -> void:
	assert_float(STATS.max_motion_hz).is_less_equal(3.0)
	assert_float(minf(STATS.flicker_hz, STATS.max_motion_hz)).is_less_equal(3.0)
	assert_float(minf(STATS.gutter_hz, STATS.max_motion_hz)).is_less_equal(3.0)


func test_colour_is_the_same_in_every_band() -> void:
	# Shape, never brightness: one outline colour everywhere; the only fill change is the hollow's void.
	for b: Composure.Band in BANDS:
		assert_that(CockpitFlame.line_color(b)).is_equal(Pal.PHOS_4)
	assert_that(CockpitFlame.fill_color(Composure.Band.CLEAR)).is_equal(Pal.PHOS_4)
	assert_that(CockpitFlame.fill_color(Composure.Band.FRAYED)).is_equal(Pal.PHOS_4)
	assert_that(CockpitFlame.fill_color(Composure.Band.UNMOORED)).is_equal(Pal.PHOS_4)
	assert_that(CockpitFlame.fill_color(Composure.Band.HOLLOWED)).is_equal(Pal.VOID_0)


func test_photosensitivity_keeps_shape_and_never_changes_colour() -> void:
	SettingsService.set_value(&"photosensitivity", true)
	var f := _flame_with(5.0)
	assert_int(f.current_band()).is_equal(Composure.Band.FRAYED)
	f._process(0.1)
	f._process(0.1)
	assert_float(f.phase_s).is_equal_approx(0.2, 1e-5)
	assert_that(CockpitFlame.line_color(f.current_band())).is_equal(Pal.PHOS_4)


func test_reduced_motion_freezes_the_phase() -> void:
	SettingsService.set_value(&"reduced_motion", true)
	var f := _flame_with(2.0)
	assert_int(f.current_band()).is_equal(Composure.Band.UNMOORED)
	f._process(0.5)
	f._process(0.5)
	assert_float(f.phase_s).is_equal(0.0)


func test_flame_reads_the_band_honestly() -> void:
	var f := _flame_with(10.0)
	assert_int(f.current_band()).is_equal(Composure.Band.CLEAR)
	f.composure.change(-10.0)
	assert_int(f.current_band()).is_equal(Composure.Band.HOLLOWED)
	f.composure = null
	assert_int(f.current_band()).is_equal(Composure.Band.CLEAR)


func test_vigil_carries_the_flame_under_its_visual() -> void:
	var v := auto_free(VIGIL_SCENE.instantiate()) as Vigil
	add_child(v)
	assert_object(v.cockpit_flame).is_not_null()
	assert_object(v.cockpit_flame.stats).is_not_null()
	assert_str(str(v.cockpit_flame.get_parent().name)).is_equal("Visual")
