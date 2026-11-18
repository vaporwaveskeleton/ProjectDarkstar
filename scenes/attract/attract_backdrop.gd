class_name AttractBackdrop
extends Control
## Behind the attract menu: deep field, drifting stars, a few vector geodes turning, and far off
## a Grub procession carrying glass toward a Sepulchre you cannot quite see. Costume art only.

var _t := 0.0
var _stars := PackedVector2Array()
var _rocks: Array[Dictionary] = []


func _ready() -> void:
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	var r := RandomNumberGenerator.new()
	r.seed = 1983
	for i in 140:
		_stars.append(Vector2(r.randf() * 640.0, r.randf() * 360.0))
	for i in 5:
		var pts := PackedVector2Array()
		var rad := r.randf_range(8.0, 18.0)
		for k in 9:
			pts.append(Vector2.from_angle(TAU * k / 9.0) * rad * r.randf_range(0.75, 1.0))
		_rocks.append({"pos": Vector2(r.randf() * 640.0, r.randf() * 360.0), "vel": Vector2.from_angle(r.randf() * TAU) * r.randf_range(4.0, 10.0),
			"shape": pts, "spin": r.randf_range(-0.3, 0.3)})


func _process(delta: float) -> void:
	_t += delta
	queue_redraw()


func _draw() -> void:
	draw_rect(Rect2(Vector2.ZERO, size), Look.c(Pal.VOID_0))
	for i in _stars.size():
		var s := _stars[i]
		var p := Vector2(fposmod(s.x - _t * (4.0 + (i % 3) * 5.0), 640.0), s.y)
		var c := Look.c(Pal.VOID_4) if i % 3 == 0 else (Look.c(Pal.VOID_5) if i % 3 == 1 else Look.c(Pal.BONE_2))
		if (i * 13 + int(_t * 3.0)) % 41 == 0:
			c = Look.c(Pal.BONE_5)
		draw_rect(Rect2(p.round(), Vector2.ONE), c)
	for rk in _rocks:
		var c: Vector2 = (rk.pos as Vector2) + (rk.vel as Vector2) * _t
		c = Vector2(fposmod(c.x, 680.0) - 20.0, fposmod(c.y, 400.0) - 20.0)
		var rot: float = float(rk.spin) * _t
		var pts := PackedVector2Array()
		for v in (rk.shape as PackedVector2Array):
			pts.append((c + v.rotated(rot)).round())
		Pal.glow_polyline(self, pts, Look.c(Pal.BONE_2), Look.c(Pal.BONE_0))
	# the procession: five Grubs and their glass, crossing low and slow
	for k in 5:
		var x := fposmod(_t * 18.0 - k * 22.0, 760.0) - 60.0
		var p := Vector2(x, 300.0 + sin(_t * 1.3 + k) * 3.0).round()
		draw_arc(p, 2.5, 0.0, TAU, 8, Look.c(Pal.CHOIR_3), 1.0)
		draw_arc(p - Vector2(4, 0), 2.0, 0.0, TAU, 8, Look.c(Pal.CHOIR_3), 1.0)
		draw_rect(Rect2(p + Vector2(0, -6), Vector2(2, 3)), Look.c(Pal.PHOS_4))
