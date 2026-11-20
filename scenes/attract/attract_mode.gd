extends Screen
## Attract mode — the cabinet's title screen (GDD §10; WARP-001 W0-01/W0-03; owner request 2026-11-18,
## TECH-001 §11.2). On a cold launch the Cabinet powers on and self-tests first (PowerOnTest). The screen
## (backdrop, marquee, instruction cards, power-on) is drawn into the arcade screen's own SubViewport, like
## the game's (Q-T80). The menu is physical (Q-T34): NEW VIGIL, SETTINGS and QUIT are pushbuttons on the
## control panel under the screen (ArcadeButton), and the coin door (CoinSlot) is on the bezel; all four are
## one focus domain. New Vigil stays dark until a credit is in. Emits intent only: routing goes through
## SceneRouter, settings through the local ScreenStack. Left alone with no credit for DEMO_IDLE seconds it
## plays its own demo.

const SETTINGS_SCENE := preload("res://scenes/settings/settings_screen.tscn")
const DEMO_IDLE := 30.0          ## s — WARP-001 W0-03 "30 s idle on the title screen"

@onready var _new_vigil: ArcadeButton = %NewVigil
@onready var _settings: ArcadeButton = %Settings
@onready var _power_switch: PowerRocker = %Power
@onready var _arcade: ArcadeScreen = %ArcadeScreen
@onready var _overlays: ScreenStack = %Overlays
@onready var _omen: Label = %Omen
@onready var _logo: AttractLogo = %Logo
@onready var _pages: AttractPages = %Pages
@onready var _strip: CabinetScreenHud = %StripHud
@onready var _coin: CoinSlot = %CoinSlot
@onready var _power: PowerOnTest = %PowerOn
@onready var _tracker: InputModeTracker = %InputModeTracker

var idle := 0.0
var demo_enabled := true         ## tests turn this off
var continue_stage := -1         ## CONTINUE offer from GAME OVER (Q-T104): 0-based stage, -1 = none; lasts until the demo
var shift_total := -1           ## the shift's cumulative score handed back with the CONTINUE offer (never saved); -1 = none received
var quit_action: Callable = Callable()   ## what POWER does after the collapse; tests inject a stub (default: quit the engine)
var _powering_off := false
var _profile: Dictionary = {}
var hum: CabinetHum                ## the mains hum (AUDIO-001 §2.1)
var haunts: CabinetHaunts          ## W0-12 Hauntings (TECH-001 Q-T250)


func _ready() -> void:
	Look.t = 0.0                       # the title is part of the neon cabinet (ART-001 §15)
	cancel_closes = false
	_new_vigil.pressed.connect(_on_new_vigil)
	_settings.pressed.connect(open_settings)
	_power_switch.pressed.connect(_on_power_pressed)
	var profile := SaveService.load_slot(&"profile")
	_profile = profile.payload if profile.ok else {}
	_omen.visible = bool(_profile.get("act0_complete", false))
	_strip.hi_score = int(_profile.get("cabinet_hi_score", 0))
	if bool(_profile.get("cabinet_tape_peeled", false)):
		_coin.set_peeled()
	_coin.tape_peeled.connect(_on_tape_peeled)
	_coin.credit_inserted.connect(_on_credit_inserted)
	_tracker.input_mode_changed.connect(_on_input_mode_changed)
	_power.finished.connect(_on_power_on_finished)
	_new_vigil.blinks = true           # the start lamp flashes once a credit is in (steady with photosensitivity)
	_set_new_vigil_ready(false)
	default_focus = _coin
	_wire_focus()
	_pages.continue_stage = continue_stage
	_coin.hint_armed = true
	_build_haunting()
	super()


## The haunted attract (TECH-001 Q-T250–Q-T258): the mains hum is always there; once this cabinet has been
## played to a0_3 (or finished), each turn of the page loop and each coin may haunt, rarely (CabinetHaunts).
func _build_haunting() -> void:
	hum = CabinetHum.new()
	hum.name = "Hum"
	add_child(hum)
	var hs := CabinetHauntScreen.new()
	hs.name = "HauntScreen"
	_arcade.viewport.add_child(hs)
	haunts = CabinetHaunts.new()
	haunts.name = "Haunts"
	haunts.hum = hum
	haunts.screen = hs
	haunts.pages = _pages
	haunts.ghost_button = _settings
	var rig := _coin.get_parent() as Control
	haunts.rig = rig
	haunts.marquee = CabinetHaunts.find_marquee(rig)
	add_child(haunts)
	haunts.enabled = haunting_unlocked(_profile, haunts.tuning)
	_pages.hi_score = int(_profile.get("cabinet_hi_score", 0))
	_pages.cycle_wrapped.connect(func() -> void: haunts.moment(CabinetHauntDeck.ATTRACT))
	_coin.credit_inserted.connect(func() -> void: haunts.moment(CabinetHauntDeck.COIN))
	hum.start()
	if OS.is_debug_build() and OS.get_cmdline_user_args().has("--haunt-showcase"):
		_start_showcase.call_deferred()


