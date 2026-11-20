class_name AetherVigilRig
extends Node2D
## The Aether-tier Vigil look (ART-001 §16.7, ART-002 §4.1): a brass lantern skiff drawn at runtime
## in Pal colours, with modules that show owned Lantern Tree nodes. Visual only: it owns no hit
## truth (collision stays on the Vigil body). The Vigil feeds it every frame through set_pose().
## Origin = the lamp (near the 12 px hitbox). Hull points along local +X, rotated by hull_heading.

const LOOK_PATH := "res://data/vigil/aether_vigil_look.tres"

## Lantern Tree node id -> part (ART-002 §4.1). Parts not listed here are always present.
const MODULE_PARTS := {
	"HULL-1": &"vaneA", "HULL-7": &"vaneB", "HULL-4": &"plate",
	"HULL-3": &"shutter1", "HULL-5": &"shutter2", "HULL-15": &"shutter3",
	"HULL-9": &"anchorRing", "ORDNANCE-1": &"hookReel",
	"LANTERN-1": &"bellowsB", "LANTERN-6": &"bellowsChain", "LANTERN-7": &"bellowsChain",
	"LANTERN-9": &"keelFairing", "LANTERN-10": &"keelLamp", "LANTERN-13": &"keelBlade",
	"LANTERN-16": &"oiler", "LANTERN-3": &"globeLarge", "LANTERN-5": &"louvres",
}
const ALWAYS_PARTS: Array[StringName] = [&"keelSpine", &"hull", &"bellowsA", &"lanceTurret",
		&"lampGimbal", &"lampGlobe", &"flue"]
## ✱ drawing, pass 8 c (Q-T406): the Lantern Down ember (core radius and glow radius as globe radii,
## opacities) and the warm hull rim it lights. Gaslight on the player only (ART-001 law 1).
const EMBER_CORE := 0.45
const EMBER_ALPHA := 0.75
const EMBER_GLOW := 3.2
const EMBER_GLOW_ALPHA := 0.22
const HULL_RIM_ALPHA := 0.5

@export var look: AetherVigilLook

var _parts: Dictionary = {}
var _heading: float = 0.0
var _aim: float = 0.0
var _velocity: Vector2 = Vector2.ZERO
var _accel: Vector2 = Vector2.ZERO
var _thrust: float = 0.0
var _braking: bool = false
var _lantern_up: bool = true
var _surging: bool = false

var _time: float = 0.0
var _lamp: float = 1.0
var _shutters: float = 0.0
var _vane: float = 0.0
var _gimbal: Vector2 = Vector2.ZERO
var _gimbal_vel: Vector2 = Vector2.ZERO
var _bellows_phase: float = 0.0
var _surge_t: float = 0.0
var _noise: FastNoiseLite
var _wake: Array[Dictionary] = []   # {pos: Vector2 (global), age: float}

var _breached: bool = false
var _breach_t: float = 0.0
var _sparks: Array[Dictionary] = []
var _glows: Array[Dictionary] = []
var _glow_node: Node2D
var _glow_tex: GradientTexture2D


func _init() -> void:
	for p in ALWAYS_PARTS:
		_parts[p] = true
	_noise = FastNoiseLite.new()
	_noise.seed = 4107
	_noise.frequency = 1.0


func _ready() -> void:
	_look()
	var g := Gradient.new()
	g.set_color(0, Color.WHITE)
	g.set_color(1, Color(1, 1, 1, 0))
	_glow_tex = GradientTexture2D.new()
	_glow_tex.gradient = g
	_glow_tex.fill = GradientTexture2D.FILL_RADIAL
	_glow_tex.fill_from = Vector2(0.5, 0.5)
	_glow_tex.fill_to = Vector2(1.0, 0.5)
	_glow_tex.width = 64
	_glow_tex.height = 64
	var layer := _GlowLayer.new()
	layer.name = "Glow"
	layer.owner_rig = self
	var mat := CanvasItemMaterial.new()
	mat.blend_mode = CanvasItemMaterial.BLEND_MODE_ADD
	layer.material = mat
	_glow_node = layer
	add_child(layer)


