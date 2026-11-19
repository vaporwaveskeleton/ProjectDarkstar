class_name PilotLamp
extends Node2D
## The Vigil's pilot lamp, walked between the Ruins' places (SLICE beats 8–11: "the player walks the
## Vigil's pilot-lamp cursor between them"). Visual only, inside RuinsLook's lit stage: a small brass
## lantern on a carrying hook, its flame a RuinsLamp (so it lights the hall around it as it walks).
## The Ruins scene sets `position`, `down` (lantern_toggle) and calls gutter() at the dark mouth.

## ✱ the lamp's light: colour, energy, radius (px), core, catch (s), breath.
const LIGHT_ENERGY := 0.55
const LIGHT_ENERGY_DOWN := 0.06
const LIGHT_RADIUS := 70.0
const CATCH_S := 0.9
## ✱ seconds a gutter (the dark refusing the lamp) dims the flame.
const GUTTER_S := 0.8

var down := false:
	set(v):
		down = v
		_configure()
## Photosensitivity: the gutter dims without a flicker.
var steady := false
var flame: RuinsLamp
var _gutter := 0.0
var _t := 0.0


func _ready() -> void:
	flame = RuinsLamp.new()
	flame.name = "Flame"
	flame.position = Vector2(0, -14)
	add_child(flame)
	_configure()
	flame.catch_light()


func _configure() -> void:
	if flame == null:
		return
	var e := LIGHT_ENERGY_DOWN if down else LIGHT_ENERGY
	e *= 1.0 - 0.6 * clampf(_gutter / GUTTER_S, 0.0, 1.0)
	flame.configure(Pal.GAS_4, e, LIGHT_RADIUS, 1.3, CATCH_S, 0.4, 0.05)


## The lamp met the dark: it shrinks back for a moment.
func gutter() -> void:
	_gutter = GUTTER_S


func _process(delta: float) -> void:
	_t += delta
	if _gutter > 0.0:
		_gutter = maxf(0.0, _gutter - delta)
		if not steady and int(_t * 14.0) % 3 == 0:
			flame.level = maxf(0.35, flame.level - 0.1)
		_configure()
	flame.step(delta)
	queue_redraw()


func _draw() -> void:
	# a hook on a short pole and the lantern's brass frame round the flame (flame drawn by RuinsLamp)
	var lit := 0.25 if down else 1.0
	var brass := Pal.VOID_4.lerp(Pal.BONE_3.lerp(Pal.GAS_3, 0.35), lit)
	draw_line(Vector2(0, 0), Vector2(0, -6), brass, 1.0)
	draw_arc(Vector2(0, -8), 2.0, PI * 0.1, PI * 1.9, 8, brass, 0.8)
	draw_rect(Rect2(-3.5, -19, 7, 10), brass, false, 0.8)
	draw_line(Vector2(-4.5, -19.5), Vector2(4.5, -19.5), brass, 1.0)
	draw_line(Vector2(-4, -8.5), Vector2(4, -8.5), brass, 1.0)
