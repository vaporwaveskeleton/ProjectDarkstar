class_name SectorDepthStyle
extends Resource
## Look of the sector's near-depth layers (Q-T163 resolved 2026-11-19, ART-001 §16): the Aether is
## read through parallax motes and fog wisps between the far layer and the play layer, never a grid.
## All values are engineering/visual ✱ (drawing geometry), not game tunables. Each array holds one
## entry per layer, back to front. Colours are Pal entries (the palette test reads them).

## ✱ Parallax factor per layer: 0 = fixed to the screen, 1 = moves with the world.
@export var parallax: PackedFloat32Array = PackedFloat32Array()
## ✱ Cell size per layer (px): one mote or wisp per cell, placed by a hash of the cell.
@export var cell_px: PackedFloat32Array = PackedFloat32Array()
## ✱ Radius per layer (px). Wisp layers draw a soft stack of circles this wide.
@export var radius_px: PackedFloat32Array = PackedFloat32Array()
## ✱ Peak alpha per layer.
@export var alpha: PackedFloat32Array = PackedFloat32Array()
## ✱ True = a fog wisp (wide soft ellipse), false = a glass mote (small bright point with a halo).
@export var wisp: Array[bool] = []
## Colour per layer (Pal).
@export var colour: PackedColorArray = PackedColorArray()
## ✱ Drift speed of the whole field (px/s, screen space), the Aether's slow current.
@export var drift_px_s: Vector2 = Vector2.ZERO
## ✱ Twinkle period (s) for the motes; 0 = steady. Off under Reduced Motion.
@export var twinkle_s: float = 0.0


func layer_count() -> int:
	return mini(parallax.size(), mini(cell_px.size(), mini(radius_px.size(),
		mini(alpha.size(), mini(wisp.size(), colour.size())))))
