class_name CabinetGame
extends Node
## Act 0 — "The Last Normal Day" as the Cabinet runs it (GDD §6.1). Owns the stage flow only:
## the stage card (BRIEFING) → READY → play → (death → respawn | game over → attract, where CONTINUE restarts this stage) →
## stage clear or entity unmade → its banner → next stage … → the last stage (a0_5) → the full
## credits (the first credits of the shift) → THE PRETENCE (WARP-001 W0-07/W0-08) → the Ruins.
## PM 2026-11-19: the shift total (every credit's score, across continues) is run-scoped and rides
## the GAME OVER → attract → CONTINUE route params, never saved; the on-screen score resets per
## credit. The profile keeps only the furthest stage reached (a relaunch may CONTINUE from it).
## Rules live in the ArcadeWorld layers; text lives in en.po; numbers live in CabinetTuning.

enum State { INTRO, PLAY, DEAD, CLEARED, UNMADE, CREDITS, REVEAL, GAME_OVER, BRIEFING }

const PAUSE_SCENE := preload("res://scenes/sector/pause_screen.tscn")
const READY_SECONDS := 2.5         ## ✱ the READY card's old length; after the stage card it is CabinetTuning.brief_ready_after_s
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
## Where THE PRETENCE goes: the first Unmaking cinematic, which then routes to the Ruins.
const UNMAKING_ROUTE := &"aether"

@export var roster: CabinetStageRoster   ## the shift, a0_1, a0_3, a0_4, a0_5 in play order (data/cabinet/stage_roster.tres; Q-T452)
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
var unmakings := 0                ## Unmakings done this shift (run-scoped, never saved); on a stage start it is derived from the stage index
var _brief_t := 0.0               ## s the stage card has been up
var _brief_froze := false         ## the card paused the world (and so must unpause it)
var _timer := 0.0
var _profile: Dictionary = {}
var demo := false
var _demo_t := 0.0
var _shift_base := 0              ## the shift total before this credit (route param on a continue, else 0)
var _shift_open := false          ## true once fresh-or-continue is decided; profile writes wait for it
## The service record (STAT_KEYS order) when this stage started, for the P3 tally card (Sizzle:
## messages.show_tally replaces the mid-shift banner): tally_lines(stage_index + 1, <now>, stage_record_start).
var stage_record_start: Array[int] = [0, 0, 0, 0]
var _end_charges := -1             ## P2 carry-over: Charges held when this stage ended (cleared/unmade); -1 = not ended
var _early_params: Dictionary = {}   ## route params that arrived before _ready (see on_route_entered)
var _has_early_params := false
## Whether the Pretence had been seen before this reveal started (read before the reveal's save sets it):
## the Unmaking that follows is skippable on the same terms as the reveal (Q-T153, TECH-001 §11.1).
var _reveal_seen_before := false
## The Unmaking's spread warm-up (Q-T344): `_warm["done"]` once drawn; `_warm_started` once begun.
var _warm: Dictionary = {}
var _warm_started := false
## The printed bezel wearing out (W0-11 Wear at stage start, then the Decay; ART-001 §12.7b). Built in _ready.
var bezel_decay: BezelDecay
var decay_tuning: CabinetDecayTuning = preload("res://data/cabinet/cabinet_decay.tres")
## Ending 5 (LOOP-001 §11.6): no Surgelight used this shift (Act 0 has no Ward Pulse). Run-scoped, like the
## shift total. Autopilot shifts (dev/QA) never count; `--clean-hands` (dev) forces it for captures.
var clean_hands := true
## The haunted costume (W0-11 hum and stage loop, W0-12 Hauntings; TECH-001 Q-T250–Q-T264). Built in _ready.
var hum: CabinetHum
var music: CabinetStageMusic
var haunts: CabinetHaunts
var haunt_screen: CabinetHauntScreen
var _demo_haunt_t := -1.0          ## s until the demo asks for its one Haunting (the figure); < 0 = none


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
	world.slowmo_changed.connect(func(s: float) -> void:
		AudioService.set_bed_pitch_scale(s)
		if music != null:
			music.set_slowmo(s))
	world.entity_line.connect(func(key: String) -> void: messages.entity_line(tr(key)))
	world.caption.connect(func(key: String) -> void: messages.caption(tr(key)))
	messages.credits_stat_shown.connect(func(_i: int) -> void: AudioService.play(&"tally_blip"))   # cue owned by AUDIO-001 (unknown id = silent no-op)
	reveal.finished.connect(_on_reveal_finished)
	bezel_decay = BezelDecay.new()
	bezel_decay.name = "BezelDecay"
	bezel_decay.hole = screen
	bezel_decay.rig = hud.get_parent() as ScreenRig
	hud.get_parent().add_child(bezel_decay)
	hud.get_parent().move_child(bezel_decay, hud.get_index() + 1)
	_build_haunting()
	world.stars.maw = reveal.maw        # S8: the star spine reads the live vertebra positions
	reveal.maw.stars = world.stars      # ... and the maw draws the arrived stars on its own layer
	autopilot.enabled = OS.get_cmdline_user_args().has("--autopilot")
	overlays.emptied.connect(func() -> void: get_tree().paused = false)
	start_stage(0)
	if _has_early_params:              # the router reached us before the tree did: apply them now, in its order
		_has_early_params = false
		on_route_entered(_early_params)
	# on_route_entered (same frame, after this) decides fresh or continue; an unrouted start
	# (F6, tests) is a fresh game once the frame ends. The demo never opens a shift.
	_open_shift.call_deferred(false)


