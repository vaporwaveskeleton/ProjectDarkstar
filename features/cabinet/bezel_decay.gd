class_name BezelDecay
extends Control
## The printed bezel wearing out (ART-001 §12.7b; WARP-001 W0-07 the Decay, W0-11 Wear). A native-resolution
## overlay on the Rig, drawn after the Hud so it lies on the print, never on the screen hole (the CRT and
## the registers own the screen). Subtract-only in spirit: bleach takes the ink's colour away, the glass
## smears, and where the print wears through there is the Aether behind it, never wood, black or white.
##
## Worn-through patches (PM art note 2026-11-19): they are LIGHT, not paint. Each grows from a natural wear
## point (the columns' outer edges, the coin door, the HOW TO PLAY panel's corner, the top corners by the
## hole) with its own noise-driven, abraded, fibrous edge and flecks of loose print. Inside, the deep Aether
## fog; over it, an additive glow from warm amber (the lantern's GAS ramp) to violet (AETHER), brightest at a
## core that drifts slowly, so each patch is a window onto something alive. No flicker: the drift is slow and
## continuous, and under reduced motion / photosensitivity it holds still.

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
var light := 0.0:                      ## 0..1 brightness of the Aether light through worn patches
	set(v):
		light = v
		_redraw()
var grow := 0.0:                       ## 0..1 how far the worn patches have spread
	set(v):
		grow = v
		_redraw()
var fade := 1.0:                       ## 1 → 0 as the bezel peels away after the tear
	set(v):
		fade = v
		_redraw()
var still := false                     ## reduced motion / photosensitivity: the light behind holds still

const PATCH_R := 17.0                  ## ✱ px (rig units), a patch's mean radius when fully spread
const RIM_POINTS := 56                 ## ✱ vertices round a patch edge (fibrous detail)
const SMEAR_W := 16.0                  ## ✱ px, the smear band around the hole
const DRIFT_HZ := 0.07                 ## ✱ how fast the light behind a patch wanders (slow: never a pulse)
const DRIFT_R := 0.35                  ## ✱ how far the bright core wanders, as a share of the patch radius
const EYE_ORDER := -2.0                ## ✱ the eye's patch spreads before every other (patch_k: grow·1.7 − order·0.09)
const EYE_PATCH_SCALE := 0.5           ## ✱ the eye patch's radius as a share of the printed eye's larger side: it eats the eye, never traces it
const SEED := 1983                    ## ✱ fixed: the same patches every time (deterministic captures)

var _glow: Control                     ## additive child: the light itself
var _patches: Array[Dictionary] = []   ## {c: Vector2, r: float, order: float, stretch: Vector2, seed: int, rim: PackedFloat32Array}
var _t := 0.0


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


func _process(delta: float) -> void:
	if light > 0.0 and fade > 0.0 and not still:
		_t += delta
		_redraw()


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


func _hole_rect() -> Rect2:
	if hole == null:
		var a := area()
		return Rect2(a.position + a.size * 0.3, a.size * 0.4)
	return Rect2(hole.position, hole.size)


