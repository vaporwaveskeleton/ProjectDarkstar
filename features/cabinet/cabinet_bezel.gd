class_name CabinetBezel
extends RefCounted
## Shared layout and drawing for the Cabinet's printed bezel (WARP-001 W0-01): the two printed side
## columns (BezelArt / BezelPrint) flush against the screen hole, the plain print field around it
## (BezelField) and the coin door (drawn by CoinDoorFace). Used by the attract screen and the in-game HUD so both show the
## same machine. The bezel is a real object, the 1983 marketing print for the fake game, drawn in
## BezelInks (owner decision D-B). It carries no readouts: score, Vigils, scanner and the rest are
## lit on the screen's HUD strip (CabinetScreenHud, P5). PR C re-composes it.

## Width of each printed column; both sit flush against the screen hole. 152 since the surround pass
## (owner direction 2026-11-19): the sheet spans x 40..600 of the 640 reference, so a 16:9 window is all
## cabinet but a sliver of side panel each side, and wider windows show the ArcadeBackdrop beyond it.
const SIDE := 152.0
const SPEC := "res://data/cabinet/cabinet_screen.tres"
const EDGE := 2.0                     ## the key-black tube-mask edge above and below the hole
## The coin door on the right panel, column-local (see `coin_plate`).
const COIN_PLATE_LOCAL := Rect2(12, 252, 56, 80)

# --- Column-local art areas (x 0..SIDE, y 0..360). The 2 px nearest the screen is the key-black lip. ---
const LEFT_ART := Rect2(0, 92, 152, 250)        ## the Vigil illustration and its geodes (full bleed, runs off the outer edge)
const LEFT_HOWTO := Rect2(8, 270, 72, 58)       ## ✱ the small how-to card in the lower outer corner (real-bezel proportions)
const RIGHT_ART := Rect2(0, 70, 152, 290)       ## the Sepulchre and the Choir crag (full bleed)
const RIGHT_STICKER := Rect2(3, 222, 74, 26)   ## the die-cut NEW! sticker


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
# Features are plate-local (0..56 × 0..80); CoinDoorFace (shaders/cabinet/coin_door.gdshader) draws them.
const SLOT_C := Vector2(28, 20)           ## the coin slot's centre
const SLOT_HALF := Vector2(1.6, 9.0)      ## half size of the drawn slot opening
const PLATE_Y := 46.0                     ## the lit reject / price plate's centre y
const PLATE_MARGIN_X := 3.2               ## clear plate each side of the lettering, plate units
const PLATE_MARGIN_Y := 2.6               ## clear plate above and below it
const PLATE_MAX_HALF_X := 23.8            ## widest plate inside the door's inner panel


static func _surface() -> CabinetSurface:
	return CabinetSurface.default() as CabinetSurface


## The price lettering's painted size (VectorText at the surface's ✱ cap height).
static func price_size() -> Vector2:
	var s := _surface()
	return BezelText.ink_size(TranslationServer.translate("CAB_COIN_PRICE"), s.price_cap, s.price_stroke, s.price_tracking)


## The plate's centre: the door's centre line, at PLATE_Y.
static func button_center() -> Vector2:
	return Vector2(28.0, PLATE_Y)


## Half size of the lit reject / price plate: the lettering plus a margin, clamped to the door's inner
## panel. `fits_price()` says whether the lettering really fits.
static func button_half() -> Vector2:
	var sz := price_size()
	return Vector2(minf(sz.x * 0.5 + PLATE_MARGIN_X, PLATE_MAX_HALF_X), sz.y * 0.5 + PLATE_MARGIN_Y)


## True while the price lettering fits on the plate with no clipping.
static func fits_price() -> bool:
	return price_size().x * 0.5 + PLATE_MARGIN_X <= PLATE_MAX_HALF_X + 0.0001


