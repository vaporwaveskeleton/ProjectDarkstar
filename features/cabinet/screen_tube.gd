class_name ScreenTube
extends ColorRect
## The tube (PR C pass 2, PM direction): a rounded-corner tube-mask opening and a VERY low-opacity glass
## layer over the arcade screen: faint convex reflection, light dust, phosphor bloom bleed at the edges and a
## soft inner shadow where the tube sits recessed (shaders/cabinet/screen_tube.gdshader). It is a separate
## overlay drawn AFTER the arcade screen (and after the CRT and register quantize, which it never sees or
## alters), so the Act 0 grid stays pixel-perfect and the register-quantized colours keep their identity.
##
## Readability: the glass is clamped to `max_alpha()`, the sum of its ✱ amounts and never above
## CabinetSurface.tube_max_shift, so by construction no screen channel moves by more than that (an alpha
## blend moves a channel by at most alpha). The only screen texels it replaces are the few corner texels
## of the rounded mask (`mask_pixels()`).
## Off switch: the glass (not the mask) is off while the `photosensitivity` setting is on (the player's
## "no glare, no flicker" promise) or `tube_glass` is 0; it follows the setting live.

const SHADER := preload("res://shaders/cabinet/screen_tube.gdshader")

@export var surface: CabinetSurface

var _mat: ShaderMaterial


func _ready() -> void:
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	color = Color.WHITE
	if surface == null:
		surface = CabinetSurface.default() as CabinetSurface
	var h := CabinetBezel.hole()
	position = h.position
	size = h.size
	_mat = ShaderMaterial.new()
	_mat.shader = SHADER
	material = _mat
	CabinetLighting.apply(_mat, surface)
	var inks := BezelInks.default() as BezelInks
	_mat.set_shader_parameter(&"corner_r", surface.tube_corner_radius)
	_mat.set_shader_parameter(&"rect_size", h.size)
	_mat.set_shader_parameter(&"rig_origin", h.position)
	_mat.set_shader_parameter(&"a_reflect", surface.tube_reflection)
	_mat.set_shader_parameter(&"a_dust", surface.tube_dust)
	_mat.set_shader_parameter(&"a_bloom", surface.tube_bloom)
	_mat.set_shader_parameter(&"a_shadow", surface.tube_edge_shadow)
	_mat.set_shader_parameter(&"key_black", Vector3(inks.key_black.r, inks.key_black.g, inks.key_black.b))
	refresh()
	SettingsService.setting_changed.connect(_on_setting_changed)


func _on_setting_changed(key: StringName, _v: Variant) -> void:
	if key == &"photosensitivity":
		refresh()


## True while the glass layer is drawn.
func glass_on() -> bool:
	return glass_enabled(surface, bool(SettingsService.get_value(&"photosensitivity")))


## Push the glass amount (0 when off) and the alpha bound into the shader.
func refresh() -> void:
	if _mat == null:
		return
	var on := glass_on()
	_mat.set_shader_parameter(&"glass", surface.tube_glass if on else 0.0)
	_mat.set_shader_parameter(&"max_alpha", max_alpha(surface, on))


## Whether the glass is on for a surface and a photosensitivity setting.
static func glass_enabled(s: CabinetSurface, photosensitive: bool) -> bool:
	return s.tube_glass > 0.0 and not photosensitive


## The largest alpha the glass can ever have: the sum of its amounts (scaled by tube_glass) bounded by
## tube_max_shift; 0 when off. A blend moves a channel by at most this much.
static func max_alpha(s: CabinetSurface, on: bool = true) -> float:
	if not on or s.tube_glass <= 0.0:
		return 0.0
	return minf((s.tube_reflection + s.tube_dust + s.tube_bloom + s.tube_edge_shadow) * s.tube_glass, s.tube_max_shift)


## The screen texels the rounded mask replaces at 1x: in each corner the cells whose centre lies outside
## the corner circle.
static func mask_pixels(s: CabinetSurface) -> int:
	var r := s.tube_corner_radius
	var n := 0
	for i in int(ceil(r)):
		for j in int(ceil(r)):
			if Vector2(i + 0.5, j + 0.5).distance_to(Vector2(r, r)) > r:
				n += 1
	return n * 4


## The shader material, for tests and captures.
func tube_material() -> ShaderMaterial:
	return _mat
