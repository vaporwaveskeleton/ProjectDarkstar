class_name AttractFrame
extends Control
## The Cabinet's bezel around the attract screen (WARP-001 W0-01): the same printed sheet as the in-game
## HUD (BezelPrint columns flush against the screen hole, the plain print field BezelField round it, the
## marquee, the printed border, the T-molding and the room beyond; BezelAssembly). The coin door itself is
## the CoinSlot control on the right column, and the menu's pushbuttons sit on the control panel under the
## screen (ControlPanel). The readouts (1UP, score, HI, credit count) are lit on the screen's HUD strip, not
## here. It draws after the arcade screen (which carries its own CRT), so the print is never scanlined; the
## tube (rounded mask and a faint glass) is drawn last over the screen and never writes into it. The
## ScreenLight samples the arcade screen's SubViewport (`light_source`), exactly as in the game.
## Costume art: honest at T0.

@export var light_source: SubViewport   ## the arcade screen's SubViewport: ScreenLight reads its average colour


func _ready() -> void:
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	set_anchors_preset(Control.PRESET_FULL_RECT)
	var rig := get_parent() as ScreenRig
	for column: StringName in [&"left", &"right"]:
		var p := BezelPrint.new()
		p.column = column
		add_child(p)
	BezelAssembly.add_sheet_parts(self, rig)
	# the glass over the whole print, above the columns; the coin slot (the door) and the control panel draw after it
	var glass := BezelGlass.new()
	glass.rig = rig
	add_child(glass)
	BezelAssembly.add_tube(self)
	BezelAssembly.add_light(self, light_source)
