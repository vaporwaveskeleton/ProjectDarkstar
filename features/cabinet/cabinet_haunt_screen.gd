class_name CabinetHauntScreen
extends Node2D
## W0-12 Hauntings drawn on the arcade screen itself (layer one, through the CRT pass and the registers):
## - `field_figure` (Q-T253): for one field a tall, thin standing figure at the right edge of the play view,
##   dim (VOID_3), as if someone stood behind the glass. A person's outline, no features: not the entity,
##   never a face (NARR-001 N4). Attract and demo only. Never under photosensitivity / reduced motion.
## - `after_image` (Q-T259): on a READY card the tube holds a dim burn of something it has never drawn: the
##   very column that the reveal will empty out of the wound, at the same off-centre place (MawView). It fades
##   in and out slowly (VOID_2 at most, additive), so it is never a flash, and it keeps under reduced motion.
## Costume only: it lies in the play view, never on the HUD strip, and uses VOID registers only.

@export var spec: CabinetScreenSpec
@export var tuning: CabinetHauntTuning
@export var decay_tuning: CabinetDecayTuning

var _figure_frames := 0
var _after_t := -1.0
var _outline := PackedVector2Array()
var _play := Rect2()


func _ready() -> void:
	if spec == null:
		spec = load("res://data/cabinet/cabinet_screen.tres") as CabinetScreenSpec
	if tuning == null:
		tuning = load("res://data/cabinet/cabinet_haunt.tres") as CabinetHauntTuning
	if decay_tuning == null:
		decay_tuning = load("res://data/cabinet/cabinet_decay.tres") as CabinetDecayTuning
	_play = spec.play_rect()
	_outline = MawView.column_outline(MawView.focus_point(spec, decay_tuning), _play.size.y)
	var m := CanvasItemMaterial.new()
	m.blend_mode = CanvasItemMaterial.BLEND_MODE_ADD   # a burn and a glimpse add light; they never black anything out
	material = m


func show_figure() -> void:
	_figure_frames = tuning.figure_frames
	queue_redraw()


func show_after_image() -> void:
	_after_t = 0.0
	queue_redraw()


func clear() -> void:
	_figure_frames = 0
	_after_t = -1.0
	queue_redraw()


func is_showing_figure() -> bool:
	return _figure_frames > 0


## The after-image's strength now (0 = none), for tests and captures.
func after_image_k() -> float:
	return tuning.after_image_k(_after_t) if _after_t >= 0.0 else 0.0


func _process(delta: float) -> void:
	if _after_t >= 0.0:
		_after_t += delta
		if _after_t >= tuning.after_image_s():
			_after_t = -1.0
		queue_redraw()
	elif _figure_frames > 0:
		queue_redraw()


func _draw() -> void:
	var k := after_image_k()
	if k > 0.0:
		var c := Pal.VOID_2
		draw_colored_polygon(_outline, Color(c.r * k, c.g * k, c.b * k, 1.0))
	if _figure_frames > 0:
		_figure_frames -= 1
		draw_colored_polygon(figure_outline(_play), Pal.VOID_3)
		if _figure_frames == 0:
			queue_redraw.call_deferred()   # the next frame draws nothing: exactly figure_frames fields


## A standing figure in a long coat, at the right edge of the play view, about a third of its height:
## narrow head (a hexagon, not a circle), sloped shoulders, the coat falling straight. No features.
static func figure_outline(play: Rect2) -> PackedVector2Array:
	var h := play.size.y * 0.34
	var foot := Vector2(play.end.x - 20.0, play.position.y + play.size.y * 0.78)
	var u := h / 34.0
	var pts := [
		Vector2(0, -34), Vector2(2, -33), Vector2(2.5, -30), Vector2(1.5, -28),        # crown, right of the head
		Vector2(5, -26.5), Vector2(6.5, -24), Vector2(6, -14), Vector2(5.5, 0),         # shoulder, coat to the hem
		Vector2(2, 0), Vector2(1.5, -6), Vector2(-1.5, -6), Vector2(-2, 0),             # the gap between the feet
		Vector2(-5.5, 0), Vector2(-6, -14), Vector2(-6.5, -24), Vector2(-5, -26.5),
		Vector2(-1.5, -28), Vector2(-2.5, -30), Vector2(-2, -33)]
	var out := PackedVector2Array()
	for p: Vector2 in pts:
		out.append((foot + p * u).round())
	return out