## Routed with {"demo": true} from the attract screen: the cabinet plays itself.
## Routed with {"continue_stage": N, "shift_total": T} after GAME OVER and a new coin (PM Q-T104c):
## a new game that begins at stage N, with T as the shift total before it (0 if missing or invalid).
## SceneRouter mounts the scene first (so _ready has already started stage 0) and calls this right
## after, in the same frame; a valid N restarts here, anything else keeps stage 0 as a fresh shift.
## A host that mounts without adding the scene to the tree (the tests' FakeRouteHost) calls this
## before _ready: the params wait, and _ready applies them right after stage 0 starts, so nothing
## touches an @onready node that is not set yet.
func on_route_entered(params: Dictionary) -> void:
	if not is_node_ready():
		_early_params = params
		_has_early_params = true
		return
	demo = bool(params.get("demo", false))
	if demo:
		_demo_t = DEMO_SECONDS
		autopilot.enabled = true
		messages.demo = true
		dismiss_brief()                # the attract demo never shows the stage card
		# W0-12: the demo may show the figure once, if this cabinet has been played into the shift (Q-T253)
		if haunts != null and (int(_profile.get(KEY_STAGE_REACHED, -1)) >= haunts.tuning.attract_min_stage or bool(_profile.get("act0_complete", false))):
			haunts.enabled = true
			_demo_haunt_t = DEMO_SECONDS * 0.4
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
## is a valid index (a larger one, from a longer shift saved by the five-stage build, clamps to the last stage, F-14) and Act 0 is not complete, else -1.
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
	return mini(i, count - 1) if i >= 0 and count > 0 else -1


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


## `carried`: the Charges the Vigil brings from the previous stage of a running shift (only the
## credits → next stage hand-off passes it); -1 = a fresh start (new game, CONTINUE, capture).
## Used only when the stage has carry_charges_in (P2), capped at the magazine.
func start_stage(i: int, carried: int = -1) -> void:
	stage_index = i
	_end_charges = -1
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
	if st.carry_charges_in and carried > 0:
		world.glass.set_charges(mini(carried, world.tuning.magazine))
	AudioService.set_bed_pitch_scale(1.0)
	world.vigil.input_enabled = false
	messages.clear()
	unmakings = roster.unmakings_before(stage_index)
	if st.zone_cue != &"":
		AudioService.play(st.zone_cue)   # AUDIO-001 zone jingle; unknown id = silent no-op
	_open_brief(st)
	_apply_wear()
	_apply_haunting()
	stage_record_start = record_values()
	_write_stage_reached()


