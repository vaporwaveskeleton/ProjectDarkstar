class_name AttractLogo
extends Control
## The cabinet's marquee (WARP-001 W0-01/W0-03): DARKSTAR in the Cabinet face with a brass glow and
## INSERT CREDIT blinking. The title takes the biggest whole-number scale that fits the 256 px screen
## (×4 today; ×6 on the old 640 px one). The high score is on the screen's HUD strip, not here.
## Costume art: honest, cheerful, 1983.

const MAX_SCALE := 6
const SIDE_MARGIN := 12.0        ## px kept clear on each side of the screen

@export var spec: CabinetScreenSpec

var has_credit := false          ## a coin is in: the marquee asks for New Vigil instead
var _t := 0.0
var _scale := MAX_SCALE


func _ready() -> void:
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	if spec == null:
		spec = load("res://data/cabinet/cabinet_screen.tres") as CabinetScreenSpec
	_scale = title_scale(tr("GAME_TITLE"), float(spec.grid.x) - 2.0 * SIDE_MARGIN)
	custom_minimum_size = Vector2(PixelText.width(tr("GAME_TITLE"), _scale) + 8, 4 + PixelText.H * _scale + 6 + PixelText.H + 2)


## The largest whole-number scale (≤ MAX_SCALE) at which `title` is at most `max_w` px wide.
static func title_scale(title: String, max_w: float) -> int:
	for s in range(MAX_SCALE, 1, -1):
		if float(PixelText.width(title, s)) <= max_w:
			return s
	return 1


func _process(delta: float) -> void:
	_t += delta
	queue_redraw()


func _draw() -> void:
	var title := tr("GAME_TITLE")
	var cx := size.x * 0.5
	var half := PixelText.width(title, _scale) * 0.5
	# glow: the same letters offset in dark brass, then the bright face
	for o in [Vector2(-1, 0), Vector2(1, 0), Vector2(0, -1), Vector2(0, 1)]:
		PixelText.draw_centered(self, cx + o.x, 4 + o.y, title, Look.c(Pal.GAS_1), _scale)
	PixelText.draw_centered(self, cx, 4, title, Look.c(Pal.GAS_4), _scale)
	# a highlight band sweeps across the marquee like a lamp passing behind glass
	var sweep := fposmod(_t * 0.25, 1.4) - 0.2
	var band_x := lerpf(cx - half, cx + half, sweep)
	draw_rect(Rect2(band_x, 4, 6, PixelText.H * _scale), Color(Look.c(Pal.GAS_5), 0.35))
	if int(_t * 1.6) % 2 == 0:
		var prompt := tr("CAB_PRESS_NEW_VIGIL") if has_credit else tr("CAB_CREDIT")
		PixelText.draw_centered(self, cx, 4 + PixelText.H * _scale + 6, prompt, Look.c(Pal.GAS_4) if has_credit else Look.c(Pal.BONE_4), 1)
