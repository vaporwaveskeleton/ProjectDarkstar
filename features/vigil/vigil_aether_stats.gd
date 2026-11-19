class_name VigilAetherStats
extends TunableResource
## Aether handling profile (GDD §4.2a, SYS-001 §1.1a). Every value is ✱ first-pass.
## Values live in data/vigil/vigil_aether_move.tres; never edit numbers here.

## `false` = sectors fly the Cabinet profile (VigilMoveStats).
@export var enabled: bool = true
## px/s
@export var max_speed: float = 0.0
## px/s²
@export var accel: float = 0.0
## 1/s, coast decay
@export var drag: float = 0.0
## px/s²
@export var brake: float = 0.0
## deg/s, keel turn rate
@export var hull_turn: float = 0.0
## Thrust factor at 90° to the keel (× accel)
@export var thrust_lateral: float = 0.0
## Thrust factor at 180° to the keel (× accel)
@export var thrust_reverse: float = 0.0
## Thrust multiplier while the lantern is down
@export var lantern_down_thrust: float = 0.0
## Drag multiplier while the lantern is down
@export var lantern_down_drag: float = 0.0
## px/s added along the surge direction
@export var surge_impulse: float = 0.0
## s the surge lasts
@export var surge_time: float = 0.0
## s per recharged charge
@export var surge_cooldown: float = 0.0
## stored charges (base 1; LANTERN-1 makes 2)
@export var surge_charges: int = 1
## s, the cooldown never goes below this (LOOP-001 §3.3)
@export var surge_cooldown_floor: float = 0.0


func tunable_properties() -> PackedStringArray:
	return PackedStringArray(["enabled", "max_speed", "accel", "drag", "brake", "hull_turn",
		"thrust_lateral", "thrust_reverse", "lantern_down_thrust", "lantern_down_drag",
		"surge_impulse", "surge_time", "surge_cooldown", "surge_charges", "surge_cooldown_floor"])
