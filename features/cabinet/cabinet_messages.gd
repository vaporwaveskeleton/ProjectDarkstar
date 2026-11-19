class_name CabinetMessages
extends Control
## Text over the play view (the grid below the HUD strip, clipped to it): the READY card, centre banners, the caption line (GDD §10:
## the chant is audio-critical, so it is always captioned), the cabinet credits roll, and the
## entity's big type (ART-001 §11.5: NULL band above the centre, never animated per letter). Long lines wrap
## at spaces to the 256 px screen; nothing is shrunk below its role scale.

var _ready_title := ""
var _ready_sub := ""
var _ready_zone := ""            ## zone name line above the READY title ("" = none)
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
var _stat_indices := PackedInt32Array()   ## entries of `credits` that are service-record lines
var _stats_emitted: Dictionary = {}          ## stat-line index -> true once credits_stat_shown fired
var glitch := 0.0                ## 0..1 the Pretence Tear corrupts the credits
var demo := false                ## attract demo: INSERT CREDIT over the field
var _t := 0.0

signal credits_stat_shown(index: int)       ## stat line `index` (0..3) just scrolled into view

@export var spec: CabinetScreenSpec
@export var fx_tuning: CabinetFxTuning   ## credits scroll speed (data/cabinet/cabinet_fx_tuning.tres)

const MARGIN := 4.0              ## text keeps this far from the screen edge
const ZONE_GAP := 6.0            ## ✱ px between the zone line and the READY title below it
const READY_CLEAR := 14.0     ## ✱ px between the READY card and the play-view centre (Vigil hull 12 px + margin)


func _ready() -> void:
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	# the play view only: text clips at the HUD strip instead of running over it
	var s := spec if spec != null else (load("res://data/cabinet/cabinet_screen.tres") as CabinetScreenSpec)
	set_anchors_preset(Control.PRESET_TOP_LEFT)
	position = s.play_rect().position
	size = s.play_rect().size
	clip_contents = true


## The READY card. `zone` (optional) is the zone name line, drawn small above the title.
func show_ready(title: String, sub: String, seconds: float, zone: String = "") -> void:
	_ready_title = title
	_ready_sub = sub
	_ready_zone = zone
	_ready_t = seconds


## Top of the READY title, and of the zone line above it (play-view y). One layout for _draw and tests.
## The whole card sits above the play view centre, where the Vigil spawns (Reviewer, PR #57): its
## bottom (the READY line) ends READY_CLEAR px above the centre.
func ready_title_top() -> float:
	var h := block_height(_ready_title, 3) + 2.0 + block_height(_ready_sub, 1) + 12.0 + float(PixelText.H * 2)
	return size.y * 0.5 - READY_CLEAR - h


## Bottom of the READY line (play-view y).
func ready_bottom() -> float:
	return ready_title_top() + block_height(_ready_title, 3) + 2.0 + block_height(_ready_sub, 1) + 12.0 + float(PixelText.H * 2)


func ready_zone_top() -> float:
	return ready_title_top() - ZONE_GAP - block_height(_ready_zone, 1)


func ready_zone() -> String:
	return _ready_zone if _ready_t > 0.0 else ""


func banner(text: String, seconds: float) -> void:
	_banner = text
	_banner_t = seconds


func caption(text: String, seconds: float = 4.0) -> void:
	_caption = text
	_caption_t = seconds


func entity_line(text: String, seconds: float = 3.0) -> void:
	_line = text
	_line_t = seconds


func roll_credits(lines: PackedStringArray, stat_indices: PackedInt32Array = PackedInt32Array()) -> void:
	credits = lines
	_stat_indices = stat_indices
	_stats_emitted.clear()
	credits_t = 0.0
	credits_frozen = false


func clear() -> void:
	_ready_t = 0.0
	_banner_t = 0.0
	_caption_t = 0.0
	_line_t = 0.0
	credits_t = -1.0
	_stats_emitted.clear()


func _process(delta: float) -> void:
	_t += delta
	_ready_t = maxf(0.0, _ready_t - delta)
	_banner_t = maxf(0.0, _banner_t - delta)
	_caption_t = maxf(0.0, _caption_t - delta)
	_line_t = maxf(0.0, _line_t - delta)
	if credits_t >= 0.0 and not credits_frozen:
		credits_t += delta
		_emit_stat_lines()
	queue_redraw()


