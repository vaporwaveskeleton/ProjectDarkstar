class_name BezelDecay
extends Control
## The printed bezel wearing out (ART-001 §12.7b; WARP-001 W0-07 the Decay, W0-11 Wear). A native-resolution
## overlay on the Rig, drawn after the Hud so it lies on the print, never on the screen hole (the CRT and
## the registers own the screen). Subtract-only in spirit: bleach takes the ink's colour away, the glass
## smears, and where the print wears through there is the Aether's pearl light behind it, never wood or black.
## No flicker anywhere: every value only moves one way during the Decay.

@export var hole: Control              ## the ArcadeScreen: its rect is the screen hole, left untouched
@export var rig: ScreenRig             ## the area to wear: rig.bezel_rect() (the whole window in rig units; the Rig itself has no size)

var bleach := 0.0:                     ## 0..1 ink saturation lost, worst at the outer edges
	set(v):
		bleach = v
		queue_redraw()
var smear := 0.0:                      ## 0..1 the smoked glass thickening at the hole's edge
	set(v):
		smear = v
		queue_redraw()
var light := 0.0:                      ## 0..1 alpha of the Aether light through worn spots
	set(v):
		light = v
		queue_redraw()
var grow := 0.0:                       ## 0..1 how far the worn spots have spread
	set(v):
		grow = v
		queue_redraw()
var fade := 1.0:                       ## 1 → 0 as the bezel peels away after the tear
	set(v):
		fade = v
		queue_redraw()

const SPOTS := 9                       ## ✱ worn spots on the print
const SPOT_R := 16.0                   ## ✱ px, a spot's radius when fully spread
const SMEAR_W := 16.0                  ## ✱ px, the smear band around the hole
const SEED := 1983                     ## ✱ fixed: the same spots every time (deterministic captures)

var _spots: Array[Vector3] = []        ## x, y, order


func _ready() -> void:
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	set_anchors_preset(Control.PRESET_FULL_RECT)


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


## Worn-spot centres, seeded, on the print either side of the hole (never inside it).
func spots() -> Array[Vector3]:
	if not _spots.is_empty():
		return _spots
	var h := _hole_rect()
	var rng := RandomNumberGenerator.new()
	rng.seed = SEED
	var i := 0
	var guard := 0
	while _spots.size() < SPOTS and guard < 400:
		guard += 1
		var ar := area()
		var p := Vector2(rng.randf_range(ar.position.x + 8.0, ar.end.x - 8.0), rng.randf_range(ar.position.y + 10.0, ar.end.y - 10.0))
		if h.grow(SPOT_R).has_point(p):
			continue
		_spots.append(Vector3(p.x, p.y, float(i)))
		i += 1
	return _spots


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
	# worn through: the Aether's pearl light behind the print (ART-001 §16.1)
	if light > 0.0 and grow > 0.0:
		for sp in spots():
			var k := clampf(grow * 1.6 - sp.z * 0.08, 0.0, 1.0)
			if k <= 0.0:
				continue
			var c := Vector2(sp.x, sp.y)
			var rad := SPOT_R * k
			# a cool halo bleeding into the ink, then the pearl light itself where the print is gone
			draw_polygon(_blob(c, rad * 1.8, int(sp.z) + 7), PackedColorArray([Color(Pal.AETHER_5, 0.45 * light * fade)]))
			draw_polygon(_blob(c, rad, int(sp.z) + 1), PackedColorArray([Color(Pal.AETHER_4, light * fade)]))


func _quad(a: Vector2, b: Vector2, c: Vector2, d: Vector2, ca: Color, cb: Color, cc: Color, cd: Color) -> void:
	draw_polygon(PackedVector2Array([a, b, c, d]), PackedColorArray([ca, cb, cc, cd]))


## An irregular worn edge: a seeded wobble round a circle (flaking print, not a clean hole).
static func _blob(c: Vector2, r: float, seed: int) -> PackedVector2Array:
	var rng := RandomNumberGenerator.new()
	rng.seed = seed
	var pts := PackedVector2Array()
	var n := 14
	for i in n:
		var ang := TAU * float(i) / float(n)
		pts.append(c + Vector2.from_angle(ang) * r * rng.randf_range(0.65, 1.15))
	return pts
