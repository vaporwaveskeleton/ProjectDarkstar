extends GdUnitTestSuite
## The Settings Audio tab (UI-001 §10, AUDIO-001 §8.4): six volume sliders in the doc's order and
## words, in both costumes, with a closed focus ring, left/right to step, Back to leave a slider,
## the entity floor, live bus effect and the preview cue. Settings are isolated from the real
## user:// (persist off; restored after each case).

const SETTINGS := preload("res://scenes/settings/settings_screen.tscn")
const ROWS: Array[String] = ["VolMaster", "VolMusic", "VolChoir", "VolEntity", "VolUi", "VolFoley"]
const LABELS: Array[String] = ["Master", "Music", "Choir", "Entity voice", "UI and readouts", "Foley and ambience"]
const AUDIO_PAGE := 2

var _saved_persist: bool
var _saved: Dictionary = {}


func before_test() -> void:
	_saved_persist = SettingsService.persist
	SettingsService.persist = false
	for key in SettingsService.DEFAULTS:
		_saved[key] = SettingsService.get_value(key)
	SettingsService.reset_to_defaults()


func after_test() -> void:
	MenuSkin.forced = -1
	for key in _saved:
		SettingsService.set_value(key, _saved[key])
	SettingsService.persist = _saved_persist
	AudioService.stop_all()


func _focus() -> Control:
	return get_viewport().gui_get_focus_owner()


func _open(kind: int = MenuSkin.Kind.CABINET) -> Screen:
	MenuSkin.forced = kind
	var vp: SubViewport = auto_free(SubViewport.new())
	vp.size = Vector2i(640, 360)
	vp.gui_disable_input = false
	add_child(vp)
	var s: Screen = auto_free(SETTINGS.instantiate())
	vp.add_child(s)
	return s


func _row(s: Node, n: String) -> MenuRow:
	return s.get_node("%" + n) as MenuRow


func test_the_audio_tab_sits_between_video_and_controls() -> void:
	var s := _open()
	var tabs: Array[String] = []
	for t: Node in s.get_node("%Rail").get_children():
		if t is MenuRow and (t as MenuRow).style == MenuRow.Style.TAB:
			tabs.append(String(t.name))
	assert_array(tabs).is_equal(["TabAccessibility", "TabVideo", "TabAudio", "TabControls"])


func test_page_lists_the_six_sliders_in_audio_001_order_with_plain_words() -> void:
	for kind: int in [MenuSkin.Kind.CABINET, MenuSkin.Kind.BRASS]:
		var s := _open(kind)
		s.call("show_page", AUDIO_PAGE)
		var names: Array[String] = []
		for c: Control in s.call("page_rows", AUDIO_PAGE):
			names.append(String(c.name))
		assert_array(names).is_equal(ROWS)
		for i in ROWS.size():
			var row := _row(s, ROWS[i])
			assert_int(row.style).is_equal(MenuRow.Style.SLIDER)
			assert_str(row.label_text()).is_equal(MenuSkin.shown(LABELS[i], kind))
			assert_str(tr(String(row.desc_key))).is_not_equal(String(row.desc_key))
		assert_str(String((_row(s, "TabAudio")).key)).is_equal("SETTINGS_TAB_AUDIO")


func test_rows_show_the_service_values_and_follow_changes_made_elsewhere() -> void:
	var s := _open()
	assert_int(_row(s, "VolMaster").value).is_equal(70)
	assert_str(_row(s, "VolMaster").value_shown()).is_equal("70")
	assert_int(_row(s, "VolChoir").value).is_equal(100)
	SettingsService.set_value(&"vol_music", 35)
	assert_int(_row(s, "VolMusic").value).is_equal(35)
	assert_str(_row(s, "VolMusic").value_shown()).is_equal("35")


func test_the_page_is_a_wrapping_ring_and_left_on_the_page_names_the_tab() -> void:
	var s := _open()
	for i in ROWS.size():
		var c := _row(s, ROWS[i])
		var next := _row(s, ROWS[(i + 1) % ROWS.size()])
		var prev := _row(s, ROWS[(i - 1 + ROWS.size()) % ROWS.size()])
		assert_object(c.get_node(c.focus_neighbor_bottom)).is_same(next)
		assert_object(c.get_node(c.focus_neighbor_top)).is_same(prev)
	s.call("show_page", AUDIO_PAGE)
	assert_object(_row(s, "TabAudio").get_node(_row(s, "TabAudio").focus_neighbor_right)).is_same(_row(s, "VolMaster"))


