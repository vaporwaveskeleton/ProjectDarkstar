class_name CockpitFlameStats
extends TunableResource
## Cockpit flame drawing (WARP-001 §4.1 cockpit-flame row, §4.2 L10). All ✱ engineering values
## (TECH-001 §3.4). Values in data/composure/cockpit_flame.tres (`ds_composure.flame.*`).
## Pixels are in the Vigil's Facing/Visual space (+x = the nose).

## ✱ where the flame's root sits (behind the cockpit core).
@export var base_x_px: float = 0.0
## ✱ half width of the flame at its root.
@export var half_width_px: float = 0.0
## ✱ flame length per band shape: steady (Clear), flickering (Frayed), guttering (Unmoored),
## hollow (Hollowed).
@export var steady_length_px: float = 0.0
@export var flicker_length_px: float = 0.0
@export var gutter_length_px: float = 0.0
@export var hollow_length_px: float = 0.0
## ✱ flickering: two tongues; each tongue's length swings by flicker_swing_px at flicker_hz.
@export var flicker_hz: float = 0.0
@export var flicker_swing_px: float = 0.0
## ✱ guttering: a low wide flame that sinks by gutter_swing_px at gutter_hz.
@export var gutter_hz: float = 0.0
@export var gutter_swing_px: float = 0.0
## ✱ ART-001 §12.9: no element changes more than 3 times a second; shape motion is capped here.
@export var max_motion_hz: float = 0.0


func tunable_properties() -> PackedStringArray:
	return PackedStringArray([
		"base_x_px", "half_width_px", "steady_length_px", "flicker_length_px", "gutter_length_px",
		"hollow_length_px", "flicker_hz", "flicker_swing_px", "gutter_hz", "gutter_swing_px",
		"max_motion_hz"])
