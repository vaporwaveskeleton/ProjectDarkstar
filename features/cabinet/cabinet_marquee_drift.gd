class_name CabinetMarqueeDrift
extends RefCounted
## The cursed turn on the marquee (TECH-001 Q-T261 revised, PM under owner direction 2026-11-19 overnight push):
## during the Decay the printed title's letters come loose from the sign. Each sags, tilts and slides a little
## its own way (a fixed hash per letter); late in D3 they rearrange, each travelling on a small arc to a FIXED
## scrambled slot (SCRAMBLE: "TRKDASRA", checked never to hold an English word of 3+ letters, the test lists the
## words), and one letter's ink fades out (that A, leaving "TRKDASR"). The sign never spells anything new
## (NARR-001 §4.5); PM ruling 2026-11-19 overnight push (TECH-001 Q-T261 follow-up). Drawn through
## BezelMarquee's additive hooks from #101 (`lettering_override` blanks the printed title, `ink_hook` draws it
## letter by letter on the same ink layer); no bezel file is edited. Reduced motion: no sag, tilt or slide;
## the fading letter still fades, and the letters stay in their printed order.

const SAG := 2.5                      ## ✱ rig units the loosest letter drops at k = 1
const TILT := 0.14                    ## ✱ rad the loosest letter tilts at k = 1
const SLIDE := 1.5                    ## ✱ rig units a letter slides sideways at k = 1
const LOST := 6                       ## ✱ the letter that fades (index into the title, the second A)
## ✱ position p of the rearranged sign shows title letter SCRAMBLE[p]: D A R K S T A R → T R K D A S R A.
const SCRAMBLE: Array[int] = [5, 2, 3, 0, 1, 4, 7, 6]
const ARC := 0.4                      ## ✱ a travelling letter lifts (or dips) this share of the cap height mid-way

var marquee: BezelMarquee
var k := 0.0                          ## 0..1 how loose the letters are
var lost_k := 0.0                     ## 0..1 how far the lost letter has faded
var swap_k := 0.0                     ## 0..1 how far the letters have travelled to their scrambled slots
var still := false
var _cache: Dictionary = {}


func attach(m: BezelMarquee) -> void:
	marquee = m
	if m == null:
		return
	m.lettering_override = " "        # the printed title is blanked; the hook prints it letter by letter
	m.ink_hook = draw
	m.refresh_ink()


func set_state(p_k: float, p_lost: float, p_swap: float = 0.0) -> void:
	k = 0.0 if still else clampf(p_k, 0.0, 1.0)
	swap_k = 0.0 if still else clampf(p_swap, 0.0, 1.0)
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
		var x0 := rect.position.x + BezelText.measure(s.substr(0, i), cap, st, trk).x if i > 0 else rect.position.x
		var x1 := rect.position.x + slot_x(s, i, cap, st, trk)
		var e := smoothstep(0.0, 1.0, swap_k)
		var lift := -sin(PI * e) * cap * ARC * (1.0 if x1 > x0 else -1.0)   # right-movers arc over, left-movers under
		var pose := letter_pose(i, k)
		var at := Vector2(lerpf(x0, x1, e) + pose.x, top + pose.y + lift)
		var a := 1.0 - lost_k if i == LOST else 1.0
		if a <= 0.0:
			continue
		var shadow := inks.key_black
		shadow.a *= a
		var ink := inks.warm_red
		ink.a *= a
		BezelText.draw(ci, _cache, ch, at + Vector2(1.0, 1.2), false, cap, st + 1.6, trk, shadow, pose.z)
		BezelText.draw(ci, _cache, ch, at, false, cap, st, trk, ink, pose.z)


## The rearranged sign as text (tests): the title's letters in SCRAMBLE order.
static func scrambled(title: String) -> String:
	var out := ""
	for p in SCRAMBLE.size():
		if SCRAMBLE[p] < title.length():
			out += title.substr(SCRAMBLE[p], 1)
	return out


## x of title letter `i` in the rearranged sign, from the sign's left: the width of what precedes its slot.
static func slot_x(title: String, i: int, cap: float, st: float, trk: float) -> float:
	var p := SCRAMBLE.find(i)
	if p <= 0:
		return 0.0
	return BezelText.measure(scrambled(title).substr(0, p), cap, st, trk).x
