class_name MawView
extends Node2D
## The hole where a star should be (NARR-001 §1.2): a NULL disc that opens at the centre of the
## screen during THE PRETENCE. As `reveal` rises the true body shows inside it — the first time
## the game draws the entity with its real 64×64-module art instead of the cabinet costume.

@export var body_texture: Texture2D
var radius := 0.0:
	set(v):
		radius = v
		queue_redraw()
var reveal := 0.0:
	set(v):
		reveal = v
		queue_redraw()
var _t := 0.0


func _process(delta: float) -> void:
	_t += delta
	if visible:
		queue_redraw()


func _draw() -> void:
	if radius <= 0.0:
		return
	var c := Vector2(320, 180)
	draw_circle(c, radius, Pal.NULL)
	# veins of phosphor reaching out of the hole: the truth-telling colour (palette law 2)
	for k in 9:
		var a := TAU * k / 9.0 + _t * 0.05
		var p0 := c + Vector2.from_angle(a) * radius
		var p1 := c + Vector2.from_angle(a + 0.12) * (radius + 10.0 + 6.0 * sin(_t * 2.0 + k))
		draw_line(p0.round(), p1.round(), Pal.PHOS_2, 1.0)
	draw_arc(c, radius, 0.0, TAU, 64, Pal.VOID_5, 1.0)
	if body_texture != null and reveal > 0.0 and radius > 40.0:
		var size := body_texture.get_size() * 2.0            # integer scale only (ART-002 §7)
		var col := Color(1, 1, 1, clampf(reveal, 0.0, 1.0))
		draw_texture_rect(body_texture, Rect2((c - size * 0.5).round(), size), false, col)
