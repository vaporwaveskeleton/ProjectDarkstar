class_name VectorLabel
extends Control
## Stroke text node (Q-T23): draws a VectorText layout as one tessellated mesh with round caps and
## joins. `key` is looked up with tr(); `text` overrides it for dynamic or already-translated text.
## Re-lays out only when text, key, face, glyphs, size, alignment, filter or the language changes.
## Colour channels stay <= 1.0 so the text never blooms; for a fade use a plain colour alpha of 1
## and modulate the whole control (overlapping tessellation would double-blend a translucent colour).

@export var key: StringName = &"":
	set(v):
		key = v
		_dirty()
@export var text: String = "":
	set(v):
		text = v
		_dirty()
@export var face: VectorFace:
	set(v):
		face = v
		_dirty()
@export var glyphs: VectorGlyphSet:
	set(v):
		glyphs = v
		_dirty()
@export var color: Color = Pal.BONE_4:
	set(v):
		color = v
		queue_redraw()
@export var alignment: VectorText.Align = VectorText.Align.LEFT:
	set(v):
		alignment = v
		_dirty()
@export var wrap: bool = false:                 ## wrap at the control width
	set(v):
		wrap = v
		_dirty()
@export var max_width: float = 0.0:             ## wrap at this logical px width instead (0 = off)
	set(v):
		max_width = v
		_dirty()

## The glyph-lie seam: (ch: String, index: int) -> String | Array[PackedVector2Array] (em) | null.
var glyph_filter: Callable = Callable():
	set(v):
		glyph_filter = v
		_dirty()

## How many times the layout has been rebuilt (tests and profiling).
var layout_count := 0

var _layout: VectorLayout
var _mesh: ArrayMesh
var _mesh_width := 0.0
var _stale := true


func _ready() -> void:
	resized.connect(_on_resized)


func _notification(what: int) -> void:
	if what == NOTIFICATION_TRANSLATION_CHANGED:
		_dirty()
	elif what == NOTIFICATION_ENTER_TREE:
		update_minimum_size()   # out-of-tree changes could not invalidate the cached minimum


## The text actually shown.
func shown_text() -> String:
	if text != "":
		return text
	return tr(key) if key != &"" else ""


## The current layout (built on demand).
func get_layout() -> VectorLayout:
	_ensure()
	return _layout


func _get_minimum_size() -> Vector2:
	_ensure()
	var pad: float = _face().stroke_width
	var w: float = 0.0 if (wrap or max_width > 0.0) else _layout.size.x + pad
	return Vector2(w, _layout.size.y + pad)


func _draw() -> void:
	_ensure()
	var f: VectorFace = _face()
	var w: float = VectorText.effective_stroke_width(f.stroke_width, _screen_scale())
	if absf(w - _mesh_width) > 0.001:
		_mesh_width = w
		_mesh = VectorText.build_mesh(_layout, w)
	if _mesh == null:
		return
	var box: float = _layout.box_width
	var factor: float = 0.0
	if alignment == VectorText.Align.CENTER:
		factor = 0.5
	elif alignment == VectorText.Align.RIGHT:
		factor = 1.0
	var avail: float = size.x - f.stroke_width
	var dx: float = f.stroke_width * 0.5 + maxf(avail - box, 0.0) * factor
	var xf := Transform2D(0.0, Vector2(dx, f.stroke_width * 0.5))
	draw_mesh(_mesh, null, xf, color)


## Logical px -> physical px scale (canvas transform and window stretch); 1 when not in a tree.
func _screen_scale() -> float:
	if not is_inside_tree():
		return 1.0
	var s: Vector2 = (get_viewport().get_final_transform() * get_global_transform_with_canvas()).get_scale()
	return minf(s.x, s.y)


func _face() -> VectorFace:
	return face if face != null else VectorText.default_face()


func _glyphs() -> VectorGlyphSet:
	return glyphs if glyphs != null else VectorText.default_glyphs()


func _wrap_width() -> float:
	if max_width > 0.0:
		return max_width
	if wrap:
		return maxf(size.x - _face().stroke_width, 1.0)
	return 0.0


func _dirty() -> void:
	_stale = true
	if is_inside_tree():
		update_minimum_size()
		queue_redraw()


func _on_resized() -> void:
	if wrap or alignment != VectorText.Align.LEFT:
		_dirty()


func _ensure() -> void:
	if not _stale and _layout != null:
		return
	_stale = false
	layout_count += 1
	var f: VectorFace = _face()
	_layout = VectorText.layout(shown_text(), _glyphs(), f, alignment, _wrap_width(), glyph_filter)
	_mesh = null
	_mesh_width = -1.0   # the mesh is tessellated in _draw, at the width for the current screen scale
