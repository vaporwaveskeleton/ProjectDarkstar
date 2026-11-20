class_name ArcadeBackdrop
extends ColorRect
## The arcade behind the cabinet (surround pass, owner direction 2026-11-19; TECH-001 §2.10): a defocused
## late-70s / early-80s arcade floor that fills the window beyond the printed sheet on wide and ultrawide
## windows, so there are never bars and never a black void. One full-window ColorRect in rig units
## (ScreenRig.bezel_rect) with shaders/cabinet/arcade_backdrop.gdshader: blurred silhouettes of fictional
## cabinets, their marquees and screens as soft neon bokeh, tungsten ceiling lights, a carpet hint and a
## gentle film grain. It paints nothing inside the sheet's x range and is drawn behind everything (before
## CabinetRoom, which keeps the cabinet's side panel). Generated at runtime (D-13/D-14); its colours are
## CabinetSurface room values (✱), outside the Neon Cabinet palette like the rest of the cabinet. The grain
## is frozen while photosensitivity is on.

const SHADER := preload("res://shaders/cabinet/arcade_backdrop.gdshader")

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
	_mat.set_shader_parameter(&"sheet_x", CabinetBezel.sheet_x())
	_mat.set_shader_parameter(&"trim", surface.tmold_width)
	_mat.set_shader_parameter(&"room_glow", surface.room_glow)
	_mat.set_shader_parameter(&"exposure", surface.backdrop_exposure)
	_mat.set_shader_parameter(&"blur", surface.backdrop_blur)
	_mat.set_shader_parameter(&"grain", surface.backdrop_grain)
	_mat.set_shader_parameter(&"grain_fps", grain_fps())
	_mat.set_shader_parameter(&"desaturate", surface.backdrop_desaturate)
	_mat.set_shader_parameter(&"cabinet_shadow", surface.backdrop_cabinet_shadow)
	_mat.set_shader_parameter(&"haze", surface.backdrop_haze)
	_mat.set_shader_parameter(&"wall_color", _rgb(surface.backdrop_wall_color))
	_mat.set_shader_parameter(&"carpet_color", _rgb(surface.backdrop_carpet_color))
	_mat.set_shader_parameter(&"tungsten_color", _rgb(surface.backdrop_tungsten_color))
	_mat.set_shader_parameter(&"ceiling_color", _rgb(surface.backdrop_ceiling_color))
	_mat.set_shader_parameter(&"warmth", surface.backdrop_warmth)
	var neon := PackedVector3Array()
	for i in 6:
		var c := surface.backdrop_neon[i % surface.backdrop_neon.size()] if surface.backdrop_neon.size() > 0 else Color.WHITE
		neon.append(_rgb(c))
	_mat.set_shader_parameter(&"neon", neon)
	SettingsService.setting_changed.connect(_on_setting_changed)
	if rig != null:
		rig.refitted.connect(set_area)
		set_area(rig.bezel_rect())
	else:
		set_area(Rect2(Vector2.ZERO, Vector2(ScreenFit.REF)))


func _on_setting_changed(key: StringName, _v: Variant) -> void:
	if key == &"photosensitivity" and _mat != null:
		_mat.set_shader_parameter(&"grain_fps", grain_fps())


## The grain's refresh rate: the surface's value, or 0 (frozen) while photosensitivity is on.
func grain_fps() -> float:
	if bool(SettingsService.get_value(&"photosensitivity")):
		return 0.0
	return surface.backdrop_grain_fps


func set_area(area: Rect2) -> void:
	position = area.position
	size = area.size
	if _mat != null:
		_mat.set_shader_parameter(&"rect_size", area.size)
		_mat.set_shader_parameter(&"rig_origin", area.position)


## The backdrop's visible rects (left of and right of the sheet's molding) for window area `area`, rig units.
## Same as the room's: it never paints inside the sheet.
static func visible_rects(area: Rect2, trim: float) -> Array[Rect2]:
	return CabinetRoom.room_rects(area, trim)


static func _rgb(c: Color) -> Vector3:
	return Vector3(c.r, c.g, c.b)
