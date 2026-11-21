extends Screen
## The debug menu's one screen (see debug_menu.gd): a stage select. Each Act 0 stage is a row of two
## controls: the name (Enter = play that stage now) and a lamp toggle "in shift" (the order you switch
## them on is the shift order). Below: the resulting shift with its Unmaking count, then Start shift,
## Reset to data roster, Close. UI-001: one default focus, explicit neighbours, ui_cancel closes.
## Dev builds only; no class_name.

var menu: Node                          ## the debug_menu.gd host (set before the screen enters the tree)

var _stages: Array[CabinetStage] = []
var _picked: Array[int] = []            ## indices into _stages, in shift order
var _grid: Array = []                   ## rows of Controls for the focus neighbours
var _toggles: Array[MenuRow] = []
var _shift_text: MenuText
var _unmake_text: MenuText
var _status: MenuText
var _start: MenuRow


func _ready() -> void:
	_stages = menu.call("all_stages")
	_pick_active()
	_build()
	_refresh()
	super()


## The picked list starts as the shift the cabinet plays now.
func _pick_active() -> void:
	_picked.clear()
	var active: CabinetStageRoster = menu.call("active_roster")
	for st in active.stages:
		for i in _stages.size():
			if _stages[i].id == st.id:
				_picked.append(i)


func _build() -> void:
	var dim := Panel.new()
	dim.theme_type_variation = &"DimPanel"
	dim.set_anchors_preset(Control.PRESET_FULL_RECT)
	add_child(dim)
	var center := CenterContainer.new()
	center.set_anchors_preset(Control.PRESET_FULL_RECT)
	add_child(center)
	var panel := PanelContainer.new()
	panel.set_script(preload("res://core/ui/menu_frame.gd"))
	center.add_child(panel)
	var layout := VBoxContainer.new()
	layout.add_theme_constant_override("separation", 4)
	panel.add_child(layout)
	var title := _text(&"MENU_DEBUG_TITLE", MenuSkin.Role.TITLE)
	layout.add_child(title)
	var rule := MenuRule.new()
	rule.heavy = true
	layout.add_child(rule)
	var scroll := FitScrollContainer.new()
	scroll.also_reserve = [title, rule]
	layout.add_child(scroll)
	var rows := VBoxContainer.new()
	rows.custom_minimum_size = Vector2(230, 0)
	rows.add_theme_constant_override("separation", 3)
	scroll.add_child(rows)

	rows.add_child(_text(&"MENU_DEBUG_HINT", MenuSkin.Role.HINT))
	for i in _stages.size():
		var line := HBoxContainer.new()
		line.add_theme_constant_override("separation", 4)
		rows.add_child(line)
		var play := _row(StringName(_stages[i].title_key))
		play.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		play.pressed.connect(_on_play.bind(i))
		line.add_child(play)
		var lamp := _row(&"MENU_DEBUG_IN_SHIFT", MenuRow.Style.TOGGLE)
		lamp.button_pressed = _picked.has(i)
		lamp.toggled.connect(_on_lamp.bind(i))
		line.add_child(lamp)
		_toggles.append(lamp)
		_grid.append([play, lamp])
	rows.add_child(MenuRule.new())
	_shift_text = _text(&"", MenuSkin.Role.ROW)
	rows.add_child(_shift_text)
	_unmake_text = _text(&"", MenuSkin.Role.ROW)
	rows.add_child(_unmake_text)
	_start = _row(&"MENU_DEBUG_START")
	_start.pressed.connect(_on_start)
	rows.add_child(_start)
	var reset := _row(&"MENU_DEBUG_RESET")
	reset.pressed.connect(_on_reset)
	rows.add_child(reset)
	var close_row := _row(&"MENU_DEBUG_CLOSE")
	close_row.pressed.connect(close)
	rows.add_child(close_row)
	_status = _text(&"", MenuSkin.Role.HINT)
	rows.add_child(_status)
	_grid.append([_start])
	_grid.append([reset])
	_grid.append([close_row])
	default_focus = _grid[0][0]
	_link_focus.call_deferred()


func _text(key: StringName, role: MenuSkin.Role) -> MenuText:
	var t := MenuText.new()
	t.key = key
	t.role = role
	t.mouse_filter = Control.MOUSE_FILTER_IGNORE
	return t


func _row(key: StringName, style: MenuRow.Style = MenuRow.Style.ACTION) -> MenuRow:
	var r := MenuRow.new()
	r.key = key
	r.style = style
	return r


## Explicit neighbours: up/down by grid row (wrapping, same column when it exists), left/right in a row.
func _link_focus() -> void:
	var n := _grid.size()
	for r in n:
		var line: Array = _grid[r]
		for c in line.size():
			var ctl := line[c] as Control
			var up: Array = _grid[(r + n - 1) % n]
			var down: Array = _grid[(r + 1) % n]
			ctl.focus_neighbor_top = ctl.get_path_to(up[mini(c, up.size() - 1)] as Control)
			ctl.focus_neighbor_bottom = ctl.get_path_to(down[mini(c, down.size() - 1)] as Control)
			ctl.focus_neighbor_left = ctl.get_path_to(line[(c + line.size() - 1) % line.size()] as Control)
			ctl.focus_neighbor_right = ctl.get_path_to(line[(c + 1) % line.size()] as Control)


func _picked_stages() -> Array[CabinetStage]:
	var out: Array[CabinetStage] = []
	for i in _picked:
		out.append(_stages[i])
	return out


func _refresh() -> void:
	var names := PackedStringArray()
	for k in _picked.size():
		names.append("%d %s" % [k + 1, tr(_stages[_picked[k]].title_key)])
	var list := ", ".join(names) if not names.is_empty() else tr("MENU_DEBUG_NONE")
	_shift_text.text = tr("MENU_DEBUG_SHIFT").format({"stages": list})
	var roster: CabinetStageRoster = menu.call("make_roster", _picked_stages())
	_unmake_text.text = tr("MENU_DEBUG_UNMAKINGS").format({"n": roster.unmakings_required()})
	_start.disabled = _picked.is_empty()


func _on_lamp(on: bool, i: int) -> void:
	if on and not _picked.has(i):
		_picked.append(i)
	elif not on:
		_picked.erase(i)
	_refresh()


func _on_play(i: int) -> void:
	if bool(menu.call("play_stage", _stages[i])):
		close()
	else:
		_status.text = tr("MENU_DEBUG_NO_CABINET")


func _on_start() -> void:
	if bool(menu.call("apply_shift", _picked_stages())):
		close()
	else:
		_status.text = tr("MENU_DEBUG_NO_CABINET_KEPT")   # the choice waits for the next New Vigil


func _on_reset() -> void:
	if bool(menu.call("reset_shift")):
		close()
		return
	_pick_active()
	for i in _toggles.size():
		_toggles[i].set_pressed_no_signal(_picked.has(i))
	_refresh()
	_status.text = tr("MENU_DEBUG_RESET_DONE")
