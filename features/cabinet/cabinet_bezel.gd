class_name CabinetBezel
extends RefCounted
## Shared layout and drawing for the Cabinet's 4:3 bezel (WARP-001 W0-01): the two printed side
## columns (BezelArt / BezelPrint), their readout windows and the coin door. Used by the attract
## screen and the in-game HUD so both show the same machine. The bezel is a real object, the 1983
## marketing print for the fake game, drawn in BezelInks (owner decision D-B); only the lamps behind
## the glass (readout text, the coin slit glow) are phosphor colours via Look.c.

const SIDE := 80.0                    ## bezel width: 640 − 2 × 80 = 480 = a 4:3 field at 360 high
const RIGHT_X := 640.0 - SIDE         ## the right column's offset in screen space
## The coin door on the right panel, in screen space.
const COIN_PLATE := Rect2(572, 252, 56, 80)

# --- Column-local layout (x 0..80, y 0..360). The 2 px nearest the screen is the key-black lip. ---
const LEFT_SCORE := Rect2(3, 16, 74, 46)       ## 1UP + score
const LEFT_VIGILS := Rect2(3, 66, 74, 38)      ## label + spare-ship icons
const LEFT_ART := Rect2(3, 108, 74, 124)       ## the Vigil illustration
const LEFT_HOWTO := Rect2(3, 236, 74, 82)      ## the how-to-play card
const LEFT_CREDIT := Rect2(3, 322, 74, 24)     ## credit count / INSERT CREDIT
const RIGHT_HI := Rect2(3, 16, 74, 46)         ## HI + value
const RIGHT_GLASS := Rect2(3, 66, 74, 54)      ## label + the magazine lamps
const RIGHT_ART := Rect2(3, 124, 74, 54)       ## the Sepulchre illustration
const RIGHT_SEPULCHRE := Rect2(3, 182, 74, 36) ## Sepulchre progress
const RIGHT_STICKER := Rect2(3, 222, 74, 26)   ## the starburst sticker

## Readout text starts MARGIN px into the column; the widest 2× readout is READOUT_W px.
## A window's inner width is 72 (1 px bevel each side), so text keeps 1 px clear of the bevel.
const MARGIN := 5.0
const READOUT_W := 70.0
const TEXT_H := 7.0                   ## PixelText glyph height at 1×

# --- Readout baselines (column-local y; PixelText draws up from the baseline) ---
const ONE_UP_BASE := 30.0
const SCORE_BASE := 56.0
const VIGILS_BASE := 80.0
const ICON_Y := 94.0
const MAX_ICONS := 5
const HI_BASE := 30.0
const HI_VALUE_BASE := 56.0
const GLASS_BASE := 80.0
const LAMP_Y := 92.0
const LAMP_STEP := 18.0
const SEPULCHRE_BASE := 192.0
const SEPULCHRE_VALUE_BASE := 212.0


## Column-local rect → screen space. `column` is &"left" or &"right".
static func to_screen(column: StringName, r: Rect2) -> Rect2:
	return Rect2(r.position + Vector2(RIGHT_X if column == &"right" else 0.0, 0.0), r.size)


## Every window that holds a lit readout, with its column.
static func windows() -> Array[Dictionary]:
	return [
		{"id": &"score", "column": &"left", "rect": LEFT_SCORE},
		{"id": &"vigils", "column": &"left", "rect": LEFT_VIGILS},
		{"id": &"credit", "column": &"left", "rect": LEFT_CREDIT},
		{"id": &"hi", "column": &"right", "rect": RIGHT_HI},
		{"id": &"glass", "column": &"right", "rect": RIGHT_GLASS},
		{"id": &"sepulchre", "column": &"right", "rect": RIGHT_SEPULCHRE},
	]


# --- Lit text helpers shared by the HUD and the attract frame -------------------------------------

## Cabinet-face text with `p` as the baseline (like draw_string).
static func text(ci: CanvasItem, p: Vector2, s: String, col: Color, scale: int = 1) -> void:
	PixelText.draw(ci, p - Vector2(0, PixelText.H * scale), s, col, scale)


## 1UP and the score in their window, `shift` px sideways (the HUD peels the column away).
static func draw_score(ci: CanvasItem, t: float, score_text: String, scale: int, shift: float = 0.0) -> void:
	var one_up := Look.c(Pal.GAS_4) if int(t * 2.0) % 2 == 0 else Look.c(Pal.GAS_2)
	text(ci, Vector2(MARGIN + shift, ONE_UP_BASE), ci.tr("CAB_1UP"), one_up)
	text(ci, Vector2(MARGIN + shift, SCORE_BASE), score_text, Look.c(Pal.BONE_5), scale)


## The credit window's text, split into lines that fit it ("INSERT CREDIT" wraps to two).
static func credit_lines(s: String) -> PackedStringArray:
	var inner := LEFT_CREDIT.size.x - 4.0
	if float(PixelText.width(s)) <= inner or s.find(" ") < 0:
		return PackedStringArray([s])
	var cut := s.rfind(" ", s.length() / 2 + 1)
	if cut < 0:
		cut = s.find(" ")
	return PackedStringArray([s.substr(0, cut), s.substr(cut + 1)])


## Column-local boxes of the lit credit lines (tops at 1× height, centred in the window).
static func credit_boxes(s: String) -> Array[Rect2]:
	var lines := credit_lines(s)
	var gap := 2.0
	var total := lines.size() * TEXT_H + (lines.size() - 1) * gap
	var y := LEFT_CREDIT.position.y + floorf((LEFT_CREDIT.size.y - total) * 0.5)
	var out: Array[Rect2] = []
	for l in lines:
		var w := float(PixelText.width(l))
		out.append(Rect2(roundf(LEFT_CREDIT.get_center().x - w * 0.5), y, w, TEXT_H))
		y += TEXT_H + gap
	return out


static func draw_credit(ci: CanvasItem, s: String, col: Color, shift: float = 0.0) -> void:
	var lines := credit_lines(s)
	var boxes := credit_boxes(s)
	for i in lines.size():
		PixelText.draw(ci, boxes[i].position + Vector2(shift, 0.0), lines[i], col)


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
