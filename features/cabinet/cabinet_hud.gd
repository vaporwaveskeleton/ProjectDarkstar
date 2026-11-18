class_name CabinetHud
extends Control
## The Act 0 costume around the field (WARP-001 W0-01, W0-02, W0-04): the printed 4:3 bezel
## (two BezelPrint columns, drawn behind this control), the lit 1UP / score strip, Vigils, the
## glass-lamp Charge pips and the Sepulchre count in their windows, and the coin door. It lives on
## the BezelLayer, above the CRT: the bezel is a real object, not a CRT image. The Ledger Compass and
## the maker mark are on the screen (CabinetScreenHud, forwarded `world`, `eaten`, `peel`).
## Everything here is honest at T0. `peel` 0 → 1 slides the costume away (W0-07/W0-08);
## `eaten` 0 → 1 lets the Unmaking swallow the readouts.

const SIDE := CabinetBezel.SIDE       ## bezel width: 640 − 2 × 80 = 480 = a 4:3 field at 360 high
const MARGIN := CabinetBezel.MARGIN   ## readout text left margin inside a column
const READOUT_W := CabinetBezel.READOUT_W  ## widest readout (a 2× number): inside the window inner width

@export var screen_hud: CabinetScreenHud

var score := 0
var hi_score := 0
var lives := 3
var charges := 0
var magazine := 5
var demo := false      ## attract demo: only then does the bezel beg for a credit
var world: ArcadeWorld:
	set(v):
		world = v
		if screen_hud != null:
			screen_hud.world = v
var eaten := 0.0:
	set(v):
		eaten = v
		if screen_hud != null:
			screen_hud.eaten = v
var peel := 0.0:
	set(v):
		peel = v
		if _left != null:
			_left.peel = v
			_right.peel = v
		if screen_hud != null:
			screen_hud.peel = v
var crack := 0.0:
	set(v):
		crack = v
		if _left != null:
			_left.crack = v
			_right.crack = v
var _t := 0.0
var _left: BezelPrint
var _right: BezelPrint


func _ready() -> void:
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	set_anchors_preset(Control.PRESET_FULL_RECT)
	_left = _make_print(&"left")
	_right = _make_print(&"right")
	_left.peel = peel
	_right.peel = peel
	_left.crack = crack
	_right.crack = crack
	if screen_hud != null:
		screen_hud.world = world
		screen_hud.eaten = eaten
		screen_hud.peel = peel


func _make_print(column: StringName) -> BezelPrint:
	var p := BezelPrint.new()
	p.column = column
	add_child(p)
	return p


func _process(delta: float) -> void:
	_t += delta
	queue_redraw()


func _draw() -> void:
	if peel >= 1.0:
		return
	var shift := peel * (SIDE + 20.0)
	var plate := CabinetBezel.COIN_PLATE
	plate.position.x += shift
	CabinetBezel.draw_coin_plate(self, plate, 0.0, tr("CAB_COIN_PRICE"))
	_draw_left_text(-shift)
	_draw_right_text(shift)


## Readout scale: 2× when `text` fits in `max_w` pixels, else 1×.
static func score_scale(text: String, max_w: float) -> int:
	return 2 if PixelText.width(text, 2) <= max_w else 1


## Sepulchre readout value: the segment count, or "" once it is awake (the caller shows CAB_SEP_AWAKE).
static func sepulchre_text(segments: int, total: int, awake: bool) -> String:
	return "" if awake else "%d/%d" % [segments, total]


## Column-local boxes of every lit readout against the window that must hold it, for the texts given:
## [{"name", "window": Rect2, "box": Rect2}, ...]. Tests check containment; the draw code uses the
## same CabinetBezel constants.
static func readout_boxes(score_text: String, hi_text: String, sepulchre_value: String) -> Array[Dictionary]:
	var m := CabinetBezel.MARGIN
	var h := CabinetBezel.TEXT_H
	var out: Array[Dictionary] = []
	var add := func(label: String, window: Rect2, box: Rect2) -> void:
		out.append({"name": label, "window": window, "box": box})
	add.call("1up", CabinetBezel.LEFT_SCORE, Rect2(m, CabinetBezel.ONE_UP_BASE - h, PixelText.width("1UP"), h))
	var sc := score_scale(score_text, READOUT_W)
	add.call("score", CabinetBezel.LEFT_SCORE, Rect2(m, CabinetBezel.SCORE_BASE - h * sc, PixelText.width(score_text, sc), h * sc))
	add.call("vigils", CabinetBezel.LEFT_VIGILS, Rect2(m, CabinetBezel.VIGILS_BASE - h, PixelText.width("VIGILS"), h))
	add.call("icons", CabinetBezel.LEFT_VIGILS, Rect2(m + 2.0, CabinetBezel.ICON_Y - 6.0, 14.0 * (CabinetBezel.MAX_ICONS - 1) + 10.0, 12.0))
	add.call("hi_label", CabinetBezel.RIGHT_HI, Rect2(m, CabinetBezel.HI_BASE - h, PixelText.width("HI"), h))
	var hs := score_scale(hi_text, READOUT_W)
	add.call("hi", CabinetBezel.RIGHT_HI, Rect2(m, CabinetBezel.HI_VALUE_BASE - h * hs, PixelText.width(hi_text, hs), h * hs))
	add.call("glass_label", CabinetBezel.RIGHT_GLASS, Rect2(m, CabinetBezel.GLASS_BASE - h, PixelText.width("GLASS"), h))
	add.call("lamps", CabinetBezel.RIGHT_GLASS, Rect2(m, CabinetBezel.LAMP_Y - 7.0, 2.0 * 18.0 + 10.0, CabinetBezel.LAMP_STEP + 14.0))
	add.call("sepulchre_label", CabinetBezel.RIGHT_SEPULCHRE, Rect2(m, CabinetBezel.SEPULCHRE_BASE - h, PixelText.width("SEPULCHRE"), h))
	var vs := score_scale(sepulchre_value, READOUT_W)
	add.call("sepulchre_value", CabinetBezel.RIGHT_SEPULCHRE, Rect2(m, CabinetBezel.SEPULCHRE_VALUE_BASE - h * vs, PixelText.width(sepulchre_value, vs), h * vs))
	return out


