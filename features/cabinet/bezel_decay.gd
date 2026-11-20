class_name BezelDecay
extends Control
## The printed bezel wearing out (ART-001 §12.7b; WARP-001 W0-07 the Decay, W0-11 Wear). A native-resolution
## overlay on the Rig, drawn after the Hud so it lies on the print, never on the screen hole (the CRT and
## the registers own the screen). Subtract-only in spirit: bleach takes the ink's colour away, the glass
## smears, and where the print breaks there is nothing behind it.
##
## The cursed turn's damage (PM art direction 2026-11-20, Fable review item 3; TECH-001 Q-T262a): the print does
## not glow, it BREAKS. Three clustered sites, never an even scatter, sized 1 : ½ : ¼, each growing outward from
## the screen's edge: the art glass cracks in radial hairlines, the print blisters and lifts (a curled flap of
## paper casting a small shadow), and where it has gone there is a true-black void edged with one thin phosphor
## line (the screen's own light, a colour the print does not own); through the biggest void the Aether fog is
## glimpsed, cold, as through a window. Nothing here moves but the slow one-way growth: no drift, no pulse.
##
## The printed eye (N4, PM 2026-11-20): it goes FIRST, as an ABSENCE: a ragged, pupil-less hole in the print,
## flat true black (the entity's shadow), set off its slit, edged only by torn ink. No iris, no highlight, no
## glow, no lid: the hole has its final shape from the start and only darkens (the ink flaking away), never opens.
##
## The CRT's last line (PM 2026-11-20): when the picture squeezes to its line, the line throws a brief white bar
## across the bezel's inner edges and the control strip (`flash`: one rise and fall; CabinetDecay keeps it at 0
## under photosensitivity / reduced motion, where the picture fades instead of collapsing).

@export var hole: Control              ## the ArcadeScreen: its rect is the screen hole, left untouched
@export var rig: ScreenRig             ## the area to wear: rig.bezel_rect() (the whole window in rig units; the Rig itself has no size)

var bleach := 0.0:                     ## 0..1 ink saturation lost, worst at the outer edges
	set(v):
		bleach = v
		_redraw()
var smear := 0.0:                      ## 0..1 the smoked glass thickening at the hole's edge
	set(v):
		smear = v
		_redraw()
var light := 0.0:                      ## 0..1 the phosphor edges and the fog window's brightness
	set(v):
		light = v
		_redraw()
var grow := 0.0:                       ## 0..1 how far the damage has spread (and the eye's absence darkened)
	set(v):
		grow = v
		_redraw()
var fade := 1.0:                       ## 1 → 0 as the bezel peels away after the tear
	set(v):
		fade = v
		_redraw()
var flash := 0.0:                      ## 0..1 the CRT's last line thrown across the bezel's inner edges and the control strip
	set(v):
		flash = v
		_redraw()
var line_uv := 0.5                     ## the last line's height in the screen hole (0 top … 1 bottom: the collapse focus)
var still := false                     ## reduced motion / photosensitivity (nothing here moves anyway; kept for the wiring)

const SITE_R := 26.0                   ## ✱ px (rig units), the biggest site's main void at full spread
const RIM_POINTS := 56                 ## ✱ vertices round a void edge (torn-paper detail)
const SMEAR_W := 16.0                  ## ✱ px, the smear band around the hole
const EDGE_GAP := 1.5                  ## ✱ px, voids start this far outside the screen hole (they never cover the tube)
const EYE_LEAD := 2.4                  ## ✱ the eye's absence darkens this many times faster than `grow` (it leads)
const EYE_SCALE := 0.9                 ## ✱ the hole's radius as a share of the wear origin's SMALLER side (the band's height): it lands on the band, it never swallows the world
const EYE_OFFSET := Vector2(0.22, 0.14)   ## ✱ the hole sits off the slit's centre (share of its radius): never concentric
const FLASH_SPILL := 22.0              ## ✱ px, how far the last line's bar spills onto the bezel either side of the hole
const SEED := 1983                    ## ✱ fixed: the same damage every time (deterministic captures)

