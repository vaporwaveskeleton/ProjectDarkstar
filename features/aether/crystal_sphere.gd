class_name CrystalSphere
extends AetherShaderRect
## The crystal-sphere sky layer: places the vast curve of glass and moves its glint along the seam.
## Emits `sphere_glinted` when the glint passes the frame centre (EVT-001 row pending; dev gallery).

signal sphere_glinted

## ✱ sphere centre in world px (layer space) and radius: the curve spans the frame, never closes.
@export var sphere_centre: Vector2 = Vector2(380.0, 1000.0)
## ✱
@export var sphere_radius: float = 900.0
## ✱ seconds for one glint sweep along the seam.
@export var glint_period_s: float = 16.0
## ✱ half-range of the glint sweep, radians from straight up.
@export var glint_span: float = 0.9

var _last_side := 0.0


func glint_angle(t: float) -> float:
	return -glint_span + 2.0 * glint_span * fposmod(t / glint_period_s, 1.0)


## Angle of the frame centre seen from the sphere centre (same convention as the shader).
func centre_angle(screen_centre_world: Vector2) -> float:
	var rel := screen_centre_world - sphere_centre
	return atan2(rel.x, -rel.y)


func update_glint(t: float, screen_centre_world: Vector2) -> void:
	var a := glint_angle(t)
	set_param(&"glint_angle", a)
	set_param(&"centre", sphere_centre - position)
	set_param(&"radius", sphere_radius)
	var side := signf(a - centre_angle(screen_centre_world))
	if _last_side < 0.0 and side > 0.0:
		sphere_glinted.emit()
	_last_side = side
