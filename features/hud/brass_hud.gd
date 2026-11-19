class_name BrassHud
extends Control
## The Aether-tier diegetic HUD (TECH-001 §5.4; WARP-001 §4.1 anchor slots; ART-001 §15): brass
## instrument plates around the play layer, all fully honest. The Ledger Compass (top-centre) and the
## Composure wick (bottom-right) are their own nodes; this control draws the other T0 slots the sector
## has values for:
##   top-left       Steady Ledger panel (only with Steady Ledger on, WARP-001 §4.4): the honest Warp Tier
##   top-right      Vigil Index (score, SYS-001 §7.1)
##   bottom-left    Charge pip strip (one glass lamp per magazine slot, lit = loaded; phosphor = truth)
##   bottom-centre  Seam index (one stud per Seam of the run, the current one lit)
## Plus the hull line: shown only when the hull has more than one point (D-08 stays data-switchable)
## or when it is breached. Values are pushed in by the sector (`set_values`), never read from the
## world here, and never lied about: nothing in this control has a lie seam (L6: Charges are a
## resource spendable in the next 3 s; L10/§4.7: the Seam index never lies). Text: VectorLabel + tr().
## One deviation seam, not a lie: W1-10 Ledger Smudge (WARP-001 §4.2 Glyph class) may draw one Vigil
## Index digit as a close neighbour through `liar` (HudLiar); `score` never changes, and with Steady
## Ledger on the liar returns nothing (WARP-001 §4.4).

const FACE := preload("res://data/hud/brass_face.tres")
const SMALL := preload("res://data/hud/brass_face_small.tres")
## ✱ Plate geometry (logical px, 640×360 frame), not tunables.
const MARGIN := 4.0
const INDEX_SIZE := Vector2(92.0, 22.0)
const LEDGER_SIZE := Vector2(80.0, 22.0)
## ✱ Sand-glass size inside the top-left plate (logical px).
const GLASS_SIZE := Vector2(8.0, 14.0)
const STRIP_H := 18.0
const LAMP_R := 3.0
const LAMP_STEP := 10.0
const SEAM_STEP := 12.0

var score: int = 0
var charges: int = 0
var charge_capacity: int = 0
var seam_index: int = 0
var seams_per_run: int = 0
var tier: int = 0
var hull: int = 0
var hull_max: int = 0
var hull_breached := false
## True when the Steady Ledger panel is drawn (read from Settings at each refresh).
var ledger_on := true
## The Hourglass (Q-T210, WARP-001 §4.1 home anchor top-left): the share of the Iteration budget left
## (0–1) and whether it shows. It shows always under Steady Ledger (§4.4 honest read) and otherwise
## only when RunSessionCore.hourglass_visible() (SYS-001 §6 show threshold). Never lies (L6).
var hourglass_frac := 1.0
var hourglass_shown := false
## `_draw` passes (tests read it).
var draw_count := 0
## W1-10 seam (TECH-001 §5.1a). Null = honest, always.
var liar: HudLiar = null
var _smudged := false

var _index_label: VectorLabel
var _index_value: VectorLabel
var _charges_label: VectorLabel
var _seam_label: VectorLabel
var _ledger_label: VectorLabel
## The hull line (named HullLabel so tests and the probe find it).
var hull_label: VectorLabel


func _ready() -> void:
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	set_anchors_preset(Control.PRESET_FULL_RECT)
	_index_label = _label(&"IndexLabel", SMALL, Pal.GAS_5, &"HUD_PLATE_INDEX")
	_index_value = _label(&"IndexValue", FACE, Pal.BONE_5, &"")
	_index_value.alignment = VectorText.Align.RIGHT
	_charges_label = _label(&"ChargesLabel", SMALL, Pal.GAS_5, &"HUD_PLATE_CHARGES")
	_seam_label = _label(&"SeamLabel", SMALL, Pal.GAS_5, &"HUD_PLATE_SEAM")
	_ledger_label = _label(&"LedgerLabel", SMALL, Pal.PHOS_5, &"")
	hull_label = _label(&"HullLabel", FACE, Pal.BONE_5, &"")
	resized.connect(_layout)
	_layout()


func _label(n: StringName, f: VectorFace, c: Color, k: StringName) -> VectorLabel:
	var l := VectorLabel.new()
	l.name = n
	l.face = f
	l.color = c
	l.key = k
	l.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(l)
	return l


