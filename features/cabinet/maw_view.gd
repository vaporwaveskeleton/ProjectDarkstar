class_name MawView
extends Node2D
## The hole where a star should be (NARR-001 §1.2), as the cabinet half of the reveal draws it after the
## cursed turn (TECH-001 Q-T262, PM under owner direction 2026-11-19 overnight push; Reviewer v3 gap 3).
## It is NOT a centred disc and has no teeth, no eye and no ring (NARR-001 N3/N4, ART-001 §16.6c/§16.6f):
## - the WOUND is the same torn NULL erasure the Aether half uses (EntityPresence, entity_presence.gdshader),
##   opened off-centre at the point where the Cabinet looked back (CabinetDecayTuning.focus_play: the glass
##   bulged there and the picture collapsed to its dot there), and grown by `radius`;
## - the TRUE BODY is seen only by what it removes (N3): the twenty spine stars of THE LAST NORMAL DAY settle
##   onto a column that runs out of the wound and off the frame, and as `reveal` rises each pair goes out and
##   leaves a NULL vertebra where it was: a constellation turning into an absence, head first.
## Fully generated (D-13, ART-001 §14): no image is loaded. Entity palette only: NULL (and the wound's VOID
## crazing, which is the world's, not the entity's); never GASLIGHT (palette law 1). `centre` keeps its name:
## it is the wound's origin, and the sky drains into it (Starfield.pull_target).

const WOUND_SHADER := preload("res://shaders/aether/entity_presence.gdshader")

@export var spec: CabinetScreenSpec
@export var tuning: CabinetDecayTuning
var centre := Vector2.ZERO:          ## the wound's origin: the off-centre focus, in screen px
	set(v):
		centre = v
		if _wound != null:
			_wound.centre = v
		queue_redraw()
const SEGMENTS := 20                 ## the entity's 20 modules (SYS-001 §2.1)
const RING := 74.0                   ## ✱ legacy: the old reveal ring radius; only vertebra_radius() (S2 frame maths) uses it
const WOUND_REACH := 440.0           ## ✱ largest wound radius asked for (the close covers the 256 × 304 screen from the focus)
const WOUND_SEED := 2.71             ## ✱ turns the torn outline so its ruled cut and notch point away from the column
const COLUMN_LEAN := 0.42            ## ✱ rad: the column leans down-left from the wound, across the play view, off the frame
const COLUMN_LENGTH_FRAC := 0.95     ## ✱ column length, fraction of the play view's height (its tail leaves the frame)
const COLUMN_WIDTH := 1.5            ## ✱ the column's width as a multiple of the S2 silhouette's
const SWAY_PX := 1.5                 ## ✱ the column's slow sway (px), never a pulse
const SWAY_HZ := 0.09                ## ✱

var radius := 0.0:
	set(v):
		radius = v
		if _wound != null:
			_wound.radius = v
			_wound.set_growth(clampf(v / 96.0, 0.0, 1.0))
		queue_redraw()
var reveal := 0.0:
	set(v):
		reveal = v
		queue_redraw()
var _t := 0.0
var _wound: EntityPresence
var _play := Rect2()
var stars: Starfield                 ## wired by CabinetGame: S8 hand-off, the arrived spine stars are drawn here


func _ready() -> void:
	var s := spec if spec != null else (load("res://data/cabinet/cabinet_screen.tres") as CabinetScreenSpec)
	var tun := tuning if tuning != null else (load("res://data/cabinet/cabinet_decay.tres") as CabinetDecayTuning)
	_play = s.play_rect()
	_wound = EntityPresence.new()
	_wound.name = "Wound"
	_wound.shader = WOUND_SHADER
	_wound.max_radius = WOUND_REACH
	_wound.seed = WOUND_SEED
	add_child(_wound)
	centre = focus_point(s, tun)
	radius = radius


## The off-centre focus in screen px: the same point the CRT bulges at and collapses to (CabinetDecay).
static func focus_point(s: CabinetScreenSpec, tun: CabinetDecayTuning) -> Vector2:
	var play_top := s.strip_rect().end.y / float(s.grid.y)
	return tun.focus_uv(play_top) * Vector2(s.grid)


func _process(delta: float) -> void:
	_t += delta
	if visible:
		if _wound != null:
			_wound.set_time(_t)
		queue_redraw()


func _draw() -> void:
	_draw_arrived_spine_stars()
	if reveal > 0.0:
		_draw_absences(clampf(reveal, 0.0, 1.0))


## S8 hand-off: the starfield's spine stars sit on MawView's own layer once they have arrived, each pair at
## its own vertebra slot on the column, until that vertebra goes out.
func _draw_arrived_spine_stars() -> void:
	for r in spine_star_rects():
		draw_rect(r, Pal.BONE_5)


## The 2x2 dots MawView draws for arrived spine stars: a pair per vertebra not yet gone out, side by side
## at that vertebra's own slot. Empty until the stars have arrived.
func spine_star_rects() -> Array[Rect2]:
	var out: Array[Rect2] = []
	if stars == null or not stars.spine_star_arrived():
		return out
	for i in range(spine_stars_hidden_from(), SEGMENTS):
		for side in 2:
			out.append(Rect2(vertebra_star_pos(i, side).round(), Vector2(2, 2)))
	return out


## Vertebrae below this index have gone out (their star has become an absence).
func spine_stars_hidden_from() -> int:
	return ceili(clampf(reveal, 0.0, 1.0) * SEGMENTS)


