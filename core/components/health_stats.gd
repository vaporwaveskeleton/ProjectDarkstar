class_name HealthStats
extends TunableResource
## Tunables for a HealthComponent. Values come from SYS-001; this resource only stores them.
## D-08 (one-hit hull) is OPEN: the Vigil's hull is a data edit here, never a code change.

## SYS-001 §1.2 "Hull HP" for the Vigil (base 1). Must be >= 1.
@export_range(1, 999) var max_hp: int = 1
## Seconds of invulnerability after an accepted hit. 0 = none.
## No SYS-001 row exists; 0 keeps one-hit behaviour honest. ✱ engineering default (TECH-001 §11).
@export_range(0.0, 10.0, 0.01) var invulnerable_after_hit_s: float = 0.0


func tunable_properties() -> PackedStringArray:
	return PackedStringArray(["max_hp", "invulnerable_after_hit_s"])
