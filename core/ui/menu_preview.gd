class_name MenuPreview
extends Control
## A live preview of the focused setting, in the lower right of Settings (UI-001 §10; Fable review
## 2026-11-20). It reads SettingsService itself, so it always shows the real current value:
##   text_scale        the sample word at 100 % and 200 %, the one in use lit
##   reduced_motion    the Vigil dart drifting on its line; it holds still when the setting is on
##   photosensitivity  a flash sample: full when off, dimmed when on (it never flashes here)
##   muzzle_flash      the Arc-Lance muzzle: a flash at the nose when on, none when off
##   steady_ledger     a lying HUD digit beside the honest Steady Ledger digit (the ledger plate is
##                     dark when the setting is off)
##   vol_*             a level meter filled to the slider's value
## Anything else (a tab, Back, a controls row) shows a one-line prompt. Pure presentation: no input,
## no focus. At Large Text it gives its room to the text (like MenuOrnament).
## Colours are role colours (focus GAS, honest PHOS, the lie CHOIR); never SIGNAL. Geometry is ✱.

## ✱ Size at 100 % text (logical px); zero at 200 %.
@export var base_min := Vector2(132.0, 44.0)
## ✱ The dart's drift speed (cycles per second).
const DRIFT_HZ := 0.25

var kind: MenuSkin.Kind = MenuSkin.Kind.CABINET
var setting: StringName = &""
var _t := 0.0


func _ready() -> void:
	kind = MenuSkin.for_node(self)
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	focus_mode = Control.FOCUS_NONE
	SettingsService.setting_changed.connect(_on_setting_changed)
	_fit()
	_update_process()


## Show the preview for setting `key` (a SettingsService key, or &"" for none).
func show_for(key: StringName) -> void:
	setting = key
	_update_process()
	queue_redraw()


## True while the preview animates (only the motion sample, and never under reduced motion).
func is_moving() -> bool:
	return is_processing()


func _fit() -> void:
	custom_minimum_size = base_min if MenuSkin.text_scale() < 1.5 else Vector2.ZERO
	visible = MenuSkin.text_scale() < 1.5


func _update_process() -> void:
	set_process(setting == &"reduced_motion" and not MenuSkin.still() and visible)


func _on_setting_changed(k: StringName, _v: Variant) -> void:
	if k == &"text_scale":
		_fit()
	_update_process()
	queue_redraw()


func _process(delta: float) -> void:
	_t = fmod(_t + delta * DRIFT_HZ, 1.0)
	queue_redraw()


# ---------------------------------------------------------------- drawing

func _ink(base: Color) -> Color:
	return MenuSkin.c(kind, base)


func _draw() -> void:
	if size.x < 40.0 or size.y < 24.0:
		return
	var r := Rect2(Vector2.ZERO, size)
	_window(r)
	var inner := r.grow(-5.0)
	var key := String(setting)
	if key == "text_scale":
		_draw_text_sample(inner)
	elif key == "reduced_motion":
		_draw_motion(inner)
	elif key == "photosensitivity":
		_draw_flash(inner, not bool(SettingsService.get_value(&"photosensitivity")))
	elif key == "muzzle_flash":
		_draw_muzzle(inner, bool(SettingsService.get_value(&"muzzle_flash")))
	elif key == "steady_ledger":
		_draw_ledger(inner, bool(SettingsService.get_value(&"steady_ledger")))
	elif key.begins_with("vol_"):
		_draw_meter(inner, float(SettingsService.get_value(setting)) / 100.0)
	else:
		var m := MenuSkin.measure(tr(&"SETTINGS_PREVIEW_IDLE"), MenuSkin.Role.SMALL, kind)
		MenuSkin.text(self, (r.get_center() - m * 0.5).round(), tr(&"SETTINGS_PREVIEW_IDLE"), MenuSkin.Role.SMALL, kind,
			MenuSkin.ink(kind, MenuSkin.Role.HINT))


