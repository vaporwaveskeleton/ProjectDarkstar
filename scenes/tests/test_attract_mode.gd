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



func test_everything_inside_safe_area_at_200_percent_text() -> void:
	SettingsService.set_value(&"text_scale", 2.0)
	var runner := scene_runner(SCENE)
	await runner.simulate_frames(3)
	var view := Rect2(Vector2.ZERO, Vector2(ScreenFit.REF))   # the bezel is laid out in reference units
	var rig := runner.find_child("Rig") as Control
	var play := runner.find_child("Play") as Control
	# the cards live on the screen (the play view of the tube); at 200 % they still fit (the buttons are off the screen)
	for name in ["Logo", "Pages"]:
		var c: Control = runner.find_child(name)
		assert_bool(c.is_visible_in_tree()).override_failure_message("%s hidden at 200 %%" % name).is_true()
		assert_bool(play.get_global_rect().encloses(c.get_global_rect())).override_failure_message("%s outside the play view %s: %s" % [name, play.get_global_rect(), c.get_global_rect()]).is_true()
	# the pushbuttons and the coin door are on the bezel, in the window, and the buttons are inside the control panel
	var to_rig: Transform2D = rig.get_global_transform().affine_inverse()
	var panel := CabinetBezel.control_panel()
	for name in ["NewVigil", "Settings", "Quit"]:
		var c: Control = runner.find_child(name)
		var r: Rect2 = to_rig * c.get_global_rect()
		assert_bool(panel.grow(0.01).encloses(r)).override_failure_message("%s outside the control panel %s: %s" % [name, panel, r]).is_true()
	var coin: Control = runner.find_child("CoinSlot")
	var coin_rect: Rect2 = to_rig * coin.get_global_rect()
	assert_bool(view.encloses(coin_rect)).override_failure_message("coin door outside %s: %s" % [view, coin_rect]).is_true()
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




func test_printed_labels_are_never_a_raw_key() -> void:
	var runner := scene_runner(SCENE)
	await runner.simulate_frames(2)
	for name in ["NewVigil", "Settings", "Quit"]:
		var c := runner.find_child(name) as ArcadeButton
		var shown := c.label_text()
		assert_str(shown).is_not_empty()
		assert_str(shown).is_not_equal(c.label_key)
		assert_bool(RegEx.create_from_string("^[A-Z][A-Z0-9_]+_[A-Z0-9_]+$").search(shown) == null).override_failure_message("%s prints raw key %s" % [name, shown]).is_true()


func test_instruction_cards_stay_on_screen_at_200_percent_text() -> void:
	SettingsService.set_value(&"text_scale", 2.0)
	var runner := scene_runner(SCENE)
	await runner.simulate_frames(2)
	assert_bool((runner.find_child("Pages") as Control).is_visible_in_tree()).is_true()
	SettingsService.set_value(&"text_scale", 1.0)


func test_focus_walks_left_and_right_between_the_buttons_and_the_coin_door() -> void:
	var runner := scene_runner(SCENE)
	await runner.simulate_frames(2)
	var coin := runner.find_child("CoinSlot") as CoinSlot
	coin.set_peeled()
	coin.phase = CoinSlot.Phase.CREDITED
	runner.scene().call("_on_credit_inserted")
	await runner.simulate_frames(2)
	var seen: Array[String] = []
	for i in 4:
		seen.append(_focus().name)
		runner.simulate_action_pressed("ui_right")
		await runner.await_input_processed()
	assert_array(seen).is_equal(["NewVigil", "Settings", "Quit", "CoinSlot"])
	assert_str(_focus().name).is_equal("NewVigil")
	runner.simulate_action_pressed("ui_left")
	await runner.await_input_processed()
	assert_str(_focus().name).is_equal("CoinSlot")


func test_accept_presses_the_focused_pushbutton_and_a_disabled_one_ignores_it() -> void:
	var runner := scene_runner(SCENE)
	await runner.simulate_frames(2)
	var settings := runner.find_child("Settings") as ArcadeButton
	var hits := [0]
	settings.pressed.connect(func() -> void: hits[0] += 1)
	settings.grab_focus()
	await runner.simulate_frames(1)
	runner.simulate_action_pressed("ui_accept")
	await runner.simulate_frames(2)
	assert_int(hits[0]).is_equal(1)
	assert_int((runner.find_child("Overlays") as ScreenStack).depth()).is_equal(1)
	runner.simulate_action_pressed("ui_cancel")
	await runner.simulate_frames(2)
	settings.disabled = true
	settings.grab_focus()
	await runner.simulate_frames(1)
	runner.simulate_action_pressed("ui_accept")
	await runner.simulate_frames(2)
	assert_int(hits[0]).is_equal(1)


