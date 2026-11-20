extends GdUnitTestSuite
## Warp tier state (WARP-001 §1.3–§1.5), the T1 set data (§2.2, Q-T100, §5.2 L-05) and the
## transient schedule (TECH-001 §5.1 Determinism, Novelty cap).

const TIER := preload("res://data/warp/warp_tier.tres")
const T1 := preload("res://data/warp/t1_frayed.tres")


func test_act_window_holds_for_every_act() -> void:
	assert_int(WarpTier.compute(TIER, 0, 10, true, true).world).is_equal(0)
	assert_int(WarpTier.compute(TIER, 1, 0, false, false).world).is_equal(1)
	assert_int(WarpTier.compute(TIER, 1, 10, true, true).world).is_equal(1)   # Act 1 ceiling
	assert_int(WarpTier.compute(TIER, 2, 0, false, false).world).is_equal(2)
	assert_int(WarpTier.compute(TIER, 2, 4, false, false).world).is_equal(3)
	assert_int(WarpTier.compute(TIER, 2, 8, true, false).world).is_equal(3)   # Act 2 ceiling 3
	assert_int(WarpTier.compute(TIER, 3, 0, false, false).world).is_equal(3)
	assert_int(WarpTier.compute(TIER, 4, 0, false, false).world).is_equal(5)


func test_entropy_terms() -> void:
	assert_int(WarpTier.entropy_term(TIER, 3)).is_equal(0)
	assert_int(WarpTier.entropy_term(TIER, 4)).is_equal(1)
	assert_int(WarpTier.entropy_term(TIER, 8)).is_equal(2)


func test_hollowed_forces_one_tier_below_the_ceiling_only() -> void:
	var a2 := WarpTier.compute(TIER, 2, 0, false, false)
	assert_bool(a2.force_hollowed(TIER)).is_true()
	assert_int(a2.effective(TIER)).is_equal(3)
	assert_bool(a2.force_hollowed(TIER)).is_false()   # once per sector
	var a1 := WarpTier.compute(TIER, 1, 0, false, false)
	assert_bool(a1.force_hollowed(TIER)).is_false()   # Act 1 is already at its ceiling
	assert_int(a1.effective(TIER)).is_equal(1)


func test_t1_set_is_the_ruled_slice_set() -> void:
	assert_array(T1.ids()).contains_exactly_in_any_order(
		[&"W1-01", &"W1-02", &"W1-03", &"W1-05", &"W1-06", &"W1-07", &"W1-08", &"W1-09", &"W1-10"])
	for id: StringName in [&"W1-01", &"W1-02", &"W1-03", &"W1-05", &"W1-08"]:
		assert_bool(T1.effect(id).is_standing()).override_failure_message(str(id)).is_true()
		assert_int(T1.effect(id).trigger).is_equal(WarpEffect.Trigger.TIER_START)
	for id: StringName in [&"W1-07", &"W1-09", &"W1-10"]:
		assert_bool(T1.effect(id).is_standing()).override_failure_message(str(id)).is_false()
	assert_int(T1.effect(&"W1-06").trigger).is_equal(WarpEffect.Trigger.FRAYED_BAND)
	for e in T1.effects:
		assert_int(e.tier).is_equal(1)


func test_t1_worst_case_fits_the_warp_budget() -> void:
	# WARP-001 §5.2 L-05: standing sum + two largest transient peaks <= SYS-001 §9 1.2 ms.
	assert_float(T1.budget_ms).is_equal(1.2)
	assert_float(T1.worst_case_ms()).is_less_equal(T1.budget_ms)
	for e in T1.effects:
		assert_float(e.ms_reduced).is_less_equal(maxf(e.ms_standing, e.ms_transient))


func test_t1_hud_deviations_are_never_lies_and_steady_ledger_pins_them() -> void:
	for e in T1.effects:
		assert_int(e.deviation).is_not_equal(WarpEffect.Deviation.LIE)
		if e.is_hud_deviation():
			assert_bool(e.pinned_by_steady_ledger()).is_true()
	assert_int(T1.effect(&"W1-09").deviation).is_equal(WarpEffect.Deviation.SMEAR)
	assert_int(T1.effect(&"W1-10").deviation).is_equal(WarpEffect.Deviation.GLYPH)