## The preview's window: a monitor inset on the cabinet, a glass porthole plate in brass.
func _window(r: Rect2) -> void:
	if kind == MenuSkin.Kind.BRASS:
		draw_rect(r, Color(Pal.VOID_0, 0.55), true)
		draw_rect(r, Pal.GAS_2, false, 1.0)
		draw_rect(r.grow(-2.0), Color(Pal.GAS_0, 0.9), false, 1.0)
		for p: Vector2 in [r.position + Vector2(3, 3), Vector2(r.end.x - 3, r.position.y + 3),
				r.end - Vector2(3, 3), Vector2(r.position.x + 3, r.end.y - 3)]:
			Brass.rivet(self, p)
		return
	draw_rect(r, _ink(Pal.VOID_0), true)
	draw_rect(r, _ink(Pal.VOID_4), false, 1.0)
	# corner ticks of a monitor inset
	var tick := _ink(Pal.BONE_2)
	for c: Vector2 in [r.position, Vector2(r.end.x, r.position.y), r.end, Vector2(r.position.x, r.end.y)]:
		var sx := 1.0 if c.x <= r.position.x else -1.0
		var sy := 1.0 if c.y <= r.position.y else -1.0
		draw_line(c + Vector2(sx * 1.0, sy * 1.0), c + Vector2(sx * 5.0, sy * 1.0), tick, 1.0)
		draw_line(c + Vector2(sx * 1.0, sy * 1.0), c + Vector2(sx * 1.0, sy * 5.0), tick, 1.0)


func _caption(pos: Vector2, key: StringName, col: Color) -> void:
	MenuSkin.text(self, pos.round(), tr(key), MenuSkin.Role.SMALL, kind, col)


func _draw_text_sample(r: Rect2) -> void:
	var large := MenuSkin.text_scale() > 1.5
	var word := MenuSkin.shown(tr(&"SETTINGS_PREVIEW_TEXT"), kind)
	var lit := MenuSkin.focus_ink(kind)
	var dim := MenuSkin.off_ink(kind)
	var x := r.position.x + 4.0
	for i in 2:
		var s := float(i + 1)
		var col := lit if (i == 1) == large else dim
		if kind == MenuSkin.Kind.CABINET:
			var h := float(PixelText.H) * s
			PixelText.draw_crt(self, Vector2(x, r.get_center().y - h * 0.5).round(), word, col, int(s))
			x += float(PixelText.width(word, int(s))) + 10.0
		else:
			var f := MenuSkin.face(MenuSkin.Role.ROW, s, kind)
			var sz := VectorText.measure(word, VectorText.default_glyphs(), f)
			var mesh := MenuSkin.cached_mesh(word, f)
			if mesh != null:
				draw_mesh(mesh, null, Transform2D(0.0, Vector2(x, r.get_center().y - sz.y * 0.5)), col)
			x += sz.x + 10.0


func _dart(at: Vector2, h: float, col: Color) -> PackedVector2Array:
	var pts := PackedVector2Array([at + Vector2(h, 0), at + Vector2(-h * 0.7, -h * 0.55), at + Vector2(-h * 0.35, 0),
		at + Vector2(-h * 0.7, h * 0.55)])
	draw_colored_polygon(pts, col)
	return pts


func _draw_motion(r: Rect2) -> void:
	var y := r.get_center().y
	var line := _ink(Pal.VOID_4)
	draw_line(Vector2(r.position.x + 4.0, y), Vector2(r.end.x - 4.0, y), line, 1.0)
	var still := MenuSkin.still()
	var f := 0.5 if still else 0.5 + 0.42 * sin(_t * TAU)
	var at := Vector2(lerpf(r.position.x + 10.0, r.end.x - 10.0, f), y)
	if not still:
		# a short trail behind the dart (motion only)
		for k in 3:
			var back := at - Vector2(5.0 + 4.0 * k, 0) * signf(cos(_t * TAU) + 0.0001)
			draw_circle(back, 1.2, Color(_ink(Pal.GAS_3), 0.5 - 0.15 * k))
	_dart(at, 6.0, MenuSkin.focus_ink(kind))


## A flash burst: full when `full`, dimmed (smaller, lower alpha) when the photosensitivity mode is on.
func _burst(c: Vector2, rad: float, full: bool) -> void:
	var a := 1.0 if full else 0.35
	var core := Color(_ink(Pal.BONE_5), a)
	var ray := Color(_ink(Pal.GAS_4), a * 0.85)
	var k := 1.0 if full else 0.6
	for i in 8:
		var ang := float(i) * TAU / 8.0
		var ray_len := rad * k * (1.0 if i % 2 == 0 else 0.6)
		draw_line(c, c + Vector2(cos(ang), sin(ang)) * ray_len, ray, 1.5)
	draw_circle(c, rad * 0.35 * k, core)


func _draw_flash(r: Rect2, full: bool) -> void:
	_burst(r.get_center(), minf(r.size.y * 0.5, 16.0), full)


