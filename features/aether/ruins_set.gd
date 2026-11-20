class_name RuinsSet
extends Node2D
## The Ruins hall's set dressing, runtime vector (ART-001 §14, §16): pilasters with brass bands,
## the vault's ribs broken where the roof is torn, the observatory's great telescope aimed at the
## tear, a broken orrery hanging from the vault (one ring still turning, very slowly), old chalk
## (star charts and tallies; marks, never text), rubble, and the hangar door tracks. Drawn in
## albedo colours and lit by the hall's lights (it never lights itself). Owns no state but layout.

## ✱ the slow orrery ring: seconds per turn.
const ORRERY_TURN_S := 140.0
## ✱ the orrery rings: x/y radius, tilt (rad), unused.
const ORRERY_RINGS: Array[Vector4] = [Vector4(48.0, 12.0, 0.22, 0.0), Vector4(34.0, 21.0, -0.55, 0.0),
	Vector4(58.0, 7.0, 0.08, 1.0)]
## ✱ rubble seed (the heaps are generated, same every run).
const RUBBLE_SEED := 9171

var mouth := Rect2(484, 116, 132, 186)
var floor_y := 300.0
var hole_c := Vector2(150, 10)
var hole_r := Vector2(122, 70)
var orrery_at := Vector2(372, 96)
var stone_a := Pal.BONE_1
var stone_b := Pal.BONE_0
var brass := Pal.BONE_2
var brass_hi := Pal.BONE_4
var brass_shadow := Pal.VOID_3
var chalk := Pal.BONE_4
## Perf (Q-T248, Ruins): the set is static and drawn once; only the turning planet lives on this child
## and redraws each frame.
var _planet: Node2D
var _t := 0.0
var _rubble: Array[PackedVector2Array] = []
var _rubble_tone: PackedFloat32Array = []


func configure(data: RuinsLookData) -> void:
	stone_a = data.stone_a
	stone_b = data.stone_b
	brass = data.brass
	brass_hi = data.brass_hi
	brass_shadow = data.brass_shadow
	chalk = data.chalk
	queue_redraw()


func set_layout(p_mouth: Rect2, p_floor_y: float, p_hole_c: Vector2, p_hole_r: Vector2) -> void:
	mouth = p_mouth
	floor_y = p_floor_y
	hole_c = p_hole_c
	hole_r = p_hole_r
	_build_rubble()
	queue_redraw()


func set_time(t: float) -> void:
	_t = t
	if _planet != null:
		_planet.queue_redraw()


## Redraw everything (layout or colours changed).
func _notification(what: int) -> void:
	if what == NOTIFICATION_DRAW and _planet != null:
		_planet.queue_redraw()


func pilaster_xs() -> PackedFloat32Array:
	return PackedFloat32Array([40.0, 230.0, mouth.position.x - 26.0])


func in_hole(p: Vector2) -> bool:
	var q := (p - hole_c) / hole_r
	return q.length() < 1.04


func _ready() -> void:
	if _rubble.is_empty():
		_build_rubble()
	_planet = Node2D.new()
	_planet.name = "OrreryPlanet"
	add_child(_planet)
	_planet.draw.connect(_draw_planet)


func _build_rubble() -> void:
	_rubble.clear()
	_rubble_tone.clear()
	var rng := RandomNumberGenerator.new()
	rng.seed = RUBBLE_SEED
	# heaps: under the tear, the left corner, right of the mouth
	var heaps: Array[Vector3] = [Vector3(hole_c.x - 30.0, 46.0, 9.0), Vector3(8.0, 30.0, 6.0),
		Vector3(mouth.end.x + 14.0, 22.0, 5.0)]
	for h in heaps:
		for i in int(h.z):
			var cx := h.x + rng.randf_range(-h.y, h.y)
			var spread := 1.0 - absf(cx - h.x) / h.y
			var r := rng.randf_range(4.0, 9.0) * (0.6 + 0.6 * spread)
			var cy := floor_y + 4.0 - r * 0.5 - spread * rng.randf_range(0.0, 8.0)
			var poly := PackedVector2Array()
			var n := rng.randi_range(5, 7)
			for k in n:
				var a := TAU * float(k) / float(n) + rng.randf_range(-0.3, 0.3)
				var rr := r * rng.randf_range(0.7, 1.1)
				poly.append(Vector2(cx + cos(a) * rr, cy + sin(a) * rr * 0.62))
			_rubble.append(poly)
			_rubble_tone.append(rng.randf())


