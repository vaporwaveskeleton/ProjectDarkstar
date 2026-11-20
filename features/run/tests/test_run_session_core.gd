extends GdUnitTestSuite
## RunSessionCore rules (TECH-001 §4.2a): seeding and Seams 1–5, Seam write-back and Ember, the
## death lump per Seam, the win refund clamp, multi-sky lumps, the ninth sky, reason-counted pause,
## no tick before the first Ruins visit, abandon only between Seams. Injected; no autoload state.

const STATS := preload("res://data/run/run_session.tres")

var core: RunSessionCore
var events: Array[String] = []


func before_test() -> void:
	events = []
	core = RunSessionCore.new(STATS, null)
	core.iteration_started.connect(func() -> void: events.append("iteration_started"))
	core.run_started.connect(func(s: int) -> void: events.append("run_started:%d" % s))
	core.seam_entered.connect(func(i: int) -> void: events.append("seam_entered:%d" % i))
	core.seam_cleared.connect(func(i: int) -> void: events.append("seam_cleared:%d" % i))
	core.run_ended.connect(func(o: StringName) -> void: events.append("run_ended:%s" % o))
	core.sky_darkened.connect(func(n: int) -> void: events.append("sky:%d" % n))
	core.iteration_ended.connect(func() -> void: events.append("iteration_ended"))


func _report(composure: float, charges: int, ember: int) -> SeamReport:
	var r := SeamReport.new()
	r.composure = composure
	r.charges = charges
	r.ember_earned = ember
	return r


func _clear_seam(composure: float = 7.0, charges: int = 2, ember: int = 0) -> void:
	core.enter_seam()
	assert_bool(core.end_seam(_report(composure, charges, ember))).is_true()


func test_data_matches_sys001() -> void:
	var s := STATS as RunSessionStats
	assert_str(s.ds_namespace).is_equal("ds_run.session")
	assert_float(s.iteration_budget_loop_min).is_equal(120.0)
	assert_int(s.skies).is_equal(9)
	assert_float(s.loop_min_per_real_min).is_equal(1.0)
	assert_float(s.death_cost_base_loop_min).is_equal(10.0)
	assert_float(s.death_cost_per_seam_loop_min).is_equal(2.0)
	assert_float(s.win_refund_loop_min).is_equal(15.0)
	assert_float(s.show_threshold_loop_min).is_equal(15.0)
	assert_int(s.seams_per_run).is_equal(5)
	assert_int(s.seam_clear_ember).is_equal(40)
	assert_int(s.score_per_ember).is_equal(200)
	assert_int(s.act0_bank_floor_ember).is_equal(40)
	assert_bool(s.carry_between_seams).is_true()
	assert_int(s.slice_last_seam).is_equal(2)   # PM-02 ruling: the slice is two Seams (Q-T276)
	assert_float(s.death_cost_loop_min(1)).is_equal(10.0)
	assert_float(s.death_cost_loop_min(5)).is_equal(18.0)


func test_start_run_seeds_and_walks_seams_one_to_five() -> void:
	var r := core.start_run(12345)
	assert_int(r.seam_index).is_equal(1)
	assert_int(r.seed_value).is_equal(12345)
	assert_array(events).contains(["run_started:12345"])
	for i in range(1, 5):
		var p := core.enter_seam()
		assert_int(int(p.seam_index)).is_equal(i)
		assert_object(p.session).is_same(core)
		_ok_end(i)
	assert_int(core.run().seam_index).is_equal(5)


func _ok_end(_i: int) -> void:
	assert_bool(core.end_seam(_report(6.0, 3, 0))).is_true()


func test_fresh_seed_is_in_range_and_seam_seeds_are_stable() -> void:
	core.start_run()
	assert_int(core.run().seed_value).is_between(0, RunSeed.SEED_MASK)
	var other := RunSessionCore.new(STATS, null)
	other.start_run(77)
	core = RunSessionCore.new(STATS, null)
	core.start_run(77)
	assert_int(int(core.enter_seam().seam_seed)).is_equal(int(other.enter_seam().seam_seed))


