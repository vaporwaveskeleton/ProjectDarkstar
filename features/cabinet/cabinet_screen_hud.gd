class_name CabinetScreenHud
extends Control
## The Act 0 HUD strip (WARP-001 W0-02, GDD §10, owner 2026-11-18 Q-T31): every live readout, lit on
## the screen's top 40 rows: 1UP and score, spare Vigils and the Ledger Compass on the left and centre,
## HI, the glass lamps and the Sepulchre count on the right. It sits on the HudLayer inside the arcade
## screen, under the CRT, so scanlines and curvature touch it. The printed bezel carries no readouts.
## Honest at T0. `eaten` 0 → 1 lets the Unmaking swallow the readouts; `peel` drops the maker mark.
## The attract screen reuses it (`attract`): 1UP, score 0, HI and the credit count, nothing else.
## Layout constants are strip coordinates (y 0..40 of the 256×304 grid); the play view is below.

const LEFT_X := 4.0                  ## left block text starts here
const RIGHT_EDGE := 252.0            ## right block is right-aligned to here
const ONE_UP_BASE := 9.0             ## baselines: PixelText draws up from them
const SCORE_BASE := 25.0
const SCORE_MAX_W := 80.0            ## a 2× score must end left of the compass (x ≤ 84)
const ICON_X := 6.0                  ## left edge of the first spare-Vigil icon
const ICON_Y := 34.0
const ICON_STEP := 10.0
const ICON_LIMIT_X := 84.0           ## the icon row stays left of this
const COMPASS := Rect2(88, 3, 80, 31)
const HI_BASE := 9.0
const HI_VALUE_BASE := 19.0
const LAMP_Y := 29.0
const LAMP_STEP := 8.0
const LAMP_END_X := 248.0            ## the last lamp's right edge
const MAX_LAMPS := 5
const SEPULCHRE_BASE := 37.0
const SEPULCHRE_END_X := 202.0       ## right-aligned value ends 4 px clear of the first lamp's glow (x ≈ 206.5)
const SEPARATOR_Y := 39.0
const TEXT_H := 7.0                  ## PixelText glyph height at 1×
const CREDIT_ABOVE_FOOT := 22.0      ## the credit line's top, measured up from the grid's bottom
const MAKER_ABOVE_FOOT := 10.0

var world: ArcadeWorld
var score := 0
var hi_score := 0
var lives := 3
var charges := 0
var magazine := 5
var eaten := 0.0       ## 0 → 1: the Unmaking swallows the readouts
var peel := 0.0        ## 0 → 1: the maker mark falls away with the costume
var attract := false   ## attract screen: 1UP, score, HI and `credit_line` only
var credit_line := ""  ## attract: the credit count, in the bottom of the play view
var credit_color := Color.WHITE
var _t := 0.0


func _ready() -> void:
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	set_anchors_preset(Control.PRESET_FULL_RECT)


func _process(delta: float) -> void:
	_t += delta
	queue_redraw()


## Readout scale: 2× when `text` fits in `max_w` pixels, else 1×.
static func score_scale(text: String, max_w: float) -> int:
	return 2 if PixelText.width(text, 2) <= max_w else 1


## Sepulchre readout value: the segment count, or "" once it is awake (the caller shows CAB_SEP_AWAKE).
static func sepulchre_text(segments: int, total: int, awake: bool) -> String:
	return "" if awake else "%d/%d" % [segments, total]


static func _text_box(right_aligned: bool, x: float, base: float, text: String, scale: int) -> Rect2:
	var w := float(PixelText.width(text, scale))
	return Rect2(x - (w if right_aligned else 0.0), base - TEXT_H * scale, w, TEXT_H * scale)


static func lamp_count(magazine_size: int) -> int:
	return clampi(magazine_size, 0, MAX_LAMPS)


static func lamp_centre(i: int, count: int) -> Vector2:
	return Vector2(LAMP_END_X - 4.0 - (count - 1 - i) * LAMP_STEP, LAMP_Y)


