class_name ControlPanel
extends Control
## The Cabinet's control panel (Q-T34): the strip of the bezel under the screen where the attract menu's
## pushbuttons (ArcadeButton) live. It only places its children: each ArcadeButton goes to its `slot` in
## CabinetBezel.panel_slot, so the buttons sit on the print under the tube and never over it. It draws after
## the glass (like the coin door), so the buttons stand proud of the sheet.


func _ready() -> void:
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	var panel := CabinetBezel.control_panel()
	position = panel.position
	size = panel.size
	for b in buttons():
		var r := CabinetBezel.panel_slot(b.slot)
		b.position = r.position - panel.position
		b.size = r.size


## The panel's buttons, in slot order.
func buttons() -> Array[ArcadeButton]:
	var out: Array[ArcadeButton] = []
	for c in get_children():
		if c is ArcadeButton:
			out.append(c)
	out.sort_custom(func(a: ArcadeButton, b: ArcadeButton) -> bool: return a.slot < b.slot)
	return out


## The in-game bezel's panel: the same three buttons in the same slots, as decoration only (the arcade game is played
## with the game's own controls). Lamps dark, not focusable, mouse and input ignored.
static func add_decorative(host: Control) -> ControlPanel:
	var panel := ControlPanel.new()
	panel.name = "ControlPanel"
	var specs := [
		[ArcadeButton.Kind.START, 0, "MENU_NEW_VIGIL", 0.0],
		[ArcadeButton.Kind.SERVICE, 1, "MENU_SETTINGS", 1.0],
		[ArcadeButton.Kind.SERVICE, 2, "MENU_QUIT", 2.0],
	]
	for s: Array in specs:
		var b := ArcadeButton.new()
		b.kind = s[0]
		b.slot = s[1]
		b.label_key = s[2]
		b.variant = s[3]
		panel.add_child(b)
	host.add_child(panel)
	for b in panel.buttons():
		b.focus_mode = Control.FOCUS_NONE
		b.mouse_filter = Control.MOUSE_FILTER_IGNORE
		b.mouse_default_cursor_shape = Control.CURSOR_ARROW
	return panel
