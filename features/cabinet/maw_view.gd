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
var stars: Starfield                 ## wired by CabinetGame: S8 hand-off, the arrived spine stars are drawn here


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
	_draw_arrived_spine_stars()
	if reveal > 0.0 and radius > 40.0:
		_draw_true_body(clampf(reveal, 0.0, 1.0))


## S8 hand-off: the starfield's spine stars sit on MawView's own layer once they have arrived (so the
## maw's disc cannot occlude them), each at its own vertebra slot, until that vertebra is revealed.
func _draw_arrived_spine_stars() -> void:
	for r in spine_star_rects():
		draw_rect(r, Pal.BONE_5)


## The 2x2 dots MawView draws for arrived spine stars: a pair per vertebra not yet revealed, side by side
## at that vertebra's own slot. Empty until the stars have arrived.
func spine_star_rects() -> Array[Rect2]:
	var out: Array[Rect2] = []
	if stars == null or not stars.spine_star_arrived():
		return out
	for i in range(spine_stars_hidden_from(), SEGMENTS):
		for side in 2:
			out.append(Rect2(vertebra_star_pos(i, side).round(), Vector2(2, 2)))
	return out


## Vertebrae below this index are drawn (their star has become them).
func spine_stars_hidden_from() -> int:
	return ceili(clampf(reveal, 0.0, 1.0) * SEGMENTS)


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


# --- the entity's spine: ONE curve shared by the S2 impact frame and the S8 star constellation ---

## Where star `side` (0 or 1) of pair `i` rests at vertebra i's slot: side by side across the ring tangent.
func vertebra_star_pos(i: int, side: int) -> Vector2:
	var tangent := Vector2.from_angle(vertebra_angle(i, _t) + PI * 0.5)
	return vertebra_screen_pos(i) + tangent * (SPINE_PAIR_GAP if side == 0 else -SPINE_PAIR_GAP)


const SPINE_SWAY := 0.075         ## ✱ S-curve amplitude, fraction of the column length
const SPINE_TAPER := 0.7          ## ✱ vertebra spacing falls toward the tail (head step : tail step is e^0.7, about 2 : 1)
const SPINE_HEAD_HALF := 11.0     ## px ✱ silhouette half-width at the head (S2)
const SPINE_TAIL_RATIO := 0.5     ## ✱ half-width at the tail as a fraction of the head's
const SPINE_PINCH := 0.45         ## ✱ width at each gap between two vertebrae, fraction of the local peak width
const SPINE_BULGE := 0.6          ## ✱ lobe roundness: width follows sin(pi q) to this power (smaller = squarer lobe)
const SPINE_CAP := 0.15           ## ✱ head and tail caps reach this fraction of a step past the end gaps
const SPINE_LOBE_Q := [0.15, 0.35, 0.5, 0.65, 0.85]   ## ✱ points along a lobe (0 = gap behind it, 1 = gap ahead)
const SPINE_PAIR_GAP := 2.0       ## px ✱ S8: the two stars of a pair sit this far either side of the vertebra slot on arrival


## The vertebral column in unit space: `n` points along a gentle asymmetric S, head at (0, 0), running
## toward +x to about (1, y). Spacing tapers toward the tail so it reads as a spine, not an even arc.
## Pure formula, no rng.
static func spine_points(n: int = SEGMENTS) -> PackedVector2Array:
	var pts := PackedVector2Array()
	var k := SPINE_TAPER
	var span := 1.0 - exp(-k)
	for i in n:
		var t := float(i) / float(maxi(1, n - 1))
		var u := (1.0 - exp(-k * t)) / span
		pts.append(Vector2(u, SPINE_SWAY * (0.55 + 0.9 * u) * sin(TAU * (u + 0.08 * u * u))))
	return pts


## The unit spine placed on screen: head at `origin`, the column running along `dir`, `length` px long.
static func spine_place(unit: PackedVector2Array, origin: Vector2, dir: Vector2, length: float) -> PackedVector2Array:
	var out := PackedVector2Array()
	var a := dir.angle()
	for p in unit:
		out.append(origin + (p * length).rotated(a))
	return out


## Half-width of the silhouette at vertebra `i` of `n`.
static func spine_half_width(i: int, n: int = SEGMENTS) -> float:
	return SPINE_HEAD_HALF * lerpf(1.0, SPINE_TAIL_RATIO, float(i) / float(maxi(1, n - 1)))