func test_keyboard_left_right_step_a_slider_and_the_bus_follows() -> void:
	var runner := scene_runner(SETTINGS.resource_path)
	await runner.simulate_frames(3)
	for i in 2:
		runner.simulate_action_pressed("ui_down")
		await runner.simulate_frames(2)
	assert_str(_focus().name).is_equal("TabAudio")
	runner.simulate_action_pressed("ui_accept")
	await runner.simulate_frames(2)
	assert_str(_focus().name).is_equal("VolMaster")
	runner.simulate_action_pressed("ui_left")
	await runner.simulate_frames(2)
	assert_str(_focus().name).is_equal("VolMaster")   # left steps the slider; it does not leave the page
	assert_int(SettingsService.get_value(&"vol_master")).is_equal(70 - UserVolume.STEP)
	assert_float(AudioServer.get_bus_volume_db(AudioServer.get_bus_index(&"Master"))).is_equal_approx(UserVolume.to_db(65), 0.1)
	runner.simulate_action_pressed("ui_right")
	runner.simulate_action_pressed("ui_right")
	await runner.simulate_frames(2)
	assert_int(SettingsService.get_value(&"vol_master")).is_equal(75)


func test_the_entity_slider_stops_at_its_floor() -> void:
	var s := _open()
	var row := _row(s, "VolEntity")
	assert_int(row.floor_value).is_equal(40)
	row.set_slider(0)
	assert_int(SettingsService.get_value(&"vol_entity")).is_equal(40)
	assert_int(row.value).is_equal(40)
	assert_str(row.value_shown()).is_equal("40")


func test_a_slider_at_zero_mutes_its_bus_and_the_screen_shows_the_zero() -> void:
	var s := _open()
	_row(s, "VolMusic").set_slider(0)
	assert_int(SettingsService.get_value(&"vol_music")).is_equal(0)
	assert_str(_row(s, "VolMusic").value_shown()).is_equal("0")
	assert_bool(AudioServer.is_bus_mute(AudioServer.get_bus_index(&"BUS-MUS"))).is_true()


func test_back_on_a_slider_returns_to_its_tab_and_back_on_the_tab_closes() -> void:
	var s := _open()
	await await_idle_frame()   # the screen grabs its default focus deferred
	s.call("show_page", AUDIO_PAGE)
	_row(s, "VolMusic").grab_focus()
	await await_idle_frame()
	s.call("cancel")
	await await_idle_frame()
	assert_str(_focus_in(s).name).is_equal("TabAudio")
	assert_bool(is_instance_valid(s) and not s.is_queued_for_deletion()).is_true()
	s.call("cancel")   # on the tab, Back closes as every overlay does
	assert_bool(s.is_queued_for_deletion()).is_true()


func test_a_change_queues_one_preview_for_the_sliders_own_cue() -> void:
	var s := _open()
	var timer: Timer = null
	for c in s.get_children():
		if c is Timer:
			timer = c
	assert_object(timer).is_not_null()
	_row(s, "VolUi").set_slider(80)
	assert_float(timer.time_left).is_greater(0.0)
	assert_str(String(s.get("_preview_key"))).is_equal("vol_ui")
	AudioService.muted_for_tests = false
	AudioService.stop_all()
	s.call("_play_preview")
	assert_int(AudioService.active_count(&"menu_move")).is_equal(1)


func test_every_audio_string_is_translated_not_a_raw_key() -> void:
	for key in ["SETTINGS_TAB_AUDIO", "SETTINGS_TAB_AUDIO_DESC", "SETTINGS_VOL_MASTER", "SETTINGS_VOL_MUSIC",
			"SETTINGS_VOL_CHOIR", "SETTINGS_VOL_ENTITY", "SETTINGS_VOL_UI", "SETTINGS_VOL_FOLEY"]:
		assert_str(tr(key)).override_failure_message(key).is_not_equal(key)
		if key.begins_with("SETTINGS_VOL_"):
			assert_str(tr(key + "_DESC")).override_failure_message(key + "_DESC").is_not_equal(key + "_DESC")


func _focus_in(s: Node) -> Control:
	return s.get_viewport().gui_get_focus_owner()
