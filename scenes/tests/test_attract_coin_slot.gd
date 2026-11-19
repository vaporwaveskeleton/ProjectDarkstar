extends GdUnitTestSuite
## The Cabinet's power-on test, instruction cards and taped coin door (owner request 2026-11-18):
## prompt timing, peel by hold and by drag, coin → credit → New Vigil, the tape staying off,
## the power-on path and its skip, and the binding labels the cards print.

const SCENE := "res://scenes/attract/attract_mode.tscn"

var host: FakeRouteHost
var _saved_backend: SaveBackend


func before_test() -> void:
	host = FakeRouteHost.install(self)
	SettingsService.persist = false
	_saved_backend = SaveService.backend
	SaveService.set_backend(MemorySaveBackend.new())
	AudioService.muted_for_tests = true


func after_test() -> void:
	FakeRouteHost.uninstall(host)
	SaveService.set_backend(_saved_backend)
	SettingsService.persist = true
	AudioService.muted_for_tests = false


func _focus() -> Control:
	return get_viewport().gui_get_focus_owner()


func _open(runner: GdUnitSceneRunner) -> CoinSlot:
	var scene: Node = runner.scene()
	scene.set("demo_enabled", false)
	await runner.simulate_frames(2)
	return runner.find_child("CoinSlot") as CoinSlot


func _step(coin: CoinSlot, seconds: float, dt: float = 0.05) -> void:
	var t := 0.0
	while t < seconds:
		coin._process(dt)
		t += dt


func _accept(pressed: bool) -> InputEventAction:
	var ev := InputEventAction.new()
	ev.action = &"ui_accept"
	ev.pressed = pressed
	return ev


func test_coin_door_has_focus_and_new_vigil_waits_for_a_credit() -> void:
	var runner := scene_runner(SCENE)
	var coin := await _open(runner)
	assert_object(_focus()).is_same(coin)
	assert_bool((runner.find_child("NewVigil") as ArcadeButton).disabled).is_true()
	assert_int(coin.phase).is_equal(CoinSlot.Phase.TAPED)


func test_focus_loop_without_credit_wraps_through_the_coin_door() -> void:
	var runner := scene_runner(SCENE)
	await _open(runner)
	var seen: Array[String] = []
	for i in 3:
		seen.append(_focus().name)
		runner.simulate_action_pressed("ui_down")
		await runner.await_input_processed()
	assert_array(seen).is_equal(["CoinSlot", "Settings", "Power"])
	assert_str(_focus().name).is_equal("CoinSlot")


func test_prompt_appears_only_after_the_delay() -> void:
	var runner := scene_runner(SCENE)
	var coin := await _open(runner)
	_step(coin, coin.tuning.tape_hint_delay * 0.5)
	assert_bool(coin.hint_visible).is_false()
	_step(coin, coin.tuning.tape_hint_delay * 0.6)
	assert_bool(coin.hint_visible).is_true()
	coin.gamepad = false
	assert_str(coin.hint_text()).is_equal(tr("CAB_HINT_PEEL_DRAG"))
	coin.gamepad = true
	assert_str(coin.hint_text()).contains(InputLabels.accept(true))


func test_holding_accept_peels_the_tape_and_saves_it() -> void:
	var runner := scene_runner(SCENE)
	var coin := await _open(runner)
	var peeled := [false]
	coin.tape_peeled.connect(func() -> void: peeled[0] = true)
	coin._gui_input(_accept(true))
	_step(coin, coin.tuning.tape_hold_seconds * 0.5)
	assert_float(coin.peel).is_between(0.3, 0.7)
	coin._gui_input(_accept(false))          # let go half way: the flap stays half peeled
	_step(coin, 0.5)
	assert_float(coin.peel).is_between(0.3, 0.7)
	coin._gui_input(_accept(true))
	_step(coin, coin.tuning.tape_hold_seconds)
	assert_bool(peeled[0]).is_true()
	assert_int(coin.phase).is_not_equal(CoinSlot.Phase.TAPED)
	var saved := SaveService.load_slot(&"profile")
	assert_bool(bool((saved.payload as Dictionary).get("cabinet_tape_peeled", false))).is_true()
	# the press that finished the peel must not also drop a coin
	coin._gui_input(_accept(true))
	_step(coin, coin.tuning.tape_fall_seconds + 0.1)
	assert_int(coin.phase).is_equal(CoinSlot.Phase.OPEN)