## The frame of the column at each vertebra: the gap positions b[0..n] (midpoints between vertebrae,
## extrapolated half a step at the ends) and the unit normals at the vertebrae and at the gaps.
static func _spine_frame(c: PackedVector2Array) -> Dictionary:
	var n := c.size()
	var b := PackedVector2Array()
	b.append(c[0] - (c[1] - c[0]) * 0.5)
	for i in range(1, n):
		b.append((c[i - 1] + c[i]) * 0.5)
	b.append(c[n - 1] + (c[n - 1] - c[n - 2]) * 0.5)
	var tan_c := PackedVector2Array()
	for i in n:
		tan_c.append((b[i + 1] - b[i]).normalized())
	var nor_c := PackedVector2Array()
	for i in n:
		nor_c.append(tan_c[i].orthogonal())
	var nor_b := PackedVector2Array()
	for j in n + 1:
		var t0 := tan_c[maxi(j - 1, 0)]
		var t1 := tan_c[mini(j, n - 1)]
		nor_b.append((t0 + t1).normalized().orthogonal())
	return {"b": b, "tan_c": tan_c, "nor_c": nor_c, "nor_b": nor_b}


## Peak half-width at gap j of n (between vertebra j-1 and j): the pinch.
static func spine_pinch_width(j: int, n: int = SEGMENTS) -> float:
	var lo := spine_half_width(clampi(j - 1, 0, n - 1), n)
	var hi := spine_half_width(clampi(j, 0, n - 1), n)
	return SPINE_PINCH * minf(lo, hi)


## S2: the entity's true body as one closed, simple polygon (no interior detail: GDD §20 silhouette only,
## NARR-001 §3.4 no face): a beaded column along the shared curve. Each vertebra is one wide lobe on BOTH
## edges, at the same points along the curve (edges in phase), pinched at every gap between vertebrae;
## the body narrows toward the tail. Head at `origin`, column along `dir` (unit), `length` px.
static func spine_silhouette(origin: Vector2, dir: Vector2, length: float) -> PackedVector2Array:
	var c := spine_place(spine_points(), origin, dir, length)
	var n := c.size()
	var f := _spine_frame(c)
	var b: PackedVector2Array = f.b
	var nor_b: PackedVector2Array = f.nor_b
	var nor_c: PackedVector2Array = f.nor_c
	var side_a := PackedVector2Array()
	var side_b := PackedVector2Array()
	for i in n:
		var w_peak := spine_half_width(i, n)
		var w0 := spine_pinch_width(i, n)
		var w1 := spine_pinch_width(i + 1, n)
		var q_all: Array = [0.0]
		q_all.append_array(SPINE_LOBE_Q)
		for q: float in q_all:
			var pos: Vector2
			var nor: Vector2
			if q < 0.5:
				pos = b[i].lerp(c[i], q * 2.0)
				nor = nor_b[i].lerp(nor_c[i], q * 2.0).normalized()
			else:
				pos = c[i].lerp(b[i + 1], (q - 0.5) * 2.0)
				nor = nor_c[i].lerp(nor_b[i + 1], (q - 0.5) * 2.0).normalized()
			var base := lerpf(w0, w1, q)
			var w := base + (w_peak - base) * pow(sin(PI * q), SPINE_BULGE)
			side_a.append(pos + nor * w)
			side_b.append(pos - nor * w)
	var w_end := spine_pinch_width(n, n)
	side_a.append(b[n] + nor_b[n] * w_end)
	side_b.append(b[n] - nor_b[n] * w_end)
	var out := PackedVector2Array()
	out.append_array(side_a)
	out.append(b[n] + (b[n] - b[n - 1]) * SPINE_CAP)
	side_b.reverse()
	out.append_array(side_b)
	out.append(b[0] - (b[1] - b[0]) * SPINE_CAP)
	return out


## S8: the silhouette's outline as stars: two per vertebra, side by side across the curve at that
## vertebra's half-width (the S2 width function) times `width_scale`. Index 2*i is one side, 2*i+1 the other.
static func spine_ladder(origin: Vector2, dir: Vector2, length: float, width_scale: float) -> PackedVector2Array:
	var c := spine_place(spine_points(), origin, dir, length)
	var f := _spine_frame(c)
	var nor_c: PackedVector2Array = f.nor_c
	var out := PackedVector2Array()
	for i in c.size():
		var w := spine_half_width(i, c.size()) * width_scale
		out.append(c[i] + nor_c[i] * w)
		out.append(c[i] - nor_c[i] * w)
	return out