## The stage card (SYS-001 §1.7, UI-001 §11) opens at every stage start, CONTINUE included: the world does
## not tick while it is up. The demo (attract) never shows it.
func _open_brief(st: CabinetStage) -> void:
	_brief_t = 0.0
	var reopened := state == State.BRIEFING      # a restart while the card is up keeps the first card's claim on the world
	_enter(State.BRIEFING)
	if not reopened:
		_brief_froze = not world.paused_sim
	world.paused_sim = true
	messages.show_brief(brief_card(st), tuning)
	if demo:
		dismiss_brief()


## The card's content for stage `st` (pure data; CabinetMessages draws it). Rows list only units the stage has.
func brief_card(st: CabinetStage) -> Dictionary:
	var n := stage_number(st)
	var wake := st.goal == CabinetStage.Goal.UNMAKE_ENTITY
	var rows: Array[Dictionary] = []
	if st.geodes > 0:
		rows.append({"kind": CabinetBriefIcons.GEODE, "name": tr("CAB_UNIT_GEODE"), "count": st.geodes})
	if st.grubs > 0:
		rows.append({"kind": CabinetBriefIcons.GRUB, "name": tr("CAB_UNIT_GRUB"), "count": st.grubs})
	if st.acolytes + st.guard_acolytes > 0:
		rows.append({"kind": CabinetBriefIcons.ACOLYTE, "name": tr("CAB_UNIT_ACOLYTE"), "count": st.acolytes + st.guard_acolytes})
	rows.append({"kind": CabinetBriefIcons.SEPULCHRE, "name": tr("CAB_UNIT_SEPULCHRE"), "count": 1})
	var reminders := PackedStringArray([
		tr("CAB_BRIEF_A0_%d_1" % n).format({"n": world.tuning.unravel_hits}),
		tr("CAB_BRIEF_A0_%d_2" % n).format({"n": world.tuning.unravel_hits})])
	var unm := ""
	if wake:   # only waking stages count Unmakings (a0_4, a0_5 on the shift; a0_1 is cold)
		unm = tr("CAB_BRIEF_UNMAKINGS").format({"n": unmakings, "total": roster.unmakings_required()})
	return {
		"zone": "" if st.zone_key.is_empty() else tr(st.zone_key),
		"title": tr(st.title_key),
		"order": tr("CAB_BRIEF_ORDER_WAKE" if wake else "CAB_BRIEF_ORDER_COLD"),
		"reminders": reminders,
		"roster": tr("CAB_BRIEF_ROSTER"),
		"rows": rows,
		"unmakings": unm,
		"prompt": tr("CAB_BRIEF_PRESS_FIRE"),
		"blink_hz": tuning.brief_prompt_blink_hz,
		"duty": tuning.brief_prompt_duty,
	}


## The stage number the card keys (CAB_BRIEF_A0_<n>_*) and the Unmakings line use, from the stage id ("a0_3" → 3)
## so it stays the same when the roster drops a0_1 / a0_2 (F-14); falls back to the roster position.
func stage_number(st: CabinetStage) -> int:
	var parts := String(st.id).split("_")
	if parts.size() == 2 and parts[1].is_valid_int():
		return parts[1].to_int()
	var i := roster.index_of(st.id)
	return (i if i >= 0 else stage_index) + 1


## Close the card: the world wakes, then the short READY card (brief_ready_after_s), then play.
func dismiss_brief() -> void:
	if state != State.BRIEFING:
		return
	messages.hide_brief()
	if _brief_froze:
		world.paused_sim = false
	_brief_froze = false
	var st := stages[stage_index]
	var zone := "" if st.zone_key.is_empty() else tr(st.zone_key)
	messages.show_ready(tr(st.title_key), tr(st.subtitle_key), tuning.brief_ready_after_s, zone)
	_enter(State.INTRO, tuning.brief_ready_after_s)


## W0-11 Wear (PM under owner autonomy grant 2026-11-19, Q-T180 B): at a stage start only, the bezel ages
## one level per stage (the three-stage shift: wear 1, 2, 3; F-14). Costume only: never the HUD strip, the registers or anything mid-play.
func _apply_wear() -> void:
	if bezel_decay == null:
		return
	var lvl := decay_tuning.wear_level(stage_index)
	bezel_decay.bleach = decay_tuning.wear_bleach_per_level * float(lvl)
	bezel_decay.smear = 0.0
	bezel_decay.light = 0.0


