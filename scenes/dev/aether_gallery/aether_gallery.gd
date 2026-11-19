extends Node
## Dev-only Aether gallery (route `aether_gallery`, dev builds only — never in the shipped route
## table). Shows the post-Pretence world tier by tier: 0 T1 Pale Marches, 1 T2 Green Rot,
## 2 T3 Drowned Observatory, 3 T4 Litany, 4 T5 The Black, 5 the entity's presence (T3 look,
## drain 0 → 1). ui_right / ui_left cycle, ui_focus_next cycles the quality rung, ui_cancel returns
## to attract. No on-screen text.
## The world renders in an HDR SubViewport at native window resolution with its own glow.
## Dev user args, read here only (automation ignores unknown args; TECH-001 Q-T47 note):
##   --aether-quality=high|medium|low   start on that quality rung (default high)
##   --aether-sweep                     per-layer GPU cost sweep: prints AETHER_LAYER_COST lines,
##                                      then quits (every rung, or only the --aether-quality rung)
##   --aether-exhibit=N                 start on exhibit N (0–5)
##   --aether-measure                   clean isolated cost: one exhibit (--aether-exhibit) in this
##                                      fresh process, MEASURE_WARMUP frames, then AETHER_COST over
##                                      MEASURE_FRAMES frames, then quits (entity exhibit holds
##                                      SWEEP_DRAIN)
## No class_name: scenes/dev is excluded from release builds.

signal sphere_glinted
signal leviathan_closest

const LOOKS: Array[String] = [
	"res://data/aether/pale_marches_t1.tres",
	"res://data/aether/green_rot_t2.tres",
	"res://data/aether/drowned_observatory_t3.tres",
	"res://data/aether/litany_t4.tres",
	"res://data/aether/the_black_t5.tres",
	"res://data/aether/drowned_observatory_t3.tres",
]
const ENTITY_EXHIBIT := 5
const BEDS: Array[StringName] = [&"aether_bed_t1", &"aether_bed_t2", &"aether_bed_t3", &"aether_bed_t4",
	&"aether_bed_t5", &"aether_bed_t3"]
const DRAIN_RAMP_S := 12.0     ## ✱ entity exhibit: seconds for drain 0 → 1
const DRAIN_HOLD_S := 1.0      ## ✱ entity exhibit: seconds before the drain starts
const FLEE_AT := 0.15          ## ✱ drain at which life starts to drift in (one swell)
const SILENCE_AT := 0.5        ## ✱ drain past which the bed goes to silence
const FADE_IN_S := 1.6         ## ✱ every exhibit fades in from VOID_0: zero startle
const COST_WARMUP := 90        ## ✱ frames before the cost window
const COST_FRAMES := 60        ## ✱ frames averaged per exhibit
const SWEEP_SETTLE := 24       ## ✱ frames after a layer toggle before the sweep measures
const SWEEP_FIRST_SETTLE := 40 ## ✱ settle frames after an exhibit / quality switch
const SWEEP_FRAMES := 60       ## ✱ frames averaged per sweep sample
const SWEEP_DRAIN := 0.6       ## ✱ entity exhibit drain held during the sweep
const MEASURE_WARMUP := 120    ## ✱ --aether-measure: warm-up frames before averaging
const MEASURE_FRAMES := 120    ## ✱ --aether-measure: frames averaged
const CAMERA_HOME := Vector2(320.0, 180.0)
const LANTERN_OFFSET := Vector2(0.0, 22.0)   ## ✱ lantern below frame centre
const ARG_QUALITY := "--aether-quality="
const ARG_SWEEP := "--aether-sweep"
const ARG_EXHIBIT := "--aether-exhibit="
const ARG_MEASURE := "--aether-measure"

var exhibit := 0
var exhibit_time := 0.0
var drain := 0.0
var quality_level := "high"
var _frames := 0
var _gpu_sum := 0.0
var _cpu_sum := 0.0
var _cost_logged := false
var _swell_played := false
var _silenced := false
var _looks: Array[AetherLook] = []
var _sweep_on := false
var _sweep_pairs: Array[Vector2i] = []
var _sweep_layers: Array[StringName] = []
var _sweep_li := 0
var _sweep_wait := 0
var _sweep_n := 0
var _sweep_acc := 0.0
var _sweep_base := 0.0
var _sweep_off_layer: StringName = &""
var _sweep_off_ms := 0.0
var _measure_on := false

@onready var _world: SubViewport = %World
@onready var _screen: TextureRect = %Screen
@onready var _env: WorldEnvironment = %Env
@onready var _backdrop: AetherBackdrop = %Backdrop
@onready var _lantern: LanternMarker = %Lantern
@onready var _camera: Camera2D = %Camera
@onready var _veil: ColorRect = %Veil


