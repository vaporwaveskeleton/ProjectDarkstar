class_name MawView
extends Node2D
## The hole where a star should be (NARR-001 §1.2): a NULL disc that opens at the centre of the
## screen during THE PRETENCE. As `reveal` rises the true body assembles inside it, vertebra by
## vertebra. It is the same 20-segment ring the cabinet drew as outlines, now drawn as it really is:
## filled, shaded down the bone ramp, breathing, veined with phosphor, and watching.
## Fully generated (GDD-001 D-13, ART-001 §14): no image is loaded. Entity palette only —
## VOID, BONE, PHOS, NULL; never GASLIGHT (palette law 1).

const CENTRE := Vector2(320, 180)
const SEGMENTS := 20                 ## the entity's 20 modules (SYS-001 §2.1)
const RING := 74.0                   ## ✱ vertebra ring radius in the reveal
const TEETH := 14                    ## ✱ inner ring

var radius := 0.0:
	set(v):
		radius = v
		queue_redraw()
var reveal := 0.0:
	set(v):
		reveal = v
		queue_redraw()
var _t := 0.0


func _process(delta: float) -> void:
	_t += delta
	if visible:
		queue_redraw()


func _draw() -> void:
	if radius <= 0.0:
		return
	draw_circle(CENTRE, radius, Pal.NULL)
	# veins of phosphor reaching out of the hole: the truth-telling colour (palette law 2)
	for k in 9:
		var a := TAU * k / 9.0 + _t * 0.05
		var p0 := CENTRE + Vector2.from_angle(a) * radius
		var p1 := CENTRE + Vector2.from_angle(a + 0.12) * (radius + 10.0 + 6.0 * sin(_t * 2.0 + k))
		draw_line(p0.round(), p1.round(), Pal.PHOS_2, 1.0)
	draw_arc(CENTRE, radius, 0.0, TAU, 64, Pal.VOID_5, 1.0)
	if reveal > 0.0 and radius > 40.0:
		_draw_true_body(clampf(reveal, 0.0, 1.0))


## The entity as it is: generated from the same parameters as the costume, with the horror dial up.
func _draw_true_body(k: float) -> void:
	var breathe := 1.0 + 0.03 * sin(_t * 1.3)
	var spin := _t * 0.08
	# inner veins: from the core out between the vertebrae
	for i in SEGMENTS:
		var a := spin + TAU * (i + 0.5) / SEGMENTS
		var wob := sin(_t * 2.0 + i * 1.7) * 0.06
		var pts := PackedVector2Array()
		for s in 6:
			var r := lerpf(26.0, RING * breathe, s / 5.0)
			pts.append((CENTRE + Vector2.from_angle(a + wob * s) * r).round())
		draw_polyline(pts, Pal.PHOS_1 if i % 2 == 0 else Pal.PHOS_2, 1.0)
	# the teeth: a ring of bone pointing inward
	for i in TEETH:
		var a := -spin * 1.5 + TAU * i / TEETH
		var base_l := CENTRE + Vector2.from_angle(a - 0.12) * 44.0 * breathe
		var base_r := CENTRE + Vector2.from_angle(a + 0.12) * 44.0 * breathe
		var tip := CENTRE + Vector2.from_angle(a) * (31.0 + 2.0 * sin(_t * 3.0 + i))
		var tooth := PackedVector2Array([base_l.round(), tip.round(), base_r.round()])
		draw_colored_polygon(tooth, Pal.BONE_2)
		draw_line(base_l.round(), tip.round(), Pal.BONE_4)
	# the vertebrae: they assemble one by one as `reveal` rises, like deposits, then never stop moving
	var shown := int(ceil(k * SEGMENTS))
	for i in shown:
		var a := spin + TAU * i / SEGMENTS
		var r := RING * breathe + sin(_t * 1.7 + i * 0.9) * 2.0
		_draw_vertebra(CENTRE + Vector2.from_angle(a) * r, a, i)
	# the core and the eye
	draw_circle(CENTRE, 26.0, Pal.NULL)
	var look := Vector2.from_angle(_t * 0.7) * 6.0 + Vector2(sin(_t * 2.3), cos(_t * 1.9)) * 2.0
	var eye := (CENTRE + look).round()
	draw_circle(eye, 9.0, Pal.PHOS_1)
	draw_circle(eye, 6.0, Pal.PHOS_3)
	draw_circle(eye, 3.0, Pal.PHOS_5)
	var slit := Vector2(0, 5)
	draw_line((eye - slit).round(), (eye + slit).round(), Pal.NULL, 2.0)


## One vertebra: a shaded bone block (dark side, mid, lit edge) with a spinous process outward.
func _draw_vertebra(c: Vector2, a: float, i: int) -> void:
	var out := Vector2.from_angle(a)
	var side := out.orthogonal()
	var w := 9.0 + float(i % 3)
	var h := 7.0
	var body := PackedVector2Array([
		(c + side * w + out * h * 0.6).round(), (c - side * w + out * h * 0.6).round(),
		(c - side * (w - 2.0) - out * h).round(), (c + side * (w - 2.0) - out * h).round()])
	draw_colored_polygon(body, Pal.BONE_1)
	var lit := PackedVector2Array([body[0], body[1], ((body[1] + body[2]) * 0.5).round(), ((body[0] + body[3]) * 0.5).round()])
	draw_colored_polygon(lit, Pal.BONE_3)
	draw_line(body[0], body[1], Pal.BONE_5)
	var spine := PackedVector2Array([(c + side * 3.0 + out * h * 0.6).round(), (c + out * (h + 9.0)).round(),
		(c - side * 3.0 + out * h * 0.6).round()])
	draw_colored_polygon(spine, Pal.BONE_2)
	draw_line(spine[0], spine[1], Pal.BONE_4)
	draw_polyline(PackedVector2Array([body[0], body[1], body[2], body[3], body[0]]), Pal.BONE_0, 1.0)
