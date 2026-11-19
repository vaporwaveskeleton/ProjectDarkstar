class_name ChargeStats
extends TunableResource
## Null-Iron Charge flight tunables (GDD §8.3, SYS-001 §1.4). Values live in data/charges/charge.tres.

## SYS-001 §1.4 Charge speed, 210 px/s (🔒).
@export var speed_px_s: float = 0.0
## SYS-001 §1.4 Turn authority, 1.6 s (🔒): the time a Charge needs to turn through 180°, so the
## steering limit is PI / turn_authority_s rad/s (the Cabinet's reading, glass_field.gd).
@export var turn_authority_s: float = 1.0
## SYS-001 §1.4 Charge life, 6.0 s ✱: then it gutters (counts as lost, cue charge_gutter).
@export var life_s: float = 0.0
## SYS-001 §1.4 Charge HP (interceptable), 1 damage unit ✱.
@export var hp: int = 1
## SYS-001 §1.4: damage a Grub contact does to a Charge (1).
@export var grub_contact_damage: int = 1
## SYS-001 §1.4: damage a geode contact does to a Charge (1).
@export var geode_contact_damage: int = 1
## Hits a Charge lands on its target (PM, M1 slice 3 PR 4: Charge → target 1 hit).
@export var target_hits: int = 1
## Contact radius of the Charge (px) ✱ (the Cabinet's CHARGE_RADIUS).
@export var radius_px: float = 4.0
## Trail points drawn behind a Charge ✱ (presentation, the Cabinet's 10).
@export var trail_points: int = 10


## Steering limit in rad/s.
func turn_rate() -> float:
	return PI / maxf(0.001, turn_authority_s)


func tunable_properties() -> PackedStringArray:
	return PackedStringArray(["speed_px_s", "turn_authority_s", "life_s", "hp", "grub_contact_damage",
		"geode_contact_damage", "target_hits", "radius_px", "trail_points"])