func _draw() -> void:
	_draw_ribs()
	_draw_pilasters()
	_draw_chalk()
	_draw_door_tracks()
	_draw_telescope()
	_draw_orrery()
	_draw_fallen_rib()
	_draw_rubble()


# --- vault ---------------------------------------------------------------------------------

func _draw_ribs() -> void:
	var xs := pilaster_xs()
	for i in xs.size() - 1:
		var a := Vector2(xs[i], 64.0)
		var b := Vector2(xs[i + 1], 64.0)
		var apex := Vector2((a.x + b.x) * 0.5, -36.0)
		_rib(a, Vector2(a.x, apex.y + 30.0), apex)
		_rib(b, Vector2(b.x, apex.y + 30.0), apex)
		# a diagonal (transverse) rib, foreshortened
		_rib(a, Vector2(lerpf(a.x, b.x, 0.55), 10.0), Vector2(b.x - 10.0, -60.0))
	# the outer rib over the mouth
	var m0 := Vector2(xs[xs.size() - 1], 64.0)
	_rib(m0, Vector2(m0.x + 30.0, -10.0), Vector2(660.0, -20.0))


func _rib(p0: Vector2, c: Vector2, p1: Vector2) -> void:
	var seg := PackedVector2Array()
	var steps := 28
	for k in steps + 1:
		var t := float(k) / float(steps)
		var p := (1.0 - t) * (1.0 - t) * p0 + 2.0 * (1.0 - t) * t * c + t * t * p1
		if in_hole(p):
			_rib_stroke(seg, true)
			seg = PackedVector2Array()
		else:
			seg.append(p)
	_rib_stroke(seg, false)


func _rib_stroke(seg: PackedVector2Array, broken_end: bool) -> void:
	if seg.size() < 2:
		return
	draw_polyline(seg, brass_shadow, 7.0, true)
	draw_polyline(seg, stone_a.lerp(brass, 0.5), 5.0, true)
	var hi := PackedVector2Array()
	for p in seg:
		hi.append(p + Vector2(-1.2, -0.6))
	draw_polyline(hi, brass_hi.lerp(brass, 0.4), 1.0, true)
	if broken_end:
		# a snapped end: a ragged wedge, not a clean cut
		var e := seg[seg.size() - 1]
		var d := (e - seg[seg.size() - 2]).normalized()
		var n := Vector2(-d.y, d.x)
		draw_colored_polygon(PackedVector2Array([e + n * 3.5, e + d * 4.0 + n * 1.0, e + d * 1.5, e + d * 3.0 - n * 2.0,
			e - n * 3.5]), stone_a.lerp(brass, 0.5))


func _draw_pilasters() -> void:
	for x in pilaster_xs():
		var top := 60.0
		var w := 20.0
		var body := Rect2(x - w * 0.5, top, w, floor_y - top)
		draw_rect(body, stone_a.lerp(stone_b, 0.25))
		draw_rect(Rect2(body.position.x, top, 3.0, body.size.y), stone_a.lightened(0.12))
		draw_rect(Rect2(body.end.x - 4.0, top, 4.0, body.size.y), stone_b.darkened(0.15))
		# capital and base
		draw_rect(Rect2(x - w * 0.5 - 4.0, top - 6.0, w + 8.0, 8.0), stone_a)
		draw_rect(Rect2(x - w * 0.5 - 4.0, top - 6.0, w + 8.0, 1.5), brass_hi.lerp(brass, 0.5))
		draw_rect(Rect2(x - w * 0.5 - 3.0, floor_y - 9.0, w + 6.0, 9.0), stone_a.lerp(stone_b, 0.4))
		# riveted brass bands
		for by in [130.0, 210.0]:
			draw_rect(Rect2(x - w * 0.5 - 1.0, by, w + 2.0, 4.0), brass)
			draw_line(Vector2(x - w * 0.5 - 1.0, by), Vector2(x + w * 0.5 + 1.0, by), brass_hi, 0.8)
			for r in 3:
				draw_circle(Vector2(x - w * 0.5 + 3.0 + r * 7.0, by + 2.0), 0.7, brass_shadow)


# --- observatory pieces ---------------------------------------------------------------------

