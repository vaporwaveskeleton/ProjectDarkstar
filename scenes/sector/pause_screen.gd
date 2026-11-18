extends Screen
## Real pause screen. With Steady Ledger on, Esc always opens this (WARP-001 §4.4, W4-07).
## Pauses the tree while open; process_mode = ALWAYS so it still receives input.

signal abandon_requested

const SETTINGS_SCENE := preload("res://scenes/settings/settings_screen.tscn")

@onready var _resume: Button = %Resume
@onready var _settings: Button = %Settings
@onready var _abandon: Button = %Abandon


func _ready() -> void:
	_resume.pressed.connect(close)
	_settings.pressed.connect(func(): stack.push(SETTINGS_SCENE.instantiate()))
	_abandon.pressed.connect(_on_abandon)
	super()


func _unhandled_input(event: InputEvent) -> void:
	# The pause action toggles back to play, like ui_cancel.
	if is_visible_in_tree() and stack and stack.top() == self and event.is_action_pressed(&"pause") and not event.is_echo():
		get_viewport().set_input_as_handled()
		close()
		return
	super(event)


func _on_abandon() -> void:
	var confirm := ConfirmScreen.create("CONFIRM_ABANDON_TITLE", "CONFIRM_ABANDON_BODY",
		"CONFIRM_ABANDON_YES", "CONFIRM_KEEP_PLAYING")
	confirm.confirmed.connect(func(): abandon_requested.emit())
	stack.push(confirm)