## Per-frame pose. Angles in radians, world space. accel in px/s² (world). thrust 0..1.
func set_pose(hull_heading: float, aim_angle: float, velocity: Vector2, accel: Vector2,
		thrust: float, braking: bool, lantern_up: bool, surging: bool) -> void:
	_heading = hull_heading
	_aim = aim_angle
	_velocity = velocity
	_accel = accel
	_thrust = clampf(thrust, 0.0, 1.0)
	_braking = braking
	_lantern_up = lantern_up
	if surging and not _surging:
		_surge_t = _look().surge_bloom_s
	_surging = surging


## Owned Lantern Tree node ids (e.g. "HULL-1", "LANTERN-10") that have a visible module.
func set_modules(node_ids: PackedStringArray) -> void:
	_parts.clear()
	for p in ALWAYS_PARTS:
		_parts[p] = true
	for id in node_ids:
		if MODULE_PARTS.has(id):
			_parts[MODULE_PARTS[id]] = true


## Called once when the hull is breached (lamp gutters, hull goes dark).
func play_breach() -> void:
	if _breached:
		return
	_breached = true
	_breach_t = 0.0
	if has_part(&"plate"):
		var rng := RandomNumberGenerator.new()
		rng.seed = 91
		var n: int = _look().spark_count
		for i in n:
			var a: float = TAU * float(i) / float(maxi(n, 1)) + rng.randf_range(-0.2, 0.2)
			_sparks.append({"pos": Vector2(rng.randf_range(-6.0, 12.0), rng.randf_range(-6.0, 6.0)),
					"vel": Vector2.from_angle(a) * _look().spark_speed * rng.randf_range(0.5, 1.0),
					"age": 0.0})


func has_part(part: StringName) -> bool:
	if part == &"plateSheared":
		return plate_sheared()
	return _parts.has(part)


## 0..1 brightness of the lamp globe (dim ember while Lantern Down, 0 once the breach has guttered it out).
func lamp_intensity() -> float:
	return _lamp


## 0 closed .. 1 fully open brake shutters.
func shutter_openness() -> float:
	return _shutters


## Current swing of the globe in its gimbal (px, world axes): opposite to acceleration.
func gimbal_offset() -> Vector2:
	return _gimbal


func plate_sheared() -> bool:
	return _breached and _parts.has(&"plate")


## True once the breach has finished: lamp out and hull dark.
func is_dark() -> bool:
	return _breached and _lamp <= 0.001 and _hull_dark() >= 0.999


func is_breached() -> bool:
	return _breached


## Palette colours the rig draws with (tests scan this).
func palette_colors() -> Array[Color]:
	return _look().all_colors()


func _look() -> AetherVigilLook:
	if look == null:
		look = load(LOOK_PATH) as AetherVigilLook
	if look == null:
		look = AetherVigilLook.new()
	return look


func _process(delta: float) -> void:
	step(delta)
	if is_visible_in_tree():
		queue_redraw()
		if _glow_node != null:
			_glow_node.queue_redraw()


## Advance the rig's own motion (springs, easing, wake). Public so tests can step it deterministically.
func step(delta: float) -> void:
	var lk := _look()
	delta = minf(delta, 1.0 / 30.0)
	_time += delta
	# Lamp: ease to lit / ember; a breach gutters it with flicker, then out.
	if _breached:
		_breach_t += delta
		var k: float = clampf(_breach_t / maxf(lk.breach_gutter_s, 0.001), 0.0, 1.0)
		var flick: float = 0.5 + 0.5 * sin(_breach_t * 38.0 + sin(_breach_t * 11.0) * 2.0)
		_lamp = 0.0 if k >= 1.0 else minf(_lamp, (1.0 - k) * lerpf(0.35, 1.0, flick))
	else:
		var target: float = 1.0 if _lantern_up else lk.lamp_dim_level
		_lamp = lerpf(_lamp, target, clampf(lk.lamp_ease_rate * delta, 0.0, 1.0))
	_shutters = move_toward(_shutters, 1.0 if _braking else 0.0, lk.shutter_rate * delta)
	# Vanes angle with lateral thrust (perpendicular to the hull).
	var lateral: float = _accel.dot(Vector2.from_angle(_heading + PI * 0.5))
	var vane_t: float = clampf(lateral / maxf(lk.vane_accel_ref, 1.0), -1.0, 1.0)
	_vane = lerpf(_vane, vane_t, clampf(lk.vane_rate * delta, 0.0, 1.0))
	# Gimbal: damped spring pulled toward -accel (the visible sign of inertia).
	var gt: Vector2 = -_accel / maxf(lk.gimbal_accel_ref, 1.0)
	if gt.length() > 1.0:
		gt = gt.normalized()
	gt *= lk.gimbal_max_px
	var acc: Vector2 = (gt - _gimbal) * lk.gimbal_stiffness - _gimbal_vel * lk.gimbal_damping
	_gimbal_vel += acc * delta
	_gimbal += _gimbal_vel * delta
	# Bellows breathe faster with thrust, pumped while surging.
	var hz: float = lk.bellows_base_hz + lk.bellows_thrust_hz * _thrust \
			+ (lk.bellows_surge_hz if _surging else 0.0)
	_bellows_phase += TAU * hz * delta
	_surge_t = maxf(_surge_t - delta, 0.0)
	_step_wake(delta)
	_step_sparks(delta)


