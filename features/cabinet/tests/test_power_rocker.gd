extends GdUnitTestSuite
## The POWER rocker, the panel captions, the angled control panel surface, the decal wear and the hazard tape
## material (PR C pass 2c): geometry at the five test sizes, the captions' text and place, the in-game copy, the
## shaders, and the new strings.

const SIZES: Array[Vector2i] = [Vector2i(1920, 1080), Vector2i(2560, 1440), Vector2i(3440, 1440), Vector2i(1280, 800), Vector2i(1366, 768)]


func after_test() -> void:
	SettingsService.set_value(&"text_scale", 1.0)


func _rocker(decorative: bool = false) -> PowerRocker:
	var host := Control.new()
	add_child(host)
	auto_free(host)
	var r := PowerRocker.new()
	r.decorative = decorative
	host.add_child(r)
	return r


func test_the_rocker_never_meets_the_door_the_vents_or_the_hole_at_the_five_sizes() -> void:
	var spec := load("res://data/cabinet/cabinet_screen.tres") as CabinetScreenSpec
	var rect := CabinetBezel.power_rocker()
	var right_x := CabinetBezel.right_x()
	var vents: Array[Rect2] = [Rect2(2.0, 0.0, 78.0, 10.0), CabinetBezel.APRON_VENT_LOCAL, Rect2(2.0, 350.0, 78.0, 10.0)]
	assert_bool(CabinetBezel.coin_plate().intersects(rect)).override_failure_message("rocker over the coin door").is_false()
	for v in vents:
		assert_bool(Rect2(v.position + Vector2(right_x, 0.0), v.size).intersects(rect)).override_failure_message("rocker over vent %s" % v).is_false()
	assert_bool(CabinetBezel.APRON_VENT_LOCAL.size.x > 0.0 and CabinetBezel.APRON_VENT_LOCAL.end.y <= CabinetBezel.POWER_LOCAL.end.y + 0.01).is_true()
	assert_bool(Rect2(right_x, 0.0, CabinetBezel.SIDE, 360.0).encloses(rect)).override_failure_message("rocker leaves the column").is_true()
	for win in SIZES:
		var area := ScreenFit.bezel_rect(win, spec.grid)
		assert_bool(area.encloses(rect)).override_failure_message("rocker outside the window at %s" % win).is_true()
		assert_bool(rect.intersects(CabinetBezel.hole())).override_failure_message("rocker over the hole at %s" % win).is_false()
		assert_bool(rect.intersects(CabinetBezel.control_panel())).override_failure_message("rocker over the panel at %s" % win).is_false()


func test_decal_housing_and_label_fit_the_module() -> void:
	var r := _rocker()
	await get_tree().process_frame
	var box := Rect2(Vector2.ZERO, r.size)
	assert_bool(box.encloses(r.housing_rect())).is_true()
	assert_bool(box.encloses(r.label_rect())).is_true()
	assert_bool(r.label_rect().intersects(r.housing_rect())).is_false()
	assert_str(r.label_text()).is_equal(tr("CAB_PANEL_POWER").to_upper())
	assert_str(r.label_text()).is_not_equal("CAB_PANEL_POWER")


func test_it_is_a_real_focusable_basebutton() -> void:
	var r := _rocker()
	await get_tree().process_frame
	assert_bool(r is BaseButton).is_true()
	assert_int(r.focus_mode).is_equal(Control.FOCUS_ALL)
	assert_int(r.mouse_filter).is_equal(Control.MOUSE_FILTER_STOP)
	assert_str(r.face_material().shader.resource_path).is_equal("res://shaders/cabinet/power_rocker.gdshader")


func test_the_in_game_rocker_is_inert() -> void:
	var r := _rocker(true)
	await get_tree().process_frame
	assert_int(r.focus_mode).is_equal(Control.FOCUS_NONE)
	assert_int(r.mouse_filter).is_equal(Control.MOUSE_FILTER_IGNORE)
	r.emit_signal("mouse_entered")
	await get_tree().process_frame
	assert_bool(r.caption_visible()).is_false()


