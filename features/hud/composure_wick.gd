class_name ComposureWick
extends Control
## The Composure wick (ART-001 §12.5: 64 × 16, an oil-lamp wick, never a bar; WARP-001 §4.1
## bottom-right). Q-T119: the flame height steps by Composure BAND only (four heights from
## ComposureWickStats), never by the value, so there is no readable number.
## Fully honest: never lied about, never eaten (WARP-001 §4.1). Static drawing (no motion, no
## flashes); it redraws only when the band changes. Runtime vector (ART-001 §14), Pal colours.

const BRASS := Pal.GAS_2
const WICK := Pal.BONE_2
const FLAME := Pal.GAS_4
const HOLLOW_FILL := Pal.VOID_0
## Lamp layout inside the 64 × 16 box (✱ drawing geometry, not tunables).
const BASE_TOP := 13.0
const WICK_TOP := 11.0

@export var stats: ComposureWickStats
## The Composure to read (injected by the sector). Null = Clear.
var composure: Composure

var drawn_band: int = -1


func _ready() -> void:
	mouse_filter = Control.MOUSE_FILTER_IGNORE


func _process(_delta: float) -> void:
	refresh()


## Redraws when the band changed. Returns true on a redraw.
func refresh() -> bool:
	var b := current_band()
	if b == drawn_band:
		return false
	drawn_band = b
	queue_redraw()
	return true


func current_band() -> Composure.Band:
	return composure.band if is_instance_valid(composure) else Composure.Band.CLEAR


## The flame height (px) drawn now: one of four band steps.
func flame_height() -> float:
	return stats.height_for(current_band()) if stats else 0.0


## The flame outline standing on the wick top at `cx`, `h` px tall.
static func flame_points(cx: float, h: float, hw: float) -> PackedVector2Array:
	var w := minf(hw, maxf(1.0, h * 0.5))
	return PackedVector2Array([
		Vector2(cx, WICK_TOP), Vector2(cx - w, WICK_TOP - h * 0.35),
		Vector2(cx, WICK_TOP - h), Vector2(cx + w, WICK_TOP - h * 0.35)])


func _draw() -> void:
	if stats == null:
		return
	var cx := floorf(size.x * 0.5)
	draw_rect(Rect2(cx - 10.0, BASE_TOP, 21.0, size.y - BASE_TOP), BRASS)
	draw_rect(Rect2(cx, WICK_TOP, 1.0, BASE_TOP - WICK_TOP), WICK)
	var b := current_band()
	var pts := flame_points(cx + 0.5, stats.height_for(b), stats.flame_half_width_px)
	draw_colored_polygon(pts, HOLLOW_FILL if b == Composure.Band.HOLLOWED else FLAME)
	var ring := pts.duplicate()
	ring.append(pts[0])
	draw_polyline(ring, FLAME, 1.0)
