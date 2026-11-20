class_name BezelPiece
extends RefCounted
## One piece of the printed bezel art (column-local coordinates, 0..CabinetBezel.SIDE × 0..360). The art is a list
## of these, sorted by `z` (then build order). A BezelPrint draws the list once. Because every
## piece has an id, a pivot and a z, the later "zoom destruction" (peel, crack, curl, decay) can
## move, rotate or drop single pieces without a redraw of the rest: the list is the seam.

enum Kind { FILL, OUTLINE, HALFTONE, STROKE, PIXELS, TEXT }

var id: StringName = &""
var column: StringName = &"left"            ## &"left" or &"right"
var kind: int = Kind.FILL
var points := PackedVector2Array()          ## polygon / polyline / pixel positions / [text origin]
var ink: StringName = &"key_black"          ## a BezelInks id
var z := 0
var pivot := Vector2.ZERO                   ## rotation / scale centre for per-piece effects
var width := 1.0                            ## stroke width, or pixel size for PIXELS
var text_key := ""                          ## TEXT: the tr() key
var centered := false                       ## TEXT: points[0].x is the centre, not the left edge
var order := 0                             ## build order, the tie-break inside a z
## HALFTONE tone ramp: the polygon is a screened tone, its per-vertex tone (0 = no ink, 1 = solid) runs
## linearly from `tone_a` to `tone_b` (TONE_LINEAR) or radially round `tone_a` between radii
## `tone_b.x` and `tone_b.y` (TONE_RADIAL). The print shader turns the tone into round dots with dot gain.
const TONE_LINEAR := 1
const TONE_RADIAL := 2
var tone_mode := TONE_LINEAR
var tone_a := Vector2.ZERO
var tone_b := Vector2.ZERO
var tone0 := 1.0
var tone1 := 0.0
var stroke_w := 0.0                         ## TEXT: stroke width in logical px (`width` is the cap height)
var tracking := 0.0                         ## TEXT: extra px between glyphs
var rot := 0.0                              ## TEXT: radians about its anchor
var text_part := 0                          ## TEXT: 0 the whole string, 1 its first half, 2 its second half (the big logo stacks over two lines)


## Tone (0..1) of the point `p` along this piece's ramp.
func tone_at(p: Vector2) -> float:
	if tone_mode == TONE_RADIAL:
		var span := maxf(tone_b.y - tone_b.x, 0.001)
		return lerpf(tone0, tone1, clampf((p.distance_to(tone_a) - tone_b.x) / span, 0.0, 1.0))
	var axis := tone_b - tone_a
	var len2 := maxf(axis.length_squared(), 0.001)
	return lerpf(tone0, tone1, clampf((p - tone_a).dot(axis) / len2, 0.0, 1.0))


static func make(p_id: StringName, p_column: StringName, p_kind: int, p_points: PackedVector2Array,
		p_ink: StringName, p_z: int) -> BezelPiece:
	var b := BezelPiece.new()
	b.id = p_id
	b.column = p_column
	b.kind = p_kind
	b.points = p_points
	b.ink = p_ink
	b.z = p_z
	var lo := Vector2(INF, INF)
	var hi := Vector2(-INF, -INF)
	for p in p_points:
		lo = lo.min(p)
		hi = hi.max(p)
	b.pivot = (lo + hi) * 0.5 if p_points.size() > 0 else Vector2.ZERO
	return b
