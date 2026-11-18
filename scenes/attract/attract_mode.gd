extends Screen
## Attract mode — the title screen (GDD §10: Attract -> New Vigil -> Sector 1, three clicks max).
## Emits intent only: routing goes through SceneRouter, settings through the local ScreenStack.

const SETTINGS_SCENE := preload("res://scenes/settings/settings_screen.tscn")

@onready var _new_vigil: Button = %NewVigil
@onready var _settings: Button = %Settings
@onready var _quit: Button = %Quit
@onready var _overlays: ScreenStack = %Overlays


func _ready() -> void:
	cancel_closes = false
	_new_vigil.pressed.connect(_on_new_vigil)
	_settings.pressed.connect(open_settings)
	_quit.pressed.connect(_on_quit)
	super()


func _on_new_vigil() -> void:
	# Busy state: lock the menu so repeated input cannot queue a second run.
	if SceneRouter.is_busy:
		return
	set_buttons_disabled(true)
	if not SceneRouter.go_to(&"sector"):
		set_buttons_disabled(false)


func open_settings() -> Screen:
	return _overlays.push(SETTINGS_SCENE.instantiate())


func set_buttons_disabled(value: bool) -> void:
	for b in [_new_vigil, _settings, _quit]:
		b.disabled = value


func _on_quit() -> void:
	get_tree().quit()
