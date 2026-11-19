class_name StationMark
extends Node2D
## A chalk mark on the Ruins floor in front of a place you can use (a ring and a tick, as Sable marks
## a station), or a page stamped on the Codex desk. Visual only, in RuinsLook's lit stage; RuinsLook
## eases its tint by state (idle / focused / used), so focus is the chalk lifting, never a prompt.

enum Style { FLOOR, PAGE }

@export var style: Style = Style.FLOOR
## ✱ ring radii (px).
@export var radius := Vector2(14.0, 3.0)
## Unused stations breathe faintly so the eye finds them (✱ hz; 0 when used or reduced motion).
var breath_hz := 0.35
var _t := 0.0


func _process(delta: float) -> void:
	_t += delta
	queue_redraw()


func _draw() -> void:
	var b := 0.82 + 0.18 * sin(_t * TAU * breath_hz) if breath_hz > 0.0 else 0.85
	match style:
		Style.FLOOR:
			var c := Color(Pal.BONE_4, 0.55 * b)
			var pts := PackedVector2Array()
			for i in 25:
				var a := TAU * float(i) / 24.0
				pts.append(Vector2(cos(a) * radius.x, sin(a) * radius.y))
			draw_polyline(pts, c, 1.0, true)
			draw_line(Vector2(-3, -radius.y - 2), Vector2(0, -radius.y - 5), c, 1.0, true)
			draw_line(Vector2(0, -radius.y - 5), Vector2(3, -radius.y - 2), c, 1.0, true)
		Style.PAGE:
			# a freshly stamped page lifted off the open book: pale, with a phosphor-truth stamp
			var page := PackedVector2Array([Vector2(-7, -2), Vector2(6, -5), Vector2(7, 3), Vector2(-6, 6)])
			draw_colored_polygon(page, Color(Pal.BONE_4, 0.9))
			draw_circle(Vector2(1, 1), 1.8, Color(Pal.PHOS_4, b))
			for k in 3:
				draw_line(Vector2(-4, -1 + k * 2), Vector2(-1 + k, -1.6 + k * 2), Color(Pal.VOID_3, 0.6), 0.6)