func test_start_run_refused_while_a_run_is_live() -> void:
	var r := core.start_run(1)
	assert_object(core.start_run(2)).is_same(r)
	assert_int(core.run().seed_value).is_equal(1)


func test_end_seam_writes_back_and_pays_seam_ember() -> void:
	core.start_run(1)
	core.enter_seam()
	assert_bool(core.end_seam(_report(6.5, 4, 12))).is_true()
	assert_float(core.run().composure).is_equal(6.5)
	assert_int(core.run().charges).is_equal(4)
	assert_int(core.run().ember_in_run).is_equal(12 + 40)
	assert_array(events).contains(["seam_entered:1", "seam_cleared:1"])


func test_end_seam_outside_a_seam_is_refused() -> void:
	core.start_run(1)
	assert_bool(core.end_seam(_report(5.0, 1, 0))).is_false()
	assert_int(core.run().seam_index).is_equal(1)


func test_carry_switch_off_resets_composure_and_charges() -> void:
	var s := STATS.duplicate() as RunSessionStats
	s.carry_between_seams = false
	core = RunSessionCore.new(s, null)
	core.start_run(1)
	core.enter_seam()
	core.end_seam(_report(3.0, 4, 0))
	assert_float(core.run().composure).is_less(0.0)
	assert_int(core.run().charges).is_equal(0)


func test_fifth_seam_clear_wins_with_refund_and_banks_ember() -> void:
	core.arrive_at_ruins({})
	core.consume_clock(30.0, &"test")
	core.start_run(1)
	for i in 5:
		_clear_seam(7.0, 1, 10)
	assert_bool(core.run().is_active()).is_false()
	assert_array(events).contains(["seam_cleared:5", "run_ended:won"])
	# 5 × (10 + 40) Seam Ember banks in full on the win (Q-T145)
	assert_int(core.profile().ember_banked).is_equal(250)
	assert_float(core.loop_min_left()).is_equal(105.0)


func test_win_refund_clamps_to_budget() -> void:
	core.arrive_at_ruins({})
	core.consume_clock(5.0, &"test")
	core.start_run(1)
	assert_bool(core.win()).is_true()
	assert_float(core.loop_min_left()).is_equal(120.0)


func test_win_refund_never_relights_a_sky() -> void:
	core.arrive_at_ruins({})
	core.consume_clock(20.0, &"test")
	assert_int(core.skies_dark()).is_equal(1)
	core.start_run(1)
	core.win()
	assert_float(core.loop_min_left()).is_equal(115.0)
	assert_int(core.skies_dark()).is_equal(1)


func test_death_lump_grows_per_seam_and_banks_in_full() -> void:
	core.arrive_at_ruins({})
	core.start_run(1)
	_clear_seam(7.0, 1, 0)
	_clear_seam(7.0, 1, 0)
	core.enter_seam()     # Seam 3
	assert_bool(core.die()).is_true()
	# 10 + 2 × (3 − 1) = 14
	assert_float(core.loop_min_left()).is_equal(106.0)
	assert_int(core.profile().ember_banked).is_equal(80)
	assert_bool(core.run().is_active()).is_false()
	assert_array(events).contains(["run_ended:died"])


func test_death_at_seam_one_costs_ten() -> void:
	core.arrive_at_ruins({})
	core.start_run(1)
	core.enter_seam()
	core.die()
	assert_float(core.loop_min_left()).is_equal(110.0)


func test_die_without_a_run_does_nothing() -> void:
	core.arrive_at_ruins({})
	assert_bool(core.die()).is_false()
	assert_float(core.loop_min_left()).is_equal(120.0)


