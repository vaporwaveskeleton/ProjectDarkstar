class_name MawView
extends Node2D
## The hole where a star should be (NARR-001 §1.2): a NULL disc that opens at the centre of the
## screen during THE PRETENCE. As `reveal` rises the true body assembles inside it, vertebra by
## vertebra. It is the same 20-segment ring the cabinet drew as outlines, now drawn as it really is:
## filled, shaded down the bone ramp, breathing, veined with phosphor, and watching.
## Fully generated (GDD-001 D-13, ART-001 §14): no image is loaded. Entity palette only —
## VOID, BONE, PHOS, NULL; never GASLIGHT (palette law 1).

@export var spec: CabinetScreenSpec
var centre := Vector2.ZERO          ## the centre of the play view (from the screen spec)
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


func _ready() -> void:
	var s := spec if spec != null else (load("res://data/cabinet/cabinet_screen.tres") as CabinetScreenSpec)
	centre = s.play_centre()


func _process(delta: float) -> void:
	_t += delta
	if visible:
		queue_redraw()


func _draw() -> void:
	if radius <= 0.0:
		return
	draw_circle(centre, radius, Pal.NULL)
	# veins of phosphor reaching out of the hole: the truth-telling colour (palette law 2)
	for k in 9:
		var a := TAU * k / 9.0 + _t * 0.05
		var p0 := centre + Vector2.from_angle(a) * radius
		var p1 := centre + Vector2.from_angle(a + 0.12) * (radius + 10.0 + 6.0 * sin(_t * 2.0 + k))
		draw_line(p0.round(), p1.round(), Pal.PHOS_2, 1.0)
	draw_arc(centre, radius, 0.0, TAU, 64, Pal.VOID_5, 1.0)
	if reveal > 0.0 and radius > 40.0:
		_draw_true_body(clampf(reveal, 0.0, 1.0))


## The entity as it is: generated from the same parameters as the costume, with the horror dial up.
func _draw_true_body(k: float) -> void:
	var breathe := _breathe(_t)
	var spin := _spin(_t)
	# inner veins: from the core out between the vertebrae
	for i in SEGMENTS:
		var a := spin + TAU * (i + 0.5) / SEGMENTS
		var wob := sin(_t * 2.0 + i * 1.7) * 0.06
		var pts := PackedVector2Array()
		for s in 6:
			var r := lerpf(26.0, RING * breathe, s / 5.0)
			pts.append((centre + Vector2.from_angle(a + wob * s) * r).round())
		draw_polyline(pts, Pal.PHOS_1 if i % 2 == 0 else Pal.PHOS_2, 1.0)
	# the teeth: a ring of bone pointing inward
	for i in TEETH:
		var a := -spin * 1.5 + TAU * i / TEETH
		var base_l := centre + Vector2.from_angle(a - 0.12) * 44.0 * breathe
		var base_r := centre + Vector2.from_angle(a + 0.12) * 44.0 * breathe
		var tip := centre + Vector2.from_angle(a) * (31.0 + 2.0 * sin(_t * 3.0 + i))
		var tooth := PackedVector2Array([base_l.round(), tip.round(), base_r.round()])
		draw_colored_polygon(tooth, Pal.BONE_2)
		draw_line(base_l.round(), tip.round(), Pal.BONE_4)
	# the vertebrae: they assemble one by one as `reveal` rises, like deposits, then never stop moving
	var shown := int(ceil(k * SEGMENTS))
	for i in shown:
		var a := vertebra_angle(i, _t)
		var r := vertebra_radius(i, _t)
		_draw_vertebra(centre + Vector2.from_angle(a) * r, a, i)
	# the core and the eye
	draw_circle(centre, 26.0, Pal.NULL)
	var look := Vector2.from_angle(_t * 0.7) * 6.0 + Vector2(sin(_t * 2.3), cos(_t * 1.9)) * 2.0
	var eye := (centre + look).round()
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


# --- the true body's vertebra placement, shared by the reveal, the S2 impact frame and the S8 star spine ---

static func _breathe(t: float) -> float:
	return 1.0 + 0.03 * sin(t * 1.3)


static func _spin(t: float) -> float:
	return t * 0.08


## Angle of vertebra `i` of the true ring at time `t`.
static func vertebra_angle(i: int, t: float) -> float:
	return _spin(t) + TAU * i / SEGMENTS


## Distance of vertebra `i` from the centre at time `t`.
static func vertebra_radius(i: int, t: float) -> float:
	return RING * _breathe(t) + sin(t * 1.7 + i * 0.9) * 2.0


## Where vertebra `i` is on screen right now (MawView's own clock and centre), so the star spine (S8)
## can meet it exactly.
func vertebra_screen_pos(i: int) -> Vector2:
	return centre + Vector2.from_angle(vertebra_angle(i, _t)) * vertebra_radius(i, _t)


const SIL_TIP := 16.0        ## ✱ spinous process reach beyond the vertebra centre (h + 9, as _draw_vertebra)
const SIL_SHOULDER := 4.2    ## ✱ body outer face beyond the centre (h * 0.6)
const SIL_NOTCH := 7.0       ## ✱ body inner face behind the centre (h): the notch between two vertebrae sits here
const SIL_HALF_STEP := 0.3   ## fraction of the angular step each vertebra's shoulders span


## The farthest reach of the true ring at time `t` (before scaling): the ritual scales by
## BODY_DRAWN_RADIUS / this, so the silhouette always touches the costume's drawn radius.
static func true_peak_radius(t: float) -> float:
	var m := 0.0
	for i in SEGMENTS:
		m = maxf(m, vertebra_radius(i, t) + SIL_TIP)
	return m


## S2: the outer envelope of the true body's vertebra ring as one closed, simple polygon (no interior
## detail: GDD §20 silhouette only, NARR-001 §3.4 no face). Per vertebra: shoulder, spinous tip,
## shoulder; then one notch between it and the next (SEGMENTS notches). `scale` applies about `centre`.
static func true_silhouette(centre: Vector2, t: float, scale: float) -> PackedVector2Array:
	var out := PackedVector2Array()
	var step := TAU / SEGMENTS
	for i in SEGMENTS:
		var a := vertebra_angle(i, t)
		var r := vertebra_radius(i, t)
		var r_next := vertebra_radius((i + 1) % SEGMENTS, t)
		out.append(centre + Vector2.from_angle(a - step * SIL_HALF_STEP) * (r + SIL_SHOULDER) * scale)
		out.append(centre + Vector2.from_angle(a) * (r + SIL_TIP) * scale)
		out.append(centre + Vector2.from_angle(a + step * SIL_HALF_STEP) * (r + SIL_SHOULDER) * scale)
		out.append(centre + Vector2.from_angle(a + step * 0.5) * ((r + r_next) * 0.5 - SIL_NOTCH) * scale)
	return out
