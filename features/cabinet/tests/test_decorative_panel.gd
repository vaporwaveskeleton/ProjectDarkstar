extends GdUnitTestSuite
## The in-game bezel carries the same control panel as the attract bezel, as decoration only (Q-T34 consistency):
## START and SERVICE unlit buttons and the POWER rocker, none focusable, none taking the mouse, never over the screen hole.

const GAME_SCENE := "res://features/cabinet/cabinet_game.tscn"
const SIZES: Array[Vector2i] = [Vector2i(1920, 1080), Vector2i(2560, 1440), Vector2i(3440, 1440), Vector2i(1280, 800), Vector2i(1366, 768)]


func _panel_in_game() -> ControlPanel:
	var scene := (load(GAME_SCENE) as PackedScene).instantiate()
	add_child(scene)
	auto_free(scene)
	await get_tree().process_frame
	return scene.find_child("ControlPanel", true, false) as ControlPanel


func test_the_game_bezel_has_the_panel_with_two_unlit_buttons_and_a_rocker() -> void:
	var panel := await _panel_in_game()
	assert_object(panel).is_not_null()
	assert_int(panel.buttons().size()).is_equal(2)
	assert_int(panel.buttons()[0].kind).is_equal(ArcadeButton.Kind.START)
	for b in panel.buttons():
		assert_float(b.lamp_level()).is_equal(0.0)
		assert_bool(b.lamp_on).is_false()
	assert_str(panel.buttons()[0].label_text()).is_equal(tr("MENU_NEW_VIGIL").to_upper())


func test_nothing_in_the_game_panel_is_focusable_or_takes_input() -> void:
	var panel := await _panel_in_game()
	assert_int(panel.mouse_filter).is_equal(Control.MOUSE_FILTER_IGNORE)
	for b in panel.buttons():
		assert_int(b.focus_mode).is_equal(Control.FOCUS_NONE)
		assert_int(b.mouse_filter).is_equal(Control.MOUSE_FILTER_IGNORE)
	# nothing under the Hud or its panel can be focused
	var stack: Array[Node] = [panel]
	while not stack.is_empty():
		var n: Node = stack.pop_back()
		if n is Control:
			assert_int((n as Control).focus_mode).override_failure_message("%s is focusable" % n.name).is_equal(Control.FOCUS_NONE)
		stack.append_array(n.get_children())


func test_the_game_panel_matches_the_attract_panel_and_never_meets_the_hole_at_the_five_sizes() -> void:
	var panel := await _panel_in_game()
	var spec := load("res://data/cabinet/cabinet_screen.tres") as CabinetScreenSpec
	var rect := Rect2(panel.position, panel.size)
	assert_object(rect).is_equal(CabinetBezel.control_panel())
	for win in SIZES:
		var area := ScreenFit.bezel_rect(win, spec.grid)
		assert_bool(area.encloses(rect)).override_failure_message("panel outside the window at %s" % win).is_true()
		assert_bool(rect.intersects(CabinetBezel.hole())).override_failure_message("panel over the hole at %s" % win).is_false()
		for b in panel.buttons():
			var r := Rect2(b.position + panel.position, b.size)
			assert_bool(r.intersects(CabinetBezel.hole())).override_failure_message("button over the hole at %s" % win).is_false()
			assert_bool(rect.grow(0.01).encloses(r)).is_true()


func test_the_game_panel_goes_with_the_peel() -> void:
	var scene := (load(GAME_SCENE) as PackedScene).instantiate()
	add_child(scene)
	auto_free(scene)
	await get_tree().process_frame
	var panel := scene.find_child("ControlPanel", true, false) as ControlPanel
	var hud := scene.find_child("Hud", true, false) as CabinetHud
	hud.peel = 1.0
	assert_bool(panel.visible).is_false()
