class_name CoinDoorFace
extends ColorRect
## The coin door's physical face: a stamped-steel early-1980s US coin door drawn by
## shaders/cabinet/coin_door.gdshader (SDFs, resolution independent, owner direction 2026-11-18).
## Covers exactly CabinetBezel.coin_plate() (or the rect given to `fit_to`). Materials and wear come
## from CabinetSurface; `glow` 0 → 1 is the lamp behind the lit price button. Draws behind its parent,
## so the parent's own drawing (price text, coin, tape, focus ring) sits on top.

const SHADER := preload("res://shaders/cabinet/coin_door.gdshader")

@export var surface: CabinetSurface

## Lamp behind the price button, 0 (idle glow) → 1 (lit).
var glow := 0.0:
	set(v):
		glow = clampf(v, 0.0, 1.0)
		if _mat != null:
			_mat.set_shader_parameter(&"glow", glow)

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
	var plate := CabinetBezel.coin_plate()
	if size == Vector2.ZERO:
		size = plate.size
	apply_surface()
	_mat.set_shader_parameter(&"glow", glow)


## Place the face over `plate` (rig units) and tell the shader its size in reference units.
func fit_to(plate: Rect2) -> void:
	position = plate.position
	size = plate.size
	if _mat != null:
		_mat.set_shader_parameter(&"plate_size", plate.size)


## Push the surface resource and the plate's feature layout into the material.
func apply_surface() -> void:
	if _mat == null or surface == null:
		return
	_mat.set_shader_parameter(&"plate_size", size)
	_mat.set_shader_parameter(&"paint_color", surface.paint_color)
	_mat.set_shader_parameter(&"chrome_color", surface.chrome_color)
	_mat.set_shader_parameter(&"bare_steel_color", surface.bare_steel_color)
	_mat.set_shader_parameter(&"brass_color", surface.brass_color)
	_mat.set_shader_parameter(&"lens_color", surface.lens_color)
	_mat.set_shader_parameter(&"rust_color", surface.rust_color)
	_mat.set_shader_parameter(&"wear", surface.wear)
	_mat.set_shader_parameter(&"grime", surface.grime)
	_mat.set_shader_parameter(&"smudge", surface.smudge)
	_mat.set_shader_parameter(&"lamp_idle", surface.lamp_idle)
	_mat.set_shader_parameter(&"noise_seed", surface.noise_seed)
	_mat.set_shader_parameter(&"light_dir", surface.light_direction)
	_mat.set_shader_parameter(&"slot_c", CabinetBezel.SLOT_C)
	_mat.set_shader_parameter(&"slot_half", CabinetBezel.SLOT_HALF)
	_mat.set_shader_parameter(&"button_c", CabinetBezel.button_center())
	_mat.set_shader_parameter(&"button_half", CabinetBezel.button_half())
	_mat.set_shader_parameter(&"label_c", CabinetBezel.label_center())
	_mat.set_shader_parameter(&"label_half", CabinetBezel.label_half())
	_mat.set_shader_parameter(&"label_color", surface.label_paper_color)


## The material, for tests and captures.
func door_material() -> ShaderMaterial:
	return _mat