func _draw_telescope() -> void:
	# a great refractor on a cast pier, aimed at the tear in the vault
	var pier_x := hole_c.x - 2.0
	var pivot := Vector2(pier_x, floor_y - 66.0)
	var pier := PackedVector2Array([Vector2(pier_x - 10.0, floor_y), Vector2(pier_x - 5.0, pivot.y + 6.0),
		Vector2(pier_x + 5.0, pivot.y + 6.0), Vector2(pier_x + 10.0, floor_y)])
	draw_colored_polygon(pier, brass_shadow.lerp(brass, 0.35))
	draw_line(pier[0], pier[1], brass_hi.lerp(brass, 0.5), 1.0, true)
	var dir := (hole_c + Vector2(-46.0, 24.0) - pivot).normalized()
	var n := Vector2(-dir.y, dir.x)
	var front := pivot + dir * 92.0
	var back := pivot - dir * 26.0
	var tube := PackedVector2Array([back + n * 4.0, front + n * 6.0, front - n * 6.0, back - n * 4.0])
	draw_colored_polygon(tube, brass)
	draw_line(back + n * 4.0, front + n * 6.0, brass_hi, 1.0, true)
	draw_line(back - n * 4.0, front - n * 6.0, brass_shadow, 1.5, true)
	# dew cap and bands
	draw_colored_polygon(PackedVector2Array([front + n * 7.0, front + dir * 12.0 + n * 7.5, front + dir * 12.0 - n * 7.5,
		front - n * 7.0]), brass.lerp(brass_shadow, 0.3))
	for k in [0.15, 0.5, 0.82]:
		var p := back.lerp(front, k)
		draw_line(p + n * 6.5, p - n * 6.5, brass_hi.lerp(brass, 0.3), 1.2, true)
	# the objective: a glass disc catching the Aether's light (PHOS = glass)
	draw_line(front + dir * 12.0 + n * 6.0, front + dir * 12.0 - n * 6.0, Pal.PHOS_2, 1.5, true)
	# eyepiece and the declination wheel
	draw_line(back, back - dir * 6.0 + n * 2.0, brass, 2.0, true)
	draw_arc(pivot, 7.0, 0.0, TAU, 20, brass_hi.lerp(brass, 0.5), 1.0, true)
	draw_circle(pivot, 2.0, brass_shadow)


func _draw_orrery() -> void:
	# a broken orrery hanging from the vault on a rod; one ring still turns (very slowly)
	var c := orrery_at
	draw_line(Vector2(c.x, 0.0), c + Vector2(0, -8.0), brass_shadow.lerp(brass, 0.5), 1.5)
	var rings := ORRERY_RINGS
	for i in rings.size():
		var r := rings[i]
		var start := 0.0
		var span := TAU
		if i == 1:
			start = 0.4
			span = TAU * 0.78   # snapped ring
		if i == 2:
			start = 2.2
			span = TAU * 0.62
		var pts := PackedVector2Array()
		var steps := 48
		for k in steps + 1:
			var a := start + span * float(k) / float(steps)
			var e := Vector2(cos(a) * r.x, sin(a) * r.y).rotated(r.z)
			pts.append(c + e)
		draw_polyline(pts, brass_shadow, 2.4, true)
		draw_polyline(pts, brass, 1.2, true)
		if i == 2:
			# the broken end sags: a short bent length hanging down
			var e2 := pts[pts.size() - 1]
			draw_line(e2, e2 + Vector2(3.0, 16.0), brass, 1.2, true)
		# a planet on each ring (glass; PHOS = glass); the turning one is drawn by _draw_planet
		if i == 0:
			continue
		var pa := 1.1 + float(i) * 2.0
		if i == 1 and fposmod(pa - start, TAU) > span:
			pa = start + span * 0.5
		var pp := c + Vector2(cos(pa) * r.x, sin(pa) * r.y).rotated(r.z)
		var pr := [2.6, 1.9, 3.2][i] as float
		draw_circle(pp, pr, Pal.PHOS_1)
		draw_arc(pp, pr, -2.2, -0.6, 6, Pal.PHOS_3, 0.8, true)
	# the centre: a dull brass sun, cold (its light is long gone)
	draw_circle(c, 6.0, brass_shadow.lerp(brass, 0.4))
	draw_arc(c, 6.0, -2.6, -0.9, 10, brass_hi, 1.0, true)


## The one planet that still turns (innermost ring), on its own small canvas item.
func _draw_planet() -> void:
	var r := ORRERY_RINGS[0]
	var pa := TAU * fposmod(_t / ORRERY_TURN_S, 1.0)
	var pp := orrery_at + Vector2(cos(pa) * r.x, sin(pa) * r.y).rotated(r.z)
	_planet.draw_circle(pp, 2.6, Pal.PHOS_1)
	_planet.draw_arc(pp, 2.6, -2.2, -0.6, 6, Pal.PHOS_3, 0.8, true)


