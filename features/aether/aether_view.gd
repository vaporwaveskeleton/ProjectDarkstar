class_name AetherView
extends Node
## Presents an Aether world (TECH-001 §2.9). Whatever is put under %World (an HDR SubViewport
## with its own world and glow) is rendered at the window's real pixel size, laid out in the root's
## logical space, and shown on %Screen through aether_present.gdshader. Owns no veil and no fade:
## the scene that uses it decides how it is entered. Owns no game state.

@onready var world: SubViewport = %World
@onready var _screen: TextureRect = %Screen
@onready var _env: WorldEnvironment = %Env


func _ready() -> void:
	_screen.texture = world.get_texture()
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