## True once the profile has reached `attract_min_stage` (a0_3) or finished Act 0: before that the
## attract is clean (W0-12 starts where W0-11 Wear starts).
static func haunting_unlocked(profile: Dictionary, t: CabinetHauntTuning) -> bool:
	var done: Variant = profile.get("act0_complete", false)
	if typeof(done) == TYPE_BOOL and bool(done):
		return true
	var v: Variant = profile.get(CabinetGame.KEY_STAGE_REACHED, -1)
	if typeof(v) != TYPE_INT and typeof(v) != TYPE_FLOAT:
		return false
	return int(v) >= t.attract_min_stage


## Boot routes the first attract of a launch with {"power_on": true}.
## A `continue_stage` param (GAME OVER) wins; on the launch's first attract (`power_on`) without one, the saved
## stage offers CONTINUE across a relaunch (Arcade layer contract, `CabinetGame.saved_continue_stage`), with no
## shift total (the cabinet then starts the shift total at 0).
func on_route_entered(params: Dictionary) -> void:
	continue_stage = int(params.get("continue_stage", -1))
	shift_total = int(params["shift_total"]) if params.has("shift_total") else -1
	if not params.has("continue_stage") and bool(params.get("power_on", false)):
		continue_stage = CabinetGame.saved_continue_stage(_saved_profile(), CabinetStageRoster.default_size())
		shift_total = -1
	if is_node_ready():
		_pages.continue_stage = continue_stage
	if bool(params.get("power_on", false)):
		power_on()


## The profile payload: the one `_ready` loaded, or a fresh read when the route arrives first.
func _saved_profile() -> Dictionary:
	if is_node_ready():
		return _profile
	var profile := SaveService.load_slot(&"profile")
	return profile.payload if profile.ok else {}


func power_on() -> void:
	_coin.hint_armed = false
	_power.start()


func _on_power_on_finished() -> void:
	_pages.reset()
	_coin.hint_armed = true
	idle = 0.0
	focus_entered_screen()


func _process(delta: float) -> void:
	_strip.credit_line = tr("CAB_CREDIT_COUNT") % (1 if _coin.has_credit() else 0)
	_strip.credit_color = Look.c(Pal.GAS_4) if _coin.has_credit() else Look.c(Pal.BONE_2)
	if not demo_enabled or _powering_off or not _overlays.is_empty() or SceneRouter.is_busy or _power.running or _coin.is_busy():
		idle = 0.0
		return
	idle += delta
	if idle >= DEMO_IDLE:
		idle = 0.0
		clear_continue_offer()          # the offer ends where the attract cycle reaches its demo
		SceneRouter.go_to(&"cabinet", {"demo": true})


func _input(event: InputEvent) -> void:
	# The power-on test lives inside the arcade screen's viewport, which the bezel's controls never see: while it
	# runs, any key, button or click skips it and is consumed here, before the coin door or a pushbutton can act on it.
	if _power.running and _power.handle_input(event):
		get_viewport().set_input_as_handled()
		return
	if event is InputEventKey or event is InputEventMouseButton or event is InputEventJoypadButton \
			or (event is InputEventMouseMotion and (event as InputEventMouseMotion).relative.length() > 0.0):
		idle = 0.0


func _on_input_mode_changed(mode: InputModeTracker.Mode) -> void:
	var pad := mode == InputModeTracker.Mode.GAMEPAD
	_coin.gamepad = pad
	_pages.gamepad = pad


func _on_tape_peeled() -> void:
	# The tape stays off for good: a profile fact, written outside any run (TECH-001 §7).
	_profile["cabinet_tape_peeled"] = true
	SaveService.save_slot(&"profile", _profile, &"cabinet_tape")


func _on_credit_inserted() -> void:
	_set_new_vigil_ready(true)
	_wire_focus()
	default_focus = _new_vigil
	_new_vigil.grab_focus()


## New Vigil keeps its place on the panel; without a credit its lamp is dark, it is disabled and skipped by focus.
func _set_new_vigil_ready(armed: bool) -> void:
	_new_vigil.disabled = not armed
	_new_vigil.lamp_on = armed
	_new_vigil.focus_mode = Control.FOCUS_ALL if armed else Control.FOCUS_NONE
	_logo.has_credit = armed


