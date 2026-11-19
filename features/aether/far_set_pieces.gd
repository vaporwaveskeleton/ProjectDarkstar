class_name FarSetPieces
extends Node2D
## Retro-future Victorian far set pieces (ART-001 §15; pass 3): runtime vector in the far band,
## fogged by the bands in front of them and cropped by the frame. One silhouette family per tier so
## the tiers sort at a glance: T1 orrery armillary (rings round a small globe), T2 gaslit greenhouse
## ribs overgrown with spore fuzz, T3 drowned observatory dome and telescope, T4 the lamp-interior
## ribs (OrreryRibs, not here), T5 broken ring fragments drifting apart.
## Brass is BRASS: two-tone metal (look.brass body, BONE_4 highlight edge, VOID_3 shadow), never GAS
## (GAS stays the lantern's; T4's lamp-interior tarnish lives on OrreryRibs).
## The armillary rings INTERLEAVE with the crystal sphere's shell: this script runs twice — a back
## copy (`half` = BACK, drawn below the sphere layer) draws the far half of every ring, the front
## copy (`half` = FRONT, above it) draws the globe and the near halves. Pal colours from the look.

enum Half { BOTH, BACK, FRONT }

## ✱ pass 6: the T1 armillary's contrast (ring, bead and axis alpha multiplier; calmer than pass 5).
const ORRERY_CALM := 0.72

## Which halves of the armillary rings this copy draws (BACK sits below the sphere layer).
@export var half: Half = Half.BOTH
## ✱ orrery centre (layer px), ring radii, ellipse squash and tilt.
@export var orrery_centre: Vector2 = Vector2(500.0, 64.0)
@export var orrery_radii: PackedFloat32Array = PackedFloat32Array([90.0, 150.0, 220.0, 300.0])
@export var orrery_squash: float = 0.3
@export var orrery_tilt: float = -0.16
## ✱ radians per second of the innermost bead (outer beads slower).
@export var orrery_speed: float = 0.02
## ✱ opacity of the set pieces (they sit in the far band, behind the fog).
@export var fade: float = 0.22
## ✱ ring band width (layer px) of the innermost ring; outer rings are thinner (further).
@export var ring_width: float = 3.6
## ✱ how far each T5 fragment has drifted per second (layer px) and its slow spin (rad/s).
@export var fragment_drift: float = 0.6
@export var fragment_spin: float = 0.0015

var brass: Color = Pal.BONE_2
var brass_hi: Color = Pal.BONE_4
var brass_shadow: Color = Pal.VOID_3
## The T1 sun at the armillary's heart (pass 6): lit brass, never a dark disc.
var sun_body: Color = Pal.BONE_3
var sun_hi: Color = Pal.BONE_4
var silhouette: Color = Pal.VOID_2
var window: Color = Pal.BONE_4
var overgrowth: Color = Pal.PHOS_2
var show_orrery := false
var show_lattice := false
var show_dome := false
var show_greenhouse := false
var show_fragments := false
var _t := 0.0


func configure(look: AetherLook) -> void:
	brass = look.brass
	silhouette = look.fog_mid
	overgrowth = look.life_glow
	show_orrery = look.set_orrery_rings
	show_lattice = look.set_lattice
	show_dome = look.set_dome
	show_greenhouse = look.set_greenhouse
	show_fragments = look.set_ring_fragments
	queue_redraw()


func any_shown() -> bool:
	if half == Half.BACK:
		return show_orrery
	return show_orrery or show_lattice or show_dome or show_greenhouse or show_fragments


## Every colour this copy can draw with (tests: no GAS on the set pieces).
func colours_used() -> Array[Color]:
	return [brass, brass_hi, brass_shadow, silhouette, window, overgrowth, sun_body, sun_hi]


func set_time(t: float) -> void:
	_t = t
	if show_orrery or show_fragments:
		queue_redraw()


func _c(base: Color, a: float) -> Color:
	var c := base
	c.a = clampf(a * fade, 0.0, 1.0)
	return c


func _draw() -> void:
	if show_orrery:
		_draw_orrery()
	if half == Half.BACK:
		return
	if show_greenhouse:
		_draw_greenhouse(Vector2(420.0, 372.0), 230.0, 5)
	if show_lattice:
		_draw_lattice(Vector2(-60.0, 70.0), Vector2(760.0, 10.0), 9.0)
	if show_dome:
		_draw_dome(Vector2(96.0, 318.0), 112.0)
	if show_fragments:
		_draw_fragments()


