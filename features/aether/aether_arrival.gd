extends Node
## The Aether arrival (route &"aether", TECH-001 §2.9): the first Unmaking cinematic, beats 4–6
## (research/act1_vertical_slice.md §2; GDD §6.1: in-engine, ≤ 90 s from the tear, agency 0 except a
## look-only tilt in beat 4, unskippable once and skippable after). Every duration and curve is in
## UnmakingTimeline; this script only plays it:
##   beat 4 tear silence — Pale Marches T1, the Presence far off with its heartbeat, the T1 bed; the
##          mouse (or right stick) tilts the parallax a few px, with no gameplay effect;
##   beat 5 the arrival  — the Presence turns and leaves; an off-centre erasure front spreads outward
##          from inside the picture across the sphere seam (the entity: the only true black), the
##          audio subtraction ramps; slow, no flash, no full-field step (WARP-001 §4.5);
##   beat 6 the last light — the front reaches the stand-in lamp (LastLamp, not the Vigil), it dims,
##          then black with one phosphor ember fading across the full 10 s, in silence; then
##          SceneRouter.go_to(&"ruins", …) exactly once.
## First frame: no fade-in and no tween on entry (the caller routes here with `skip_curtain`, so Act
## 0's last frame is followed directly by this scene's first); on_route_entered pushes everything the
## first drawn frame needs. No class_name: reached only by route id. Saves nothing (no saves mid-run):
## whether the cinematic was seen is the caller's (RunSession / M1), passed in as `can_skip`.
##
## Route params (all optional, typed; a missing or wrongly typed value uses the default):
##   aether_time_s (float) world time to continue from, tier (int 1–5),
##   camera_centre (Vector2, logical px), camera_zoom (float), can_skip (bool, default false).
## Every other param is forwarded unchanged to &"ruins" (e.g. act0_vigil_index, shift_total), with
## "first_visit": true added; a key that did not arrive is not invented.

const DEFAULT_TIME_S := 0.0
const DEFAULT_TIER := 1
const DEFAULT_CAMERA_CENTRE := Vector2(320.0, 180.0)   ## ✱ centre of the 640×360 logical frame
const DEFAULT_CAMERA_ZOOM := 1.0
const RUINS_ROUTE := &"ruins"
## The keys that are this scene's or the router's own: read here, never forwarded to the Ruins.
const OWN_KEYS: Array[String] = ["skip_curtain", "aether_time_s", "tier", "camera_centre", "camera_zoom", "can_skip"]
## ✱ seconds ui_cancel or ui_accept must be held to skip (only when can_skip).
const SKIP_HOLD_S := 0.6
## ✱ look-only tilt: camera offset (logical px) at full mouse / stick deflection, the smoothing time
## constant (s) and the stick deadzone.
const TILT_PX := 6.0
const TILT_SMOOTH_S := 0.5
const TILT_DEADZONE := 0.2
## Dev-only (LaunchRoute.is_dev_build): `--aether-cine-scale=N` (1–16) runs the whole cinematic N×
## faster through Engine.time_scale, so a capture fits its frame budget (tests/scenarios/
## aether_unmaking_capture is timed for N = 8, appended to the Godot command line by hand: suite
## scenarios must keep args == []; without it the scenario still passes, on beat-4 frames). Never in a release.
const DEV_SCALE_ARG := "--aether-cine-scale="
## Dev-only: `--aether-cine-measure=T` holds the cinematic at time T (the world keeps running), waits
## MEASURE_WARMUP frames, prints AETHER_CINE_COST (GPU / CPU ms of the world viewport and its
## offscreen layers, averaged over MEASURE_FRAMES), then quits. Never in a release.
const DEV_MEASURE_ARG := "--aether-cine-measure="
const MEASURE_WARMUP := 420   ## ✱ > FrostPresence.FLEE_S at 60 fps, so a held late beat is settled
const MEASURE_FRAMES := 120   ## ✱
const BED_CUE := &"aether_bed_t1"
const FLEE_CUE := &"presence_flee"
## The last lamp starving (AUDIO-001 §12.19): starts as the front reaches the lamp and ends in a 0.3 s
## fade at the black, so the protected silence that follows is the beat (no sting, §1.1).
const LAMP_OUT_CUE := &"unmaking_lamp_out"