func test_throwing_it_off_flips_the_paddle() -> void:
	var r := _rocker()
	await get_tree().process_frame
	assert_float(r.flip_level()).is_equal(0.0)
	r.throw_off()
	for i in 30:
		r._process(0.02)
	assert_float(r.flip_level()).is_equal(1.0)


func test_captions_sit_on_the_panel_strip_never_over_the_screen_at_both_text_sizes() -> void:
	var panel := CabinetBezel.control_panel()
	for scale in [1.0, 2.0]:
		SettingsService.set_value(&"text_scale", scale)
		var r := _rocker()
		await get_tree().process_frame
		var cap := r.caption_rect()
		cap.position += CabinetBezel.power_rocker().position
		assert_bool(panel.encloses(cap)).override_failure_message("POWER caption %s outside the panel %s at %s" % [cap, panel, scale]).is_true()
		assert_bool(cap.intersects(CabinetBezel.hole())).is_false()
		var svc := ArcadeButton.new()
		svc.kind = ArcadeButton.Kind.SERVICE
		svc.slot = 1
		svc.label_key = "CAB_PANEL_SERVICE"
		svc.caption_key = "CAB_PANEL_SERVICE_HINT"
		var cp := ControlPanel.new()
		add_child(cp)
		auto_free(cp)
		cp.add_child(svc)
		await get_tree().process_frame
		var sr := svc.caption_rect()
		sr.position += cp.position + svc.position
		assert_bool(panel.encloses(sr)).override_failure_message("SERVICE caption %s outside the panel at %s" % [sr, scale]).is_true()
		assert_bool(sr.intersects(CabinetBezel.hole())).is_false()


func test_caption_text_is_plain_language_through_tr() -> void:
	assert_str(tr("CAB_PANEL_SERVICE_HINT")).is_equal("Settings")
	assert_str(tr("CAB_PANEL_POWER_HINT")).is_equal("Quit game")
	assert_str(tr("CAB_PANEL_SERVICE")).is_equal("SERVICE")
	assert_str(tr("CAB_PANEL_POWER")).is_equal("POWER")
	for k in ["CONFIRM_QUIT_TITLE", "CONFIRM_QUIT_BODY", "CONFIRM_QUIT_YES", "CONFIRM_QUIT_STAY"]:
		assert_str(tr(k)).is_not_equal(k)


func test_every_new_key_is_in_the_english_po() -> void:
	var po := FileAccess.get_file_as_string("res://locale/en.po")
	for k in ["CAB_PANEL_SERVICE", "CAB_PANEL_SERVICE_HINT", "CAB_PANEL_POWER", "CAB_PANEL_POWER_HINT", "CONFIRM_QUIT_TITLE", "CONFIRM_QUIT_BODY", "CONFIRM_QUIT_YES", "CONFIRM_QUIT_STAY"]:
		assert_bool(po.contains('msgid "%s"' % k)).override_failure_message("%s missing from en.po" % k).is_true()


func test_the_panel_slab_is_its_own_angled_laminate_with_contact_shadows() -> void:
	var panel := ControlPanel.new()
	auto_free(panel)
	for i in 2:
		var b := ArcadeButton.new()
		b.kind = ArcadeButton.Kind.START if i == 0 else ArcadeButton.Kind.SERVICE
		b.slot = i
		b.label_key = "MENU_NEW_VIGIL"
		panel.add_child(b)
	add_child(panel)
	await get_tree().process_frame
	var mat := panel.slab_material()
	assert_str(mat.shader.resource_path).is_equal("res://shaders/cabinet/control_panel.gdshader")
	assert_int(int(mat.get_shader_parameter(&"btn_n"))).is_equal(2)
	var src := FileAccess.get_file_as_string("res://shaders/cabinet/control_panel.gdshader")
	for word in ["lip", "front_shadow", "contact", "palm"]:
		assert_bool(src.contains("uniform float %s" % word)).override_failure_message("slab shader lacks %s" % word).is_true()
	assert_bool(src.contains("cabinet_material.gdshaderinc")).is_true()


