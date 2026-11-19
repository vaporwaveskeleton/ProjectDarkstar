class_name BezelFrame
extends ColorRect
## The printed border round the rounded-corner screen opening, plus the recess wall's shadow
## (shaders/cabinet/bezel_frame.gdshader). Part of the one printed sheet, so it sits under the glass. It
## paints nothing inside the opening's rectangle: the screen is never touched. Rect = the opening grown by
## REACH rig units.

const SHADER := preload("res://shaders/cabinet/bezel_frame.gdshader")
const REACH := 14.0

@export var surface: CabinetSurface

var _mat: ShaderMaterial


func _ready() -> void:
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	color = Color.WHITE
	if surface == null:
		surface = CabinetSurface.default() as CabinetSurface
	var r := rect()
	position = r.position
	size = r.size
	_mat = ShaderMaterial.new()
	_mat.shader = SHADER
	material = _mat
	CabinetLighting.apply(_mat, surface)
	var inks := BezelInks.default() as BezelInks
	_mat.set_shader_parameter(&"corner_r", surface.tube_corner_radius)
	_mat.set_shader_parameter(&"rect_size", r.size)
	_mat.set_shader_parameter(&"rig_origin", r.position)
	_mat.set_shader_parameter(&"recess_shadow", surface.recess_shadow)
	_mat.set_shader_parameter(&"recess_width", surface.recess_width)
	_mat.set_shader_parameter(&"key_black", Vector3(inks.key_black.r, inks.key_black.g, inks.key_black.b))
	_mat.set_shader_parameter(&"cream", Vector3(inks.cream.r, inks.cream.g, inks.cream.b))


## The control's rect in rig units: the opening grown by REACH.
static func rect() -> Rect2:
	return CabinetBezel.hole().grow(REACH)