func _ellipse_arc(c: Vector2, rx: float, ry: float, tilt: float, a0: float, a1: float, n: int) -> PackedVector2Array:
	var pts := PackedVector2Array()
	var rot := Transform2D(tilt, Vector2.ZERO)
	for i in n + 1:
		var a := lerpf(a0, a1, float(i) / float(n))
		pts.append(c + rot * Vector2(cos(a) * rx, sin(a) * ry))
	return pts


## One brass band along an elliptical arc: body, highlight edge (outer), engraved shadow (inner).
## `shadow` scales the dark engraved edge (0 = none: pass 6, T1 has nothing darker than its fog).
func _brass_arc(c: Vector2, rx: float, ry: float, tilt: float, a0: float, a1: float, w: float, alpha: float, shadow: float = 1.0) -> void:
	var n := maxi(int(absf(a1 - a0) * 40.0), 6)
	draw_polyline(_ellipse_arc(c, rx, ry, tilt, a0, a1, n), _c(brass, alpha), w, true)
	draw_polyline(_ellipse_arc(c, rx + w * 0.5, ry + w * 0.5 * (ry / maxf(rx, 1.0)), tilt, a0, a1, n), _c(brass_hi, alpha * 1.2), 1.0, true)
	if shadow > 0.0:
		draw_polyline(_ellipse_arc(c, rx - w * 0.5, ry - w * 0.5 * (ry / maxf(rx, 1.0)), tilt, a0, a1, n), _c(brass_shadow, alpha * 1.4 * shadow), 1.0, true)


## The armillary. Ring i: angles 0..PI are the near half (lower on screen), PI..TAU the far half.
## Pass 6 (G-2 tier sort): T1 must read as the most intact, and nothing in it is darker than the
## fog — a dark round centred object read as "something is watching". The globe is a LIT brass sun
## (BONE_3 body, BONE_4 soft highlight) and the rings are calmer (lower contrast, no dark edge).
func _draw_orrery() -> void:
	var rot := Transform2D(orrery_tilt, Vector2.ZERO)
	var back := half != Half.FRONT
	var front := half != Half.BACK
	if back:
		for i in orrery_radii.size():
			var r: float = orrery_radii[i]
			var depth := float(i) / float(maxi(orrery_radii.size() - 1, 1))
			# far halves: thinner, more fogged (the fog sits between us and them)
			_brass_arc(orrery_centre, r, r * orrery_squash, orrery_tilt, PI, TAU,
				ring_width * (1.0 - 0.45 * depth) * 0.8, (0.75 - 0.35 * depth) * 0.6 * ORRERY_CALM, 0.0)
	if not front:
		return
	# the axis and the globe the rings turn round
	draw_line(orrery_centre + rot * Vector2(0, -150), orrery_centre + rot * Vector2(0, 150), _c(brass, 0.6 * ORRERY_CALM), 1.5, true)
	# a small LIT brass sun (fogged): a soft BONE_4 bloom round a BONE_3 body, a lit cap, an
	# engraved equator in the body's own brass (never a dark disc)
	for k in 5:
		draw_circle(orrery_centre, 14.0 + 2.0 * float(5 - k), _c(sun_hi, 0.1))
	draw_circle(orrery_centre, 14.0, _c(sun_body, 1.0))
	draw_circle(orrery_centre + Vector2(-3.0, -3.5), 7.0, _c(sun_hi, 0.6))
	draw_polyline(_ellipse_arc(orrery_centre, 14.0, 4.0, orrery_tilt, 0.0, PI, 16), _c(brass, 0.9), 1.0, true)
	for i in orrery_radii.size():
		var r: float = orrery_radii[i]
		var ry := r * orrery_squash
		var depth := float(i) / float(maxi(orrery_radii.size() - 1, 1))
		_brass_arc(orrery_centre, r, ry, orrery_tilt, 0.0, PI, ring_width * (1.0 - 0.45 * depth), (0.95 - 0.35 * depth) * ORRERY_CALM, 0.0)
		# the planet bead rides the ring; drawn only while on the near half
		var a := fposmod(_t * orrery_speed / (1.0 + float(i)) + float(i) * 1.7, TAU)
		if a < PI:
			var bead := orrery_centre + rot * Vector2(cos(a) * r, sin(a) * ry)
			draw_circle(bead, 3.0 + float(i), _c(brass, ORRERY_CALM))
			draw_arc(bead, 3.0 + float(i), PI * 1.1, PI * 1.7, 12, _c(brass_hi, 1.2 * ORRERY_CALM), 1.0, true)


