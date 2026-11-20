class_name BezelPrint
extends Control
## One printed bezel column (CabinetBezel.SIDE × 360, flush against the screen hole) drawn from its BezelPiece list (BezelArt).
## The two columns are the side-panel halves of ONE printed sheet (with BezelField round the opening): the art
## bleeds off the column's outer, top and bottom edges (the control clips to its SIDE × 360 box), and
## the inner 2 px is the key-black lip against the opening. The art is drawn once and redrawn only when
## the crack or the inks change: there is no per-frame redraw. The costume's peel slides the whole column
## sideways by its position (left slides left, right slides right), it never redraws. A Control drawn
## behind its parent (the HUD / attract frame), so the lit readouts the parent draws sit on top of the print.
## Screened tones are polygons whose alpha is the tone (bezel_print.gdshader turns them into round dots on
## each ink's own rotated grid); all lettering is VectorText (BezelText), never PixelText.

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

var _surface: CabinetSurface
var _mat: ShaderMaterial
var _hardware: Array[Control] = []
var _pieces: Array[BezelPiece] = []
var _text_cache: Dictionary = {}


func _ready() -> void:
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	show_behind_parent = true
	clip_contents = true
	size = Vector2(CabinetBezel.SIDE, 360.0)
	_surface = CabinetSurface.default() as CabinetSurface
	_mat = CabinetLighting.print_material(_surface, Vector2.ZERO, false)
	material = _mat
	pieces_rebuild()
	_build_hardware()
	_apply_peel()


## The perforated speaker grilles at the top and bottom of the column (and under the coin door on the
## right) and, on the right, the die-cut vinyl sticker: real parts over the print, not printed art.
func _build_hardware() -> void:
	var x0 := 0.0 if column == &"left" else 2.0
	var vents: Array[Rect2] = [Rect2(x0, 0, CabinetBezel.SIDE - 2.0, 10), Rect2(x0, 350, CabinetBezel.SIDE - 2.0, 10)]
	if column == &"right":
		vents.append(CabinetBezel.APRON_VENT_LOCAL)
		_hardware.append(BezelSticker.make(CabinetBezel.RIGHT_STICKER))
	for r in vents:
		_hardware.append(BezelVent.make(r))
	for h in _hardware:
		add_child(h)


func pieces() -> Array[BezelPiece]:
	return _pieces


func pieces_rebuild() -> void:
	_pieces = BezelArt.build_left() if column == &"left" else BezelArt.build_right()
	_text_cache.clear()
	queue_redraw()


func _apply_peel() -> void:
	position.x = _base_x() + (-1.0 if column == &"left" else 1.0) * peel * PEEL_TRAVEL
	visible = peel < 1.0
	if _mat != null:
		_mat.set_shader_parameter(&"origin", position)
	for h in _hardware:
		if h is BezelVent:
			(h as BezelVent).refresh()


func _base_x() -> float:
	return CabinetBezel.left_x() if column == &"left" else CabinetBezel.right_x()


func _draw() -> void:
	for p in _pieces:
		_draw_piece(p)
	if crack > 0.0:
		_draw_crack()


## The colour plates were never printed in perfect register: each ink is nudged by its own small offset
## (the key-black plate is the reference). Deterministic, from the ink's name.
func plate_offset(ink: StringName) -> Vector2:
	if ink == &"key_black" or _surface == null:
		return Vector2.ZERO
	var h := BezelArt.hash_int(String(ink).hash())
	return Vector2(float(h % 2001) / 1000.0 - 1.0, float((h / 2001) % 2001) / 1000.0 - 1.0) * _surface.print_misregister


func _draw_piece(p: BezelPiece) -> void:
	var col := inks.ink(p.ink)
	draw_set_transform(plate_offset(p.ink))
	_draw_piece_shape(p, col)
	draw_set_transform(Vector2.ZERO)


func _draw_piece_shape(p: BezelPiece, col: Color) -> void:
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
			_draw_tone(p, col)
		BezelPiece.Kind.PIXELS:
			for d in p.points:
				draw_rect(Rect2(d, Vector2(p.width, p.width)), col)
		BezelPiece.Kind.TEXT:
			BezelText.draw(self, _text_cache, BezelArt.text_of(p, tr(p.text_key)), p.points[0], p.centered, p.width, p.stroke_w, p.tracking, col, p.rot)


## A screened tone: the polygon carries its tone per vertex in the alpha; bezel_print.gdshader turns it
## into round dots with dot gain.
func _draw_tone(p: BezelPiece, col: Color) -> void:
	if p.tone_mode == BezelPiece.TONE_RADIAL and p.tone_b.x <= 0.0:
		# a glow round a centre: a triangle fan, so the tone is graded all the way in
		var c := Color(col.r, col.g, col.b, clampf(p.tone_at(p.tone_a), 0.0, 0.998))
		for i in p.points.size():
			var q0 := p.points[i]
			var q1 := p.points[(i + 1) % p.points.size()]
			draw_primitive(PackedVector2Array([p.tone_a, q0, q1]), PackedColorArray([c,
				Color(col.r, col.g, col.b, clampf(p.tone_at(q0), 0.0, 0.998)),
				Color(col.r, col.g, col.b, clampf(p.tone_at(q1), 0.0, 0.998))]), PackedVector2Array())
		return
	var cols := PackedColorArray()
	for q in p.points:
		cols.append(Color(col.r, col.g, col.b, clampf(p.tone_at(q), 0.0, 0.998)))
	draw_polygon(p.points, cols)


## Lines aimed at pixel centres so 1 px strokes land on whole pixels.
static func _half_px(pts: PackedVector2Array) -> PackedVector2Array:
	var out := PackedVector2Array()
	for q in pts:
		out.append(q + Vector2(0.5, 0.5))
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
