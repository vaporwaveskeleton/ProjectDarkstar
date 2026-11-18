class_name VigilMoveStats
extends TunableResource
## Vigil movement tunables. Values are copied from SYS-001 §1.1 / §9 into data/vigil/vigil_move.tres.
## Never edit numbers here; edit the .tres (and SYS-001 first).

## SYS-001 §1.1 max_speed (px/s) 🔒
@export var max_speed: float = 0.0
## SYS-001 §1.1 accel (px/s²) 🔒
@export var accel: float = 0.0
## SYS-001 §1.1 drag (1/s), exponential decay while coasting ⚙
@export var drag: float = 0.0
## SYS-001 §1.1 brake (px/s²) ⚙
@export var brake: float = 0.0
## SYS-001 §1.1 snap_turn (deg/s) ⚙
@export var snap_turn: float = 0.0
## SYS-001 §9 "player hitbox 12 px circle". Read as DIAMETER (TECH-001 §11 open question).
@export var hitbox_circle_px: float = 0.0


func tunable_properties() -> PackedStringArray:
	return PackedStringArray(["max_speed", "accel", "drag", "brake", "snap_turn", "hitbox_circle_px"])
