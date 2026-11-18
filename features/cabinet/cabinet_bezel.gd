class_name CabinetBezel
extends RefCounted
## Shared drawing for the Cabinet's 4:3 bezel (WARP-001 W0-01): the side panels and the coin door.
## Used by the attract screen and the in-game HUD so both show the same machine. Static draw
## calls only; text is passed in already translated. Placeholder art until ART-001 designs the
## bezel (owner, 2026-11-18: "a quick mockup is fine").

const SIDE := 80.0                    ## bezel width: 640 − 2 × 80 = 480 = a 4:3 field at 360 high
## The coin door on the right panel, in screen space.
const COIN_PLATE := Rect2(572, 252, 56, 80)


## One side panel at `x` (0 or 640 − SIDE), slid sideways by `shift`, with `crack` 0 → 1.
static func draw_panel(ci: CanvasItem, x: float, shift: float, crack: float = 0.0) -> void:
	var r := Rect2(x + shift, 0, SIDE, 360)
	ci.draw_rect(r, Look.c(Pal.VOID_0))
	var inner := r.grow(-6)
	ci.draw_rect(inner, Look.c(Pal.VOID_1))
	ci.draw_rect(inner, Look.c(Pal.VOID_3), false, 1.0)
	# cabinet trim: brass rivets down the inner edge
	var edge := r.position.x + (SIDE - 3.0 if x < 320.0 else 2.0)
	for y in range(12, 360, 24):
		ci.draw_rect(Rect2(edge, y, 1, 1), Look.c(Pal.GAS_1))
	if crack > 0.0:
		var cx := r.position.x + SIDE * 0.5
		var pts := PackedVector2Array()
		for k in 9:
			var y := 360.0 * k / 8.0
			pts.append(Vector2(cx + sin(k * 2.3 + x) * 14.0 * crack, y))
		ci.draw_polyline(pts, Look.c(Pal.BONE_4), 1.0)


## The coin slit inside a plate drawn at `plate`.
static func slit(plate: Rect2) -> Rect2:
	return Rect2(plate.position + Vector2(plate.size.x * 0.5 - 2.0, 12.0), Vector2(4, 22))


## The coin door: a brass-trimmed plate, the slit (lit by `glow` 0 → 1), the coin-return button
## and the price label.
static func draw_coin_plate(ci: CanvasItem, plate: Rect2, glow: float, price: String) -> void:
	ci.draw_rect(plate, Look.c(Pal.VOID_2))
	ci.draw_rect(plate, Look.c(Pal.GAS_1), false, 1.0)
	ci.draw_rect(plate.grow(-3), Look.c(Pal.GAS_0), false, 1.0)
	var s := slit(plate)
	ci.draw_rect(s.grow(2), Look.c(Pal.GAS_1).lerp(Look.c(Pal.GAS_4), clampf(glow, 0.0, 1.0)))
	ci.draw_rect(s, Look.c(Pal.VOID_0))
	var ret := Rect2(plate.position + Vector2(plate.size.x * 0.5 - 6.0, 44.0), Vector2(12, 8))
	ci.draw_rect(ret, Look.c(Pal.VOID_0))
	ci.draw_rect(ret, Look.c(Pal.GAS_2), false, 1.0)
	PixelText.draw_centered(ci, plate.get_center().x, plate.end.y - 14.0, price, Look.c(Pal.BONE_3))
