class_name BezelGlass
extends Control
## The glass over the whole printed bezel (owner direction 2026-11-18: reverse-printed glass with sheen,
## dust, fingerprints and fine scratches). It draws only the rectangles of BezelField.glass_rects, the
## field and the two columns around the screen hole, so it can never cover the screen, and the coin door
## is cut out of it. Drawn after (above) the print. It follows the costume's peel and the window's area;
## the shader is static, so it redraws only when those change.

const SHADER := preload("res://shaders/cabinet/bezel_glass.gdshader")

@export var rig: ScreenRig
@export var surface: CabinetSurface

## 0 to 1: the glass slides away with the costume.
var peel := 0.0:
	set(v):
		peel = v
		visible = peel < 1.0
		_push_door()
		queue_redraw()

var _area := Rect2()
var _mat: ShaderMaterial


func _ready() -> void:
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	if surface == null:
		surface = CabinetSurface.default() as CabinetSurface
	_mat = ShaderMaterial.new()
	_mat.shader = SHADER
	material = _mat
	CabinetLighting.apply(_mat, surface)
	_mat.set_shader_parameter(&"edge_color", surface.glass_edge_color)
	_mat.set_shader_parameter(&"reflection", surface.glass_reflection)
	_mat.set_shader_parameter(&"band_gain", surface.glass_band)
	_mat.set_shader_parameter(&"screen_reflection", surface.glass_screen_reflection)
	_mat.set_shader_parameter(&"edge_tint", surface.glass_edge_tint)
	_mat.set_shader_parameter(&"dust", surface.glass_dust)
	_mat.set_shader_parameter(&"smudges", surface.glass_smudge)
	_mat.set_shader_parameter(&"scratch", surface.glass_scratch)
	if rig != null:
		rig.refitted.connect(set_area)
		set_area(rig.bezel_rect())
	_push_door()


## The bezel's drawable area in rig units (ScreenRig.bezel_rect()).
func set_area(r: Rect2) -> void:
	_area = r
	if _mat != null:
		_mat.set_shader_parameter(&"area", Vector4(r.position.x, r.position.y, r.size.x, r.size.y))
	queue_redraw()


## The rectangles the glass paints at the current peel.
func rects() -> Array[Rect2]:
	return BezelField.glass_rects(_area, peel)


func _push_door() -> void:
	if _mat == null:
		return
	var d := CabinetBezel.coin_plate()
	d.position.x += peel * (CabinetBezel.SIDE + 20.0)
	_mat.set_shader_parameter(&"door_rect", Vector4(d.position.x, d.position.y, d.size.x, d.size.y))


func _draw() -> void:
	for r in rects():
		draw_rect(r, Color.WHITE)
