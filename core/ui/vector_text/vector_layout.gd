class_name VectorLayout
extends RefCounted
## Result of VectorText.layout(): polylines in logical px (origin = top-left of the text block,
## y down) plus line metrics. A polyline of one point is a dot.

var strokes: Array[PackedVector2Array] = []
var size := Vector2.ZERO            ## ink extent of the widest line x all lines
var box_width := 0.0                ## width lines are aligned within (max_width if wrapping, else widest line)
var ascent := 0.0                   ## cap-top to baseline of a line
var descent := 0.0                  ## baseline to the bottom of descenders
var line_height := 0.0              ## baseline to baseline
var line_widths := PackedFloat32Array()
var lines: PackedStringArray = PackedStringArray()   ## the text of each laid-out line (after wrapping)
var missing := PackedStringArray()  ## characters that had no glyph (drawn as boxes)


func line_count() -> int:
	return line_widths.size()
