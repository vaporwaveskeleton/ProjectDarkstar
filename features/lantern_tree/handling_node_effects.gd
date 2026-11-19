class_name HandlingNodeEffects
extends TunableResource
## Lantern Tree handling readings as data (LOOP-001 §3.3, §3.8): node id -> list of field effects
## on VigilAetherStats. Each effect is {"field": String, "op": String, "value": float}.
## Ops: "max_to" (raise to at least value), "mul" (multiply by value), "add_base_frac"
## (additive fraction of the BASE value; all such on one field sum), "speed_frac" (adds to the
## shared speed bonus, which scales max_speed, accel and brake together, capped by speed_bonus_cap).
## Values live in data/lantern_tree/handling_node_effects.tres.

@export var effects: Dictionary = {}
## LOOP-001 §3.3: total max_speed bonus never exceeds +12%.
@export var speed_bonus_cap: float = 0.0


func tunable_properties() -> PackedStringArray:
	return PackedStringArray(["speed_bonus_cap"])
