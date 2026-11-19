class_name LedgerCompassStats
extends TunableResource
## Ledger Compass engineering limits (TECH-001 §5.4, both ✱). Values in data/hud/ledger_compass.tres.

## ✱ TECH-001 §5.4 "up to 8 markers".
@export var max_markers: int = 0
## ✱ TECH-001 §5.4 "at most 10 Hz" (redraws per second).
@export var redraw_hz: float = 0.0


func tunable_properties() -> PackedStringArray:
	return PackedStringArray(["max_markers", "redraw_hz"])