func _ready() -> void:
	for p in LOOKS:
		_looks.append(load(p) as AetherLook)
	_screen.texture = _world.get_texture()
	get_tree().root.size_changed.connect(_fit)
	_fit()
	RenderingServer.viewport_set_measure_render_time(_world.get_viewport_rid(), true)
	_backdrop.sphere_glinted.connect(sphere_glinted.emit)
	_backdrop.leviathan_entered.connect(_on_leviathan_entered)
	_backdrop.leviathan_closest.connect(_on_leviathan_closest)
	var args := OS.get_cmdline_user_args()
	var asked := ""
	var start := 0
	for a in args:
		if a.begins_with(ARG_QUALITY):
			asked = a.trim_prefix(ARG_QUALITY)
		elif a.begins_with(ARG_EXHIBIT):
			start = clampi(a.trim_prefix(ARG_EXHIBIT).to_int(), 0, LOOKS.size() - 1)
	set_quality(asked if asked in AetherQuality.LEVELS else "high")
	_measure_on = args.has(ARG_MEASURE)
	_show(start)
	if _measure_on:
		print("AETHER_MEASURE_START exhibit=%d quality=%s warmup=%d frames=%d" % [exhibit, quality_level, MEASURE_WARMUP, MEASURE_FRAMES])
	if args.has(ARG_SWEEP):
		var levels: Array[String] = []
		if asked in AetherQuality.LEVELS:
			levels.append(asked)
		else:
			levels.append_array(AetherQuality.LEVELS)
		_start_sweep(levels)


func _exit_tree() -> void:
	_set_ambience(&"")


## Render the world at the window's real pixel size, laid out in the root's logical space.
func _fit() -> void:
	var px := Vector2i(get_tree().root.size)
	var logical := Vector2i(get_viewport().get_visible_rect().size)
	_world.size = Vector2i(maxi(px.x, 1), maxi(px.y, 1))
	_world.size_2d_override = Vector2i(maxi(logical.x, 1), maxi(logical.y, 1))
	_world.size_2d_override_stretch = true
	_veil.size = Vector2(logical)


func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed(&"ui_right"):
		_show(posmod(exhibit + 1, LOOKS.size()))
		get_viewport().set_input_as_handled()
	elif event.is_action_pressed(&"ui_left"):
		_show(posmod(exhibit - 1, LOOKS.size()))
		get_viewport().set_input_as_handled()
	elif event.is_action_pressed(&"ui_focus_next"):
		var i := AetherQuality.LEVELS.find(quality_level)
		set_quality(AetherQuality.LEVELS[posmod(i + 1, AetherQuality.LEVELS.size())])
		print("AETHER_QUALITY %s" % quality_level)
		_show(exhibit)
		get_viewport().set_input_as_handled()
	elif event.is_action_pressed(&"ui_cancel"):
		get_viewport().set_input_as_handled()
		SceneRouter.go_to(&"attract")


func show_exhibit(index: int) -> void:
	_show(posmod(index, LOOKS.size()))


## Switch the backdrop's quality rung by name (high / medium / low).
func set_quality(level_name: String) -> void:
	var q := load(AetherQuality.path_for(level_name)) as AetherQuality
	quality_level = q.level
	_backdrop.apply_quality(q)
	_env.environment.glow_enabled = q.glow == 1


func _show(index: int) -> void:
	exhibit = index
	exhibit_time = 0.0
	_frames = 0
	_gpu_sum = 0.0
	_cpu_sum = 0.0
	_cost_logged = false
	_swell_played = false
	_silenced = false
	var look := _looks[index]
	_backdrop.apply_look(look)
	drain = look.base_drain
	_backdrop.set_drain(drain)
	_lantern.configure(look)
	var env := _env.environment
	env.glow_hdr_threshold = look.glow_threshold
	env.glow_intensity = look.glow_intensity
	env.glow_bloom = look.glow_bloom
	_veil.color = Color(Pal.VOID_0, 1.0)
	_set_ambience(BEDS[index])


func _process(delta: float) -> void:
	exhibit_time += delta
	_frames += 1
	var look := _looks[exhibit]
	_veil.color.a = 0.0 if _sweep_on else 1.0 - smoothstep(0.0, FADE_IN_S, exhibit_time)
	var drift := look.camera_drift_px
	var cam := CAMERA_HOME + Vector2(sin(exhibit_time * 0.11) * drift, sin(exhibit_time * 0.07 + 1.0) * drift * 0.45)
	if _backdrop.reduced_motion:
		cam = CAMERA_HOME
	_camera.position = cam
	_lantern.position = cam + LANTERN_OFFSET
	_backdrop.set_camera(cam, 1.0)
	_backdrop.set_time(exhibit_time)
	_backdrop.set_lantern(CAMERA_HOME + LANTERN_OFFSET, look.lantern_radius, _lantern.light.color, _lantern.light.energy)
	if exhibit == ENTITY_EXHIBIT:
		if _sweep_on or _measure_on:
			drain = SWEEP_DRAIN
			_backdrop.set_drain(drain)
		else:
			_step_drain()
	if _sweep_on:
		_sweep_step()
	else:
		_measure_cost()


