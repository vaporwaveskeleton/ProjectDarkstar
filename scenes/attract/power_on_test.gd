class_name PowerOnTest
extends Control
## The Cabinet switching on (owner request 2026-11-18; WARP-001 W0-01): the CRT line opens to a
## raster of uninitialised video memory, the self-test wipes it and reports each check, then
## attract begins. Plays once per launch (Boot routes attract with {"power_on": true}).
## Any key, button or click skips it. Photosensitivity / reduced motion freeze the noise.

signal finished

const TESTS := ["CAB_BOOT_RAM", "CAB_BOOT_ROM", "CAB_BOOT_LAMPS", "CAB_BOOT_GLASS"]
const CELL := Vector2(8, 6)        ## noise cell, px
const REPORT_MARGIN := 24.0        # px: the self-test report keeps this far from the hole edge
const NOISE_COLOURS := [Pal.VOID_3, Pal.VOID_4, Pal.CHOIR_2, Pal.CHOIR_3, Pal.PHOS_2, Pal.PHOS_3,
	Pal.GAS_2, Pal.GAS_3, Pal.BONE_2, Pal.VOID_0]

@export var tuning: CabinetBootTuning

var running := false
var _t := 0.0
var _shown := 0
var _noise: PackedInt32Array = PackedInt32Array()
var _cols := 0
var _rows := 0


func _ready() -> void:
	set_anchors_preset(Control.PRESET_FULL_RECT)
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	visible = false


## The video-memory noise, sized to the hole (known once the parent HoleFit has sized this control).
func _build_noise() -> void:
	_cols = int(size.x / CELL.x) + 1
	_rows = int(size.y / CELL.y) + 2
	var r := RandomNumberGenerator.new()
	r.seed = 6809
	_noise.resize(_cols * _rows)
	for i in _noise.size():
		_noise[i] = r.randi_range(0, NOISE_COLOURS.size() - 1)


func start() -> void:
	_build_noise()
	running = true
	visible = true
	mouse_filter = Control.MOUSE_FILTER_STOP
	_t = 0.0
	_shown = 0
	AudioService.play(&"power_on")


func skip() -> void:
	if running:
		_finish()


## Seconds from switch-on to attract.
func total_seconds() -> float:
	return tuning.warmup_seconds + tuning.noise_seconds + (TESTS.size() + 1) * tuning.test_line_seconds + tuning.test_hold_seconds


func _lines_t() -> float:
	return _t - tuning.warmup_seconds - tuning.noise_seconds


func _process(delta: float) -> void:
	if not running:
		return
	_t += delta
	var lt := _lines_t()
	if lt >= 0.0:
		var n := mini(int(lt / tuning.test_line_seconds) + 1, TESTS.size() + 1)
		if n > _shown:
			_shown = n
			AudioService.play(&"menu_move")
	if _t >= total_seconds():
		_finish()
	queue_redraw()


func _finish() -> void:
	running = false
	visible = false
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	finished.emit()


## The attract screen feeds every input event here while the test runs (the test lives inside the arcade
## screen's viewport, which never sees the bezel's events). Returns true when the event is consumed: anything
## but motion. A press skips the test.
func handle_input(event: InputEvent) -> bool:
	if not running:
		return false
	if event is InputEventMouseMotion or event is InputEventJoypadMotion:
		return false
	if event.is_pressed() and not event.is_echo():
		skip()
	return true


func _draw() -> void:
	draw_rect(Rect2(Vector2.ZERO, size), Look.c(Pal.VOID_0))
	if _t < tuning.warmup_seconds:
		_draw_warmup(_t / tuning.warmup_seconds)
		return
	var lt := _lines_t()
	if lt < 0.0:
		_draw_noise(1.0)
		return
	# the self-test clears video memory top-down during its first line
	var wipe := clampf(lt / tuning.test_line_seconds, 0.0, 1.0)
	if wipe < 1.0:
		_draw_noise(1.0 - wipe)
	_draw_report()


## The beam opens: a dot, a line, then the raster.
func _draw_warmup(k: float) -> void:
	var w := lerpf(4.0, size.x, clampf(k * 2.0, 0.0, 1.0))
	var h := lerpf(1.0, size.y, clampf(k * 2.0 - 1.0, 0.0, 1.0))
	draw_rect(Rect2((size.x - w) * 0.5, (size.y - h) * 0.5, w, h), Look.c(Pal.BONE_4) if h < 4.0 else Look.c(Pal.VOID_1))


## `keep` 1 → 0: the bottom fraction still holding garbage.
func _draw_noise(keep: float) -> void:
	var frozen: bool = SettingsService.get_value(&"photosensitivity") or SettingsService.get_value(&"reduced_motion")
	var scroll := 0.0 if frozen else _t * tuning.noise_scroll
	var top := size.y * (1.0 - keep)
	var row_shift := int(scroll / CELL.y)
	var sub := fmod(scroll, CELL.y)
	for ry in _rows:
		var y := ry * CELL.y - sub
		if y + CELL.y <= top or y >= size.y:
			continue
		var src := posmod(ry + row_shift, _rows)
		# each row jitters sideways a little, as if memory were being rewritten under the beam
		var jitter := 0 if frozen else int(_t * 7.0 + src * 3) % 3
		for cx in _cols:
			var idx := _noise[src * _cols + posmod(cx + jitter, _cols)]
			var col: Color = Look.c(NOISE_COLOURS[idx])
			draw_rect(Rect2(cx * CELL.x, maxf(y, top), CELL.x, minf(CELL.y, y + CELL.y - maxf(y, top))), col)


func _draw_report() -> void:
	var x := REPORT_MARGIN
	var right := size.x - REPORT_MARGIN
	PixelText.draw_centered(self, size.x * 0.5, 70.0, tr("CAB_BOOT_HEADER"), Look.c(Pal.BONE_4))
	for i in mini(_shown, TESTS.size()):
		var y := 102.0 + i * 16.0
		var label := tr(TESTS[i])
		PixelText.draw(self, Vector2(x, y), label, Look.c(Pal.BONE_3))
		var dots_from := x + PixelText.width(label) + 6.0
		var ok_x := right - PixelText.width(tr("CAB_BOOT_OK"))
		for dx in range(int(dots_from), int(ok_x) - 6, 6):
			draw_rect(Rect2(dx, y + 6, 1, 1), Look.c(Pal.BONE_1))
		PixelText.draw(self, Vector2(ok_x, y), tr("CAB_BOOT_OK"), Look.c(Pal.PHOS_4))
	if _shown > TESTS.size():
		PixelText.draw_centered(self, size.x * 0.5, 102.0 + TESTS.size() * 16.0 + 12.0, tr("CAB_BOOT_DONE"), Look.c(Pal.GAS_4))
	PixelText.draw_centered(self, size.x * 0.5, size.y - 30.0, tr("CAB_MAKER"), Look.c(Pal.BONE_1))