## Pushes the honest values in; redraws only when something changed. Returns true on a change.
func set_values(p_score: int, p_charges: int, p_capacity: int, p_seam: int, p_seams: int, p_tier: int,
		p_hull: int, p_hull_max: int, p_breached: bool) -> bool:
	var ledger := HudModel.steady_ledger_on()
	var key := [p_score, p_charges, p_capacity, p_seam, p_seams, p_tier, p_hull, p_hull_max, p_breached, ledger]
	var now := [score, charges, charge_capacity, seam_index, seams_per_run, tier, hull, hull_max,
		hull_breached, ledger_on]
	if key == now:
		return false
	score = p_score
	charges = p_charges
	charge_capacity = p_capacity
	seam_index = p_seam
	seams_per_run = p_seams
	tier = p_tier
	hull = p_hull
	hull_max = p_hull_max
	hull_breached = p_breached
	ledger_on = ledger
	_index_value.text = LocFormat.format_int(score)
	_apply_glyph()
	_ledger_label.text = LocFormat.tr_count("HUD_LEDGER_TIER", tier)
	_ledger_label.visible = ledger_on
	if hull_breached:
		hull_label.text = tr("HUD_HULL_BREACHED")
	elif hull_max > 1:
		hull_label.text = LocFormat.tr_count("HUD_HULL_COUNT", hull)
	else:
		hull_label.text = ""
	hull_label.visible = hull_label.text != ""
	_layout()
	return true


func index_rect() -> Rect2:
	return Rect2(Vector2(size.x - MARGIN - INDEX_SIZE.x, MARGIN), INDEX_SIZE)


## Sets the Hourglass read; redraws only on a visible change. Returns true on a change.
func set_hourglass(frac: float, threshold_reached: bool) -> bool:
	var f := snappedf(clampf(frac, 0.0, 1.0), 0.01)
	var shown := threshold_reached or HudModel.steady_ledger_on()
	if is_equal_approx(f, hourglass_frac) and shown == hourglass_shown:
		return false
	hourglass_frac = f
	hourglass_shown = shown
	queue_redraw()
	return true


## The top-left plate shows when it has something: the Steady Ledger tier or the Hourglass.
func top_left_shown() -> bool:
	return ledger_on or hourglass_shown


func ledger_rect() -> Rect2:
	return Rect2(Vector2(MARGIN, MARGIN), LEDGER_SIZE)


func strip_rect() -> Rect2:
	var w := 58.0 + maxf(1.0, float(charge_capacity)) * LAMP_STEP
	return Rect2(Vector2(MARGIN, size.y - MARGIN - STRIP_H), Vector2(w, STRIP_H))


func seam_rect() -> Rect2:
	var w := 42.0 + maxf(1.0, float(seams_per_run)) * SEAM_STEP
	return Rect2(Vector2(floorf((size.x - w) * 0.5), size.y - MARGIN - STRIP_H), Vector2(w, STRIP_H))


func _layout() -> void:
	if _index_label == null:
		return
	var ir := index_rect()
	_index_label.position = ir.position + Vector2(7.0, 8.0)
	_index_label.size = Vector2(30.0, 8.0)
	_index_value.position = ir.position + Vector2(30.0, 6.0)
	_index_value.size = Vector2(ir.size.x - 37.0, 10.0)
	var lr := ledger_rect()
	_ledger_label.position = lr.position + Vector2(20.0, 8.0)
	_ledger_label.size = lr.size - Vector2(27.0, 10.0)
	var sr := strip_rect()
	_charges_label.position = sr.position + Vector2(7.0, 6.0)
	_charges_label.size = Vector2(40.0, 8.0)
	var mr := seam_rect()
	_seam_label.position = mr.position + Vector2(7.0, 6.0)
	_seam_label.size = Vector2(26.0, 8.0)
	hull_label.position = Vector2(MARGIN + 2.0, sr.position.y - 14.0)
	hull_label.size = Vector2(160.0, 12.0)
	queue_redraw()