## The three sites: [edge, share down the hole, size scale, hairline cracks, satellite voids]. Sizes 1 : ½ : ¼.
const SITES: Array = [
	[&"right", 0.30, 1.0, 9, 3],       # the focus side of the swelling glass: the worst
	[&"left", 0.70, 0.5, 6, 2],
	[&"right", 0.84, 0.25, 4, 1],
]

var _glow: Control                     ## additive child: the phosphor edges, the fog window, the last line
var _sites: Array[Dictionary] = []


func _ready() -> void:
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	set_anchors_preset(Control.PRESET_FULL_RECT)
	_glow = Control.new()
	_glow.name = "Glow"
	_glow.mouse_filter = Control.MOUSE_FILTER_IGNORE
	var m := CanvasItemMaterial.new()
	m.blend_mode = CanvasItemMaterial.BLEND_MODE_ADD
	_glow.material = m
	add_child(_glow)
	_glow.draw.connect(_draw_glow)


func _redraw() -> void:
	queue_redraw()
	if _glow != null:
		_glow.queue_redraw()


## The printed sheet in our (= the Rig's) units: the two columns either side of the hole, full height.
## Never the room beyond the cabinet (the window margins at wide aspects).
func area() -> Rect2:
	var full := rig.bezel_rect() if rig != null else Rect2(Vector2.ZERO, size)
	if hole == null:
		return full
	var x0 := maxf(full.position.x, hole.position.x - CabinetBezel.SIDE)
	var x1 := minf(full.end.x, hole.position.x + hole.size.x + CabinetBezel.SIDE)
	return Rect2(x0, full.position.y, x1 - x0, full.size.y)


func hole_rect() -> Rect2:
	if hole == null:
		return CabinetBezel.hole()
	return Rect2(hole.position, hole.size)


# --- the three damage sites ---------------------------------------------------------------------------

## The sites, built once from the hole: {origin, n (outward normal), t (along the edge), scale, voids, cracks}.
## Each void: {r, off (t, n shares of the site radius), seed, rim, mx (its largest rim factor)}.
func sites() -> Array[Dictionary]:
	if not _sites.is_empty():
		return _sites
	var h := hole_rect()
	for i in SITES.size():
		var row: Array = SITES[i]
		var right := (row[0] as StringName) == &"right"
		var n := Vector2.RIGHT if right else Vector2.LEFT
		var origin := Vector2(h.end.x + EDGE_GAP if right else h.position.x - EDGE_GAP, h.position.y + h.size.y * float(row[1]))
		var sc := float(row[2])
		var r0 := SITE_R * sc
		var rng := RandomNumberGenerator.new()
		rng.seed = SEED + 101 * (i + 1)
		var voids: Array[Dictionary] = []
		for v in 1 + int(row[4]):
			var vs := SEED + 101 * (i + 1) + 17 * v
			var rim := BezelDecay.rim_profile(vs, RIM_POINTS, 1.0 if v == 0 else 1.3)
			var mx := 0.0
			for f in rim:
				mx = maxf(mx, f)
			voids.append({
				"r": r0 if v == 0 else r0 * rng.randf_range(0.28, 0.5),
				"off": Vector2.ZERO if v == 0 else Vector2.from_angle(rng.randf_range(-1.35, 1.35)) * rng.randf_range(1.25, 1.65),
				"seed": vs,
				"rim": rim,
				"mx": mx,
			})
		var cracks: Array[PackedVector2Array] = []
		for c in int(row[3]):
			var ang := n.angle() + rng.randf_range(-1.3, 1.3)
			var dir := Vector2.from_angle(ang)
			var perp := Vector2(-dir.y, dir.x)
			var length := r0 * rng.randf_range(1.6, 3.6) + 6.0
			var pts := PackedVector2Array()
			for m in 6:
				var u := float(m) / 5.0
				pts.append(origin + dir * length * u + perp * (0.0 if m == 0 else rng.randf_range(-1.6, 1.6)))
			cracks.append(pts)
		_sites.append({"origin": origin, "n": n, "t": Vector2(0.0, 1.0), "scale": sc, "r0": r0, "voids": voids, "cracks": cracks, "order": i})
	return _sites


## How far site `s` has spread (0..1): the biggest leads, the others follow.
func site_k(s: Dictionary) -> float:
	if grow <= 0.0:
		return 0.0
	return clampf(grow * 1.45 - float(s["order"]) * 0.14, 0.0, 1.0)


