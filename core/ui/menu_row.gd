class_name MenuRow
extends BaseButton
## One focusable row of an overlay menu (UI-001 §10): a BaseButton that draws itself in the menu
## costume (MenuSkin) with stroke text (MenuText). Styles:
##   ACTION  a plain command (Resume, Back, Confirm)
##   TOGGLE  a setting: toggle_mode, shows a lamp and ON/OFF (never colour alone, GDD §10)
##   TAB     a page tab; `active` marks the one whose page is shown (drawn as the lit plate)
##   INFO    a read-only line with up to two value columns (the controls reference); focusable so a
##           pad can scroll to it, pressing does nothing
##   SLIDER  a 0..100 setting: a bar and the number; left/right step it (`step`), a click or drag on
##           the bar sets it. Emits `value_changed` for a change the player made (not `show_slider`).
## Holds no game state: the owning Screen reads and writes the service.

signal value_changed(value: int)

enum Style { ACTION, TOGGLE, TAB, INFO, SLIDER }

@export var key: StringName = &"":
	set(v):
		key = v
		if _label:
			_label.key = v
@export var desc_key: StringName = &""
@export var style: Style = Style.ACTION:
	set(v):
		style = v
		toggle_mode = v == Style.TOGGLE
@export var align_center := false
## INFO values (already readable text, e.g. InputLabels output).
@export var value_text: String = "":
	set(v):
		value_text = v
		if _value:
			_value.text = v
@export var value_text_2: String = "":
	set(v):
		value_text_2 = v
		if _value_2:
			_value_2.text = v
## ✱ Width of each INFO value column at 100 % text (logical px), unless the Screen sets `columns`.
@export var value_column: float = 78.0
## SLIDER: range and key step (percent). `floor_value` is the lowest the player may set.
@export var max_value := 100
@export var step := 5
@export var floor_value := 0
## ✱ SLIDER bar size (logical px; the bar does not grow with Large Text, the number and label do).
const BAR_SIZE := Vector2(56.0, 7.0)
## ✱ Gap between the label, the bar and the number (logical px at 100 % text).
const BAR_GAP := 8.0
var value := 0
var _dragging := false
## INFO column widths at the current text size, set by the Screen so every row of a table lines up
## (0 = use value_column).
var columns := Vector2.ZERO:
	set(v):
		columns = v
		update_minimum_size()
		_layout()
## ✱ Gap between the label and the stacked values (logical px at 100 % text).
const STACK_GAP := 2.0
## ✱ Indent of the stacked values under the label (logical px at 100 % text).
const STACK_INDENT := 8.0

## TAB: this tab's page is the one shown (drawn as the lit plate).
var active := false:
	set(v):
		active = v
		queue_redraw()
var kind: MenuSkin.Kind = MenuSkin.Kind.CABINET
var _label: MenuText
var _value: MenuText
var _value_2: MenuText
var _blink := 0.0
var _cursor_on := true


func _ready() -> void:
	kind = MenuSkin.for_node(self)
	toggle_mode = style == Style.TOGGLE
	if desc_key != &"" and tooltip_text == "":
		tooltip_text = desc_key
	_label = _make_text(&"Label", MenuSkin.Role.ROW)
	_label.key = key
	if style == Style.TOGGLE or style == Style.SLIDER:
		_value = _make_text(&"Value", MenuSkin.Role.VALUE)
		if style == Style.SLIDER:
			_value.text = str(value)
			gui_input.connect(_on_slider_input)
	elif style == Style.INFO:
		_value = _make_text(&"Value", MenuSkin.Role.VALUE)
		_value.text = value_text
		_value_2 = _make_text(&"Value2", MenuSkin.Role.VALUE)
		_value_2.text = value_text_2
	toggled.connect(func(_on: bool) -> void: _refresh())
	focus_entered.connect(_on_focus_changed)
	focus_exited.connect(_on_focus_changed)
	mouse_entered.connect(queue_redraw)
	mouse_exited.connect(queue_redraw)
	resized.connect(_layout)
	SettingsService.setting_changed.connect(_on_setting_changed)
	_refresh()
	set_process(false)


func _make_text(n: StringName, role: MenuSkin.Role) -> MenuText:
	var t := MenuText.new()
	t.name = n
	t.role = role
	t.custom_color = true
	t.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(t, false, Node.INTERNAL_MODE_FRONT)
	t.minimum_size_changed.connect(_on_text_resized)
	return t


## The text this row prints (tests: never a raw key).
func label_text() -> String:
	return _label.shown_text() if _label else ""


func value_shown() -> String:
	return _value.shown_text() if _value else ""


func _on_text_resized() -> void:
	update_minimum_size()
	_layout()


