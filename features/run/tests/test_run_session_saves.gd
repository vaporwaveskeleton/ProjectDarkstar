extends GdUnitTestSuite
## RunSessionCore save cadence (TECH-001 §4.2a, §7.2; Q-T139): a saver saver sees only the marked
## call sites and reasons, nothing from tick / enter_seam / a sky / mid-Seam; every payload holds
## numbers, bools and ids only; snapshot / restore round-trips and rejects bad payloads.

const STATS := preload("res://data/run/run_session.tres")
const SpySaver := preload("res://features/run/tests/run_spy_saver.gd")

var saver: SpySaver
var core: RunSessionCore


func before_test() -> void:
	saver = SpySaver.new()
	core = RunSessionCore.new(STATS, saver)


func after_test() -> void:
	saver.free_service()


func _report() -> SeamReport:
	var r := SeamReport.new()
	r.composure = 6.0
	r.charges = 2
	r.ember_earned = 5
	return r


func _assert_all_accepted() -> void:
	for c in saver.calls:
		assert_int(int(c.result)).override_failure_message("refused: %s" % [c]).is_equal(OK)
		assert_bool(RunPayload.is_plain(c.payload)).override_failure_message("not plain: %s" % [c]).is_true()


func test_ruins_entry_writes_profile_and_iteration_once() -> void:
	core.arrive_at_ruins({})
	assert_array(saver.slots_and_reasons()).is_equal(["profile:ruins_entry", "iteration:ruins_entry"])
	_assert_all_accepted()


func test_nothing_saves_from_tick_start_enter_or_skies() -> void:
	core.arrive_at_ruins({})
	saver.clear()
	core.start_run(3)
	core.enter_seam()
	for i in 120:
		core.tick(10.0)          # 20 loop-minutes: crosses a sky
	core.consume_clock(10.0, &"test")
	core.pause_clock(&"codex")
	core.resume_clock(&"codex")
	assert_int(core.skies_dark()).is_greater_equal(2)
	assert_array(saver.calls).is_empty()


func test_seam_boundary_writes_run_only() -> void:
	core.arrive_at_ruins({})
	core.start_run(3)
	saver.clear()
	core.enter_seam()
	core.end_seam(_report())
	assert_array(saver.slots_and_reasons()).is_equal(["run:seam_boundary"])
	assert_int(int(saver.calls[0].payload.seam_index)).is_equal(2)
	_assert_all_accepted()


func test_death_writes_run_end_with_no_live_run() -> void:
	core.arrive_at_ruins({})
	core.start_run(3)
	core.enter_seam()
	saver.clear()
	core.die()
	assert_array(saver.slots_and_reasons()).is_equal(["run:run_end", "iteration:run_end"])
	assert_int(int(saver.calls[0].payload.seam_index)).is_equal(0)
	assert_float(float(saver.calls[1].payload.loop_min_left)).is_equal(110.0)
	_assert_all_accepted()


func test_win_and_abandon_write_run_end() -> void:
	core.arrive_at_ruins({})
	core.start_run(3)
	saver.clear()
	core.win()
	assert_array(saver.slots_and_reasons()).is_equal(["run:run_end", "iteration:run_end"])
	core.start_run(4)
	saver.clear()
	core.abandon()
	assert_array(saver.slots_and_reasons()).is_equal(["run:run_end", "iteration:run_end"])
	_assert_all_accepted()


func test_last_seam_clear_saves_run_end_not_seam_boundary() -> void:
	core.arrive_at_ruins({})
	core.start_run(3)
	for i in 4:
		core.enter_seam()
		core.end_seam(_report())
	saver.clear()
	core.enter_seam()
	core.end_seam(_report())
	assert_array(saver.slots_and_reasons()).is_equal(["run:run_end", "iteration:run_end"])


## Q-T276: the frontier exit is one `run_end` write set, with no `seam_boundary` write before it.
func test_frontier_exit_writes_run_end_only() -> void:
	core.arrive_at_ruins({})
	core.start_run(3)
	core.enter_seam()
	saver.clear()
	assert_bool(core.return_from_frontier(_report())).is_true()
	assert_array(saver.slots_and_reasons()).is_equal(["run:run_end", "iteration:run_end"])
	assert_int(int(saver.calls[0].payload.seam_index)).is_equal(0)
	_assert_all_accepted()


