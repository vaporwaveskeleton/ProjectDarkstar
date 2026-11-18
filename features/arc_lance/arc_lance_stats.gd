class_name ArcLanceStats
extends TunableResource
## Arc-Lance tunables. Values are copied from SYS-001 §1.3 into data/arc_lance/arc_lance.tres.
## Never edit numbers here; edit the .tres (and SYS-001 first).

## SYS-001 §1.3 fire rate (shots/s)
@export var fire_rate_per_s: float = 0.0
## SYS-001 §1.3 projectile speed (px/s)
@export var projectile_speed: float = 0.0
## SYS-001 §1.3 visual length (px)
@export var visual_length_px: float = 0.0
## SYS-001 §1.3 hits per projectile
@export var hits_per_projectile: int = 1
## Damage per lance hit ✱ (derived: 0.9 s to shatter a small geode = 5 hits at 6/s)
@export var damage: int = 1
## Projectile lifetime (s) ✱ (Q-T17 Cabinet value); range = lifetime x speed
@export var lifetime_s: float = 0.0
## Spawn distance ahead of the Vigil centre (px) ✱ engineering-only (the nose of the placeholder)
@export var muzzle_offset_px: float = 0.0


func tunable_properties() -> PackedStringArray:
	return PackedStringArray(["fire_rate_per_s", "projectile_speed", "visual_length_px",
		"hits_per_projectile", "damage", "lifetime_s", "muzzle_offset_px"])


## Seconds between shots.
func fire_interval_s() -> float:
	return 1.0 / fire_rate_per_s if fire_rate_per_s > 0.0 else INF


## Derived range in px ✱ (lifetime x speed).
func range_px() -> float:
	return lifetime_s * projectile_speed
