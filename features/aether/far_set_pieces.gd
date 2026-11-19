class_name FarSetPieces
extends Node2D
## Retro-future Victorian far set pieces (ART-001 §15; pass 2): runtime vector in the far band,
## fogged by the bands in front of them and cropped by the frame. Brass is BONE (+ VOID through the
## fog), never GAS — GAS stays the lantern's (T4's lamp-interior tarnish lives on OrreryRibs).
## Orrery rings (concentric tilted ellipses with planet beads, slowly turning) in T1/T4; gaslit
## lattice fragments (riveted girders, tiny warm windows below the lantern) in T2/T3; a drowned
## observatory dome with its telescope housing in T3. Pal colours come from the look.

## ✱ orrery centre (layer px), ring radii, ellipse squash and tilt.
@export var orrery_centre: Vector2 = Vector2(500.0, 64.0)
@export var orrery_radii: PackedFloat32Array = PackedFloat32Array([90.0, 150.0, 220.0, 300.0])
@export var orrery_squash: float = 0.3
@export var orrery_tilt: float = -0.16
## ✱ radians per second of the innermost bead (outer beads slower).
@export var orrery_speed: float = 0.02
## ✱ opacity of the set pieces (they sit in the far band, behind the fog).
@export var fade: float = 0.14

var brass: Color = Pal.BONE_2
var silhouette: Color = Pal.VOID_2
var window: Color = Pal.BONE_4
var show_orrery := false
var show_lattice := false
var show_dome := false
var _t := 0.0


func configure(look: AetherLook) -> void:
	brass = look.brass
	silhouette = look.fog_mid
	show_orrery = look.set_orrery_rings
	show_lattice = look.set_lattice
	show_dome = look.set_dome
	queue_redraw()


func any_shown() -> bool:
	return show_orrery or show_lattice or show_dome


func set_time(t: float) -> void:
	_t = t
	if show_orrery:
		queue_redraw()


func _c(base: Color, a: float) -> Color:
	var c := base
	c.a = a * fade
	return c


func _draw() -> void:
	if show_orrery:
		_draw_orrery()
	if show_lattice:
		_draw_lattice(Vector2(-60.0, 70.0), Vector2(760.0, 10.0), 9.0)
	if show_dome:
		_draw_dome(Vector2(96.0, 318.0), 112.0)


func _ellipse(c: Vector2, rx: float, ry: float, tilt: float, n: int) -> PackedVector2Array:
	var pts := PackedVector2Array()
	var rot := Transform2D(tilt, Vector2.ZERO)
	for i in n + 1:
		var a := TAU * float(i) / float(n)
		pts.append(c + rot * Vector2(cos(a) * rx, sin(a) * ry))
	return pts


func _draw_orrery() -> void:
	var rot := Transform2D(orrery_tilt, Vector2.ZERO)
	draw_line(orrery_centre + rot * Vector2(0, -150), orrery_centre + rot * Vector2(0, 150), _c(brass, 0.5), 1.0, true)
	draw_circle(orrery_centre, 6.0, _c(brass, 0.8))
	for i in orrery_radii.size():
		var r: float = orrery_radii[i]
		var ry := r * orrery_squash
		draw_polyline(_ellipse(orrery_centre, r, ry, orrery_tilt, 96), _c(brass, 0.85 - 0.1 * float(i)), 1.4, true)
		draw_polyline(_ellipse(orrery_centre, r - 3.0, ry - 1.0, orrery_tilt, 96), _c(brass, 0.35), 1.0, true)
		var a := _t * orrery_speed / (1.0 + float(i)) + float(i) * 1.7
		var bead := orrery_centre + rot * Vector2(cos(a) * r, sin(a) * ry)
		draw_circle(bead, 3.0 + float(i), _c(brass, 0.9))
		draw_arc(bead, 6.0 + float(i) * 1.5, 0.0, TAU, 24, _c(brass, 0.4), 1.0, true)


func _draw_lattice(a: Vector2, b: Vector2, depth: float) -> void:
	var dir := (b - a).normalized()
	var n := Vector2(-dir.y, dir.x) * depth
	var span := a.distance_to(b)
	var col := _c(brass, 0.5)
	draw_line(a, b, col, 1.4, true)
	draw_line(a + n, b + n, col, 1.4, true)
	var bay := depth * 1.6
	var k := 0.0
	var flip := false
	while k < span - bay:
		var p0 := a + dir * k + (n if flip else Vector2.ZERO)
		var p1 := a + dir * (k + bay) + (Vector2.ZERO if flip else n)
		draw_line(p0, p1, _c(brass, 0.3), 1.0, true)
		draw_circle(a + dir * k, 1.1, _c(brass, 0.9))
		# a tiny warm window every few bays: lit from inside, far below the lantern
		if int(k / bay) % 5 == 2:
			draw_rect(Rect2(a + dir * k + n * 0.3 - Vector2(1.0, 1.0), Vector2(2.0, 2.5)), _c(window, 1.4))
		flip = not flip
		k += bay


func _draw_dome(base: Vector2, r: float) -> void:
	var sil := _c(silhouette, 2.2)
	var line := _c(brass, 0.45)
	# drum and dome
	draw_rect(Rect2(base + Vector2(-r, 0.0), Vector2(r * 2.0, r * 0.7)), sil)
	var dome := PackedVector2Array()
	for i in 33:
		var a := PI + PI * float(i) / 32.0
		dome.append(base + Vector2(cos(a) * r, sin(a) * r * 0.85))
	draw_colored_polygon(dome, sil)
	draw_polyline(dome, line, 1.4, true)
	# dome ribs
	for k in 7:
		var x := -r + r * 2.0 * float(k + 1) / 8.0
		var top := base + Vector2(x, -sqrt(maxf(r * r - x * x, 0.0)) * 0.85)
		draw_line(top, base + Vector2(x, 0.0), _c(brass, 0.4), 1.0, true)
	# the slot and the telescope housing, raking out of it
	var slot_a := base + Vector2(r * 0.12, -r * 0.84)
	draw_line(slot_a, base + Vector2(r * 0.3, -r * 0.1), _c(brass, 0.7), 2.0, true)
	var tube0 := base + Vector2(r * 0.18, -r * 0.55)
	var tube1 := tube0 + Vector2(cos(-1.05), sin(-1.05)) * r * 1.25
	draw_line(tube0, tube1, sil, 14.0, true)
	draw_line(tube0, tube1, line, 1.0, true)
	draw_circle(tube1, 8.0, sil)
	draw_arc(tube1, 8.0, 0.0, TAU, 24, line, 1.0, true)