## The true body, seen only by what it removes: one NULL lobe per gone-out vertebra, head first.
func _draw_absences(k: float) -> void:
	var shown := ceili(k * SEGMENTS)
	if shown <= 0:
		return
	var sides := _spine_sides(column_points(), COLUMN_WIDTH)
	var a: PackedVector2Array = sides[0]
	var b: PackedVector2Array = sides[1]
	var per := SPINE_LOBE_Q.size() + 1
	for i in mini(shown, SEGMENTS):
		var lobe := PackedVector2Array()
		for j in range(i * per, mini((i + 1) * per + 1, a.size())):
			lobe.append(a[j].round())
		for j in range(mini((i + 1) * per, b.size() - 1), i * per - 1, -1):
			lobe.append(b[j].round())
		if lobe.size() >= 3:
			draw_colored_polygon(lobe, Pal.NULL)


## The column's twenty points on screen right now: the shared S curve, head at the wound, leaning down-left,
## swaying slowly. Pure function of `centre`, the play view and MawView's clock.
func column_points() -> PackedVector2Array:
	var length := maxf(_play.size.y, 1.0) * COLUMN_LENGTH_FRAC
	var dir := Vector2.DOWN.rotated(COLUMN_LEAN)
	var sway := dir.orthogonal() * sin(TAU * SWAY_HZ * _t) * SWAY_PX
	return spine_place(spine_points(), centre + sway, dir, length)


## The column's unit normal at vertebra `i` (the S8 star pairs straddle the curve along it).
func column_normal(i: int) -> Vector2:
	var c := column_points()
	var f := _spine_frame(c)
	var nor: PackedVector2Array = f.nor_c
	return nor[clampi(i, 0, nor.size() - 1)]


# --- the vertebra placement, shared by the reveal, the S2 impact frame and the S8 star spine ---

static func _breathe(t: float) -> float:
	return 1.0 + 0.03 * sin(t * 1.3)


static func _spin(t: float) -> float:
	return t * 0.08


## Legacy ring maths (the S2 impact frame's tests pin it); the reveal no longer draws a ring.
static func vertebra_angle(i: int, t: float) -> float:
	return _spin(t) + TAU * i / SEGMENTS


static func vertebra_radius(i: int, t: float) -> float:
	return RING * _breathe(t) + sin(t * 1.7 + i * 0.9) * 2.0


## Where vertebra `i` is on screen right now: point i of the column, so the star spine (S8) meets it exactly.
func vertebra_screen_pos(i: int) -> Vector2:
	return column_points()[clampi(i, 0, SEGMENTS - 1)]


# --- the entity's spine: ONE curve shared by the S2 impact frame, the S8 star constellation and the reveal ---

## Where star `side` (0 or 1) of pair `i` rests at vertebra i's slot: side by side across the column.
func vertebra_star_pos(i: int, side: int) -> Vector2:
	var n := column_normal(i)
	return vertebra_screen_pos(i) + n * (SPINE_PAIR_GAP if side == 0 else -SPINE_PAIR_GAP)


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


## Both edges of the beaded column along `c` (widths × `width_scale`): [side_a, side_b], each with
## (SPINE_LOBE_Q.size() + 1) points per vertebra, in order, then the last gap's point.
static func _spine_sides(c: PackedVector2Array, width_scale: float = 1.0) -> Array[PackedVector2Array]:
	var n := c.size()
	var f := _spine_frame(c)
	var b: PackedVector2Array = f.b
	var nor_b: PackedVector2Array = f.nor_b
	var nor_c: PackedVector2Array = f.nor_c
	var side_a := PackedVector2Array()
	var side_b := PackedVector2Array()
	for i in n:
		var w_peak := spine_half_width(i, n) * width_scale
		var w0 := spine_pinch_width(i, n) * width_scale
		var w1 := spine_pinch_width(i + 1, n) * width_scale
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
	var w_end := spine_pinch_width(n, n) * width_scale
	side_a.append(b[n] + nor_b[n] * w_end)
	side_b.append(b[n] - nor_b[n] * w_end)
	var out: Array[PackedVector2Array] = [side_a, side_b]
	return out


## S2: the entity's true body as one closed, simple polygon (no interior detail: GDD §20 silhouette only,
## NARR-001 §3.4 no face): a beaded column along the shared curve. Each vertebra is one wide lobe on BOTH
## edges, at the same points along the curve (edges in phase), pinched at every gap between vertebrae;
## the body narrows toward the tail. Head at `origin`, column along `dir` (unit), `length` px.
static func spine_silhouette(origin: Vector2, dir: Vector2, length: float, width_scale: float = 1.0) -> PackedVector2Array:
	var c := spine_place(spine_points(), origin, dir, length)
	var b: PackedVector2Array = _spine_frame(c).b
	var n := c.size()
	var sides := _spine_sides(c, width_scale)
	var side_a: PackedVector2Array = sides[0]
	var side_b: PackedVector2Array = sides[1]
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


## The reveal's column as one closed outline at rest (no sway): head at `origin`, for a play view `play_h`
## px tall. The W0-12 after-image burns exactly this shape into the tube before it is ever drawn (Q-T259).
static func column_outline(origin: Vector2, play_h: float) -> PackedVector2Array:
	return spine_silhouette(origin, Vector2.DOWN.rotated(COLUMN_LEAN), play_h * COLUMN_LENGTH_FRAC, COLUMN_WIDTH)
