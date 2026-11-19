class_name CabinetGame
extends Node
## Act 0 — "The Last Normal Day" as the Cabinet runs it (GDD §6.1). Owns the stage flow only:
## READY → play → (death → respawn | game over → attract, where CONTINUE restarts this stage) →
## stage clear or entity unmade → its banner → next stage … → the last stage (a0_5) → the full
## credits (the first credits of the shift) → THE PRETENCE (WARP-001 W0-07/W0-08) → the Ruins.
## PM 2026-11-19: the shift total (every credit's score, across continues) is run-scoped and rides
## the GAME OVER → attract → CONTINUE route params, never saved; the on-screen score resets per
## credit. The profile keeps only the furthest stage reached (a relaunch may CONTINUE from it).
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

## S7 service record: shown after CAB_CREDITS_3, one honest count per line (WORDING PROPOSED, NARR-001).
const STAT_KEYS := ["CAB_CREDITS_STAT_GRUBS", "CAB_CREDITS_STAT_MINED", "CAB_CREDITS_STAT_CHARGES", "CAB_CREDITS_STAT_CARRIED"]
const STAT_AFTER := 3             ## stat lines follow the first 3 credit lines
const STAT_ENTRY_INDICES := [3, 4, 5, 6]   ## their positions in the full roll
const TALLY_STAT_INDICES := [1, 2, 3, 4]   ## their positions in tally_lines() (after the title)
const MID_SHIFT_HOLD_SECONDS := CREDITS_SECONDS * 0.6   ## ✱ the banner stays this much longer after a mid-shift end

## Profile key (ids and numbers only, TECH-001 §7): furthest stage index this shift; -1 = nothing to continue.
const KEY_STAGE_REACHED := "act0_stage_reached"

@export var roster: CabinetStageRoster   ## the shift, a0_1 … a0_5 in play order (data/cabinet/stage_roster.tres)
@export var tuning: CabinetTuning

## Read-only view of `roster.stages` (the automation probe and tests read `stages`).
var stages: Array[CabinetStage]:
	get:
		if roster == null:
			var none: Array[CabinetStage] = []
			return none
		return roster.stages

@onready var world: ArcadeWorld = %World
@onready var hud: CabinetHud = %Hud
@onready var messages: CabinetMessages = %Messages
@onready var screen: ArcadeScreen = %ArcadeScreen
@onready var reveal: PretenceReveal = %Reveal
@onready var overlays: ScreenStack = %Overlays
@onready var autopilot: CabinetAutopilot = %Autopilot

var score: ScoreKeeper
var record := ServiceRecord.new()   ## S7 run-wide counts: lives as long as `score`, NOT reset between stages
var state: int = State.INTRO
var stage_index := 0
var _timer := 0.0
var _profile: Dictionary = {}
var demo := false
var _demo_t := 0.0
var _shift_base := 0              ## the shift total before this credit (route param on a continue, else 0)
var _shift_open := false          ## true once fresh-or-continue is decided; profile writes wait for it
## The service record (STAT_KEYS order) when this stage started, for the P3 tally card (Sizzle:
## messages.show_tally replaces the mid-shift banner): tally_lines(stage_index + 1, <now>, stage_record_start).
var stage_record_start: Array[int] = [0, 0, 0, 0]


func _ready() -> void:
	Look.t = 0.0                       # Act 0 is the neon cabinet (ART-001 §15)
	score = ScoreKeeper.new(tuning)
	world.record = record
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
	world.slowmo_changed.connect(func(s: float) -> void: AudioService.set_bed_pitch_scale(s))
	world.entity_line.connect(func(key: String) -> void: messages.entity_line(tr(key)))
	world.caption.connect(func(key: String) -> void: messages.caption(tr(key)))
	messages.credits_stat_shown.connect(func(_i: int) -> void: AudioService.play(&"tally_blip"))   # cue owned by AUDIO-001 (unknown id = silent no-op)
	reveal.finished.connect(_on_reveal_finished)
	world.stars.maw = reveal.maw        # S8: the star spine reads the live vertebra positions
	reveal.maw.stars = world.stars      # ... and the maw draws the arrived stars on its own layer
	autopilot.enabled = OS.get_cmdline_user_args().has("--autopilot")
	overlays.emptied.connect(func() -> void: get_tree().paused = false)
	start_stage(0)
	# on_route_entered (same frame, after this) decides fresh or continue; an unrouted start
	# (F6, tests) is a fresh game once the frame ends. The demo never opens a shift.
	_open_shift.call_deferred(false)


