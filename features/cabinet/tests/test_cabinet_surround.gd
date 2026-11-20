extends GdUnitTestSuite
## The surround pass (owner direction 2026-11-19): the wider printed sheet, the small how-to card and the
## defocused ArcadeBackdrop behind the cabinet. The backdrop fills every Steam-survey window beyond the sheet
## (no bars), never paints the sheet or the screen, sits behind every other sheet part, and is generated
## (a shader, no textures).

const SCREEN := Rect2(192, 28, 256, 304)
const SIZES: Array[Vector2i] = [Vector2i(1920, 1080), Vector2i(2560, 1440), Vector2i(3440, 1440), Vector2i(1280, 800),
	Vector2i(2560, 1600), Vector2i(3840, 2160), Vector2i(1920, 1200), Vector2i(1366, 768)]


func _spec() -> CabinetScreenSpec:
	return load("res://data/cabinet/cabinet_screen.tres") as CabinetScreenSpec


## The sheet fills a 16:9 reference but for a sliver of side panel each side, and stays inside it.
func test_the_sheet_fills_a_16_9_window_but_for_the_side_panel() -> void:
	var sx := CabinetBezel.sheet_x()
	assert_float(sx.y - sx.x).is_greater_equal(float(ScreenFit.REF.x) * 0.85)
	assert_float(sx.x).is_greater(0.0)
	assert_float(sx.y).is_less(float(ScreenFit.REF.x))


## Real-bezel proportions: the instruction card is a small fraction of the sheet, in fine print.
func test_the_how_to_card_is_small_with_fine_print() -> void:
	var sx := CabinetBezel.sheet_x()
	var card := CabinetBezel.LEFT_HOWTO
	assert_float(card.size.x).is_less_equal((sx.y - sx.x) * 0.15)
	assert_float(card.size.y).is_less_equal(64.0)
	assert_float(BezelArt.HOWTO_CAP).is_less_equal(4.0)
	assert_float(BezelArt.HOWTO_TITLE_CAP).is_less_equal(5.0)
	assert_bool(Rect2(0, 0, CabinetBezel.SIDE, 360).encloses(card)).is_true()


## The maker's badge sits between the POWER rocker and the pinstripes, inside the column.
func test_the_maker_badge_clears_the_rocker_and_the_stripes() -> void:
	var plate: BezelPiece = null
	for p in BezelArt.build_right():
		if p.id == &"right_maker_plate":
			plate = p
	assert_object(plate).is_not_null()
	var lo := Vector2(INF, INF)
	var hi := Vector2(-INF, -INF)
	for q in plate.points:
		lo = lo.min(q)
		hi = hi.max(q)
	var r := Rect2(lo, hi - lo)
	assert_bool(r.intersects(CabinetBezel.POWER_LOCAL)).is_false()
	assert_float(r.end.x).is_less_equal(CabinetBezel.SIDE - BezelArt.STRIPE_X[BezelArt.STRIPE_X.size() - 1])
	assert_bool(r.intersects(CabinetBezel.COIN_PLATE_LOCAL)).is_false()


## The haunt overlays' anchors (cursed turn): four named rects in rig units, inside the sheet, off the screen.
func test_haunt_anchors_name_the_eye_figure_marquee_and_card() -> void:
	var a := BezelArt.haunt_anchors()
	var sx := CabinetBezel.sheet_x()
	for k: StringName in [&"eye", &"figure", &"marquee_letters", &"how_to_play"]:
		assert_bool(a.has(k)).override_failure_message("missing %s" % k).is_true()
		var r: Rect2 = a[k]
		assert_bool(r.has_area()).override_failure_message("%s is empty" % k).is_true()
		assert_bool(r.intersects(SCREEN)).override_failure_message("%s over the screen" % k).is_false()
		assert_bool(r.position.x >= sx.x and r.end.x <= sx.y).override_failure_message("%s leaves the sheet" % k).is_true()
	assert_bool(CabinetBezel.marquee().encloses(a[&"marquee_letters"])).is_true()
	assert_bool((a[&"eye"] as Rect2).position.x >= CabinetBezel.right_x()).is_true()
	var print_node := BezelPrint.new()
	assert_object(print_node.haunt_anchors()[&"how_to_play"]).is_equal(a[&"how_to_play"])
	print_node.free()