func _hull_dark() -> float:
	if not _breached:
		return 0.0
	var lk := _look()
	return clampf((_breach_t - lk.breach_gutter_s) / maxf(lk.breach_dark_s, 0.001), 0.0, 1.0)


func _step_wake(delta: float) -> void:
	var lk := _look()
	for w in _wake:
		w["age"] = (w["age"] as float) + delta
	while not _wake.is_empty() and (_wake[0]["age"] as float) > lk.wake_life_s:
		_wake.pop_front()
	if _breached or _velocity.length() < lk.wake_min_speed or not is_inside_tree():
		return
	var stern: Vector2 = to_global(Vector2.from_angle(_heading) * -lk.hull_stern_x)
	if _wake.is_empty() or (_wake[_wake.size() - 1]["pos"] as Vector2).distance_to(stern) >= lk.wake_spacing:
		_wake.append({"pos": stern, "age": 0.0})
		if _wake.size() > lk.wake_max_points:
			_wake.pop_front()


func _step_sparks(delta: float) -> void:
	var life: float = _look().spark_life_s
	for s in _sparks:
		s["age"] = (s["age"] as float) + delta
		s["pos"] = (s["pos"] as Vector2) + (s["vel"] as Vector2) * delta
	_sparks = _sparks.filter(func(s: Dictionary) -> bool: return (s["age"] as float) < life)


# ---------------------------------------------------------------- drawing

func _tint(c: Color) -> Color:
	var d: float = _hull_dark()
	return c if d <= 0.0 else c.lerp(Pal.VOID_0, d * 0.85)


## Half-width of the hull at local x (smooth lens: blunt stern, pointed nose).
func _hw(x: float) -> float:
	var lk := _look()
	if x < -lk.hull_stern_x or x > lk.hull_nose_x:
		return 0.0
	var u: float = (x + lk.hull_stern_x) / (lk.hull_stern_x + lk.hull_nose_x)   # 0 stern .. 1 nose
	var swell: float = sin(u * PI * 0.92 + 0.12)
	var taper: float = 1.0 - pow(u, 3.0) * 0.75
	return lk.hull_half_width * clampf(swell * taper, 0.18, 1.0)


func _outline() -> PackedVector2Array:
	var lk := _look()
	var top := PackedVector2Array()
	var steps := 16
	for i in steps + 1:
		var x: float = lerpf(-lk.hull_stern_x, lk.hull_nose_x, float(i) / float(steps))
		top.append(Vector2(x, -_hw(x)))
	var out := PackedVector2Array(top)
	for i in range(top.size() - 1, -1, -1):
		out.append(Vector2(top[i].x, -top[i].y))
	return out


func _draw() -> void:
	var lk := _look()
	_glows.clear()
	var lamp: float = _lamp
	_draw_wake()
	# Hull layer (rotated by the heading): keel -> hull -> plate -> flanks -> stern -> cowl -> bow.
	draw_set_transform(Vector2.ZERO, _heading)
	_draw_keel()
	_draw_hull(lamp)
	if has_part(&"plate"):
		_draw_plate()
	_draw_vanes(lamp)
	_draw_stern(lamp)
	_draw_cowl()
	_draw_bow()
	draw_set_transform(Vector2.ZERO, 0.0)
	_draw_turret()
	_draw_lamp(lamp)
	_draw_sparks()
	if lamp > 0.01:
		_add_glow(_gimbal, lk.lamp_glow_radius * (0.6 + 0.4 * lamp), lk.bloom, lk.lamp_glow_alpha * lamp)
	if _surge_t > 0.0:
		var f: float = _surge_t / maxf(lk.surge_bloom_s, 0.001)
		_add_glow(_gimbal, lk.surge_glow_radius, lk.lamp_glass_hi, 0.6 * f)


