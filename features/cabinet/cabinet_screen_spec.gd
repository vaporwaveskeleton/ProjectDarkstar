class_name CabinetScreenSpec
extends TunableResource
## The Act 0 arcade screen's grid (TECH-001 §1.3): the SubViewport size the tube is drawn at, and how
## much of it the on-screen HUD strip takes. Every screen-side script derives its sizes from this
## resource; none may hold a 640×360 literal. Engineering parameters, not SYS-001 numbers.

## ✱ The maker mark's band: its top sits this far above the grid's foot (text 7 px tall, drawn inside
## the play view). Single source for the HUD layout and for anything that must stay clear of it.
const MAKER_BAND_PX := 10.0

@export var grid: Vector2i = Vector2i(256, 304)   ## texels (width, height) of the arcade screen (owner, 2026-11-18)
## Rows at the TOP of the grid taken by the HUD strip (score, Vigils, scanner, readouts); the play
## view is the grid below it. Owner, 2026-11-18, Q-T31; 48 since SYS-001 §1.7 (Q-T367), so the play view is 256 × 256.
@export var hud_strip_height: int = 48


func tunable_properties() -> PackedStringArray:
	return PackedStringArray(["grid", "hud_strip_height", "compass_box"])


## The HUD strip, in grid coordinates.
func strip_rect() -> Rect2:
	return Rect2(0.0, 0.0, float(grid.x), float(hud_strip_height))


## The play view: the grid below the strip, in grid coordinates. The world is drawn into it.
func play_rect() -> Rect2:
	return Rect2(0.0, float(hud_strip_height), float(grid.x), float(grid.y - hud_strip_height))


## The play view minus the maker-mark band at its foot: the area chalk and other overlays may use
## without crossing cabinet text.
func playfield_rect() -> Rect2:
	var r := play_rect()
	r.size.y -= MAKER_BAND_PX
	return r


func play_size() -> Vector2:
	return play_rect().size


## Where the Vigil is drawn: the centre of the play view.
func play_centre() -> Vector2:
	return play_rect().get_center()
## ✱ The Ledger Compass box in strip coordinates (SYS-001 §1.7, Q-T368): 44 × 44 at the top centre of the strip.
## Its inner 40 × 40 is the scanner window; the world scale is `CabinetTuning.compass_px_per_dot`.
@export var compass_box: Rect2 = Rect2(106, 2, 44, 44)


## The scanner window: the compass box minus its 2 px frame, 40 × 40.
func compass_inner() -> Rect2:
	return compass_box.grow(-2.0)
