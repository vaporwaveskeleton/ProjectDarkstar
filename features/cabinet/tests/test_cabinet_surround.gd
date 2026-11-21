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
	for k: StringName in [&"wear_origin", &"figure", &"marquee_letters", &"how_to_play"]:
		assert_bool(a.has(k)).override_failure_message("missing %s" % k).is_true()
		var r: Rect2 = a[k]
		assert_bool(r.has_area()).override_failure_message("%s is empty" % k).is_true()
		assert_bool(r.intersects(SCREEN)).override_failure_message("%s over the screen" % k).is_false()
		assert_bool(r.position.x >= sx.x and r.end.x <= sx.y).override_failure_message("%s leaves the sheet" % k).is_true()
	assert_bool(CabinetBezel.marquee().encloses(a[&"marquee_letters"])).is_true()
	assert_bool((a[&"wear_origin"] as Rect2).position.x >= CabinetBezel.right_x()).is_true()
	assert_bool(a.has(&"eye")).is_false()                       # renamed: the world has no eye (N4)
	var print_node := BezelPrint.new()
	assert_object(print_node.haunt_anchors()[&"how_to_play"]).is_equal(a[&"how_to_play"])
	print_node.free()


func test_the_marquee_takes_an_ink_hook() -> void:
	var sign := BezelMarquee.new()
	add_child(sign)
	auto_free(sign)
	var seen: Array[Rect2] = []
	sign.ink_hook = func(_ci: CanvasItem, r: Rect2) -> void: seen.append(r)
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


## 1983 spot-colour screenprint (Fable review 2026-11-20): six inks plus key black, one keyline width, no glow
## pieces, and the side art's tones stepped to a coarse screen whose dots show at 1920×1080.
func test_the_side_art_is_six_inks_with_keylines_and_a_coarse_stepped_screen() -> void:
	var used := {}
	for p in BezelArt.build_left() + BezelArt.build_right():
		used[p.ink] = true
		assert_bool(p.ink in BezelArt.PRINT_INKS).override_failure_message("%s prints in %s" % [p.id, p.ink]).is_true()
		assert_bool(String(p.id).contains("glow")).override_failure_message(p.id).is_false()
		if p.kind == BezelPiece.Kind.OUTLINE:
			assert_float(p.width).override_failure_message(p.id).is_equal(BezelArt.KEYLINE)
	assert_int(used.size()).is_less_equal(7)
	assert_float(BezelArt.KEYLINE * 3.0).is_between(3.0, 4.0)       # 3–4 px at 1920×1080
	var s := CabinetSurface.default() as CabinetSurface
	assert_float(s.print_art_cell * 3.0).is_greater_equal(6.0)        # dots several pixels across at 1080p
	var col := BezelPrint.new()
	add_child(col)
	auto_free(col)
	var m := col.material as ShaderMaterial
	assert_float(float(m.get_shader_parameter(&"halftone_cell"))).is_equal(s.print_art_cell)
	assert_float(float(m.get_shader_parameter(&"tone_steps"))).is_equal(1.0)
	assert_bool((load("res://shaders/cabinet/bezel_print.gdshader") as Shader).code.contains("tone_steps")).is_true()


## Every coloured shape of the illustrations carries a key-black keyline (fills keyed by default).
func test_the_hero_shapes_are_keylined() -> void:
	var ids := {}
	for p in BezelArt.build_left() + BezelArt.build_right():
		ids[String(p.id)] = p
	for id in ["left_vigil_fin_r", "left_vigil_flame", "left_vigil_cockpit", "right_grub_hero_body", "right_grub_hero_glass", "right_grub_hero_leg_a"]:
		assert_bool(ids.has(id)).override_failure_message(id).is_true()
		assert_bool(ids.has(id + "_key")).override_failure_message("%s has no keyline" % id).is_true()
		assert_str(String((ids[id + "_key"] as BezelPiece).ink)).is_equal("key_black")


## The right panel's hero: a Grub about the Vigil's size, facing the screen (its hood is on the screen side).
func test_the_right_panel_has_a_hero_grub_facing_the_screen() -> void:
	var body: BezelPiece = null
	var hood: BezelPiece = null
	var glass: BezelPiece = null
	for p in BezelArt.build_right():
		match p.id:
			&"right_grub_hero_body": body = p
			&"right_grub_hero_hood": hood = p
			&"right_grub_hero_glass": glass = p
	var b := _rect(body.points)
	var full := b.merge(_rect(glass.points))
	assert_float(full.size.y).is_greater(90.0)
	assert_float(_rect(hood.points).get_center().x).is_less(b.get_center().x)     # the screen is on the right column's inner (left) side
	assert_bool(Rect2(0, 0, CabinetBezel.SIDE, 360).encloses(full)).is_true()


## The coin door sits in a printed cut-out with a keyline, and the NEW! sticker is clear of it.
func test_the_coin_door_sits_in_a_keylined_cut_out_clear_of_the_sticker() -> void:
	var band: BezelPiece = null
	var key: BezelPiece = null
	for p in BezelArt.build_right():
		if p.id == &"right_door_cutout_band":
			band = p
		elif p.id == &"right_door_cutout_key":
			key = p
	assert_object(band).is_not_null()
	assert_object(key).is_not_null()
	var cut := _rect(band.points)
	assert_bool(cut.encloses(CabinetBezel.COIN_PLATE_LOCAL)).is_true()
	assert_bool(cut.intersects(CabinetBezel.RIGHT_STICKER)).is_false()


func _rect(pts: PackedVector2Array) -> Rect2:
	var lo := Vector2(INF, INF)
	var hi := Vector2(-INF, -INF)
	for q in pts:
		lo = lo.min(q)
		hi = hi.max(q)
	return Rect2(lo, hi - lo)


## Generated art only (D-13/D-14): the backdrop is a shader with no texture samplers and no external files.
func test_the_backdrop_is_generated() -> void:
	var code := FileAccess.get_file_as_string("res://shaders/cabinet/arcade_backdrop.gdshader")
	# the code room stays in the shader; the one sampler is the manifested ComfyUI photo (ART-001 §14.9, ComfyArt), off by default in the shader
	assert_int(code.count("sampler2D")).is_equal(1)
	assert_bool(code.contains("uniform sampler2D photo")).is_true()
	assert_bool(code.contains("res://assets")).is_false()
	var s := CabinetSurface.default() as CabinetSurface
	assert_int(s.backdrop_neon.size()).is_equal(6)
	assert_float(s.backdrop_exposure).is_less_equal(0.55)      # two to three stops under the bezel: never pulls focus from the screen
	assert_float(s.backdrop_warmth).is_greater_equal(0.5)       # warm tungsten, not cool neon
	assert_bool(code.contains("cabinet_front") and code.contains("person") and code.contains("ceiling")).is_true()
