class_name LedgerCompassLayout
extends RefCounted
## Where each part of the Ledger Compass sits inside its module (ART-001 §12.5: 64 × 64, built on
## the 4 px sub-grid). Pure geometry derived from the widget size, the bezel width and the map's
## aspect; no tunables of its own (those are in LedgerCompassStats).

const SUBGRID := 4.0   ## ART-001 §12.5 UI sub-grid
const LIST_CELL := Vector2(16, 8)
const ENTITY_FRAME := Vector2(16, 16)

var size: Vector2
var face: Rect2
## The sector cell: the whole wrapping map, scaled to the face width, aspect from the world rect.
var map: Rect2
var entity_frame: Rect2
var _list_origin: Vector2


static func make(widget_size: Vector2, bezel_px: float, world_size: Vector2) -> LedgerCompassLayout:
	var l := LedgerCompassLayout.new()
	l.size = widget_size
	l.face = Rect2(Vector2(bezel_px, bezel_px), widget_size - Vector2(bezel_px, bezel_px) * 2.0)
	var inset := bezel_px + SUBGRID
	var map_w := widget_size.x - inset * 2.0
	var aspect := world_size.y / world_size.x if world_size.x > 0.0 else 0.5
	var map_h := maxf(SUBGRID, snappedf(map_w * aspect, SUBGRID))
	map_h = minf(map_h, widget_size.y - inset * 2.0 - ENTITY_FRAME.y - SUBGRID * 2.0)
	l.map = Rect2(Vector2(inset, inset), Vector2(map_w, map_h))
	var below := l.map.end.y + SUBGRID * 2.0
	l._list_origin = Vector2(inset, below)
	l.entity_frame = Rect2(Vector2(widget_size.x - inset - ENTITY_FRAME.x, below), ENTITY_FRAME)
	return l


## Rect of sector-list cell `i` (one row, left to right).
func list_cell(i: int) -> Rect2:
	return Rect2(_list_origin + Vector2(i * (LIST_CELL.x + SUBGRID), 0), LIST_CELL)


## Widget-local point of a world position, inside the map rect (clamped to it).
func to_widget(world: Vector2, world_area: Rect2) -> Vector2:
	return map.position + LedgerCompass.map_point(world, world_area, map.size)


## Interior grid-line positions as fractions of `extent` (one line per `cell` world px).
static func grid_lines(extent: float, cell: float) -> PackedFloat32Array:
	var out := PackedFloat32Array()
	if cell <= 0.0 or extent <= 0.0:
		return out
	var x := cell
	while x < extent - 0.5:
		out.append(x / extent)
		x += cell
	return out