## A void's centre at spread `k`. The main void starts at the screen's edge and moves outward as it grows, so its
## inner side never crosses into the hole (its innermost rim point stays at the site's origin, EDGE_GAP outside);
## the satellites sit round its outer side (`off`: x along the outward normal, y along the edge, in site radii).
func void_centre(s: Dictionary, v: Dictionary, k: float) -> Vector2:
	var n: Vector2 = s["n"]
	var t: Vector2 = s["t"]
	var r0: float = s["r0"]
	var voids: Array = s["voids"]
	var main: Dictionary = voids[0]
	var c := (s["origin"] as Vector2) + n * (r0 * k * float(main["mx"]) * 1.12)
	var off: Vector2 = v["off"]
	return c + (n * off.x + t * off.y) * r0 * k


func void_points(s: Dictionary, v: Dictionary, k: float, scale: float = 1.0) -> PackedVector2Array:
	return _ring(void_centre(s, v, k), v["rim"] as PackedFloat32Array, float(v["r"]) * k * scale)


func _ring(c: Vector2, rim: PackedFloat32Array, r: float) -> PackedVector2Array:
	var pts := PackedVector2Array()
	for i in rim.size():
		var ang := TAU * float(i) / float(rim.size())
		pts.append(c + Vector2(cos(ang), sin(ang)) * r * rim[i])
	return pts


# --- the eye's absence --------------------------------------------------------------------------------

## Where the cursed turn's wear-through starts, in rig units, from the bezel art's haunt anchors: `wear_origin`
## (#101 Fable pass, Q-T295: the ringed world's middle band; the world has no eye, N4), falling back to the old
## `eye` anchor when the art predates the rename. Rect2() when the art has neither.
static func eye_anchor() -> Rect2:
	var a: Dictionary = BezelArt.haunt_anchors()
	var v: Variant = a.get(&"wear_origin", a.get(&"eye", Rect2()))
	return v as Rect2 if v is Rect2 else Rect2()


## The eye's hole: a FIXED ragged shape (it never opens or moves: only its darkness grows). {} without an anchor.
static func eye_hole() -> Dictionary:
	var e := eye_anchor()
	if e.size.x <= 0.0:
		return {}
	var r := maxf(minf(e.size.x, e.size.y) * EYE_SCALE, 8.0)
	var es := SEED + 997
	return {
		"c": e.get_center() + EYE_OFFSET * r,
		"r": r,
		"seed": es,
		"rim": BezelDecay.rim_profile(es, RIM_POINTS, 1.7),
	}


## 0..1 how dark the eye's absence is: it leads every other site, and is nothing before the Decay.
func eye_k() -> float:
	if grow <= 0.0:
		return 0.0
	return clampf(grow * EYE_LEAD, 0.0, 1.0)


func eye_points(scale: float = 1.0) -> PackedVector2Array:
	var e := BezelDecay.eye_hole()
	if e.is_empty():
		return PackedVector2Array()
	return _ring(e["c"] as Vector2, e["rim"] as PackedFloat32Array, float(e["r"]) * scale)


## A torn edge as radius factors round the circle: low-frequency noise for the overall shape (`rough` scales
## it), high-frequency jitter for paper fibre, and a few long thin tears. Unique per seed, deterministic.
static func rim_profile(seed: int, n: int, rough: float = 1.0) -> PackedFloat32Array:
	var noise := FastNoiseLite.new()
	noise.seed = seed
	noise.noise_type = FastNoiseLite.TYPE_SIMPLEX
	noise.frequency = 0.9
	var rng := RandomNumberGenerator.new()
	rng.seed = seed * 7 + 3
	var out := PackedFloat32Array()
	for i in n:
		var ang := TAU * float(i) / float(n)
		var v := 0.78 + 0.32 * rough * noise.get_noise_2d(cos(ang) * 1.6, sin(ang) * 1.6)
		v += rng.randf_range(-0.045, 0.045)                     # fibre
		if rng.randf() < 0.06:
			v *= rng.randf_range(1.12, 1.3)                      # a longer tear
		out.append(maxf(v, 0.35))
	return out


# --- the last line ------------------------------------------------------------------------------------