func _draw_muzzle(r: Rect2, on: bool) -> void:
	var y := r.get_center().y
	var nose := Vector2(r.position.x + 30.0, y)
	_dart(nose - Vector2(6.0, 0), 8.0, MenuSkin.ink(kind, MenuSkin.Role.ROW))
	# the lance's line to the right
	draw_line(nose + Vector2(4.0, 0), Vector2(r.end.x - 6.0, y), Color(_ink(Pal.GAS_3), 0.8), 1.0)
	if on:
		_burst(nose + Vector2(4.0, 0), 9.0, true)


func _draw_ledger(r: Rect2, on: bool) -> void:
	var half := Rect2(r.position, Vector2(r.size.x * 0.5 - 3.0, r.size.y))
	var right := Rect2(Vector2(r.position.x + r.size.x * 0.5 + 3.0, r.position.y), half.size)
	var cap := MenuSkin.ink(kind, MenuSkin.Role.SMALL)
	# the HUD under warp: a digit that lies (CHOIR), slightly torn
	_caption(half.position + Vector2(2, 1), &"SETTINGS_PREVIEW_HUD", cap)
	_digit(Vector2(half.get_center().x, half.end.y - 2.0), "8", _ink(Pal.CHOIR_4), true)
	# the Steady Ledger: always the truth, in phosphor (dark plate when the setting is off)
	draw_rect(right, _ink(Pal.VOID_2) if on else _ink(Pal.VOID_0), true)
	draw_rect(right, _ink(Pal.PHOS_2) if on else _ink(Pal.VOID_3), false, 1.0)
	_caption(right.position + Vector2(2, 1), &"SETTINGS_PREVIEW_LEDGER", cap if on else MenuSkin.disabled_ink(kind))
	if on:
		_digit(Vector2(right.get_center().x, right.end.y - 2.0), "3", MenuSkin.on_ink(kind), false)


## A large digit with its bottom centre at `bottom`; `torn` shifts its lower half (the HUD lie).
func _digit(bottom: Vector2, d: String, col: Color, torn: bool) -> void:
	if kind == MenuSkin.Kind.CABINET:
		var ps := 3
		var p := Vector2(bottom.x - PixelText.width(d, ps) * 0.5, bottom.y - PixelText.H * ps).round()
		PixelText.draw_crt(self, p, d, col, ps)
		if torn:
			# a torn scan band across the middle: the lie
			draw_rect(Rect2(p + Vector2(-2.0, PixelText.H * ps * 0.5), Vector2(PixelText.width(d, ps) + 4.0, 2.0)), _ink(Pal.VOID_0), true)
		return
	var f := MenuSkin.face(MenuSkin.Role.TITLE, 1.6, kind)
	var sz := VectorText.measure(d, VectorText.default_glyphs(), f)
	var mesh := MenuSkin.cached_mesh(d, f)
	if mesh == null:
		return
	var at := Vector2(bottom.x - sz.x * 0.5, bottom.y - sz.y)
	if torn:
		draw_mesh(mesh, null, Transform2D(0.0, at + Vector2(2.0, 0.0)), Color(col, 0.45))
	draw_mesh(mesh, null, Transform2D(0.0, at), col)


func _draw_meter(r: Rect2, level: float) -> void:
	var bars := 14
	var gap := 2.0
	var bw := floorf((r.size.x - gap * float(bars - 1)) / float(bars))
	var x0 := r.position.x + floorf((r.size.x - (bw * bars + gap * (bars - 1))) * 0.5)
	var lit := _ink(Pal.PHOS_3) if kind == MenuSkin.Kind.CABINET else Pal.GAS_4
	var unlit := _ink(Pal.VOID_2) if kind == MenuSkin.Kind.CABINET else Pal.GAS_0
	for i in bars:
		# a fixed level shape (a held tone's spectrum), scaled by the slider: louder fills taller bars
		var shape := 0.45 + 0.55 * sin((float(i) + 0.5) / float(bars) * PI)
		var h := r.size.y * shape
		var x := x0 + float(i) * (bw + gap)
		draw_rect(Rect2(Vector2(x, r.end.y - h), Vector2(bw, h)), unlit, true)
		var fill := h * clampf(level, 0.0, 1.0)
		if fill > 0.5:
			draw_rect(Rect2(Vector2(x, r.end.y - fill), Vector2(bw, fill)), lit, true)
