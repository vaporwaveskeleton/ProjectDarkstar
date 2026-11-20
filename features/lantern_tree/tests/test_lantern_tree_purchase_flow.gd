extends GdUnitTestSuite
## Lantern Tree purchase rules and flow (LanternTreeRules; RunSessionCore.buy_tree_node_id; Q-T326):
## state of a node, the tier gate and hard prerequisites, Codex gates, the slice's tier-1-only sale,
## one `tree_purchase` profile write per purchase (ids only), never mid-run, and the bought hull
## modules reaching the sector Vigil.

const TREE := preload("res://data/lantern_tree/m2_tree.tres")
const STATS := preload("res://data/run/run_session.tres")
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


func _ids(list: Array) -> Array[StringName]:
	var out: Array[StringName] = []
	for s: Variant in list:
		out.append(StringName(str(s)))
	return out


## The same tree with tier 2 on sale (a shallow copy: only scalars change; the shared preload is untouched).
func _tree_with_t2() -> LanternTreeData:
	var t := TREE.duplicate() as LanternTreeData
	t.max_tier_on_sale = 2
	return t


func test_states_of_tier_one_nodes() -> void:
	var none := _ids([])
	assert_str(String(LanternTreeRules.state_of(TREE, &"LANTERN-1", none, 40))).is_equal(String(LanternTreeRules.BUYABLE))
	assert_str(String(LanternTreeRules.state_of(TREE, &"LANTERN-1", none, 39))).is_equal(String(LanternTreeRules.SHORT))
	assert_str(String(LanternTreeRules.state_of(TREE, &"LANTERN-1", _ids(["LANTERN-1"]), 400))).is_equal(String(LanternTreeRules.OWNED))
	assert_str(String(LanternTreeRules.state_of(TREE, &"NOPE-1", none, 400))).is_equal(String(LanternTreeRules.UNKNOWN))


func test_codex_gated_nodes_need_their_entry_and_cost_nothing() -> void:
	var none := _ids([])
	assert_str(String(LanternTreeRules.state_of(TREE, &"WARD-1", none, 400))).is_equal(String(LanternTreeRules.NEEDS_CODEX))
	assert_str(String(LanternTreeRules.state_of(TREE, &"WARD-1", none, 0, _ids(["cx_choir_shrine"])))).is_equal(String(LanternTreeRules.BUYABLE))


func test_the_slice_hangs_tier_two_as_dark_lamps() -> void:
	var all_t1 := _ids(["LANTERN-1", "LANTERN-2", "LANTERN-3"])
	assert_str(String(LanternTreeRules.state_of(TREE, &"LANTERN-5", all_t1, 1000))).is_equal(String(LanternTreeRules.NOT_IN_SLICE))


func test_tier_two_needs_its_prerequisite_and_the_tier_gate() -> void:
	var t := _tree_with_t2()
	# LANTERN-5 hangs from LANTERN-3 (LOOP-001 §3.3) and needs 2 tier-1 LANTERN nodes (§3.1)
	assert_str(String(LanternTreeRules.state_of(t, &"LANTERN-5", _ids(["LANTERN-1", "LANTERN-2"]), 1000))).is_equal(String(LanternTreeRules.NEEDS_PREREQ))
	assert_str(String(LanternTreeRules.state_of(t, &"LANTERN-5", _ids(["LANTERN-3"]), 1000))).is_equal(String(LanternTreeRules.NEEDS_TIER))
	assert_str(String(LanternTreeRules.state_of(t, &"LANTERN-5", _ids(["LANTERN-3", "HULL-1", "HULL-3"]), 1000))).is_equal(String(LanternTreeRules.NEEDS_TIER))
	assert_str(String(LanternTreeRules.state_of(t, &"LANTERN-5", _ids(["LANTERN-3", "LANTERN-1"]), 119))).is_equal(String(LanternTreeRules.SHORT))
	assert_str(String(LanternTreeRules.state_of(t, &"LANTERN-5", _ids(["LANTERN-3", "LANTERN-1"]), 120))).is_equal(String(LanternTreeRules.BUYABLE))
	# ORDNANCE-6 has no hard prerequisite: the tier gate alone
	assert_str(String(LanternTreeRules.state_of(t, &"ORDNANCE-6", _ids(["ORDNANCE-1"]), 1000))).is_equal(String(LanternTreeRules.NEEDS_TIER))
	assert_str(String(LanternTreeRules.state_of(t, &"ORDNANCE-6", _ids(["ORDNANCE-1", "ORDNANCE-4"]), 1000))).is_equal(String(LanternTreeRules.BUYABLE))


