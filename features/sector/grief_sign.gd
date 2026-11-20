class_name GriefSign
extends Node2D
## A biome's grief story as art (ZONES-001 §2.4; PM-02 carries the Pale Marches sign, Q-T429): an Office
## recruitment placard, frosted over and still lit, hung in the far fog. Art only: no collision, no
## hitbox, no light into the play layer, no lint effect. It lives on the sector's Depth canvas layer
## (behind play, never dimmed by the dark kit) and drifts at a slow parallax so it reads far. Its words
## are player text (`tr()` key, L10N-001). Drawn in Pal colours at runtime (D-13). No signals, no RNG.

## The sign's words (L10N-001).
const KEY := &"NARR_PM_SIGN_KEEP_THE_VIGIL"
const FACE := preload("res://data/hud/brass_face.tres")
## ✱ Parallax against the camera: < 1 reads farther than the play layer.
const PARALLAX := 0.45
## ✱ Placard size (logical px) and the frost rim.
const SIZE := Vector2(132, 30)
const FROST_PX := 3.0
## ✱ Lit, but dim: law 4 (nothing in the background outshines the lantern).
const ALPHA := 0.42
## ✱ Drawn small: it hangs far off in the fog, not on the glass of the HUD.
const FAR_SCALE := 0.62
## ✱ The slow breath of its lamp (Hz, far under the flicker cap); held still under Reduced Motion.
const BREATH_HZ := 0.12

var torus: Torus
## The sign's place in the field (torus px).
var anchor := Vector2.ZERO
var reduced_motion := false
var time_s := 0.0
var label: VectorLabel


func _ready() -> void:
	label = VectorLabel.new()
	label.name = "Words"
	label.face = FACE
	label.color = Color(Pal.GAS_3, 0.85)
	label.key = KEY
	label.alignment = VectorText.Align.CENTER
	label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	label.position = -SIZE * 0.5 + Vector2(0, 6)
	label.size = Vector2(SIZE.x, SIZE.y - 8)
	add_child(label)
	modulate.a = ALPHA
	scale = Vector2.ONE * FAR_SCALE


## Places the sign for a camera centre (world px) and a viewport size (logical px).
func follow(camera_centre: Vector2, view: Vector2) -> void:
	if torus == null:
		return
	position = view * 0.5 + torus.delta(camera_centre, anchor) * PARALLAX


func _process(delta: float) -> void:
	if not reduced_motion:
		time_s += delta
	queue_redraw()


func _draw() -> void:
	var r := Rect2(-SIZE * 0.5, SIZE)
	var lamp := 0.85 + 0.15 * sin(TAU * BREATH_HZ * time_s)
	# the lamp's spill behind the board: warm, soft, small (Office gaslight; the Choir never wears GAS)
	for i in 4:
		var g := r.grow(10.0 - 2.0 * i)
		draw_rect(g, Color(Pal.GAS_3, 0.035 * lamp))
	# the board and its frame
	draw_rect(r, Color(Pal.BONE_0, 0.85))
	draw_rect(r, Color(Pal.BONE_3, 0.9), false, 1.0)
	# frost creeping in from the edges (BONE-4/5), heaviest at the bottom corners
	draw_rect(Rect2(r.position, Vector2(r.size.x, FROST_PX)), Color(Pal.BONE_4, 0.55))
	draw_rect(Rect2(r.position + Vector2(0, r.size.y - FROST_PX * 2.0), Vector2(r.size.x, FROST_PX * 2.0)), Color(Pal.BONE_4, 0.6))
	for k in 5:
		var x := r.position.x + 6.0 + k * (r.size.x - 12.0) / 4.0
		draw_line(Vector2(x, r.end.y), Vector2(x + 3.0, r.end.y - 6.0 - 2.0 * (k % 2)), Color(Pal.BONE_5, 0.5), 1.0)
	# the small lamp over the words, still lit
	draw_circle(Vector2(0, r.position.y - 4.0), 2.5, Color(Pal.GAS_4, lamp))
	draw_circle(Vector2(0, r.position.y - 4.0), 5.0, Color(Pal.GAS_3, 0.25 * lamp))
