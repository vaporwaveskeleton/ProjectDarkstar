class_name EntityPresence
extends AetherShaderRect
## The entity's presence: the only pure black in the game (ART-001 §16). A NULL mass whose radius
## the backdrop drives; it has no rim and no glow. Lives in group `entity_presence` so tests can
## prove every black pixel source belongs to it. Unlit, never a collider.

const GROUP := &"entity_presence"

## ✱ largest radius this node will ever be asked for; sizes the quad.
@export var max_radius: float = 140.0
## ✱ edge irregularity as a fraction of the radius.
@export var wobble: float = 0.16
@export var seed: float = 0.0

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
	set_param(&"wobble", wobble)
	_place()
	radius = radius


func _place() -> void:
	var half := max_radius * (1.0 + wobble + 0.1)
	size = Vector2(half, half) * 2.0
	position = centre - Vector2(half, half)
	set_param(&"half_size", Vector2(half, half))


func set_time(t: float) -> void:
	set_param(&"time_s", t)


## xy = screen position (logical px), z = radius, w = 1 when showing.
func screen_mask() -> Vector4:
	if not visible or not is_inside_tree():
		return Vector4.ZERO
	var p := get_global_transform_with_canvas() * (size * 0.5)
	return Vector4(p.x, p.y, radius, 1.0)
