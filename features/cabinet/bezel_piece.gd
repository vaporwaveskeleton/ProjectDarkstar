class_name BezelPiece
extends RefCounted
## One piece of the printed bezel art (column-local coordinates, 0..80 × 0..360). The art is a list
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
