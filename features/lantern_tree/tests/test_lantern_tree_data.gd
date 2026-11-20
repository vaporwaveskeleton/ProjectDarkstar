extends GdUnitTestSuite
## The M2 Lantern Tree stub as data (data/lantern_tree/m2_tree.tres; PROD-001 §3 M2, LOOP-001 §3):
## 30 nodes over the five branches, prerequisites that exist, sit lower and form a DAG, every price
## from a SYS-001 §7.6/§7.7 row, the #90 handling nodes folded in, and unwired nodes marked.

const TREE := preload("res://data/lantern_tree/m2_tree.tres")
const STOCK := preload("res://data/lantern_tree/tier1_stock.tres")

## SYS-001 §7.7 `Lantern Tree node price, tier 1` and `tier 2`; §7.6 `Ink-node Ember price`
## (= §7.7 `Codex-gated nodes`). The test restates the rows so a data drift is caught.
const SYS_PRICE_T1 := 40
const SYS_PRICE_T2 := 120
const SYS_PRICE_CODEX := 0
## LOOP-001 §3.3 `Requires` column: the Codex-gated nodes of tiers 1–2 and their entries (§3.7).
const GATES := {
	"LANTERN-4": "cx_rule_lantern_dark", "WARD-1": "cx_choir_shrine", "WARD-6": "cx_choir_matron",
	"MADNESS-2": "cx_rule_gaze", "MADNESS-3": "cx_rule_frayed", "MADNESS-5": "cx_rule_unmoored",
}


func test_thirty_nodes_over_five_branches() -> void:
	assert_int(TREE.nodes.size()).is_equal(30)
	for b in LanternTreeData.BRANCHES:
		var list := TREE.nodes_in(b)
		assert_int(list.size()).override_failure_message("%s has %d nodes" % [b, list.size()]).is_equal(6)
		var t1 := list.filter(func(n: LanternTreeNode) -> bool: return n.tier == 1).size()
		var t2 := list.filter(func(n: LanternTreeNode) -> bool: return n.tier == 2).size()
		assert_int(t1).is_equal(4)   # every tier-1 node of the branch (the slice shows tier 1)
		assert_int(t2).is_equal(2)   # two tier-2 dark lamps per branch


func test_every_tier_one_node_of_loop_001_is_in_the_stub() -> void:
	for b in LanternTreeData.BRANCHES:
		for i in range(1, 5):
			var id := StringName("%s-%d" % [b, i])
			assert_bool(TREE.has_node_id(id)).override_failure_message("missing %s" % id).is_true()


func test_the_data_validates_clean() -> void:
	var errs := LanternTreeRules.validate(TREE)
	assert_array(Array(errs)).override_failure_message("\n".join(errs)).is_empty()


func test_prerequisites_form_a_dag() -> void:
	assert_bool(LanternTreeRules.has_cycle(TREE)).is_false()
	for n in TREE.nodes:
		for r in n.requires:
			var p := TREE.get_node_def(StringName(r))
			assert_object(p).override_failure_message("%s requires unknown %s" % [n.id, r]).is_not_null()
			assert_int(p.tier).is_less(n.tier)
			assert_str(String(p.branch)).is_equal(String(n.branch))   # no cross-branch prereq in tiers 1–2


func test_a_cycle_is_caught() -> void:
	var bad := LanternTreeData.new()
	bad.stock = STOCK
	bad.price_tier2 = SYS_PRICE_T2
	var a := LanternTreeNode.new()
	a.id = &"HULL-5"
	a.branch = &"HULL"
	a.tier = 2
	a.requires = PackedStringArray(["HULL-6"])
	var b := LanternTreeNode.new()
	b.id = &"HULL-6"
	b.branch = &"HULL"
	b.tier = 2
	b.requires = PackedStringArray(["HULL-5"])
	bad.nodes = [a, b]
	assert_bool(LanternTreeRules.has_cycle(bad)).is_true()
	assert_bool(LanternTreeRules.validate(bad).size() > 0).is_true()


