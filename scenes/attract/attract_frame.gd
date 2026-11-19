class_name AttractFrame
extends Control
## The Cabinet's bezel around the attract screen (WARP-001 W0-01): the same printed sheet as the in-game
## HUD (BezelPrint columns flush against the screen hole, the plain print field BezelField round it, the
## marquee, the printed border, the T-molding and the room beyond; BezelAssembly). The coin door itself is
## the CoinSlot control on the right column. The readouts (1UP, score, HI, credit count) are lit on the
## screen's HUD strip, not here. It draws after the CRT in the attract scene, so the print is never
## scanlined; the tube (rounded mask and a faint glass) is drawn last over the screen and reads the CRT's
## output without ever writing to it. Costume art: honest at T0.


func _ready() -> void:
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	set_anchors_preset(Control.PRESET_FULL_RECT)
	var rig := get_parent() as ScreenRig
	for column: StringName in [&"left", &"right"]:
		var p := BezelPrint.new()
		p.column = column
		add_child(p)
	BezelAssembly.add_sheet_parts(self, rig)
	# the glass over the whole print, above the columns; the coin slot (the door) draws after it
	var glass := BezelGlass.new()
	glass.rig = rig
	add_child(glass)
	BezelAssembly.add_tube(self)
	BezelAssembly.add_light(self, null)