## Routed with {"demo": true} from the attract screen: the cabinet plays itself.
## Routed with {"continue_stage": N, "shift_total": T} after GAME OVER and a new coin (PM Q-T104c):
## a new game that begins at stage N, with T as the shift total before it (0 if missing or invalid).
## SceneRouter mounts the scene first (so _ready has already started stage 0) and calls this right
## after, in the same frame; a valid N restarts here, anything else keeps stage 0 as a fresh shift.
func on_route_entered(params: Dictionary) -> void:
	demo = bool(params.get("demo", false))
	if demo:
		_demo_t = DEMO_SECONDS
		autopilot.enabled = true
		messages.demo = true
		return
	var cont := continue_stage_of(params, stages.size())
	if cont >= 0:
		_open_shift(true, shift_total_of(params))
		new_game(cont)
		AudioService.play(&"continue_taken")   # AUDIO-001 cue (unknown id = silent no-op)
	else:
		_open_shift(false)


## Decide this credit's shift once (PM 2026-11-19). Fresh (New Vigil, boot): base 0, the saved
## furthest stage starts over, then the stage-start write for the stage already on screen.
## Continue: base = the shift total the route carried; the caller's new_game() makes the
## stage-start write. Never in the demo.
func _open_shift(continued: bool, base: int = 0) -> void:
	if _shift_open or demo:
		return
	_shift_open = true
	_shift_base = base if continued else 0
	if continued:
		return
	_profile[KEY_STAGE_REACHED] = -1
	_write_stage_reached()


## The whole shift's score so far: every earlier credit (route-carried) plus this credit's score.
func shift_total() -> int:
	return _shift_base + score.score


## The shift total a route param carries: a non-negative int (or float), else 0.
static func shift_total_of(params: Dictionary) -> int:
	for key: Variant in ["shift_total", &"shift_total"]:
		if not params.has(key):
			continue
		var v: Variant = params[key]
		if typeof(v) != TYPE_INT and typeof(v) != TYPE_FLOAT:
			return 0
		return maxi(0, int(v))
	return 0


## The stage a relaunch may CONTINUE from (attract asks on a fresh boot): `act0_stage_reached` when it
## is a valid index 0..count-1 and Act 0 is not complete, else -1.
static func saved_continue_stage(profile: Dictionary, count: int) -> int:
	var done: Variant = profile.get("act0_complete", false)
	if typeof(done) == TYPE_BOOL and bool(done):
		return -1
	if not profile.has(KEY_STAGE_REACHED):
		return -1
	var v: Variant = profile[KEY_STAGE_REACHED]
	if typeof(v) != TYPE_INT and typeof(v) != TYPE_FLOAT:
		return -1
	var i := int(v)
	return i if i >= 0 and i < count else -1


## The stage a `continue_stage` route param asks for: an int (or float) inside 0..count-1, else -1.
static func continue_stage_of(params: Dictionary, count: int) -> int:
	for key: Variant in ["continue_stage", &"continue_stage"]:
		if not params.has(key):
			continue
		var v: Variant = params[key]
		if typeof(v) != TYPE_INT and typeof(v) != TYPE_FLOAT:
			return -1
		var i := int(v)
		return i if i >= 0 and i < count else -1
	return -1


## A fresh game (score 0, starting lives, empty service record) that begins at stage `i`.
func new_game(i: int) -> void:
	score.reset()
	record.reset()
	start_stage(i)


## True on the shift's last stage: its end rolls the full credits and opens THE PRETENCE.
func is_last_stage() -> bool:
	return stage_index >= stages.size() - 1


## The stage that follows this one's credits (cleared or unmade alike), or -1: THE PRETENCE follows.
func next_stage_index() -> int:
	return -1 if is_last_stage() else stage_index + 1


## The attract CONTINUE page's line for stage index `i` (shown 1-based). Attract draws it.
static func continue_line(i: int) -> String:
	return TranslationServer.translate("CAB_CONTINUE").format({"stage": i + 1})


## What GAME OVER hands the attract screen: the stage a CONTINUE restarts and the shift total so far
## (attract passes both back on CONTINUE). The demo hands nothing.
func _game_over_params() -> Dictionary:
	if demo:
		return {}
	return {"continue_stage": stage_index, "shift_total": shift_total()}


