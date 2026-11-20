class_name RaceEdgeMarkerStats
extends TunableResource
## Race edge markers (RaceEdgeMarkers; TECH-001 §5.4; Q-T357). Values in data/hud/race_edge_markers.tres
## (`ds_hud.race_marks.*`). All ✱ engineering layout (logical px in the 640×360 frame), not game numbers.

## ✱ distance from the left and right frame edges to the marker band.
@export var inset_side_px: float = 0.0
## ✱ distance from the top edge: clears the top-left and top-right plates (22 px + 4 px margin).
@export var inset_top_px: float = 0.0
## ✱ distance from the bottom edge: clears the Charge strip, Seam plate and wick.
@export var inset_bottom_px: float = 0.0
## ✱ chevron half length for a Charge or a Grub; the Sepulchre's is `sepulchre_size_px`.
@export var size_px: float = 0.0
@export var sepulchre_size_px: float = 0.0
## ✱ most markers drawn at once (Charges first, then the Sepulchre, then Grubs; nearest first).
@export var max_markers: int = 0


func tunable_properties() -> PackedStringArray:
	return PackedStringArray(["inset_side_px", "inset_top_px", "inset_bottom_px", "size_px",
		"sepulchre_size_px", "max_markers"])
