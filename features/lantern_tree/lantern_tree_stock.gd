class_name LanternTreeStock
extends TunableResource
## The Lantern Tree nodes the station sells, in the order it sells them (Q-T191; LOOP-001 §3.8).
## One price per tier (SYS-001 §7.7). Only the tier-1 handling nodes are on sale so far.
## Values live in data/lantern_tree/tier1_stock.tres.

## Node ids in sale order (LANTERN-1, HULL-1, HULL-3: the tier-1 handling nodes).
@export var node_ids: PackedStringArray = PackedStringArray()
## Ember price of a tier-1 node (SYS-001 §7.7).
@export var price_tier1: int = 0


func tunable_properties() -> PackedStringArray:
	return PackedStringArray(["price_tier1"])


## The next node to sell: the first id in sale order not in `owned`, or &"" when all are owned.
func next_unbought(owned: Array[StringName]) -> StringName:
	for id in node_ids:
		if not owned.has(StringName(id)):
			return StringName(id)
	return &""
