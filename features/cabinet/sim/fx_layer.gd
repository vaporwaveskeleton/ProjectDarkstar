class_name FxLayer
extends ArcadeLayer
## Small, physical VFX (ART-001 §7): 1 px chalk flecks, shock rings, floating score numbers.
## Pooled and capped; purely cosmetic, never gameplay truth.

const MAX_PARTICLES := 600       ## ✱
const MAX_TEXTS := 24            ## ✱

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

var sparks: Array[Spark] = []
var rings: Array[Ring] = []
var texts: Array[FloatText] = []


func reset() -> void:
	sparks.clear()
	rings.clear()
	texts.clear()


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
	for r in rings:
		if not visible_at(r.pos, r.radius):
			continue
		var k := 1.0 - r.life / r.max_life
		draw_arc(world.to_screen(r.pos).round(), maxf(1.0, r.radius * k), 0.0, TAU, 32, r.color, 1.0)
	for t in texts:
		if not visible_at(t.pos, 20.0):
			continue
		var p := world.to_screen(t.pos).round() + Vector2(-PixelText.width(t.text) * 0.5, -12)
		PixelText.draw(self, p, t.text, Look.c(Pal.BONE_4) if t.life > 0.3 else Look.c(Pal.BONE_1))
