class_name GrubView
extends Node2D
## Draws its parent OublietteGrub (runtime vector, base palette, ART-001 §14; the Cabinet's shape
## without Look.c()). Choir hue only (ART-001 role law: CHOIR never on player art, GAS never on
## Choir). A carried shard shows as a phosphor diamond at its side. Reads only; no RNG.

const SEGMENTS := 3
const WIGGLE_RATE := 8.0     ## rad/s ✱ (Cabinet)
const FLASH_DECAY := 5.0     ## 1/s ✱ (Cabinet)

@export var grub: OublietteGrub

var _flash: float = 0.0
var _wiggle: float = 0.0


func _ready() -> void:
	if grub != null:
		_wiggle = float(grub.index)   # deterministic phase per Grub


## A hit landed (presentation only).
func flash() -> void:
	_flash = 1.0


func _process(delta: float) -> void:
	_wiggle += delta * WIGGLE_RATE
	_flash = maxf(0.0, _flash - delta * FLASH_DECAY)
	queue_redraw()


func _draw() -> void:
	if grub == null:
		return
	var v := grub.velocity
	var heading := v.normalized() if v.length() > 1.0 else Vector2.RIGHT
	var side := heading.orthogonal()
	var body := Pal.CHOIR_5 if _flash > 0.4 else Pal.CHOIR_3
	for k in SEGMENTS:
		var q := -heading * (k * 4.0) + side * sin(_wiggle - k * 1.1) * 1.5
		draw_arc(q.round(), 3.0 - k * 0.6, 0.0, TAU, 8, body, 1.0)
	draw_rect(Rect2((heading * 2.0).round(), Vector2.ONE), Pal.CHOIR_5)
	if grub.carrying:
		var s := (-side * 6.0).round()
		draw_colored_polygon(PackedVector2Array([s + Vector2(0, -3), s + Vector2(2, 0), s + Vector2(0, 3), s + Vector2(-2, 0)]), Pal.PHOS_4)
