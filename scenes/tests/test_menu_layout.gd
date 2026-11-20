extends GdUnitTestSuite
## The overlay menus' layout and navigation (UI-001 §10): Settings tab rail and pages, Pause, Confirm,
## in both costumes (MenuSkin CABINET for Act 0, BRASS for the Aether). Focus rings without dead
## ends, rail <-> page moves, real ui_* input, safe area at 200 % text on every page, ON/OFF never
## colour alone, no raw keys and no missing glyphs, the cabinet cursor holds still under reduced motion.

const SETTINGS := preload("res://scenes/settings/settings_screen.tscn")
const PAUSE := preload("res://scenes/sector/pause_screen.tscn")
const KINDS := [MenuSkin.Kind.CABINET, MenuSkin.Kind.BRASS]
const RAW_KEY := "^[A-Z][A-Z0-9_]+_[A-Z0-9_]+$"

var _saved_values: Dictionary = {}
var _saved_persist: bool


func before_test() -> void:
	_saved_persist = SettingsService.persist
	SettingsService.persist = false
	for key in SettingsService.DEFAULTS:
		_saved_values[key] = SettingsService.get_value(key)
	SettingsService.reset_to_defaults()


func after_test() -> void:
	MenuSkin.forced = -1
	for key in _saved_values:
		SettingsService.set_value(key, _saved_values[key])
	SettingsService.persist = _saved_persist


func _focus() -> Control:
	return get_viewport().gui_get_focus_owner()


## Screens open inside a 640×360 viewport, the logical frame (TECH-001 §1.1), so the safe-area checks are real.
func _host() -> SubViewport:
	var vp: SubViewport = auto_free(SubViewport.new())
	vp.size = Vector2i(640, 360)
	vp.gui_disable_input = false
	add_child(vp)
	return vp


func _open(scene: PackedScene, kind: int = MenuSkin.Kind.CABINET) -> Screen:
	MenuSkin.forced = kind
	var s: Screen = auto_free(scene.instantiate())
	_host().add_child(s)
	return s


func _confirm(kind: int = MenuSkin.Kind.CABINET) -> ConfirmScreen:
	MenuSkin.forced = kind
	var s: ConfirmScreen = auto_free(ConfirmScreen.create("CONFIRM_ABANDON_TITLE", "CONFIRM_ABANDON_BODY",
		"CONFIRM_ABANDON_YES", "CONFIRM_KEEP_PLAYING"))
	_host().add_child(s)
	return s


func _n(s: Node, unique: String) -> Control:
	return s.get_node("%" + unique) as Control


func _assert_ring(s: Node, ring: Array[String]) -> void:
	for i in ring.size():
		var c := _n(s, ring[i])
		var next := _n(s, ring[(i + 1) % ring.size()])
		var prev := _n(s, ring[(i - 1 + ring.size()) % ring.size()])
		assert_object(c.get_node(c.focus_neighbor_bottom)).override_failure_message("%s down" % ring[i]).is_same(next)
		assert_object(c.get_node(c.focus_neighbor_top)).override_failure_message("%s up" % ring[i]).is_same(prev)


# ---------------------------------------------------------------- settings structure

func test_settings_rail_is_a_closed_wrapping_ring_and_opens_on_accessibility() -> void:
	var s := _open(SETTINGS)
	_assert_ring(s, ["TabAccessibility", "TabVideo", "TabAudio", "TabControls", "Back"] as Array[String])
	assert_str(s.default_focus.name).is_equal("TabAccessibility")
	assert_bool(_n(s, "PageAccessibility").visible).is_true()
	assert_bool(_n(s, "PageVideo").visible).is_false()
	assert_bool(_n(s, "PageControls").visible).is_false()
	assert_bool((_n(s, "TabAccessibility") as MenuRow).active).is_true()
	assert_bool(s.cancel_closes).is_true()


