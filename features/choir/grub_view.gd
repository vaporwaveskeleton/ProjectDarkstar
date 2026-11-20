class_name GrubView
extends Node2D
## Draws its parent OublietteGrub (runtime vector, Aether tier, ART-001 §15). Choir hue only
## (ART-001 role law: CHOIR never on player art, GAS never on Choir). Soft filled segments with
## bands, a faint bioluminescent halo (concentric low-alpha circles), a glinting carried shard
## (phosphor = truth). Reads only; no RNG.

const SEGMENTS := 3
const WIGGLE_RATE := 8.0     ## rad/s ✱ (Cabinet)
const FLASH_DECAY := 5.0     ## 1/s ✱ (Cabinet)
const HALO_RINGS := 3        ## ✱ drawing
const HALO_RADIUS_PX := 9.0  ## ✱ drawing: outermost halo ring
const HALO_ALPHA := 0.07     ## ✱ drawing: per-ring opacity (stacks to ~0.2 at the core)
const GLINT_RATE := 6.0      ## rad/s ✱ drawing: carried glass glint

@export var grub: OublietteGrub

## Multiplier on the halo (the dark kit dims it outside the light pocket; GrubProcession sets it).
var halo_scale: float = 1.0
var _flash: float = 0.0
var _wiggle: float = 0.0
var _time: float = 0.0


func _ready() -> void:
	if grub != null:
		_wiggle = float(grub.index)   # deterministic phase per Grub


## A hit landed (presentation only).
func flash() -> void:
	_flash = 1.0


func _process(delta: float) -> void:
	_wiggle += delta * WIGGLE_RATE
	_time += delta
	_flash = maxf(0.0, _flash - delta * FLASH_DECAY)
	queue_redraw()


func _draw() -> void:
	if grub == null:
		return
	var v := grub.velocity
	var heading := v.normalized() if v.length() > 1.0 else Vector2.RIGHT
	var side := heading.orthogonal()
	var hot := _flash > 0.4
	for r in HALO_RINGS:
		draw_circle(Vector2.ZERO, HALO_RADIUS_PX * float(r + 1) / HALO_RINGS, Color(Pal.CHOIR_3, HALO_ALPHA * halo_scale))
	var body := Pal.CHOIR_5 if hot else Pal.CHOIR_3
	for i in SEGMENTS:
		var k := SEGMENTS - 1 - i   # tail first so the head overlaps
		var q := (-heading * (k * 4.0) + side * sin(_wiggle - k * 1.1) * 1.5).round()
		var rad := 3.0 - k * 0.6
		draw_circle(q, rad, Color(Pal.CHOIR_2 if not hot else Pal.CHOIR_4, 0.85))
		draw_arc(q, rad, 0.0, TAU, 8, body, 1.0)
		draw_line(q - side * (rad - 0.5), q + side * (rad - 0.5), Pal.CHOIR_1, 1.0)   # segment band
	draw_rect(Rect2((heading * 2.0).round(), Vector2.ONE), Pal.CHOIR_5)
	if grub.carrying:
		var s := (-side * 6.0).round()
		var tw := 0.5 if bool(SettingsService.get_value(&"reduced_motion")) else 0.5 + 0.5 * sin(_time * GLINT_RATE)
		draw_circle(s, 3.0, Color(Pal.PHOS_3, 0.12 + 0.12 * tw))
		draw_colored_polygon(PackedVector2Array([s + Vector2(0, -3), s + Vector2(2, 0), s + Vector2(0, 3), s + Vector2(-2, 0)]), Pal.PHOS_4)
		draw_rect(Rect2(s - Vector2(0, 1), Vector2(1, 1)), Pal.PHOS_5 if tw > 0.5 else Pal.PHOS_4)
