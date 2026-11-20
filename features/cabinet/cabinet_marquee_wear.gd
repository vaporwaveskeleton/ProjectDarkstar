class_name CabinetMarqueeWear
extends RefCounted
## The marquee wearing out in the Decay. **Owner, 2026-11-19: the marquee is a screenprint; letters may fade
## or wear, never move, fall off or reorder** (ART-001 §12.7a, TECH-001 §11.2). The printed title stays exactly
## as BezelMarquee prints it (D-A-R-K-S-T-A-R, in place, in order); this only draws what an old backlit
## screenprint really does, through BezelMarquee's additive `ink_hook` (#101) and one additive child:
## - the ink sun-bleaches unevenly (a wash of the lens colour over each letter, by a fixed per-letter amount);
## - the print flakes and pits (specks of bare lens in the ink, more as it wears);
## - one tube section browns (a warm brown cast over the right end of the sign);
## - a crack runs across the plexi;
## - the cursed turn: the backlight behind one letter gutters out (that letter goes dark IN PLACE), and a cold
##   Aether glow bleeds through the worn ink behind two others, from behind the print, never in front of it.
## Guttering dips at most 1.2 times a second; photosensitivity / reduced motion turn the dips into a plain fade.
## Pure function of its state: captures and tests can seek.

const GUTTER := 6                     ## ✱ the letter whose backlight gutters out (the second A): it stays printed, unlit
const GLOW_LETTERS: Array[int] = [2, 4]   ## ✱ the R and the S: the Aether glows through their worn ink
const FLAKES := 48                    ## ✱ pits in the print at full wear
const BROWN_FROM := 0.64              ## ✱ the browning tube section starts this far along the lettering
const GUTTER_DIP_HZ := 1.2            ## ✱ the guttering tube's dips per second (≤ 3: flash rule); none when still
const BLEACH_MAX := 0.42              ## ✱ how far the most-faded letter washes toward the lens colour
const LENS := Color(0.97, 0.92, 0.78)   ## ✱ the backlit lens showing through bleached or pitted ink

var marquee: BezelMarquee
var still := false
var fade_k := 0.0                     ## 0..1 bleach, pitting and browning
var gutter_k := 0.0                   ## 0..1 the one letter's backlight dying
var glow_k := 0.0                     ## 0..1 the Aether glow through the worn ink
var crack_k := 0.0                    ## 0..1 the crack across the plexi
var time_s := 0.0                     ## for the guttering dips
var _glow: Control
var _cache: Dictionary = {}


func attach(m: BezelMarquee) -> void:
	marquee = m
	if m == null:
		return
	m.ink_hook = draw
	_glow = Control.new()
	_glow.name = "AetherBleed"
	_glow.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_glow.size = m.size
	var mat := CanvasItemMaterial.new()
	mat.blend_mode = CanvasItemMaterial.BLEND_MODE_ADD   # light from behind the print adds; it never paints over it
	_glow.material = mat
	_glow.draw.connect(_draw_glow)
	m.add_child(_glow)
	m.refresh_ink()


func set_state(p_fade: float, p_gutter: float, p_glow: float, p_crack: float, p_time: float) -> void:
	fade_k = clampf(p_fade, 0.0, 1.0)
	gutter_k = clampf(p_gutter, 0.0, 1.0)
	glow_k = clampf(p_glow, 0.0, 1.0)
	crack_k = clampf(p_crack, 0.0, 1.0)
	time_s = p_time
	if marquee != null:
		marquee.refresh_ink()
	if _glow != null:
		_glow.queue_redraw()


## How dark the guttering letter's backlight is now (0 lit … 1 out): a fade with slow, narrow dips while it
## dies; under photosensitivity or reduced motion, the fade alone.
func gutter_level() -> float:
	if still or gutter_k <= 0.0 or gutter_k >= 1.0:
		return gutter_k
	var dip := pow(maxf(sin(TAU * GUTTER_DIP_HZ * time_s), 0.0), 8.0)
	return clampf(gutter_k + 0.3 * dip * (1.0 - gutter_k), 0.0, 1.0)


## Pure: each printed letter's box, from the printed layout (read only: nothing here ever moves a letter).
## `anchor` is BezelMarquee.lettering_anchor() (centre x, cap top), exactly where the print is centred.
static func letter_boxes(title: String, anchor: Vector2, cap: float, st: float, trk: float) -> Array[Rect2]:
	var out: Array[Rect2] = []
	var left := anchor.x - BezelText.measure(title, cap, st, trk).x * 0.5
	for i in title.length():
		# measure() is the INK extent: up to and including letter i, minus letter i's own ink, is where it starts
		var w := BezelText.measure(title.substr(i, 1), cap, st, trk).x
		var x := BezelText.measure(title.substr(0, i + 1), cap, st, trk).x - w
		out.append(Rect2(left + x, anchor.y, w, cap))
	return out


