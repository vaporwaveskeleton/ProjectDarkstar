class_name CabinetScreenHud
extends Control
## The part of the Act 0 costume that lives on the CRT screen (WARP-001 W0-02, GDD §10): the Ledger
## Compass mini-map on top of the field and the cabinet maker mark. It sits on the HudLayer inside the arcade screen, under
## the CRT, so scanlines and curvature touch it; the printed bezel and the lit readouts do not (they
## are on the Rig, CabinetHud). Honest at T0. CabinetHud forwards `world`, `eaten` and `peel`.

const COMPASS := Rect2(250, 4, 140, 40)

var world: ArcadeWorld
var eaten := 0.0       ## 0 → 1: the Unmaking swallows the compass
var peel := 0.0        ## 0 → 1: the maker mark falls away with the costume


func _ready() -> void:
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	set_anchors_preset(Control.PRESET_FULL_RECT)


func _process(_delta: float) -> void:
	queue_redraw()


func _draw() -> void:
	if world != null and world.torus != null and eaten < 1.0:
		_draw_compass()
	if peel < 1.0 and eaten < 0.9:
		PixelText.draw_centered(self, 320.0, 351.0 + peel * 20.0, tr("CAB_MAKER"), Look.c(Pal.BONE_1))


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