## The worn patches, at the print's natural wear points: where hands, coins and cleaning cloths go.
## Each has its own seed, size, stretch (scuffs run along an edge) and order of appearance.
func patches() -> Array[Dictionary]:
	if not _patches.is_empty():
		return _patches
	var ar := area()
	var h := _hole_rect()
	var door := CabinetBezel.coin_plate()
	var lx := h.position.x - CabinetBezel.SIDE   # left column, outer edge
	var rx := h.end.x + CabinetBezel.SIDE        # right column, outer edge
	var y := func(f: float) -> float: return ar.position.y + ar.size.y * f
	# [position, radius scale, stretch]
	var spec: Array = [
		[Vector2(rx - 13.0, y.call(0.62)), 1.0, Vector2(0.55, 1.5)],                  # right outer edge, at hand height
		[Vector2(door.position.x + 4.0, door.position.y + 6.0), 0.8, Vector2(1.2, 0.8)],   # the coin door's top-left: every coin
		[Vector2(door.end.x - 6.0, door.end.y - 4.0), 0.65, Vector2(1.3, 0.7)],        # the coin door's bottom edge
		[Vector2(h.position.x - 6.0, y.call(0.70)), 0.9, Vector2(0.8, 1.2)],          # the HOW TO PLAY panel's inner corner
		[Vector2(lx + 13.0, y.call(0.40)), 1.1, Vector2(0.55, 1.6)],                   # left outer edge
		[Vector2(h.position.x - 4.0, h.position.y + 6.0), 0.7, Vector2(1.0, 1.0)],     # top-left corner by the hole
		[Vector2(h.end.x + 5.0, h.position.y + 10.0), 0.75, Vector2(0.9, 1.1)],        # top-right corner by the hole
		[Vector2(lx + 16.0, y.call(0.86)), 0.85, Vector2(1.4, 0.7)],                   # left foot, kicked
		[Vector2(rx - 13.0, y.call(0.22)), 0.7, Vector2(0.6, 1.3)],                    # right shoulder
	]
	var rng := RandomNumberGenerator.new()
	rng.seed = SEED
	for i in spec.size():
		var row: Array = spec[i]
		var seed := SEED + 31 * (i + 1)
		_patches.append({
			"c": row[0] as Vector2,
			"r": PATCH_R * float(row[1]) * rng.randf_range(0.85, 1.15),
			"order": float(i),
			"stretch": row[2] as Vector2,
			"seed": seed,
			"rim": BezelDecay.rim_profile(seed, RIM_POINTS),
		})
	# The cursed turn (TECH-001 Q-T261 revised): the printed slit eye on the right column wears through FIRST,
	# so the one painted eye in the costume becomes a window of Aether light: an absence, never a gaze (N4).
	# Placed from the bezel art's own anchor (BezelArt.haunt_anchors, #101); no anchor, no patch.
	var eye := eye_anchor()
	if eye.size.x > 0.0:
		var es := SEED + 997
		_patches.append({
			"c": eye.get_center(),
			"r": maxf(maxf(eye.size.x, eye.size.y) * EYE_PATCH_SCALE, PATCH_R * 0.45),
			"order": EYE_ORDER,
			"stretch": Vector2(0.8, 1.25),   # taller than wide: never an almond, never an eye shape (N4)
			"seed": es,
			"rim": BezelDecay.rim_profile(es, RIM_POINTS),
		})
	return _patches


## Where the cursed turn's wear-through starts, in rig units, from the bezel art's haunt anchors: `wear_origin`
## (#101 Fable pass, Q-T295: the ringed world's middle band; the world has no eye, N4), falling back to the old
## `eye` anchor when the art predates the rename. Rect2() when the art has neither.
static func eye_anchor() -> Rect2:
	var a: Dictionary = BezelArt.haunt_anchors()
	var v: Variant = a.get(&"wear_origin", a.get(&"eye", Rect2()))
	return v as Rect2 if v is Rect2 else Rect2()


## A patch edge as radius factors round the circle: low-frequency noise for the overall shape, high-frequency
## jitter for abraded fibre, and a few long thin fibres that catch the light. Unique per seed, deterministic.
static func rim_profile(seed: int, n: int) -> PackedFloat32Array:
	var noise := FastNoiseLite.new()
	noise.seed = seed
	noise.noise_type = FastNoiseLite.TYPE_SIMPLEX
	noise.frequency = 0.9
	var rng := RandomNumberGenerator.new()
	rng.seed = seed * 7 + 3
	var out := PackedFloat32Array()
	for i in n:
		var ang := TAU * float(i) / float(n)
		var v := 0.78 + 0.32 * noise.get_noise_2d(cos(ang) * 1.6, sin(ang) * 1.6)
		v += rng.randf_range(-0.045, 0.045)                     # fibre
		if rng.randf() < 0.06:
			v *= rng.randf_range(1.12, 1.3)                      # a longer torn fibre
		out.append(maxf(v, 0.35))
	return out


## How far patch `p` has spread (0..1) for the current `grow`.
func patch_k(p: Dictionary) -> float:
	if grow <= 0.0:
		return 0.0   # nothing has worn through before the Decay (Wear only bleaches; the eye patch leads, never precedes)
	return clampf(grow * 1.7 - float(p["order"]) * 0.09, 0.0, 1.0)


func _rim_points(p: Dictionary, scale: float) -> PackedVector2Array:
	var rim: PackedFloat32Array = p["rim"]
	var c: Vector2 = p["c"]
	var st: Vector2 = p["stretch"]
	var r: float = p["r"] * scale
	var pts := PackedVector2Array()
	for i in rim.size():
		var ang := TAU * float(i) / float(rim.size())
		pts.append(c + Vector2(cos(ang) * st.x, sin(ang) * st.y) * r * rim[i])
	return pts


