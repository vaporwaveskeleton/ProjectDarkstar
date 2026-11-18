extends Screen
## Settings overlay. Reads/writes SettingsService only; holds no state of its own.
## Accessibility rows never lie and are never hidden by warp (WARP-001 §4.7).

@onready var _large_text: CheckButton = %LargeText
@onready var _reduced_motion: CheckButton = %ReducedMotion
@onready var _photosensitivity: CheckButton = %Photosensitivity
@onready var _steady_ledger: CheckButton = %SteadyLedger
@onready var _back: Button = %Back

var _toggles: Dictionary = {}   # CheckButton -> setting key


func _ready() -> void:
	_toggles = {
		_large_text: &"text_scale",
		_reduced_motion: &"reduced_motion",
		_photosensitivity: &"photosensitivity",
		_steady_ledger: &"steady_ledger",
	}
	refresh()
	for cb: CheckButton in _toggles:
		cb.toggled.connect(_on_toggled.bind(cb))
	_back.pressed.connect(close)
	super()


func refresh() -> void:
	for cb: CheckButton in _toggles:
		var key: StringName = _toggles[cb]
		var v: Variant = SettingsService.get_value(key)
		cb.set_pressed_no_signal(v > 1.0 if key == &"text_scale" else bool(v))


func _on_toggled(pressed: bool, cb: CheckButton) -> void:
	var key: StringName = _toggles[cb]
	SettingsService.set_value(key, (2.0 if pressed else 1.0) if key == &"text_scale" else pressed)