func _exit_tree() -> void:
	get_tree().paused = false
	AudioService.set_bed_pitch_scale(1.0)
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
	AudioService.set_bed_pitch_scale(1.0)
	world.vigil.input_enabled = false
	messages.clear()
	var zone := "" if st.zone_key.is_empty() else tr(st.zone_key)
	messages.show_ready(tr(st.title_key), tr(st.subtitle_key), READY_SECONDS, zone)
	if st.zone_cue != &"":
		AudioService.play(st.zone_cue)   # AUDIO-001 zone jingle (≤ READY_SECONDS); unknown id = silent no-op
	_enter(State.INTRO, READY_SECONDS)
	stage_record_start = record_values()
	_write_stage_reached()


## Stage start is a boundary (before play): save the furthest stage reached this shift.
## Only once the shift is open (route decided), never in the demo.
func _write_stage_reached() -> void:
	if demo or not _shift_open:
		return
	_profile[KEY_STAGE_REACHED] = maxi(int(_profile.get(KEY_STAGE_REACHED, -1)), stage_index)
	SaveService.save_slot(&"profile", _profile, &"cabinet_stage")


## The service record's four counts, in STAT_KEYS order.
func record_values() -> Array[int]:
	var vals: Array[int] = [record.grubs_destroyed, record.glass_mined, record.charges_thrown, record.glass_carried]
	return vals


## Pure: the stage tally (PM 2026-11-19; content for Sizzle's P3 tally card) for 1-based stage `n`:
## a CAB_TALLY_TITLE line, then the four stat lines for that stage only (`now` minus `at_start`,
## STAT_KEYS order). The stat lines sit at TALLY_STAT_INDICES.
static func tally_lines(n: int, now: Array[int], at_start: Array[int]) -> PackedStringArray:
	var out := PackedStringArray()
	out.append(TranslationServer.translate("CAB_TALLY_TITLE").format({"n": n}))
	for k in STAT_KEYS.size():
		out.append(TranslationServer.translate(STAT_KEYS[k]) % (now[k] - at_start[k]))
	return out


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
		mat.set_shader_parameter(&"time_s", world.shader_time)
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
				world.fx.clear_death_marks()
				world.vigil.respawn(_safe_spawn())
				_enter(State.PLAY)
			else:
				messages.banner(tr("CAB_GAME_OVER"), 3.5)
				_save_hi_score()
				_enter(State.GAME_OVER, 3.5)
		State.GAME_OVER:
			SceneRouter.go_to(&"attract", _game_over_params())
		State.CLEARED:
			_hold_banner("CAB_VIGIL_COMPLETE")
		State.UNMADE:
			if is_last_stage():
				messages.roll_credits(_full_credit_lines(), PackedInt32Array(STAT_ENTRY_INDICES))
				_enter(State.CREDITS, world.fx_tuning.credits_full_seconds)
			else:   # mid-shift unmade (a0_3, a0_4): the banner holds, then the next stage
				_hold_banner("CAB_ENTITY_DOWN")
		State.CREDITS:
			var next := next_stage_index()
			if next >= 0:
				start_stage(next)
			else:
				_enter(State.REVEAL)
				reveal.play(self, bool(_profile.get("pretence_seen", false)))


## A mid-shift stage end (PM 2026-11-19): banner only, no roll. The stage-end banner stays up for
## the old short-roll hold, then CREDITS' timer starts the next stage (same total pause as before).
## a0_5's full roll is the first credits of the shift.
func _hold_banner(key: String) -> void:
	messages.banner(tr(key), MID_SHIFT_HOLD_SECONDS)
	_enter(State.CREDITS, MID_SHIFT_HOLD_SECONDS)


## The full roll after the last stage: the 7 propaganda lines with the true service record after "YOUR QUOTA IS MET".
func _full_credit_lines() -> PackedStringArray:
	var out := PackedStringArray()
	var vals := record_values()
	for i in CREDIT_KEYS.size():
		if i == STAT_AFTER:
			for k in STAT_KEYS.size():
				out.append(tr(STAT_KEYS[k]) % vals[k])
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
	_save_act0_complete()
	SceneRouter.go_to(&"ruins", _reveal_params())


## The reveal's boundary save: Act 0 is done, so there is nothing to continue.
func _save_act0_complete() -> void:
	_profile["act0_complete"] = true
	_profile["pretence_seen"] = true
	_profile[KEY_STAGE_REACHED] = -1
	_save_hi_score()


## What the reveal hands the Ruins: the run-scoped shift total (Ember is banked from it later; not built).
func _reveal_params() -> Dictionary:
	return {"shift_total": shift_total()}


## GAME OVER and the reveal: the hi-score (and the furthest-stage key already in _profile), merged.
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
