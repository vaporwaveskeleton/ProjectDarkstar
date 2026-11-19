class_name AetherFarLayer
extends Node
## The Aether far layer, pre-wired (TECH-001 §2.9): an AetherView with an AetherBackdrop and a
## Camera2D inside its World. A sector scene instances this in its far layer and drives it each frame
## through the forwarders below; it owns no game state, no collision and no input, and it never adds
## light to the play layer. Camera and lantern positions are in the backdrop's world space (the
## gallery's frame: home centre (320, 180), the 640×360 logical frame).

## The world's look (biome × tier). Pale Marches T1 until a sector sets one.
@export var look: AetherLook = preload("res://data/aether/pale_marches_t1.tres")

var time_s := 0.0
var camera_centre := Vector2(320.0, 180.0)
var camera_zoom := 1.0

@onready var view: AetherView = %View
@onready var backdrop: AetherBackdrop = %Backdrop
@onready var _camera: Camera2D = %Camera


func _ready() -> void:
	if look != null:
		apply_look(look)
	set_camera(camera_centre, camera_zoom)


func apply_look(new_look: AetherLook) -> void:
	look = new_look
	if not is_node_ready() or look == null:
		return
	view.apply_glow(look)
	backdrop.apply_look(look)
	backdrop.set_tier(look.tier)


func apply_quality(q: AetherQuality) -> void:
	backdrop.apply_quality(q)
	view.environment().glow_enabled = q != null and q.glow == 1


func set_tier(t: int) -> void:
	backdrop.set_tier(t)


## Camera centre (backdrop world px) and zoom (> 0; anything else counts as 1).
func set_camera(centre: Vector2, zoom: float) -> void:
	camera_centre = centre
	camera_zoom = zoom if zoom > 0.0 else 1.0
	_camera.position = camera_centre
	_camera.zoom = Vector2(camera_zoom, camera_zoom)
	backdrop.set_camera(camera_centre, camera_zoom)


## The lantern at `world_pos` (same space as the camera) with its light radius (world px), up or
## down. Down (CH-3) fades the warm pool out and the reveal (far-band life, the Presence's full
## light pattern) in; it changes nothing in the play layer.
func set_lantern(world_pos: Vector2, radius: float, lit: bool) -> void:
	var energy := look.lantern_energy if look != null else 1.6
	backdrop.set_lantern(world_to_screen(world_pos), radius * camera_zoom, Pal.GAS_4, energy)
	backdrop.set_lantern_lit(lit)


## World px → this layer's screen (logical px) for the current camera.
func world_to_screen(world_pos: Vector2) -> Vector2:
	var logical := backdrop.get_viewport_rect().size
	return (world_pos - camera_centre) * camera_zoom + logical * 0.5


func set_drain(amount: float) -> void:
	backdrop.set_drain(amount)


func set_time(seconds: float) -> void:
	time_s = seconds
	backdrop.set_time(time_s)


## The Presence turns and leaves (also automatic when the entity drains the world).
func presence_flee() -> void:
	backdrop.presence_flee()


## 0 = the Presence is here … 1 = it has gone.
func flee_progress() -> float:
	return backdrop.presence_flee_progress()


## 0 = lantern up … 1 = lantern down, reveal fully in.
func reveal() -> float:
	return backdrop.reveal


## W1-06 Chromatic Edge (Composure in Frayed): default off; never drawn under photosensitivity.
func set_chromatic_edge(on: bool) -> void:
	backdrop.set_chromatic_edge(on)


func _process(delta: float) -> void:
	time_s += delta
	backdrop.set_time(time_s)
