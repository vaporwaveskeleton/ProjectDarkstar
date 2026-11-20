class_name SeamThroat
extends Node2D
## The cleared Seam's exit throat (Q-T278; research slice beat 16 "the exit throat opens"): a ring of
## phosphor light that opens in the fog where the kit's throat is. Diegetic: no text, no arrow; the
## Ledger Compass shows it as a plain marker. Draw only: SeamExit owns the rule and the pass check.
## Lives under the sector's %Actors so SectorWrap keeps it on the image nearest the Vigil.

## 0 = shut (not drawn), 1 = fully open.
var open_frac := 0.0:
	set(v):
		open_frac = clampf(v, 0.0, 1.0)
		visible = open_frac > 0.0
		queue_redraw()
## The pass radius (px), from SeamExitStats.
var radius_px := 40.0
## Reduced motion: no breathing ring.
var still := false
var _t := 0.0


func _ready() -> void:
	visible = open_frac > 0.0


func _process(delta: float) -> void:
	if not visible or still:
		return
	_t += delta
	queue_redraw()


func _draw() -> void:
	if open_frac <= 0.0:
		return
	var r := radius_px * open_frac
	var breath := 0.0 if still else sin(_t * TAU * 0.4) * 0.06
	# the opening: aether light inside, a phosphor lip (phosphor = the honest thing, ART-001 §16)
	draw_circle(Vector2.ZERO, r * 1.35, Color(Pal.AETHER_2, 0.18 * open_frac))
	draw_circle(Vector2.ZERO, r, Color(Pal.AETHER_4, 0.30 * open_frac))
	draw_arc(Vector2.ZERO, r * (1.0 + breath), 0.0, TAU, 48, Color(Pal.PHOS_4, 0.9 * open_frac), 2.0)
	draw_arc(Vector2.ZERO, r * (0.72 - breath), 0.0, TAU, 40, Color(Pal.PHOS_3, 0.55 * open_frac), 1.0)
