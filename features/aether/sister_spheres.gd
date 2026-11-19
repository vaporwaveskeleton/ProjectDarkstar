class_name SisterSpheres
extends Node2D
## The other heavens (ART-001 §16.6i): small, far crystal spheres seen through the far fog, each one
## holding its own lit sky, a brass meridian and a few motes of life. Runtime vector in the far band
## (FarLayer, under the mid fog), off-centre, never in the play core, some cropped by the frame.
## The cosmic-horror ladder: the entity eats the sky in order of beauty (GDD, the Eating of a Sky),
## so the sisters go out one per tier, the most beautiful first. An eaten sister is the same flat cold
## VOID as the missing slice, with its rim broken and its meridian snapped: never black (the only
## true black is the entity, §16.1), never a glow of its own.
## Lantern down (CH-3) shows their inner life brighter; drain dims them. Reduced motion holds them
## still. Every number here is ✱ (engineering placeholder, not a game number).

## ✱ the sisters, most beautiful first (eaten in this order): centre (layer px) and radius. The last
## one is never eaten by the ladder (T5 keeps one last pearl being erased).
const SPHERES: Array[Vector3] = [
	Vector3(92.0, 74.0, 34.0),
	Vector3(626.0, 142.0, 27.0),
	Vector3(38.0, 262.0, 19.0),
	Vector3(572.0, 312.0, 15.0),
	Vector3(252.0, 30.0, 10.0),
]
## ✱ overall opacity (they sit in the far band, behind the mid fog) and the inner glow's peak.
const FADE := 0.62
const GLOW := 0.55
## ✱ brass meridian tilt per sister (rad) and squash.
const MERIDIAN_TILT: Array[float] = [0.5, -0.35, 0.9, -0.7, 0.2]
const MERIDIAN_SQUASH := 0.32
## ✱ inner fog swirl: radians per second, and the life motes' twinkle period (s; >= 4 s keeps the
## luminance cycle well under the WARP-001 §4.5 flicker cap).
const SWIRL_SPEED := 0.03
const TWINKLE_S := 5.0
## ✱ broken-rim gaps of an eaten sister (rad), and how far its snapped meridian has slid (px per r).
const EATEN_GAPS: Array[Vector2] = [Vector2(0.3, 0.9), Vector2(2.2, 2.6), Vector2(4.1, 4.9)]
const SNAP_SLIDE := 0.18

## How many sisters are drawn (0..5) and how many of them are eaten (most beautiful first). A
## fractional `eaten` part-eats the next one (for the Eating of a Sky to animate later).
var count: int = 0
var eaten: float = 0.0
var reveal: float = 0.0
var drain: float = 0.0
var still: bool = false
var glass: Color = Pal.PHOS_4
var brass: Color = Pal.BONE_2
var highlight: Color = Pal.BONE_5
var life_col: Color = Pal.PHOS_5
var void_flat: Color = Pal.VOID_1.lerp(Pal.VOID_4, 0.22)
## ✱ each sister's own sky (AETHER, PHOS and BONE only: no GAS, no CHOIR, no SIGNAL, no NULL).
var skies: Array[Color] = [Pal.AETHER_4, Pal.AETHER_5, Pal.AETHER_3, Pal.BONE_3, Pal.PHOS_4]
var _t := 0.0


func configure(look: AetherLook) -> void:
	count = clampi(look.sister_spheres, 0, SPHERES.size())
	eaten = clampf(float(look.sister_spheres_eaten), 0.0, float(count))
	glass = look.sphere_glass
	brass = look.brass
	queue_redraw()


func any_shown() -> bool:
	return count > 0


## How eaten sister `i` is: 0 untouched … 1 gone to flat VOID.
func eaten_amount(i: int) -> float:
	return clampf(eaten - float(i), 0.0, 1.0)


func set_state(t: float, new_reveal: float, new_drain: float, new_still: bool) -> void:
	_t = 0.0 if new_still else t
	reveal = clampf(new_reveal, 0.0, 1.0)
	drain = clampf(new_drain, 0.0, 1.0)
	still = new_still
	if count > 0:
		queue_redraw()


## Every colour this layer can draw with (tests: Pal roles only, never black).
func colours_used() -> Array[Color]:
	var out: Array[Color] = [glass, brass, highlight, life_col, void_flat]
	out.append_array(skies)
	return out


