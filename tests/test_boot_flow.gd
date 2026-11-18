extends GdUnitTestSuite
## Routing: route table integrity, unknown routes fail safely, input-mode tracking.
## The full boot -> attract -> sector path is the headless smoke test (`-- --smoke`), because it
## needs Boot to be the real main scene.


func test_every_route_points_at_a_loadable_scene() -> void:
	var table := load(SceneRouter.TABLE_PATH) as RouteTable
	assert_object(table).is_not_null()
	assert_bool(table.has_route(table.initial_route)).is_true()
	for id in table.routes:
		var packed := load(table.path_for(id)) as PackedScene
		assert_object(packed).override_failure_message("route %s does not load" % id).is_not_null()


func test_unknown_route_fails_without_changing_scene() -> void:
	var reasons: Array[StringName] = []
	var cb := func(_id, reason): reasons.append(reason)
	SceneRouter.route_failed.connect(cb)
	assert_bool(SceneRouter.go_to(&"no_such_route")).is_false()
	SceneRouter.route_failed.disconnect(cb)
	assert_array(reasons).is_equal([&"unknown_route"])
	assert_bool(SceneRouter.is_busy).is_false()
	assert_str(PlayerMessages.route_message(&"unknown_route")).is_not_equal("MSG_SCREEN_FAILED")


func test_input_mode_switches_between_devices() -> void:
	var t: InputModeTracker = auto_free(InputModeTracker.new())
	var modes: Array = []
	t.input_mode_changed.connect(func(m): modes.append(m))
	var pad := InputEventJoypadButton.new()
	pad.pressed = true
	t.feed(pad)
	var drift := InputEventJoypadMotion.new()
	drift.axis_value = 0.1
	t.feed(drift)   # below threshold: ignored
	var key := InputEventKey.new()
	key.pressed = true
	t.feed(key)
	assert_array(modes).is_equal([InputModeTracker.Mode.GAMEPAD, InputModeTracker.Mode.KEYBOARD_MOUSE])


func test_default_settings_match_accessibility_rules() -> void:
	# WARP-001 §4.4: Steady Ledger ships ON. GDD §10: photosensitivity is opt-in presentation only.
	assert_bool(SettingsService.DEFAULTS[&"steady_ledger"]).is_true()
	assert_float(SettingsService.DEFAULTS[&"text_scale"]).is_equal(1.0)
