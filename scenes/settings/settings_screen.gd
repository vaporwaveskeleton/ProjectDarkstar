extends Screen
## Settings overlay (UI-001 §10). Reads/writes SettingsService only; holds no state of its own.
## Accessibility rows never lie and are never hidden by warp (WARP-001 §4.7).
## Layout: a tab rail (Accessibility, Video, Controls, then Back) beside the active page, a line under
## the page that describes the focused row. Focusing a tab shows its page; accept moves into the page.
## Focus: the rail is a wrapping ring, each page is a wrapping ring, right goes rail -> page and left
## goes page -> the active tab (explicit neighbours, set here and tested). Costume: MenuSkin.

## Page rows -> setting key. Large Text maps on/off to text_scale 2.0/1.0 (GDD §10).
const TOGGLES := {
	&"LargeText": &"text_scale",
	&"ReducedMotion": &"reduced_motion",
	&"Photosensitivity": &"photosensitivity",
	&"SteadyLedger": &"steady_ledger",
	&"MuzzleFlash": &"muzzle_flash",
}
## Controls reference rows -> the InputMap actions they print (GDD §4.1; read live by InputLabels).
const BINDINGS := {
	&"BindMove": [&"move_left", &"move_right", &"move_up", &"move_down"],
	&"BindAim": [&"aim_left", &"aim_right", &"aim_up", &"aim_down"],
	&"BindFire": [&"fire_lance"],
	&"BindCharge": [&"deploy_charge"],
	&"BindSurgelight": [&"surgelight"],
	&"BindLantern": [&"lantern_toggle"],
	&"BindBrake": [&"brake"],
	&"BindCodex": [&"open_codex"],
	&"BindPause": [&"pause"],
}

## ✱ Gap after each controls value column (logical px at 100 % text).
const COLUMN_GAP := 12.0

## ✱ A slider preview waits this long after the last change, so holding a key plays one cue, not a burst.
const PREVIEW_DELAY_S := 0.18

@onready var _tabs: Array[MenuRow] = [%TabAccessibility, %TabVideo, %TabAudio, %TabControls]
@onready var _pages: Array[Control] = [%PageAccessibility, %PageVideo, %PageAudio, %PageControls]
@onready var _back: MenuRow = %Back
@onready var _desc: MenuText = %Desc
@onready var _subtitle: MenuText = %Subtitle

var _rows: Dictionary = {}     # MenuRow -> setting key
var _sliders: Dictionary = {}  # MenuRow -> setting key (the Audio page's volume sliders)
var _page := 0
var _preview_timer: Timer
var _preview_key: StringName = &""


func _ready() -> void:
	_subtitle.visible = MenuSkin.for_node(self) == MenuSkin.Kind.CABINET
	for row_name: StringName in TOGGLES:
		var row := get_node("%" + String(row_name)) as MenuRow
		_rows[row] = TOGGLES[row_name]
		row.toggled.connect(_on_toggled.bind(row))
	_preview_timer = Timer.new()
	_preview_timer.one_shot = true
	_preview_timer.wait_time = PREVIEW_DELAY_S
	_preview_timer.timeout.connect(_play_preview)
	add_child(_preview_timer)
	for e in UserVolume.SLIDERS:
		var srow := get_node("%" + String(e["row"])) as MenuRow
		srow.floor_value = int(e["floor"])
		srow.step = UserVolume.STEP
		_sliders[srow] = e["key"]
		srow.value_changed.connect(_on_slider_changed.bind(srow))
	for i in _tabs.size():
		var tab := _tabs[i]
		tab.focus_entered.connect(show_page.bind(i))
		tab.pressed.connect(_enter_page)
	_fill_bindings()
	refresh()
	_back.pressed.connect(close)
	for c: Control in _focusables():
		c.focus_entered.connect(_describe.bind(c))
	show_page(0)
	SettingsService.setting_changed.connect(_on_setting_changed)
	super()


func refresh() -> void:
	for row: MenuRow in _rows:
		var key: StringName = _rows[row]
		var v: Variant = SettingsService.get_value(key)
		row.show_value(float(v) > 1.0 if key == &"text_scale" else bool(v))
	for srow: MenuRow in _sliders:
		srow.show_slider(int(SettingsService.get_value(_sliders[srow])))


## A slider the player moved: write it (AudioService applies it live) and queue the preview cue.
func _on_slider_changed(v: int, srow: MenuRow) -> void:
	var key: StringName = _sliders[srow]
	SettingsService.set_value(key, v)
	_preview_key = key
	_preview_timer.start()


func _play_preview() -> void:
	AudioService.preview_volume(_preview_key)


