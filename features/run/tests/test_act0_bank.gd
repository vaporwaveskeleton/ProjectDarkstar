extends GdUnitTestSuite
## Act 0 → Ruins bank (SYS-001 §7.1; TECH-001 §4.2a; Q-T101, Q-T141, Q-T146):
## Ember = max(floor(VI / 200), 40), once per profile; a replay pays 0; no index pays 0; the pay
## and the flag commit in one profile write; the Cabinet's pending index is used when the route
## param is lost and is cleared once banked; under `--no-save` (memory backend) it pays in memory
## only and the next real session still pays once.

const STATS := preload("res://data/run/run_session.tres")
const SpySaver := preload("res://features/run/tests/run_spy_saver.gd")

var saver: SpySaver
var core: RunSessionCore


func before_test() -> void:
	saver = SpySaver.new()
	core = RunSessionCore.new(STATS, saver)


func after_test() -> void:
	saver.free_service()


func test_pays_formula_above_the_floor() -> void:
	assert_int(core.arrive_at_ruins({"act0_vigil_index": 45_399})).is_equal(226)
	assert_int(core.profile().ember_banked).is_equal(226)
	assert_bool(core.profile().act0_banked).is_true()


func test_low_score_pays_the_floor() -> void:
	assert_int(core.arrive_at_ruins({"act0_vigil_index": 1200})).is_equal(40)
	assert_int(core.profile().ember_banked).is_equal(40)


func test_zero_score_still_pays_the_floor() -> void:
	assert_int(core.arrive_at_ruins({&"act0_vigil_index": 0})).is_equal(40)


func test_replay_pays_nothing() -> void:
	core.arrive_at_ruins({"act0_vigil_index": 20_000})
	assert_int(core.arrive_at_ruins({"act0_vigil_index": 90_000})).is_equal(0)
	assert_int(core.profile().ember_banked).is_equal(100)


func test_replay_blocked_across_sessions() -> void:
	core.arrive_at_ruins({"act0_vigil_index": 20_000})
	var next := RunSessionCore.new(STATS, saver)   # a later launch on the same saves
	next.load_from_saver()
	assert_int(next.arrive_at_ruins({"act0_vigil_index": 20_000})).is_equal(0)
	assert_int(next.profile().ember_banked).is_equal(100)


func test_absent_param_pays_nothing() -> void:
	assert_int(core.arrive_at_ruins({})).is_equal(0)
	assert_bool(core.profile().act0_banked).is_false()
	assert_int(core.profile().ember_banked).is_equal(0)


func test_pay_and_flag_commit_in_one_profile_write() -> void:
	core.arrive_at_ruins({"act0_vigil_index": 9000})
	var profile_writes := saver.calls.filter(func(c: Dictionary) -> bool: return c.slot == &"profile")
	assert_int(profile_writes.size()).is_equal(1)
	var p: Dictionary = profile_writes[0].payload
	assert_int(int(p.ember_banked)).is_equal(45)
	assert_bool(p.act0_banked).is_true()
	assert_str(String(profile_writes[0].reason)).is_equal("ruins_entry")


func test_pending_index_from_cabinet_banks_when_param_is_lost() -> void:
	# Q-T141: the Cabinet stored the index with its cabinet_score write, then the game crashed.
	saver.save_slot(&"profile", {"cabinet_hi_score": 30_000, "act0_pending_vi": 30_000}, &"cabinet_score")
	core.load_from_saver()
	assert_int(core.arrive_at_ruins({})).is_equal(150)
	var p: Dictionary = saver.calls[saver.calls.size() - 2].payload
	assert_bool(p.has("act0_pending_vi")).is_false()
	assert_bool(p.act0_banked).is_true()


func test_pending_index_is_cleared_on_a_replay_without_paying() -> void:
	core.arrive_at_ruins({"act0_vigil_index": 9000})
	saver.save_slot(&"profile", core.snapshot(&"profile").merged({"act0_pending_vi": 50_000}, true), &"cabinet_score")
	saver.clear()
	assert_int(core.arrive_at_ruins({})).is_equal(0)
	assert_bool((saver.calls[0].payload as Dictionary).has("act0_pending_vi")).is_false()
	assert_int(core.profile().ember_banked).is_equal(45)


func test_no_save_pays_in_memory_only_and_next_real_session_pays_once() -> void:
	# `--no-save` = SaveService on a MemorySaveBackend (autoload/save_service.gd _ready).
	core.arrive_at_ruins({"act0_vigil_index": 9000})
	assert_int(core.profile().ember_banked).is_equal(45)
	assert_bool(saver.mem.exists("profile")).is_true()     # written to memory only
	# The next real session starts from the player's real (here: empty) saves and pays once.
	var real := SpySaver.new()
	var next := RunSessionCore.new(STATS, real)
	next.load_from_saver()
	assert_int(next.arrive_at_ruins({"act0_vigil_index": 9000})).is_equal(45)
	assert_int(next.arrive_at_ruins({"act0_vigil_index": 9000})).is_equal(0)
	real.free_service()
