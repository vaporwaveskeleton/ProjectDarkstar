extends GdUnitTestSuite
## Attract mode: primary action focus (the coin door until a credit is in), focus loop without dead ends, settings modal with
## ui_cancel and focus restoration, repeated input, safe area at 200 % text, no raw keys.

const SCENE := "res://scenes/attract/attract_mode.tscn"

var host: FakeRouteHost


func before_test() -> void:
	host = FakeRouteHost.install(self)
	SettingsService.persist = false


func after_test() -> void:
	FakeRouteHost.uninstall(host)
	UiTheme.apply_text_scale(1.0)
	SettingsService.persist = true


func _focus() -> Control:
	return get_viewport().gui_get_focus_owner()


func test_primary_action_has_focus_on_open() -> void:
	var runner := scene_runner(SCENE)
	await runner.simulate_frames(2)
	assert_object(_focus()).is_same(runner.find_child("CoinSlot"))


func test_focus_loop_reaches_every_button_and_wraps() -> void:
	var runner := scene_runner(SCENE)
	await runner.simulate_frames(2)
	var seen: Array[String] = []
	for i in 3:
		seen.append(_focus().name)
		runner.simulate_action_pressed("ui_down")
		await runner.await_input_processed()
	assert_array(seen).is_equal(["CoinSlot", "Settings", "Quit"])
	assert_str(_focus().name).is_equal("CoinSlot")
	runner.simulate_action_pressed("ui_up")
	await runner.await_input_processed()
	assert_str(_focus().name).is_equal("Quit")


func test_settings_opens_modal_and_ui_cancel_restores_focus() -> void:
	var runner := scene_runner(SCENE)
	await runner.simulate_frames(2)
	runner.simulate_action_pressed("ui_down")
	await runner.await_input_processed()
	runner.simulate_action_pressed("ui_accept")
	await runner.simulate_frames(2)
	var stack: ScreenStack = runner.find_child("Overlays")
	assert_int(stack.depth()).is_equal(1)
	assert_str(_focus().name).is_equal("Back")
	runner.simulate_action_pressed("ui_cancel")
	await runner.simulate_frames(2)
	assert_int(stack.depth()).is_equal(0)
	assert_str(_focus().name).is_equal("Settings")


func test_ui_cancel_on_root_screen_does_nothing() -> void:
	var runner := scene_runner(SCENE)
	await runner.simulate_frames(2)
	runner.simulate_action_pressed("ui_cancel")
	await runner.simulate_frames(2)
	assert_bool(is_instance_valid(runner.scene())).is_true()
	assert_str(_focus().name).is_equal("CoinSlot")



func test_all_buttons_inside_safe_area_at_200_percent_text() -> void:
	SettingsService.set_value(&"text_scale", 2.0)
	var runner := scene_runner(SCENE)
	await runner.simulate_frames(3)
	var view: Rect2 = runner.scene().get_viewport_rect()
	for name in ["Logo", "Pages", "NewVigil", "Settings", "Quit", "CoinSlot"]:
		var c: Control = runner.find_child(name)
		assert_bool(view.encloses(c.get_global_rect())).override_failure_message("%s outside %s: %s" % [name, view, c.get_global_rect()]).is_true()
	SettingsService.set_value(&"text_scale", 1.0)


func test_settings_panel_inside_safe_area_at_200_percent_text() -> void:
	SettingsService.set_value(&"text_scale", 2.0)
	var runner := scene_runner(SCENE)
	await runner.simulate_frames(2)
	runner.invoke("open_settings")
	await runner.simulate_frames(3)
	var panel: Control = runner.find_child("Panel")
	var view: Rect2 = runner.scene().get_viewport_rect()
	assert_bool(view.encloses(panel.get_global_rect())).override_failure_message("settings panel %s exceeds %s" % [panel.get_global_rect(), view]).is_true()
	SettingsService.set_value(&"text_scale", 1.0)




func test_visible_text_is_never_a_raw_key() -> void:
	var runner := scene_runner(SCENE)
	await runner.simulate_frames(2)
	for name in ["NewVigil", "Settings", "Quit"]:
		var c: Control = runner.find_child(name)
		var shown: String = c.atr(c.text)
		assert_bool(RegEx.create_from_string("^[A-Z][A-Z0-9_]+_[A-Z0-9_]+$").search(shown) == null).override_failure_message("%s shows raw key %s" % [name, shown]).is_true()
