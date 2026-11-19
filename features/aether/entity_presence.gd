class_name EntityPresence
extends AetherShaderRect
## The entity's presence: the only pure black in the game (ART-001 §16). A torn NULL wound whose
## radius the backdrop drives; it has no rim, no glow and no halo. Filaments grow out of it with
## drain. Lives in group `entity_presence` so tests can prove every black pixel source belongs to
## it. Unlit, never a collider.

const GROUP := &"entity_presence"
## ✱ quad half-size as a multiple of max_radius: room for the torn edge and the filaments.
const QUAD_REACH := 1.95

## ✱ largest radius this node will ever be asked for; sizes the quad.
@export var max_radius: float = 140.0
## ✱ kept for the scene files; the torn outline replaces the old wobble.
@export var wobble: float = 0.16
@export var seed: float = 0.0
## ✱ filaments reaching out of the wound (5–9).
@export var tendril_count: int = 7

## Centre in layer px.
var centre: Vector2 = Vector2.ZERO:
	set(v):
		centre = v
		_place()
var radius: float = 0.0:
	set(v):
		radius = maxf(v, 0.0)
		set_param(&"radius", radius)
		visible = radius > 0.5


func _init() -> void:
	super._init()
	add_to_group(GROUP)


func _ready() -> void:
	super._ready()
	light_mask = 0
	set_param(&"seed", seed)
	set_param(&"tendril_count", tendril_count)
	_place()
	radius = radius


func _place() -> void:
	var half := max_radius * QUAD_REACH
	size = Vector2(half, half) * 2.0
	position = centre - Vector2(half, half)
	set_param(&"half_size", Vector2(half, half))


func set_time(t: float) -> void:
	set_param(&"time_s", t)


## 0..1: how far the filaments have grown (the backdrop ties it to drain).
func set_growth(g: float) -> void:
	set_param(&"grow", clampf(g, 0.0, 1.0))


func set_edge_octaves(n: int) -> void:
	set_param(&"edge_octaves", clampi(n, 2, 4))


## xy = screen position (logical px), z = radius, w = 1 when showing.
func screen_mask() -> Vector4:
	if not visible or not is_inside_tree():
		return Vector4.ZERO
	var p := get_global_transform_with_canvas() * (size * 0.5)
	return Vector4(p.x, p.y, radius, 1.0)