func _draw_fallen_rib() -> void:
	# a length of rib fallen from the tear, lying across the rubble
	var a := Vector2(hole_c.x - 72.0, floor_y - 2.0)
	var b := Vector2(hole_c.x + 4.0, floor_y - 20.0)
	draw_line(a, b, brass_shadow, 7.0, true)
	draw_line(a, b, stone_a.lerp(brass, 0.5), 5.0, true)
	draw_line(a + Vector2(0, -1.5), b + Vector2(0, -1.5), brass_hi.lerp(brass, 0.4), 1.0, true)


func _draw_rubble() -> void:
	for i in _rubble.size():
		var poly := _rubble[i]
		var tone := _rubble_tone[i]
		draw_colored_polygon(poly, stone_b.lerp(stone_a, tone))
		# the top edge catches light
		var top := PackedVector2Array()
		for p in poly:
			if p.y < poly[0].y + 1.0 or p.y < _centroid(poly).y:
				top.append(p)
		if top.size() >= 2:
			draw_polyline(top, stone_a.lightened(0.15), 0.8, true)


static func _centroid(poly: PackedVector2Array) -> Vector2:
	var s := Vector2.ZERO
	for p in poly:
		s += p
	return s / maxf(float(poly.size()), 1.0)


func _draw_door_tracks() -> void:
	# the hangar's brass door tracks up both jambs; the doors are long gone
	for x in [mouth.position.x - 5.0, mouth.end.x + 5.0]:
		draw_line(Vector2(x, mouth.position.y + mouth.size.y * 0.35), Vector2(x, floor_y), brass_shadow, 3.0)
		draw_line(Vector2(x, mouth.position.y + mouth.size.y * 0.35), Vector2(x, floor_y), brass, 1.4)
		for k in 6:
			var y := lerpf(mouth.position.y + mouth.size.y * 0.4, floor_y - 6.0, float(k) / 5.0)
			draw_circle(Vector2(x, y), 0.8, brass_hi)


# --- chalk ---------------------------------------------------------------------------------

func _draw_chalk() -> void:
	var ch := Color(chalk, 0.5)
	var faint := Color(chalk, 0.28)
	# a star chart: a ruled circle with the ecliptic and a few marked stars (left bay)
	var sc := Vector2(104.0, 214.0)
	draw_arc(sc, 20.0, 0.0, TAU, 40, ch, 0.8, true)
	draw_arc(sc, 13.0, 0.3, TAU - 0.4, 30, faint, 0.6, true)
	draw_line(sc + Vector2(-24, 6), sc + Vector2(24, -6), faint, 0.6, true)
	for s: Vector2 in [Vector2(-8, -9), Vector2(6, -14), Vector2(11, 4), Vector2(-3, 10), Vector2(-14, 2)]:
		draw_line(sc + s - Vector2(1.5, 0), sc + s + Vector2(1.5, 0), ch, 0.7)
		draw_line(sc + s - Vector2(0, 1.5), sc + s + Vector2(0, 1.5), ch, 0.7)
	# orbit sketch: two ellipses and a long ruled line (an old calculation)
	var oc := Vector2(190.0, 168.0)
	_ellipse(oc, Vector2(26, 9), -0.2, faint)
	_ellipse(oc + Vector2(4, 2), Vector2(16, 5), -0.2, faint)
	draw_line(Vector2(80.0, 246.0), Vector2(196.0, 238.0), faint, 0.6, true)
	# old tallies in gates of five, on the right bay (counted nights)
	var tx := 292.0
	for gate in 4:
		var gx := tx + gate * 16.0
		for k in 4:
			draw_line(Vector2(gx + k * 3.0, 206.0), Vector2(gx + k * 3.0 + 0.6, 219.0), ch, 0.8)
		if gate < 3:
			draw_line(Vector2(gx - 2.0, 217.0), Vector2(gx + 11.0, 207.0), ch, 0.8)
	# a chalk arrow on the stone near the mouth, pointing out (someone marked the way once)
	var ax := mouth.position.x - 48.0
	draw_line(Vector2(ax, 262.0), Vector2(ax + 16.0, 262.0), faint, 0.8)
	draw_line(Vector2(ax + 16.0, 262.0), Vector2(ax + 11.0, 258.5), faint, 0.8)
	draw_line(Vector2(ax + 16.0, 262.0), Vector2(ax + 11.0, 265.5), faint, 0.8)


func _ellipse(c: Vector2, r: Vector2, rot: float, col: Color) -> void:
	var pts := PackedVector2Array()
	for k in 33:
		var a := TAU * float(k) / 32.0
		pts.append(c + Vector2(cos(a) * r.x, sin(a) * r.y).rotated(rot))
	draw_polyline(pts, col, 0.6, true)
