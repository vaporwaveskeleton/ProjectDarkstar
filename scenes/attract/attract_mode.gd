extends Screen
## Attract mode — the cabinet's title screen (GDD §10; WARP-001 W0-01/W0-03; owner request
## 2026-11-18, TECH-001 §11.2). On a cold launch the Cabinet powers on and self-tests first
## (PowerOnTest). Then the marquee, the instruction cards (AttractPages) and the coin door
## (CoinSlot) on the bezel: New Vigil stays greyed out until a credit is in. Emits intent only:
## routing goes through SceneRouter, settings through the local ScreenStack. Left alone with
## no credit for DEMO_IDLE seconds it plays its own demo.

const SETTINGS_SCENE := preload("res://scenes/settings/settings_screen.tscn")
const DEMO_IDLE := 30.0          ## s — WARP-001 W0-03 "30 s idle on the title screen"

@onready var _new_vigil: Button = %NewVigil
@onready var _settings: Button = %Settings
@onready var _quit: Button = %Quit
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
var _profile: Dictionary = {}


func _ready() -> void:
	Look.t = 0.0                       # the title is part of the neon cabinet (ART-001 §15)
	cancel_closes = false
	_new_vigil.pressed.connect(_on_new_vigil)
	_settings.pressed.connect(open_settings)
	_quit.pressed.connect(_on_quit)
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
	_set_new_vigil_ready(false)
	default_focus = _coin
	_wire_focus()
	_apply_text_scale_layout()
	SettingsService.setting_changed.connect(func(key: StringName, _v: Variant) -> void:
		if key == &"text_scale":
			_apply_text_scale_layout())
	_coin.hint_armed = true
	super()


## The 240-class screen has no room for the instruction cards beside 200 % buttons (the text is never
## shrunk): at 200 % the cards give way, the marquee and the menu stay.
func _apply_text_scale_layout() -> void:
	_pages.visible = float(SettingsService.get_value(&"text_scale")) < 1.5


## Boot routes the first attract of a launch with {"power_on": true}.
func on_route_entered(params: Dictionary) -> void:
	if bool(params.get("power_on", false)):
		power_on()


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
	if not demo_enabled or not _overlays.is_empty() or SceneRouter.is_busy or _power.running or _coin.is_busy():
		idle = 0.0
		return
	idle += delta
	if idle >= DEMO_IDLE:
		idle = 0.0
		SceneRouter.go_to(&"cabinet", {"demo": true})


func _input(event: InputEvent) -> void:
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


## New Vigil keeps its place in the menu; without a credit it is greyed out and skipped by focus.
func _set_new_vigil_ready(armed: bool) -> void:
	_new_vigil.disabled = not armed
	_new_vigil.focus_mode = Control.FOCUS_ALL if armed else Control.FOCUS_NONE
	_logo.has_credit = armed


## Vertical loop through what can act: [New Vigil] → Settings → Quit → coin door → wrap.
## The coin door sits on the bezel to the right, so right from any button reaches it too.
func _wire_focus() -> void:
	var order: Array[Control] = []
	if _new_vigil.focus_mode != Control.FOCUS_NONE:
		order.append(_new_vigil)
	order.append_array([_settings, _quit, _coin])
	for i in order.size():
		var c := order[i]
		var prev := order[(i - 1 + order.size()) % order.size()]
		var next := order[(i + 1) % order.size()]
		c.focus_neighbor_top = c.get_path_to(prev)
		c.focus_neighbor_bottom = c.get_path_to(next)
		c.focus_previous = c.get_path_to(prev)
		c.focus_next = c.get_path_to(next)
		if c != _coin:
			c.focus_neighbor_right = c.get_path_to(_coin)
	_coin.focus_neighbor_left = _coin.get_path_to(order[0])


func _on_new_vigil() -> void:
	# Busy state: lock the menu so repeated input cannot queue a second run.
	if SceneRouter.is_busy or not _coin.has_credit():
		return
	set_buttons_disabled(true)
	if SceneRouter.go_to(&"cabinet"):
		_coin.spend()
	else:
		set_buttons_disabled(false)


func open_settings() -> Screen:
	return _overlays.push(SETTINGS_SCENE.instantiate())


func set_buttons_disabled(value: bool) -> void:
	for b: Button in [_new_vigil, _settings, _quit]:
		b.disabled = value


func _on_quit() -> void:
	get_tree().quit()
