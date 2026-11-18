class_name BezelPrint
extends Control
## One printed bezel column (80 × 360, flush against the screen hole) drawn from its BezelPiece list (BezelArt). The art is drawn
## once and redrawn only when the crack or the inks change: there is no per-frame redraw. The
## costume's peel slides the whole column sideways by its position (left slides left, right slides
## right), it never redraws. A Control drawn behind its parent (the HUD / attract frame), so the
## lit readouts the parent draws sit on top of the print.

const HALFTONE_GRID := 3          ## px between halftone dots
const DOT := 1.0                  ## dot size in logical units; round dots once D-A moves to native res
const PEEL_TRAVEL := CabinetBezel.SIDE + 20.0

@export var column: StringName = &"left"

var inks: BezelInks = (BezelInks.default() as BezelInks):
	set(v):
		inks = v
		queue_redraw()

## 0 → 1: the plexi cracks (a piece-independent overlay).
var crack := 0.0:
	set(v):
		if is_equal_approx(v, crack):
			return
		crack = v
		queue_redraw()

## 0 → 1: the column slides off its side of the screen.
var peel := 0.0:
	set(v):
		peel = v
		_apply_peel()

var _pieces: Array[BezelPiece] = []
var _dots: Dictionary = {}        ## piece id -> PackedVector2Array of halftone dot origins


func _ready() -> void:
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	show_behind_parent = true
	size = Vector2(CabinetBezel.SIDE, 360.0)
	pieces_rebuild()
	_apply_peel()


func pieces() -> Array[BezelPiece]:
	return _pieces


func pieces_rebuild() -> void:
	_pieces = BezelArt.build_left() if column == &"left" else BezelArt.build_right()
	_dots.clear()
	queue_redraw()


func _apply_peel() -> void:
	position.x = _base_x() + (-1.0 if column == &"left" else 1.0) * peel * PEEL_TRAVEL
	visible = peel < 1.0


func _base_x() -> float:
	return CabinetBezel.left_x() if column == &"left" else CabinetBezel.right_x()


func _draw() -> void:
	for p in _pieces:
		_draw_piece(p)
	if crack > 0.0:
		_draw_crack()


func _draw_piece(p: BezelPiece) -> void:
	var col := inks.ink(p.ink)
	match p.kind:
		BezelPiece.Kind.FILL:
			draw_colored_polygon(p.points, col)
		BezelPiece.Kind.OUTLINE:
			var pts := _half_px(p.points)
			pts.append(pts[0])
			draw_polyline(pts, col, p.width)
		BezelPiece.Kind.STROKE:
			draw_polyline(_half_px(p.points), col, p.width)
		BezelPiece.Kind.HALFTONE:
			for d in _dots_of(p):
				draw_rect(Rect2(d, Vector2(DOT, DOT)), col)
		BezelPiece.Kind.PIXELS:
			for d in p.points:
				draw_rect(Rect2(d, Vector2(p.width, p.width)), col)
		BezelPiece.Kind.TEXT:
			var s := tr(p.text_key)
			var at := p.points[0]
			if p.centered:
				PixelText.draw_centered(self, at.x, at.y, s, col)
			else:
				PixelText.draw(self, at, s, col)


## Lines aimed at pixel centres so 1 px strokes land on whole pixels.
static func _half_px(pts: PackedVector2Array) -> PackedVector2Array:
	var out := PackedVector2Array()
	for q in pts:
		out.append(q + Vector2(0.5, 0.5))
	return out


## Halftone dots: the 3 px grid cells whose centre lies inside the piece's region (cached).
func _dots_of(p: BezelPiece) -> PackedVector2Array:
	if _dots.has(p.id):
		return _dots[p.id]
	var out := PackedVector2Array()
	var lo := Vector2(INF, INF)
	var hi := Vector2(-INF, -INF)
	for q in p.points:
		lo = lo.min(q)
		hi = hi.max(q)
	var gy0 := int(floorf(lo.y / HALFTONE_GRID))
	var gy1 := int(ceilf(hi.y / HALFTONE_GRID))
	var gx0 := int(floorf(lo.x / HALFTONE_GRID)) - 1
	var gx1 := int(ceilf(hi.x / HALFTONE_GRID))
	for gy in range(gy0, gy1 + 1):
		for gx in range(gx0, gx1 + 1):
			# alternate rows shift by one px so the dots read as a screen, not a grid
			var at := Vector2(gx * HALFTONE_GRID + (gy % 2) * 1, gy * HALFTONE_GRID)
			if Geometry2D.is_point_in_polygon(at + Vector2(0.5, 0.5), p.points):
				out.append(at)
	_dots[p.id] = out
	return out


## A crack down the plexi, as a zigzag with a dark edge so it reads over any ink.
func _draw_crack() -> void:
	var pts := PackedVector2Array()
	for k in 9:
		var y := 360.0 * k / 8.0
		pts.append(Vector2(CabinetBezel.SIDE * 0.5 + sin(k * 2.3 + (0.0 if column == &"left" else 1.7)) * 14.0 * crack, y))
	var shade := pts.duplicate()
	for i in shade.size():
		shade[i] += Vector2(1, 0)
	draw_polyline(shade, inks.key_black, 1.0)
	draw_polyline(pts, inks.chrome_light, 1.0)