static func icon_count(lives_left: int) -> int:
	return clampi(lives_left - 1, 0, int((ICON_LIMIT_X - ICON_X) / ICON_STEP))


## Strip-coordinate boxes of every lit readout for the texts given: [{"name", "box": Rect2}, ...].
## The draw code uses the same constants, so a test of these boxes is a test of the screen.
static func readout_boxes(score_text: String, hi_text: String, sepulchre_value: String, lives_left: int = 3, magazine_size: int = MAX_LAMPS) -> Array[Dictionary]:
	var out: Array[Dictionary] = []
	var add := func(label: String, box: Rect2) -> void:
		out.append({"name": label, "box": box})
	add.call("1up", _text_box(false, LEFT_X, ONE_UP_BASE, "1UP", 1))
	add.call("score", _text_box(false, LEFT_X, SCORE_BASE, score_text, score_scale(score_text, SCORE_MAX_W)))
	var n := icon_count(lives_left)
	if n > 0:
		add.call("icons", Rect2(ICON_X, ICON_Y - 5.0, ICON_STEP * (n - 1) + 8.0, 9.0))
	add.call("compass", COMPASS)
	add.call("hi_label", _text_box(true, RIGHT_EDGE, HI_BASE, "HI", 1))
	add.call("hi", _text_box(true, RIGHT_EDGE, HI_VALUE_BASE, hi_text, 1))
	var lc := lamp_count(magazine_size)
	if lc > 0:
		var first := lamp_centre(0, lc)
		var last := lamp_centre(lc - 1, lc)
		add.call("lamps", Rect2(first.x - 4.0, LAMP_Y - 6.0, last.x - first.x + 8.0, 12.0))
	if sepulchre_value != "":
		add.call("sepulchre", _text_box(true, SEPULCHRE_END_X, SEPULCHRE_BASE, sepulchre_value, 1))
	return out


## The demo / attract credit line's box: 1×, centred, near the bottom of a grid `grid` big.
static func credit_box(text: String, grid: Vector2) -> Rect2:
	var w := float(PixelText.width(text))
	return Rect2(roundf((grid.x - w) * 0.5), grid.y - CREDIT_ABOVE_FOOT, w, TEXT_H)


func _draw() -> void:
	# the strip is opaque: the play view starts under it
	draw_rect(Rect2(0, 0, size.x, SEPARATOR_Y), Look.c(Pal.VOID_0))
	draw_rect(Rect2(0, SEPARATOR_Y, size.x, 1), Look.c(Pal.VOID_4))
	_draw_left()
	if not attract and world != null and world.torus != null and eaten < 1.0:
		_draw_compass()
	_draw_right()
	if attract:
		if credit_line != "":
			var b := credit_box(credit_line, size)
			PixelText.draw(self, b.position, credit_line, credit_color)
	elif peel < 1.0 and eaten < 0.9:
		PixelText.draw_centered(self, size.x * 0.5, size.y - MAKER_ABOVE_FOOT + peel * 20.0, tr("CAB_MAKER"), Look.c(Pal.BONE_1))


## Cabinet-face text with `x, base` as the baseline (like draw_string).
func _text(x: float, base: float, s: String, col: Color, scale: int = 1) -> void:
	PixelText.draw(self, Vector2(x, base - TEXT_H * scale), s, col, scale)


func _text_right(base: float, s: String, col: Color) -> void:
	_text(RIGHT_EDGE - PixelText.width(s), base, s, col)


func _draw_left() -> void:
	if eaten < 0.3:
		var one_up := Look.c(Pal.GAS_4) if int(_t * 2.0) % 2 == 0 else Look.c(Pal.GAS_2)
		_text(LEFT_X, ONE_UP_BASE, tr("CAB_1UP"), one_up)
		var sv := LocFormat.format_int(score)
		_text(LEFT_X, SCORE_BASE, sv, Look.c(Pal.BONE_5), score_scale(sv, SCORE_MAX_W))
	if eaten < 0.6 and not attract:
		for i in icon_count(lives):
			var c := Vector2(ICON_X + 4.0 + i * ICON_STEP, ICON_Y)
			var hull := PackedVector2Array([c + Vector2(0, -5), c + Vector2(4, 4), c + Vector2(0, 2), c + Vector2(-4, 4)])
			Pal.glow_polyline(self, hull, Look.c(Pal.GAS_4), Look.c(Pal.GAS_1))


