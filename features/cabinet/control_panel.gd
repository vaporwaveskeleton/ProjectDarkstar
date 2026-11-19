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
