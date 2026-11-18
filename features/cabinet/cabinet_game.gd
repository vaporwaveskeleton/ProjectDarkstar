extends Node
## Act 0 — "The Last Normal Day" as the Cabinet runs it (GDD §6.1). Owns the stage flow only:
## READY → play → (death → respawn | game over) → stage clear → … → the entity unmade →
## the cabinet's credits → THE PRETENCE (WARP-001 W0-07/W0-08) → the Ruins.
## Rules live in the ArcadeWorld layers; text lives in en.po; numbers live in CabinetTuning.

enum State { INTRO, PLAY, DEAD, CLEARED, UNMADE, CREDITS, REVEAL, GAME_OVER }

const PAUSE_SCENE := preload("res://scenes/sector/pause_screen.tscn")
const READY_SECONDS := 2.5         ## ✱
const CLEAR_SECONDS := 2.5         ## ✱
const UNMADE_SECONDS := 3.0        ## ✱
const CREDITS_SECONDS := 9.0       ## ✱
const DEMO_SECONDS := 45.0         ## ✱ attract demo length (WARP-001 W0-03)
const CREDIT_KEYS := ["CAB_CREDITS_1", "CAB_CREDITS_2", "CAB_CREDITS_3", "CAB_CREDITS_4",
	"CAB_CREDITS_5", "CAB_CREDITS_6", "CAB_CREDITS_7"]

@export var stages: Array[CabinetStage] = []
@export var tuning: CabinetTuning

@onready var world: ArcadeWorld = %World
@onready var hud: CabinetHud = %Hud
@onready var messages: CabinetMessages = %Messages
@onready var screen: ArcadeScreen = %ArcadeScreen
@onready var reveal: PretenceReveal = %Reveal
@onready var overlays: ScreenStack = %Overlays
@onready var autopilot: CabinetAutopilot = %Autopilot

var score: ScoreKeeper
var state: int = State.INTRO
var stage_index := 0
var _timer := 0.0
var _profile: Dictionary = {}
var demo := false
var _demo_t := 0.0


func _ready() -> void:
	Look.t = 0.0                       # Act 0 is the neon cabinet (ART-001 §15)
	score = ScoreKeeper.new(tuning)
	score.score_changed.connect(func(s: int) -> void: hud.score = s)
	score.lives_changed.connect(func(l: int) -> void: hud.lives = l)
	score.extra_life_awarded.connect(_on_extra_life)
	hud.world = world
	hud.lives = score.lives
	hud.magazine = tuning.magazine
	var loaded := SaveService.load_slot(&"profile")
	if loaded.ok:
		_profile = loaded.payload
	hud.hi_score = int(_profile.get("cabinet_hi_score", 0))
	world.score_awarded.connect(func(p: int, _at: Vector2) -> void: score.add(p))
	world.charges_changed.connect(func(n: int) -> void: hud.charges = n)
	world.vigil_destroyed.connect(_on_vigil_destroyed)
	world.sepulchre_cleared.connect(_on_sepulchre_cleared)
	world.entity_unmade.connect(_on_entity_unmade)
	world.entity_line.connect(func(key: String) -> void: messages.entity_line(tr(key)))
	world.caption.connect(func(key: String) -> void: messages.caption(tr(key)))
	reveal.finished.connect(_on_reveal_finished)
	autopilot.enabled = OS.get_cmdline_user_args().has("--autopilot")
	overlays.emptied.connect(func() -> void: get_tree().paused = false)
	start_stage(0)


## Routed with {"demo": true} from the attract screen: the cabinet plays itself.
func on_route_entered(params: Dictionary) -> void:
	demo = bool(params.get("demo", false))
	if demo:
		_demo_t = DEMO_SECONDS
		autopilot.enabled = true
		messages.demo = true
		hud.demo = true


func _exit_tree() -> void:
	get_tree().paused = false
	AudioService.stop_all()


func start_stage(i: int) -> void:
	stage_index = i
	var st := stages[i]
	var forced := _forced_stage()
	if forced >= 0 and i == 0:
		i = forced
		stage_index = i
		st = stages[i]
	var hits := _arg_int("--hits=")
	if hits > 0 and world.tuning.unravel_hits != hits:
		world.tuning = world.tuning.duplicate() as CabinetTuning
		world.tuning.unravel_hits = hits
	var seg := _arg_int("--segments=")
	if seg >= 0:
		st = st.duplicate() as CabinetStage
		st.sepulchre_start_segments = seg
	world.start(st)
	world.vigil.input_enabled = false
	messages.clear()
	messages.show_ready(tr(st.title_key), tr(st.subtitle_key), READY_SECONDS)
	_enter(State.INTRO, READY_SECONDS)


## `-- --stage=N` starts at stage N (captures and tests only).
func _forced_stage() -> int:
	var n := _arg_int("--stage=")
	return clampi(n, 0, stages.size() - 1) if n >= 0 else -1