func test_omen_line_fits_the_screen_at_200_percent_text() -> void:
	var saved := SaveService.backend
	SaveService.set_backend(MemorySaveBackend.new())
	SaveService.save_slot(&"profile", {"act0_complete": true}, &"cabinet_tape")
	SettingsService.set_value(&"text_scale", 2.0)
	var runner := scene_runner(SCENE)
	await runner.simulate_frames(3)
	var omen := runner.find_child("Omen") as Control
	var play := runner.find_child("Play") as Control
	assert_bool(omen.visible).is_true()
	assert_bool(play.get_global_rect().encloses(omen.get_global_rect())).override_failure_message("omen %s outside the play view %s" % [omen.get_global_rect(), play.get_global_rect()]).is_true()
	assert_bool(play.get_global_rect().encloses((runner.find_child("Pages") as Control).get_global_rect())).is_true()
	SettingsService.set_value(&"text_scale", 1.0)
	SaveService.set_backend(saved)


# --- the CONTINUE offer after GAME OVER (Q-T104) -----------------------------------------------------

## A route host that keeps the params the router hands to the scene it mounts.
class ParamHost extends Node:
	var routes: Array[String] = []
	var params: Array[Dictionary] = []

	func mount(scene: Node) -> void:
		routes.append(scene.scene_file_path)
		var stub := GDScript.new()
		stub.source_code = "extends Node\nvar sink\nfunc on_route_entered(p: Dictionary) -> void:\n\tsink.append(p)\n"
		stub.reload()
		scene.set_script(stub)
		scene.set("sink", params)
		scene.queue_free()


func _with_param_host() -> ParamHost:
	FakeRouteHost.uninstall(host)
	host = null
	var h := ParamHost.new()
	add_child(h)
	SceneRouter.register_host(h)
	return h


func _credit(runner: GdUnitSceneRunner) -> CoinSlot:
	var coin := runner.find_child("CoinSlot") as CoinSlot
	coin.set_peeled()
	coin.phase = CoinSlot.Phase.CREDITED
	runner.scene().call("_on_credit_inserted")
	return coin


func test_the_continue_offer_shows_with_the_param() -> void:
	var runner := scene_runner(SCENE)
	await runner.simulate_frames(2)
	runner.scene().call("on_route_entered", {"continue_stage": 1})
	var pages := runner.find_child("Pages") as AttractPages
	assert_int(pages.continue_stage).is_equal(1)
	assert_int(int(runner.scene().get("continue_stage"))).is_equal(1)
	assert_str(tr("CAB_CONTINUE")).is_not_equal("CAB_CONTINUE")
	assert_str(tr("CAB_CONTINUE") % 2).contains("2")
	await runner.simulate_frames(2)


func test_no_param_means_no_offer_and_a_fresh_start() -> void:
	var h := _with_param_host()
	var runner := scene_runner(SCENE)
	await runner.simulate_frames(2)
	runner.scene().call("on_route_entered", {})
	assert_int((runner.find_child("Pages") as AttractPages).continue_stage).is_equal(-1)
	_credit(runner)
	(runner.find_child("NewVigil") as ArcadeButton).pressed.emit()
	await runner.simulate_frames(5)
	assert_array(h.routes).is_equal(["res://features/cabinet/cabinet_game.tscn"])
	assert_bool(h.params[0].has("continue_stage")).is_false()
	SceneRouter.unregister_host(h)
	SceneRouter.is_busy = false
	host = FakeRouteHost.install(self)


func test_start_continues_the_stage_when_the_offer_stands() -> void:
	var h := _with_param_host()
	var runner := scene_runner(SCENE)
	await runner.simulate_frames(2)
	runner.scene().call("on_route_entered", {"continue_stage": 2})
	var coin := _credit(runner)
	await runner.simulate_frames(2)
	assert_object(_focus()).is_same(runner.find_child("NewVigil"))
	(runner.find_child("NewVigil") as ArcadeButton).pressed.emit()
	await runner.simulate_frames(5)
	assert_array(h.routes).is_equal(["res://features/cabinet/cabinet_game.tscn"])
	assert_int(int(h.params[0]["continue_stage"])).is_equal(2)
	assert_bool(coin.has_credit()).is_false()
	SceneRouter.unregister_host(h)
	SceneRouter.is_busy = false
	host = FakeRouteHost.install(self)


func test_the_offer_clears_when_the_attract_reaches_its_demo() -> void:
	var h := _with_param_host()
	var runner := scene_runner(SCENE)
	await runner.simulate_frames(2)
	runner.scene().call("on_route_entered", {"continue_stage": 1})
	runner.scene().set("demo_enabled", true)
	runner.scene().set("idle", 29.9999)
	await runner.simulate_frames(4)
	assert_int(int(runner.scene().get("continue_stage"))).is_equal(-1)
	assert_int((runner.find_child("Pages") as AttractPages).continue_stage).is_equal(-1)
	assert_bool(h.params[0].get("demo", false)).is_true()
	assert_bool(h.params[0].has("continue_stage")).is_false()
	SceneRouter.unregister_host(h)
	SceneRouter.is_busy = false
	host = FakeRouteHost.install(self)