func test_every_price_comes_from_a_sys_001_row() -> void:
	assert_int(TREE.stock.price_tier1).is_equal(SYS_PRICE_T1)
	assert_object(TREE.stock).is_same(STOCK)   # one source for the tier-1 price (#90's stock)
	assert_int(TREE.price_tier2).is_equal(SYS_PRICE_T2)
	assert_int(TREE.price_codex_gated).is_equal(SYS_PRICE_CODEX)
	var total := 0
	for n in TREE.nodes:
		var want := SYS_PRICE_CODEX if n.is_codex_gated() else (SYS_PRICE_T1 if n.tier == 1 else SYS_PRICE_T2)
		assert_int(TREE.price_of(n)).override_failure_message("%s price" % n.id).is_equal(want)
		total += TREE.price_of(n)
	assert_int(total).is_equal(16 * SYS_PRICE_T1 + 8 * SYS_PRICE_T2)   # 16 Ember T1 + 8 Ember T2


func test_codex_gates_match_loop_001() -> void:
	var gated := 0
	for n in TREE.nodes:
		if n.is_codex_gated():
			gated += 1
			assert_str(String(n.codex_gate)).is_equal(str(GATES.get(String(n.id), "")))
	assert_int(gated).is_equal(GATES.size())


func test_the_handling_nodes_of_pr_90_are_folded_in() -> void:
	for id in STOCK.node_ids:   # LANTERN-1, HULL-1, HULL-3: the #90 sale order is unchanged
		assert_bool(TREE.has_node_id(StringName(id))).is_true()
	assert_array(Array(STOCK.node_ids)).is_equal(["LANTERN-1", "HULL-1", "HULL-3"])
	assert_int(STOCK.price_tier1).is_equal(40)
	# every tree node with a handling reading is at least partly wired, and every wired node has one
	for n in TREE.nodes:
		var has_reading: bool = HandlingTree.EFFECTS.effects.has(String(n.id))
		if has_reading:
			assert_int(n.wiring).override_failure_message("%s has a reading" % n.id).is_not_equal(LanternTreeNode.Wiring.NOOP)
		if n.wiring == LanternTreeNode.Wiring.WIRED:
			assert_bool(has_reading).override_failure_message("%s is WIRED with no reading" % n.id).is_true()


func test_the_tier_one_hull_modules_are_in_the_tree() -> void:
	# LOOP-001 §3.8: the five T1 modules plus ORDNANCE-1's bow line show on the hull once bought
	for id in ["LANTERN-1", "LANTERN-3", "HULL-1", "HULL-3", "HULL-4", "ORDNANCE-1"]:
		assert_bool(TREE.has_node_id(StringName(id))).is_true()
		assert_bool(AetherVigilRig.MODULE_PARTS.has(id)).override_failure_message("%s has no module" % id).is_true()


func test_unwired_nodes_are_marked_in_the_data() -> void:
	var noop := 0
	for n in TREE.nodes:
		if n.wiring != LanternTreeNode.Wiring.WIRED:
			assert_str(n.stub_note.strip_edges()).override_failure_message("%s needs a stub note" % n.id).is_not_empty()
		if n.wiring == LanternTreeNode.Wiring.NOOP:
			noop += 1
			assert_str(n.stub_note).starts_with("no-op")
	assert_int(noop).is_equal(21)   # 4 WIRED + 5 PARTIAL + 21 NOOP = 30


func test_the_slice_sells_tier_one_only() -> void:
	assert_int(TREE.max_tier_on_sale).is_equal(1)   # PROD-001 §3 M2 (proposed SYS-001 row)
	assert_int(TREE.tier2_gate).is_equal(2)         # LOOP-001 §3.1 pity, T2 (proposed SYS-001 row)


func test_the_ds_keys_are_registered() -> void:
	var keys := TREE.ds_keys()
	for k in ["ds_lantern_tree.tree.price_tier2", "ds_lantern_tree.tree.price_codex_gated",
			"ds_lantern_tree.tree.tier2_gate", "ds_lantern_tree.tree.max_tier_on_sale"]:
		assert_bool(keys.has(k)).override_failure_message("missing %s" % k).is_true()


func test_every_node_names_its_text_keys() -> void:
	for n in TREE.nodes:
		var stem := "RUINS_TREE_%s" % String(n.id).replace("-", "_")
		assert_str(String(n.name_key)).is_equal(stem + "_NAME")
		assert_str(String(n.effect_key)).is_equal(stem + "_FX")
		assert_str(tr(n.name_key)).is_not_equal(String(n.name_key))   # translated, never a raw key
		assert_str(tr(n.effect_key)).is_not_equal(String(n.effect_key))
