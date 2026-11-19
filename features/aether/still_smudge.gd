class_name StillSmudge
extends Node2D
## T1 wrongness: a far smudge that does not drift with the fog around it. VOID tones (never NULL),
## soft concentric discs; it simply stays where it is while everything else moves.

## ✱ radius of the smudge in layer px.
@export var smudge_radius: float = 30.0

var tone: Color = Pal.VOID_2


func configure(look: AetherLook) -> void:
	tone = look.far_silhouette
	queue_redraw()


func _draw() -> void:
	# many faint discs: a soft-edged stain, densest at its middle
	for i in 14:
		var k := 1.0 - float(i) / 14.0
		var c := tone
		c.a = 0.07
		draw_circle(Vector2.ZERO, smudge_radius * (0.2 + 0.8 * k), c)