## Q-T277: Abandon Run mid-Seam writes the same `run_end` set as any abandon.
func test_abandon_from_seam_writes_run_end() -> void:
	core.arrive_at_ruins({})
	core.start_run(3)
	core.enter_seam()
	saver.clear()
	assert_bool(core.abandon_from_seam()).is_true()
	assert_array(saver.slots_and_reasons()).is_equal(["run:run_end", "iteration:run_end"])
	_assert_all_accepted()


func test_null_saver_never_saves() -> void:
	var quiet := RunSessionCore.new(STATS, null)
	quiet.arrive_at_ruins({"act0_vigil_index": 9000})
	quiet.start_run(1)
	quiet.enter_seam()
	quiet.end_seam(_report())
	quiet.die()
	assert_int(quiet.profile().ember_banked).is_greater(0)   # the rules still run in memory


func test_snapshot_restore_round_trip_through_json() -> void:
	core.arrive_at_ruins({"act0_vigil_index": 20000})
	core.consume_clock(17.5, &"test")
	core.iteration().corruption[&"pale_marches"] = 3
	core.start_run(99)
	core.run().sigils.append(&"sigil_a")
	core.run().pact = &"pact_b"
	core.enter_seam()
	core.end_seam(_report())
	var other := RunSessionCore.new(STATS, null)
	for slot: StringName in [&"profile", &"iteration", &"run"]:
		var json := JSON.stringify(core.snapshot(slot))
		var back: Dictionary = JSON.parse_string(json)
		assert_bool(other.restore(slot, back)).override_failure_message(str(slot)).is_true()
		assert_dict(other.snapshot(slot)).is_equal(core.snapshot(slot))
	assert_int(other.run().seed_value).is_equal(99)
	assert_int(other.run().seam_index).is_equal(2)
	assert_int(other.profile().ember_banked).is_equal(100)


func test_restore_rejects_unknown_keys_and_bad_values() -> void:
	assert_bool(core.restore(&"run", {"seam_index": 1, "cheat": 1})).is_false()
	assert_bool(core.restore(&"run", {"seam_index": "two"})).is_false()
	assert_bool(core.restore(&"run", {"seam_index": 1.5})).is_false()
	assert_bool(core.restore(&"iteration", {"loop_min_left": "lots"})).is_false()
	assert_bool(core.restore(&"iteration", {"what": 1})).is_false()
	assert_bool(core.restore(&"profile", {"ember_banked": "many"})).is_false()
	assert_bool(core.restore(&"profile", {"odd": Vector2.ONE})).is_false()
	assert_bool(core.restore(&"nope", {})).is_false()
	assert_int(core.run().seam_index).is_equal(0)


func test_profile_keeps_other_writers_keys() -> void:
	saver.save_slot(&"profile", {"cabinet_hi_score": 4321, "cabinet_tape_peeled": true, "future_flag": true}, &"cabinet_tape")
	core.load_from_saver()
	saver.clear()
	core.arrive_at_ruins({})
	var p: Dictionary = saver.calls[0].payload
	assert_int(int(p.cabinet_hi_score)).is_equal(4321)
	assert_bool(p.cabinet_tape_peeled).is_true()
	assert_bool(p.future_flag).is_true()
	assert_bool(p.act0_complete).is_true()


func test_cabinet_write_after_boot_does_not_erase_banked_ember() -> void:
	core.arrive_at_ruins({})
	core.start_run(1)
	core.enter_seam()
	core.end_seam(_report())   # 45 in-run
	core.enter_seam()
	core.die()                 # banks 45 in memory
	# The Cabinet writes its own (older) copy of the profile with a new hi score.
	saver.save_slot(&"profile", {"cabinet_hi_score": 777, "ember_banked": 0}, &"cabinet_score")
	saver.clear()
	core.arrive_at_ruins({})
	var p: Dictionary = saver.calls[0].payload
	assert_int(int(p.ember_banked)).is_equal(45)
	assert_int(int(p.cabinet_hi_score)).is_equal(777)


func test_unreadable_profile_is_never_overwritten() -> void:
	saver.mem.files["profile"] = "{not json"
	core.load_from_saver()
	saver.clear()
	core.arrive_at_ruins({})
	assert_array(saver.slots_and_reasons()).is_equal(["iteration:ruins_entry"])
	assert_str(saver.mem.files["profile"]).is_equal("{not json")
