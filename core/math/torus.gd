class_name Torus
extends RefCounted
## Wrap-around ("torus") space for the arcade field (GDD §4.2: the Pale Marches torus-wraps).
## Positions live in [0, size). Distances and directions always take the short way round,
## so a thing just across the seam is close, not a whole field away.

var size: Vector2


func _init(p_size: Vector2) -> void:
	size = p_size


## Bring a position back inside the field.
func wrap(p: Vector2) -> Vector2:
	return Vector2(fposmod(p.x, size.x), fposmod(p.y, size.y))


## Shortest vector from a to b across the seams.
func delta(a: Vector2, b: Vector2) -> Vector2:
	var d := b - a
	d.x -= size.x * roundf(d.x / size.x)
	d.y -= size.y * roundf(d.y / size.y)
	return d


func distance(a: Vector2, b: Vector2) -> float:
	return delta(a, b).length()


func distance_sq(a: Vector2, b: Vector2) -> float:
	return delta(a, b).length_squared()


## Where `p` should be drawn when the view is centred on `centre` (which is drawn at `screen_centre`).
func to_screen(p: Vector2, centre: Vector2, screen_centre: Vector2) -> Vector2:
	return screen_centre + delta(centre, p)
