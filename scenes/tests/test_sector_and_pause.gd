extends GdUnitTestSuite
## Sector stub + pause flow: Vigil spawned from the reusable scene, HUD text, pause always
## available (Steady Ledger W4-07), modal stacking, safe default focus on destructive confirm.

const SCENE := "res://scenes/sector/sector_stub.tscn"

var host: FakeRouteHost


func before_test() -> void:
	host = FakeRouteHost.install(self)
	SettingsService.persist = false


func after_test() -> void:
	get_tree().paused = false
	FakeRouteHost.uninstall(host)
	SettingsService.persist = true


func _focus() -> Control:
	return get_viewport().gui_get_focus_owner()


func test_vigil_spawns_at_anchor_with_hud() -> void:
	var runner := scene_runner(SCENE)
	await runner.simulate_frames(2)
	var vigil: Vigil = runner.get_property("vigil")
	assert_object(vigil).is_not_null()
	assert_vector(vigil.global_position).is_equal(Vector2(320, 180))
	var hud: Label = runner.find_child("HullLabel")
	assert_str(hud.text).is_equal("Hull 1")


func test_pause_action_opens_pause_and_pauses_tree() -> void:
	var runner := scene_runner(SCENE)
	await runner.simulate_frames(2)
	runner.simulate_action_pressed("pause")
	await runner.simulate_frames(2)
	var stack: ScreenStack = runner.find_child("Overlays")
	assert_int(stack.depth()).is_equal(1)
	assert_bool(get_tree().paused).is_true()
	assert_str(_focus().name).is_equal("Resume")


func test_ui_cancel_and_pause_both_resume() -> void:
	var runner := scene_runner(SCENE)
	await runner.simulate_frames(2)
	var stack: ScreenStack = runner.find_child("Overlays")
	runner.invoke("open_pause")
	await runner.simulate_frames(2)
	runner.simulate_action_pressed("ui_cancel")
	await runner.simulate_frames(2)
	assert_int(stack.depth()).is_equal(0)
	assert_bool(get_tree().paused).is_false()
	runner.invoke("open_pause")
	await runner.simulate_frames(2)
	runner.simulate_action_pressed("pause")
	await runner.simulate_frames(2)
	assert_int(stack.depth()).is_equal(0)
	assert_bool(get_tree().paused).is_false()


func test_abandon_confirm_defaults_to_safe_choice_and_cancel_restores_focus() -> void:
	var runner := scene_runner(SCENE)
	await runner.simulate_frames(2)
	var stack: ScreenStack = runner.find_child("Overlays")
	runner.invoke("open_pause")
	await runner.simulate_frames(2)
	(runner.find_child("Abandon") as Button).grab_focus()
	runner.simulate_action_pressed("ui_accept")
	await runner.simulate_frames(2)
	assert_int(stack.depth()).is_equal(2)
	assert_str(_focus().name).is_equal("Cancel")
	runner.simulate_action_pressed("ui_cancel")
	await runner.simulate_frames(2)
	assert_int(stack.depth()).is_equal(1)
	assert_str(_focus().name).is_equal("Abandon")
	assert_bool(get_tree().paused).is_true()


func test_confirmed_abandon_routes_to_attract_and_unpauses() -> void:
	var runner := scene_runner(SCENE)
	await runner.simulate_frames(2)
	runner.invoke("open_pause")
	await runner.simulate_frames(2)
	(runner.find_child("Abandon") as Button).pressed.emit()
	await runner.simulate_frames(2)
	(runner.find_child("Confirm") as Button).pressed.emit()
	await runner.simulate_frames(4)
	assert_bool(get_tree().paused).is_false()
	assert_array(host.mounted_routes).is_equal(["res://scenes/attract/attract_mode.tscn"])


func test_settings_from_pause_stacks_three_deep_and_unwinds() -> void:
	var runner := scene_runner(SCENE)
	await runner.simulate_frames(2)
	var stack: ScreenStack = runner.find_child("Overlays")
	runner.invoke("open_pause")
	await runner.simulate_frames(2)
	(runner.find_child("Settings") as Button).pressed.emit()
	await runner.simulate_frames(2)
	assert_int(stack.depth()).is_equal(2)
	for i in 2:
		runner.simulate_action_pressed("ui_cancel")
		await runner.simulate_frames(2)
	assert_int(stack.depth()).is_equal(0)
	assert_bool(get_tree().paused).is_false()
