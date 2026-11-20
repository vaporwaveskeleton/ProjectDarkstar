extends GdUnitTestSuite
## The Codex knowledge record (Q-T350..Q-T353; closes Q-T327): stamp and read rules, the profile
## round trip (ids only), arrival stamps the Act 0 page, the tier-1 backstop after run 3 (SYS-001 §7.6)
## makes the four gated tier-1 lamps buyable at 0 Ember, and no Codex change ever saves on its own:
## only the allowed `ruins_entry` / `tree_purchase` writes carry it.

const TREE := preload("res://data/lantern_tree/m2_tree.tres")
const STATS := preload("res://data/run/run_session.tres")
const SpySaver := preload("res://features/run/tests/run_spy_saver.gd")
## LOOP-001 §3.7: the tier-1 gating entries, in the gating map's order.
const TIER1_GATES: Array[StringName] = [&"cx_choir_shrine", &"cx_rule_gaze", &"cx_rule_frayed", &"cx_rule_lantern_dark"]
const GATED_T1: Array[StringName] = [&"LANTERN-4", &"WARD-1", &"MADNESS-2", &"MADNESS-3"]
## SYS-001 §7.6 `Gating backstop: tier-1 entries`: after run 3.
const SYS_BACKSTOP_RUNS := 3

var saver: SpySaver
var core: RunSessionCore


func before_test() -> void:
	saver = SpySaver.new()
	core = RunSessionCore.new(STATS, saver)


func after_test() -> void:
	saver.free_service()


func _end_runs(n: int) -> void:
	for i in n:
		core.start_run(7)
		core.enter_seam()
		assert_bool(core.die()).is_true()


# --- pure rules ------------------------------------------------------------------------------------

func test_stamp_is_once_and_ids_only() -> void:
	var known: Array[StringName] = []
	assert_bool(CodexRecord.stamp(known, &"cx_rule_gaze")).is_true()
	assert_bool(CodexRecord.stamp(known, &"cx_rule_gaze")).is_false()
	assert_bool(CodexRecord.stamp(known, &"LANTERN-1")).is_false()
	assert_bool(CodexRecord.stamp(known, &"cx_")).is_false()
	assert_array(known).is_equal([&"cx_rule_gaze"])


func test_only_stamped_entries_can_be_read() -> void:
	var known: Array[StringName] = [&"cx_place_act0_3", &"cx_rule_gaze"]
	var read: Array[StringName] = []
	assert_bool(CodexRecord.mark_read(known, read, &"cx_rule_frayed")).is_false()
	assert_bool(CodexRecord.mark_read(known, read, &"cx_place_act0_3")).is_true()
	assert_bool(CodexRecord.mark_read(known, read, &"cx_place_act0_3")).is_false()
	assert_array(CodexRecord.unread(known, read)).is_equal([&"cx_rule_gaze"])


func test_tier_one_gating_ids_come_from_the_tree() -> void:
	var ids := CodexRecord.gating_ids(TREE, 1)
	assert_int(ids.size()).is_equal(TIER1_GATES.size())
	for id in TIER1_GATES:
		assert_bool(ids.has(id)).is_true()
	assert_bool(CodexRecord.gating_ids(TREE, 2).has(&"cx_choir_matron")).is_true()
	assert_array(CodexRecord.gating_ids(null, 1)).is_empty()


func test_backstop_data_matches_sys_001() -> void:
	assert_int(STATS.codex_backstop_tier1_runs).is_equal(SYS_BACKSTOP_RUNS)
	assert_bool(STATS.ds_keys().has("ds_run.session.codex_backstop_tier1_runs")).is_true()
	assert_bool(CodexRecord.tier1_backstop_due(2, 3)).is_false()
	assert_bool(CodexRecord.tier1_backstop_due(3, 3)).is_true()
	assert_bool(CodexRecord.tier1_backstop_due(9, 0)).is_false()


# --- the profile ----------------------------------------------------------------------------------

func test_profile_round_trip_keeps_the_record() -> void:
	var p := ProfileState.new()
	p.codex_known = [&"cx_place_act0_3", &"cx_rule_gaze"] as Array[StringName]
	p.codex_read = [&"cx_place_act0_3"] as Array[StringName]
	p.runs_ended = 4
	var d := p.to_payload()
	assert_array(d["codex_known"] as Array).is_equal(["cx_place_act0_3", "cx_rule_gaze"])
	assert_int(int(d["runs_ended"])).is_equal(4)
	var back := ProfileState.from_payload(d)
	assert_object(back).is_not_null()
	assert_array(back.codex_known).is_equal(p.codex_known)
	assert_array(back.codex_read).is_equal(p.codex_read)
	assert_int(back.runs_ended).is_equal(4)
	assert_object(ProfileState.from_payload({"codex_known": [3]})).is_null()


