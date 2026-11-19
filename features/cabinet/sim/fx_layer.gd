class_name FxLayer
extends ArcadeLayer
## Small, physical VFX (ART-001 §7): 1 px chalk flecks, shock rings, floating score numbers.
## Pooled and capped; purely cosmetic, never gameplay truth.

const MAX_PARTICLES := 600       ## ✱
const MAX_TEXTS := 24            ## ✱
const MIN_RING_GAP_PX := 2.0     ## ✱ the S6 chalk ring clears the killer silhouette by at least this
const DASH_RING_ON := 3.0       ## px ✱ S6 coarse rhythm: only the big silhouette ring round a shot (when bigger than the hull)
const DASH_RING_OFF := 3.0      ## px ✱
const DASH_SMALL_ON := 2.0      ## px ✱ S6 fine rhythm: hull outline, arrow, leader (small shapes)
const DASH_SMALL_OFF := 1.0     ## px ✱
const LEADER_SAME_SIDE_COS := 0.5  ## ✱ cos 60°: live killer within 60° of the arrow -> leader continues the shaft
const SOLID_ON_PX := 1.0e9     ## dash_path "on" length that never breaks: a solid line, still drawn on by frac
const ARROW_HEAD_PX := 4.0      ## px ✱ S6 arrowhead barb length
const ARROW_TIP_INSET_PX := 4.0 ## px ✱ S6 the arrow tip sits this far inside the outline, on the killer's side

class Spark:
	var pos: Vector2
	var vel: Vector2
	var life: float
	var max_life: float
	var color: Color

class Ring:
	var pos: Vector2
	var radius: float
	var life: float
	var max_life: float
	var color: Color

class FloatText:
	var pos: Vector2
	var text: String
	var life: float

class Fleck:
	var pos: Vector2
	var vel: Vector2
	var life: float
	var max_life: float

class ChalkTick:
	var pos: Vector2
	var dir: Vector2      ## unit, perpendicular to the lance
	var life: float

class DeathMark:
	var killer_pos: Vector2
	var killer_radius: float
	var from_dir: Vector2     ## unit, from the Vigil toward the killer
	var vigil_pos: Vector2
	var age: float = 0.0      ## sim seconds since death
	var facing: float = -PI / 2.0   ## the Vigil's facing at death (for the coroner's outline)

var death_marks: Array[DeathMark] = []
var flecks: Array[Fleck] = []
var chalk_ticks: Array[ChalkTick] = []
var sparks: Array[Spark] = []
var rings: Array[Ring] = []
var texts: Array[FloatText] = []


func reset() -> void:
	sparks.clear()
	flecks.clear()
	chalk_ticks.clear()
	rings.clear()
	texts.clear()
	death_marks.clear()


func burst(at: Vector2, color: Color, count: int, speed: float) -> void:
	for i in count:
		if sparks.size() >= MAX_PARTICLES:
			sparks.remove_at(0)
		var s := Spark.new()
		s.pos = at
		s.vel = Vector2.from_angle(world.rng.randf() * TAU) * world.rng.randf_range(speed * 0.2, speed)
		s.max_life = world.rng.randf_range(0.3, 0.9)
		s.life = s.max_life
		s.color = color
		sparks.append(s)


## Two 1 px specks leaving perpendicular to the shot (fixed geometry: never touches world.rng).
func fleck(at: Vector2, dir: Vector2) -> void:
	var side := dir.normalized().orthogonal()
	for sgn in [-1.0, 1.0]:
		if flecks.size() >= MAX_PARTICLES:
			flecks.remove_at(0)
		var f := Fleck.new()
		f.pos = at
		f.vel = side * world.fx_tuning.fleck_speed_px_s * float(sgn)
		f.max_life = world.fx_tuning.fleck_life_s
		f.life = f.max_life
		flecks.append(f)


