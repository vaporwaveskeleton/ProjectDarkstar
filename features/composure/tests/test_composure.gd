extends GdUnitTestSuite
## Composure (SYS-001 §1.5, Q-T118): starts at 10, clamps 0..10, every event row's Δ, band
## boundaries (fractional values) and the E01–E04 band-change cue requests (spied).

const STATS := preload("res://data/composure/composure.tres")

var comp: Composure
var cues: Array = []


func before_test() -> void:
	SettingsService.persist = false
	cues = []
	comp = auto_free(Composure.new()) as Composure
	comp.stats = STATS
	comp.sfx = _record
	add_child(comp)
	comp.set_physics_process(false)


func after_test() -> void:
	SettingsService.persist = true


func _record(id: StringName, _db: float = 0.0) -> void:
	cues.append(id)


func test_data_matches_sys001() -> void:
	var s := STATS as ComposureStats
	assert_str(s.ds_namespace).is_equal("ds_composure")
	assert_float(s.min_value).is_equal(0.0)
	assert_float(s.max_value).is_equal(10.0)
	assert_float(s.start_value).is_equal(10.0)
	assert_float(s.clear_floor).is_equal(7.0)
	assert_float(s.frayed_floor).is_equal(4.0)
	assert_float(s.gaze_cone_per_s).is_equal(-1.0)
	assert_float(s.gaze_drain_per_s).is_equal(-0.5)
	assert_int(s.gaze_drain_min_tier).is_equal(3)
	assert_float(s.chant_radius_per_s).is_equal(-0.5)
	assert_float(s.warp_passive_per_s_per_tier).is_equal(-0.1)
	assert_float(s.charge_lost).is_equal(-0.5)
	assert_float(s.charge_spent).is_equal(0.0)
	assert_float(s.death).is_equal(-2.0)
	assert_float(s.death_recover_s).is_equal(60.0)
	assert_float(s.surgelight_use).is_equal(-1.0)
	assert_int(s.surgelight_min_tier).is_equal(2)
	assert_float(s.surgelight_max_per_s).is_equal(2.0)
	assert_float(s.shrine_destroyed).is_equal(1.0)
	assert_float(s.matron_killed).is_equal(2.0)
	assert_float(s.procession_let_pass).is_equal(2.0)
	assert_float(s.darkness_delay_s).is_equal(5.0)
	assert_float(s.darkness_per_s).is_equal(0.5)
	assert_float(s.darkness_cap).is_equal(2.0)
	assert_float(s.clear_eyed).is_equal(-1.0)


func test_starts_clear_at_ten() -> void:
	assert_float(comp.value).is_equal(10.0)
	assert_int(comp.band).is_equal(Composure.Band.CLEAR)
	assert_str(comp.band_name()).is_equal("clear")
	assert_array(cues).is_empty()


func test_no_passive_regen_or_drain() -> void:
	comp.change(-3.0)
	for i in 600:
		comp.tick(1.0 / 60.0)
	assert_float(comp.value).is_equal(7.0)


func test_clamps_to_range() -> void:
	assert_float(comp.change(5.0)).is_equal(0.0)
	assert_float(comp.value).is_equal(10.0)
	comp.change(-25.0)
	assert_float(comp.value).is_equal(0.0)
	comp.change(-1.0)
	assert_float(comp.value).is_equal(0.0)


func test_per_second_rows() -> void:
	assert_float(comp.gaze_cone(1.0)).is_equal_approx(-1.0, 1e-5)
	assert_float(comp.chant_radius(1.0)).is_equal_approx(-0.5, 1e-5)
	assert_float(comp.warp_passive(1.0, 3)).is_equal_approx(-0.3, 1e-5)
	assert_float(comp.warp_passive(1.0, 0)).is_equal(0.0)
	assert_float(comp.gaze_drain(1.0, 2)).is_equal(0.0)   # T3+ only
	assert_float(comp.gaze_drain(1.0, 3)).is_equal_approx(-0.5, 1e-5)
	assert_float(comp.value).is_equal_approx(7.7, 1e-5)


func test_charge_rows() -> void:
	assert_float(comp.charge_lost()).is_equal(-0.5)
	assert_float(comp.charge_spent()).is_equal(0.0)
	assert_float(comp.value).is_equal(9.5)


func test_restore_rows() -> void:
	comp.change(-8.0)
	assert_float(comp.shrine_destroyed()).is_equal(1.0)
	assert_float(comp.matron_killed()).is_equal(2.0)
	assert_float(comp.procession_let_pass()).is_equal(2.0)
	assert_float(comp.value).is_equal(7.0)
	assert_float(comp.clear_eyed()).is_equal(-1.0)
	assert_float(comp.codex_read()).is_equal(4.0)
	assert_float(comp.value).is_equal(10.0)