## One focus domain: the pushbuttons on the control panel and the coin door.
## Up/down loop [START] → SERVICE → POWER → coin door → wrap; left/right walk the row of pushbuttons
## (as they sit on the panel) and leave it for the coin door, which is to the right of the panel.
func _wire_focus() -> void:
	var row: Array[Control] = []
	if _new_vigil.focus_mode != Control.FOCUS_NONE:
		row.append(_new_vigil)
	row.append_array([_settings, _power_switch])
	var order: Array[Control] = row.duplicate()
	order.append(_coin)
	for i in order.size():
		var c := order[i]
		var prev := order[(i - 1 + order.size()) % order.size()]
		var next := order[(i + 1) % order.size()]
		c.focus_neighbor_top = c.get_path_to(prev)
		c.focus_neighbor_bottom = c.get_path_to(next)
		c.focus_previous = c.get_path_to(prev)
		c.focus_next = c.get_path_to(next)
	for i in row.size():
		var c := row[i]
		c.focus_neighbor_left = c.get_path_to(row[i - 1] if i > 0 else _coin)
		c.focus_neighbor_right = c.get_path_to(row[i + 1] if i < row.size() - 1 else _coin)
	_coin.focus_neighbor_left = _coin.get_path_to(row.back())
	_coin.focus_neighbor_right = _coin.get_path_to(row[0])


func _on_new_vigil() -> void:
	# Busy state: lock the menu so repeated input cannot queue a second run.
	if SceneRouter.is_busy or not _coin.has_credit():
		return
	set_buttons_disabled(true)
	var params: Dictionary = {}
	if continue_stage >= 0:
		params["continue_stage"] = continue_stage
		if shift_total >= 0:
			params["shift_total"] = shift_total
	if SceneRouter.go_to(&"cabinet", params):
		_coin.spend()
	else:
		set_buttons_disabled(false)


func clear_continue_offer() -> void:
	continue_stage = -1
	shift_total = -1
	if is_node_ready():
		_pages.continue_stage = -1


func open_settings() -> Screen:
	return _overlays.push(SETTINGS_SCENE.instantiate())


func set_buttons_disabled(value: bool) -> void:
	for b: BaseButton in [_new_vigil, _settings, _power_switch]:
		b.disabled = value


## POWER was pressed: ask first. The confirmation goes on this scene's own ScreenStack; cancelling returns focus to POWER
## (the stack restores the remembered focus).
func _on_power_pressed() -> void:
	if _powering_off or SceneRouter.is_busy:
		return
	var confirm := ConfirmScreen.create("CONFIRM_QUIT_TITLE", "CONFIRM_QUIT_BODY", "CONFIRM_QUIT_YES", "CONFIRM_QUIT_STAY")
	confirm.confirmed.connect(power_off)
	_overlays.push(confirm)


## The player confirmed: throw the switch, collapse the picture, then quit. Photosensitivity / reduced motion swaps the
## collapse for a plain quick fade of the same length.
func power_off() -> void:
	if _powering_off:
		return
	_powering_off = true
	set_buttons_disabled(true)
	if haunts != null:
		haunts.stop_all()
		haunts.enabled = false
	if hum != null:
		hum.stop()
	_coin.hint_armed = false
	_power_switch.throw_off()
	var mat := _arcade.crt_material()
	var seconds := _power.tuning.power_off_seconds
	if mat != null:
		mat.set_shader_parameter(&"collapse_fade", 1.0 if ArcadeButton.is_still() else 0.0)
		var tw := create_tween()
		tw.tween_method(func(v: float) -> void: mat.set_shader_parameter(&"collapse", v), 0.0, 1.0, seconds)
		tw.finished.connect(_finish_power_off)
	else:
		_finish_power_off()


func is_powering_off() -> bool:
	return _powering_off


func _finish_power_off() -> void:
	if quit_action.is_valid():
		quit_action.call()
	else:
		get_tree().quit()


## Dev captures only (`-- --haunt-showcase`, debug builds): every attract Haunting once, a few seconds apart,
## so one short windowed run can photograph them (normally they are rare and minutes apart). The figure is
## held for 60 fields here so a still can catch it; in play it lasts one (Q-T253). Never in a release build.
## Starts once the route has settled: after the power-on test if one runs, else at once.
func _start_showcase() -> void:
	if _power.running:
		_power.finished.connect(_haunt_showcase, CONNECT_ONE_SHOT)
	else:
		_haunt_showcase()


func _haunt_showcase() -> void:
	if haunts == null:
		return
	var steps: Array = [
		[1.0, func() -> void: haunts.perform(CabinetHauntDeck.GHOST_PRESS)],
		[3.0, func() -> void:
			haunts.perform(CabinetHauntDeck.STRANGER)
			_pages.show_page(AttractPages.Page.ROLL)],
		[8.0, func() -> void: haunts.perform(CabinetHauntDeck.WARM_COIN)],
		[11.0, func() -> void: haunts.screen.show_figure(60)],
		[14.0, func() -> void: haunts.perform(CabinetHauntDeck.LITANY)],
		[14.0, func() -> void: haunts.perform(CabinetHauntDeck.SOUR_JINGLE)],
		[16.5, func() -> void: haunts.perform(CabinetHauntDeck.CRAG_FIGURE)],
	]
	for s: Array in steps:
		get_tree().create_timer(float(s[0])).timeout.connect(s[1] as Callable)
