class_name LanternTreeRules
extends RefCounted
## Pure Lantern Tree purchase rules (LOOP-001 §3.1, §3.7; SYS-001 §7.7). No nodes, no saves:
## RunSessionCore.buy_tree_node_id spends and saves; the station screen only reads `state_of`.

## Why a node can or cannot be bought, in the order the checks run.
const OWNED := &"owned"
const NOT_IN_SLICE := &"not_in_slice"     ## above `max_tier_on_sale`: a dark lamp
const UNWIRED := &"unwired"               ## Wiring.NOOP and the tree does not sell unwired nodes
const NEEDS_CODEX := &"needs_codex"       ## gating entry not stamped (LOOP-001 §3.7)
const NEEDS_PREREQ := &"needs_prereq"     ## a hard `requires` node is not owned
const NEEDS_TIER := &"needs_tier"         ## fewer than the tier gate's nodes owned in the tier below
const SHORT := &"short"                   ## not enough banked Ember
const BUYABLE := &"buyable"
const UNKNOWN := &"unknown"               ## not a node of this tree


## The node's state for this owner. `owned` = owned node ids, `known` = stamped Codex entry ids.
static func state_of(tree: LanternTreeData, id: StringName, owned: Array[StringName], ember: int,
		known: Array[StringName] = []) -> StringName:
	var n := tree.get_node_def(id) if tree != null else null
	if n == null:
		return UNKNOWN
	if owned.has(id):
		return OWNED
	if n.tier > tree.max_tier_on_sale:
		return NOT_IN_SLICE
	if n.wiring == LanternTreeNode.Wiring.NOOP and not tree.sell_unwired:
		return UNWIRED
	if n.is_codex_gated() and not known.has(n.codex_gate):
		return NEEDS_CODEX
	for r in n.requires:
		if not owned.has(StringName(r)):
			return NEEDS_PREREQ
	if owned_in_tier(tree, n.branch, n.tier - 1, owned) < tree.gate_for_tier(n.tier):
		return NEEDS_TIER
	if ember < tree.price_of(n):
		return SHORT
	return BUYABLE


static func can_buy(tree: LanternTreeData, id: StringName, owned: Array[StringName], ember: int,
		known: Array[StringName] = []) -> bool:
	return state_of(tree, id, owned, ember, known) == BUYABLE


## Owned nodes of `branch` at `tier`.
static func owned_in_tier(tree: LanternTreeData, branch: StringName, tier: int, owned: Array[StringName]) -> int:
	var c := 0
	for n in tree.nodes_in(branch):
		if n.tier == tier and owned.has(n.id):
			c += 1
	return c


## The station's default focus: the first buyable node of the stock's sale order, else the first
## buyable node in data order, else the first unowned node, else the first node.
static func suggested(tree: LanternTreeData, owned: Array[StringName], ember: int,
		known: Array[StringName] = []) -> StringName:
	if tree.stock != null:
		for id in tree.stock.node_ids:
			if can_buy(tree, StringName(id), owned, ember, known):
				return StringName(id)
	for n in tree.nodes:
		if can_buy(tree, n.id, owned, ember, known):
			return n.id
	for n in tree.nodes:
		if not owned.has(n.id):
			return n.id
	return tree.nodes[0].id if not tree.nodes.is_empty() else &""


## Data integrity (LOOP-001 §3.1): returns one message per problem, empty when the tree is sound.
## Checks ids and branches, tiers against node numbers, unique ids, prerequisites that exist, sit in
## a lower tier and form a DAG, Codex-gated nodes carry a gate, NOOP/PARTIAL nodes carry a note,
## and every node has a price from a SYS-001 §7.7 row.
static func validate(tree: LanternTreeData) -> PackedStringArray:
	var errs := PackedStringArray()
	var seen := {}
	for n in tree.nodes:
		if n == null:
			errs.append("null node")
			continue
		var parts := String(n.id).split("-")
		if parts.size() != 2 or not LanternTreeData.BRANCHES.has(StringName(parts[0])) or StringName(parts[0]) != n.branch:
			errs.append("%s: id must be <BRANCH>-<n> of its branch" % n.id)
		elif not parts[1].is_valid_int() or tier_of_number(parts[1].to_int()) != n.tier:
			errs.append("%s: tier %d does not match its node number" % [n.id, n.tier])
		if seen.has(n.id):
			errs.append("%s: duplicate id" % n.id)
		seen[n.id] = true
		if n.name_key == &"" or n.effect_key == &"":
			errs.append("%s: missing name or effect key" % n.id)
		if n.wiring != LanternTreeNode.Wiring.WIRED and n.stub_note.strip_edges() == "":
			errs.append("%s: unwired node without a stub note" % n.id)
		if n.codex_gate != &"" and not String(n.codex_gate).begins_with("cx_"):
			errs.append("%s: codex gate must be a cx_ entry id" % n.id)
		if tree.price_of(n) < 0:
			errs.append("%s: no SYS-001 §7.7 price for tier %d" % [n.id, n.tier])
	for n in tree.nodes:
		if n == null:
			continue
		for r in n.requires:
			var p := tree.get_node_def(StringName(r))
			if p == null:
				errs.append("%s: requires unknown node %s" % [n.id, r])
			elif p.tier >= n.tier:
				errs.append("%s: requires %s, which is not in a lower tier" % [n.id, r])
	if has_cycle(tree):
		errs.append("prerequisites contain a cycle")
	return errs


## Node number 1..18 -> tier (LOOP-001 §3.1).
static func tier_of_number(num: int) -> int:
	if num < 1 or num > 18:
		return -1
	return mini(floori((num - 1) / 4.0) + 1, 5)


## True when the hard prerequisites contain a cycle (depth-first, three colours).
static func has_cycle(tree: LanternTreeData) -> bool:
	var colour := {}   # id -> 1 visiting, 2 done
	for n in tree.nodes:
		if n != null and _visit(tree, n.id, colour):
			return true
	return false


static func _visit(tree: LanternTreeData, id: StringName, colour: Dictionary) -> bool:
	var c: int = int(colour.get(id, 0))
	if c == 1:
		return true
	if c == 2:
		return false
	colour[id] = 1
	var n := tree.get_node_def(id)
	if n != null:
		for r in n.requires:
			if _visit(tree, StringName(r), colour):
				return true
	colour[id] = 2
	return false