func _get_minimum_size() -> Vector2:
	if _label == null:
		return Vector2.ZERO
	var s := MenuSkin.text_scale()
	var pad := MenuSkin.ROW_PAD * Vector2(1.0, s)
	var lm := _label.get_combined_minimum_size()
	var w := lm.x + pad.x * 2.0
	var h := lm.y
	if style == Style.TOGGLE:
		w += _value_width() + _lamp_r() * 2.0 + pad.x * 2.0
		h = maxf(h, _value.get_combined_minimum_size().y)
	elif style == Style.SLIDER:
		if _slider_stacked():
			w = maxf(lm.x + BAR_GAP * s + _number_width(), STACK_INDENT * s + BAR_SIZE.x * 2.0) + pad.x * 2.0
			h = lm.y + STACK_GAP * s + BAR_SIZE.y
		else:
			w += (BAR_GAP * 2.0) * s + BAR_SIZE.x + _number_width() + pad.x
			h = maxf(h, _value.get_combined_minimum_size().y)
	elif _stacked():
		var v1 := _value.get_combined_minimum_size()
		var v2 := _value_2.get_combined_minimum_size()
		w = maxf(lm.x, maxf(v1.x, v2.x) + STACK_INDENT * s) + pad.x * 2.0
		h = lm.y + v1.y + v2.y + STACK_GAP * s * 2.0
	elif style == Style.INFO:
		w += pad.x + _col(0) + _col(1)
	return Vector2(w, h + pad.y * 2.0)


## INFO rows at Large Text put each value on its own line under the label (keyboard, then gamepad,
## the header row in the same order), so the controls reference stays inside the 640 px frame
## (UI-001 §4 safe area).
func _stacked() -> bool:
	return style == Style.INFO and MenuSkin.text_scale() > 1.5


func _value_width() -> float:
	# reserve the wider of ON and OFF so the row never changes width when toggled
	var f := MenuSkin.face(MenuSkin.Role.VALUE)
	var g := VectorText.default_glyphs()
	return maxf(VectorText.measure(MenuSkin.shown(tr(&"SETTINGS_ON"), kind), g, f).x,
		VectorText.measure(MenuSkin.shown(tr(&"SETTINGS_OFF"), kind), g, f).x) + f.stroke_width


## Reserve the width of "100" so the bar never moves as the number changes.
func _number_width() -> float:
	var f := MenuSkin.face(MenuSkin.Role.VALUE)
	return VectorText.measure("100", VectorText.default_glyphs(), f).x + f.stroke_width


## At Large Text the bar drops under the label (a wider bar, the number stays on the label line), so
## the longest label still fits the 640 px frame (UI-001 §4 safe area).
func _slider_stacked() -> bool:
	return style == Style.SLIDER and MenuSkin.text_scale() > 1.5


## The bar's rect in the row's own space.
func slider_rect() -> Rect2:
	var s := MenuSkin.text_scale()
	var pad := MenuSkin.ROW_PAD * Vector2(1.0, s)
	if _slider_stacked():
		var y := pad.y + _label.get_combined_minimum_size().y + STACK_GAP * s
		return Rect2(Vector2(pad.x + STACK_INDENT * s, y), Vector2(BAR_SIZE.x * 2.0, BAR_SIZE.y))
	var x := size.x - pad.x - _number_width() - BAR_GAP * s - BAR_SIZE.x
	return Rect2(Vector2(x, (size.y - BAR_SIZE.y) * 0.5), BAR_SIZE)


func _lamp_r() -> float:
	return 2.5 * MenuSkin.text_scale()


func _layout() -> void:
	if _label == null:
		return
	var s := MenuSkin.text_scale()
	var pad := MenuSkin.ROW_PAD * Vector2(1.0, s)
	var lm := _label.get_combined_minimum_size()
	var ly := pad.y if (_stacked() or _slider_stacked()) else (size.y - lm.y) * 0.5
	if align_center:
		_label.position = Vector2(maxf((size.x - lm.x) * 0.5, pad.x), ly)
	else:
		_label.position = Vector2(pad.x, ly)
	_label.size = lm
	if style == Style.TOGGLE:
		var vm := _value.get_combined_minimum_size()
		var vw := _value_width()
		_value.position = Vector2(size.x - pad.x - vw, (size.y - vm.y) * 0.5)
		_value.size = Vector2(vw, vm.y)
	elif style == Style.SLIDER:
		var vm := _value.get_combined_minimum_size()
		# right-aligned in the reserved number width, so the bar never moves as the digits change
		var vy := pad.y if _slider_stacked() else (size.y - vm.y) * 0.5
		_value.position = Vector2(size.x - pad.x - vm.x, vy)
		_value.size = vm
	elif style == Style.INFO:
		for i in 2:
			var t: MenuText = [_value, _value_2][i]
			var vm := t.get_combined_minimum_size()
			if _stacked():
				var above := lm.y + STACK_GAP * s + (_value.get_combined_minimum_size().y + STACK_GAP * s if i == 1 else 0.0)
				t.position = Vector2(pad.x + STACK_INDENT * s, pad.y + above)
			else:
				t.position = Vector2(size.x - pad.x - _col(1) - (_col(0) if i == 0 else 0.0), (size.y - vm.y) * 0.5)
			t.size = Vector2(vm.x if _stacked() else _col(i), vm.y)
	queue_redraw()