## The world's look. Pale Marches (T1) until the run decides where the player arrives.
@export var look: AetherLook = preload("res://data/aether/pale_marches_t1.tres")

var time_s := DEFAULT_TIME_S
## Cinematic time (s) since the hand-off.
var cine_s := 0.0
var can_skip := false
## What &"ruins" will receive.
var forward_params: Dictionary = {}
## Who receives the route request (SceneRouter unless a test stubs it): needs go_to(id, params).
var router: Object
var routed := false
var tilt := Vector2.ZERO
var _centre := DEFAULT_CAMERA_CENTRE
var _zoom := DEFAULT_CAMERA_ZOOM
var _look_target := Vector2.ZERO
var _look_smooth := Vector2.ZERO
var _skip_held := 0.0
var _fled := false
var _front := false
var _lamp_out := false
var _lamp_starving := false
var _calm := false
var _prev_time_scale := -1.0
var _hold_at := -1.0
var _measure_n := 0
var _gpu_sum := 0.0
var _cpu_sum := 0.0

@onready var _view: AetherView = %View
@onready var _backdrop: AetherBackdrop = %Backdrop
@onready var _camera: Camera2D = %Camera
@onready var _lantern: LastLamp = %Lantern


func _ready() -> void:
	if router == null:
		router = get_node_or_null(^"/root/SceneRouter")
	_calm = _setting(&"reduced_motion") or _setting(&"photosensitivity")
	_view.apply_glow(look)
	_backdrop.apply_look(look)
	_lantern.configure(look)
	_apply_dev_scale()
	on_route_entered({})


func _exit_tree() -> void:
	# left without finishing (quit, a test freeing it): leave the audio subtraction at rest
	if _front and not routed:
		_audio(&"set_subtraction", [0.0, 0.0])
	if _prev_time_scale >= 0.0:
		Engine.time_scale = _prev_time_scale
		_prev_time_scale = -1.0


## SceneRouter calls this in the same deferred call that mounts the scene, after this frame's
## _process, so everything the first drawn frame needs is pushed here, not on the next _process.
func on_route_entered(params: Dictionary) -> void:
	time_s = _float_param(params, "aether_time_s", DEFAULT_TIME_S)
	var tier := _int_param(params, "tier", DEFAULT_TIER)
	_centre = _vector2_param(params, "camera_centre", DEFAULT_CAMERA_CENTRE)
	_zoom = _float_param(params, "camera_zoom", DEFAULT_CAMERA_ZOOM)
	if _zoom <= 0.0:
		_zoom = DEFAULT_CAMERA_ZOOM
	can_skip = _bool_param(params, "can_skip", false)
	forward_params = ruins_params(params)
	cine_s = 0.0
	routed = false
	tilt = Vector2.ZERO
	_look_target = Vector2.ZERO
	_look_smooth = Vector2.ZERO
	_skip_held = 0.0
	_fled = false
	_front = false
	_lamp_out = false
	_lamp_starving = false
	if _backdrop.is_erasing():
		_backdrop.clear_erasure()
	_backdrop.set_time(time_s)
	_backdrop.set_tier(tier)
	_camera.position = _centre
	_camera.zoom = Vector2(_zoom, _zoom)
	_backdrop.set_camera(_centre, _zoom)
	_lantern.position = _centre
	_lantern.set_state(1.0, 1.0, 0.0)
	_push_lantern(1.0)
	_camera.force_update_scroll()
	_backdrop.refresh()
	_audio(&"set_ambience", [BED_CUE])


## The params &"ruins" receives: every received param unchanged except OWN_KEYS, plus
## "first_visit": true. Nothing is invented: a key that did not arrive stays missing.
static func ruins_params(params: Dictionary) -> Dictionary:
	var out := {}
	for k: Variant in params.keys():
		var key_s := str(k)
		if OWN_KEYS.has(key_s) or key_s == "first_visit":
			continue
		out[k] = params[k]
	out["first_visit"] = true
	return out


