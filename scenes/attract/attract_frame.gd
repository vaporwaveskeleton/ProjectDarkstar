class_name AttractFrame
extends Control
## The Cabinet's bezel around the attract screen (WARP-001 W0-01): the same printed columns as the
## in-game HUD (BezelPrint), the lit 1UP / score strip in the same window and at the same scale, and
## the credit counter in the credit window. The right-hand windows show as dark, unlit glass. The
## coin door itself is the CoinSlot control on the right column. It draws after the CRT in the
## attract scene, so the print is never scanlined. Costume art: honest at T0.

var credits := 0
var _t := 0.0


func _ready() -> void:
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	set_anchors_preset(Control.PRESET_FULL_RECT)
	for column: StringName in [&"left", &"right"]:
		var p := BezelPrint.new()
		p.column = column
		add_child(p)


func _process(delta: float) -> void:
	_t += delta
	queue_redraw()


func _draw() -> void:
	var sv := LocFormat.format_int(0)
	CabinetBezel.draw_score(self, _t, sv, CabinetHud.score_scale(sv, CabinetBezel.READOUT_W))
	var col := Look.c(Pal.GAS_4) if credits > 0 else Look.c(Pal.BONE_2)
	CabinetBezel.draw_credit(self, tr("CAB_CREDIT_COUNT") % credits, col)
