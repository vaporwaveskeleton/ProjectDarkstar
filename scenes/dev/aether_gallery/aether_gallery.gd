extends Node
## Dev-only Aether gallery (route `aether_gallery`, dev builds only — never in the shipped route
## table). Shows the post-Pretence world tier by tier: 0 T1 Pale Marches, 1 T2 Green Rot,
## 2 T3 Drowned Observatory, 3 T4 Litany, 4 T5 The Black, 5 the entity's presence (T3 look,
## drain 0 → 1). ui_right / ui_left cycle, ui_cancel returns to attract. No on-screen text.
## The world renders in an HDR SubViewport at native window resolution with its own glow.
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
const FLEE_AT := 0.15          ## ✱ drain at which life starts to flee (one swell)
const SILENCE_AT := 0.5        ## ✱ drain past which the bed goes to silence
const FADE_IN_S := 1.6         ## ✱ every exhibit fades in from VOID_0: zero startle
const COST_WARMUP := 90        ## ✱ frames before the cost window
const COST_FRAMES := 60        ## ✱ frames averaged per exhibit
const CAMERA_HOME := Vector2(320.0, 180.0)
const LANTERN_OFFSET := Vector2(0.0, 22.0)   ## ✱ lantern below frame centre

var exhibit := 0
var exhibit_time := 0.0
var drain := 0.0
var _frames := 0
var _gpu_sum := 0.0
var _cpu_sum := 0.0
var _cost_logged := false
var _swell_played := false
var _silenced := false
var _looks: Array[AetherLook] = []

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
	_show(0)


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
	elif event.is_action_pressed(&"ui_cancel"):
		get_viewport().set_input_as_handled()
		SceneRouter.go_to(&"attract")


func show_exhibit(index: int) -> void:
	_show(posmod(index, LOOKS.size()))


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
	_veil.color.a = 1.0 - smoothstep(0.0, FADE_IN_S, exhibit_time)
	var drift := look.camera_drift_px
	var cam := CAMERA_HOME + Vector2(sin(exhibit_time * 0.11) * drift, sin(exhibit_time * 0.07 + 1.0) * drift * 0.45)
	if _backdrop.reduced_motion:
		cam = CAMERA_HOME
	_camera.position = cam
	_lantern.position = cam + LANTERN_OFFSET
	_backdrop.set_camera(cam, 1.0)
	_backdrop.set_time(exhibit_time)
	_backdrop.set_lantern(CAMERA_HOME + LANTERN_OFFSET, look.lantern_radius)
	if exhibit == ENTITY_EXHIBIT:
		_step_drain()
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


func _measure_cost() -> void:
	if _cost_logged or _frames <= COST_WARMUP:
		return
	var rid := _world.get_viewport_rid()
	_gpu_sum += RenderingServer.viewport_get_measured_render_time_gpu(rid)
	_cpu_sum += RenderingServer.viewport_get_measured_render_time_cpu(rid)
	if _frames >= COST_WARMUP + COST_FRAMES:
		_cost_logged = true
		print("AETHER_COST exhibit=%d gpu_ms=%.3f cpu_ms=%.3f layers=%s" % [exhibit, _gpu_sum / COST_FRAMES,
			_cpu_sum / COST_FRAMES, ",".join(_backdrop.active_layers())])


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