static func _h(i: int, salt: float) -> float:
	return fposmod(sin(float(i) * 12.9898 + salt) * 43758.5453, 1.0)


func _boxes() -> Array[Rect2]:
	var s := marquee.surface
	return letter_boxes(TranslationServer.translate(BezelMarquee.KEY), marquee.lettering_anchor(), s.marquee_lettering, s.marquee_stroke, s.marquee_tracking)


## A soft-edged band: `layers` nested rects, so the edge fades instead of cutting a hard box.
static func _soft_rect(ci: CanvasItem, r: Rect2, col: Color, feather: float, layers: int = 5) -> void:
	for l in layers:
		var g := feather * (1.0 - float(l) / float(layers))
		ci.draw_rect(r.grow(g), Color(col.r, col.g, col.b, col.a / float(layers)))


## The ink hook (drawn on the print layer, after the lettering).
func draw(ci: CanvasItem, rect: Rect2) -> void:
	if marquee == null:
		return
	var boxes := _boxes()
	var title := TranslationServer.translate(BezelMarquee.KEY)
	var surf := marquee.surface
	# sun-bleach: each letter's INK washed toward the lens by its own amount (the glyph itself, re-inked in the
	# lens colour on top: only the ink fades, the sign around it does not)
	for i in boxes.size():
		var ch := title.substr(i, 1)
		if ch == " ":
			continue
		var a := fade_k * BLEACH_MAX * (0.35 + 0.65 * _h(i, 3.1)) * (0.7 + 0.3 * float(i) / maxf(boxes.size() - 1, 1))
		BezelText.draw(ci, _cache, ch, boxes[i].position, false, surf.marquee_lettering, surf.marquee_stroke, surf.marquee_tracking, Color(LENS.r, LENS.g, LENS.b, a))
	# pitting and flaking: specks of bare lens in the ink, appearing as the print wears
	for f in FLAKES:
		if _h(f, 7.7) > fade_k:
			continue
		var p := rect.position + Vector2(_h(f, 1.3), _h(f, 5.9)) * rect.size
		var sz := 0.5 + 1.1 * _h(f, 9.2)
		ci.draw_rect(Rect2(p, Vector2(sz, sz * (0.6 + 0.8 * _h(f, 2.2)))), Color(LENS.r, LENS.g, LENS.b, 0.85))
	# the browning tube section: a warm cast over the right end of the sign
	var bx := rect.position.x + rect.size.x * BROWN_FROM
	_soft_rect(ci, Rect2(bx + 3.0, rect.position.y - 1.0, rect.end.x - bx - 1.0, rect.size.y + 2.0), Color(0.36, 0.21, 0.08, 0.3 * fade_k), 3.0)
	# the one letter whose backlight gutters out: dark, in place, still printed
	var g := gutter_level()
	if g > 0.0 and GUTTER < boxes.size():
		var gb := boxes[GUTTER]
		_soft_rect(ci, Rect2(gb.position.x + 0.5, rect.position.y - 1.0, gb.size.x - 1.0, rect.size.y + 2.0), Color(0.02, 0.015, 0.02, 0.85 * g), 2.5)
	# the crack across the plexi, with its lit edge
	if crack_k > 0.0:
		var pts := crack_points(rect, crack_k)
		ci.draw_polyline(pts, Color(0.04, 0.03, 0.03, 0.75), 0.6)
		var lit := PackedVector2Array()
		for q in pts:
			lit.append(q + Vector2(0.0, -0.6))
		ci.draw_polyline(lit, Color(LENS.r, LENS.g, LENS.b, 0.35), 0.4)


## The crack: a fixed jagged line from the sign's lower left up across the first letters, drawn to `k` of its
## length (it runs, it never jumps).
static func crack_points(rect: Rect2, k: float) -> PackedVector2Array:
	var full := PackedVector2Array()
	var n := 9
	for j in n:
		var u := float(j) / float(n - 1)
		var y := lerpf(rect.end.y + 2.0, rect.position.y - 1.0, u) + (_h(j, 4.4) - 0.5) * 3.0
		full.append(Vector2(rect.position.x - 6.0 + u * rect.size.x * 0.42, y))
	var keep := maxi(2, int(ceil(k * float(n))))
	return full.slice(0, mini(keep, n))


## The Aether glow through the worn ink (additive child, drawn over the print in the same place: light from
## behind shows where the ink is thin). Cold violet into cyan, the Aether's own colours (ART-001 §15–§16).
func _draw_glow() -> void:
	if marquee == null or glow_k <= 0.0:
		return
	var boxes := _boxes()
	for i in GLOW_LETTERS:
		if i >= boxes.size():
			continue
		var c := boxes[i].get_center()
		for ring in 5:
			var rad := boxes[i].size.y * (0.75 - 0.12 * ring)
			var col := Pal.AETHER_2.lerp(Pal.AETHER_5, float(ring) / 4.0)
			_glow.draw_circle(c, rad, Color(col.r, col.g, col.b, 0.07 * glow_k))
