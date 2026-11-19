class_name RuinsForeground
extends Node2D
## The near arch the hall is seen through: a broken pointed arch close to the eye, its jambs at the
## frame's edges and its spandrels darkening the top corners, plus a fallen beam leaning across the
## top right. It makes the hall read cramped and enclosed (NARR-001 §5.7 "a cramped, half-ruined
## hall"). Near, so mostly in shadow (VOID albedo, lit by the hall's lights like everything else).
## Drawn in front of the hall's props; it stays clear of the play floor.

## ✱ the near arch's jamb width, spring height and apex (logical px, 640×360 frame).
const JAMB_PX := 16.0
const SPRING_Y := 150.0
const APEX_Y := -46.0

var size := Vector2(640.0, 360.0)
var near := Pal.VOID_2
var near_edge := Pal.BONE_0


func configure(data: RuinsLookData) -> void:
	near = data.mortar
	near_edge = data.stone_b
	queue_redraw()


func set_size(s: Vector2) -> void:
	if s != size:
		size = s
		queue_redraw()


func _draw() -> void:
	var w := size.x
	# spandrels: everything outside the near arch's intrados, above the spring
	var span := w - JAMB_PX * 2.0
	var ah := SPRING_Y - APEX_Y
	var r := (ah * ah + span * span * 0.25) / span
	var left := PackedVector2Array([Vector2(0, -2), Vector2(0, SPRING_Y)])
	var right := PackedVector2Array([Vector2(w, -2), Vector2(w, SPRING_Y)])
	var steps := 24
	var arc_l := PackedVector2Array()
	var arc_r := PackedVector2Array()
	for k in steps + 1:
		var t := float(k) / float(steps)
		# left half: circle centred right of the left jamb, from the spring up to the frame top
		var y := lerpf(SPRING_Y, -2.0, t)
		var dy := y - SPRING_Y
		var x_l := JAMB_PX + r - sqrt(maxf(r * r - dy * dy, 0.0))
		arc_l.append(Vector2(x_l, y))
		arc_r.append(Vector2(w - x_l, y))
	left.append(Vector2(JAMB_PX, SPRING_Y))
	left.append_array(arc_l)
	draw_colored_polygon(left, near)
	var rr := PackedVector2Array([Vector2(w - JAMB_PX, SPRING_Y)])
	rr.append_array(arc_r)
	rr.append_array(right)
	draw_colored_polygon(rr, near)
	draw_polyline(arc_l, near_edge, 1.5, true)
	draw_polyline(arc_r, near_edge, 1.5, true)
	# the jambs down to the floor, a chamfer line catching light
	draw_rect(Rect2(0, SPRING_Y, JAMB_PX, size.y - SPRING_Y), near)
	draw_rect(Rect2(w - JAMB_PX, SPRING_Y, JAMB_PX, size.y - SPRING_Y), near)
	draw_line(Vector2(JAMB_PX, SPRING_Y), Vector2(JAMB_PX, size.y), near_edge, 1.2)
	draw_line(Vector2(w - JAMB_PX, SPRING_Y), Vector2(w - JAMB_PX, size.y), near_edge, 1.2)
	# a bite out of the right spandrel: the near arch is broken too
	draw_colored_polygon(PackedVector2Array([Vector2(w - 70, -2), Vector2(w - 52, 9), Vector2(w - 60, 15),
		Vector2(w - 40, 22), Vector2(w - 38, -2)]), near_edge.lerp(near, 0.4))
	# a fallen beam leaning across the top right, close to the eye
	var a := Vector2(w - 230.0, -6.0)
	var b := Vector2(w + 4.0, 58.0)
	draw_line(a, b, near, 9.0, true)
	draw_line(a + Vector2(0, 4.2), b + Vector2(0, 4.2), near_edge, 1.0, true)
