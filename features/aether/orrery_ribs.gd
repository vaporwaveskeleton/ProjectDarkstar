class_name OrreryRibs
extends Node2D
## T4 far layer: the brass ribs of the lamp's interior, seen from inside — partial arcs and spokes
## of an orrery cage, faint, turning very slowly. Vector only (_draw), Pal colours from the look.

## ✱ cage centre (layer px) and radii.
@export var cage_centre: Vector2 = Vector2(330.0, 560.0)
## ✱
@export var radii: PackedFloat32Array = PackedFloat32Array([420.0, 520.0, 640.0, 790.0])
## ✱ radians per second.
@export var turn_speed: float = 0.004

var rib_colour: Color = Pal.BONE_1
var accent: Color = Pal.GAS_1
var _angle := 0.0


func configure(look: AetherLook) -> void:
	rib_colour = look.rib_colour
	accent = look.rib_accent
	queue_redraw()


func set_time(t: float) -> void:
	_angle = t * turn_speed
	queue_redraw()


func _draw() -> void:
	for i in radii.size():
		var r: float = radii[i]
		var a0 := PI + 0.25 + _angle * (1.0 if i % 2 == 0 else -1.3)
		var c := rib_colour
		c.a = 0.45 - 0.07 * float(i)
		draw_arc(cage_centre, r, a0, a0 + PI - 0.5, 96, c, 3.0, true)
		# pass 3: two-tone metal — a thin lit edge on the inner side of each rib
		var hi := Pal.BONE_3
		hi.a = c.a * 0.6
		draw_arc(cage_centre, r - 1.5, a0, a0 + PI - 0.5, 96, hi, 1.0, true)
		var acc := accent
		acc.a = 0.25 - 0.04 * float(i)
		draw_arc(cage_centre, r - 4.0, a0 + 0.3, a0 + 0.9, 32, acc, 1.0, true)
	for k in 9:
		var a := PI + 0.3 + float(k) * 0.32 + _angle
		var dir := Vector2(cos(a), sin(a))
		var c2 := rib_colour
		c2.a = 0.12
		draw_line(cage_centre + dir * radii[0], cage_centre + dir * radii[radii.size() - 1], c2, 1.5, true)