func test_abandon_only_between_seams_and_costs_the_death_price() -> void:
	core.arrive_at_ruins({})
	core.start_run(1)
	_clear_seam()
	core.enter_seam()     # Seam 2, inside it
	assert_bool(core.abandon()).is_false()
	assert_bool(core.run().is_active()).is_true()
	core.end_seam(_report(7.0, 0, 0))   # boundary before Seam 3
	assert_bool(core.abandon()).is_true()
	assert_float(core.loop_min_left()).is_equal(120.0 - 14.0)
	assert_array(events).contains(["run_ended:abandoned"])


## Q-T277: the sector's Abandon Run mid-Seam ends the run at the death price and banks its Ember.
func test_abandon_from_seam_costs_the_death_price_and_banks() -> void:
	core.arrive_at_ruins({})
	core.start_run(1)
	_clear_seam(7.0, 1, 5)       # 45 in-run Ember
	core.enter_seam()            # Seam 2, inside it
	assert_bool(core.abandon_from_seam()).is_true()
	assert_bool(core.run().is_active()).is_false()
	assert_bool(core.in_seam()).is_false()
	assert_float(core.loop_min_left()).is_equal(120.0 - 12.0)
	assert_int(core.profile().ember_banked).is_equal(45)
	assert_array(events).contains(["run_ended:abandoned"])
	assert_bool(core.abandon_from_seam()).is_false()   # no run left


## Q-T276: at the slice frontier the cleared Seam's exit ends the run `returned`: Seam clear Ember and
## the report's Ember bank in full, no death lump, no win refund.
func test_frontier_exit_returns_and_banks_the_clear() -> void:
	core.stats = _frontier_stats(1)
	core.arrive_at_ruins({})
	core.consume_clock(30.0, &"test")
	core.start_run(1)
	core.enter_seam()
	assert_bool(core.at_frontier()).is_true()
	assert_bool(core.return_from_frontier(_report(6.0, 2, 3))).is_true()
	assert_bool(core.run().is_active()).is_false()
	assert_int(core.profile().ember_banked).is_equal(3 + 40)
	assert_float(core.loop_min_left()).is_equal(90.0)
	assert_array(events).contains(["seam_cleared:1", "run_ended:returned"])
	assert_bool(core.at_frontier()).is_false()


func test_frontier_exit_outside_a_seam_is_refused() -> void:
	core.start_run(1)
	assert_bool(core.return_from_frontier(_report(5.0, 1, 0))).is_false()
	assert_bool(core.run().is_active()).is_true()


## `slice_last_seam` 0 switches the frontier off: the exit is an ordinary Seam clear.
func test_no_frontier_means_the_exit_leads_to_the_next_seam() -> void:
	var s := STATS.duplicate() as RunSessionStats
	s.slice_last_seam = 0
	core = RunSessionCore.new(s, null)
	core.start_run(1)
	core.enter_seam()
	assert_bool(core.at_frontier()).is_false()
	assert_bool(core.return_from_frontier(_report(5.0, 1, 0))).is_true()
	assert_bool(core.run().is_active()).is_true()
	assert_int(core.run().seam_index).is_equal(2)


## The frontier never swallows the last Seam: a frontier at or past Seam 5 leaves the win path alone.
func test_frontier_at_the_last_seam_still_wins() -> void:
	var s := STATS.duplicate() as RunSessionStats
	s.slice_last_seam = 5
	core = RunSessionCore.new(s, null)
	core.run_ended.connect(func(o: StringName) -> void: events.append("run_ended:%s" % o))
	core.start_run(1)
	for i in 4:
		_clear_seam()
	core.enter_seam()
	assert_bool(core.at_frontier()).is_false()
	core.return_from_frontier(_report(5.0, 1, 0))
	assert_array(events).contains(["run_ended:won"])