## Cabinet face, centred in the play view; `y` is the top of the glyphs; `scale` is an integer (ART-001 §11).
func _centered(y: float, s: String, scale: int, col: Color) -> void:
	PixelText.draw_centered(self, size.x * 0.5, y, s, col, scale)


## Wrapped, centred lines from `y`; returns the y just below the block.
func _block(y: float, s: String, scale: int, col: Color) -> float:
	var step := float(PixelText.H * scale + 3 * scale)
	for line in PixelText.wrap(s, scale, size.x - 2.0 * MARGIN):
		_centered(y, line, scale, col)
		y += step
	return y


## Height of `_block` for `s`.
func block_height(s: String, scale: int) -> float:
	return PixelText.wrap(s, scale, size.x - 2.0 * MARGIN).size() * float(PixelText.H * scale + 3 * scale)


func _draw() -> void:
	var cy := size.y * 0.5
	if _ready_t > 0.0:
		if not _ready_zone.is_empty():
			_block(ready_zone_top(), _ready_zone, 1, Look.c(Pal.GAS_4))
		var y := _block(ready_title_top(), _ready_title, 3, Look.c(Pal.BONE_5)) + 2.0
		y = _block(y, _ready_sub, 1, Look.c(Pal.BONE_2)) + 12.0
		if int(_t * 3.0) % 2 == 0:
			_centered(y, tr("CAB_READY"), 2, Look.c(Pal.GAS_4))
	if _banner_t > 0.0:
		_block(cy - 8.0 - (block_height(_banner, 2) - 18.0) * 0.5, _banner, 2, Look.c(Pal.BONE_5))
	if credits_t >= 0.0:
		_draw_credits()
	if _caption_t > 0.0:
		_block(size.y - 34.0, _caption, 1, Look.c(Pal.BONE_3))
	if demo and int(_t * 1.6) % 2 == 0:
		_centered(size.y - 22.0, tr("CAB_CREDIT"), 1, Look.c(Pal.BONE_5))
	if _line_t > 0.0:
		# the entity's big type: a hole torn in the frame (ART-001 §11.5); the band grows with the lines
		var h := block_height(_line, 3) + 2.0 * 8.0 - 9.0
		var top := cy - 60.0 - h * 0.5
		draw_rect(Rect2(0, top, size.x, h), Look.c(Pal.NULL))
		_block(top + 8.0, _line, 3, Look.c(Pal.BONE_5))


## Top edge (play-view y) of credits entry `i` when the roll has run `t` seconds. One layout for
## drawing and for `credits_stat_shown`, so they cannot disagree (wrap and pitch match _draw_credits).
func credit_entry_top(i: int, t: float) -> float:
	var y := size.y - t * _tuning().credits_scroll_px_per_s
	for k in mini(i, credits.size()):
		y += PixelText.wrap(credits[k], 2, size.x - 2.0 * MARGIN).size() * 18.0 + 4.0
	return y


func _draw_credits() -> void:
	for i in credits.size():
		var y := credit_entry_top(i, credits_t)
		var col := Look.c(Pal.BONE_4) if glitch < 0.5 or i % 2 == 0 else Look.c(Pal.PHOS_4)
		var x_shift := 0.0
		if glitch > 0.0 and (i * 7 + int(_t * 8.0)) % 3 == 0:
			x_shift = (sin(_t * 40.0 + i) * 12.0) * glitch
		for line in PixelText.wrap(credits[i], 2, size.x - 2.0 * MARGIN):
			if y > -16.0 and y < size.y + 2.0:
				PixelText.draw_centered(self, size.x * 0.5 + x_shift, y, line, col, 2)
			y += 18.0


## The stat lines announce themselves the first time their top edge scrolls into the view.
func _emit_stat_lines() -> void:
	for n in _stat_indices.size():
		if _stats_emitted.has(n):
			continue
		if credit_entry_top(_stat_indices[n], credits_t) < size.y:
			_stats_emitted[n] = true
			credits_stat_shown.emit(n)


func _tuning() -> CabinetFxTuning:
	if fx_tuning == null:
		fx_tuning = load("res://data/cabinet/cabinet_fx_tuning.tres") as CabinetFxTuning
	return fx_tuning
