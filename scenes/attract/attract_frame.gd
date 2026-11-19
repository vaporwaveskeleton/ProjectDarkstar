class_name AttractFrame
extends Control
## The Cabinet's bezel around the attract screen (WARP-001 W0-01): the same printed columns as the
## in-game HUD (BezelPrint) flush against the screen hole, on the plain print field (BezelField). The
## coin door itself is the CoinSlot control on the right column. The readouts (1UP, score, HI, credit
## count) are lit on the screen's HUD strip, not here. It draws after the CRT in the attract scene, so
## the print is never scanlined. Costume art: honest at T0.


func _ready() -> void:
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	set_anchors_preset(Control.PRESET_FULL_RECT)
	for column: StringName in [&"left", &"right"]:
		var p := BezelPrint.new()
		p.column = column
		add_child(p)
	# the glass over the whole print, above the columns; the coin slot (the door) draws after it
	var glass := BezelGlass.new()
	glass.rig = get_parent() as ScreenRig
	add_child(glass)