func _draw_left_text(shift: float) -> void:
	var x := MARGIN + shift
	if eaten < 0.3:
		var sv := LocFormat.format_int(score)
		CabinetBezel.draw_score(self, _t, sv, score_scale(sv, READOUT_W), shift)
	if eaten < 0.6:
		CabinetBezel.text(self, Vector2(x, CabinetBezel.VIGILS_BASE), tr("CAB_VIGILS"), Look.c(Pal.BONE_4))
		for i in mini(maxi(0, lives - 1), CabinetBezel.MAX_ICONS):
			var c := Vector2(x + 6 + i * 14, CabinetBezel.ICON_Y)
			var hull := PackedVector2Array([c + Vector2(0, -5), c + Vector2(4, 4), c + Vector2(0, 2), c + Vector2(-4, 4)])
			Pal.glow_polyline(self, hull, Look.c(Pal.GAS_4), Look.c(Pal.GAS_1))
	if demo and eaten < 0.9:
		var blink := int(_t * 1.5) % 2 == 0
		CabinetBezel.draw_credit(self, tr("CAB_CREDIT"), Look.c(Pal.BONE_4) if blink else Look.c(Pal.BONE_1), shift)


func _draw_right_text(shift: float) -> void:
	var x := CabinetBezel.RIGHT_X + MARGIN + shift
	if eaten < 0.3:
		CabinetBezel.text(self, Vector2(x, CabinetBezel.HI_BASE), tr("CAB_HI"), Look.c(Pal.BONE_4))
		var hv := LocFormat.format_int(maxi(hi_score, score))
		CabinetBezel.text(self, Vector2(x, CabinetBezel.HI_VALUE_BASE), hv, Look.c(Pal.BONE_4), score_scale(hv, READOUT_W))
	if eaten < 0.6:
		CabinetBezel.text(self, Vector2(x, CabinetBezel.GLASS_BASE), tr("CAB_GLASS"), Look.c(Pal.BONE_4))
		for i in magazine:
			var c := Vector2(x + 4 + (i % 3) * 18, CabinetBezel.LAMP_Y + (i / 3) * CabinetBezel.LAMP_STEP)
			var full := i < charges
			var lamp := PackedVector2Array([c + Vector2(0, -6), c + Vector2(4, 0), c + Vector2(0, 6), c + Vector2(-4, 0)])
			if full:
				draw_colored_polygon(lamp, Look.c(Pal.PHOS_3))
				draw_rect(Rect2(c - Vector2(0, 1), Vector2(1, 2)), Look.c(Pal.PHOS_5))
			Pal.glow_polyline(self, lamp, Look.c(Pal.PHOS_4) if full else Look.c(Pal.VOID_4), Look.c(Pal.VOID_2))
		_draw_sepulchre(x)


## Sepulchre progress in its window: segments / total, or AWAKE once it stirs. Nothing once unmade.
func _draw_sepulchre(x: float) -> void:
	if world == null or world.ritual == null or world.ritual.phase == SepulchreRitual.Phase.UNMADE:
		return
	var rit := world.ritual
	var val := sepulchre_text(rit.segments, world.tuning.segments_total, rit.awake)
	if rit.awake:
		val = tr("CAB_SEP_AWAKE")
	CabinetBezel.text(self, Vector2(x, CabinetBezel.SEPULCHRE_BASE), tr("CAB_SEPULCHRE"), Look.c(Pal.BONE_4))
	CabinetBezel.text(self, Vector2(x, CabinetBezel.SEPULCHRE_VALUE_BASE), val, Look.c(Pal.BONE_5), score_scale(val, READOUT_W))