## A dim dash across the lance's line: the lance cannot hurt this (no rng, no sparks).
func chalk_tick(at: Vector2, dir: Vector2) -> void:
	if chalk_ticks.size() >= MAX_TEXTS:
		chalk_ticks.remove_at(0)
	var t := ChalkTick.new()
	t.pos = at
	t.dir = dir.normalized().orthogonal()
	t.life = world.fx_tuning.tick_life_s
	chalk_ticks.append(t)


## S6: the coroner's chalk: the Vigil's outline at the death spot, one arrow in from the killer, a ring round a small killer.
## Anchored to the world positions at death; held until clear_death_marks() (no rng).
func death_mark(killer_pos: Vector2, killer_radius: float, from_dir: Vector2, vigil_pos: Vector2, facing: float = INF) -> void:
	var m := DeathMark.new()
	m.killer_pos = killer_pos
	m.killer_radius = killer_radius
	m.from_dir = from_dir.normalized() if from_dir.length() > 0.0 else Vector2.UP
	m.vigil_pos = vigil_pos
	m.facing = world.vigil.facing if is_inf(facing) else facing
	death_marks.append(m)


func clear_death_marks() -> void:
	death_marks.clear()


## Life (s) of a shock ring of `radius` (the formula ring() uses).
static func ring_life(radius: float) -> float:
	return 0.35 + radius / 400.0


## Sim seconds after death before any chalk is drawn: the Vigil's own GAS death burst ring must
## have faded first (the field, never shorter than that ring's life). Sequencing, not motion: it
## also applies under Reduced Motion.
func death_chalk_delay() -> float:
	var ft := world.fx_tuning
	return maxf(ft.death_chalk_delay_s, ring_life(ft.vigil_death_ring_radius))


## 0..1 of the outline (and the ring round a shot) drawn: first in the ordered draw-on, after the
## delay. Under Reduced Motion it is complete at once once the delay has passed.
func death_outline_frac(m: DeathMark) -> float:
	var t := m.age - death_chalk_delay()
	if t < 0.0:
		return 0.0
	var s := world.fx_tuning.death_outline_draw_s
	if SettingsService.get_value(&"reduced_motion") or s <= 0.0:
		return 1.0
	return clampf(t / s, 0.0, 1.0)


## 0..1 of the arrow (and the leader) drawn: starts only once the outline is complete.
func death_arrow_frac(m: DeathMark) -> float:
	var t := m.age - death_chalk_delay()
	if t < 0.0:
		return 0.0
	var s := world.fx_tuning.death_arrow_draw_s
	if SettingsService.get_value(&"reduced_motion") or s <= 0.0:
		return 1.0
	return clampf((t - world.fx_tuning.death_outline_draw_s) / s, 0.0, 1.0)


func ring(at: Vector2, color: Color, radius: float) -> void:
	var r := Ring.new()
	r.pos = at
	r.radius = radius
	r.max_life = ring_life(radius)
	r.life = r.max_life
	r.color = color
	rings.append(r)


func float_text(at: Vector2, text: String) -> void:
	if texts.size() >= MAX_TEXTS:
		texts.remove_at(0)
	var t := FloatText.new()
	t.pos = at
	t.text = text
	t.life = 0.8
	texts.append(t)


func tick(delta: float) -> void:
	for s in sparks:
		s.life -= delta
		s.vel *= exp(-2.5 * delta)
		s.pos = world.torus.wrap(s.pos + s.vel * delta)
	sparks.assign(sparks.filter(func(s: Spark) -> bool: return s.life > 0.0))
	for f in flecks:
		f.life -= delta
		f.pos = world.torus.wrap(f.pos + f.vel * delta)
	flecks.assign(flecks.filter(func(f: Fleck) -> bool: return f.life > 0.0))
	for k in chalk_ticks:
		k.life -= delta
	chalk_ticks.assign(chalk_ticks.filter(func(k: ChalkTick) -> bool: return k.life > 0.0))
	for m in death_marks:
		m.age += delta
	for r in rings:
		r.life -= delta
	rings.assign(rings.filter(func(r: Ring) -> bool: return r.life > 0.0))
	for t in texts:
		t.life -= delta
		t.pos += Vector2(0, -18.0 * delta)
	texts.assign(texts.filter(func(t: FloatText) -> bool: return t.life > 0.0))