func test_unwired_nodes_can_be_held_back_by_data() -> void:
	var t := TREE.duplicate() as LanternTreeData
	t.sell_unwired = false
	assert_str(String(LanternTreeRules.state_of(t, &"LANTERN-2", _ids([]), 400))).is_equal(String(LanternTreeRules.UNWIRED))
	assert_str(String(LanternTreeRules.state_of(t, &"LANTERN-3", _ids([]), 400))).is_equal(String(LanternTreeRules.BUYABLE))   # PARTIAL sells


func test_suggested_follows_the_pr_90_sale_order_first() -> void:
	assert_str(String(LanternTreeRules.suggested(TREE, _ids([]), 40))).is_equal("LANTERN-1")
	assert_str(String(LanternTreeRules.suggested(TREE, _ids(["LANTERN-1"]), 40))).is_equal("HULL-1")
	assert_str(String(LanternTreeRules.suggested(TREE, _ids(["LANTERN-1", "HULL-1", "HULL-3"]), 40))).is_equal("LANTERN-2")
	assert_str(String(LanternTreeRules.suggested(TREE, _ids([]), 0))).is_equal("LANTERN-1")   # nothing affordable: first unowned


func test_a_purchase_spends_the_tier_price_and_saves_once() -> void:
	core.arrive_at_ruins({"act0_vigil_index": 20_000})   # 100 Ember
	saver.calls.clear()
	assert_bool(core.buy_tree_node_id(TREE, &"HULL-4")).is_true()
	assert_int(core.profile().ember_banked).is_equal(60)
	assert_array(core.profile().tree_nodes).is_equal([&"HULL-4"])
	assert_array(saver.slots_and_reasons()).is_equal(["profile:tree_purchase"])
	assert_array(saver.calls[0].payload["tree_nodes"]).is_equal(["HULL-4"])   # ids only
	assert_int(saver.calls[0].payload["ember_banked"]).is_equal(60)


func test_refused_purchases_spend_and_save_nothing() -> void:
	core.arrive_at_ruins({"act0_vigil_index": 9_000})   # 45 Ember
	assert_bool(core.buy_tree_node_id(TREE, &"LANTERN-3")).is_true()
	saver.calls.clear()
	assert_bool(core.buy_tree_node_id(TREE, &"LANTERN-3")).is_false()   # owned
	assert_bool(core.buy_tree_node_id(TREE, &"HULL-1")).is_false()      # 5 < 40
	assert_bool(core.buy_tree_node_id(TREE, &"LANTERN-5")).is_false()   # tier 2: a dark lamp
	assert_bool(core.buy_tree_node_id(TREE, &"WARD-1")).is_false()      # Codex-gated, nothing stamped
	assert_bool(core.buy_tree_node_id(TREE, &"BOGUS-1")).is_false()
	assert_bool(core.buy_tree_node_id(null, &"HULL-1")).is_false()
	assert_int(core.profile().ember_banked).is_equal(5)
	assert_int(saver.calls.size()).is_equal(0)


func test_never_mid_run() -> void:
	core.arrive_at_ruins({"act0_vigil_index": 20_000})
	core.start_run(5)
	assert_bool(core.buy_tree_node_id(TREE, &"HULL-1")).is_false()
	assert_int(core.profile().ember_banked).is_equal(100)


func test_the_old_stock_purchase_and_the_new_one_share_the_profile() -> void:
	core.arrive_at_ruins({"act0_vigil_index": 30_000})   # 150 Ember
	assert_str(String(core.buy_tree_node(TREE.stock))).is_equal("LANTERN-1")   # #90's path still works
	assert_bool(core.buy_tree_node_id(TREE, &"HULL-1")).is_true()
	assert_str(String(core.buy_tree_node(TREE.stock))).is_equal("HULL-3")       # skips what the tree bought
	assert_int(core.profile().ember_banked).is_equal(30)   # 150 - 3 × 40


func test_bought_modules_show_on_the_sector_vigil() -> void:
	core.arrive_at_ruins({"act0_vigil_index": 20_000})
	assert_bool(core.buy_tree_node_id(TREE, &"HULL-4")).is_true()
	assert_bool(core.buy_tree_node_id(TREE, &"LANTERN-3")).is_true()
	core.start_run(5)
	var runner := scene_runner(SECTOR)
	var sector: Node = runner.scene()
	sector.on_route_entered(core.enter_seam())
	var vigil: Vigil = sector.vigil
	assert_array(Array(vigil.tree_nodes)).is_equal(["HULL-4", "LANTERN-3"])
	assert_bool(vigil.rig.has_part(&"plate")).is_true()        # HULL-4 Plating (#90 module)
	assert_bool(vigil.rig.has_part(&"globeLarge")).is_true()   # LANTERN-3 Full Wick
	assert_bool(vigil.rig.has_part(&"vaneA")).is_false()       # HULL-1 not bought
