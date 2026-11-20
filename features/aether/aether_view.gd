class_name AetherView
extends Node
## Presents an Aether world (TECH-001 §2.9). Whatever is put under %World (an HDR SubViewport
## with its own world and glow) is rendered at the window's real pixel size, laid out in the root's
## logical space, and shown on %Screen through aether_present.gdshader. Owns no veil and no fade:
## the scene that uses it decides how it is entered. Owns no game state.

## ✱ pass 8 c: the night floor is AETHER-0 at this share (linear), a deep indigo, never neutral black.
const NIGHT_FLOOR_K := 0.35

@onready var world: SubViewport = %World
@onready var _screen: TextureRect = %Screen
@onready var _env: WorldEnvironment = %Env


func _ready() -> void:
	_screen.texture = world.get_texture()
	# one presenting material per view: the pass 8 grade uniforms must never leak between views
	if _screen.material != null:
		_screen.material = _screen.material.duplicate()
	get_tree().root.size_changed.connect(_fit)
	_fit()


## Render the world at the window's real pixel size, laid out in the root's logical space.
func _fit() -> void:
	var px := Vector2i(get_tree().root.size)
	var logical := Vector2i(get_viewport().get_visible_rect().size)
	world.size = Vector2i(maxi(px.x, 1), maxi(px.y, 1))
	world.size_2d_override = Vector2i(maxi(logical.x, 1), maxi(logical.y, 1))
	world.size_2d_override_stretch = true


## Glow threshold, intensity and bloom from the look (ART-001 §15).
func apply_glow(look: AetherLook) -> void:
	if look == null:
		return
	var env := _env.environment
	env.glow_hdr_threshold = look.glow_threshold
	env.glow_intensity = look.glow_intensity
	env.glow_bloom = look.glow_bloom


func environment() -> Environment:
	return _env.environment


## Pass 8: the far layer's value cap from the look (Q-T296), on the presenting material
## (aether_present.gdshader). Folded into the present pass: no extra back-buffer copy.
func apply_grade(look: AetherLook) -> void:
	grade_material(_screen.material as ShaderMaterial, look)


## Pass 8: lantern-down night (Q-T310) and the lantern pool the cap spares, every frame.
func update_night(backdrop: AetherBackdrop) -> void:
	night_material(_screen.material as ShaderMaterial, backdrop)


static func grade_material(m: ShaderMaterial, look: AetherLook) -> void:
	if m == null or look == null:
		return
	m.set_shader_parameter(&"cap_knee", look.far_value_cap)
	m.set_shader_parameter(&"cap_slope", look.far_cap_slope)
	m.set_shader_parameter(&"cap_desat", look.far_cap_desat)
	m.set_shader_parameter(&"cap_veil", look.far_cap_veil)
	m.set_shader_parameter(&"veil_col", look.fog_deep.srgb_to_linear())
	m.set_shader_parameter(&"floor_col", Pal.VOID_0.srgb_to_linear())
	# pass 8 c (Q-T403, Q-T404): the night floor and the split tone, Pal hues in linear space
	m.set_shader_parameter(&"night_floor", Pal.AETHER_0.srgb_to_linear() * NIGHT_FLOOR_K)
	m.set_shader_parameter(&"tone_k", look.far_split_tone)
	m.set_shader_parameter(&"tone_deep", Pal.AETHER_5.srgb_to_linear())
	m.set_shader_parameter(&"tone_lit", Pal.AETHER_4.srgb_to_linear())
	m.set_shader_parameter(&"tone_pool", Pal.GAS_3.srgb_to_linear())


static func night_material(m: ShaderMaterial, backdrop: AetherBackdrop) -> void:
	if m == null or backdrop == null or backdrop.look == null:
		return
	m.set_shader_parameter(&"night", backdrop.look.lantern_night * smoothstep(0.0, 1.0, backdrop.reveal))
	m.set_shader_parameter(&"logical_size", backdrop.get_viewport_rect().size)
	m.set_shader_parameter(&"lantern_px", backdrop.lantern_screen)
	m.set_shader_parameter(&"lantern_r", backdrop.lantern_radius)