## The last line's height in rig units.
func line_y() -> float:
	var h := hole_rect()
	return h.position.y + h.size.y * line_uv


# --- drawing ------------------------------------------------------------------------------------------

func _draw() -> void:
	var r := area()
	if fade <= 0.0 or r.size.x <= 0.0:
		return
	var h := hole_rect()
	var ink := Pal.BONE_5
	# bleach: four quads from the outer edges inward (strongest at the edge, gone by the hole)
	if bleach > 0.0:
		var a := Color(ink, 0.55 * bleach * fade)
		var z := Color(ink, 0.0)
		var x0 := r.position.x
		var x1 := r.end.x
		var y0 := r.position.y
		var y1 := r.end.y
		_quad(Vector2(x0, y0), Vector2(h.position.x, y0), Vector2(h.position.x, y1), Vector2(x0, y1), a, z, z, a)
		_quad(Vector2(h.end.x, y0), Vector2(x1, y0), Vector2(x1, y1), Vector2(h.end.x, y1), z, a, a, z)
		_quad(Vector2(h.position.x, y0), Vector2(h.end.x, y0), Vector2(h.end.x, h.position.y), Vector2(h.position.x, h.position.y), a, a, z, z)
		_quad(Vector2(h.position.x, h.end.y), Vector2(h.end.x, h.end.y), Vector2(h.end.x, y1), Vector2(h.position.x, y1), z, z, a, a)
	# the smoked glass thickening round the hole
	if smear > 0.0:
		var s := Color(Pal.VOID_0, 0.45 * smear * fade)
		var o := Color(Pal.VOID_0, 0.0)
		var g := h.grow(SMEAR_W)
		_quad(g.position, Vector2(g.end.x, g.position.y), Vector2(h.end.x, h.position.y), h.position, o, o, s, s)
		_quad(Vector2(h.position.x, h.end.y), Vector2(h.end.x, h.end.y), g.end, Vector2(g.position.x, g.end.y), s, s, o, o)
		_quad(g.position, h.position, Vector2(h.position.x, h.end.y), Vector2(g.position.x, g.end.y), o, s, s, o)
		_quad(Vector2(h.end.x, h.position.y), Vector2(g.end.x, g.position.y), g.end, h.end, s, o, o, s)
	if grow <= 0.0:
		return
	_draw_eye()
	for s in sites():
		var k := site_k(s)
		if k > 0.0:
			_draw_site(s, k)


## The eye: torn ink round a flat true-black hole that only darkens. Nothing else (no glow child entry).
func _draw_eye() -> void:
	var ek := eye_k()
	var e := BezelDecay.eye_hole()
	if ek <= 0.0 or e.is_empty():
		return
	var c: Vector2 = e["c"]
	_fan(c, eye_points(1.12), Color(Pal.BONE_4, 0.38 * ek * fade))       # the torn ink's paper edge
	_fan(c, eye_points(1.0), Color(Pal.NULL, ek * fade))                   # the absence: flat, true black
	_draw_flecks(c, float(e["r"]), int(e["seed"]), ek, 10)


func _draw_site(s: Dictionary, k: float) -> void:
	var sc: float = s["scale"]
	# the art glass first, behind nothing: hairline cracks running out from the screen's edge (drawn to k)
	for pts: PackedVector2Array in s["cracks"]:
		var part := _partial(pts, k)
		if part.size() < 2:
			continue
		draw_polyline(part, Color(Pal.NULL, 0.6 * fade), 0.55)
		var lit := PackedVector2Array()
		for q in part:
			lit.append(q + Vector2(-0.5, -0.5))
		draw_polyline(lit, Color(Pal.BONE_5, 0.32 * fade), 0.4)
	var voids: Array[Dictionary] = []
	voids.assign(s["voids"])
	for v in voids:
		var c := void_centre(s, v, k)
		var r := float(v["r"]) * k
		if r < 0.4:
			continue
		_fan(c, void_points(s, v, k, 1.1), Color(Pal.BONE_4, 0.3 * fade))  # torn paper edge
		_fan(c, void_points(s, v, k), Color(Pal.NULL, fade))                 # where the print has gone: true black
		_draw_blisters(c, r, int(v["seed"]), k, sc, s)
		_draw_flecks(c, r, int(v["seed"]), k, 8, s)
	# the print lifting off the main void's outer side: a curled flap of paper, its back showing, with its shadow
	var main: Dictionary = voids[0]
	if k > 0.35:
		var rim := void_points(s, main, k)
		var c0 := void_centre(s, main, k)
		var n: Vector2 = s["n"]
		var best := 0
		for i in rim.size():
			if (rim[i] - c0).dot(n) > (rim[best] - c0).dot(n):
				best = i
		var a := rim[(best - 4 + rim.size()) % rim.size()]
		var b := rim[(best + 4) % rim.size()]
		var lift := clampf((k - 0.35) / 0.65, 0.0, 1.0)
		var tip := rim[best].lerp(c0, 0.5 * lift)
		var flap := PackedVector2Array([a, b, tip])
		var sh := Vector2(1.2, 1.7) * maxf(sc, 0.5)
		_tri(a + sh, b + sh, tip + sh * 1.6, Color(Pal.NULL, 0.5 * fade))
		_tri(flap[0], flap[1], flap[2], Color(Pal.BONE_3, 0.9 * fade))
		draw_line(a, b, Color(Pal.BONE_5, 0.5 * fade), 0.5)


