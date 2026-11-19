class_name SectorWrap
extends Node
## Keeps a sector's actors on its torus (Q-T57). Runs in the physics tick AFTER the actors (place it
## after the actors' parent in the tree), so the Vigil wraps after its own physics step.
## - The anchor (the Vigil) wraps into [0, size): position only, velocity untouched.
## - Every other actor is kept on the image nearest the anchor (Torus.delta), so shots fired across
##   the seam stay continuous on screen and in physics near the player; they still expire by their
##   own lifetime. Arc-Lance code is not touched.

## The node whose children are the actors (the sector's %Actors).
@export var actors: Node2D
## The wrapping sector, injected by the sector host.
var torus: Torus
## The actor that defines the canonical field (the Vigil). Null = everything wraps into [0, size).
var anchor: Node2D


func _physics_process(_delta: float) -> void:
	wrap_actors()


## One pass over the actors. Public so tests can drive it.
func wrap_actors() -> void:
	if torus == null or actors == null:
		return
	var has_anchor := is_instance_valid(anchor)
	if has_anchor:
		_move(anchor, torus.wrap(anchor.global_position))
	for child in actors.get_children():
		var n := child as Node2D
		if n == null or n == anchor:
			continue
		if has_anchor:
			_move(n, nearest_image(torus, n.global_position, anchor.global_position))
		else:
			_move(n, torus.wrap(n.global_position))


static func _move(n: Node2D, to: Vector2) -> void:
	if n.global_position != to:
		n.global_position = to


## The copy of `p` on the torus that is nearest `near`.
static func nearest_image(t: Torus, p: Vector2, near: Vector2) -> Vector2:
	return near + t.delta(near, p)
