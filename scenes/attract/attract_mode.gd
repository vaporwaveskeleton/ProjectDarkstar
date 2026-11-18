extends Screen
## Attract mode — the cabinet's title screen (GDD §10: Attract → New Vigil → play, three clicks
## max; WARP-001 W0-01/W0-03). Emits intent only: routing goes through SceneRouter, settings
## through the local ScreenStack. Left alone for DEMO_IDLE seconds it plays its own demo.

const SETTINGS_SCENE := preload("res://scenes/settings/settings_screen.tscn")
const DEMO_IDLE := 30.0          ## s — WARP-001 W0-03 "30 s idle on the title screen"

@onready var _new_vigil: Button = %NewVigil
@onready var _settings: Button = %Settings
@onready var _quit: Button = %Quit
@onready var _overlays: ScreenStack = %Overlays
@onready var _omen: Label = %Omen
@onready var _logo: AttractLogo = %Logo

var idle := 0.0
var demo_enabled := true         ## tests turn this off


func _ready() -> void:
	cancel_closes = false
	_new_vigil.pressed.connect(_on_new_vigil)
	_settings.pressed.connect(open_settings)
	_quit.pressed.connect(_on_quit)
	var profile := SaveService.load_slot(&"profile")
	var payload: Dictionary = profile.payload if profile.ok else {}
	_omen.visible = bool(payload.get("act0_complete", false))
	_logo.hi_score = int(payload.get("cabinet_hi_score", 0))
	super()


func _process(delta: float) -> void:
	if not demo_enabled or not _overlays.is_empty() or SceneRouter.is_busy:
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


func _on_new_vigil() -> void:
	# Busy state: lock the menu so repeated input cannot queue a second run.
	if SceneRouter.is_busy:
		return
	set_buttons_disabled(true)
	if not SceneRouter.go_to(&"cabinet"):
		set_buttons_disabled(false)


func open_settings() -> Screen:
	return _overlays.push(SETTINGS_SCENE.instantiate())


func set_buttons_disabled(value: bool) -> void:
	for b in [_new_vigil, _settings, _quit]:
		b.disabled = value


func _on_quit() -> void:
	get_tree().quit()
