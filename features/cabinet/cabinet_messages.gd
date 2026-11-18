class_name CabinetMessages
extends Control
## Full-screen text over the field: the READY card, centre banners, the caption line (GDD §10:
## the chant is audio-critical, so it is always captioned), the cabinet credits roll, and the
## entity's big type (ART-001 §11.5: NULL band at y = 120, never animated per letter).

var _ready_title := ""
var _ready_sub := ""
var _ready_t := 0.0
var _banner := ""
var _banner_t := 0.0
var _caption := ""
var _caption_t := 0.0
var _line := ""
var _line_t := 0.0
var credits: PackedStringArray = PackedStringArray()
var credits_t := -1.0            ## < 0 = no credits roll
var credits_frozen := false
var glitch := 0.0                ## 0..1 the Pretence Tear corrupts the credits
var demo := false                ## attract demo: INSERT CREDIT over the field
var _t := 0.0


func _ready() -> void:
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	set_anchors_preset(Control.PRESET_FULL_RECT)


func show_ready(title: String, sub: String, seconds: float) -> void:
	_ready_title = title
	_ready_sub = sub
	_ready_t = seconds


func banner(text: String, seconds: float) -> void:
	_banner = text
	_banner_t = seconds


func caption(text: String, seconds: float = 4.0) -> void:
	_caption = text
	_caption_t = seconds


func entity_line(text: String, seconds: float = 3.0) -> void:
	_line = text
	_line_t = seconds


func roll_credits(lines: PackedStringArray) -> void:
	credits = lines
	credits_t = 0.0
	credits_frozen = false


func clear() -> void:
	_ready_t = 0.0
	_banner_t = 0.0
	_caption_t = 0.0
	_line_t = 0.0
	credits_t = -1.0


func _process(delta: float) -> void:
	_t += delta
	_ready_t = maxf(0.0, _ready_t - delta)
	_banner_t = maxf(0.0, _banner_t - delta)
	_caption_t = maxf(0.0, _caption_t - delta)
	_line_t = maxf(0.0, _line_t - delta)
	if credits_t >= 0.0 and not credits_frozen:
		credits_t += delta
	queue_redraw()


## Cabinet face, centred; `y` is the top of the glyphs; `scale` is an integer (ART-001 §11).
func _centered(y: float, s: String, scale: int, col: Color) -> void:
	PixelText.draw_centered(self, 320.0, y, s, col, scale)


func _draw() -> void:
	if _ready_t > 0.0:
		_centered(132, _ready_title, 3, Pal.BONE_5)
		_centered(162, _ready_sub, 1, Pal.BONE_2)
		if int(_t * 3.0) % 2 == 0:
			_centered(196, tr("CAB_READY"), 2, Pal.GAS_4)
	if _banner_t > 0.0:
		_centered(172, _banner, 2, Pal.BONE_5)
	if credits_t >= 0.0:
		_draw_credits()
	if _caption_t > 0.0:
		_centered(334, _caption, 1, Pal.BONE_3)
	if demo and int(_t * 1.6) % 2 == 0:
		_centered(300, tr("CAB_CREDIT"), 2, Pal.BONE_5)
	if _line_t > 0.0:
		# the entity's big type: a hole torn in the frame (ART-001 §11.5)
		draw_rect(Rect2(0, 120 - 19, 640, 38), Pal.NULL)
		_centered(120 - 10, _line, 3, Pal.BONE_5)


func _draw_credits() -> void:
	var y0 := 360.0 - credits_t * 24.0
	for i in credits.size():
		var y := y0 + i * 22.0
		if y < -10.0 or y > 380.0:
			continue
		var s := credits[i]
		var x_shift := 0.0
		if glitch > 0.0 and (i * 7 + int(_t * 8.0)) % 3 == 0:
			x_shift = (sin(_t * 40.0 + i) * 24.0) * glitch
		PixelText.draw_centered(self, 320.0 + x_shift, y, s, Pal.BONE_4 if glitch < 0.5 or i % 2 == 0 else Pal.PHOS_4, 2)