func test_a_cabinet_refresh_keeps_the_record_and_the_run_count() -> void:
	var mine := ProfileState.new()
	mine.codex_known = [&"cx_rule_gaze"] as Array[StringName]
	mine.runs_ended = 2
	var disk := ProfileState.new()
	disk.cabinet_hi_score = 900
	mine.merge_foreign(disk)
	assert_array(mine.codex_known).is_equal([&"cx_rule_gaze"])
	assert_int(mine.runs_ended).is_equal(2)
	assert_int(mine.cabinet_hi_score).is_equal(900)


# --- RunSessionCore ------------------------------------------------------------------------------

func test_arrival_stamps_the_act0_page_and_reading_it_saves_nothing() -> void:
	var stamped: Array[StringName] = []
	core.codex_stamped.connect(func(id: StringName) -> void: stamped.append(id))
	core.arrive_at_ruins({}, TREE)
	assert_array(core.codex_known()).is_equal([CodexRecord.ACT0_PAGE])
	assert_array(stamped).is_equal([CodexRecord.ACT0_PAGE])
	var n := saver.calls.size()
	assert_bool(core.read_codex(CodexRecord.ACT0_PAGE)).is_true()
	assert_bool(core.read_codex(&"cx_rule_gaze")).is_false()   # not stamped
	assert_bool(core.stamp_codex(&"cx_rule_gaze")).is_true()
	assert_int(saver.calls.size()).is_equal(n)                  # stamping and reading never save
	core.arrive_at_ruins({}, TREE)
	var last: Dictionary = saver.calls.filter(func(c: Dictionary) -> bool: return c.slot == &"profile").back()
	assert_str(String(last.reason)).is_equal("ruins_entry")
	assert_array(last.payload["codex_read"] as Array).is_equal(["cx_place_act0_3"])
	assert_bool((last.payload["codex_known"] as Array).has("cx_rule_gaze")).is_true()
	for c: Dictionary in saver.calls:
		assert_int(int(c.result)).is_equal(OK)


func test_every_run_end_counts() -> void:
	core.arrive_at_ruins({}, TREE)
	_end_runs(2)
	assert_int(core.runs_ended()).is_equal(2)
	core.start_run(7)
	core.enter_seam()
	assert_bool(core.abandon_from_seam()).is_true()
	assert_int(core.runs_ended()).is_equal(3)


func test_tier_one_backstop_after_run_three_opens_the_gated_lamps() -> void:
	core.arrive_at_ruins({}, TREE)
	_end_runs(SYS_BACKSTOP_RUNS - 1)
	core.arrive_at_ruins({}, TREE)
	for id in TIER1_GATES:
		assert_bool(core.codex_known().has(id)).is_false()
	for id in GATED_T1:
		assert_str(String(LanternTreeRules.state_of(TREE, id, core.profile().tree_nodes, 0, core.codex_known()))) \
			.is_equal(String(LanternTreeRules.NEEDS_CODEX))
	_end_runs(1)
	assert_int(core.runs_ended()).is_equal(SYS_BACKSTOP_RUNS)
	core.arrive_at_ruins({}, TREE)
	for id in TIER1_GATES:
		assert_bool(core.codex_known().has(id)).is_true()
	assert_bool(core.codex_known().has(&"cx_choir_matron")).is_false()   # tier 2 waits for Iteration 2
	var last: Dictionary = saver.calls.filter(func(c: Dictionary) -> bool: return c.slot == &"profile").back()
	assert_str(String(last.reason)).is_equal("ruins_entry")
	assert_int((last.payload["codex_known"] as Array).size()).is_equal(1 + TIER1_GATES.size())
	# The four gated tier-1 lamps are now buyable, at 0 Ember, one `tree_purchase` write each.
	var ember := core.profile().ember_banked
	for id in GATED_T1:
		assert_bool(core.buy_tree_node_id(TREE, id)).is_true()
		assert_str(String(saver.calls.back().reason)).is_equal("tree_purchase")
	assert_int(core.profile().ember_banked).is_equal(ember)


func test_backstop_needs_the_tree_and_is_idempotent() -> void:
	_end_runs(SYS_BACKSTOP_RUNS)
	core.arrive_at_ruins({})
	assert_bool(core.codex_known().has(&"cx_rule_gaze")).is_false()
	assert_int(core.apply_codex_backstop(TREE)).is_equal(TIER1_GATES.size())
	assert_int(core.apply_codex_backstop(TREE)).is_equal(0)