func _refresh() -> void:
	if _label == null:
		return
	_label.color = _label_ink()
	if style == Style.TOGGLE:
		_value.key = &"SETTINGS_ON" if button_pressed else &"SETTINGS_OFF"
		_value.color = MenuSkin.on_ink(kind) if button_pressed else MenuSkin.off_ink(kind)
	elif style == Style.SLIDER:
		_value.color = MenuSkin.ink(kind, MenuSkin.Role.VALUE)
	elif style == Style.INFO:
		_value.color = MenuSkin.ink(kind, MenuSkin.Role.VALUE)
		_value_2.color = MenuSkin.ink(kind, MenuSkin.Role.VALUE)
	queue_redraw()


func _label_ink() -> Color:
	if disabled:
		return MenuSkin.disabled_ink(kind)
	if has_focus() or (style == Style.TAB and active):
		return MenuSkin.focus_ink(kind) if kind == MenuSkin.Kind.CABINET else Pal.GAS_5
	return MenuSkin.ink(kind, MenuSkin.Role.ROW)


func _on_focus_changed() -> void:
	_blink = 0.0
	_cursor_on = true
	set_process(has_focus() and kind == MenuSkin.Kind.CABINET and not MenuSkin.still())
	_refresh()


func _on_setting_changed(k: StringName, _v: Variant) -> void:
	if k == &"text_scale":
		update_minimum_size()
		_layout()
	elif k == &"reduced_motion" or k == &"photosensitivity":
		_on_focus_changed()


func _process(delta: float) -> void:
	_blink += delta
	if _blink >= MenuSkin.BLINK_S:
		_blink = 0.0
		_cursor_on = not _cursor_on
		queue_redraw()


func _draw() -> void:
	_draw_row()


func _state() -> MenuSkin.State:
	if disabled:
		return MenuSkin.State.DISABLED
	if is_pressed() and style != Style.TOGGLE and style != Style.TAB:
		return MenuSkin.State.PRESSED
	if has_focus():
		return MenuSkin.State.FOCUS
	if is_hovered():
		return MenuSkin.State.HOVER
	return MenuSkin.State.NORMAL


func _draw_row() -> void:
	if _label and _label.color != _label_ink():
		_label.color = _label_ink()
	var r := Rect2(Vector2.ZERO, size)
	MenuSkin.row_back(self, r, kind, _state(), style == Style.TAB and active, _cursor_on or MenuSkin.still())
	if style == Style.TOGGLE and _value:
		var lr := _lamp_r()
		MenuSkin.indicator(self, Vector2(_value.position.x - lr - 5.0 * MenuSkin.text_scale(), size.y * 0.5), lr, kind, button_pressed)
	if style == Style.SLIDER and _value:
		MenuSkin.slider(self, slider_rect(), kind, float(value) / float(max_value), float(floor_value) / float(max_value))
	if style != Style.TAB and kind == MenuSkin.Kind.CABINET and not has_focus():
		# a ruled line under each cabinet row, like a printed service sheet
		MenuSkin.rule(self, Vector2(MenuSkin.ROW_PAD.x, size.y - 1.0), size.x - MenuSkin.ROW_PAD.x * 2.0, kind, false)


## Width of INFO column `i` at the current text size.
func _col(i: int) -> float:
	var w := columns.x if i == 0 else columns.y
	return w if w > 0.0 else value_column * MenuSkin.text_scale()


## The widths the INFO values need (the Screen takes the maximum over a table).
func value_widths() -> Vector2:
	if _value == null or _value_2 == null:
		return Vector2.ZERO
	return Vector2(_value.get_combined_minimum_size().x, _value_2.get_combined_minimum_size().x)


## SLIDER: show `v` (held inside the floor and the maximum) without emitting `value_changed`.
func show_slider(v: int) -> void:
	value = clampi(v, floor_value, max_value)
	if _value:
		_value.text = str(value)
	update_minimum_size()
	queue_redraw()


## SLIDER: the player moved it to `v`. Emits only when the held value actually changes.
func set_slider(v: int) -> void:
	var nv := clampi(v, floor_value, max_value)
	if nv == value:
		return
	show_slider(nv)
	value_changed.emit(value)


func _on_slider_input(event: InputEvent) -> void:
	if disabled:
		return
	if event.is_action_pressed(&"ui_left", true):
		set_slider(value - step)
		accept_event()   # left/right belong to the slider; Escape/Back returns to the tab (Settings)
	elif event.is_action_pressed(&"ui_right", true):
		set_slider(value + step)
		accept_event()
	elif event is InputEventMouseButton and (event as InputEventMouseButton).button_index == MOUSE_BUTTON_LEFT:
		_dragging = (event as InputEventMouseButton).pressed
		if _dragging:
			_set_from_x((event as InputEventMouseButton).position.x)
	elif event is InputEventMouseMotion and _dragging:
		_set_from_x((event as InputEventMouseMotion).position.x)


func _set_from_x(x: float) -> void:
	var r := slider_rect()
	var f := clampf((x - r.position.x) / r.size.x, 0.0, 1.0)
	set_slider(int(round(f * float(max_value) / float(step))) * step)


## Show a setting's value without emitting `toggled` (the Screen reads the service).
func show_value(on: bool) -> void:
	set_pressed_no_signal(on)
	_refresh()