## T2: a gaslit greenhouse vault in the lower right — pointed glasshouse arches receding into the
## fog (each further arch smaller, higher, fainter), broken glazing bars between them, overgrown:
## spore fuzz clings to the ribs (a deterministic scatter of soft dots, the tier's life hue).
## Kept out of the play band: it frames the lantern, never crosses it.
func _draw_greenhouse(base: Vector2, width: float, arches: int) -> void:
	var rng := RandomNumberGenerator.new()
	rng.seed = 7071
	var prev := PackedVector2Array()
	for k in arches:
		var depth := float(k) / float(maxi(arches - 1, 1))
		var s := lerpf(1.0, 0.45, depth)
		var foot_l := base + Vector2(width * 0.55 * depth, -60.0 * depth)
		var w := width * s
		var h := 190.0 * s
		var pts := PackedVector2Array()
		for i in 25:
			var u := float(i) / 24.0
			# a pointed (gothic) arch: two curved sides meeting at the apex
			var side := -1.0 if u < 0.5 else 1.0
			var t := (u if u < 0.5 else 1.0 - u) * 2.0
			var x := w * 0.5 + side * w * 0.5 * (1.0 - t)
			var y := -h * pow(t, 0.6)   # steep at the feet, meeting at a point
			pts.append(foot_l + Vector2(x, y))
		var a := lerpf(0.9, 0.35, depth)
		draw_polyline(pts, _c(brass, a), lerpf(2.6, 1.2, depth), true)
		draw_polyline(pts, _c(brass_hi, a * 0.7), 1.0, true)
		# glazing bars to the previous arch, some panes fallen
		if prev.size() == pts.size():
			for i in range(2, 23, 4):
				if rng.randf() > 0.35:
					draw_line(prev[i], pts[i], _c(brass, a * 0.6), 1.0, true)
		prev = pts
		# overgrowth: spore fuzz on the lower half of the arch
		for f in 26:
			var i2 := rng.randi_range(0, 24)
			if absf(float(i2) - 12.0) < 5.0:
				continue
			var p := pts[i2] + Vector2(rng.randf_range(-3.5, 3.5), rng.randf_range(-3.0, 3.0))
			draw_circle(p, rng.randf_range(0.7, 2.2) * s, _c(overgrowth, rng.randf_range(0.4, 1.0) * a))
	# a few tiny warm windows deep inside (far below the lantern)
	for wi in 3:
		var p2 := base + Vector2(width * (0.3 + 0.18 * float(wi)), -30.0 - 22.0 * float(wi))
		draw_rect(Rect2(p2, Vector2(2.0, 2.5)), _c(window, 1.4))


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
	draw_arc(base, r - 1.5, PI * 1.08, PI * 1.45, 24, _c(brass_hi, 0.6), 1.0, true)
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


## T5: the armillary broken — arc fragments of the rings drifting apart from where they were, each
## turning slowly on its own, with a straight snapped end.
func _draw_fragments() -> void:
	var c0 := Vector2(330.0, 90.0)
	var rng := RandomNumberGenerator.new()
	rng.seed = 5150
	for i in 9:
		var r := rng.randf_range(120.0, 330.0)
		var a0 := rng.randf_range(0.0, TAU)
		var arc_len := rng.randf_range(0.25, 0.7)
		var mid := a0 + arc_len * 0.5
		var away := Vector2(cos(mid), sin(mid) * 0.35)
		var drift := away * (8.0 + fragment_drift * _t * rng.randf_range(0.6, 1.4))
		var spin := fragment_spin * _t * (1.0 if i % 2 == 0 else -1.0)
		var w := ring_width * rng.randf_range(0.5, 0.9)
		_brass_arc(c0 + drift, r, r * 0.32, -0.12 + spin, a0, a0 + arc_len, w, rng.randf_range(0.45, 0.85))
		# the snapped end: a short straight cut across the band
		var rot := Transform2D(-0.12 + spin, Vector2.ZERO)
		var e := c0 + drift + rot * Vector2(cos(a0 + arc_len) * r, sin(a0 + arc_len) * r * 0.32)
		var cut_dir := Vector2(cos(a0 + arc_len + 0.9), sin(a0 + arc_len + 0.9))
		draw_line(e - cut_dir * w, e + cut_dir * w, _c(brass_hi, 0.9), 1.0, true)
