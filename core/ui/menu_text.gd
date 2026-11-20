class_name MenuText
extends VectorLabel
## Stroke text for the overlay menus (TECH-001 §2.9a/§2.9b): a VectorLabel whose face follows the
## menu role and Large Text (SettingsService text_scale, live), and whose case and colour follow the
## costume (MenuSkin: upper case on the cabinet). Set `key` (a tr() key) as usual.

@export var role: MenuSkin.Role = MenuSkin.Role.ROW:
	set(v):
		role = v
		if is_inside_tree():
			restyle()
## Keep the colour the owner sets instead of the role's ink.
@export var custom_color := false

var kind: MenuSkin.Kind = MenuSkin.Kind.CABINET


func _ready() -> void:
	super()
	kind = MenuSkin.for_node(self)
	restyle()
	if not SettingsService.setting_changed.is_connected(_on_setting_changed):
		SettingsService.setting_changed.connect(_on_setting_changed)


## The text as the costume prints it (cabinet upper case).
func shown_text() -> String:
	var s := text if text != "" else (tr(key) if key != &"" else "")
	return MenuSkin.shown(s, kind)


func restyle() -> void:
	face = MenuSkin.face(role)
	if not custom_color:
		color = MenuSkin.ink(kind, role)


func _on_setting_changed(k: StringName, _v: Variant) -> void:
	if k == &"text_scale":
		restyle()