func _draw() -> void:
	if world == null:
		return
	for s in sparks:
		if not visible_at(s.pos, 4.0):
			continue
		var c := s.color if s.life > s.max_life * 0.35 else Look.c(Pal.BONE_1)
		draw_rect(Rect2(world.to_screen(s.pos).round(), Vector2.ONE), c)
	for f in flecks:
		if not visible_at(f.pos, 4.0):
			continue
		var fc := Look.c(Pal.BONE_4) if f.life > f.max_life * 0.35 else Look.c(Pal.BONE_1)
		draw_rect(Rect2(world.to_screen(f.pos).round(), Vector2.ONE), fc)
	for k in chalk_ticks:
		if not visible_at(k.pos, 8.0):
			continue
		var half := world.fx_tuning.tick_len_px * 0.5
		var kc := world.to_screen(k.pos).round()
		draw_line((kc - k.dir * half).round(), (kc + k.dir * half).round(), Look.c(Pal.BONE_2), 1.0)
	for r in rings:
		if not visible_at(r.pos, r.radius):
			continue
		var k := 1.0 - r.life / r.max_life
		draw_arc(world.to_screen(r.pos).round(), maxf(1.0, r.radius * k), 0.0, TAU, 32, r.color, 1.0)
	_draw_death_marks()
	for t in texts:
		if not visible_at(t.pos, 20.0):
			continue
		var p := world.to_screen(t.pos).round() + Vector2(-PixelText.width(t.text) * 0.5, -12)
		PixelText.draw(self, p, t.text, Look.c(Pal.BONE_4) if t.life > 0.3 else Look.c(Pal.BONE_1))


## Killers drawn larger than death_big_killer_px (the entity) are tracked live through DEAD.
func death_is_big(m: DeathMark) -> bool:
	return m.killer_radius > world.fx_tuning.death_big_killer_px


## Where the killer is NOW: a big killer (the entity) is tracked live (torus-aware via the deltas
## below); a small one (a shot) stays where it killed.
func death_killer_pos(m: DeathMark) -> Vector2:
	if death_is_big(m) and world.ritual != null:
		return world.ritual.entity_pos
	return m.killer_pos


## Chalk ring radius round a small killer: its drawn silhouette + pad, never closer than MIN_RING_GAP_PX.
func death_ring_radius(m: DeathMark) -> float:
	return m.killer_radius + maxf(MIN_RING_GAP_PX, world.fx_tuning.death_ring_pad_px)


## The ring round a shot is bigger than the hull -> the coarse 3/3 rhythm; otherwise the fine 2/1.
func ring_uses_coarse_dashes(radius: float) -> bool:
	return radius * 2.0 > VigilShip.HULL_LENGTH * world.fx_tuning.death_outline_scale


## Screen points of the Vigil's own hull (4 closed points) at the death spot and facing, scaled by death_outline_scale about the spot.
func death_outline(m: DeathMark) -> PackedVector2Array:
	var c := world.to_screen(m.vigil_pos).round()
	var pts := world.vigil.hull_points(c, m.facing)
	for i in pts.size():
		pts[i] = (c + (pts[i] - c) * world.fx_tuning.death_outline_scale).round()
	return pts


## Screen points [tail, tip, barb_a, barb_b] of the single arrow: it comes from the killer's side
## (from_dir) and points into the outline. Shaft length = death_arrow_px; the barbs are the head.
func death_arrow(m: DeathMark) -> PackedVector2Array:
	var c := world.to_screen(m.vigil_pos).round()
	var sc := world.fx_tuning.death_outline_scale
	var tip := c + m.from_dir * (ARROW_TIP_INSET_PX * sc)
	var tail := tip + m.from_dir * world.fx_tuning.death_arrow_px
	var back := m.from_dir * (ARROW_HEAD_PX * sc)
	var side := m.from_dir.orthogonal() * (ARROW_HEAD_PX * sc * 0.6)
	return PackedVector2Array([tail.round(), tip.round(), (tip + back + side).round(), (tip + back - side).round()])