## The haunted costume (TECH-001 Q-T250–Q-T259, Q-T264): the mains hum, the stage loop, and the Hauntings
## with their layer on the arcade screen and the marquee they dim. Built once, in _ready.
func _build_haunting() -> void:
	hum = CabinetHum.new()
	hum.name = "Hum"
	add_child(hum)
	music = CabinetStageMusic.new()
	music.name = "StageMusic"
	add_child(music)
	haunt_screen = CabinetHauntScreen.new()
	haunt_screen.name = "HauntScreen"
	screen.viewport.add_child(haunt_screen)
	screen.viewport.move_child(haunt_screen, world.get_index() + 1)   # over the field, under the HUD strip and the messages
	haunts = CabinetHaunts.new()
	haunts.name = "Haunts"
	haunts.hum = hum
	haunts.screen = haunt_screen
	haunts.marquee = CabinetHaunts.find_marquee(hud.get_parent())
	haunts.rig = hud.get_parent() as Control
	add_child(haunts)
	hum.start()


## W0-11 Wear and W0-12 Hauntings at a stage start: the hum beats, the stage loop is detuned, and from a0_3
## the READY card may haunt (costume only; never during play).
func _apply_haunting() -> void:
	if haunts == null:
		return
	var lvl := decay_tuning.wear_level(stage_index)
	hum.set_wear(lvl)
	music.play_stage(stages[stage_index].music, lvl)
	haunts.enabled = not demo and lvl >= haunts.tuning.min_wear_level
	haunts.moment(CabinetHauntDeck.READY)


## Clean hands so far: any Surgelight, or the autopilot flying, spoils it (dev `--clean-hands` forces it).
func _note_hands() -> void:
	if OS.is_debug_build() and OS.get_cmdline_user_args().has("--clean-hands"):
		clean_hands = true
		return
	if world.vigil.used_surgelight or autopilot.enabled:
		clean_hands = false


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
	_poll_unmaking_warmup()
	if demo:
		_demo_t -= delta
		if _demo_t <= 0.0 or state == State.GAME_OVER:
			demo = false
			SceneRouter.go_to(&"attract")
			return
	if _demo_haunt_t > 0.0:
		_demo_haunt_t -= delta
		if _demo_haunt_t <= 0.0:
			haunts.moment(CabinetHauntDeck.DEMO)
	if state == State.BRIEFING:
		_brief_t += delta
		# --autopilot and --smoke dismiss the card themselves (SYS-001 §1.7 brief.autopilot_s)
		if (autopilot.enabled or OS.get_cmdline_user_args().has("--smoke")) and _brief_t >= tuning.brief_autopilot_s:
			dismiss_brief()
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
				music.stop()
		State.GAME_OVER:
			SceneRouter.go_to(&"attract", _game_over_params())
		State.CLEARED:
			if is_last_stage():
				_hold_banner("CAB_VIGIL_COMPLETE")
			else:
				_begin_morph()
		State.UNMADE:
			if is_last_stage():
				messages.roll_credits(_full_credit_lines(), PackedInt32Array(STAT_ENTRY_INDICES))
				_enter(State.CREDITS, world.fx_tuning.credits_full_seconds)
			else:   # mid-shift unmade (a0_3, a0_4 on the four-stage shift; a0_1 is cleared, not unmade): the sky morphs, then the next stage
				_begin_morph()
		State.CREDITS:
			_note_hands()
			var next := next_stage_index()
			if next >= 0:
				start_stage(next, _end_charges if _end_charges >= 0 else world.glass.charges)
			else:
				_enter(State.REVEAL)
				_end_haunting()
				_reveal_seen_before = bool(_profile.get("pretence_seen", false))
				reveal.play(self, _reveal_seen_before, clean_hands and not demo)
				SceneRouter.prewarm(UNMAKING_ROUTE)   # Q-T243: load the Unmaking while the reveal plays