func _add_glow(pos: Vector2, radius: float, col: Color, alpha: float) -> void:
	_glows.append({"pos": pos, "r": radius, "c": Color(col, clampf(alpha, 0.0, 1.0))})


func _draw_wake() -> void:
	if _wake.size() < 2:
		return
	var lk := _look()
	draw_set_transform_matrix(global_transform.affine_inverse())
	for i in range(1, _wake.size()):
		var a: Dictionary = _wake[i - 1]
		var b: Dictionary = _wake[i]
		var f: float = 1.0 - clampf((b["age"] as float) / maxf(lk.wake_life_s, 0.001), 0.0, 1.0)
		var col: Color = lk.wake_a.lerp(lk.wake_b, 1.0 - f)
		col.a = lk.wake_alpha * f
		draw_line(a["pos"] as Vector2, b["pos"] as Vector2, col, maxf(lk.wake_width * f, 1.0))
	draw_set_transform_matrix(Transform2D.IDENTITY)


func _draw_keel() -> void:
	var lk := _look()
	var s: float = lk.hull_stern_x + 2.0
	var n: float = lk.hull_nose_x + 3.0
	if has_part(&"keelFairing"):
		draw_colored_polygon(PackedVector2Array([Vector2(-s, -2.0), Vector2(-4.0, -4.5), Vector2(n - 4.0, -1.5),
				Vector2(n - 4.0, 1.5), Vector2(-4.0, 4.5), Vector2(-s, 2.0)]), _tint(lk.brass_dark))
	draw_line(Vector2(-s, 0), Vector2(n, 0), _tint(lk.brass_shadow), 4.0)
	draw_line(Vector2(-s, 0), Vector2(n, 0), _tint(lk.brass_light), 2.0)
	draw_line(Vector2(-s + 3.0, -0.5), Vector2(n - 2.0, -0.5), _tint(lk.brass_gleam), 1.0)
	if has_part(&"keelBlade"):
		draw_colored_polygon(PackedVector2Array([Vector2(n - 6.0, -2.5), Vector2(n + 6.0, 0.0), Vector2(n - 6.0, 2.5)]),
				_tint(lk.brass_high))
		draw_line(Vector2(n - 5.0, 0), Vector2(n + 5.0, 0), _tint(lk.brass_gleam), 1.0)
	if has_part(&"keelLamp"):
		var p := Vector2(lk.hull_nose_x * 0.55, 0.0)
		draw_circle(p, 2.2, _tint(lk.brass_dark))
		draw_circle(p, 1.4, _tint(lk.lamp_glass.lerp(lk.lamp_ember, 1.0 - _lamp)))
		if _lamp > 0.1:
			_add_glow(p.rotated(_heading), 9.0, lk.lamp_glass, 0.35 * _lamp)