func test_every_page_is_a_ring_and_left_returns_to_its_tab() -> void:
	var s := _open(SETTINGS)
	var pages := {
		0: ["LargeText", "ReducedMotion", "Photosensitivity", "SteadyLedger"],
		1: ["MuzzleFlash"],
		2: ["VolMaster", "VolMusic", "VolChoir", "VolEntity", "VolUi", "VolFoley"],
		3: ["BindMove", "BindAim", "BindFire", "BindCharge", "BindSurgelight", "BindLantern", "BindBrake", "BindCodex", "BindPause"],
	}
	var tabs := ["TabAccessibility", "TabVideo", "TabAudio", "TabControls"]
	for i: int in pages:
		s.call("show_page", i)
		var ring: Array[String] = []
		ring.assign(pages[i])
		_assert_ring(s, ring)
		var names: Array[String] = []
		for c: Control in s.call("page_rows", i):
			names.append(String(c.name))
		assert_array(names).is_equal(ring)
		for row_name in ring:
			var c := _n(s, row_name)
			assert_object(c.get_node(c.focus_neighbor_left)).is_same(_n(s, tabs[i]))
		for rail_name in tabs + ["Back"]:
			var r := _n(s, rail_name)
			assert_object(r.get_node(r.focus_neighbor_right)).override_failure_message("%s right on page %d" % [rail_name, i]).is_same(_n(s, ring[0]))


func test_controls_header_is_not_a_focus_stop() -> void:
	var s := _open(SETTINGS)
	assert_int(_n(s, "BindHeader").focus_mode).is_equal(Control.FOCUS_NONE)


# ---------------------------------------------------------------- real input

func test_keyboard_walk_through_tabs_pages_and_back_out() -> void:
	var runner := scene_runner(SETTINGS.resource_path)
	await runner.simulate_frames(3)
	assert_str(_focus().name).is_equal("TabAccessibility")
	runner.simulate_action_pressed("ui_down")
	await runner.simulate_frames(2)
	assert_str(_focus().name).is_equal("TabVideo")
	assert_bool((runner.find_child("PageVideo") as Control).visible).is_true()
	assert_bool((runner.find_child("PageAccessibility") as Control).visible).is_false()
	runner.simulate_action_pressed("ui_right")
	await runner.simulate_frames(2)
	assert_str(_focus().name).is_equal("MuzzleFlash")
	runner.simulate_action_pressed("ui_left")
	await runner.simulate_frames(2)
	assert_str(_focus().name).is_equal("TabVideo")
	runner.simulate_action_pressed("ui_up")
	await runner.simulate_frames(2)
	runner.simulate_action_pressed("ui_up")
	await runner.simulate_frames(2)
	assert_str(_focus().name).is_equal("Back")


func test_accept_on_a_tab_steps_into_its_page_and_accept_on_a_row_toggles_it() -> void:
	var runner := scene_runner(SETTINGS.resource_path)
	await runner.simulate_frames(3)
	runner.simulate_action_pressed("ui_accept")
	await runner.simulate_frames(2)
	assert_str(_focus().name).is_equal("LargeText")
	runner.simulate_action_pressed("ui_down")
	await runner.simulate_frames(2)
	assert_str(_focus().name).is_equal("ReducedMotion")
	assert_bool(SettingsService.get_value(&"reduced_motion")).is_false()
	runner.simulate_action_pressed("ui_accept")
	await runner.simulate_frames(2)
	assert_bool(SettingsService.get_value(&"reduced_motion")).is_true()
	var row := runner.find_child("ReducedMotion") as MenuRow
	assert_str(row.value_shown()).is_equal(MenuSkin.shown(tr("SETTINGS_ON"), row.kind))


func test_focused_row_is_described_under_the_page() -> void:
	var s := _open(SETTINGS)
	await await_idle_frame()
	_n(s, "SteadyLedger").grab_focus()
	await await_idle_frame()
	assert_str(String((_n(s, "Desc") as MenuText).key)).is_equal("SETTINGS_STEADY_LEDGER_DESC")
	_n(s, "Back").grab_focus()
	await await_idle_frame()
	assert_str((_n(s, "Desc") as MenuText).shown_text()).is_empty()


# ---------------------------------------------------------------- values and text

func test_toggles_print_on_and_off_from_the_service() -> void:
	SettingsService.set_value(&"steady_ledger", true)
	SettingsService.set_value(&"photosensitivity", false)
	var s := _open(SETTINGS, MenuSkin.Kind.BRASS)
	assert_str((_n(s, "SteadyLedger") as MenuRow).value_shown()).is_equal(tr("SETTINGS_ON"))
	assert_str((_n(s, "Photosensitivity") as MenuRow).value_shown()).is_equal(tr("SETTINGS_OFF"))
	SettingsService.set_value(&"photosensitivity", true)   # changed elsewhere: the row follows live
	assert_str((_n(s, "Photosensitivity") as MenuRow).value_shown()).is_equal(tr("SETTINGS_ON"))


