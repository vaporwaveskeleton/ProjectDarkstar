class_name LedgerCompassMarkers
extends Control
## The Ledger Compass's marker layer (TECH-001 §5.4): one small `_draw` per frame, a dot per marker.
## It draws what it is given (widget-local points from the presented HudModel) and never applies a
## lie itself. Pal colours only (LedgerCompass.color_for).

var points: PackedVector2Array = PackedVector2Array()
var kinds: Array[StringName] = []
var radius_px: float = 1.5
## W1-09 Smudged Blip (WARP-001 §4.2 Smear family): the slot drawn smeared (-1 none) and the point the
## streak runs to. Drawn as smeared so the player can tell; still the presented model, never a lie.
var smear_slot: int = -1
var smear_tail: Vector2 = Vector2.ZERO
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
		var c := LedgerCompass.color_for(kinds[i])
		if i == smear_slot:
			_draw_smear(points[i], smear_tail, c)
			continue
		draw_circle(points[i], radius_px, c)
	last_draw_usec = Time.get_ticks_usec() - t0


## A chalk smear: a fading run of dots from the lagged blip to where the target is now.
func _draw_smear(from: Vector2, to: Vector2, c: Color) -> void:
	var steps := 6
	for k in steps + 1:
		var f := float(k) / float(steps)
		var col := Color(c, lerpf(0.9, 0.2, f))
		draw_circle(from.lerp(to, f), radius_px * lerpf(1.25, 0.6, f), col)
	draw_line(from, to, Color(Pal.BONE_3, 0.35), 1.0)
