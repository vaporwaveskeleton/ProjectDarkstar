class_name ComposureWickStats
extends TunableResource
## Composure wick (ART-001 §12.5 `ds_ui_wick_composure`, 64 × 16; WARP-001 §4.1 bottom-right).
## Q-T119: the flame height steps by BAND only, four heights, no readable number. All heights ✱.
## Values in data/hud/composure_wick.tres (`ds_hud.wick.*`).

## ✱ flame height in px per band (Clear, Frayed, Unmoored, Hollowed). Hollowed is drawn hollow.
@export var clear_height_px: float = 0.0
@export var frayed_height_px: float = 0.0
@export var unmoored_height_px: float = 0.0
@export var hollowed_height_px: float = 0.0
## ✱ half width of the flame at its widest.
@export var flame_half_width_px: float = 0.0


func height_for(b: Composure.Band) -> float:
	match b:
		Composure.Band.FRAYED:
			return frayed_height_px
		Composure.Band.UNMOORED:
			return unmoored_height_px
		Composure.Band.HOLLOWED:
			return hollowed_height_px
	return clear_height_px


func tunable_properties() -> PackedStringArray:
	return PackedStringArray([
		"clear_height_px", "frayed_height_px", "unmoored_height_px", "hollowed_height_px",
		"flame_half_width_px"])