func test_the_marquee_takes_a_lettering_override_and_an_ink_hook() -> void:
	var sign := BezelMarquee.new()
	add_child(sign)
	auto_free(sign)
	var seen: Array[Rect2] = []
	sign.ink_hook = func(_ci: CanvasItem, r: Rect2) -> void: seen.append(r)
	sign.lettering_override = "RAKDSTAR"
	sign.refresh_ink()
	await get_tree().process_frame
	await get_tree().process_frame
	assert_int(seen.size()).is_greater(0)
	assert_bool(Rect2(Vector2.ZERO, sign.size).grow(2.0).encloses(seen[0])).is_true()


func test_the_backdrop_fills_the_window_beyond_the_sheet_at_every_size_and_never_the_sheet() -> void:
	var s := CabinetSurface.default() as CabinetSurface
	var sx := CabinetBezel.sheet_x()
	for win in SIZES:
		var area := ScreenFit.bezel_rect(win, _spec().grid)
		var rects := ArcadeBackdrop.visible_rects(area, s.tmold_width)
		assert_float(rects[0].position.x).is_equal_approx(area.position.x, 0.001)
		assert_float(rects[1].end.x).is_equal_approx(area.end.x, 0.001)
		for r in rects:
			assert_bool(r.intersects(SCREEN)).override_failure_message("backdrop over the screen at %s" % win).is_false()
			assert_bool(r.intersects(Rect2(sx.x, area.position.y, sx.y - sx.x, area.size.y))).override_failure_message("backdrop over the sheet at %s" % win).is_false()
			assert_float(r.size.y).is_equal_approx(area.size.y, 0.001)
	var wide := ScreenFit.bezel_rect(Vector2i(3440, 1440), _spec().grid)
	assert_float(ArcadeBackdrop.visible_rects(wide, s.tmold_width)[0].size.x).is_greater(100.0)


func test_the_backdrop_follows_the_rig_and_sits_behind_the_other_sheet_parts() -> void:
	var host := Control.new()
	add_child(host)
	auto_free(host)
	var parts := BezelAssembly.add_sheet_parts(host, null)
	assert_object(parts[0]).is_instanceof(ArcadeBackdrop)
	assert_object(parts[1]).is_instanceof(CabinetRoom)
	var b := parts[0] as ArcadeBackdrop
	assert_bool(b.show_behind_parent).is_true()
	assert_int(b.get_index()).is_less(parts[1].get_index())
	assert_object(b.get_rect()).is_equal(Rect2(Vector2.ZERO, Vector2(ScreenFit.REF)))
	var area := Rect2(-110, 0, 860, 360)
	b.set_area(area)
	assert_object(b.get_rect()).is_equal(area)
	assert_vector((b.material as ShaderMaterial).get_shader_parameter(&"rig_origin") as Vector2).is_equal(area.position)
	assert_vector((b.material as ShaderMaterial).get_shader_parameter(&"sheet_x") as Vector2).is_equal(CabinetBezel.sheet_x())


func test_the_grain_freezes_with_photosensitivity_on() -> void:
	var b := ArcadeBackdrop.new()
	add_child(b)
	auto_free(b)
	var mat := b.material as ShaderMaterial
	SettingsService.set_value(&"photosensitivity", true)
	assert_float(b.grain_fps()).is_equal(0.0)
	assert_float(float(mat.get_shader_parameter(&"grain_fps"))).is_equal(0.0)
	SettingsService.set_value(&"photosensitivity", false)
	assert_float(b.grain_fps()).is_greater(0.0)
	assert_float(float(mat.get_shader_parameter(&"grain_fps"))).is_greater(0.0)


## Generated art only (D-13/D-14): the backdrop is a shader with no texture samplers and no external files.
func test_the_backdrop_is_generated() -> void:
	var code := FileAccess.get_file_as_string("res://shaders/cabinet/arcade_backdrop.gdshader")
	assert_bool(code.contains("sampler2D")).is_false()
	assert_bool(code.contains("res://assets")).is_false()
	var s := CabinetSurface.default() as CabinetSurface
	assert_int(s.backdrop_neon.size()).is_equal(6)
	assert_float(s.backdrop_exposure).is_less_equal(0.6)       # dim: never pulls focus from the screen