func test_dragging_the_tape_with_the_mouse_peels_it() -> void:
	var runner := scene_runner(SCENE)
	var coin := await _open(runner)
	var press := InputEventMouseButton.new()
	press.button_index = MOUSE_BUTTON_LEFT
	press.pressed = true
	press.position = CoinSlot.TAPE_A.lerp(CoinSlot.TAPE_B, 0.1)
	coin._gui_input(press)
	var miss := InputEventMouseButton.new()
	var move := InputEventMouseMotion.new()
	move.position = press.position + Vector2(-coin.tuning.tape_drag_px * 0.5, 0)
	coin._gui_input(move)
	assert_float(coin.peel).is_between(0.4, 0.6)
	move.position = press.position + Vector2(-coin.tuning.tape_drag_px * 1.2, 10)
	coin._gui_input(move)
	assert_int(coin.phase).is_equal(CoinSlot.Phase.FALLING)
	miss.button_index = MOUSE_BUTTON_LEFT
	miss.pressed = false
	coin._gui_input(miss)


func test_a_press_away_from_the_tape_does_not_grab_it() -> void:
	var runner := scene_runner(SCENE)
	var coin := await _open(runner)
	var press := InputEventMouseButton.new()
	press.button_index = MOUSE_BUTTON_LEFT
	press.pressed = true
	press.position = Vector2(4, 76)
	coin._gui_input(press)
	var move := InputEventMouseMotion.new()
	move.position = Vector2(-60, 76)
	coin._gui_input(move)
	assert_float(coin.peel).is_equal(0.0)


func test_coin_gives_one_credit_then_new_vigil_spends_it() -> void:
	var runner := scene_runner(SCENE)
	var coin := await _open(runner)
	coin.set_peeled()
	assert_bool(coin.insert()).is_true()
	assert_bool(coin.insert()).is_false()      # one coin at a time
	_step(coin, coin.tuning.coin_drop_seconds + 0.1)
	assert_bool(coin.has_credit()).is_true()
	await runner.simulate_frames(2)
	var btn: ArcadeButton = runner.find_child("NewVigil")
	assert_bool(btn.disabled).is_false()
	assert_object(_focus()).is_same(btn)
	assert_str((runner.find_child("StripHud") as CabinetScreenHud).credit_line).is_equal(tr("CAB_CREDIT_COUNT") % 1)
	btn.pressed.emit()
	btn.pressed.emit()
	btn.pressed.emit()
	assert_bool(btn.disabled).is_true()
	await runner.simulate_frames(5)
	assert_array(host.mounted_routes).is_equal(["res://features/cabinet/cabinet_game.tscn"])
	assert_bool(coin.has_credit()).is_false()


func test_new_vigil_without_a_credit_does_nothing() -> void:
	var runner := scene_runner(SCENE)
	await _open(runner)
	(runner.find_child("NewVigil") as ArcadeButton).pressed.emit()
	await runner.simulate_frames(5)
	assert_array(host.mounted_routes).is_empty()


func test_tape_stays_off_once_peeled() -> void:
	SaveService.save_slot(&"profile", {"cabinet_tape_peeled": true}, &"cabinet_tape")
	var runner := scene_runner(SCENE)
	var coin := await _open(runner)
	assert_int(coin.phase).is_equal(CoinSlot.Phase.OPEN)
	coin.gamepad = true
	_step(coin, coin.tuning.tape_hint_delay + 0.1)
	assert_str(coin.hint_text()).contains(InputLabels.accept(true))
	coin._gui_input(_accept(true))
	assert_int(coin.phase).is_equal(CoinSlot.Phase.DROPPING)