## Two screen points of a chalk tick on the play-view edge toward an off-view killer, or empty when
## the killer is in view. Direction = torus delta from the Vigil's death position (wrap-aware),
## to the killer's live position for a big killer.
func death_edge_tick(m: DeathMark) -> PackedVector2Array:
	var kp := death_killer_pos(m)
	if world.on_screen(kp, 0.0):
		return PackedVector2Array()
	var d := world.torus.delta(m.vigil_pos, kp)
	if d.length() < 0.001:
		return PackedVector2Array()
	d = d.normalized()
	var half := world.view_rect.size * 0.5 - Vector2(MIN_RING_GAP_PX + 1.0, MIN_RING_GAP_PX + 1.0)
	var t := minf(half.x / maxf(absf(d.x), 0.0001), half.y / maxf(absf(d.y), 0.0001))
	var edge := (world.screen_centre + d * t).round()
	return PackedVector2Array([edge, (edge - d * world.fx_tuning.death_edge_tick_px).round()])


## Tracking leader (screen start, end): the arrow's shaft continued from its tail to the killer's
## live edge, ending at the view-edge tick when the killer is off-view. Empty when the killer is
## adjacent (the gap between outline and killer's edge is not longer than the arrow).
func death_leader(m: DeathMark) -> PackedVector2Array:
	var ft := world.fx_tuning
	var s_vigil := world.to_screen(m.vigil_pos).round()
	var to_k := world.torus.delta(m.vigil_pos, death_killer_pos(m))
	if to_k.length() < 0.001:
		return PackedVector2Array()
	var dir := to_k.normalized()
	# While the live killer is still on the arrow's side, the leader continues the arrow's shaft.
	# Once it has moved round (a rampaging entity), start from the outline's edge that faces it,
	# so the leader never runs back across the outline or the arrow (review follow-up).
	var start := s_vigil + m.from_dir * (ARROW_TIP_INSET_PX * ft.death_outline_scale + ft.death_arrow_px)
	if dir.dot(m.from_dir) < LEADER_SAME_SIDE_COS:
		var reach := 0.0
		for p in death_outline(m):
			reach = maxf(reach, (p - s_vigil).dot(dir))
		start = s_vigil + dir * (reach + maxf(MIN_RING_GAP_PX, ft.death_ring_pad_px))
	var end := s_vigil + to_k - dir * (m.killer_radius + maxf(MIN_RING_GAP_PX, ft.death_ring_pad_px))
	var tick := death_edge_tick(m)
	if tick.size() == 2:
		end = tick[1]
	if (end - start).dot(dir) <= 1.0:
		return PackedVector2Array()
	return PackedVector2Array([start.round(), end.round()])


## Dashed arc spans [start, end] in radians for a ring of `radius` (on / off measured along the
## circle, fixed pattern), clipped to `frac` (0..1) of the full turn.
func dash_spans(radius: float, frac: float, on: float = DASH_RING_ON, off: float = DASH_RING_OFF) -> Array[Vector2]:
	var out: Array[Vector2] = []
	var n := maxi(3, int(floor(TAU * radius / (on + off))))
	var step := TAU / float(n)
	var dash := minf(on / maxf(radius, 1.0), step * 0.75)
	var limit := TAU * clampf(frac, 0.0, 1.0)
	for i in n:
		var a0 := -PI * 0.5 + step * i
		if step * i >= limit:
			break
		out.append(Vector2(a0, minf(a0 + dash, -PI * 0.5 + limit)))
	return out


