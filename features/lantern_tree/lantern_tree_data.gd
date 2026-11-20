class_name LanternTreeData
extends TunableResource
## The Lantern Tree the Ruins station shows (LOOP-001 §3; M2: the 30-node stub, PROD-001 §3 M2).
## Nodes are content (`LanternTreeNode` sub-resources); prices come from the tier only
## (SYS-001 §7.7): tier 1 from the #90 stock resource (`ds_lantern_tree.stock.price_tier1`, one
## source), tier 2 and the Codex-gated price here. The purchase rules are LanternTreeRules.
## Values live in data/lantern_tree/m2_tree.tres.

## The five branches in display order (LOOP-001 §3.1).
const BRANCHES: Array[StringName] = [&"LANTERN", &"HULL", &"ORDNANCE", &"WARD", &"MADNESS"]

## Every node of this tree, grouped by branch, tier ascending.
@export var nodes: Array[LanternTreeNode] = []
## The #90 tier-1 stock: its `price_tier1` is the tier-1 price and its `node_ids` the suggested
## first purchases (the station's default focus).
@export var stock: LanternTreeStock
## Ember price of a tier-2 node (SYS-001 §7.7).
@export var price_tier2: int = 0
## Ember price of a Codex-gated node at any tier (SYS-001 §7.6 / §7.7).
@export var price_codex_gated: int = 0
## Tier-1 nodes of the same branch that must be owned before its tier 2 opens
## (LOOP-001 §3.1 pity rule; SYS-001 §7.7 proposed row).
@export var tier2_gate: int = 0
## Highest tier the station sells; nodes above it hang as dark lamps (PROD-001 §3 M2: the slice
## Tree sells tier 1 only; SYS-001 §7.7 proposed row).
@export var max_tier_on_sale: int = 1
## Whether nodes whose effect is not wired yet (Wiring.NOOP) are on sale (TECH-001 Q-T328).
@export var sell_unwired: bool = true


func tunable_properties() -> PackedStringArray:
	return PackedStringArray(["price_tier2", "price_codex_gated", "tier2_gate", "max_tier_on_sale"])


## The node with this id, or null.
func get_node_def(id: StringName) -> LanternTreeNode:
	for n in nodes:
		if n != null and n.id == id:
			return n
	return null


func has_node_id(id: StringName) -> bool:
	return get_node_def(id) != null


## Ember price of a node: 0 when Codex-gated, else its tier's SYS-001 §7.7 price. -1 for a tier
## this tree has no price for.
func price_of(n: LanternTreeNode) -> int:
	if n == null:
		return -1
	if n.is_codex_gated():
		return price_codex_gated
	match n.tier:
		1:
			return stock.price_tier1 if stock != null else -1
		2:
			return price_tier2
	return -1


## Tier-gate count for a tier: how many nodes of the tier below, same branch, must be owned.
func gate_for_tier(tier: int) -> int:
	return tier2_gate if tier == 2 else 0


## The nodes of one branch, in data order.
func nodes_in(branch: StringName) -> Array[LanternTreeNode]:
	var out: Array[LanternTreeNode] = []
	for n in nodes:
		if n != null and n.branch == branch:
			out.append(n)
	return out