func test_death_costs_two_then_recovers_after_sixty_seconds() -> void:
	assert_float(comp.death_at_run_start()).is_equal(-2.0)
	assert_float(comp.value).is_equal(8.0)
	comp.tick(59.0)
	assert_float(comp.value).is_equal(8.0)
	comp.tick(1.0)
	assert_float(comp.value).is_equal(10.0)


func test_surgelight_costs_from_tier_two_and_caps_at_two_per_second() -> void:
	assert_float(comp.surgelight_used(1)).is_equal(0.0)
	assert_float(comp.surgelight_used(2)).is_equal(-1.0)
	assert_float(comp.surgelight_used(2)).is_equal(-1.0)
	assert_float(comp.surgelight_used(2)).is_equal(0.0)   # capped this second
	comp.tick(1.0)
	assert_float(comp.surgelight_used(3)).is_equal(-1.0)
	assert_float(comp.value).is_equal(7.0)


func test_darkness_restores_after_five_seconds_capped_at_two() -> void:
	comp.change(-5.0)
	var gained := 0.0
	for i in 5 * 60:
		gained += comp.darkness(1.0 / 60.0, true, false)
	assert_float(gained).is_equal_approx(0.0, 1e-4)
	for i in 2 * 60:
		gained += comp.darkness(1.0 / 60.0, true, false)
	assert_float(gained).is_equal_approx(1.0, 1e-3)
	for i in 10 * 60:
		gained += comp.darkness(1.0 / 60.0, true, false)
	assert_float(gained).is_equal_approx(2.0, 1e-4)
	# firing ends the spell; a new one waits 5 s again
	assert_float(comp.darkness(1.0 / 60.0, true, true)).is_equal(0.0)
	assert_float(comp.darkness(1.0, true, false)).is_equal(0.0)


func test_band_boundaries_including_fractions() -> void:
	var s := STATS as ComposureStats
	var cases := {10.0: 0, 7.0: 0, 6.9: 1, 6.5: 1, 6.0: 1, 4.0: 1, 3.9: 2, 3.5: 2, 1.0: 2, 0.5: 2, 0.0: 3}
	for v: float in cases:
		assert_int(Composure.band_for(v, s)).override_failure_message("value %s" % v).is_equal(int(cases[v]))


func test_band_change_cues() -> void:
	comp.change(-3.5)   # 6.5 Frayed
	assert_array(cues).is_equal([Composure.CUE_FRAYED])
	comp.change(-0.5)   # 6.0 still Frayed: no cue
	assert_array(cues).is_equal([Composure.CUE_FRAYED])
	comp.change(-3.0)   # 3.0 Unmoored
	comp.change(-3.0)   # 0.0 Hollowed
	assert_array(cues).is_equal([Composure.CUE_FRAYED, Composure.CUE_UNMOORED, Composure.CUE_HOLLOWED])
	comp.codex_read()   # back to Clear
	assert_array(cues).is_equal([Composure.CUE_FRAYED, Composure.CUE_UNMOORED, Composure.CUE_HOLLOWED, Composure.CUE_RECOVERY])
	assert_int(comp.band).is_equal(Composure.Band.CLEAR)


func test_skipping_bands_plays_the_entered_band_only() -> void:
	comp.change(-8.0)   # Clear -> Unmoored directly
	assert_array(cues).is_equal([Composure.CUE_UNMOORED])
	comp.change(1.0)    # 3.0 still Unmoored
	comp.change(2.0)    # 5.0 Frayed: a recovery
	assert_array(cues).is_equal([Composure.CUE_UNMOORED, Composure.CUE_RECOVERY])


func test_cue_ids_are_e01_to_e04_names() -> void:
	assert_str(str(Composure.cue_for(Composure.Band.CLEAR, Composure.Band.FRAYED))).is_equal("wick_frayed")
	assert_str(str(Composure.cue_for(Composure.Band.FRAYED, Composure.Band.UNMOORED))).is_equal("wick_unmoored")
	assert_str(str(Composure.cue_for(Composure.Band.UNMOORED, Composure.Band.HOLLOWED))).is_equal("wick_hollowed")
	assert_str(str(Composure.cue_for(Composure.Band.HOLLOWED, Composure.Band.UNMOORED))).is_equal("wick_recovery")
	assert_str(str(Composure.cue_for(Composure.Band.FRAYED, Composure.Band.FRAYED))).is_equal("")


func test_reset_returns_to_start_without_cue() -> void:
	comp.change(-6.0)
	cues.clear()
	comp.reset()
	assert_float(comp.value).is_equal(10.0)
	assert_int(comp.band).is_equal(Composure.Band.CLEAR)
	assert_array(cues).is_empty()
