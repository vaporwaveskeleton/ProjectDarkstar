class_name StillSmudge
extends Node2D
## T1 wrongness: a large, faint, slightly darker vertical shape far off that does not drift while
## the fog around it does. VOID_2 (never NULL), soft-edged: stacked translucent ellipses, densest
## along its spine. It simply stays where it is while everything else moves.

## ✱ half-width and half-height of the shape in layer px.
@export var half_size: Vector2 = Vector2(34.0, 120.0)
## ✱ opacity of each stacked layer (the stack sums to roughly 0.45 at the spine).
@export var layer_alpha: float = 0.05

var tone: Color = Pal.VOID_2


func configure(look: AetherLook) -> void:
	tone = look.far_silhouette
	queue_redraw()


func _draw() -> void:
	for i in 12:
		var k := 1.0 - float(i) / 12.0
		var c := tone
		c.a = layer_alpha
		var hs := half_size * Vector2(0.25 + 0.75 * k, 0.55 + 0.45 * k)
		var pts := PackedVector2Array()
		for j in 32:
			var a := TAU * float(j) / 32.0
			# a slight lean and a narrower top: a standing shape, not a disc
			var w := hs.x * (0.8 + 0.2 * sin(a))
			pts.append(Vector2(cos(a) * w + sin(a) * hs.y * 0.06, sin(a) * hs.y))
		draw_colored_polygon(pts, c)
