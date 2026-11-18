class_name AttractFrame
extends Control
## The Cabinet's bezel around the attract screen (WARP-001 W0-01): the same side panels as the
## in-game HUD (CabinetBezel), the 1UP strip, and the credit counter. The coin door itself is the
## CoinSlot control on the right panel. Costume art: honest at T0.

var credits := 0
var _t := 0.0


func _ready() -> void:
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	set_anchors_preset(Control.PRESET_FULL_RECT)


func _process(delta: float) -> void:
	_t += delta
	queue_redraw()


func _draw() -> void:
	CabinetBezel.draw_panel(self, 0.0, 0.0)
	CabinetBezel.draw_panel(self, 640.0 - CabinetBezel.SIDE, 0.0)
	var x := 12.0
	var one_up := Look.c(Pal.GAS_4) if int(_t * 2.0) % 2 == 0 else Look.c(Pal.GAS_2)
	PixelText.draw(self, Vector2(x, 23), tr("CAB_1UP"), one_up)
	PixelText.draw(self, Vector2(x, 39), LocFormat.format_int(0), Look.c(Pal.BONE_5))
	var col := Look.c(Pal.GAS_4) if credits > 0 else Look.c(Pal.BONE_2)
	PixelText.draw(self, Vector2(x, 323), tr("CAB_CREDIT_COUNT") % credits, col)
