extends Node
## The Aether arrival (route &"aether", TECH-001 §2.9): where Act 0 hands the player to the Aether.
## Stub destination: it shows the world at the hand-off frame and lets it run; the flow after
## arrival is not designed (TECH-001 §11.1). No fade-in and no tween on entry: the caller routes
## here with `skip_curtain`, so Act 0's last frame is followed directly by this scene's first.
## ui_cancel does nothing yet. No class_name: reached only by route id.
##
## Route params (all optional, typed; a missing or wrongly typed value uses the default):
##   aether_time_s (float) world time to continue from, tier (int 1–5),
##   camera_centre (Vector2, logical px), camera_zoom (float).

const DEFAULT_TIME_S := 0.0
const DEFAULT_TIER := 1
const DEFAULT_CAMERA_CENTRE := Vector2(320.0, 180.0)   ## ✱ centre of the 640×360 logical frame
const DEFAULT_CAMERA_ZOOM := 1.0

## The world's look. Pale Marches (T1) until the run decides where the player arrives.
@export var look: AetherLook = preload("res://data/aether/pale_marches_t1.tres")

var time_s := DEFAULT_TIME_S

@onready var _view: AetherView = %View
@onready var _backdrop: AetherBackdrop = %Backdrop
@onready var _camera: Camera2D = %Camera
@onready var _lantern: LanternMarker = %Lantern


func _ready() -> void:
	_view.apply_glow(look)
	_backdrop.apply_look(look)
	_lantern.configure(look)
	on_route_entered({})


## SceneRouter calls this in the same deferred call that mounts the scene, after this frame's
## _process, so everything the first drawn frame needs is pushed here, not on the next _process.
func on_route_entered(params: Dictionary) -> void:
	time_s = _float_param(params, "aether_time_s", DEFAULT_TIME_S)
	var tier := _int_param(params, "tier", DEFAULT_TIER)
	var centre := _vector2_param(params, "camera_centre", DEFAULT_CAMERA_CENTRE)
	var zoom := _float_param(params, "camera_zoom", DEFAULT_CAMERA_ZOOM)
	if zoom <= 0.0:
		zoom = DEFAULT_CAMERA_ZOOM
	_backdrop.set_time(time_s)
	_backdrop.set_tier(tier)
	_camera.position = centre
	_camera.zoom = Vector2(zoom, zoom)
	_backdrop.set_camera(centre, zoom)
	_lantern.position = centre
	_backdrop.set_lantern(_backdrop.get_viewport_rect().size * 0.5, look.lantern_radius if look != null else _backdrop.lantern_radius)
	_camera.force_update_scroll()
	_backdrop.refresh()


func _process(delta: float) -> void:
	time_s += delta
	_backdrop.set_time(time_s)


static func _param(params: Dictionary, key: String) -> Variant:
	if params.has(key):
		return params[key]
	return params.get(StringName(key))


static func _float_param(params: Dictionary, key: String, fallback: float) -> float:
	var v: Variant = _param(params, key)
	if typeof(v) == TYPE_FLOAT or typeof(v) == TYPE_INT:
		return float(v)
	return fallback


static func _int_param(params: Dictionary, key: String, fallback: int) -> int:
	var v: Variant = _param(params, key)
	if typeof(v) != TYPE_INT:
		return fallback
	var n: int = v
	return n


static func _vector2_param(params: Dictionary, key: String, fallback: Vector2) -> Vector2:
	var v: Variant = _param(params, key)
	if typeof(v) != TYPE_VECTOR2:
		return fallback
	var out: Vector2 = v
	return out
