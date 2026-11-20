class_name DustMotes
extends Node2D
## Dust in the Ruins' air (LOOP-001 §10.5; ART-001 §16: haunted, lamp-lit, alive). Visual only, in
## RuinsLook's lit stage, so the hall's lights do the work: a mote in the dark stays near-black and a
## mote crossing a lamp's pool glints. Each mote also brightens a little by its distance to `lights`
## (the hall lantern and the pilot lamp), so the beams read even where the Light2D falloff is soft.
## Cosmetic hash only (never a gameplay RNG stream). Reduced motion: the motes hang still.

## ✱ how many motes, where they drift (logical px), how fast, how big.
const COUNT := 90
const AREA := Rect2(60, 40, 520, 260)
const DRIFT_PX_S := 3.0
const SWAY_PX := 4.0
const RADIUS_PX := 0.6
## ✱ px from a light inside which a mote glints, and the glint's strength.
const GLINT_RADIUS := 70.0
const GLINT := 0.55
## ✱ the dot texture: size (px) and the share of its radius that is solid (so the quad covers the old
## circle's radius). Runtime GradientTexture2D, no image files (D-13).
const DOT_PX := 32
const DOT_SOLID := 0.7

static var _dot_tex: GradientTexture2D


static func _ensure_dot() -> void:
	if _dot_tex != null:
		return
	var g := Gradient.new()
	g.offsets = PackedFloat32Array([0.0, 0.55, 0.85, 1.0])
	g.colors = PackedColorArray([Color(1, 1, 1, 1), Color(1, 1, 1, 1), Color(1, 1, 1, 0.35), Color(1, 1, 1, 0)])
	_dot_tex = GradientTexture2D.new()
	_dot_tex.gradient = g
	_dot_tex.fill = GradientTexture2D.FILL_RADIAL
	_dot_tex.fill_from = Vector2(0.5, 0.5)
	_dot_tex.fill_to = Vector2(1.0, 0.5)
	_dot_tex.width = DOT_PX
	_dot_tex.height = DOT_PX

## Light positions (stage-local px) the motes glint near.
var lights: PackedVector2Array = []
## The pilot lamp is down: only the hall lantern glints (the second light is ignored).
var light_down := false
## Reduced motion.
var still := false
var _t := 0.0
var _seed: PackedVector2Array = []
var _phase: PackedFloat32Array = []


func _ready() -> void:
	for i in COUNT:
		_seed.append(Vector2(_hash(i * 2), _hash(i * 2 + 1)))
		_phase.append(_hash(i * 7 + 3) * TAU)


static func _hash(n: int) -> float:
	var x := (n * 374761393 + 668265263) & 0x7fffffff
	x = ((x ^ (x >> 13)) * 1274126177) & 0x7fffffff
	return float(x % 10007) / 10007.0


## Where mote `i` is at time `t` (stage-local px), wrapping inside AREA.
func mote_at(i: int, t: float) -> Vector2:
	var s := _seed[i]
	var k := 0.0 if still else t
	var y := fposmod(s.y * AREA.size.y - k * DRIFT_PX_S * (0.4 + s.x), AREA.size.y)
	var x := s.x * AREA.size.x + sin(k * 0.3 + _phase[i]) * SWAY_PX
	return AREA.position + Vector2(fposmod(x, AREA.size.x), y)


func _process(delta: float) -> void:
	_t += delta
	queue_redraw()


func _draw() -> void:
	_ensure_dot()
	for i in _seed.size():
		var p := mote_at(i, _t)
		var glint := 0.0
		for j in lights.size():
			if j == 1 and light_down:
				continue
			glint = maxf(glint, 1.0 - p.distance_to(lights[j]) / GLINT_RADIUS)
		var twinkle := 0.75 + 0.25 * sin(_t * 1.7 + _phase[i])
		var c := Pal.BONE_3.lerp(Pal.GAS_5, clampf(glint, 0.0, 1.0) * 0.5)
		c.a = clampf((0.18 + GLINT * glint) * twinkle, 0.0, 0.9)
		# Perf (Q-T248, Ruins): one textured quad per mote from a shared generated dot, so the canvas
		# batches all of them (was a tessellated circle each, every frame)
		var d := 2.0 * (RADIUS_PX + 0.5 * glint) / DOT_SOLID
		draw_texture_rect(_dot_tex, Rect2(p - Vector2(d, d) * 0.5, Vector2(d, d)), false, c)
