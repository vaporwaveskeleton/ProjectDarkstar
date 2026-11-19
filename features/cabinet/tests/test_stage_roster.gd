extends GdUnitTestSuite
## The Act 0 shift (SYS-001 §1.5, PM 2026-11-19): five stages in order, the cold ones first, the
## entity wakes from a0_3, the star spine only on THE LAST NORMAL DAY. Every key has English text.

const ROSTER := "res://data/cabinet/stage_roster.tres"
const IDS: Array[StringName] = [&"a0_1", &"a0_2", &"a0_3", &"a0_4", &"a0_5"]
const SHARDS_PER_GEODE := 3     ## CabinetStage.geodes lint: geodes * 3 >= 24 shards of supply
const MIN_SHARDS := 24

var roster: CabinetStageRoster


func before_test() -> void:
	roster = load(ROSTER) as CabinetStageRoster


func test_the_roster_holds_the_five_stages_in_order() -> void:
	assert_object(roster).is_not_null()
	assert_int(roster.size()).is_equal(5)
	var ids: Array[StringName] = []
	for st in roster.stages:
		ids.append(st.id)
	assert_array(ids).is_equal(IDS)


func test_stage_ids_are_unique_and_findable() -> void:
	var seen := {}
	for i in roster.size():
		var st := roster.get_stage(i)
		assert_bool(seen.has(st.id)).override_failure_message("duplicate stage id %s" % st.id).is_false()
		seen[st.id] = true
		assert_int(roster.index_of(st.id)).is_equal(i)
	assert_object(roster.get_stage(-1)).is_null()
	assert_object(roster.get_stage(roster.size())).is_null()
	assert_int(roster.index_of(&"nope")).is_equal(-1)


func test_the_first_two_are_cold_sepulchres_to_clear() -> void:
	for id: StringName in [&"a0_1", &"a0_2"]:
		var st := roster.get_stage(roster.index_of(id))
		assert_int(st.goal).override_failure_message("%s goal" % id).is_equal(CabinetStage.Goal.CLEAR_SEPULCHRE)
		assert_bool(st.sepulchre_wakes).override_failure_message("%s must stay cold" % id).is_false()


func test_from_a0_3_the_entity_wakes_and_must_be_unmade() -> void:
	for id: StringName in [&"a0_3", &"a0_4", &"a0_5"]:
		var st := roster.get_stage(roster.index_of(id))
		assert_int(st.goal).override_failure_message("%s goal" % id).is_equal(CabinetStage.Goal.UNMAKE_ENTITY)
		assert_bool(st.sepulchre_wakes).override_failure_message("%s must wake" % id).is_true()


func test_only_the_last_normal_day_has_the_star_spine() -> void:
	for st in roster.stages:
		assert_bool(st.spine_stars).override_failure_message("%s spine_stars" % st.id).is_equal(st.id == &"a0_5")


func test_every_card_key_has_english_text() -> void:
	for st in roster.stages:
		var keys: Array[String] = [st.title_key, st.subtitle_key]
		if st.id == &"a0_1":
			assert_str(st.zone_key).override_failure_message("a0_1 has no zone line").is_empty()
		else:
			assert_str(st.zone_key).override_failure_message("%s needs a zone line" % st.id).is_not_empty()
			keys.append(st.zone_key)
		for k in keys:
			assert_str(k).override_failure_message("%s has an empty key" % st.id).is_not_empty()
			assert_str(tr(k)).override_failure_message("%s has no translation" % k).is_not_equal(k)


func test_every_stage_has_enough_shard_supply() -> void:
	for st in roster.stages:
		assert_int(st.geodes * SHARDS_PER_GEODE).override_failure_message("%s shard supply" % st.id).is_greater_equal(MIN_SHARDS)


func test_the_cabinet_game_scene_plays_this_roster() -> void:
	var scene := load("res://features/cabinet/cabinet_game.tscn") as PackedScene
	var state := scene.get_state()
	var found := false
	for p in state.get_node_property_count(0):
		if state.get_node_property_name(0, p) == &"roster":
			found = true
			assert_str((state.get_node_property_value(0, p) as Resource).resource_path).is_equal(ROSTER)
	assert_bool(found).is_true()


## PM 2026-11-19: THE LAST NORMAL DAY eased to 4 Grubs and 1 guard Acolyte.
func test_the_last_normal_day_population() -> void:
	var st := roster.get_stage(roster.index_of(&"a0_5"))
	assert_int(st.grubs).is_equal(4)
	assert_int(st.guard_acolytes).is_equal(1)


func test_the_default_roster_is_this_roster_and_counts_five() -> void:
	assert_str(CabinetStageRoster.DEFAULT_PATH).is_equal(ROSTER)
	assert_object(CabinetStageRoster.default_roster()).is_not_null()
	assert_int(CabinetStageRoster.default_size()).is_equal(5)


func test_a_zone_card_has_a_zone_cue_and_only_then() -> void:
	for st: CabinetStage in roster.stages:
		assert_bool(st.zone_cue != &"").override_failure_message("%s: zone_cue iff zone_key" % st.id) \
			.is_equal(not st.zone_key.is_empty())
