class_name ArcadeLayer
extends Node2D
## Base for one rule-owning layer of the Cabinet (geodes, glass, Grubs…). The world calls
## reset() at stage start, tick() every physics frame, and the layer draws itself in _draw()
## using world.to_screen(). Layers talk through the world, never through node paths.

var world: ArcadeWorld


func reset() -> void:
	pass


func tick(_delta: float) -> void:
	pass


## Shared helper: is a world point inside the visible field?
func visible_at(p: Vector2, margin: float = 64.0) -> bool:
	return world.on_screen(p, margin)
