class_name BezelVent
extends ColorRect
## A perforated black-painted metal speaker / vent grille on the bezel (replaces the cartoon white vent
## plates): shaders/cabinet/bezel_vent.gdshader draws the staggered holes, lit by the cabinet light, with
## dust on the hole rims. Child of a BezelPrint column, so it slides away with it. `rect` is column-local.

const SHADER := preload("res://shaders/cabinet/bezel_vent.gdshader")

@export var surface: CabinetSurface

var _mat: ShaderMaterial


## A vent over `rect` (column-local).
static func make(rect: Rect2) -> BezelVent:
	var v := BezelVent.new()
	v.position = rect.position
	v.size = rect.size
	return v


func _ready() -> void:
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	color = Color.WHITE
	if surface == null:
		surface = CabinetSurface.default() as CabinetSurface
	_mat = ShaderMaterial.new()
	_mat.shader = SHADER
	material = _mat
	refresh()


## Push the material and the vent's rig position (call again after the column moves).
func refresh() -> void:
	if _mat == null:
		return
	var parent := get_parent() as Control
	var origin := position + (parent.position if parent != null else Vector2.ZERO)
	CabinetLighting.apply(_mat, surface)
	_mat.set_shader_parameter(&"vent_size", size)
	_mat.set_shader_parameter(&"rig_origin", origin)
	_mat.set_shader_parameter(&"paint_color", surface.paint_color)
	_mat.set_shader_parameter(&"bare_steel_color", surface.bare_steel_color)
	_mat.set_shader_parameter(&"vent_dust", surface.vent_dust)
	_mat.set_shader_parameter(&"wear", surface.wear)