func _draw_right() -> void:
	if eaten < 0.3:
		_text_right(HI_BASE, tr("CAB_HI"), Look.c(Pal.BONE_4))
		_text_right(HI_VALUE_BASE, LocFormat.format_int(maxi(hi_score, score)), Look.c(Pal.BONE_4))
	if eaten >= 0.6 or attract:
		return
	var n := lamp_count(magazine)
	for i in n:
		var c := lamp_centre(i, n)
		var full := i < charges
		var lamp := PackedVector2Array([c + Vector2(0, -6), c + Vector2(4, 0), c + Vector2(0, 6), c + Vector2(-4, 0)])
		if full:
			draw_colored_polygon(lamp, Look.c(Pal.PHOS_3))
			draw_rect(Rect2(c - Vector2(0, 1), Vector2(1, 2)), Look.c(Pal.PHOS_5))
		Pal.glow_polyline(self, lamp, Look.c(Pal.PHOS_4) if full else Look.c(Pal.VOID_4), Look.c(Pal.VOID_2))
	if world == null or world.ritual == null or world.ritual.phase == SepulchreRitual.Phase.UNMADE:
		return
	var rit := world.ritual
	var val := tr("CAB_SEP_AWAKE") if rit.awake else sepulchre_text(rit.segments, world.tuning.segments_total, false)
	var b := _text_box(true, SEPULCHRE_END_X, SEPULCHRE_BASE, val, 1)
	PixelText.draw(self, b.position, val, Look.c(Pal.BONE_5))


## The Ledger Compass: the whole torus at a glance (the Sinistar scanner homage). Honest at T0.
func _draw_compass() -> void:
	var r := COMPASS
	var tsize := world.torus.size
	draw_rect(r, Look.c(Pal.VOID_0))
	draw_rect(r, Look.c(Pal.BONE_1) if eaten <= 0.0 else Look.c(Pal.BONE_0), false, 1.0)
	var scale := Vector2((r.size.x - 4.0) / tsize.x, (r.size.y - 4.0) / tsize.y)
	var o := r.position + Vector2(2, 2)
	var to_c := func(p: Vector2) -> Vector2: return (o + p * scale).round()
	# the view window: the play view, in torus units
	var view := Rect2(to_c.call(world.torus.wrap(world.view_centre - world.view_size * 0.5)), world.view_size * scale)
	draw_rect(view, Look.c(Pal.VOID_3), false, 1.0)
	for g in world.geodes.items:
		draw_rect(Rect2(to_c.call(g.pos), Vector2.ONE), Look.c(Pal.BONE_1))
	for s in world.glass.shards:
		if s.alive:
			draw_rect(Rect2(to_c.call(s.pos), Vector2.ONE), Look.c(Pal.PHOS_3))
	for gr in world.grubs.items:
		draw_rect(Rect2(to_c.call(gr.pos), Vector2.ONE), Look.c(Pal.CHOIR_4))
	for a in world.acolytes.items:
		draw_rect(Rect2(to_c.call(a.pos), Vector2(2, 2)), Look.c(Pal.CHOIR_5))
	var rit := world.ritual
	if rit.phase != SepulchreRitual.Phase.UNMADE:
		var ep: Vector2 = to_c.call(rit.entity_pos if rit.awake else rit.pos)
		draw_rect(Rect2(ep - Vector2(2, 2), Vector2(5, 5)), Look.c(Pal.NULL))
		draw_rect(Rect2(ep - Vector2(2, 2), Vector2(5, 5)), Look.c(Pal.PHOS_4) if rit.awake else Look.c(Pal.VOID_5), false, 1.0)
	if world.vigil.alive:
		draw_rect(Rect2(to_c.call(world.vigil.pos) - Vector2(1, 1), Vector2(2, 2)), Look.c(Pal.GAS_5))
