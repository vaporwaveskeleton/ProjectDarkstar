class_name CoinDoorFace
extends ColorRect
## The coin door's physical face: a stamped-steel early-1980s US coin door drawn by
## shaders/cabinet/coin_door.gdshader (SDFs, resolution independent, owner direction 2026-11-18): satin
## black paint, dull zinc plating, one polished lip, the lit reject / price plate, a coin-return pocket
## with a hinged flap, causal wear. Covers exactly CabinetBezel.coin_plate() (or the rect given to
## `fit_to`) and carries a soft contact shadow child (contact_shadow.gdshader) so it sits IN the cabinet.
## Materials and wear come from CabinetSurface; `glow` 0 to 1 is the lamp behind the lit plate. Draws
## behind its parent, so the parent's own drawing (price text, coin, tape, focus ring) sits on top.

const SHADER := preload("res://shaders/cabinet/coin_door.gdshader")
const SHADOW_SHADER := preload("res://shaders/cabinet/contact_shadow.gdshader")
const SHADOW_MARGIN := 9.0

@export var surface: CabinetSurface

## Lamp behind the lit plate, 0 (idle glow) to 1 (lit).
var glow := 0.0:
	set(v):
		glow = clampf(v, 0.0, 1.0)
		if _mat != null:
			_mat.set_shader_parameter(&"glow", glow)

var _mat: ShaderMaterial
var _shadow: ColorRect
var _shadow_mat: ShaderMaterial


func _ready() -> void:
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	show_behind_parent = true
	color = Color.WHITE
	if surface == null:
		surface = CabinetSurface.default() as CabinetSurface
	_mat = ShaderMaterial.new()
	_mat.shader = SHADER
	material = _mat
	_shadow = ColorRect.new()
	_shadow.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_shadow.show_behind_parent = true
	_shadow.color = Color.WHITE
	_shadow_mat = ShaderMaterial.new()
	_shadow_mat.shader = SHADOW_SHADER
	_shadow.material = _shadow_mat
	add_child(_shadow)
	var plate := CabinetBezel.coin_plate()
	if size == Vector2.ZERO:
		size = plate.size
	apply_surface()
	_mat.set_shader_parameter(&"glow", glow)
	_layout_shadow()


## Place the face over `plate` (rig units, relative to the parent) and tell the shader its size.
func fit_to(plate: Rect2) -> void:
	position = plate.position
	size = plate.size
	if _mat != null:
		_mat.set_shader_parameter(&"plate_size", plate.size)
		_mat.set_shader_parameter(&"rig_origin", rig_origin())
		_layout_shadow()


## The door's top-left in rig units: its own position plus its parent's (the Hud sits at 0, the CoinSlot on the plate).
func rig_origin() -> Vector2:
	var parent := get_parent() as Control
	return position + (parent.position if parent != null else Vector2.ZERO)


## Push the surface resource and the plate's feature layout into the material.
func apply_surface() -> void:
	if _mat == null or surface == null:
		return
	CabinetLighting.apply(_mat, surface)
	_mat.set_shader_parameter(&"plate_size", size)
	_mat.set_shader_parameter(&"rig_origin", rig_origin())
	_mat.set_shader_parameter(&"paint_color", surface.paint_color)
	_mat.set_shader_parameter(&"zinc_color", surface.zinc_color)
	_mat.set_shader_parameter(&"lip_color", surface.lip_color)
	_mat.set_shader_parameter(&"bare_steel_color", surface.bare_steel_color)
	_mat.set_shader_parameter(&"brass_color", surface.brass_color)
	_mat.set_shader_parameter(&"lens_color", surface.lens_color)
	_mat.set_shader_parameter(&"sticker_color", surface.sticker_paper_color)
	_mat.set_shader_parameter(&"wear", surface.wear)
	_mat.set_shader_parameter(&"grime", surface.grime)
	_mat.set_shader_parameter(&"smudge", surface.smudge)
	_mat.set_shader_parameter(&"dust", surface.dust)
	_mat.set_shader_parameter(&"finger_halo", surface.finger_halo)
	_mat.set_shader_parameter(&"thumb_wear", surface.thumb_wear)
	_mat.set_shader_parameter(&"micro_texture", surface.micro_texture)
	_mat.set_shader_parameter(&"lamp_idle", surface.lamp_idle)
	_mat.set_shader_parameter(&"lamp_spill", surface.lamp_spill)
	_mat.set_shader_parameter(&"lamp_spill_radius", surface.lamp_spill_radius)
	_mat.set_shader_parameter(&"slot_c", CabinetBezel.SLOT_C)
	_mat.set_shader_parameter(&"slot_half", CabinetBezel.SLOT_HALF)
	_mat.set_shader_parameter(&"plate_c", CabinetBezel.button_center())
	_mat.set_shader_parameter(&"plate_half", CabinetBezel.button_half())
	if _shadow_mat != null:
		CabinetLighting.apply(_shadow_mat, surface)
		_shadow_mat.set_shader_parameter(&"margin", SHADOW_MARGIN)
		_shadow_mat.set_shader_parameter(&"strength", surface.contact_shadow)
		_shadow_mat.set_shader_parameter(&"blur", surface.contact_blur)
		_layout_shadow()


func _layout_shadow() -> void:
	if _shadow == null:
		return
	_shadow.position = Vector2(-SHADOW_MARGIN, -SHADOW_MARGIN)
	_shadow.size = size + Vector2(SHADOW_MARGIN, SHADOW_MARGIN) * 2.0
	_shadow_mat.set_shader_parameter(&"part_size", size)
	_shadow_mat.set_shader_parameter(&"rig_origin", rig_origin())


## The material, for tests and captures.
func door_material() -> ShaderMaterial:
	return _mat


## The contact shadow's rect child, for tests.
func contact_shadow() -> ColorRect:
	return _shadow