func _draw_hull(lamp: float) -> void:
	var lk := _look()
	var out := _outline()
	draw_colored_polygon(out, _tint(lk.brass_dark))
	# Plate bands: nested, lighter toward the lit centre (cheap brass gradient).
	var bands: Array[Color] = [lk.brass_mid, lk.brass_light, lk.brass_high]
	for i in bands.size():
		var sc: float = 0.88 - 0.22 * float(i)
		var inner := PackedVector2Array()
		for p in out:
			inner.append(Vector2(p.x * lerpf(1.0, 0.92, float(i) * 0.4), p.y * sc))
		draw_colored_polygon(inner, _tint(bands[i]))
	draw_polyline(_close(out), _tint(lk.brass_shadow), 1.5)
	# Pass 8 c (Q-T406): Lantern Down, the ember lights a faint warm rim along the upper hull.
	var ember: float = _ember_level(clampf(lamp, 0.0, 1.0))
	if ember > 0.01:
		var top := PackedVector2Array()
		for p in out:
			if p.y < -0.5:
				top.append(p * 0.97)
		if top.size() >= 2:
			draw_polyline(top, _tint(Color(Pal.GAS_3, HULL_RIM_ALPHA * ember)), 1.0)
	# Ribs and rivets.
	var rib_x: Array[float] = [-23.0, -15.0, -7.0, 1.0, 9.0, 17.0, 25.0]
	for x in rib_x:
		var h: float = _hw(x)
		if h > 1.0:
			draw_line(Vector2(x, -h + 0.5), Vector2(x, h - 0.5), _tint(lk.engraving), 1.0)
			for sgn in [-1.0, 1.0]:
				draw_circle(Vector2(x + 1.5, (h - 1.8) * (sgn as float)), 0.7, _tint(lk.rivet))
	# Engraved filigree: two mirrored scrolls along the flanks.
	for sgn in [-1.0, 1.0]:
		var sg: float = sgn as float
		var pts := PackedVector2Array()
		for i in 21:
			var x: float = lerpf(-24.0, 24.0, float(i) / 20.0)
			pts.append(Vector2(x, sg * (_hw(x) * 0.52 + sin(x * 0.55) * 1.4)))
		draw_polyline(pts, _tint(lk.engraving), 1.0)
		draw_arc(Vector2(-16.0, sg * 5.0), 2.2, 0.0, TAU, 12, _tint(lk.engraving), 1.0)
		draw_arc(Vector2(14.0, sg * 4.0), 1.8, 0.0, TAU, 10, _tint(lk.engraving), 1.0)
	# Cockpit window with a warm glow that follows the lamp.
	var win := PackedVector2Array()
	for i in 14:
		var a: float = TAU * float(i) / 14.0
		win.append(Vector2(12.0 + cos(a) * 5.0, sin(a) * 3.0))
	draw_colored_polygon(win, _tint(lk.brass_shadow))
	var glass: Color = lk.lamp_ember.lerp(lk.window_glass, clampf(lamp, 0.0, 1.0))
	var inner_win := PackedVector2Array()
	for p in win:
		inner_win.append(Vector2(12.0 + (p.x - 12.0) * 0.78, p.y * 0.7))
	draw_colored_polygon(inner_win, _tint(glass))
	draw_line(Vector2(9.0, -1.0), Vector2(13.0, -1.2), _tint(lk.lamp_glass_hi.lerp(lk.lamp_ember, 1.0 - lamp)), 1.0)
	if lamp > 0.1:
		_add_glow(Vector2(12.0, 0.0).rotated(_heading), 11.0, lk.window_glass, 0.4 * lamp)


func _draw_plate() -> void:
	var lk := _look()
	if plate_sheared():
		# Bare ribs where the plate was.
		for x in [-4.0, 0.0, 4.0, 8.0]:
			draw_line(Vector2(x as float, -5.0), Vector2(x as float, 5.0), _tint(lk.brass_shadow), 1.5)
		draw_line(Vector2(-6.0, 0.0), Vector2(10.0, 0.0), _tint(lk.brass_shadow), 1.0)
		return
	var pl := PackedVector2Array([Vector2(-7.0, -5.0), Vector2(8.0, -4.2), Vector2(9.0, 4.2), Vector2(-7.0, 5.0)])
	draw_colored_polygon(pl, _tint(lk.brass_high))
	draw_polyline(_close(pl), _tint(lk.brass_shadow), 1.0)
	draw_line(Vector2(-5.0, -3.5), Vector2(6.0, -3.0), _tint(lk.brass_gleam), 1.0)
	for c in pl:
		draw_circle(c.lerp(Vector2(1.0, 0.0), 0.15), 0.7, _tint(lk.rivet))