func test_multi_sky_lump_emits_each_sky() -> void:
	core.arrive_at_ruins({})
	events.clear()
	assert_int(core.consume_clock(27.0, &"test")).is_equal(2)
	assert_array(events).is_equal(["sky:1", "sky:2"])
	assert_int(core.skies_dark()).is_equal(2)


func test_ninth_sky_ends_the_run_and_the_iteration() -> void:
	core.arrive_at_ruins({})
	core.start_run(1)
	core.enter_seam()
	events.clear()
	core.consume_clock(200.0, &"test")
	assert_int(core.skies_dark()).is_equal(9)
	assert_float(core.loop_min_left()).is_equal(0.0)
	assert_bool(core.run().is_active()).is_false()
	assert_array(events).contains(["sky:9", "run_ended:ninth_sky", "iteration_ended"])
	assert_int(events.count("iteration_ended")).is_equal(1)
	# Q-T143: the ninth-sky bank is deferred — nothing banks yet.
	assert_int(core.profile().ember_banked).is_equal(0)


func test_next_ruins_after_ninth_sky_begins_a_new_iteration() -> void:
	core.arrive_at_ruins({})
	core.consume_clock(200.0, &"test")
	events.clear()
	core.arrive_at_ruins({})
	assert_array(events).contains(["iteration_started"])
	assert_float(core.loop_min_left()).is_equal(120.0)
	assert_int(core.skies_dark()).is_equal(0)


func test_no_tick_before_first_ruins_visit() -> void:
	core.tick(600.0)
	assert_bool(core.iteration().started).is_false()
	assert_float(core.loop_min_left()).is_equal(0.0)
	assert_int(core.consume_clock(50.0, &"test")).is_equal(0)


func test_tick_spends_one_loop_minute_per_real_minute() -> void:
	core.arrive_at_ruins({})
	for i in 60:
		core.tick(1.0)
	assert_float(core.loop_min_left()).is_equal_approx(119.0, 0.0001)


func test_pause_is_reason_counted() -> void:
	core.arrive_at_ruins({})
	core.pause_clock(&"codex")
	core.pause_clock(&"codex")
	core.pause_clock(&"cinematic")
	core.tick(60.0)
	core.resume_clock(&"codex")
	core.tick(60.0)
	core.resume_clock(&"cinematic")
	core.tick(60.0)
	assert_bool(core.is_clock_paused()).is_true()
	core.resume_clock(&"codex")
	assert_bool(core.is_clock_paused()).is_false()
	core.tick(60.0)
	assert_float(core.loop_min_left()).is_equal_approx(119.0, 0.0001)


func test_hourglass_shows_in_run_at_threshold() -> void:
	core.arrive_at_ruins({})
	core.start_run(1)
	core.consume_clock(104.0, &"test")
	assert_bool(core.hourglass_visible()).is_false()
	core.consume_clock(1.0, &"test")
	assert_bool(core.hourglass_visible()).is_true()


## A copy of the shipped stats with the slice frontier at Seam `last` (the shipped value is 2).
func _frontier_stats(last: int) -> RunSessionStats:
	var s := STATS.duplicate() as RunSessionStats
	s.slice_last_seam = last
	return s


## PM-02: with the shipped frontier (Seam 2) Seam 1's exit is an ordinary clear into Seam 2, and
## Seam 2's exit ends the run `returned`.
func test_shipped_frontier_is_seam_2() -> void:
	core.arrive_at_ruins({})
	core.start_run(1)
	core.enter_seam()
	assert_bool(core.at_frontier()).is_false()
	assert_bool(core.return_from_frontier(_report(6.0, 2, 3))).is_true()
	assert_bool(core.run().is_active()).is_true()
	assert_int(core.run().seam_index).is_equal(2)
	core.enter_seam()
	assert_bool(core.at_frontier()).is_true()
	assert_bool(core.return_from_frontier(_report(6.0, 2, 3))).is_true()
	assert_bool(core.run().is_active()).is_false()
	assert_array(events).contains(["run_ended:returned"])