func test_t1_numbers_match_their_owner_rows() -> void:
	assert_float(T1.entry_quiet_s).is_equal(2.0)          # WARP-001 §1.4
	assert_int(T1.novel_per_sector).is_equal(3)            # GDD §16 R-02
	assert_float(T1.chromatic_edge_px).is_less_equal(2.0)  # SYS-001 §1.5 Frayed
	assert_float(T1.false_chant_period_s).is_equal(40.0)   # SYS-001 §1.5 Frayed
	assert_float(T1.breath_px).is_equal(1.0)               # WARP-001 W1-02 ±1 px


func test_seam_depth_deepens_through_a_run() -> void:
	var last := 0.0
	for seam in range(1, 6):
		var d := T1.depth_for_seam(seam)
		assert_float(d).is_greater(last)
		last = d
	assert_float(T1.depth_for_seam(5)).is_equal(1.0)
	assert_float(T1.depth_for_seam(9)).is_equal(1.0)


func test_schedule_is_seeded_and_inside_the_window() -> void:
	var a := WarpSchedule.plan(T1, 1234, 1)
	var b := WarpSchedule.plan(T1, 1234, 1)
	var c := WarpSchedule.plan(T1, 1234, 2)
	assert_array(a.planned.keys()).contains_exactly_in_any_order([&"W1-09", &"W1-10"])
	for id: StringName in [&"W1-09", &"W1-10"]:
		assert_float(a.start_of(id)).is_equal(b.start_of(id))
		assert_float(a.start_of(id)).is_between(maxf(T1.entry_quiet_s, T1.transient_earliest_s),
			T1.transient_latest_s)
	assert_bool(a.start_of(&"W1-09") != c.start_of(&"W1-09")).is_true()
	assert_float(a.end_of(&"W1-09") - a.start_of(&"W1-09")).is_equal_approx(T1.blip_smear_s, 0.001)


func test_novelty_cap_refuses_the_fourth_novel_effect() -> void:
	var s := WarpSchedule.plan(T1, 1, 1)
	assert_bool(s.admit(&"W1-07")).is_true()
	assert_bool(s.admit(&"W1-07")).is_true()   # a repeat is free
	assert_bool(s.admit(&"W1-09")).is_true()
	assert_bool(s.admit(&"W1-10")).is_true()
	assert_int(s.novel_used).is_equal(3)
	assert_bool(s.admit(&"W2-01")).is_false()


func test_run_session_supplies_the_warp_drives() -> void:
	var core := RunSessionCore.new(preload("res://data/run/run_session.tres"), null)
	core.start_run(77)
	core.enter_seam()
	var d := core.warp_inputs()
	assert_int(int(d.act)).is_equal(1)
	assert_int(int(d.seam_index)).is_equal(1)
	assert_int(int(d.seed)).is_equal(77)
	assert_int(WarpTier.compute(TIER, int(d.act), int(d.entropy), bool(d.hollow),
		bool(d.composure_zero)).world).is_equal(1)


func test_novelty_is_remembered_across_sectors_of_one_iteration() -> void:
	var memory: Dictionary = {}
	var a := WarpSchedule.plan(T1, 1, 1, memory)
	assert_bool(a.admit(&"W1-09")).is_true()
	assert_int(a.novel_used).is_equal(1)
	var b := WarpSchedule.plan(T1, 1, 2, memory)
	assert_bool(b.admit(&"W1-09")).is_true()
	assert_int(b.novel_used).is_equal(0)   # witnessed earlier this Iteration: not novel


func test_run_session_keeps_warp_max_and_clears_it_with_the_iteration() -> void:
	var core := RunSessionCore.new(preload("res://data/run/run_session.tres"), null)
	core.begin_iteration_if_needed()
	core.note_warp_tier(1)
	core.note_warp_tier(0)
	assert_int(core.warp_max).is_equal(1)
	core.warp_witnessed[&"W1-07"] = true
	core.iteration().skies_dark = 99
	core.begin_iteration_if_needed()
	assert_int(core.warp_max).is_equal(0)
	assert_bool(core.warp_witnessed.is_empty()).is_true()
