class_name AetherLeviathan
extends AetherShaderRect
## The Presence (leviathan) crossing the frame: scale by occlusion — it passes in front of the
## sphere line, blots out the stars, is cropped by both frame edges (body ~60% of frame height).
## Moves, fades at the ends of its pass, flees as drain rises.
## Never a collider (no physics body anywhere under it). Emits `leviathan_entered` when it comes
## into the frame and `leviathan_closest` when its middle passes the frame centre.

signal leviathan_entered
signal leviathan_closest

## ✱ quad size in logical px: many times the frame, so it is only ever seen cropped.
@export var quad_size: Vector2 = Vector2(2600.0, 900.0)
## ✱ y of the body's centre line in layer px (low, so the frame crops it).
@export var body_y: float = 176.0
## ✱ body thickness in logical px (about 60% of the 360 px frame).
@export var thickness: float = 230.0
## ✱ extra speed per unit of drain (it flees).
@export var flee_speedup: float = 5.0

var cross_s := 20.0
var period_s := 34.0
var _progress := 0.0      ## seconds along the period (scaled by flee)
var _last_t := -1.0
var _inside := false
var _closest_fired := false
var screen_width := 640.0


func _ready() -> void:
	super._ready()
	size = quad_size
	set_param(&"quad_size", quad_size)
	set_param(&"thickness", thickness)


func configure(look: AetherLook) -> void:
	cross_s = maxf(look.leviathan_cross_s, 1.0)
	period_s = maxf(look.leviathan_period_s, cross_s)
	_progress = look.leviathan_phase_s
	_last_t = -1.0
	_inside = false
	_closest_fired = false
	set_param(&"body_col", look.far_silhouette)
	set_param(&"plate_col", look.fog_mid)
	set_param(&"rim_col", look.leviathan_rim)
	set_param(&"light_col", look.leviathan_lights)
	set_param(&"thickness", thickness)
	set_param(&"floor_col", Pal.VOID_0)


func advance(t: float, drain: float) -> void:
	var dt := 0.0 if _last_t < 0.0 else maxf(t - _last_t, 0.0)
	_last_t = t
	_progress += dt * (1.0 + flee_speedup * drain)
	if _progress >= period_s:
		_progress = fposmod(_progress, period_s)
		_closest_fired = false
	var travel := screen_width + 20.0 + quad_size.x
	var k := _progress / cross_s
	position = Vector2(screen_width + 20.0 - k * travel, body_y - quad_size.y * 0.5)
	var visible_now := k < 1.0
	var presence := smoothstep(0.0, 0.08, k) * (1.0 - smoothstep(0.85, 1.0, k)) if visible_now else 0.0
	presence *= 1.0 - 0.6 * drain
	set_param(&"presence", presence)
	set_param(&"time_s", t)
	set_param(&"drain", drain)
	if visible_now and not _inside:
		leviathan_entered.emit()
	_inside = visible_now
	if visible_now and not _closest_fired and position.x + quad_size.x * 0.5 <= screen_width * 0.5:
		_closest_fired = true
		leviathan_closest.emit()


## Screen position (logical px) of this quad's origin, for layers that read its body line.
func screen_origin() -> Vector2:
	return get_global_transform_with_canvas().origin


## Current presence 0..1 (0 when absent).
func presence() -> float:
	var v: Variant = get_param(&"presence")
	return float(v) if v != null else 0.0
