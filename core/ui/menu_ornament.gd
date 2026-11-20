class_name MenuOrnament
extends Control
## Decorative art panel of an overlay menu, drawn in the costume (MenuSkin). Pure decoration: it
## holds no information, takes no focus and shrinks away (draws nothing) when Large Text needs the room.
##   SKY      cabinet: the bezel's world in neon line art (ringed planet, stars, the Vigil dart);
##            brass: an orrery of crystal spheres in a graduated brass ring (ART-001 §16).
##   WARNING  a caution plate for confirmations (GAS, never SIGNAL).
## Runtime vector, Pal colours only (D-13); cabinet colours through Look.c. Static: no motion.

enum Motif { SKY, WARNING }

@export var motif: Motif = Motif.SKY
## Minimum size at 100 % text; at Large Text the ornament gives its room to the text (0).
@export var base_min := Vector2.ZERO
## ✱ Below this side (logical px) the ornament draws nothing.
const MIN_SIDE := 28.0

var kind: MenuSkin.Kind = MenuSkin.Kind.CABINET


func _ready() -> void:
	kind = MenuSkin.for_node(self)
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	focus_mode = Control.FOCUS_NONE
	resized.connect(queue_redraw)
	_fit()
	SettingsService.setting_changed.connect(func(k: StringName, _v: Variant) -> void:
		if k == &"text_scale":
			_fit())


func _fit() -> void:
	custom_minimum_size = base_min if MenuSkin.text_scale() < 1.5 else Vector2.ZERO


func _draw() -> void:
	var side := minf(size.x, size.y)
	if side < MIN_SIDE:
		return
	var c := size * 0.5
	if motif == Motif.WARNING:
		_warning(c, side * 0.42)
	elif kind == MenuSkin.Kind.BRASS:
		_orrery(c, side * 0.46)
	else:
		_sky(c, side * 0.46)


func _k(col: Color) -> Color:
	return MenuSkin.c(kind, col)


func _sky(c: Vector2, r: float) -> void:
	# stars: four-point glints, fixed positions on the unit square
	var stars := [Vector2(-0.8, -0.75), Vector2(0.7, -0.85), Vector2(0.85, 0.2), Vector2(-0.9, 0.35),
		Vector2(0.3, 0.9), Vector2(-0.35, -0.95), Vector2(0.95, -0.35)]
	for i in stars.size():
		var p: Vector2 = c + (stars[i] as Vector2) * r
		var s := 1.5 + float(i % 3)
		var col := _k(Pal.BONE_4) if i % 2 == 0 else _k(Pal.GAS_4)
		draw_line(p - Vector2(s, 0), p + Vector2(s, 0), col, 1.0)
		draw_line(p - Vector2(0, s), p + Vector2(0, s), col, 1.0)
	# the ringed planet of the bezel, back half of the ring behind it
	var pc := c + Vector2(-0.15, 0.05) * r
	var pr := r * 0.42
	var tilt := -0.35
	_ellipse_arc(pc, Vector2(pr * 1.75, pr * 0.42), tilt, PI, TAU, _k(Pal.GAS_2), 1.5)
	draw_circle(pc, pr, _k(Pal.VOID_3))
	draw_arc(pc, pr, 0.0, TAU, 40, _k(Pal.VOID_5), 1.5)
	for k in 3:
		var y := pc.y - pr * 0.45 + float(k) * pr * 0.42
		var hw := sqrt(maxf(pr * pr - pow(y - pc.y, 2.0), 0.0)) * 0.9
		draw_line(Vector2(pc.x - hw, y), Vector2(pc.x + hw, y), _k(Pal.VOID_4), 1.0)
	_ellipse_arc(pc, Vector2(pr * 1.75, pr * 0.42), tilt, 0.0, PI, _k(Pal.GAS_3), 1.5)
	# the Vigil dart crossing above, its lantern lit
	var v := c + Vector2(0.55, -0.45) * r
	var d := Vector2(-1.0, 0.55).normalized()
	var n := Vector2(-d.y, d.x)
	var ln := r * 0.28
	var tip := v + d * ln
	draw_colored_polygon(PackedVector2Array([tip, v - d * ln * 0.5 + n * ln * 0.45, v - d * ln * 0.2, v - d * ln * 0.5 - n * ln * 0.45]), _k(Pal.BONE_5))
	draw_circle(v - d * ln * 0.05, maxf(1.2, ln * 0.12), _k(Pal.GAS_4))
	for k in 3:
		var t0 := v - d * (ln * 0.6 + float(k) * ln * 0.35)
		draw_line(t0, t0 - d * ln * 0.2, Color(_k(Pal.GAS_3), 0.8 - 0.25 * float(k)), 1.0)


