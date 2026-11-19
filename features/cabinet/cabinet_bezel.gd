class_name CabinetBezel
extends RefCounted
## Shared layout and drawing for the Cabinet's printed bezel (WARP-001 W0-01): the two printed side
## columns (BezelArt / BezelPrint) flush against the screen hole, the plain print field around it
## (BezelField) and the coin door (drawn by CoinDoorFace). Used by the attract screen and the in-game HUD so both show the
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
# Features are plate-local (0..56 × 0..80); CoinDoorFace (shaders/cabinet/coin_door.gdshader) draws them.

const SLOT_C := Vector2(28, 20)           ## the coin slot's centre
const SLOT_HALF := Vector2(1.6, 9.0)      ## half size of the drawn slot opening
const BUTTON_C := Vector2(28, 40)         ## the small lit reject button's centre
const BUTTON_HALF := Vector2(7, 4)        ## 14 × 8, unlettered
const LABEL_Y := 52.0                     ## the printed price label's centre y
const LABEL_MARGIN := 0.3                 ## clear paper each side of the text, plate units
const LABEL_MAX_HALF_X := 23.8            ## widest strip inside the door's inner panel (door 27.6 - rim 3.2 - 0.6)
const LABEL_HALF_Y := 5.5                 ## 7 px text + 2 units of paper above and below (rivets sit in the margin)


## Half size of the lit reject button.
static func button_half() -> Vector2:
	return BUTTON_HALF


## The button's centre.
static func button_center() -> Vector2:
	return BUTTON_C


## The label's centre: the text starts on a whole unit, so an odd-width text puts the strip half a unit right of the door centre.
static func label_center() -> Vector2:
	var w := PixelText.width(TranslationServer.translate("CAB_COIN_PRICE"), 1)
	return Vector2(28.0 + (0.5 if w % 2 == 1 else 0.0), LABEL_Y)


## Half size of the printed price label: the translated price's width at scale 1 plus a margin, clamped to
## the door's inner panel. `fits_price()` says whether the text really fits at scale 1.
static func label_half() -> Vector2:
	var w := float(PixelText.width(TranslationServer.translate("CAB_COIN_PRICE"), 1))
	return Vector2(minf(w * 0.5 + LABEL_MARGIN, LABEL_MAX_HALF_X), LABEL_HALF_Y)


## True while the price text (scale 1) fits on the label with no clipping.
static func fits_price() -> bool:
	return float(PixelText.width(TranslationServer.translate("CAB_COIN_PRICE"), 1)) * 0.5 + LABEL_MARGIN <= LABEL_MAX_HALF_X + 0.0001


## The coin slit inside a plate drawn at `plate`: exactly the drawn slot opening.
static func slit(plate: Rect2) -> Rect2:
	return Rect2(plate.position + SLOT_C - SLOT_HALF, SLOT_HALF * 2.0)


## The lit reject button's rect inside a plate drawn at `plate`.
static func price_button(plate: Rect2) -> Rect2:
	return Rect2(plate.position + BUTTON_C - BUTTON_HALF, BUTTON_HALF * 2.0)


## The printed price label's rect inside a plate drawn at `plate`.
static func price_label(plate: Rect2) -> Rect2:
	var h := label_half()
	return Rect2(plate.position + label_center() - h, h * 2.0)


## The price printed in dark ink on the label (placeholder until VectorText, PR C).
static func draw_price(ci: CanvasItem, plate: Rect2, price: String, inks: BezelInks = null) -> void:
	var ink := inks if inks != null else (BezelInks.default() as BezelInks)
	var b := price_label(plate)
	var x := b.get_center().x - PixelText.width(price) * 0.5
	PixelText.draw(ci, Vector2(x, roundf(b.get_center().y - PixelText.H * 0.5)), price, ink.key_black)
