class_name CabinetRoom
extends ColorRect
## The room round the cabinet: everything in the window outside the printed sheet's width
## (CabinetBezel.sheet_x(), with the T-molding), dark, with a hint of the cabinet's side panel. On a 21:9
## or 16:10 window the extra width is this, never the print stretched to the window's edge. Drawn behind the
## print (it paints nothing inside the sheet's x range).

const SHADER := preload("res://shaders/cabinet/cabinet_room.gdshader")

@export var rig: ScreenRig
@export var surface: CabinetSurface

var _mat: ShaderMaterial


func _ready() -> void:
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	show_behind_parent = true
	color = Color.WHITE
	if surface == null:
		surface = CabinetSurface.default() as CabinetSurface
	_mat = ShaderMaterial.new()
	_mat.shader = SHADER
	material = _mat
	CabinetLighting.apply(_mat, surface)
	var sx := CabinetBezel.sheet_x()
	_mat.set_shader_parameter(&"sheet_x", sx)
	_mat.set_shader_parameter(&"trim", surface.tmold_width)
	if rig != null:
		rig.refitted.connect(set_area)
		set_area(rig.bezel_rect())
	else:
		set_area(Rect2(Vector2.ZERO, Vector2(ScreenFit.REF)))


func set_area(area: Rect2) -> void:
	position = area.position
	size = area.size
	if _mat != null:
		_mat.set_shader_parameter(&"rect_size", area.size)
		_mat.set_shader_parameter(&"rig_origin", area.position)


## The room's rects (left of and right of the sheet's molding) for window area `area`, rig units.
static func room_rects(area: Rect2, trim: float) -> Array[Rect2]:
	var sx := CabinetBezel.sheet_x()
	return [Rect2(area.position.x, area.position.y, maxf(sx.x - trim - area.position.x, 0.0), area.size.y),
		Rect2(sx.y + trim, area.position.y, maxf(area.end.x - sx.y - trim, 0.0), area.size.y)]
