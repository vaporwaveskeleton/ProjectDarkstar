class_name CockpitFlame
extends Node2D
## The cockpit flame on the Vigil's hull (WARP-001 §4.1 cockpit-flame row, §4.2 L10): the Composure
## band shown by the flame's SHAPE, never its brightness. Fully honest: it reads the Composure
## component directly and never lies.
##   Clear     -> steady   (one still tongue)
##   Frayed    -> flickering (a forked tip whose two tongues trade length)
##   Unmoored  -> guttering (a low, wide flame that sinks and recovers)
##   Hollowed  -> hollow   (the steady outline around a void)
## One colour (PHOS-4, phosphor = truth, ART-001 §4 law 2) in every band: shape only, so it is never
## a luminance flash (photosensitivity safe in every mode). Motion is a deterministic time phase (no
## RNG), capped at max_motion_hz (ART-001 §12.9). Under Settings `reduced_motion` the phase is frozen:
## each band keeps its own static shape.
## Runtime vector (ART-001 §14). Lives under the Vigil's Facing/Visual; the sector injects `composure`.

const COLOR := Pal.PHOS_4
const HOLLOW_FILL := Pal.VOID_0

@export var stats: CockpitFlameStats
## The Composure to read (injected by the sector). Null = Clear (steady).
var composure: Composure

## Seconds of flame motion so far (frozen under reduced motion).
var phase_s: float = 0.0
var _drawn_band: int = -1


func _process(delta: float) -> void:
	if not reduced_motion():
		phase_s += delta
	var b := current_band()
	if b != _drawn_band or is_animated(b):
		_drawn_band = b
		queue_redraw()


func current_band() -> Composure.Band:
	return composure.band if is_instance_valid(composure) else Composure.Band.CLEAR


func reduced_motion() -> bool:
	return bool(SettingsService.get_value(&"reduced_motion"))


## True for the bands whose shape moves (flickering, guttering).
static func is_animated(b: Composure.Band) -> bool:
	return b == Composure.Band.FRAYED or b == Composure.Band.UNMOORED


static func is_hollow(b: Composure.Band) -> bool:
	return b == Composure.Band.HOLLOWED


## The flame's outline for band `b` at time `t` (seconds). Pure: tests and _draw share it.
static func shape_points(b: Composure.Band, t: float, s: CockpitFlameStats) -> PackedVector2Array:
	var bx := s.base_x_px
	var hw := s.half_width_px
	match b:
		Composure.Band.FRAYED:
			var w := sin(TAU * minf(s.flicker_hz, s.max_motion_hz) * t)
			var la := s.flicker_length_px - s.flicker_swing_px * (0.5 + 0.5 * w)
			var lb := s.flicker_length_px - s.flicker_swing_px * (0.5 - 0.5 * w)
			var mid := s.flicker_length_px * 0.5
			return PackedVector2Array([
				Vector2(bx - 1.0, 0.0), Vector2(bx, -hw), Vector2(bx + mid * 0.8, -hw),
				Vector2(bx + la, -hw * 0.5), Vector2(bx + mid, 0.0), Vector2(bx + lb, hw * 0.5),
				Vector2(bx + mid * 0.8, hw), Vector2(bx, hw)])
		Composure.Band.UNMOORED:
			var g := sin(TAU * minf(s.gutter_hz, s.max_motion_hz) * t)
			var l := s.gutter_length_px - s.gutter_swing_px * (0.5 + 0.5 * g)
			var gw := hw + 1.0
			return PackedVector2Array([
				Vector2(bx - 1.0, 0.0), Vector2(bx, -gw), Vector2(bx + l, 0.0), Vector2(bx, gw)])
		Composure.Band.HOLLOWED:
			return _teardrop(bx, hw, s.hollow_length_px)
	return _teardrop(bx, hw, s.steady_length_px)


static func _teardrop(bx: float, hw: float, length: float) -> PackedVector2Array:
	return PackedVector2Array([
		Vector2(bx - 1.0, 0.0), Vector2(bx, -hw), Vector2(bx + length * 0.45, -hw),
		Vector2(bx + length, 0.0), Vector2(bx + length * 0.45, hw), Vector2(bx, hw)])


## The fill colour for band `b`: the same phosphor in every band except the hollow's void core.
static func fill_color(b: Composure.Band) -> Color:
	return HOLLOW_FILL if is_hollow(b) else COLOR


## The outline colour: identical in every band (brightness never carries the band).
static func line_color(_b: Composure.Band) -> Color:
	return COLOR


func _draw() -> void:
	if stats == null:
		return
	var b := current_band()
	var pts := shape_points(b, phase_s, stats)
	draw_colored_polygon(pts, fill_color(b))
	var ring := pts.duplicate()
	ring.append(pts[0])
	draw_polyline(ring, line_color(b), 1.0)