## Starts the spread warm-up once the Decay reaches D3 (mostly dark, no input needed) and the
## Unmaking has finished loading. Never blocks.
func _poll_unmaking_warmup() -> void:
	if _warm_started or state != State.REVEAL or reveal.decay == null or not reveal.decay.running:
		return
	if reveal.decay.t < reveal.decay.tuning.marks()[2] or not SceneRouter.prewarm_ready(UNMAKING_ROUTE):
		return
	_warm_started = true
	SceneWarmup.warm_spread(self, SceneRouter.table.path_for(UNMAKING_ROUTE), _warm)


## The stage hand-off's whole length: the collapse beat plus the morph (Q-T457; both in CabinetFxTuning).
func handoff_seconds() -> float:
	return world.fx_tuning.handoff_collapse_s + world.fx_tuning.handoff_morph_s


## The ordinary stage-to-stage hand-off (Q-T457, owner 2026-11-20): no banner and no roll; the stage's sky dissolves and warps
## into the next stage's signature while the last stage's sim runs on, then start_stage(next) opens the next stage card (which
## still waits for the lance button: it carries the orders). Replaces the old banner hold (MID_SHIFT_HOLD_SECONDS, 5.4 s).
func _begin_morph() -> void:
	AudioService.play(&"quota", -3.0)
	if haunts != null:
		if haunts.enabled and decay_tuning.wear_level(stage_index) == haunts.tuning.min_wear_level:
			haunts.plant_crag_slope()
		haunts.moment(CabinetHauntDeck.HOLD)
	_enter(State.CREDITS, 0.01)   # the morph already ran from the kill frame: on to the next stage


## The sky starts to break on the kill frame and runs for the whole hand-off (Q-T457): wear scales how hard it tears.
func _start_sky_morph() -> void:
	var next := next_stage_index()
	if next >= 0:
		var power := 1.0 + float(decay_tuning.wear_level(stage_index)) * world.fx_tuning.handoff_wear_gain
		world.stars.begin_morph(stages[next].backdrop, handoff_seconds(), power)


## A mid-shift stage end (PM 2026-11-19): banner only, no roll. The stage-end banner stays up for
## the old short-roll hold, then CREDITS' timer starts the next stage (same total pause as before).
## a0_5's full roll is the first credits of the shift.
func _hold_banner(key: String) -> void:
	messages.banner(tr(key), MID_SHIFT_HOLD_SECONDS)
	if haunts != null:
		if haunts.enabled and decay_tuning.wear_level(stage_index) == haunts.tuning.min_wear_level:
			haunts.plant_crag_slope()   # the early crag figure, seeded once at the end of the first wear level, a0_3 (PM 2026-11-20)
		haunts.moment(CabinetHauntDeck.HOLD)
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
	if music != null:
		music.stop()
	if state != State.PLAY:
		return
	world.vigil.input_enabled = false
	_end_charges = world.glass.charges
	if is_last_stage():
		messages.banner(tr("CAB_VIGIL_COMPLETE"), CLEAR_SECONDS)
		AudioService.play(&"quota")
		_enter(State.CLEARED, CLEAR_SECONDS)
	else:   # the ordinary hand-off (Q-T457): a caption now, a short beat, then the sky morphs into the next stage
		messages.caption(tr("CAB_SEPULCHRE_DOWN"), handoff_seconds())
		_start_sky_morph()
		_enter(State.CLEARED, handoff_seconds())


func _on_entity_unmade() -> void:
	unmakings += 1
	if music != null:
		music.stop()
	world.vigil.input_enabled = false
	_end_charges = world.glass.charges
	if is_last_stage():
		messages.banner(tr("CAB_ENTITY_DOWN"), UNMADE_SECONDS)
		_enter(State.UNMADE, UNMADE_SECONDS)
	else:
		messages.caption(tr("CAB_ENTITY_DOWN"), handoff_seconds())
		_start_sky_morph()
		_enter(State.UNMADE, handoff_seconds())


func _on_extra_life() -> void:
	AudioService.play(&"extra_life")
	messages.caption(tr("CAB_EXTRA_VIGIL"), 2.0)


func _on_reveal_finished() -> void:
	_save_act0_complete()
	# Q-T243 / Q-T344: the Unmaking's materials are drawn off-camera a few per frame from the Decay's
	# D3 on; only what is still undrawn here is waited for (or, if it never began, drawn at once).
	if not _warm_started:
		_warm_started = true
		await SceneWarmup.warm(self, SceneRouter.prewarmed(UNMAKING_ROUTE))
	while not bool(_warm.get("done", true)):
		await get_tree().process_frame
	SceneRouter.go_to(UNMAKING_ROUTE, unmaking_params())


