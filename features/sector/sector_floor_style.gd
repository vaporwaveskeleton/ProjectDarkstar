class_name SectorFloorStyle
extends Resource
## Look of the M1 sandbox floor (Q-T58: no clear colour anywhere). Engineering/visual values (✱),
## not game tunables. The pattern period (cell_px × major_every) must divide the torus size on both
## axes so the floor is seamless across the wrap (tested).

## ✱ Grid cell size (px). 80 divides 1920 and 720.
@export var cell_px: float = 0.0
## ✱ Every Nth line is a major line. 3 × 80 = 240 divides 1920 and 720.
@export var major_every: int = 1
@export var base_colour: Color = Pal.VOID_1
@export var minor_colour: Color = Pal.VOID_2
@export var major_colour: Color = Pal.VOID_3
## ✱ Line width (px).
@export var line_px: float = 1.0


## The distance after which the pattern repeats.
func period_px() -> float:
	return cell_px * float(maxi(1, major_every))


## True when the pattern tiles a field of `size` with no visible seam.
func tiles(size: Vector2) -> bool:
	var p := period_px()
	if p <= 0.0:
		return false
	return is_zero_approx(fposmod(size.x, p)) and is_zero_approx(fposmod(size.y, p))
