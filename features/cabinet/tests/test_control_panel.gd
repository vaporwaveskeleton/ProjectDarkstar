extends GdUnitTestSuite
## The Cabinet's control panel (Q-T34): the strip under the screen, the three ArcadeButton pushbuttons in it,
## their lamp, press, focus and disabled behaviour, and the shader that draws them.

const SPEC := "res://data/cabinet/cabinet_screen.tres"
const SHADER_PATH := "res://shaders/cabinet/arcade_button.gdshader"


func _button(kind: ArcadeButton.Kind, key: String = "MENU_SETTINGS") -> ArcadeButton:
	var panel := ControlPanel.new()
	add_child(panel)
	auto_free(panel)
	var b := ArcadeButton.new()
	b.kind = kind
	b.label_key = key
	b.slot = 0 if kind == ArcadeButton.Kind.START else 1
	panel.add_child(b)
	return b


func after_test() -> void:
	SettingsService.set_value(&"photosensitivity", false)
	SettingsService.set_value(&"reduced_motion", false)


func test_the_panel_is_the_strip_under_the_hole_across_its_width() -> void:
	var hole := CabinetBezel.hole()
	var p := CabinetBezel.control_panel()
	assert_float(p.position.x).is_equal(hole.position.x)
	assert_float(p.size.x).is_equal(hole.size.x)
	assert_float(p.position.y).is_equal(hole.end.y + CabinetBezel.EDGE)
	assert_float(p.end.y).is_equal(float(ScreenFit.REF.y))
	assert_bool(p.intersects(hole)).is_false()


func test_nothing_else_lives_in_the_strip() -> void:
	var p := CabinetBezel.control_panel()
	assert_bool(p.intersects(CabinetBezel.coin_plate())).is_false()
	assert_bool(p.intersects(CabinetBezel.marquee())).is_false()
	for r in [Rect2(CabinetBezel.left_x(), 0.0, CabinetBezel.SIDE, float(ScreenFit.REF.y)), Rect2(CabinetBezel.right_x(), 0.0, CabinetBezel.SIDE, float(ScreenFit.REF.y))]:
		assert_bool(p.intersects(r)).override_failure_message("the panel runs into a printed column").is_false()


func test_the_slots_sit_inside_the_panel_and_never_overlap() -> void:
	var p := CabinetBezel.control_panel()
	for i in 3:
		assert_bool(p.encloses(CabinetBezel.panel_slot(i))).override_failure_message("slot %d outside the panel" % i).is_true()
		for j in range(i + 1, 3):
			assert_bool(CabinetBezel.panel_slot(i).intersects(CabinetBezel.panel_slot(j))).is_false()


func test_cap_label_and_ring_fit_the_slot() -> void:
	for kind in [ArcadeButton.Kind.START, ArcadeButton.Kind.SERVICE]:
		var b := _button(kind)
		b.size = Vector2(36.0, 26.0)
		var cap := b.cap_rect()
		var ring := cap.grow(0.45 + 1.5)
		assert_bool(Rect2(Vector2.ZERO, b.size).encloses(ring)).override_failure_message("ring %s leaves the slot %s" % [ring, b.size]).is_true()
		assert_bool(Rect2(Vector2.ZERO, b.size).encloses(b.label_rect())).override_failure_message("label %s leaves the slot" % b.label_rect()).is_true()
		assert_float(b.label_rect().position.y).override_failure_message("label touches the ring").is_greater(ring.end.y)


func test_start_is_the_big_lit_button_and_service_buttons_stay_unlit() -> void:
	assert_float(ArcadeButton.cap_half(ArcadeButton.Kind.START).x).is_greater(ArcadeButton.cap_half(ArcadeButton.Kind.SERVICE).x * 2.0)
	var start := _button(ArcadeButton.Kind.START, "MENU_NEW_VIGIL")
	assert_float(start.lamp_level()).is_equal(0.0)           # dark before a credit
	start.lamp_on = true
	assert_float(start.lamp_level()).is_greater(0.0)
	var service := _button(ArcadeButton.Kind.SERVICE)
	assert_float(service.lamp_level()).is_equal(0.0)


func test_the_start_lamp_blinks_and_holds_steady_with_photosensitivity_or_reduced_motion() -> void:
	var b := _button(ArcadeButton.Kind.START, "MENU_NEW_VIGIL")
	b.lamp_on = true
	b.blinks = true
	var levels := {}
	for i in 40:
		b._t = i * 0.1
		levels[snappedf(b.lamp_level(), 0.01)] = true
	assert_int(levels.size()).is_equal(2)
	assert_float(levels.keys().min()).is_greater(0.0)         # it dims, it never goes fully dark (no hard strobe)
	for key in [&"photosensitivity", &"reduced_motion"]:
		SettingsService.set_value(key, true)
		levels.clear()
		for i in 40:
			b._t = i * 0.1
			levels[snappedf(b.lamp_level(), 0.01)] = true
		assert_int(levels.size()).override_failure_message("lamp blinks with %s on" % key).is_equal(1)
		SettingsService.set_value(key, false)
	assert_float(ArcadeButton.BLINK_HZ).is_less_equal(3.0)


func test_a_disabled_button_does_not_light_and_a_credit_does() -> void:
	var b := _button(ArcadeButton.Kind.START, "MENU_NEW_VIGIL")
	b.lamp_on = true
	assert_float(b.lamp_level()).is_greater(0.0)
	b.disabled = true
	assert_float(b.lamp_level()).is_equal(0.0)


func test_the_button_is_a_real_basebutton_with_focus() -> void:
	var b := _button(ArcadeButton.Kind.SERVICE)
	assert_bool(b is BaseButton).is_true()
	await get_tree().process_frame
	assert_int(b.focus_mode).is_equal(Control.FOCUS_ALL)
	assert_int(b.mouse_filter).is_equal(Control.MOUSE_FILTER_STOP)


func test_the_material_is_the_cabinet_button_shader_with_the_cap_geometry() -> void:
	var b := _button(ArcadeButton.Kind.START, "MENU_NEW_VIGIL")
	await get_tree().process_frame
	var mat := b.face_material()
	assert_str(mat.shader.resource_path).is_equal(SHADER_PATH)
	assert_vector(mat.get_shader_parameter(&"cap_half")).is_equal(ArcadeButton.cap_half(ArcadeButton.Kind.START))
	var src := FileAccess.get_file_as_string(SHADER_PATH)
	assert_bool(src.contains("cabinet_material.gdshaderinc")).is_true()
	for u in ["press", "focus_k", "lamp", "hover_k"]:
		assert_bool(src.contains("uniform float %s" % u)).override_failure_message("shader lacks %s" % u).is_true()


func test_no_text_is_a_raw_key() -> void:
	for pair in [[ArcadeButton.Kind.START, "MENU_NEW_VIGIL"], [ArcadeButton.Kind.SERVICE, "MENU_SETTINGS"], [ArcadeButton.Kind.SERVICE, "MENU_QUIT"]]:
		var b := _button(pair[0], pair[1])
		assert_str(b.label_text()).is_not_equal(pair[1])
		assert_str(b.label_text()).is_equal(tr(pair[1]).to_upper())
