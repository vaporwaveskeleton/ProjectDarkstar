class_name WarpTierStats
extends TunableResource
## Sector-entry tier computation inputs (WARP-001 §1.3; values copied from there, `✱` rows of that
## doc). Lives in data/warp/warp_tier.tres (`ds_warp.tier.*`).

## act_floor(A) for A = 0..4 (WARP-001 §1.3, from GDD §9.1's Warp column).
@export var act_floor: PackedInt32Array = PackedInt32Array()
## act_ceiling(A) for A = 0..4.
@export var act_ceiling: PackedInt32Array = PackedInt32Array()
## entropy_term: +1 at E >= entropy_step_1, +2 at E >= entropy_step_2 (WARP-001 §1.3 ✱).
@export var entropy_step_1: int = 0
@export var entropy_step_2: int = 0
## hollow_term: +1 when any sector in the run's biome list is Hollow (one per run, ✱).
@export var hollow_term: int = 0
## composure_term: +1 while Composure is 0 at Seam entry (SYS-001 §1.5 `Hollowed`).
@export var composure_term: int = 0
## Highest tier (T5 Unmaking).
@export var max_tier: int = 0


func tunable_properties() -> PackedStringArray:
	return PackedStringArray(["act_floor", "act_ceiling", "entropy_step_1", "entropy_step_2",
		"hollow_term", "composure_term", "max_tier"])