func _draw_vanes(lamp: float) -> void:
	var lk := _look()
	var ang: float = _vane * deg_to_rad(lk.vane_angle_max_deg)
	var spans: Array[float] = []
	if has_part(&"vaneA"):
		spans.append(lk.vane_span * 0.62)
	if has_part(&"vaneB"):
		spans.append(lk.vane_span)
	if spans.is_empty():
		return
	for sgn in [-1.0, 1.0]:
		var sg: float = sgn as float
		var base := Vector2(-4.0, sg * (lk.hull_half_width - 2.0))
		var tip_p := base
		for span in spans:
			var chord: float = 5.0 if span < lk.vane_span else 4.0
			var dir := Vector2(sin(ang), sg * cos(ang)).normalized()
			var tip: Vector2 = base + dir * span
			var poly := PackedVector2Array([base + Vector2(-chord, 0.0), base + Vector2(chord * 0.6, 0.0),
					tip + Vector2(chord * 0.1, 0.0), tip + Vector2(-chord * 0.8, 0.0)])
			draw_colored_polygon(poly, _tint(lk.brass_mid))
			draw_polyline(_close(poly), _tint(lk.brass_shadow), 1.0)
			draw_line(base + Vector2(-chord * 0.2, 0.0), tip + Vector2(-chord * 0.3, 0.0), _tint(lk.brass_high), 1.0)
			tip_p = tip
		# Running lamp at the vane tip: out with Lantern Down.
		var run: float = 1.0 if _lantern_up and not _breached else 0.0
		draw_circle(tip_p, 1.8, _tint(lk.brass_dark))
		draw_circle(tip_p, 1.1, _tint(lk.run_lamp.lerp(lk.brass_shadow, 1.0 - run)))
		if run > 0.0:
			_add_glow(tip_p.rotated(_heading), lk.run_lamp_glow_radius, lk.run_lamp, 0.55 * lamp)


func _draw_stern(_lamp_level: float) -> void:
	var lk := _look()
	var breathe: float = 1.0 + sin(_bellows_phase) * lk.bellows_amp * (1.8 if _surging else 1.0)
	var sx: float = -lk.hull_stern_x
	_draw_bellows(Vector2(sx, 0.0), 6.0, 9.0 * breathe, 5)
	if has_part(&"bellowsB"):
		var b2: float = 1.0 + sin(_bellows_phase + PI) * lk.bellows_amp
		for sgn in [-1.0, 1.0]:
			_draw_bellows(Vector2(sx + 2.0, (sgn as float) * 7.0), 3.5, 6.5 * b2, 4)
	if has_part(&"bellowsChain"):
		var pts := PackedVector2Array()
		for i in 9:
			var t: float = float(i) / 8.0
			pts.append(Vector2(sx + 4.0 + t * 12.0, -9.0 + sin(t * PI) * 3.0))
		draw_polyline(pts, _tint(lk.brass_high), 1.0)
		for p in pts:
			draw_circle(p, 0.8, _tint(lk.brass_light))
	if has_part(&"oiler"):
		var o := Vector2(-18.0, -_hw(-18.0) - 2.5)
		draw_colored_polygon(PackedVector2Array([o + Vector2(-2.0, 1.5), o + Vector2(2.0, 1.5),
				o + Vector2(1.2, -2.0), o + Vector2(-1.2, -2.0)]), _tint(lk.brass_light))
		draw_line(o + Vector2(0.0, -2.0), o + Vector2(2.5, -4.0), _tint(lk.brass_high), 1.0)
		draw_circle(o, 0.6, _tint(lk.lamp_ember))
	# Flue: lengthens with thrust, flares on a surge, flickers (seeded noise), embers when dark.
	var n: float = _noise.get_noise_1d(_time * lk.flue_noise_hz) * 0.5 + 0.5
	var heat: float = clampf(_thrust + (0.6 if _surging else 0.0), 0.0, 1.0)
	var live: float = 1.0 if _lantern_up and not _breached else 0.0
	var length: float = lk.flue_len_base + lk.flue_len_thrust * heat + (lk.flue_len_surge if _surging else 0.0)
	length *= 1.0 - lk.flue_flicker * (1.0 - n)
	length = lerpf(1.6, length, live)
	var fx: float = sx - 9.0
	var hot: Color = lk.flue_ember.lerp(lk.flue_hot, live * (0.5 + 0.5 * heat))
	var w: float = 2.6 + 1.2 * heat
	draw_colored_polygon(PackedVector2Array([Vector2(fx, -w), Vector2(fx - length, 0.0), Vector2(fx, w)]), _tint(hot))
	draw_colored_polygon(PackedVector2Array([Vector2(fx, -w * 0.45), Vector2(fx - length * 0.6, 0.0), Vector2(fx, w * 0.45)]),
			_tint(lk.flue_ember.lerp(lk.flue_core, live)))
	var fg: Vector2 = Vector2(fx - length * 0.4, 0.0).rotated(_heading)
	_add_glow(fg, lk.flue_glow_radius * (0.6 + 0.4 * heat + (0.5 if _surging else 0.0)), lk.flue_hot,
			(0.15 + 0.4 * heat * live) * (1.0 if not _breached else _lamp))