## Dashed pieces along a polyline (on / off px, fixed pattern, from the first point), clipped to
## `frac` of its length. Each entry is a 2-point segment (a dash may be cut at a corner into two
## pieces). Pass a closed path by repeating the first point.
func dash_path(pts: PackedVector2Array, frac: float, on: float = DASH_SMALL_ON, off: float = DASH_SMALL_OFF) -> Array[PackedVector2Array]:
	var out: Array[PackedVector2Array] = []
	var total := 0.0
	for i in range(pts.size() - 1):
		total += pts[i].distance_to(pts[i + 1])
	var limit := total * clampf(frac, 0.0, 1.0)
	var period := on + off
	var start := 0.0                      # path distance where the current dash starts
	while start < limit:
		var stop := minf(start + on, limit)
		var piece := PackedVector2Array()
		var walked := 0.0
		for i in range(pts.size() - 1):
			var a := pts[i]
			var b := pts[i + 1]
			var seg := a.distance_to(b)
			if seg > 0.0001 and stop > walked and start < walked + seg:
				var u0 := maxf(start, walked) - walked
				var u1 := minf(stop, walked + seg) - walked
				piece = PackedVector2Array([a.lerp(b, u0 / seg).round(), a.lerp(b, u1 / seg).round()])
				out.append(piece)
			walked += seg
		start += period
	return out


## S6: the coroner's outline is a SOLID closed 1 px line (solid = you; dashed = pointing: the arrow
## and leader stay dashed). Dashes break a thin hull into a "T"; a closed triangle reads as a ship
## at any facing (review round 4). Drawn on along its perimeter up to `frac`.
func death_outline_segments(m: DeathMark, frac: float) -> Array[PackedVector2Array]:
	var hull := death_outline(m)
	var closed := PackedVector2Array(hull)
	closed.append(hull[0])
	return dash_path(closed, frac, SOLID_ON_PX, 0.0)


## S6: the coroner's chalk, 1 px BONE_4, no alpha. Order: the Vigil's outline draws on, then the
## arrow (and tracking leader), then it all holds until respawn. A small killer (a shot) also
## gets a ring round its silhouette, drawn on with the outline.
## A 1 px chalk line between two integer screen points, centred on pixel centres (+0.5). A width-1
## quad through integer corners covers no pixel centre on a 45 degree run and vanishes: the solid
## outline and the barbs were invisible in real runs until they were drawn pixel-centred.
func chalk_line_ends(a: Vector2, b: Vector2) -> PackedVector2Array:
	return PackedVector2Array([a + Vector2(0.5, 0.5), b + Vector2(0.5, 0.5)])


func _chalk_line(a: Vector2, b: Vector2, col: Color) -> void:
	var e := chalk_line_ends(a, b)
	draw_line(e[0], e[1], col, 1.0)


func _draw_death_marks() -> void:
	var col := Look.c(Pal.BONE_4)
	var ft := world.fx_tuning
	for m in death_marks:
		var o := death_outline_frac(m)
		var a := death_arrow_frac(m)
		if visible_at(m.vigil_pos, ft.death_arrow_px + 12.0):
			for seg in death_outline_segments(m, o):
				_chalk_line(seg[0], seg[1], col)
			if a > 0.0:
				var arrow := death_arrow(m)
				for seg in dash_path(PackedVector2Array([arrow[0], arrow[1]]), a):
					_chalk_line(seg[0], seg[1], col)
				_chalk_line(arrow[1], arrow[2], col)
				_chalk_line(arrow[1], arrow[3], col)
		if not death_is_big(m):
			var rr := death_ring_radius(m)
			if visible_at(m.killer_pos, rr) and o > 0.0:
				var coarse := ring_uses_coarse_dashes(rr)
				var centre := world.to_screen(m.killer_pos).round()
				for span in dash_spans(rr, o, DASH_RING_ON if coarse else DASH_SMALL_ON, DASH_RING_OFF if coarse else DASH_SMALL_OFF):
					draw_arc(centre, rr, span.x, span.y, 4, col, 1.0)
		if a >= 1.0:
			var lead := death_leader(m)
			if lead.size() == 2:
				for seg in dash_path(lead, 1.0):
					_chalk_line(seg[0], seg[1], col)
			var tick := death_edge_tick(m)
			if tick.size() == 2:
				_chalk_line(tick[0], tick[1], col)
