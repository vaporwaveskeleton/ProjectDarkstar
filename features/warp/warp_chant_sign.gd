class_name WarpChantSign
extends Control
## The visual chant indicator the GDD §10 makes mandatory for every chant cue (WARP-001 W1-07, W1-08):
## W1-08 Chant Under Music = a small standing mark of three stacked arcs beside the Composure wick;
## W1-07 False Chant = ripples at the screen edge in the direction the (false) chant is heard from, so
## deaf and hard-of-hearing players get the same false cue the audio gives (it is a world cue, not a
## HUD lie). Choir hue: the chant is the Choir's (ART-001 §4 faction law). Photosensitivity: ripples
## hold still (no expanding animation), never removed.

var under_music: bool = false:
	set(v):
		under_music = v
		queue_redraw()
## Screen-space unit direction of the false chant; zero = none.
var false_dir: Vector2 = Vector2.ZERO:
	set(v):
		false_dir = v
		queue_redraw()
## 0..1 progress through the false cue (drives the ripple), and whether motion is allowed.
var phase: float = 0.0:
	set(v):
		phase = v
		if false_dir != Vector2.ZERO:
			queue_redraw()
var still: bool = false
var strength: float = 1.0


func _ready() -> void:
	mouse_filter = Control.MOUSE_FILTER_IGNORE


## Where the false-chant ripples sit: the screen-edge point along `false_dir` (inset).
func ripple_centre() -> Vector2:
	var half := size * 0.5
	if false_dir == Vector2.ZERO:
		return half
	var inset := 26.0
	var sx := (half.x - inset) / maxf(absf(false_dir.x), 1e-4)
	var sy := (half.y - inset) / maxf(absf(false_dir.y), 1e-4)
	return half + false_dir * minf(sx, sy)


func _draw() -> void:
	if under_music:
		# Three stacked chalk arcs, bottom-right beside the wick (WARP-001 §4.1 bottom-right anchor).
		var at := Vector2(size.x - 82.0, size.y - 12.0)
		for i in 3:
			draw_arc(at, 2.0 + float(i) * 2.5, -PI * 0.85, -PI * 0.15, 8,
				Color(Pal.CHOIR_4, (0.75 - float(i) * 0.2) * strength), 1.0)
	if false_dir != Vector2.ZERO:
		var c := ripple_centre()
		var ang := false_dir.angle()
		for i in 3:
			var f := float(i) / 3.0
			var grow := 0.0 if still else fposmod(phase * 3.0 + f, 1.0)
			var r := 7.0 + (f + grow) * 16.0
			var a := (0.9 - (f + grow) * 0.5) * strength
			draw_arc(c, r, ang - 0.8, ang + 0.8, 12, Color(Pal.CHOIR_5, clampf(a, 0.0, 1.0)), 1.5)
		draw_circle(c, 1.5, Color(Pal.CHOIR_5, strength))