func _draw_bellows(at: Vector2, half_w: float, length: float, folds: int) -> void:
	var lk := _look()
	var seg: float = length / float(folds)
	for i in folds:
		var x0: float = at.x - seg * float(i)
		var w0: float = half_w * (1.0 - 0.07 * float(i))
		var w1: float = half_w * (1.0 - 0.07 * float(i + 1)) * (0.82 if i % 2 == 0 else 1.0)
		draw_colored_polygon(PackedVector2Array([Vector2(x0, at.y - w0), Vector2(x0 - seg, at.y - w1),
				Vector2(x0 - seg, at.y + w1), Vector2(x0, at.y + w0)]),
				_tint(lk.brass_mid if i % 2 == 0 else lk.brass_light))
		draw_line(Vector2(x0 - seg, at.y - w1), Vector2(x0 - seg, at.y + w1), _tint(lk.brass_shadow), 1.0)


func _draw_cowl() -> void:
	var lk := _look()
	var cx: float = 20.0
	var cw: float = _hw(cx)
	draw_arc(Vector2(cx, 0.0), cw * 0.85, -PI * 0.5, PI * 0.5, 12, _tint(lk.brass_high), 1.5)
	var open: float = deg_to_rad(lk.shutter_open_deg) * _shutters
	var names: Array[StringName] = [&"shutter1", &"shutter2", &"shutter3"]
	for i in names.size():
		if not has_part(names[i]):
			continue
		var x: float = 14.0 + 3.6 * float(i)
		var h: float = _hw(x) * 0.8
		# Closed: lies across the hull (along y). Open: pivots about its hinge toward the flow (along x).
		for sgn in [-1.0, 1.0]:
			var sg: float = sgn as float
			var hinge := Vector2(x, sg * h)
			var d: Vector2 = Vector2(0.0, -sg).rotated(sg * open) * (h * 0.9)
			draw_line(hinge, hinge + d, _tint(lk.brass_dark), 2.5)
			draw_line(hinge, hinge + d, _tint(lk.brass_light), 1.0)
			draw_circle(hinge, 0.9, _tint(lk.rivet))


func _draw_bow() -> void:
	var lk := _look()
	var nx: float = lk.hull_nose_x
	if has_part(&"anchorRing"):
		draw_arc(Vector2(nx - 2.0, 0.0), 3.2, 0.0, TAU, 14, _tint(lk.brass_high), 1.5)
		draw_circle(Vector2(nx - 2.0, 0.0), 0.8, _tint(lk.brass_gleam))
	if has_part(&"hookReel"):
		var r := Vector2(nx - 12.0, 5.0)
		draw_circle(r, 3.0, _tint(lk.brass_dark))
		draw_circle(r, 2.2, _tint(lk.brass_light))
		draw_circle(r, 0.8, _tint(lk.brass_shadow))
		draw_line(r, r + Vector2(2.0, 0.0), _tint(lk.brass_gleam), 1.0)
		draw_line(r + Vector2(0.0, 3.0), r + Vector2(5.0, 6.0), _tint(lk.brass_high), 1.0)


func _draw_turret() -> void:
	var lk := _look()
	draw_set_transform(Vector2.ZERO, _aim)
	draw_rect(Rect2(2.0, -1.8, 11.0, 3.6), _tint(lk.brass_shadow))
	draw_rect(Rect2(2.0, -1.0, 11.0, 2.0), _tint(lk.brass_light))
	draw_line(Vector2(3.0, -0.3), Vector2(12.0, -0.3), _tint(lk.brass_gleam), 1.0)
	draw_rect(Rect2(12.0, -2.2, 2.0, 4.4), _tint(lk.brass_high))
	draw_circle(Vector2.ZERO, 5.0, _tint(lk.brass_dark))
	draw_circle(Vector2.ZERO, 4.0, _tint(lk.brass_mid))
	draw_set_transform(Vector2.ZERO, 0.0)


