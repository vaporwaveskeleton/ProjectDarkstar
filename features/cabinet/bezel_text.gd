class_name BezelText
extends RefCounted
## Every string printed on the Cabinet's bezel (how-to card, sticker, marquee, price plate, coin hint) is
## drawn here with VectorText (PR #32), never PixelText: PixelText stays inside the arcade screen. The
## strokes are tessellated into one mesh and drawn through the host CanvasItem's own material, so the
## print material (fade, ink mottle, wear, the cabinet light) treats the lettering as printed ink.
## Cap heights and strokes are ✱ presentation data (CabinetSurface / the BezelPiece), not game numbers.
## The caller owns the mesh cache (a plain Dictionary), so nothing static outlives the scene.


## A face of cap height `cap` and stroke `stroke` (logical px).
static func face(cap: float, stroke: float, tracking: float) -> VectorFace:
	var f := VectorText.default_face().duplicate_with(cap, stroke)
	f.tracking = tracking
	return f


## Ink size of `text` (strokes' centre lines; add `stroke` for the painted extent).
static func measure(text: String, cap: float, stroke: float, tracking: float = 0.0) -> Vector2:
	return VectorText.measure(text, VectorText.default_glyphs(), face(cap, stroke, tracking))


## Painted size including the stroke's round caps.
static func painted_size(text: String, cap: float, stroke: float, tracking: float = 0.0) -> Vector2:
	return measure(text, cap, stroke, tracking) + Vector2(stroke, stroke)


## Draws `text` with its cap-top at `at.y`; `at.x` is the left edge, or the centre if `centered`.
## `rot` turns it about `at`. `cache` is the caller's Dictionary of built meshes.
static func draw(ci: CanvasItem, cache: Dictionary, text: String, at: Vector2, centered: bool, cap: float,
		stroke: float, tracking: float, color: Color, rot: float = 0.0, max_w: float = 0.0) -> void:
	if text == "":
		return
	var w := VectorText.effective_stroke_width(stroke, _screen_scale(ci))
	var key := "%s|%.3f|%.3f|%.3f|%.3f|%.1f" % [text, cap, stroke, tracking, snappedf(w, 0.01), max_w]
	var entry: Array = cache.get(key, [])
	if entry.is_empty():
		var lay := VectorText.layout(text, VectorText.default_glyphs(), face(cap, w, tracking), VectorText.Align.LEFT, max_w)
		entry = [VectorText.build_mesh(lay, w), lay.size]
		cache[key] = entry
	var mesh := entry[0] as ArrayMesh
	if mesh == null:
		return
	var size := entry[1] as Vector2
	var x := at.x - (size.x * 0.5 if centered else 0.0)
	var xf := Transform2D(rot, at) * Transform2D(0.0, Vector2(x - at.x, 0.0))
	ci.draw_mesh(mesh, null, xf, color)


## Logical px to physical px at the host item (1 when not in a tree).
static func _screen_scale(ci: CanvasItem) -> float:
	if not ci.is_inside_tree():
		return 1.0
	var s: Vector2 = (ci.get_viewport().get_final_transform() * ci.get_global_transform_with_canvas()).get_scale()
	return minf(s.x, s.y)


## How many lines `text` takes when wrapped at `max_w`.
static func line_count(text: String, cap: float, stroke: float, tracking: float, max_w: float) -> int:
	return VectorText.layout(text, VectorText.default_glyphs(), face(cap, stroke, tracking), VectorText.Align.LEFT, max_w).line_count()


## The ink box of capital-only lettering: its width plus the stroke, and cap height plus the stroke (the
## layout's own height also reserves room for descenders, which the bezel's capitals never use).
static func ink_size(text: String, cap: float, stroke: float, tracking: float = 0.0) -> Vector2:
	return Vector2(measure(text, cap, stroke, tracking).x + stroke, cap + stroke)