## Look-only: the mouse's position over the window sets the tilt target (beat 4 only).
func _unhandled_input(event: InputEvent) -> void:
	if event is InputEventMouseMotion:
		var size := get_viewport().get_visible_rect().size
		if size.x > 0.0 and size.y > 0.0:
			var m := (event as InputEventMouseMotion).position
			_look_target = ((m - size * 0.5) / (size * 0.5)).clamp(-Vector2.ONE, Vector2.ONE)


func _process(delta: float) -> void:
	advance(delta)


## Advance the cinematic by `delta` seconds (the world clock too) and apply its state for the new time.
func advance(delta: float) -> void:
	if routed:
		return
	delta = maxf(delta, 0.0)
	time_s += delta
	cine_s = _hold_at if _hold_at >= 0.0 else cine_s + delta
	_backdrop.set_time(time_s)
	if _hold_at >= 0.0:
		_dev_measure()
	if can_skip and (Input.is_action_pressed(&"ui_cancel") or Input.is_action_pressed(&"ui_accept")):
		_skip_held += delta
		if _skip_held >= SKIP_HOLD_S:
			_finish()
			return
	else:
		_skip_held = 0.0
	_step_tilt(delta)
	_apply(cine_s)
	if cine_s >= UnmakingTimeline.END_S:
		_finish()


func _step_tilt(delta: float) -> void:
	var target := _look_target
	for pad in Input.get_connected_joypads():
		var stick := Vector2(Input.get_joy_axis(pad, JOY_AXIS_RIGHT_X), Input.get_joy_axis(pad, JOY_AXIS_RIGHT_Y))
		if stick.length() > TILT_DEADZONE:
			target = stick.limit_length(1.0)
			break
	var w := UnmakingTimeline.tilt_weight(cine_s)
	if _calm:
		w = 0.0
	var k := 1.0 - exp(-delta / TILT_SMOOTH_S)
	_look_smooth = _look_smooth.lerp(target, k)
	# the beat-4 weight eases the offset itself, so it is exactly 0 from beat 5 on (and under calm)
	tilt = _look_smooth * TILT_PX * w


## Push the timeline's state for cinematic time `t` (and fire its one-shot events once).
func _apply(t: float) -> void:
	var cam := _centre + tilt
	_camera.position = cam
	_backdrop.set_camera(cam, _zoom)
	var light := UnmakingTimeline.lamp_light(t)
	_lantern.position = _centre + UnmakingTimeline.lamp_drift(t)
	_lantern.set_state(light, UnmakingTimeline.hull_alpha(t), UnmakingTimeline.ember(t))
	_push_lantern(light)
	if not _fled and t >= UnmakingTimeline.FLEE_AT:
		_fled = true
		_backdrop.presence_flee()
		_play(FLEE_CUE)
	if t >= UnmakingTimeline.FRONT_AT:
		if not _front:
			_front = true
			_audio(&"set_subtraction", [UnmakingTimeline.SUBTRACTION_MAX, UnmakingTimeline.LAMP_REACH_AT - UnmakingTimeline.FRONT_AT])
		var base := look.base_drain if look != null else 0.0
		_backdrop.set_drain(base + UnmakingTimeline.drain(t))
		_backdrop.set_erasure(UnmakingTimeline.FRONT_ORIGIN, UnmakingTimeline.front_radius(t),
			UnmakingTimeline.front_growth(t), UnmakingTimeline.front_reach(), UnmakingTimeline.FRONT_SEED)
	if not _lamp_starving and t >= UnmakingTimeline.LAMP_REACH_AT:
		_lamp_starving = true
		_play(LAMP_OUT_CUE)
	if not _lamp_out and t >= UnmakingTimeline.LAMP_OUT_AT:
		_lamp_out = true
		_audio(&"set_ambience", [&""])


func _push_lantern(light: float) -> void:
	var world := _lantern.position
	var logical := _backdrop.get_viewport_rect().size
	var screen := (world - _camera.position) * _zoom + logical * 0.5
	var radius := look.lantern_radius if look != null else _backdrop.lantern_radius
	var energy := look.lantern_energy if look != null else 1.6
	_backdrop.set_lantern(screen, radius * _zoom, Pal.GAS_4, energy * light)