func _step_drain() -> void:
	drain = clampf((exhibit_time - DRAIN_HOLD_S) / DRAIN_RAMP_S, 0.0, 1.0)
	_backdrop.set_drain(drain)
	if drain >= FLEE_AT and not _swell_played:
		_swell_played = true
		_play(&"aether_swell")
	if drain >= SILENCE_AT and not _silenced:
		_silenced = true
		_set_ambience(&"")


## GPU ms of the world viewport plus every offscreen layer viewport (they render separately).
func _gpu_now() -> float:
	var ms := RenderingServer.viewport_get_measured_render_time_gpu(_world.get_viewport_rid())
	for rid in _backdrop.offscreen_rids():
		ms += RenderingServer.viewport_get_measured_render_time_gpu(rid)
	return ms


func _measure_cost() -> void:
	var warm := MEASURE_WARMUP if _measure_on else COST_WARMUP
	var n := MEASURE_FRAMES if _measure_on else COST_FRAMES
	if _cost_logged or _frames <= warm:
		return
	_gpu_sum += _gpu_now()
	_cpu_sum += RenderingServer.viewport_get_measured_render_time_cpu(_world.get_viewport_rid())
	if _frames >= warm + n:
		_cost_logged = true
		print("AETHER_COST exhibit=%d quality=%s gpu_ms=%.3f cpu_ms=%.3f px=%dx%d frames=%d clean=%s layers=%s" % [exhibit,
			quality_level, _gpu_sum / n, _cpu_sum / n, _world.size.x, _world.size.y, n, str(_measure_on),
			",".join(_backdrop.active_layers())])
		if _measure_on:
			get_tree().quit()


func _start_sweep(levels: Array[String]) -> void:
	_sweep_on = true
	_sweep_pairs.clear()
	for lv in levels:
		for ex in LOOKS.size():
			_sweep_pairs.append(Vector2i(AetherQuality.LEVELS.find(lv), ex))
	print("AETHER_SWEEP_START px=%dx%d levels=%s" % [_world.size.x, _world.size.y, ",".join(PackedStringArray(levels))])
	_sweep_next_pair()


func _sweep_next_pair() -> void:
	if _sweep_pairs.is_empty():
		_sweep_on = false
		_backdrop.set_only_layer_off(&"")
		print("AETHER_SWEEP_DONE")
		get_tree().quit()
		return
	var pr: Vector2i = _sweep_pairs.pop_front()
	set_quality(AetherQuality.LEVELS[pr.x])
	_show(pr.y)
	_sweep_layers = [&""]
	_sweep_li = 0
	_sweep_measure(SWEEP_FIRST_SETTLE)


func _sweep_measure(settle: int) -> void:
	var layer := _sweep_layers[_sweep_li]
	_backdrop.set_only_layer_off(layer if layer != &"glow" else &"")
	_env.environment.glow_enabled = layer != &"glow" and _backdrop.quality.glow == 1
	_sweep_wait = settle
	_sweep_n = 0
	_sweep_acc = 0.0


func _sweep_step() -> void:
	if _sweep_wait > 0:
		_sweep_wait -= 1
		return
	_sweep_acc += _gpu_now()
	_sweep_n += 1
	if _sweep_n < SWEEP_FRAMES:
		return
	var ms := _sweep_acc / float(_sweep_n)
	var layer := _sweep_layers[_sweep_li]
	# A/B/A: every layer-off sample sits between two all-on samples; the delta uses their mean,
	# which cancels slow drift from other GPU load on the machine.
	if layer == &"":
		if _sweep_li == 0:
			print("AETHER_LAYER_COST exhibit=%d quality=%s layer=all delta_gpu_ms=0.000 total_gpu_ms=%.3f" % [exhibit, quality_level, ms])
			var order: Array[StringName] = []
			for l in _backdrop.active_layers():
				order.append(StringName(l))
			if _backdrop.quality.glow == 1:
				order.append(&"glow")
			for l in order:
				_sweep_layers.append(l)
				_sweep_layers.append(&"")
		elif _sweep_off_layer != &"":
			var base := (_sweep_base + ms) * 0.5
			print("AETHER_LAYER_COST exhibit=%d quality=%s layer=%s delta_gpu_ms=%.3f total_gpu_ms=%.3f" % [exhibit, quality_level,
				_sweep_off_layer, base - _sweep_off_ms, _sweep_off_ms])
		_sweep_base = ms
		_sweep_off_layer = &""
	else:
		_sweep_off_layer = layer
		_sweep_off_ms = ms
	_sweep_li += 1
	if _sweep_li >= _sweep_layers.size():
		_sweep_next_pair()
	else:
		_sweep_measure(SWEEP_SETTLE)


func _on_leviathan_entered() -> void:
	_play(&"aether_swell")


func _on_leviathan_closest() -> void:
	_play(&"aether_wrong")
	leviathan_closest.emit()


func _play(id: StringName) -> void:
	if AudioService.has_method("play"):
		AudioService.call("play", id)


func _set_ambience(id: StringName) -> void:
	if AudioService.has_method("set_ambience"):
		AudioService.call("set_ambience", id)