func _draw() -> void:
	for i in count:
		var s := SPHERES[i]
		_draw_sister(i, Vector2(s.x, s.y), s.z, eaten_amount(i))


func _draw_sister(i: int, c: Vector2, r: float, e: float) -> void:
	var live := (1.0 - e) * (1.0 - 0.6 * drain) * FADE
	var sky := skies[i % skies.size()]
	# the glass body: a lit sky inside, brightest a little up and left of centre (lit from within)
	var core := c + Vector2(-0.18, -0.22) * r
	for k in 6:
		var f := 1.0 - float(k) / 6.0
		draw_circle(c.lerp(core, 1.0 - f), r * f, _c(sky, live * GLOW * (0.18 + 0.16 * float(k))))
	# its inner fog: two slow arcs of the sky's lighter tone
	var sw := _t * SWIRL_SPEED * (1.0 if i % 2 == 0 else -1.0)
	draw_arc(c, r * 0.62, sw + float(i), sw + float(i) + 2.1, 24, _c(highlight, live * 0.22), maxf(r * 0.08, 1.0), true)
	draw_arc(c, r * 0.4, -sw + 2.0 + float(i), -sw + 3.4 + float(i), 18, _c(glass, live * 0.3), maxf(r * 0.06, 1.0), true)
	# its life: three motes, slow twinkle (reveal brightens them: the lantern hides small light)
	for m in 3:
		var a := float(m) * 2.1 + float(i) * 0.7 + sw * 3.0
		var p := c + Vector2(cos(a), sin(a) * 0.7) * r * (0.25 + 0.18 * float(m))
		var tw := 0.6 + 0.4 * sin(TAU * _t / TWINKLE_S + float(m * 2 + i))
		draw_circle(p, maxf(r * 0.045, 0.8), _c(life_col, live * tw * (0.45 + 0.5 * reveal)))
	# eaten: the same flat cold VOID as the missing slice fills it (never black, no texture, no glow)
	if e > 0.0:
		draw_circle(c, r, _c(void_flat, e * 0.95))
	# the glass rim (PHOS: truth), the window highlight, the brass meridian
	var rim_a := FADE * (1.0 - 0.6 * drain)
	if e < 0.999:
		draw_arc(c, r, 0.0, TAU, 48, _c(glass, rim_a * (0.75 - 0.35 * e)), 1.2, true)
		draw_arc(c, r * 0.86, -2.7, -1.7, 16, _c(highlight, live * 0.7), maxf(r * 0.07, 1.0), true)
	if e > 0.0:
		# the broken rim: what is left of the glass, in pieces
		var last := 0.0
		for g in EATEN_GAPS:
			draw_arc(c, r, last, g.x, 16, _c(glass, rim_a * 0.55 * e), 1.0, true)
			last = g.y
		draw_arc(c, r, last, TAU, 16, _c(glass, rim_a * 0.55 * e), 1.0, true)
	var tilt := MERIDIAN_TILT[i % MERIDIAN_TILT.size()]
	var slide := Vector2(r * SNAP_SLIDE * e, r * SNAP_SLIDE * 0.5 * e)
	_meridian(c, r, tilt, 0.0, PI if e < 0.5 else PI * 0.55, Vector2.ZERO, _c(brass, rim_a * 0.85))
	_meridian(c, r, tilt, PI if e < 0.5 else PI * 0.7, TAU, slide, _c(brass, rim_a * 0.5))


## Half of an elliptical brass band from angle a0 to a1 around the sister, offset by `slide`.
func _meridian(c: Vector2, r: float, tilt: float, a0: float, a1: float, slide: Vector2, col: Color) -> void:
	var pts := PackedVector2Array()
	var n := 20
	for k in n + 1:
		var a := lerpf(a0, a1, float(k) / float(n))
		var p := Vector2(cos(a) * r * 1.04, sin(a) * r * 1.04 * MERIDIAN_SQUASH).rotated(tilt)
		pts.append(c + p + slide)
	draw_polyline(pts, col, maxf(r * 0.07, 1.0), true)


func _c(base: Color, a: float) -> Color:
	return Color(base, clampf(a, 0.0, 1.0))
