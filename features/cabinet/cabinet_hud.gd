class_name CabinetHud
extends Control
## The Act 0 costume around the field (WARP-001 W0-01, W0-02, W0-04): a 4:3 bezel with the 1UP /
## score strip, lives, the glass-lamp Charge pips, and the Ledger Compass mini-map (GDD §10) on
## top of the field. Everything here is honest at T0. `peel` 0 → 1 tears the costume away
## (W0-07/W0-08); `eaten` 0 → 1 lets the Unmaking swallow the readouts.

const SIDE := CabinetBezel.SIDE       ## bezel width: 640 − 2 × 80 = 480 = a 4:3 field at 360 high
const COMPASS := Rect2(250, 4, 140, 40)

var world: ArcadeWorld
var score := 0
var hi_score := 0
var lives := 3
var charges := 0
var magazine := 5
var peel := 0.0
var eaten := 0.0
var crack := 0.0
var _t := 0.0


func _ready() -> void:
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	set_anchors_preset(Control.PRESET_FULL_RECT)


func _process(delta: float) -> void:
	_t += delta
	queue_redraw()


func _draw() -> void:
	if peel < 1.0:
		CabinetBezel.draw_panel(self, 0.0, -peel * (SIDE + 20.0), crack)
		CabinetBezel.draw_panel(self, 640.0 - SIDE, peel * (SIDE + 20.0), crack)
		var plate := CabinetBezel.COIN_PLATE
		plate.position.x += peel * (SIDE + 20.0)
		CabinetBezel.draw_coin_plate(self, plate, 0.0, tr("CAB_COIN_PRICE"))
		_draw_left_text(-peel * (SIDE + 20.0))
		_draw_right_text(peel * (SIDE + 20.0))
	if world != null and world.torus != null and eaten < 1.0:
		_draw_compass()
	if peel < 1.0 and eaten < 0.9:
		PixelText.draw_centered(self, 320.0, 351.0 + peel * 20.0, tr("CAB_MAKER"), Look.c(Pal.BONE_1))


## Cabinet face (5 × 7, ART-001 §11): `p` is the baseline, as with draw_string.
func _text(p: Vector2, s: String, col: Color, _size: int = 8) -> void:
	PixelText.draw(self, p - Vector2(0, PixelText.H), s, col, 1)


func _draw_left_text(shift: float) -> void:
	var x := 12.0 + shift
	if eaten < 0.3:
		var one_up := Look.c(Pal.GAS_4) if int(_t * 2.0) % 2 == 0 else Look.c(Pal.GAS_2)
		_text(Vector2(x, 30), tr("CAB_1UP"), one_up, 10)
		_text(Vector2(x, 46), LocFormat.format_int(score), Look.c(Pal.BONE_5), 10)
	if eaten < 0.6:
		_text(Vector2(x, 78), tr("CAB_VIGILS"), Look.c(Pal.BONE_2))
		for i in maxi(0, lives - 1):
			var c := Vector2(x + 6 + i * 14, 94)
			var hull := PackedVector2Array([c + Vector2(0, -5), c + Vector2(4, 4), c + Vector2(0, 2), c + Vector2(-4, 4)])
			Pal.glow_polyline(self, hull, Look.c(Pal.GAS_4), Look.c(Pal.GAS_1))
	if eaten < 0.9:
		var blink := int(_t * 1.5) % 2 == 0
		_text(Vector2(x, 330), tr("CAB_CREDIT"), Look.c(Pal.BONE_1) if blink else Look.c(Pal.BONE_0))


func _draw_right_text(shift: float) -> void:
	var x := 640.0 - SIDE + 12.0 + shift
	if eaten < 0.3:
		_text(Vector2(x, 30), tr("CAB_HI"), Look.c(Pal.BONE_2), 10)
		_text(Vector2(x, 46), LocFormat.format_int(maxi(hi_score, score)), Look.c(Pal.BONE_4), 10)
	if eaten < 0.6:
		_text(Vector2(x, 78), tr("CAB_GLASS"), Look.c(Pal.BONE_2))
		for i in magazine:
			var c := Vector2(x + 4 + (i % 3) * 18, 92 + (i / 3) * 18)
			var full := i < charges
			var lamp := PackedVector2Array([c + Vector2(0, -6), c + Vector2(4, 0), c + Vector2(0, 6), c + Vector2(-4, 0)])
			if full:
				draw_colored_polygon(lamp, Look.c(Pal.PHOS_3))
				draw_rect(Rect2(c - Vector2(0, 1), Vector2(1, 2)), Look.c(Pal.PHOS_5))
			Pal.glow_polyline(self, lamp, Look.c(Pal.PHOS_4) if full else Look.c(Pal.VOID_4), Look.c(Pal.VOID_2))


## The Ledger Compass: the whole torus at a glance (the Sinistar scanner homage). Honest at T0.
func _draw_compass() -> void:
	var r := COMPASS
	var size := world.torus.size
	draw_rect(r, Look.c(Pal.VOID_0))
	draw_rect(r, Look.c(Pal.BONE_1) if eaten <= 0.0 else Look.c(Pal.BONE_0), false, 1.0)
	var scale := Vector2((r.size.x - 4.0) / size.x, (r.size.y - 4.0) / size.y)
	var o := r.position + Vector2(2, 2)
	var to_c := func(p: Vector2) -> Vector2: return (o + p * scale).round()
	# the view window
	var view := Rect2(to_c.call(world.torus.wrap(world.view_centre - Vector2(240, 180))), Vector2(480, 360) * scale)
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