func _draw_lamp(lamp: float) -> void:
	var lk := _look()
	var g: Vector2 = _gimbal
	var r: float = lk.globe_large_radius if has_part(&"globeLarge") else lk.globe_radius
	# Gimbal: a brass ring about the origin, struts to the swinging globe.
	draw_arc(Vector2.ZERO, lk.gimbal_radius, 0.0, TAU, 28, _tint(lk.brass_shadow), 2.5)
	draw_arc(Vector2.ZERO, lk.gimbal_radius, 0.0, TAU, 28, _tint(lk.brass_high), 1.0)
	draw_arc(Vector2.ZERO, lk.gimbal_radius - 2.0, -0.8, 0.8, 8, _tint(lk.brass_gleam), 1.0)
	for a in [0.0, PI * 0.5, PI, PI * 1.5]:
		draw_circle(Vector2.from_angle(a as float) * lk.gimbal_radius, 1.2, _tint(lk.rivet))
	draw_line(Vector2(0.0, -lk.gimbal_radius), g + Vector2(0.0, -r), _tint(lk.brass_mid), 1.0)
	draw_line(Vector2(0.0, lk.gimbal_radius), g + Vector2(0.0, r), _tint(lk.brass_mid), 1.0)
	# Globe: ember at low lamp, glass and core when lit. The brightest thing drawn.
	var lit: float = clampf(lamp, 0.0, 1.0)
	draw_circle(g, r + 1.5, _tint(lk.brass_dark))
	draw_circle(g, r, _tint(lk.lamp_ember.lerp(lk.lamp_glass, lit)))
	draw_circle(g, r * 0.72, _tint(lk.lamp_ember.lerp(lk.lamp_glass_hi, lit)))
	draw_circle(g, r * 0.4, _tint(lk.lamp_ember.lerp(lk.lamp_core, lit)))
	if has_part(&"louvres"):
		var open: float = 1.0 if _lantern_up and not _breached else 0.0
		for i in 4:
			var y: float = (float(i) - 1.5) * r * 0.5
			var half: float = sqrt(maxf(r * r - y * y, 0.0))
			draw_line(g + Vector2(-half, y), g + Vector2(half, y), _tint(lk.brass_dark), lerpf(1.8, 0.6, open))
	draw_arc(g, r, 0.0, TAU, 24, _tint(lk.brass_high), 1.0)
	draw_circle(g + Vector2(-r * 0.35, -r * 0.4), 0.9, _tint(lk.lamp_core.lerp(lk.lamp_ember, 1.0 - lit)))
	# Pass 8 c (Q-T406): Lantern Down keeps a dim ember alive in the housing, so the ship stays the
	# clearest shape in the dark (gaslight, the player's own colour; out once a breach gutters it).
	var ember: float = _ember_level(lit)
	if ember > 0.01:
		draw_circle(g, r * EMBER_CORE, _tint(Color(Pal.GAS_3, EMBER_ALPHA * ember)))
		draw_circle(g, r * EMBER_CORE * 0.45, _tint(Color(Pal.GAS_4, EMBER_ALPHA * ember)))
		_add_glow(g, r * EMBER_GLOW, Pal.GAS_2, EMBER_GLOW_ALPHA * ember)


## 0..1: the Lantern Down ember (1 - the lamp's light; 0 once the breach has guttered it).
func _ember_level(lit: float) -> float:
	return 0.0 if _breached else clampf(1.0 - lit, 0.0, 1.0)


func _draw_sparks() -> void:
	var lk := _look()
	for s in _sparks:
		var f: float = 1.0 - clampf((s["age"] as float) / maxf(lk.spark_life_s, 0.001), 0.0, 1.0)
		var p: Vector2 = s["pos"] as Vector2
		draw_circle(p, 1.0 + f, Color(lk.spark, f))
		_add_glow(p, 5.0, lk.spark, 0.5 * f)


func _close(pts: PackedVector2Array) -> PackedVector2Array:
	var out := PackedVector2Array(pts)
	out.append(pts[0])
	return out


## Additive glow layer: soft radial blobs from the rig's list (child of the rig so it draws on top).
class _GlowLayer extends Node2D:
	var owner_rig: AetherVigilRig

	func _draw() -> void:
		if owner_rig == null or owner_rig._glow_tex == null:
			return
		for g in owner_rig._glows:
			var r: float = g["r"] as float
			var p: Vector2 = g["pos"] as Vector2
			draw_texture_rect(owner_rig._glow_tex, Rect2(p - Vector2(r, r), Vector2(r, r) * 2.0), false, g["c"] as Color)
