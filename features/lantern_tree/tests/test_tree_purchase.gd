extends GdUnitTestSuite
## The Lantern Tree station's purchase (Q-T191; LOOP-001 §3.8): the next unbought tier-1 handling node
## for the SYS-001 §7.7 tier-1 price, persisted in the profile (ids only, reason `tree_purchase`),
## never mid-run, and the bought nodes reach the sector Vigil.

const STATS := preload("res://data/run/run_session.tres")
const STOCK := preload("res://data/lantern_tree/tier1_stock.tres")
const SpySaver := preload("res://features/run/tests/run_spy_saver.gd")
const SECTOR := "res://scenes/sector/sector_stub.tscn"

var saver: SpySaver
var core: RunSessionCore


func before_test() -> void:
	saver = SpySaver.new()
	core = RunSessionCore.new(STATS, saver)


func after_test() -> void:
	get_tree().paused = false
	saver.free_service()


func test_stock_is_the_tier_one_handling_nodes_at_the_sys_001_price() -> void:
	assert_array(Array(STOCK.node_ids)).is_equal(["LANTERN-1", "HULL-1", "HULL-3"])
	assert_int(STOCK.price_tier1).is_equal(40)
	for id in STOCK.node_ids:
		assert_bool(HandlingTree.EFFECTS.effects.has(id)).is_true()   # every node on sale has a reading


func test_a_purchase_spends_forty_records_the_id_and_saves_the_profile() -> void:
	core.arrive_at_ruins({"act0_vigil_index": 1200})   # the floor: 40 Ember
	saver.calls.clear()
	assert_str(String(core.buy_tree_node(STOCK))).is_equal("LANTERN-1")
	assert_int(core.profile().ember_banked).is_equal(0)
	assert_array(core.profile().tree_nodes).is_equal([&"LANTERN-1"])
	assert_array(saver.slots_and_reasons()).is_equal(["profile:tree_purchase"])
	assert_array(saver.calls[0].payload["tree_nodes"]).is_equal(["LANTERN-1"])   # ids only
	assert_int(saver.calls[0].result).is_equal(OK)


func test_the_second_use_buys_the_next_node_then_stops_when_short() -> void:
	core.arrive_at_ruins({"act0_vigil_index": 20_000})   # 100 Ember
	assert_str(String(core.buy_tree_node(STOCK))).is_equal("LANTERN-1")
	assert_str(String(core.buy_tree_node(STOCK))).is_equal("HULL-1")
	assert_int(core.profile().ember_banked).is_equal(20)
	assert_str(String(core.buy_tree_node(STOCK))).is_equal("")   # 20 < 40: nothing bought
	assert_int(core.profile().ember_banked).is_equal(20)
	assert_array(core.profile().tree_nodes).is_equal([&"LANTERN-1", &"HULL-1"])


func test_nothing_is_bought_when_every_node_is_owned() -> void:
	core.arrive_at_ruins({"act0_vigil_index": 100_000})   # 500 Ember
	for i in 3:
		core.buy_tree_node(STOCK)
	assert_str(String(core.buy_tree_node(STOCK))).is_equal("")
	assert_int(core.profile().ember_banked).is_equal(380)


func test_unaffordable_buys_nothing_and_saves_nothing() -> void:
	assert_str(String(core.buy_tree_node(STOCK))).is_equal("")   # no Ember at all
	assert_int(saver.calls.size()).is_equal(0)
	assert_int(core.profile().tree_nodes.size()).is_equal(0)


func test_never_mid_run() -> void:
	core.arrive_at_ruins({"act0_vigil_index": 20_000})
	core.start_run(5)
	assert_str(String(core.buy_tree_node(STOCK))).is_equal("")
	assert_int(core.profile().ember_banked).is_equal(100)


func test_the_first_visit_floor_always_buys_the_first_node() -> void:
	core.arrive_at_ruins({"act0_vigil_index": 0})
	assert_str(String(core.buy_tree_node(STOCK))).is_equal("LANTERN-1")


func test_bought_nodes_survive_a_save_and_load() -> void:
	core.arrive_at_ruins({"act0_vigil_index": 20_000})
	core.buy_tree_node(STOCK)
	core.buy_tree_node(STOCK)
	var again := RunSessionCore.new(STATS, saver)
	again.load_from_saver()
	assert_array(again.profile().tree_nodes).is_equal([&"LANTERN-1", &"HULL-1"])
	assert_int(again.profile().ember_banked).is_equal(20)


func test_a_malformed_node_list_is_rejected() -> void:
	assert_object(ProfileState.from_payload({"tree_nodes": [3]})).is_null()
	assert_object(ProfileState.from_payload({"tree_nodes": "HULL-1"})).is_null()


func test_bought_nodes_reach_the_sector_vigil() -> void:
	core.arrive_at_ruins({"act0_vigil_index": 20_000})
	core.buy_tree_node(STOCK)
	core.buy_tree_node(STOCK)
	core.start_run(5)
	var runner := scene_runner(SECTOR)
	var sector: Node = runner.scene()
	sector.on_route_entered(core.enter_seam())
	var vigil: Vigil = sector.vigil
	assert_array(Array(vigil.tree_nodes)).is_equal(["LANTERN-1", "HULL-1"])
	assert_int(vigil.motor.aether_stats.surge_charges).is_equal(2)   # LANTERN-1
