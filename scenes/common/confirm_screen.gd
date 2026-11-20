class_name ConfirmScreen
extends Screen
## Reusable two-choice confirmation. Default focus is the SAFE choice (cancel), so a mashed
## confirm button never triggers the destructive action. ui_cancel = cancel.
## Costume (MenuSkin): the cabinet service screen in Act 0, brass in the Aether; a caution plate (GAS).
## Cancel sits first (left) and holds focus; Confirm is the second choice.

signal confirmed
signal cancelled

const SCENE_PATH := "res://scenes/common/confirm_screen.tscn"

@export var title_key: String = ""
@export var body_key: String = ""
@export var confirm_key: String = ""
@export var cancel_key: String = ""

@onready var _title: MenuText = %Title
@onready var _body: MenuText = %Body
@onready var _confirm: MenuRow = %Confirm
@onready var _cancel: MenuRow = %Cancel


static func create(p_title: String, p_body: String, p_confirm: String, p_cancel: String) -> ConfirmScreen:
	var s := (load(SCENE_PATH) as PackedScene).instantiate() as ConfirmScreen
	s.title_key = p_title
	s.body_key = p_body
	s.confirm_key = p_confirm
	s.cancel_key = p_cancel
	return s


func _ready() -> void:
	_title.key = StringName(title_key)
	_body.key = StringName(body_key)
	_confirm.key = StringName(confirm_key)
	_cancel.key = StringName(cancel_key)
	_confirm.pressed.connect(_on_confirm)
	_cancel.pressed.connect(cancel)
	super()


func _on_confirm() -> void:
	_confirm.disabled = true
	confirmed.emit()
	close()


func cancel() -> void:
	cancelled.emit()
	close()
