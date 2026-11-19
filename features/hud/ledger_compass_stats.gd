class_name LedgerCompassStats
extends TunableResource
## Ledger Compass limits and look (TECH-001 §5.4). Values in data/hud/ledger_compass.tres.

## ✱ TECH-001 §5.4 "up to 8 markers".
@export var max_markers: int = 0
## ✱ TECH-001 §5.4 "at most 10 Hz": the static layer redraws at most this often, and only when
## invalidated (macro map, size or sector list changed). Markers redraw every frame.
@export var redraw_hz: float = 0.0
## ART-001 §12.5 "Ledger Compass frame 64 × 64 (one module)" (Q-T120).
@export var size_px: Vector2 = Vector2.ZERO
## ✱ Brass bezel width, one 4 px sub-grid step (ART-001 §12.5 sub-grid).
@export var bezel_px: float = 0.0
## ✱ One map grid cell per this many world px (one 640 × 360 screen per cell).
@export var grid_world_px: Vector2 = Vector2.ZERO
## ✱ Marker dot radius in widget px.
@export var marker_radius_px: float = 0.0


func tunable_properties() -> PackedStringArray:
	return PackedStringArray(["max_markers", "redraw_hz", "size_px", "bezel_px", "grid_world_px",
		"marker_radius_px"])