func _draw() -> void:
	draw_count += 1
	Brass.plate(self, index_rect(), Pal.VOID_1)
	if top_left_shown():
		var lr := ledger_rect()
		Brass.plate(self, lr, Pal.PHOS_0 if ledger_on else Pal.VOID_1)
		if hourglass_shown:
			_draw_sand_glass(Rect2(lr.position + Vector2(7.0, (lr.size.y - GLASS_SIZE.y) * 0.5), GLASS_SIZE))
	var sr := strip_rect()
	Brass.plate(self, sr, Pal.VOID_1)
	for i in charge_capacity:
		Brass.lamp(self, sr.position + Vector2(54.0 + LAMP_STEP * i, sr.size.y * 0.5), LAMP_R, i < charges)
	var mr := seam_rect()
	Brass.plate(self, mr, Pal.VOID_1)
	for i in seams_per_run:
		var c := mr.position + Vector2(38.0 + SEAM_STEP * i, mr.size.y * 0.5)
		if i + 1 == seam_index:
			draw_circle(c, 3.5, Color(Pal.GAS_4, 0.3))
			draw_circle(c, 2.5, Pal.GAS_4)
			draw_circle(c, 1.0, Pal.GAS_5)
		elif i + 1 < seam_index:
			draw_circle(c, 2.0, Pal.GAS_2)   # passed: brass, spent
		else:
			draw_arc(c, 2.0, 0.0, TAU, 12, Pal.BONE_3, 1.0)   # to come: a chalk ring


## A brass-capped sand-glass: sand in the upper bulb = the budget left, the rest heaped below.
## Sand is GAS (brass light), glass is pearl; no phosphor (it is a clock, not a hull read).
func _draw_sand_glass(r: Rect2) -> void:
	var cx := r.position.x + r.size.x * 0.5
	var mid := r.position.y + r.size.y * 0.5
	var top := r.position.y + 1.5
	var bot := r.end.y - 1.5
	var hw := r.size.x * 0.5 - 0.5
	var upper := PackedVector2Array([Vector2(cx - hw, top), Vector2(cx + hw, top), Vector2(cx + 0.5, mid), Vector2(cx - 0.5, mid)])
	var lower := PackedVector2Array([Vector2(cx - 0.5, mid), Vector2(cx + 0.5, mid), Vector2(cx + hw, bot), Vector2(cx - hw, bot)])
	draw_colored_polygon(upper, Color(Pal.AETHER_4, 0.18))
	draw_colored_polygon(lower, Color(Pal.AETHER_4, 0.18))
	# upper sand: a triangle whose height is the fraction left, sitting on the neck
	var hu := (mid - top) * hourglass_frac
	if hu > 0.3:
		var w := hw * hourglass_frac
		draw_colored_polygon(PackedVector2Array([Vector2(cx - w, mid - hu), Vector2(cx + w, mid - hu), Vector2(cx, mid)]), Pal.GAS_4)
	# lower heap: the spent share
	var hl := (bot - mid) * (1.0 - hourglass_frac)
	if hl > 0.3:
		draw_colored_polygon(PackedVector2Array([Vector2(cx - hw, bot), Vector2(cx + hw, bot), Vector2(cx, bot - hl)]), Pal.GAS_3)
	draw_polyline(PackedVector2Array([upper[0], upper[3], lower[3], lower[2], lower[1], upper[2], upper[1], upper[0]]), Pal.AETHER_3, 1.0)
	draw_rect(Rect2(r.position.x - 1.0, r.position.y - 0.5, r.size.x + 2.0, 1.5), Pal.GAS_3)
	draw_rect(Rect2(r.position.x - 1.0, r.end.y - 1.0, r.size.x + 2.0, 1.5), Pal.GAS_2)


## True while W1-10 draws a wrong digit on the Vigil Index (automation `sector/warp`).
func index_smudged() -> bool:
	return _smudged


func _process(_delta: float) -> void:
	var live := liar != null and liar.glyph_live() and not HudModel.steady_ledger_on()
	if live != _smudged:
		_apply_glyph()


func _apply_glyph() -> void:
	if _index_value == null:
		return
	_smudged = liar != null and liar.glyph_live() and not HudModel.steady_ledger_on()
	if _smudged:
		var l := liar
		var txt := _index_value.text
		_index_value.glyph_filter = func(ch: String, index: int) -> Variant: return l.glyph_for(ch, index, txt)
	else:
		_index_value.glyph_filter = Callable()