func test_the_start_decal_is_worn_more_than_the_service_decal() -> void:
	var surf := CabinetSurface.default() as CabinetSurface
	assert_float(surf.start_decal_rub).is_greater(surf.decal_rub)
	assert_float(surf.start_decal_rub).is_less(0.7)         # half rubbed off, still legible
	var panel := ControlPanel.new()
	add_child(panel)
	auto_free(panel)
	var b := ArcadeButton.new()
	b.kind = ArcadeButton.Kind.START
	b.label_key = "MENU_NEW_VIGIL"
	panel.add_child(b)
	await get_tree().process_frame
	assert_float(float(b._decal_mat.get_shader_parameter(&"rub"))).is_equal(surf.start_decal_rub)
	assert_str(b._decal_mat.shader.resource_path).is_equal("res://shaders/cabinet/panel_decal.gdshader")


func test_the_hazard_tape_is_printed_vinyl_with_edges_dirt_and_a_crease() -> void:
	var src := FileAccess.get_file_as_string("res://shaders/cabinet/hazard_tape.gdshader")
	for word in ["sheen", "misreg", "edge_lift", "dirt", "crease_amt"]:
		assert_bool(src.contains("uniform float %s" % word)).override_failure_message("tape shader lacks %s" % word).is_true()
	var slot := CoinSlot.new()
	slot.tuning = load("res://data/cabinet/cabinet_boot_tuning.tres") as CabinetBootTuning
	add_child(slot)
	auto_free(slot)
	await get_tree().process_frame
	await get_tree().process_frame
	var strips: Array[TapeStrip] = []
	for c in slot.get_children():
		if c is TapeStrip:
			strips.append(c)
	assert_int(strips.size()).is_equal(2)
	assert_bool(strips[0].visible).is_true()               # the stuck length is drawn
	assert_bool(strips[1].visible).is_false()              # no flap until it is pulled
	assert_float(float((strips[0].material as ShaderMaterial).get_shader_parameter(&"crease_on"))).is_equal(1.0)
	assert_float(float((strips[0].material as ShaderMaterial).get_shader_parameter(&"face_up"))).is_equal(1.0)


func test_the_peeled_flap_shows_its_adhesive_side() -> void:
	var slot := CoinSlot.new()
	slot.tuning = load("res://data/cabinet/cabinet_boot_tuning.tres") as CabinetBootTuning
	add_child(slot)
	auto_free(slot)
	await get_tree().process_frame
	slot._set_peel(0.5)
	await get_tree().process_frame
	await get_tree().process_frame
	var flap: TapeStrip = null
	for c in slot.get_children():
		if c is TapeStrip and not (c as TapeStrip).material.get_shader_parameter(&"face_up") > 0.5:
			flap = c
	assert_object(flap).is_not_null()
	assert_bool(flap.visible).is_true()


func test_the_tape_hit_area_and_peel_behaviour_are_unchanged() -> void:
	assert_vector(CoinSlot.TAPE_A).is_equal(Vector2(-3, 38))
	assert_vector(CoinSlot.TAPE_B).is_equal(Vector2(59, 10))
	assert_float(CoinSlot.TAPE_W).is_equal(11.0)


func test_the_game_bezel_carries_an_inert_rocker_that_goes_with_the_peel() -> void:
	var scene := (load("res://features/cabinet/cabinet_game.tscn") as PackedScene).instantiate()
	add_child(scene)
	auto_free(scene)
	await get_tree().process_frame
	await get_tree().process_frame
	var r := scene.find_child("PowerRocker", true, false) as PowerRocker
	assert_object(r).is_not_null()
	assert_bool(r.decorative).is_true()
	assert_int(r.focus_mode).is_equal(Control.FOCUS_NONE)
	assert_vector(r.position).is_equal(CabinetBezel.power_rocker().position)
	var hud := scene.find_child("Hud", true, false) as CabinetHud
	hud.peel = 0.5
	await get_tree().process_frame
	assert_float(r.position.x).is_greater(CabinetBezel.power_rocker().position.x)
	hud.peel = 1.0
	await get_tree().process_frame
	assert_bool(r.visible).is_false()