func test_cabinet_prints_upper_case_and_brass_prints_the_text_as_written() -> void:
	var cab := _open(SETTINGS, MenuSkin.Kind.CABINET)
	assert_str((_n(cab, "LargeText") as MenuRow).label_text()).is_equal(tr("SETTINGS_LARGE_TEXT").to_upper())
	assert_bool(_n(cab, "Subtitle").visible).is_true()
	var brass := _open(SETTINGS, MenuSkin.Kind.BRASS)
	assert_str((_n(brass, "LargeText") as MenuRow).label_text()).is_equal(tr("SETTINGS_LARGE_TEXT"))
	assert_bool(_n(brass, "Subtitle").visible).is_false()


func test_no_raw_keys_and_no_missing_glyphs_on_any_menu_in_either_costume() -> void:
	var re := RegEx.create_from_string(RAW_KEY)
	for kind: int in KINDS:
		var screens: Array[Node] = [_open(SETTINGS, kind), _open(PAUSE, kind), _confirm(kind)]
		var settings := screens[0]
		for i in 4:
			settings.call("show_page", i)
			for c: Control in settings.call("page_rows", i):
				c.grab_focus()   # every description is printed once
				await await_idle_frame()
				_check_texts(settings, re, kind)
		for s in screens:
			_check_texts(s, re, kind)


func _check_texts(root: Node, re: RegEx, kind: int) -> void:
	for t: Node in root.find_children("*", "MenuText", true, false):
		var mt := t as MenuText
		var shown := mt.shown_text()
		if shown == "":
			continue
		assert_bool(re.search(shown) == null).override_failure_message("%s prints raw key '%s' (kind %d)" % [mt.get_path(), shown, kind]).is_true()
		assert_array(Array(mt.get_layout().missing)).override_failure_message("%s misses glyphs in '%s'" % [mt.get_path(), shown]).is_empty()


func test_controls_reference_prints_a_binding_for_every_row() -> void:
	var s := _open(SETTINGS)
	for row_name in ["BindMove", "BindAim", "BindFire", "BindCharge", "BindSurgelight", "BindLantern", "BindBrake", "BindCodex", "BindPause"]:
		var row := _n(s, row_name) as MenuRow
		assert_str(row.value_text.strip_edges()).override_failure_message("%s keys" % row_name).is_not_empty()
		assert_str(row.value_text_2.strip_edges()).override_failure_message("%s pad" % row_name).is_not_empty()
	assert_str((_n(s, "BindAim") as MenuRow).value_text).is_equal(tr("ATTRACT_MOUSE"))


# ---------------------------------------------------------------- safe area at 200 %

func test_every_page_and_menu_fits_the_screen_at_200_percent_text() -> void:
	SettingsService.set_value(&"text_scale", 2.0)
	for kind: int in KINDS:
		var s := _open(SETTINGS, kind)
		for i in 4:
			s.call("show_page", i)
			await await_idle_frame()
			await await_idle_frame()
			_assert_inside(s, "settings page %d kind %d" % [i, kind])
			for c: Control in s.call("page_rows", i) + [_n(s, "TabAccessibility"), _n(s, "Back")]:
				c.grab_focus()
				await await_idle_frame()
				await await_idle_frame()
				var view := s.get_viewport_rect()
				assert_bool(view.encloses(c.get_global_rect())).override_failure_message("%s at %s leaves %s (kind %d)" % [c.name, c.get_global_rect(), view, kind]).is_true()
		s.queue_free()
		var p := _open(PAUSE, kind)
		await await_idle_frame()
		await await_idle_frame()
		_assert_inside(p, "pause kind %d" % kind)
		p.queue_free()
		var cf := _confirm(kind)
		await await_idle_frame()
		await await_idle_frame()
		_assert_inside(cf, "confirm kind %d" % kind)
		cf.queue_free()


func _assert_inside(s: Node, what: String) -> void:
	var panel := s.get_node("Center/Panel") as Control
	var view := (s as Control).get_viewport_rect()
	assert_bool(view.encloses(panel.get_global_rect())).override_failure_message("%s panel %s exceeds %s" % [what, panel.get_global_rect(), view]).is_true()


func test_settings_panel_is_wider_than_the_old_220_px_column() -> void:
	var s := _open(SETTINGS)
	await await_idle_frame()
	assert_float((s.get_node("Center/Panel") as Control).size.x).is_greater(400.0)


# ---------------------------------------------------------------- pause and confirm

func test_pause_ring_and_default_focus_in_both_costumes() -> void:
	for kind: int in KINDS:
		var s := _open(PAUSE, kind)
		_assert_ring(s, ["Resume", "Settings", "Abandon"] as Array[String])
		assert_str(s.default_focus.name).is_equal("Resume")


