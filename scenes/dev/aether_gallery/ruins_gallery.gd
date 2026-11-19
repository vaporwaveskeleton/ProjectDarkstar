extends Node
## Dev-only Ruins look gallery (route `ruins_gallery`, dev builds only — never shipped). Shows
## RuinsLook with placeholders in four states: 0 entry (first visit: dark, then the hall lantern
## catches), 1 before any lamp (lantern lit, the hangar mouth dark), 2 one Tree lamp lit (the mouth
## lit), 3 three lamps. ui_right / ui_left cycle (each state starts fresh), ui_cancel returns to
## attract. No on-screen text.
## Dev user args, read here only:
##   --ruins-stage=N     start on state N (0–3)
##   --ruins-no-hall     hide the hall (see only the Aether outside; a debug view)
##   --ruins-measure     GPU cost of the state: MEASURE_WARMUP frames, then RUINS_COST over
##                       MEASURE_FRAMES frames, then quits
## No class_name: scenes/dev is excluded from release builds.

const LOOK_SCENE := preload("res://features/aether/ruins_look.tscn")
const STAGES := 4
const LAMP_DELAY_S := 0.5     ## ✱ seconds into a lamp state before the first lamp catches
const LAMP_STAGGER_S := 0.45  ## ✱ seconds between lamps in the three-lamp state
const LAMPS_LIT: Array[int] = [0, 0, 1, 3]
const MEASURE_WARMUP := 240   ## ✱ frames (every catch settled)
const MEASURE_FRAMES := 120   ## ✱ frames averaged
const ARG_STAGE := "--ruins-stage="
const ARG_MEASURE := "--ruins-measure"
const ARG_NO_HALL := "--ruins-no-hall"

var stage := 0
var stage_time := 0.0
var look: RuinsLook
var _lit := 0
var _measure_on := false
var _no_hall := false
var _frames := 0
var _gpu_sum := 0.0


func _ready() -> void:
	var start := 0
	for a in OS.get_cmdline_user_args():
		if a.begins_with(ARG_STAGE):
			start = clampi(a.trim_prefix(ARG_STAGE).to_int(), 0, STAGES - 1)
		elif a == ARG_NO_HALL:
			_no_hall = true
		elif a == ARG_MEASURE:
			_measure_on = true
	show_stage(start)


func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed(&"ui_right"):
		show_stage(posmod(stage + 1, STAGES))
		get_viewport().set_input_as_handled()
	elif event.is_action_pressed(&"ui_left"):
		show_stage(posmod(stage - 1, STAGES))
		get_viewport().set_input_as_handled()
	elif event.is_action_pressed(&"ui_cancel"):
		get_viewport().set_input_as_handled()
		SceneRouter.go_to(&"attract")


func show_stage(index: int) -> void:
	stage = index
	stage_time = 0.0
	_lit = 0
	_frames = 0
	_gpu_sum = 0.0
	if look != null:
		remove_child(look)
		look.queue_free()
	look = LOOK_SCENE.instantiate() as RuinsLook
	look.show_placeholders = true
	add_child(look)
	look.set_first_visit(stage == 0)
	if _no_hall:
		(look.get_node("%Hall") as CanvasLayer).visible = false
	RenderingServer.viewport_set_measure_render_time(look.view.world.get_viewport_rid(), true)
	print("RUINS_STAGE %d" % stage)


func _process(delta: float) -> void:
	stage_time += delta
	var want := LAMPS_LIT[stage]
	while _lit < want and stage_time >= LAMP_DELAY_S + LAMP_STAGGER_S * _lit:
		var at := look.placeholder_lamp_positions()
		look.light_lamp(at[_lit % at.size()])
		_lit += 1
	if _measure_on:
		_measure()


func _measure() -> void:
	_frames += 1
	if _frames <= MEASURE_WARMUP:
		return
	var ms := RenderingServer.viewport_get_measured_render_time_gpu(look.view.world.get_viewport_rid())
	for rid in look.backdrop.offscreen_rids():
		ms += RenderingServer.viewport_get_measured_render_time_gpu(rid)
	_gpu_sum += ms
	if _frames >= MEASURE_WARMUP + MEASURE_FRAMES:
		var w := look.view.world.size
		print("RUINS_COST stage=%d gpu_ms=%.3f px=%dx%d frames=%d" % [stage, _gpu_sum / MEASURE_FRAMES, w.x, w.y, MEASURE_FRAMES])
		get_tree().quit()