## The end (or a skip): the Ruins, exactly once. Leaves the audio subtraction at rest for the Ruins.
func _finish() -> void:
	if routed:
		return
	routed = true
	_audio(&"set_ambience", [&""])
	_audio(&"set_subtraction", [0.0, 0.0])
	if router != null and router.has_method("go_to"):
		router.call("go_to", RUINS_ROUTE, forward_params)


func _apply_dev_scale() -> void:
	if not LaunchRoute.is_dev_build():
		return
	for a in OS.get_cmdline_user_args():
		if a.begins_with(DEV_SCALE_ARG):
			var n := clampf(a.trim_prefix(DEV_SCALE_ARG).to_float(), 1.0, 16.0)
			_prev_time_scale = Engine.time_scale
			Engine.time_scale = n
		elif a.begins_with(DEV_MEASURE_ARG):
			_hold_at = clampf(a.trim_prefix(DEV_MEASURE_ARG).to_float(), 0.0, UnmakingTimeline.END_S - 0.5)
			RenderingServer.viewport_set_measure_render_time(_view.world.get_viewport_rid(), true)


func _dev_measure() -> void:
	_measure_n += 1
	if _measure_n <= MEASURE_WARMUP:
		return
	var vp := _view.world.get_viewport_rid()
	var gpu := RenderingServer.viewport_get_measured_render_time_gpu(vp)
	for rid in _backdrop.offscreen_rids():
		gpu += RenderingServer.viewport_get_measured_render_time_gpu(rid)
	_gpu_sum += gpu
	_cpu_sum += RenderingServer.viewport_get_measured_render_time_cpu(vp)
	if _measure_n >= MEASURE_WARMUP + MEASURE_FRAMES:
		print("AETHER_CINE_COST t=%.1f beat=%d gpu_ms=%.3f cpu_ms=%.3f px=%dx%d frames=%d front_r=%.0f flee=%.2f layers=%s" % [_hold_at,
			UnmakingTimeline.beat_at(_hold_at), _gpu_sum / MEASURE_FRAMES, _cpu_sum / MEASURE_FRAMES, _view.world.size.x,
			_view.world.size.y, MEASURE_FRAMES, UnmakingTimeline.front_radius(_hold_at), _backdrop.presence_flee_progress(),
			",".join(_backdrop.active_layers())])
		_hold_at = -1.0
		get_tree().quit()


func _audio(method: StringName, args: Array) -> void:
	var a := get_node_or_null(^"/root/AudioService")
	if a != null and a.has_method(method):
		a.callv(method, args)


func _play(cue: StringName) -> void:
	var a := get_node_or_null(^"/root/AudioService")
	if a != null and a.has_method(&"has_cue") and a.has_method(&"play") and bool(a.call(&"has_cue", cue)):
		a.call(&"play", cue)


static func _setting(key: StringName) -> bool:
	if SettingsService.DEFAULTS.has(key):
		return bool(SettingsService.get_value(key))
	return false


static func _param(params: Dictionary, key: String) -> Variant:
	if params.has(key):
		return params[key]
	return params.get(StringName(key))


static func _float_param(params: Dictionary, key: String, fallback: float) -> float:
	var v: Variant = _param(params, key)
	if typeof(v) == TYPE_FLOAT or typeof(v) == TYPE_INT:
		return float(v)
	return fallback


static func _int_param(params: Dictionary, key: String, fallback: int) -> int:
	var v: Variant = _param(params, key)
	if typeof(v) != TYPE_INT:
		return fallback
	var n: int = v
	return n


static func _bool_param(params: Dictionary, key: String, fallback: bool) -> bool:
	var v: Variant = _param(params, key)
	if typeof(v) != TYPE_BOOL:
		return fallback
	var b: bool = v
	return b


static func _vector2_param(params: Dictionary, key: String, fallback: Vector2) -> Vector2:
	var v: Variant = _param(params, key)
	if typeof(v) != TYPE_VECTOR2:
		return fallback
	var out: Vector2 = v
	return out
