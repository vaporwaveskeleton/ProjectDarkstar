class_name AttractCrt
extends ColorRect
## The attract screen's CRT costume over the arcade hole: the same look as the Act 0 screen, shaded from
## the root screen texture. The hole covers only part of the window, so the shader is told where the
## hole is in screen UV (`hole_uv`), and how many scanline rows the grid has, both from the spec and
## ScreenFit. Re-fits when the window changes size.

@export var spec: CabinetScreenSpec


func _ready() -> void:
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	if spec == null:
		spec = load("res://data/cabinet/cabinet_screen.tres") as CabinetScreenSpec
	get_window().size_changed.connect(refit)
	refit()


func refit() -> void:
	var m := material as ShaderMaterial
	var win := get_window().size
	if m == null or win.x < 1 or win.y < 1:
		return
	m.set_shader_parameter(&"rows", float(spec.grid.y))
	m.set_shader_parameter(&"hole_uv", hole_uv(win, spec.grid))


## The screen's footprint as (x, y, w, h) in 0..1 window coordinates.
static func hole_uv(win: Vector2i, grid: Vector2i) -> Vector4:
	var r := ScreenFit.screen_rect_physical(win, grid)
	return Vector4(float(r.position.x) / win.x, float(r.position.y) / win.y, float(r.size.x) / win.x, float(r.size.y) / win.y)