## Capture/test switches (`-- --stage=N`, `-- --segments=N`): -1 when absent.
static func _arg_int(prefix: String) -> int:
	for a in OS.get_cmdline_user_args():
		if a.begins_with(prefix):
			return int(a.trim_prefix(prefix))
	return -1


func _enter(s: int, seconds: float = 0.0) -> void:
	state = s
	_timer = seconds


func _process(delta: float) -> void:
	RenderingServer.set_default_clear_color(Look.c(Pal.VOID_0))   # arcade black at T0 (the vacuum is the lie, ART-001 §16)
	var mat := screen.crt_material()
	if mat:
		mat.set_shader_parameter(&"time_s", world.time)
	if demo:
		_demo_t -= delta
		if _demo_t <= 0.0 or state == State.GAME_OVER:
			demo = false
			SceneRouter.go_to(&"attract")
			return
	if _timer > 0.0:
		_timer -= delta
		if _timer <= 0.0:
			_on_timer()


func _on_timer() -> void:
	match state:
		State.INTRO:
			world.vigil.input_enabled = true
			_enter(State.PLAY)
		State.DEAD:
			if score.lose_life():
				world.vigil.respawn(_safe_spawn())
				_enter(State.PLAY)
			else:
				messages.banner(tr("CAB_GAME_OVER"), 3.5)
				_save_hi_score()
				_enter(State.GAME_OVER, 3.5)
		State.GAME_OVER:
			SceneRouter.go_to(&"attract")
		State.CLEARED:
			messages.roll_credits(_credit_lines(3))
			_enter(State.CREDITS, CREDITS_SECONDS * 0.6)
		State.UNMADE:
			messages.roll_credits(_credit_lines(CREDIT_KEYS.size()))
			_enter(State.CREDITS, CREDITS_SECONDS)
		State.CREDITS:
			if stage_index + 1 < stages.size() and world.ritual.phase != SepulchreRitual.Phase.UNMADE:
				start_stage(stage_index + 1)
			else:
				_enter(State.REVEAL)
				reveal.play(self, bool(_profile.get("pretence_seen", false)))


func _credit_lines(n: int) -> PackedStringArray:
	var out := PackedStringArray()
	for i in n:
		out.append(tr(CREDIT_KEYS[i]))
	return out


func _on_vigil_destroyed() -> void:
	if state != State.PLAY:
		return
	_enter(State.DEAD, tuning.respawn_delay)


func _on_sepulchre_cleared() -> void:
	if state != State.PLAY:
		return
	world.vigil.input_enabled = false
	messages.banner(tr("CAB_VIGIL_COMPLETE"), CLEAR_SECONDS)
	AudioService.play(&"quota")
	_enter(State.CLEARED, CLEAR_SECONDS)


func _on_entity_unmade() -> void:
	world.vigil.input_enabled = false
	messages.banner(tr("CAB_ENTITY_DOWN"), UNMADE_SECONDS)
	_enter(State.UNMADE, UNMADE_SECONDS)


func _on_extra_life() -> void:
	AudioService.play(&"extra_life")
	messages.caption(tr("CAB_EXTRA_VIGIL"), 2.0)


func _on_reveal_finished() -> void:
	_profile["act0_complete"] = true
	_profile["pretence_seen"] = true
	_save_hi_score()
	SceneRouter.go_to(&"ruins")


func _save_hi_score() -> void:
	if demo:
		return
	if score.score > int(_profile.get("cabinet_hi_score", 0)):
		_profile["cabinet_hi_score"] = score.score
	SaveService.save_slot(&"profile", _profile, &"cabinet_score")


## Far from the entity, the Sepulchre and every Acolyte.
func _safe_spawn() -> Vector2:
	var best := world.vigil.pos
	var best_score := -1.0
	for i in 12:
		var p := world.random_point()
		var d := world.torus.distance(p, world.ritual.entity_pos if world.ritual.awake else world.ritual.pos)
		for a in world.acolytes.items:
			d = minf(d, world.torus.distance(p, a.pos) * 1.5)
		if d > best_score:
			best_score = d
			best = p
	return best


func _unhandled_input(event: InputEvent) -> void:
	if demo:
		if (event is InputEventKey or event is InputEventJoypadButton or event is InputEventMouseButton) and event.is_pressed():
			get_viewport().set_input_as_handled()
			demo = false
			SceneRouter.go_to(&"attract")
		return
	if event.is_action_pressed(&"pause") and not event.is_echo() and overlays.is_empty() and state != State.REVEAL:
		get_viewport().set_input_as_handled()
		get_tree().paused = true
		var pause := PAUSE_SCENE.instantiate()
		pause.abandon_requested.connect(func() -> void:
			get_tree().paused = false
			SceneRouter.go_to(&"attract"))
		overlays.push(pause)
