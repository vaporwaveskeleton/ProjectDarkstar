class_name ScreenFit
extends RefCounted
## Pure helper (no nodes): where the Act 0 arcade screen sits in the window (TECH-001 §1.3).
## The project stretches `canvas_items` / `expand` / fractional over a 640×360 logical reference, so
## the root canvas is scaled by `content_scale` = min(W/640, H/360). The arcade screen (its own
## SubViewport, `grid` texels) is shown at the whole-number step k = floor(min(W/640, H/360)),
## min 1, centred, so every texel is exactly k display px (the integer law holds for the screen only).
## The "hole" is the screen's footprint in the 640×360 reference: the grid at 1×, centred. The rig
## transform maps reference units to root canvas units so the hole lands exactly on the screen.
## `bezel_rect` is the whole window in those units (the bezel fills the window; no bars, any aspect).
## Everything here is a function of sizes; nothing reads the engine.

const REF := Vector2i(640, 360)


## Whole-number display px per screen texel.
static func integer_scale(window: Vector2i, ref: Vector2i = REF) -> int:
	return maxi(1, int(floorf(minf(float(window.x) / float(ref.x), float(window.y) / float(ref.y)))))


## Root canvas scale under `canvas_items` / `expand` (display px per logical px).
static func content_scale(window: Vector2i, ref: Vector2i = REF) -> float:
	return maxf(minf(float(window.x) / float(ref.x), float(window.y) / float(ref.y)), 0.0001)


## The screen's size in display px.
static func screen_display_size(window: Vector2i, grid: Vector2i, ref: Vector2i = REF) -> Vector2i:
	return grid * integer_scale(window, ref)


## The screen's rectangle in window px, centred, origin on a whole display px.
static func screen_rect_physical(window: Vector2i, grid: Vector2i, ref: Vector2i = REF) -> Rect2i:
	var size := screen_display_size(window, grid, ref)
	return Rect2i((window - size) / 2, size)


## The hole in 640×360 reference units: the grid at 1×, centred in the reference.
static func hole_rect(grid: Vector2i, ref: Vector2i = REF) -> Rect2:
	return Rect2(Vector2(ref - grid) * 0.5, Vector2(grid))


## Reference units → root canvas units, so the hole coincides with the physical screen rect and
## one reference unit is k display px. Position the cabinet rig with this.
static func rig_transform(window: Vector2i, grid: Vector2i, ref: Vector2i = REF) -> Transform2D:
	var s := content_scale(window, ref)
	var k := float(integer_scale(window, ref))
	var origin := Vector2(screen_rect_physical(window, grid, ref).position) / s - hole_rect(grid, ref).position * (k / s)
	return Transform2D(Vector2(k / s, 0.0), Vector2(0.0, k / s), origin)


## Window px → arcade-screen grid coordinates (fractional; outside the grid when off the screen).
static func window_to_screen(window: Vector2i, grid: Vector2i, p: Vector2, ref: Vector2i = REF) -> Vector2:
	var r := screen_rect_physical(window, grid, ref)
	return (p - Vector2(r.position)) / float(integer_scale(window, ref))


## Arcade-screen grid coordinates → window px.
static func screen_to_window(window: Vector2i, grid: Vector2i, p: Vector2, ref: Vector2i = REF) -> Vector2:
	var r := screen_rect_physical(window, grid, ref)
	return Vector2(r.position) + p * float(integer_scale(window, ref))


## The whole window in rig units (reference units: one unit = k display px), so the bezel can fill
## every pixel at any aspect ratio (no bars). The hole stays where `hole_rect` puts it; the rect grows
## around it to the window's aspect. Lay the bezel out against this, never against REF.
static func bezel_rect(window: Vector2i, grid: Vector2i, ref: Vector2i = REF) -> Rect2:
	var k := float(integer_scale(window, ref))
	var phys := Vector2(screen_rect_physical(window, grid, ref).position)
	return Rect2(hole_rect(grid, ref).position - phys / k, Vector2(window) / k)