func test_no_demo_while_a_credit_is_waiting() -> void:
	var runner := scene_runner(SCENE)
	var coin := await _open(runner)
	runner.scene().set("demo_enabled", true)
	coin.set_peeled()
	coin.insert()
	_step(coin, coin.tuning.coin_drop_seconds + 0.1)
	runner.scene().set("idle", 29.9)
	await runner.simulate_frames(3)
	assert_float(float(runner.scene().get("idle"))).is_equal(0.0)
	assert_array(host.mounted_routes).is_empty()


func test_power_on_runs_hides_the_prompt_and_any_key_skips() -> void:
	var runner := scene_runner(SCENE)
	var coin := await _open(runner)
	var power: PowerOnTest = runner.find_child("PowerOn")
	runner.scene().call("on_route_entered", {"power_on": true})
	assert_bool(power.running).is_true()
	assert_bool(coin.hint_armed).is_false()
	assert_float(power.total_seconds()).is_less(10.0)
	var key := InputEventKey.new()
	key.keycode = KEY_SPACE
	key.pressed = true
	Input.parse_input_event(key)
	await runner.simulate_frames(3)
	assert_bool(power.running).is_false()
	assert_bool(coin.hint_armed).is_true()
	assert_int(coin.phase).is_equal(CoinSlot.Phase.TAPED)   # the skip press did not reach the tape


func test_power_on_finishes_by_itself() -> void:
	var runner := scene_runner(SCENE)
	await _open(runner)
	var power: PowerOnTest = runner.find_child("PowerOn")
	power.start()
	var t := 0.0
	while power.running and t < 20.0:
		power._process(0.1)
		t += 0.1
	assert_bool(power.running).is_false()
	assert_float(t).is_equal_approx(power.total_seconds(), 0.15)


func test_route_without_power_on_skips_the_test() -> void:
	var runner := scene_runner(SCENE)
	await _open(runner)
	runner.scene().call("on_route_entered", {})
	assert_bool((runner.find_child("PowerOn") as PowerOnTest).running).is_false()


func test_pages_cycle_through_every_card() -> void:
	var runner := scene_runner(SCENE)
	await _open(runner)
	var pages: AttractPages = runner.find_child("Pages")
	var seen := {}
	for i in AttractPages.Page.size() + 1:
		seen[pages.page] = true
		pages._process(pages.tuning.page_seconds + 0.01)
	assert_int(seen.size()).is_equal(AttractPages.Page.size())


func test_binding_labels_follow_the_device() -> void:
	assert_str(InputLabels.action(&"fire_lance", false)).is_equal(tr("ATTRACT_MOUSE_LEFT"))
	assert_str(InputLabels.action(&"fire_lance", true)).is_equal(tr("ATTRACT_PAD_RT"))
	assert_str(InputLabels.accept(true)).is_equal(tr("ATTRACT_PAD_A"))
	assert_str(InputLabels.vector(&"move_left", &"move_right", &"move_up", &"move_down", false)).is_equal("WASD")
	assert_str(InputLabels.vector(&"move_left", &"move_right", &"move_up", &"move_down", true)).is_equal(tr("ATTRACT_PAD_LSTICK"))
	assert_str(InputLabels.action(&"surgelight", false)).is_equal("SHIFT")


func test_pad_face_button_peels_like_accept() -> void:
	var runner := scene_runner(SCENE)
	var coin := await _open(runner)
	var a := InputEventJoypadButton.new()
	a.button_index = JOY_BUTTON_A
	a.pressed = true
	coin._gui_input(a)
	_step(coin, coin.tuning.tape_hold_seconds + 0.05)
	assert_int(coin.phase).is_not_equal(CoinSlot.Phase.TAPED)
