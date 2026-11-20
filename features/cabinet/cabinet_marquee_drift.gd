class_name CabinetMarqueeDrift
extends RefCounted
## The cursed turn on the marquee (TECH-001 Q-T261 revised, PM under owner direction 2026-11-19 overnight push):
## during the Decay the printed title's letters come loose from the sign. Each sags, tilts and slides a little
## its own way (a fixed hash per letter), they never change order, and one letter's ink fades out, so the sign
## loses a letter and never spells anything new (NARR-001 §4.5: subtract, never write). Drawn through
## BezelMarquee's additive hooks from #101 (`lettering_override` blanks the printed title, `ink_hook` draws it
## letter by letter on the same ink layer); no bezel file is edited. Reduced motion: no sag, tilt or slide;
## the fading letter still fades.

const SAG := 2.5                      ## ✱ rig units the loosest letter drops at k = 1
const TILT := 0.14                    ## ✱ rad the loosest letter tilts at k = 1
const SLIDE := 1.5                    ## ✱ rig units a letter slides sideways at k = 1
const LOST := 6                       ## ✱ the letter that fades (index into the title): "DARKST R", never a word

var marquee: BezelMarquee
var k := 0.0                          ## 0..1 how loose the letters are
var lost_k := 0.0                     ## 0..1 how far the lost letter has faded
var still := false
var _cache: Dictionary = {}


func attach(m: BezelMarquee) -> void:
	marquee = m
	if m == null:
		return
	m.lettering_override = " "        # the printed title is blanked; the hook prints it letter by letter
	m.ink_hook = draw
	m.refresh_ink()


func set_state(p_k: float, p_lost: float) -> void:
	k = 0.0 if still else clampf(p_k, 0.0, 1.0)
	lost_k = clampf(p_lost, 0.0, 1.0)
	if marquee != null:
		marquee.refresh_ink()


## Pure: the offset (x, y) and tilt (z) of letter `i` at looseness `kk` (fixed per letter: no rng).
static func letter_pose(i: int, kk: float) -> Vector3:
	var h1 := fposmod(sin(float(i) * 12.9898 + 1.7) * 43758.5453, 1.0)
	var h2 := fposmod(sin(float(i) * 78.233 + 0.3) * 24634.6345, 1.0)
	return Vector3((h2 - 0.5) * 2.0 * SLIDE * kk, SAG * kk * (0.35 + 0.65 * h1), (h1 - 0.5) * 2.0 * TILT * kk)


## The ink hook: the title, letter by letter, where each letter has come to rest.
func draw(ci: CanvasItem, rect: Rect2) -> void:
	if marquee == null:
		return
	var s := ci.tr(BezelMarquee.KEY)
	var surf := marquee.surface
	var cap := surf.marquee_lettering
	var st := surf.marquee_stroke
	var trk := surf.marquee_tracking
	var inks := BezelInks.default() as BezelInks
	var top := marquee.lettering_anchor().y
	for i in s.length():
		var ch := s.substr(i, 1)
		if ch == " ":
			continue
		var x := rect.position.x + BezelText.measure(s.substr(0, i), cap, st, trk).x if i > 0 else rect.position.x
		var pose := letter_pose(i, k)
		var at := Vector2(x + pose.x, top + pose.y)
		var a := 1.0 - lost_k if i == LOST else 1.0
		if a <= 0.0:
			continue
		var shadow := inks.key_black
		shadow.a *= a
		var ink := inks.warm_red
		ink.a *= a
		BezelText.draw(ci, _cache, ch, at + Vector2(1.0, 1.2), false, cap, st + 1.6, trk, shadow, pose.z)
		BezelText.draw(ci, _cache, ch, at, false, cap, st, trk, ink, pose.z)
