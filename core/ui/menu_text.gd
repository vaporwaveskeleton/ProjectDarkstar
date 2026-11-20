class_name MenuText
extends VectorLabel
## Menu text (TECH-001 §2.9a/§2.9b), by role (MenuSkin.Role) and Large Text (SettingsService
## text_scale, live). The costume picks the face:
##   CABINET  the cabinet's own 5 × 7 pixel font (PixelText), upper case, at an integer scale, each
##            pixel snapped to the logical grid (the Act 0 screen's pixel grid at 1080p) and drawn with
##            the CRT's scanline treatment, so the service screen reads like the tube it stands for.
##   BRASS    VectorLabel stroke text; the TITLE role is engraved capitals (a cut shadow and a lit lip).
## Set `key` (a tr() key) as usual.

@export var role: MenuSkin.Role = MenuSkin.Role.ROW:
	set(v):
		role = v
		if is_inside_tree():
			restyle()
## Keep the colour the owner sets instead of the role's ink.
@export var custom_color := false

var kind: MenuSkin.Kind = MenuSkin.Kind.CABINET


func _ready() -> void:
	super()
	kind = MenuSkin.for_node(self)
	restyle()
	if not SettingsService.setting_changed.is_connected(_on_setting_changed):
		SettingsService.setting_changed.connect(_on_setting_changed)


## The text as the costume prints it (cabinet upper case; brass titles are capitals).
func shown_text() -> String:
	var s := text if text != "" else (tr(key) if key != &"" else "")
	return MenuSkin.shown_role(s, kind, role)


## Characters this text cannot draw in its costume's face (tests: always empty).
func missing_glyphs() -> PackedStringArray:
	if _pixel():
		return PixelText.missing(shown_text())
	return get_layout().missing


func restyle() -> void:
	face = MenuSkin.face(role, -1.0, kind)
	if not custom_color:
		color = MenuSkin.ink(kind, role)
	update_minimum_size()
	queue_redraw()


func _on_setting_changed(k: StringName, _v: Variant) -> void:
	if k == &"text_scale":
		restyle()


func _pixel() -> bool:
	return kind == MenuSkin.Kind.CABINET


# ---------------------------------------------------------------- pixel face (cabinet)

func pixel_lines() -> PackedStringArray:
	var s := shown_text()
	var limit := _wrap_width()
	if limit > 0.0:
		return PixelText.wrap(s, MenuSkin.pixel_scale(role), limit)
	return PackedStringArray([s])


func _get_minimum_size() -> Vector2:
	if not _pixel():
		return super()
	var ps := MenuSkin.pixel_scale(role)
	var lines := pixel_lines()
	var w := 0
	for l in lines:
		w = maxi(w, PixelText.width(l, ps))
	var h := lines.size() * PixelText.H * ps + (lines.size() - 1) * MenuSkin.PIXEL_LINE_GAP * ps
	return Vector2(0.0 if (wrap or max_width > 0.0) else float(w), float(h))


func _draw() -> void:
	if not _pixel():
		if role == MenuSkin.Role.TITLE:
			# engraved capitals: the cut's shadow, a lit lip, then the face
			_draw_mesh_at(Vector2(0.8, 0.9), Color(Pal.VOID_0, 0.9))
			_draw_mesh_at(Vector2(-0.4, -0.5), Color(Pal.BONE_5, 0.35))
		_draw_mesh_at(Vector2.ZERO, color)
		return
	var ps := MenuSkin.pixel_scale(role)
	# snap to the logical pixel grid wherever the containers put us
	var g := get_global_transform_with_canvas().origin
	var snap := g.round() - g
	var y := 0.0
	for l in pixel_lines():
		var w := float(PixelText.width(l, ps))
		var x := 0.0
		if alignment == VectorText.Align.CENTER:
			x = roundf((size.x - w) * 0.5)
		elif alignment == VectorText.Align.RIGHT:
			x = roundf(size.x - w)
		PixelText.draw_crt(self, Vector2(x, y) + snap, l, color, ps)
		y += float((PixelText.H + MenuSkin.PIXEL_LINE_GAP) * ps)


func _draw_mesh_at(off: Vector2, col: Color) -> void:
	_ensure()
	var f: VectorFace = _face()
	var w: float = VectorText.effective_stroke_width(f.stroke_width, _screen_scale())
	if absf(w - _mesh_width) > 0.001:
		_mesh_width = w
		_mesh = VectorText.build_mesh(_layout, w)
	if _mesh == null:
		return
	var factor := 0.0
	if alignment == VectorText.Align.CENTER:
		factor = 0.5
	elif alignment == VectorText.Align.RIGHT:
		factor = 1.0
	var dx: float = f.stroke_width * 0.5 + maxf(size.x - f.stroke_width - _layout.box_width, 0.0) * factor
	draw_mesh(_mesh, null, Transform2D(0.0, Vector2(dx, f.stroke_width * 0.5) + off), col)
