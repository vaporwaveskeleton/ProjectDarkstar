class_name LedgerCompassMarkers
extends Control
## The Ledger Compass's marker layer (TECH-001 §5.4): one small `_draw` per frame, a dot per marker.
## It draws what it is given (widget-local points from the presented HudModel) and never applies a
## lie itself. Pal colours only (LedgerCompass.color_for).

var points: PackedVector2Array = PackedVector2Array()
var kinds: Array[StringName] = []
var radius_px: float = 1.5
## Number of `_draw` passes so far (tests read it).
var draw_count: int = 0
## Duration of the last `_draw` pass in microseconds (the compass bench reads it).
var last_draw_usec: int = 0


func _ready() -> void:
	mouse_filter = Control.MOUSE_FILTER_IGNORE


func _draw() -> void:
	var t0 := Time.get_ticks_usec()
	draw_count += 1
	for i in points.size():
		draw_circle(points[i], radius_px, LedgerCompass.color_for(kinds[i]))
	last_draw_usec = Time.get_ticks_usec() - t0
