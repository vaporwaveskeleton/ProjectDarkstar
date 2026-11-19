class_name ChargeMagazineStats
extends TunableResource
## Null-Iron Charge magazine tunables. Values live in data/charges/charge_magazine.tres.

## SYS-001 §1.4 / GDD §8.3: magazine cap, 5 Charges base (🔒). Upgrades (7/9/13) come later.
@export var capacity: int = 0


func tunable_properties() -> PackedStringArray:
	return PackedStringArray(["capacity"])