func _orrery(c: Vector2, r: float) -> void:
	# graduated brass ring
	draw_arc(c, r, 0.0, TAU, 64, Pal.GAS_0, 3.0)
	draw_arc(c, r - 0.5, 0.0, TAU, 64, Pal.GAS_3, 1.5)
	draw_arc(c, r - 4.0, 0.0, TAU, 64, Pal.GAS_2, 1.0)
	for i in 36:
		var a := TAU * float(i) / 36.0
		var tick := 3.5 if i % 3 == 0 else 2.0
		var u := Vector2(cos(a), sin(a))
		draw_line(c + u * (r - 4.0), c + u * (r - 4.0 - tick), Pal.GAS_3 if i % 3 == 0 else Pal.GAS_2, 1.0)
	# orbits and crystal spheres
	var orbits := [0.34, 0.55, 0.74]
	var angles := [0.6, 2.4, 4.3]
	var tints := [Pal.PHOS_3, Pal.AETHER_3, Pal.AETHER_5]
	for i in 3:
		var orr: float = r * float(orbits[i])
		_ellipse_arc(c, Vector2(orr, orr * 0.62), -0.3, 0.0, TAU, Color(Pal.GAS_2, 0.8), 1.0)
		var a: float = angles[i]
		var p := c + _rot(Vector2(cos(a) * orr, sin(a) * orr * 0.62), -0.3)
		draw_line(c, p, Color(Pal.GAS_1, 0.9), 1.0)
		var sr := r * (0.07 + 0.02 * float(i))
		draw_circle(p, sr + 1.0, Pal.GAS_0)
		draw_circle(p, sr, tints[i])
		draw_circle(p - Vector2(sr, sr) * 0.35, maxf(0.6, sr * 0.3), Color(Pal.BONE_5, 0.75))
	# the brass sun at the hub
	draw_circle(c, r * 0.12 + 1.5, Pal.GAS_0)
	draw_circle(c, r * 0.12, Pal.GAS_3)
	draw_circle(c - Vector2(1, 1) * r * 0.03, r * 0.06, Pal.GAS_5)


func _warning(c: Vector2, r: float) -> void:
	if kind == MenuSkin.Kind.BRASS:
		Brass.plate(self, Rect2(c - Vector2(r, r) * 1.05, Vector2(r, r) * 2.1), Pal.VOID_1)
	var pts := PackedVector2Array([c + Vector2(0, -r * 0.8), c + Vector2(r * 0.85, r * 0.7), c + Vector2(-r * 0.85, r * 0.7)])
	var edge := Pal.GAS_4 if kind == MenuSkin.Kind.BRASS else _k(Pal.GAS_3)
	draw_polyline(PackedVector2Array([pts[0], pts[1], pts[2], pts[0]]), edge, maxf(1.5, r * 0.09), true)
	var mark := Pal.BONE_5 if kind == MenuSkin.Kind.BRASS else _k(Pal.BONE_5)
	draw_line(c + Vector2(0, -r * 0.3), c + Vector2(0, r * 0.25), mark, maxf(1.5, r * 0.11))
	draw_circle(c + Vector2(0, r * 0.47), maxf(1.0, r * 0.07), mark)


func _ellipse_arc(c: Vector2, radii: Vector2, tilt: float, a0: float, a1: float, col: Color, w: float) -> void:
	var pts := PackedVector2Array()
	var steps := 32
	for i in steps + 1:
		var a := lerpf(a0, a1, float(i) / float(steps))
		pts.append(c + _rot(Vector2(cos(a) * radii.x, sin(a) * radii.y), tilt))
	draw_polyline(pts, col, w, true)


func _rot(v: Vector2, a: float) -> Vector2:
	return v.rotated(a)