## The first `k` of a polyline (cracks run, they never jump).
static func _partial(pts: PackedVector2Array, k: float) -> PackedVector2Array:
	var out := PackedVector2Array()
	if pts.size() < 2 or k <= 0.0:
		return out
	var x := k * float(pts.size() - 1)
	var whole := int(floor(x))
	for i in mini(whole + 1, pts.size()):
		out.append(pts[i])
	if whole < pts.size() - 1:
		out.append(pts[whole].lerp(pts[whole + 1], x - float(whole)))
	return out


## Blisters: the print raised in bubbles near the void (a lit top, a shadowed foot). Fixed per void.
func _draw_blisters(c: Vector2, r: float, seed: int, k: float, sc: float, s: Dictionary) -> void:
	var rng := RandomNumberGenerator.new()
	rng.seed = seed * 29
	for i in 5:
		var ang := rng.randf() * TAU
		var d := rng.randf_range(1.2, 1.6)
		var q := c + Vector2.from_angle(ang) * r * d
		var br := rng.randf_range(0.8, 2.0) * maxf(sc, 0.5) * k
		if br < 0.3:
			continue
		if not _outside(q, br + 1.0, s):
			continue
		draw_circle(q + Vector2(0.5, 0.7), br, Color(Pal.NULL, 0.32 * fade))
		draw_circle(q, br, Color(Pal.BONE_3, 0.35 * fade))
		draw_circle(q + Vector2(-0.3, -0.35) * br, br * 0.45, Color(Pal.BONE_5, 0.4 * fade))


## Loose flecks of torn print just outside an edge (fixed per seed, so they never shimmer).
func _draw_flecks(c: Vector2, r: float, seed: int, k: float, n: int, s: Dictionary = {}) -> void:
	var rng := RandomNumberGenerator.new()
	rng.seed = seed * 13
	for i in n:
		var ang := rng.randf() * TAU
		var d := rng.randf_range(1.08, 1.45)
		var q := c + Vector2.from_angle(ang) * r * d
		var col := Color(Pal.BONE_4, 0.5 * fade * k) if rng.randf() < 0.6 else Color(Pal.NULL, 0.7 * fade * k)
		if not _outside(q, 1.5, s):
			continue
		draw_rect(Rect2(q, Vector2.ONE * rng.randf_range(0.6, 1.4)), col)


## Additive: one thin phosphor line round each void, the fog window in the biggest, and the last line's bar.
## Never round the eye (it is an absence, edged only by torn ink).
func _draw_glow() -> void:
	if fade <= 0.0:
		return
	if light > 0.0 and grow > 0.0:
		for s in sites():
			var k := site_k(s)
			if k <= 0.0:
				continue
			var voids: Array[Dictionary] = []
			voids.assign(s["voids"])
			for v in voids:
				if float(v["r"]) * k < 0.4:
					continue
				var rim := void_points(s, v, k)
				rim.append(rim[0])
				_glow.draw_polyline(rim, Color(Pal.PHOS_3, 0.6 * light * fade), 0.6)
			if int(s["order"]) == 0:
				_fog_window(s, voids[0], k)
	if flash > 0.0:
		_draw_last_line()


