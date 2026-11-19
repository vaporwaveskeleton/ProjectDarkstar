extends GdUnitTestSuite
## The printed-glass bezel (owner direction 2026-11-18): the glass over the field and columns never
## covers the screen hole at any window size, it follows the peel, the print is nudged out of register
## deterministically, and the cartoon vent plates and starburst are real parts now.

const SCREEN := Rect2(192, 28, 256, 304)    ## the hole in rig units
const SIZES: Array[Vector2i] = [Vector2i(1920, 1080), Vector2i(2560, 1440), Vector2i(3440, 1440), Vector2i(1280, 800), Vector2i(1366, 768)]


func test_glass_never_covers_the_hole_and_tiles_the_window() -> void:
	var spec := load("res://data/cabinet/cabinet_screen.tres") as CabinetScreenSpec
	for win in SIZES:
		var area := ScreenFit.bezel_rect(win, spec.grid)
		var covered := 0.0
		for r in BezelField.glass_rects(area, 0.0):
			covered += r.get_area()
			assert_bool(r.intersects(SCREEN)).override_failure_message("%s overlaps the hole at %s" % [r, win]).is_false()
			assert_bool(area.encloses(r)).override_failure_message("%s leaves the window at %s" % [r, win]).is_true()
		assert_float(covered + SCREEN.get_area()).is_equal_approx(area.get_area(), 0.5)


func test_glass_slides_away_with_the_peel_and_stays_off_the_hole() -> void:
	var area := Rect2(Vector2.ZERO, Vector2(ScreenFit.REF))
	for peel in [0.25, 0.5, 1.0]:
		for r in BezelField.glass_rects(area, peel):
			assert_bool(r.intersects(SCREEN)).is_false()
	var a := BezelField.glass_rects(area, 0.0)
	var b := BezelField.glass_rects(area, 0.5)
	assert_float(b[4].position.x).is_less(a[4].position.x)     # left column goes left
	assert_float(b[5].position.x).is_greater(a[5].position.x)  # right column goes right


func test_glass_node_follows_peel_and_hides_when_gone() -> void:
	var glass := BezelGlass.new()
	add_child(glass)
	auto_free(glass)
	glass.set_area(Rect2(Vector2.ZERO, Vector2(ScreenFit.REF)))
	assert_int(glass.rects().size()).is_equal(6)
	glass.peel = 1.0
	assert_bool(glass.visible).is_false()
	var mat := glass.material as ShaderMaterial
	var door: Vector4 = mat.get_shader_parameter(&"door_rect")
	assert_float(door.x).is_equal(CabinetBezel.coin_plate().position.x + CabinetBezel.SIDE + 20.0)


func test_columns_carry_real_vents_and_the_right_one_a_sticker() -> void:
	var left := BezelPrint.new()
	var right := BezelPrint.new()
	right.column = &"right"
	add_child(left)
	add_child(right)
	auto_free(left)
	auto_free(right)
	var lv := 0
	for c in left.get_children():
		if c is BezelVent:
			lv += 1
		assert_bool(c is BezelSticker).is_false()
	assert_int(lv).is_equal(2)
	var rv := 0
	var stickers := 0
	for c in right.get_children():
		if c is BezelVent:
			rv += 1
		if c is BezelSticker:
			stickers += 1
			assert_object((c as BezelSticker).sticker_rect()).is_equal(CabinetBezel.RIGHT_STICKER)
	assert_int(rv).is_equal(3)
	assert_int(stickers).is_equal(1)
	# the flat cartoon parts are gone from the piece lists
	for p in BezelArt.build_left() + BezelArt.build_right():
		var id := String(p.id)
		assert_bool(id.contains("cap_") or id.contains("sticker") or id.contains("glare") or id.contains("apron")).override_failure_message(id).is_false()


func test_plate_misregistration_is_deterministic_small_and_spares_the_key_plate() -> void:
	var p := BezelPrint.new()
	add_child(p)
	auto_free(p)
	var s := load("res://data/cabinet/cabinet_surface.tres") as CabinetSurface
	assert_object(p.plate_offset(&"key_black")).is_equal(Vector2.ZERO)
	var moved := 0
	for ink in [&"navy", &"yellow", &"cyan", &"magenta", &"orange", &"cream"]:
		var o := p.plate_offset(ink)
		assert_object(o).is_equal(p.plate_offset(ink))
		assert_float(absf(o.x)).is_less_equal(s.print_misregister + 0.001)
		assert_float(absf(o.y)).is_less_equal(s.print_misregister + 0.001)
		if o != Vector2.ZERO:
			moved += 1
	assert_int(moved).is_greater(3)


func test_field_uses_the_print_material_and_keeps_six_paint_rects() -> void:
	var field := BezelField.new()
	add_child(field)
	auto_free(field)
	assert_object(field.material).is_not_null()
	assert_int(field.painted().size()).is_equal(6)
	field.peel = 1.0
	assert_bool(field.visible).is_false()
