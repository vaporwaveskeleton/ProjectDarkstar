class_name CabinetBezel
extends RefCounted
## Shared layout and drawing for the Cabinet's printed bezel (WARP-001 W0-01): the two printed side
## columns (BezelArt / BezelPrint) flush against the screen hole, the plain print field around it
## (BezelField) and the coin door. Used by the attract screen and the in-game HUD so both show the
## same machine. The bezel is a real object, the 1983 marketing print for the fake game, drawn in
## BezelInks (owner decision D-B). It carries no readouts: score, Vigils, scanner and the rest are
## lit on the screen's HUD strip (CabinetScreenHud, P5). PR C re-composes it.

const SIDE := 80.0                    ## width of each printed column; both sit flush against the screen hole
const SPEC := "res://data/cabinet/cabinet_screen.tres"
const EDGE := 2.0                     ## the key-black tube-mask edge above and below the hole
## The coin door on the right panel, column-local (see `coin_plate`).
const COIN_PLATE_LOCAL := Rect2(12, 252, 56, 80)

# --- Column-local art areas (x 0..80, y 0..360). The 2 px nearest the screen is the key-black lip. ---
const LEFT_ART := Rect2(3, 108, 74, 124)       ## the Vigil illustration
const LEFT_HOWTO := Rect2(3, 236, 74, 82)      ## the how-to-play card
const RIGHT_ART := Rect2(3, 124, 74, 54)       ## the Sepulchre illustration
const RIGHT_STICKER := Rect2(3, 222, 74, 26)   ## the starburst sticker


## The screen hole in rig (640×360 reference) units: the spec's grid at 1×, centred.
static func hole() -> Rect2:
	return ScreenFit.hole_rect((load(SPEC) as CabinetScreenSpec).grid)


## The left column's x: flush against the hole's left side.
static func left_x() -> float:
	return hole().position.x - SIDE


## The right column's x: flush against the hole's right side.
static func right_x() -> float:
	return hole().end.x


## The coin door in rig units (on the right column).
static func coin_plate() -> Rect2:
	return Rect2(COIN_PLATE_LOCAL.position + Vector2(right_x(), 0.0), COIN_PLATE_LOCAL.size)


## Column-local rect → rig units. `column` is &"left" or &"right".
static func to_screen(column: StringName, r: Rect2) -> Rect2:
	return Rect2(r.position + Vector2(right_x() if column == &"right" else left_x(), 0.0), r.size)


# --- The coin door ---------------------------------------------------------------------------------

## The coin slit inside a plate drawn at `plate`.
static func slit(plate: Rect2) -> Rect2:
	return Rect2(plate.position + Vector2(plate.size.x * 0.5 - 2.0, 12.0), Vector2(4, 22))


## The coin door: a chrome plate with brass screws, the slit (lit by `glow` 0 → 1) in a key-black
## surround, the coin-return button and the orange price sticker. The slit glow is a lamp.
static func draw_coin_plate(ci: CanvasItem, plate: Rect2, glow: float, price: String, inks: BezelInks = null) -> void:
	var ink := inks if inks != null else (BezelInks.default() as BezelInks)
	var black := ink.key_black
	var light := ink.chrome_light
	var dark := ink.chrome_dark
	var face := dark.lerp(light, 0.55)
	ci.draw_rect(plate.grow(1), black)
	ci.draw_rect(plate, face)
	ci.draw_rect(Rect2(plate.position, Vector2(plate.size.x, 1)), light)
	ci.draw_rect(Rect2(plate.position, Vector2(1, plate.size.y)), light)
	ci.draw_rect(Rect2(plate.position + Vector2(0, plate.size.y - 1), Vector2(plate.size.x, 1)), dark)
	ci.draw_rect(Rect2(plate.position + Vector2(plate.size.x - 1, 0), Vector2(1, plate.size.y)), dark)
	# brass screws in the corners
	for sx in [5.0, plate.size.x - 6.0]:
		for sy in [5.0, plate.size.y - 6.0]:
			var sp := plate.position + Vector2(sx, sy)
			ci.draw_rect(Rect2(sp - Vector2(1, 1), Vector2(3, 3)), black)
			ci.draw_rect(Rect2(sp, Vector2(1, 1)), ink.brass)
			ci.draw_rect(Rect2(sp - Vector2(1, 0), Vector2(3, 1)), ink.brass)
			ci.draw_rect(Rect2(sp - Vector2(0, 1), Vector2(1, 3)), ink.brass)
	# the slit: key-black surround, the lamp glow, the opening
	var s := slit(plate)
	ci.draw_rect(s.grow(4), dark)
	ci.draw_rect(s.grow(3), black)
	ci.draw_rect(s.grow(2), Look.c(Pal.GAS_0).lerp(Look.c(Pal.GAS_4), clampf(glow, 0.0, 1.0)))
	ci.draw_rect(s, black)
	# coin-return button
	var ret := Rect2(plate.position + Vector2(plate.size.x * 0.5 - 6.0, 44.0), Vector2(12, 8))
	ci.draw_rect(ret.grow(1), black)
	ci.draw_rect(ret, light)
	ci.draw_rect(Rect2(ret.position + Vector2(0, ret.size.y - 2), Vector2(ret.size.x, 2)), dark)
	ci.draw_rect(Rect2(ret.position + Vector2(3, 3), Vector2(6, 1)), black)
	# the orange price sticker
	var sticker := Rect2(plate.position + Vector2(3, 57), Vector2(plate.size.x - 6.0, 15))
	ci.draw_rect(sticker.grow(1), black)
	ci.draw_rect(sticker, ink.orange)
	ci.draw_rect(Rect2(sticker.position, Vector2(sticker.size.x, 1)), ink.yellow)
	PixelText.draw_centered(ci, sticker.get_center().x, sticker.position.y + 4.0, price, black)