## Through the biggest void, cold Aether fog as through a window: a pale radial haze, never the print's purple.
func _fog_window(s: Dictionary, v: Dictionary, k: float) -> void:
	var c := void_centre(s, v, k)
	var inner := void_points(s, v, k, 0.75)
	var pts := PackedVector2Array([c])
	pts.append_array(inner)
	var cols := PackedColorArray([Color(Pal.AETHER_4.lerp(Pal.AETHER_5, 0.5), 0.2 * light * fade * k)])
	var idx := PackedInt32Array()
	for i in inner.size():
		cols.append(Color(Pal.AETHER_5, 0.0))
		idx.append_array(PackedInt32Array([0, 1 + i, 1 + (i + 1) % inner.size()]))
	RenderingServer.canvas_item_add_triangle_array(_glow.get_canvas_item(), idx, pts, cols)


## The last line's bar: a thin white band at the line's height spilling onto the bezel either side of the hole,
## and the light it throws down across the control strip. Additive BONE_5, brief (CabinetDecay.last_line_k).
func _draw_last_line() -> void:
	var h := hole_rect()
	var y := line_y()
	var a := Color(Pal.BONE_5, 0.85 * flash * fade)
	var z := Color(Pal.BONE_5, 0.0)
	var halo := Color(Pal.BONE_5, 0.25 * flash * fade)
	for side: float in [-1.0, 1.0]:
		var x_in := h.position.x if side < 0.0 else h.end.x
		var x_out := x_in + side * FLASH_SPILL
		_glow.draw_polygon(PackedVector2Array([Vector2(x_in, y - 1.0), Vector2(x_out, y - 1.0), Vector2(x_out, y + 1.0), Vector2(x_in, y + 1.0)]), PackedColorArray([a, z, z, a]))
		_glow.draw_polygon(PackedVector2Array([Vector2(x_in, y - 5.0), Vector2(x_out, y - 5.0), Vector2(x_out, y + 5.0), Vector2(x_in, y + 5.0)]), PackedColorArray([halo, z, z, halo]))
	var p := CabinetBezel.control_panel()
	var top := Color(Pal.BONE_5, 0.45 * flash * fade)
	_glow.draw_polygon(PackedVector2Array([p.position, Vector2(p.end.x, p.position.y), Vector2(p.end.x, p.position.y + p.size.y * 0.6), Vector2(p.position.x, p.position.y + p.size.y * 0.6)]), PackedColorArray([top, top, z, z]))


## A filled star-shaped outline as an explicit triangle fan (never triangulated, so a torn fibre cannot fail).
func _fan(c: Vector2, rim: PackedVector2Array, col: Color) -> void:
	if rim.size() < 3:
		return
	var pts := PackedVector2Array([c])
	pts.append_array(rim)
	var idx := PackedInt32Array()
	var n := rim.size()
	for i in n:
		idx.append_array(PackedInt32Array([0, 1 + i, 1 + (i + 1) % n]))
	var cols := PackedColorArray()
	cols.resize(pts.size())
	cols.fill(col)
	RenderingServer.canvas_item_add_triangle_array(get_canvas_item(), idx, pts, cols)


func _quad(a: Vector2, b: Vector2, c: Vector2, d: Vector2, ca: Color, cb: Color, cc: Color, cd: Color) -> void:
	draw_polygon(PackedVector2Array([a, b, c, d]), PackedColorArray([ca, cb, cc, cd]))


## True when a mark at `q` (of reach `pad`) lies wholly on the site's side of its origin: off the screen hole.
static func _outside(q: Vector2, pad: float, s: Dictionary) -> bool:
	if s.is_empty():
		return true
	return (q - (s["origin"] as Vector2)).dot(s["n"] as Vector2) >= pad


## One triangle, never triangulated (a flap that is still nearly flat must not fail).
func _tri(a: Vector2, b: Vector2, c: Vector2, col: Color) -> void:
	RenderingServer.canvas_item_add_triangle_array(get_canvas_item(), PackedInt32Array([0, 1, 2]), PackedVector2Array([a, b, c]), PackedColorArray([col, col, col]))
