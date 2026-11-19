extends GdUnitTestSuite
## ComposureWick (ART-001 §12.5, Q-T119): 64 × 16, four flame heights stepped by band only (no
## readable number), honest, redraws only on a band change.

const STATS := preload("res://data/hud/composure_wick.tres")
const COMP_STATS := preload("res://data/composure/composure.tres")

var comp: Composure
var wick: ComposureWick


func before_test() -> void:
	SettingsService.persist = false
	comp = auto_free(Composure.new()) as Composure
	comp.stats = COMP_STATS
	comp.sfx = Callable()
	add_child(comp)
	comp.set_physics_process(false)
	wick = auto_free(ComposureWick.new()) as ComposureWick
	wick.stats = STATS
	wick.composure = comp
	wick.size = Vector2(64, 16)
	add_child(wick)
	wick.set_process(false)


func after_test() -> void:
	SettingsService.persist = true


func test_data_is_namespaced() -> void:
	assert_str(STATS.ds_namespace).is_equal("ds_hud.wick")


func test_four_distinct_heights_that_fit_the_box() -> void:
	var hs: Array[float] = [STATS.clear_height_px, STATS.frayed_height_px, STATS.unmoored_height_px, STATS.hollowed_height_px]
	for i in hs.size():
		assert_float(hs[i]).is_greater(0.0)
		assert_float(hs[i]).is_less_equal(ComposureWick.WICK_TOP)
		if i > 0:
			assert_float(hs[i]).is_less(hs[i - 1])


func test_height_steps_by_band_only() -> void:
	# Every value inside one band draws the same height: no readable number.
	var seen := {}
	for tenth in range(100, -1, -1):
		var v := tenth / 10.0
		comp.change(v - comp.value)
		var h := wick.flame_height()
		seen[h] = true
		assert_float(h).override_failure_message("value %s" % v).is_equal(STATS.height_for(comp.band))
	assert_int(seen.size()).is_equal(4)


func test_band_heights() -> void:
	comp.change(0.0)
	assert_float(wick.flame_height()).is_equal(STATS.clear_height_px)
	comp.change(-3.5)
	assert_float(wick.flame_height()).is_equal(STATS.frayed_height_px)
	comp.change(-3.5)
	assert_float(wick.flame_height()).is_equal(STATS.unmoored_height_px)
	comp.change(-3.0)
	assert_float(wick.flame_height()).is_equal(STATS.hollowed_height_px)


func test_redraws_only_on_band_change() -> void:
	wick.refresh()
	assert_bool(wick.refresh()).is_false()
	comp.change(-0.5)   # 9.5, still Clear
	assert_bool(wick.refresh()).is_false()
	comp.change(-3.0)   # 6.5 Frayed
	assert_bool(wick.refresh()).is_true()
	assert_int(wick.drawn_band).is_equal(Composure.Band.FRAYED)


func test_flame_points_stay_inside_the_box() -> void:
	for h: float in [STATS.clear_height_px, STATS.hollowed_height_px]:
		for p: Vector2 in ComposureWick.flame_points(32.5, h, STATS.flame_half_width_px):
			assert_bool(Rect2(0, 0, 64, 16).has_point(p) or p.y == 0.0).override_failure_message("%s" % p).is_true()


func test_no_composure_reads_clear() -> void:
	wick.composure = null
	assert_float(wick.flame_height()).is_equal(STATS.clear_height_px)