## The reveal's boundary save: Act 0 is done, so there is nothing to continue.
func _save_act0_complete() -> void:
	_profile["act0_complete"] = true
	_profile["pretence_seen"] = true
	if reveal.ending5_shown:
		_profile["pretence_kept"] = true   # LOOP-001 §11.6 / §11.7: ending 5 seen; the Archivist variant reads it
	_profile[KEY_STAGE_REACHED] = -1
	_profile["act0_pending_vi"] = shift_total()   # Q-T141: RunSession banks it if the param is lost; the shift total (all continues) is the Act 0 Vigil Index banked (PM direction 2026-11-19, Q-T132)
	_save_hi_score()


## What the reveal hands the Ruins: the run-scoped shift total (Q-T132, not consumed yet) and, outside
## the demo, the Act 0 Vigil Index RunSession banks as Ember (TECH-001 §4.2a, Q-T141).
func _reveal_params() -> Dictionary:
	var params := {"shift_total": shift_total()}
	if not demo:
		params["act0_vigil_index"] = shift_total()
	return params


## The golden path (TECH-001 §2.1, §2.10): the reveal hands off to the first Unmaking (route &"aether",
## beats 4–6) with no curtain, and the Unmaking forwards the Ruins keys (_reveal_params) unchanged.
## Camera continuity params (aether_time_s, camera_centre, camera_zoom) are not sent yet: the reveal
## ends in the maw's full black, so the cinematic's defaults apply (Q-T161).
func unmaking_params() -> Dictionary:
	var params := _reveal_params()
	params["skip_curtain"] = true
	params["can_skip"] = _reveal_seen_before
	return params


## GAME OVER and the reveal: the hi-score (and the furthest-stage key already in _profile), merged.
func _save_hi_score() -> void:
	if demo:
		return
	if score.score > int(_profile.get("cabinet_hi_score", 0)):
		_profile["cabinet_hi_score"] = score.score
	SaveService.save_slot(&"profile", _profile, &"cabinet_score")


## Far from the entity, the Sepulchre and every Acolyte, within the Vigil's neighbourhood box.
func _safe_spawn() -> Vector2:
	var best := world.vigil.pos
	var best_score := -1.0
	for i in 12:
		var p := world.neighbourhood.random_spot(0.0)   # SYS-001 §1.7: the box round where the Vigil fell, never across the 65,536 px field
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
	if state == State.BRIEFING:
		_brief_input(event)
		return
	if event.is_action_pressed(&"pause") and not event.is_echo() and overlays.is_empty() and state != State.REVEAL:
		get_viewport().set_input_as_handled()
		_open_pause()


## The stage card's input (UI-001 §11): only a fresh fire_lance press after brief_arm_s dismisses it;
## pause and ui_cancel open the pause overlay, after which the card is still up; nothing else does anything.
func _brief_input(event: InputEvent) -> void:
	if not overlays.is_empty() or event.is_echo():
		return
	if event.is_action_pressed(&"fire_lance"):
		get_viewport().set_input_as_handled()
		if _brief_t >= tuning.brief_arm_s:
			dismiss_brief()
	elif event.is_action_pressed(&"pause") or event.is_action_pressed(&"ui_cancel"):
		get_viewport().set_input_as_handled()
		_open_pause()


func _open_pause() -> void:
	get_tree().paused = true
	var pause := PAUSE_SCENE.instantiate()
	pause.abandon_requested.connect(func() -> void:
		get_tree().paused = false
		SceneRouter.go_to(&"attract"))
	overlays.push(pause)


## THE PRETENCE begins: the Hauntings stop and the hum, the stage loop and the marquee go quiet, so the
## Decay's own failing hum and shell are the only Cabinet sound (AUDIO-001 §12.18; the Decay is not haunted).
func _end_haunting() -> void:
	if haunts != null:
		haunts.stop_all()
		haunts.enabled = false
	if hum != null:
		hum.stop()
	if music != null:
		music.stop()
