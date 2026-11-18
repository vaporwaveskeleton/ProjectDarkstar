class_name CabinetScreenSpec
extends TunableResource
## The Act 0 arcade screen's grid (TECH-001 §1.3): the SubViewport size the tube is drawn at, and how
## much of it the on-screen HUD strip takes. Every screen-side script derives its sizes from this
## resource; none may hold a 640×360 literal. Engineering parameters, not SYS-001 numbers.

@export var grid: Vector2i = Vector2i(256, 304)   ## texels (width, height) of the arcade screen (owner, 2026-11-18)
## Rows at the TOP of the grid taken by the HUD strip (score, Vigils, scanner, readouts); the play
## view is the grid below it. Owner, 2026-11-18, Q-T31.
@export var hud_strip_height: int = 40


func tunable_properties() -> PackedStringArray:
	return PackedStringArray(["grid", "hud_strip_height"])


## The HUD strip, in grid coordinates.
func strip_rect() -> Rect2:
	return Rect2(0.0, 0.0, float(grid.x), float(hud_strip_height))


## The play view: the grid below the strip, in grid coordinates. The world is drawn into it.
func play_rect() -> Rect2:
	return Rect2(0.0, float(hud_strip_height), float(grid.x), float(grid.y - hud_strip_height))


func play_size() -> Vector2:
	return play_rect().size


## Where the Vigil is drawn: the centre of the play view.
func play_centre() -> Vector2:
	return play_rect().get_center()