func test_ruins_pause_prints_leave_for_the_title() -> void:
	MenuSkin.forced = MenuSkin.Kind.BRASS
	var s: Screen = auto_free(PAUSE.instantiate())
	s.set("leave_to_title", true)
	_host().add_child(s)
	assert_str((_n(s, "Abandon") as MenuRow).label_text()).is_equal(tr("MENU_LEAVE_TO_TITLE"))


func test_confirm_defaults_to_the_safe_choice_and_left_right_swap() -> void:
	for kind: int in KINDS:
		var s := _confirm(kind)
		assert_str(s.default_focus.name).is_equal("Cancel")
		var cancel := _n(s, "Cancel")
		var ok := _n(s, "Confirm")
		assert_object(cancel.get_node(cancel.focus_neighbor_right)).is_same(ok)
		assert_object(ok.get_node(ok.focus_neighbor_left)).is_same(cancel)
		assert_str((ok as MenuRow).label_text()).is_equal(MenuSkin.shown(tr("CONFIRM_ABANDON_YES"), kind))


# ---------------------------------------------------------------- reduced motion

func test_cabinet_cursor_blinks_only_without_reduced_motion() -> void:
	var s := _open(SETTINGS, MenuSkin.Kind.CABINET)
	await await_idle_frame()   # the screen grabs its default focus deferred
	var row := _n(s, "TabVideo") as MenuRow
	row.grab_focus()
	await await_idle_frame()
	assert_bool(row.is_processing()).is_true()
	SettingsService.set_value(&"reduced_motion", true)
	assert_bool(row.is_processing()).is_false()
	SettingsService.set_value(&"reduced_motion", false)
	SettingsService.set_value(&"photosensitivity", true)
	assert_bool(row.is_processing()).is_false()
	var brass := _open(SETTINGS, MenuSkin.Kind.BRASS)
	SettingsService.set_value(&"photosensitivity", false)
	await await_idle_frame()
	(_n(brass, "TabVideo") as MenuRow).grab_focus()
	await await_idle_frame()
	assert_bool((_n(brass, "TabVideo") as MenuRow).is_processing()).is_false()


# ---------------------------------------------------------------- costume

func test_the_screen_stack_names_the_costume_and_auto_follows_the_ladder() -> void:
	var saved_t := Look.t
	Look.t = 0.0
	for costume: int in [0, 1, 2]:
		var st: ScreenStack = auto_free(ScreenStack.new())
		st.costume = costume
		add_child(st)
		var s := st.push(SETTINGS.instantiate() as Screen)
		var want := MenuSkin.Kind.BRASS if costume == 2 else MenuSkin.Kind.CABINET
		assert_int((s.get_node("%LargeText") as MenuRow).kind).override_failure_message("costume %d" % costume).is_equal(want)
		assert_int((s.get_node("Center/Panel") as MenuFrame).kind).is_equal(want)
	Look.t = 1.0
	var auto: ScreenStack = auto_free(ScreenStack.new())
	add_child(auto)
	var s2 := auto.push(PAUSE.instantiate() as Screen)
	assert_int((s2.get_node("%Resume") as MenuRow).kind).is_equal(MenuSkin.Kind.BRASS)
	Look.t = saved_t


func test_aether_scenes_dress_their_menus_in_brass() -> void:
	for path in ["res://scenes/sector/sector_stub.tscn", "res://scenes/ruins/ruins.tscn"]:
		var state := (load(path) as PackedScene).get_state()
		var found := false
		for i in state.get_node_count():
			if state.get_node_name(i) != &"Overlays":
				continue
			for p in state.get_node_property_count(i):
				if state.get_node_property_name(i, p) == &"costume":
					found = true
					assert_int(int(state.get_node_property_value(i, p))).is_equal(2)
		assert_bool(found).override_failure_message("%s Overlays has no costume" % path).is_true()


func test_every_menu_shows_its_art_at_100_percent_text() -> void:
	for kind: int in KINDS:
		var screens: Array[Node] = [_open(SETTINGS, kind), _open(PAUSE, kind), _confirm(kind)]
		await await_idle_frame()
		await await_idle_frame()
		for s in screens:
			var orn := s.get_node("%Ornament") as MenuOrnament
			var side := minf(orn.size.x, orn.size.y)
			assert_float(side).override_failure_message("%s ornament %s (kind %d)" % [s.name, orn.size, kind]).is_greater_equal(MenuOrnament.MIN_SIDE)