func _draw() -> void:
	var r := area()
	if fade <= 0.0 or r.size.x <= 0.0:
		return
	var h := _hole_rect()
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
	# worn through, the print side: a scuffed fibrous margin, flecks of loose ink, then the deep Aether behind
	if light > 0.0 and grow > 0.0:
		for p in patches():
			var k := patch_k(p)
			if k <= 0.0:
				continue
			_fan(p["c"], _rim_points(p, k * 1.18), Color(Pal.BONE_4, 0.35 * fade))   # abraded, paler margin
			_fan(p["c"], _rim_points(p, k), Color(Pal.AETHER_0, 0.9 * fade))         # the hole in the print: deep fog
			_draw_flecks(p, k)


## Loose flecks of print just outside the edge (fixed per patch, so they never shimmer).
func _draw_flecks(p: Dictionary, k: float) -> void:
	var rng := RandomNumberGenerator.new()
	rng.seed = int(p["seed"]) * 13
	var c: Vector2 = p["c"]
	var st: Vector2 = p["stretch"]
	var r: float = p["r"] * k
	for i in 14:
		var ang := rng.randf() * TAU
		var d := rng.randf_range(1.05, 1.5)
		var q := c + Vector2(cos(ang) * st.x, sin(ang) * st.y) * r * d
		var col := Color(Pal.BONE_4, 0.5 * fade) if rng.randf() < 0.6 else Color(Pal.AETHER_1, 0.6 * fade)
		draw_rect(Rect2(q, Vector2.ONE * rng.randf_range(0.6, 1.4)), col)


## The light itself (additive): a radial falloff from a warm, slowly wandering core, through violet, to nothing
## at the torn edge; a faint violet bloom spills just past the edge. Never flat white: the colours come from
## the GAS (lantern amber) and AETHER ramps and only ever sum over the dark fog drawn underneath.
func _draw_glow() -> void:
	if fade <= 0.0 or light <= 0.0 or grow <= 0.0:
		return
	for p in patches():
		var k := patch_k(p)
		if k <= 0.0:
			continue
		var seed: int = p["seed"]
		var pc: Vector2 = p["c"]
		var ph := float(seed % 97) * 0.37
		var w := _t * TAU * DRIFT_HZ
		var r: float = p["r"] * k
		var st: Vector2 = p["stretch"]
		var core: Vector2 = pc + Vector2(cos(w + ph) * st.x, sin(w * 0.8 + ph * 1.3) * st.y) * r * DRIFT_R
		var warm := 0.5 + 0.5 * sin(w * 0.6 + ph)                 # the core drifts between amber and rose-violet
		var core_col := Pal.GAS_3.lerp(Pal.AETHER_3, 0.35 * (1.0 - warm))
		var lv := light * fade * k
		var c0 := Color(core_col, 1.0 * lv)
		var c1 := Color(Pal.GAS_2.lerp(Pal.AETHER_2, 0.55), 0.6 * lv)   # warm fog going violet
		var c2 := Color(Pal.AETHER_2, 0.22 * lv)                         # a faint violet glow at the torn edge
		var mid := _rim_points(p, k * 0.7)
		var rim := _rim_points(p, k)
		var bloom := _rim_points(p, k * 1.45)
		var n := rim.size()
		var pts := PackedVector2Array()
		var cols := PackedColorArray()
		var idx := PackedInt32Array()
		var edge := Color(Pal.AETHER_2, 0.12 * lv)
		pts.append(core)
		cols.append(c0)
		for i in n:
			# centre the inner ring on the wandering core so the brightest point moves inside the patch
			pts.append(core + (mid[i] - pc) * 0.9)
			cols.append(c1)
			pts.append(rim[i])
			cols.append(c2)
			pts.append(rim[i])
			cols.append(edge)
			pts.append(bloom[i])
			cols.append(Color(Pal.AETHER_1, 0.0))
		for i in n:
			var j := (i + 1) % n
			var mi := 1 + i * 4
			var mj := 1 + j * 4
			# explicit triangles: no triangulation, so a wandering core can never make a degenerate polygon
			idx.append_array(PackedInt32Array([0, mi, mj, mi, mi + 1, mj + 1, mi, mj + 1, mj, mi + 2, mi + 3, mj + 3, mi + 2, mj + 3, mj + 2]))
		RenderingServer.canvas_item_add_triangle_array(_glow.get_canvas_item(), idx, pts, cols)


## A filled star-shaped outline as an explicit triangle fan (never triangulated, so a torn fibre cannot fail).
func _fan(c: Vector2, rim: PackedVector2Array, col: Color) -> void:
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