## The coin slit inside a plate drawn at `plate`: exactly the drawn slot opening.
static func slit(plate: Rect2) -> Rect2:
	return Rect2(plate.position + SLOT_C - SLOT_HALF, SLOT_HALF * 2.0)


## The lit reject / price plate's rect inside a door drawn at `plate`. It carries the price lettering.
static func price_button(plate: Rect2) -> Rect2:
	var h := button_half()
	return Rect2(plate.position + button_center() - h, h * 2.0)


## The price printed in dark ink on the backlit lens, in VectorText (the ink sits on the lens, so it is
## drawn with the lens's own dark ink and nothing else). `cache` is the caller's mesh cache.
static func draw_price(ci: CanvasItem, cache: Dictionary, plate: Rect2, price: String, inks: BezelInks = null) -> void:
	var ink := inks if inks != null else (BezelInks.default() as BezelInks)
	var s := _surface()
	var b := price_button(plate)
	var sz := BezelText.ink_size(price, s.price_cap, s.price_stroke, s.price_tracking)
	var top := b.get_center().y - sz.y * 0.5 + s.price_stroke * 0.5
	BezelText.draw(ci, cache, price, Vector2(b.get_center().x, top), true, s.price_cap, s.price_stroke, s.price_tracking, ink.key_black)


# --- The sheet (PR C pass 2) -------------------------------------------------------------------------
const MARQUEE_Y := 1.5            ## the backlit sign's top, rig units (the top 28 above the screen)
const MARQUEE_H := 23.0           ## its height: the sign ends just above the tube-mask ring


## The one printed sheet in rig units: the two columns and the opening between them. Everything outside
## it (on ultrawide and 16:10) is the room falling into darkness, with a hint of the cabinet's side.
static func sheet_x() -> Vector2:
	return Vector2(left_x(), right_x() + SIDE)


## The backlit marquee sign above the screen, in rig units: a little wider than the opening.
static func marquee() -> Rect2:
	var h := hole()
	return Rect2(h.position.x - 4.0, MARQUEE_Y, h.size.x + 8.0, MARQUEE_H)


# --- The control panel (Q-T34) ----------------------------------------------------------------------
## The strip under the screen, across the opening's width: the 28 reference units below the hole (less the
## key-black tube-mask edge), the cabinet's control-panel lip. The attract menu's pushbuttons sit here, on
## the print, never over the tube.
const PANEL_SLOT_X: Array[float] = [56.0, 148.0]              ## ✱ art placement: slot centres, panel-local x (START, SERVICE)
const PANEL_SLOT_W: Array[float] = [36.0, 32.0]               ## each slot's width: the button, its ring and its printed label


static func control_panel() -> Rect2:
	var h := hole()
	return Rect2(h.position.x, h.end.y + EDGE, h.size.x, float(ScreenFit.REF.y) - h.end.y - EDGE)


## Slot `i` (0 start, 1 service) in rig units: full height of the panel, centred on its x.
static func panel_slot(i: int) -> Rect2:
	var p := control_panel()
	return Rect2(p.position.x + PANEL_SLOT_X[i] - PANEL_SLOT_W[i] * 0.5, p.position.y, PANEL_SLOT_W[i], p.size.y)


# --- The power rocker (pass 2c) ----------------------------------------------------------------------
## The POWER rocker module sits on the right column under the coin door, where the apron vent was (the vent
## is shortened to make room): column-local, so it moves with the column and never meets the door (ends at y 332),
## the vent or the bottom grille (starts at y 350). It quits the game after a confirmation.
const POWER_LOCAL := Rect2(31.0, 334.5, 44.0, 14.5)           ## ✱ art placement: label on the left, rocker on the right
const APRON_VENT_LOCAL := Rect2(6.0, 338.0, 20.0, 10.0)       ## ✱ the shortened vent under the coin door


static func power_rocker() -> Rect2:
	return Rect2(POWER_LOCAL.position + Vector2(right_x(), 0.0), POWER_LOCAL.size)
