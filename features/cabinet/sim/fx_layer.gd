class_name FxLayer
extends ArcadeLayer
## Small, physical VFX (ART-001 §7): 1 px chalk flecks, shock rings, floating score numbers.
## Pooled and capped; purely cosmetic, never gameplay truth.

const MAX_PARTICLES := 600       ## ✱
const MAX_TEXTS := 24            ## ✱
const MIN_RING_GAP_PX := 2.0     ## ✱ the S6 chalk ring clears the killer silhouette by at least this

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


## S6: a chalk ring round what killed the Vigil and an arc on the Vigil showing the hit direction.
## Anchored to the world positions at death; held until clear_death_marks() (no rng).
func death_mark(killer_pos: Vector2, killer_radius: float, from_dir: Vector2, vigil_pos: Vector2) -> void:
	var m := DeathMark.new()
	m.killer_pos = killer_pos
	m.killer_radius = killer_radius
	m.from_dir = from_dir.normalized() if from_dir.length() > 0.0 else Vector2.UP
	m.vigil_pos = vigil_pos
	death_marks.append(m)


func clear_death_marks() -> void:
	death_marks.clear()


## 0..1 of the ring drawn; full at once under Reduced Motion.
func death_sweep(m: DeathMark) -> float:
	if SettingsService.get_value(&"reduced_motion") or world.fx_tuning.death_ring_draw_s <= 0.0:
		return 1.0
	return clampf(m.age / world.fx_tuning.death_ring_draw_s, 0.0, 1.0)


func ring(at: Vector2, color: Color, radius: float) -> void:
	var r := Ring.new()
	r.pos = at
	r.radius = radius
	r.max_life = 0.35 + radius / 400.0
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


## Chalk ring radius: the killer's drawn silhouette + pad, never closer than MIN_RING_GAP_PX to it.
func death_ring_radius(m: DeathMark) -> float:
	return m.killer_radius + maxf(MIN_RING_GAP_PX, world.fx_tuning.death_ring_pad_px)


## Two screen points of a chalk tick on the play-view edge toward an off-view killer, or empty when
## the killer is in view. Direction = torus delta from the Vigil's death position (wrap-aware).
func death_edge_tick(m: DeathMark) -> PackedVector2Array:
	if world.on_screen(m.killer_pos, 0.0):
		return PackedVector2Array()
	var d := world.torus.delta(m.vigil_pos, m.killer_pos)
	if d.length() < 0.001:
		return PackedVector2Array()
	d = d.normalized()
	var half := world.view_rect.size * 0.5 - Vector2(MIN_RING_GAP_PX + 1.0, MIN_RING_GAP_PX + 1.0)
	var t := minf(half.x / maxf(absf(d.x), 0.0001), half.y / maxf(absf(d.y), 0.0001))
	var edge := (world.screen_centre + d * t).round()
	return PackedVector2Array([edge, (edge - d * world.fx_tuning.death_edge_tick_px).round()])


## S6: chalk ring (swept over death_ring_draw_s) round the killer, chalk arc on the Vigil,
## a chalk edge tick when the killer is off-view. 1 px BONE_4, no alpha.
func _draw_death_marks() -> void:
	var col := Look.c(Pal.BONE_4)
	var ft := world.fx_tuning
	for m in death_marks:
		var rr := death_ring_radius(m)
		if visible_at(m.killer_pos, rr):
			var sweep := death_sweep(m)
			if sweep > 0.0:
				draw_arc(world.to_screen(m.killer_pos).round(), rr, -PI * 0.5, -PI * 0.5 + TAU * sweep, 48, col, 1.0)
		var tick := death_edge_tick(m)
		if tick.size() == 2:
			draw_line(tick[0], tick[1], col, 1.0)
		if visible_at(m.vigil_pos, ft.death_arc_radius_px):
			var half := deg_to_rad(ft.death_arc_deg) * 0.5
			var a := m.from_dir.angle()
			draw_arc(world.to_screen(m.vigil_pos).round(), ft.death_arc_radius_px, a - half, a + half, 12, col, 1.0)