## Escape / Back on a slider steps out to its tab (left and right belong to the slider); anywhere
## else it closes the screen as every overlay does (UI-001 §3).
func cancel() -> void:
	var f := get_viewport().gui_get_focus_owner()
	if f is MenuRow and _sliders.has(f):
		_tabs[_page].grab_focus()
		return
	super()


func _on_toggled(pressed: bool, row: MenuRow) -> void:
	var key: StringName = _rows[row]
	SettingsService.set_value(key, (2.0 if pressed else 1.0) if key == &"text_scale" else pressed)


func _on_setting_changed(key: StringName, _value: Variant) -> void:
	refresh()
	if key == &"text_scale":
		_fit_columns.call_deferred()


## Show page `i`, mark its tab and rewire the focus neighbours.
func show_page(i: int) -> void:
	_page = clampi(i, 0, _pages.size() - 1)
	for p in _pages.size():
		_pages[p].visible = p == _page
	for t in _tabs.size():
		_tabs[t].active = t == _page
	_wire_focus()


func current_page() -> int:
	return _page


## Accept on a tab: step into its page.
func _enter_page() -> void:
	var rows := page_rows(_page)
	if not rows.is_empty():
		rows[0].grab_focus()


## The focusable rows of page `i`, top to bottom.
func page_rows(i: int) -> Array[Control]:
	var out: Array[Control] = []
	for c in _pages[i].get_children():
		if c is Control and (c as Control).focus_mode != Control.FOCUS_NONE:
			out.append(c as Control)
	return out


func _rail() -> Array[Control]:
	var out: Array[Control] = []
	out.append_array(_tabs)
	out.append(_back)
	return out


func _focusables() -> Array[Control]:
	var out := _rail()
	for i in _pages.size():
		out.append_array(page_rows(i))
	return out


func _wire_focus() -> void:
	var rail := _rail()
	var rows := page_rows(_page)
	var into: Control = rows[0] if not rows.is_empty() else rail[_page]
	_ring(rail)
	for c in rail:
		c.focus_neighbor_left = c.get_path_to(c)
		c.focus_neighbor_right = c.get_path_to(into)
	for i in _pages.size():
		var pr := page_rows(i)
		_ring(pr)
		for c in pr:
			c.focus_neighbor_left = c.get_path_to(_tabs[i])
			c.focus_neighbor_right = c.get_path_to(c)


## Vertical wrapping ring (UI-001 §4: no dead ends).
func _ring(items: Array[Control]) -> void:
	var n := items.size()
	for k in n:
		var c := items[k]
		var prev := items[(k - 1 + n) % n]
		var next := items[(k + 1) % n]
		c.focus_neighbor_top = c.get_path_to(prev)
		c.focus_neighbor_bottom = c.get_path_to(next)
		c.focus_previous = c.get_path_to(prev)
		c.focus_next = c.get_path_to(next)


func _describe(c: Control) -> void:
	_desc.key = (c as MenuRow).desc_key if c is MenuRow else &""


## The controls reference reads the live InputMap (InputLabels), so it always matches the bindings.
func _fill_bindings() -> void:
	var header := %BindHeader as MenuRow
	header.value_text = tr(&"CONTROLS_COLUMN_KEYS")
	header.value_text_2 = tr(&"CONTROLS_COLUMN_PAD")
	for row_name: StringName in BINDINGS:
		var row := get_node("%" + String(row_name)) as MenuRow
		var acts: Array = BINDINGS[row_name]
		row.value_text = _binding(acts, false)
		row.value_text_2 = _binding(acts, true)
	_fit_columns()


## Line the controls table up: each value column is as wide as its widest entry plus a gap.
func _fit_columns() -> void:
	var rows: Array[MenuRow] = [%BindHeader as MenuRow]
	for row_name: StringName in BINDINGS:
		rows.append(get_node("%" + String(row_name)) as MenuRow)
	var w := Vector2.ZERO
	for r in rows:
		w = w.max(r.value_widths())
	var gap := COLUMN_GAP * MenuSkin.text_scale()
	for r in rows:
		r.columns = w + Vector2(gap, gap)


func _binding(acts: Array, gamepad: bool) -> String:
	var s := ""
	var first: StringName = acts[0]
	if acts.size() == 4:
		var right: StringName = acts[1]
		var up: StringName = acts[2]
		var down: StringName = acts[3]
		s = InputLabels.vector(first, right, up, down, gamepad)
		if s.strip_edges() == "" and not gamepad:
			s = tr(&"ATTRACT_MOUSE")
	else:
		s = InputLabels.action(first, gamepad)
	return s if s.strip_edges() != "" else tr(&"CONTROLS_UNBOUND")
