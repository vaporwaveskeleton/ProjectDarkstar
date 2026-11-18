class_name AttractLogo
extends Control
## The cabinet's marquee (WARP-001 W0-01/W0-03): DARKSTAR in the Cabinet face at ×6 with a brass
## glow, INSERT CREDIT blinking, and the high score. Costume art: honest, cheerful, 1983.

const SCALE := 6
var hi_score := 0
var has_credit := false          ## a coin is in: the marquee asks for New Vigil instead
var _t := 0.0


func _ready() -> void:
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	custom_minimum_size = Vector2(PixelText.width(tr("GAME_TITLE"), SCALE) + 8, 80)


func _process(delta: float) -> void:
	_t += delta
	queue_redraw()


func _draw() -> void:
	var title := tr("GAME_TITLE")
	var cx := size.x * 0.5
	# glow: the same letters offset in dark brass, then the bright face
	for o in [Vector2(-1, 0), Vector2(1, 0), Vector2(0, -1), Vector2(0, 1)]:
		PixelText.draw_centered(self, cx + o.x, 4 + o.y, title, Look.c(Pal.GAS_1), SCALE)
	PixelText.draw_centered(self, cx, 4, title, Look.c(Pal.GAS_4), SCALE)
	# a highlight band sweeps across the marquee like a lamp passing behind glass
	var sweep := fposmod(_t * 0.25, 1.4) - 0.2
	var band_x := lerpf(cx - 160.0, cx + 160.0, sweep)
	draw_rect(Rect2(band_x, 4, 6, 7 * SCALE), Color(Look.c(Pal.GAS_5), 0.35))
	if int(_t * 1.6) % 2 == 0:
		var prompt := tr("CAB_PRESS_NEW_VIGIL") if has_credit else tr("CAB_CREDIT")
		PixelText.draw_centered(self, cx, 58, prompt, Look.c(Pal.GAS_4) if has_credit else Look.c(Pal.BONE_4), 1)
	PixelText.draw_centered(self, cx, 70, "%s %s" % [tr("CAB_HI"), LocFormat.format_int(hi_score)], Look.c(Pal.BONE_2), 1)
