extends GdUnitTestSuite
## The printed bezel (BezelArt / BezelInks, owner decision D-B): deterministic piece lists, valid
## inks, nothing on the screen, how-to-play text that fits, and the layer / draw order that keeps the
## print out from under the CRT.

const GAME_SCENE := "res://features/cabinet/cabinet_game.tscn"
const ATTRACT_SCENE := "res://scenes/attract/attract_mode.tscn"
const COLUMN := Rect2(0, 0, CabinetBezel.SIDE, 360)
const BLEED := 70.0                         ## art may run this far off a column edge: BezelPrint clips to the SIDE x 360 box
const SCREEN := Rect2(192, 28, 256, 304)    ## the hole in rig units (spec grid 256×304 centred in 640×360)


func _both() -> Array[BezelPiece]:
	var out: Array[BezelPiece] = []
	out.append_array(BezelArt.build_left())
	out.append_array(BezelArt.build_right())
	return out


func _signature(list: Array[BezelPiece]) -> PackedStringArray:
	var out := PackedStringArray()
	for p in list:
		out.append("%s|%d|%d|%s|%d|%s|%s|%s" % [p.id, p.column.hash(), p.kind, p.ink, p.z, p.points, p.width, p.text_key])
	return out


## Column-local bounds of a piece, text included (the VectorText painted size of the translated key).
func _bounds(p: BezelPiece) -> Rect2:
	var lo := Vector2(INF, INF)
	var hi := Vector2(-INF, -INF)
	for q in p.points:
		lo = lo.min(q)
		hi = hi.max(q)
	if p.kind == BezelPiece.Kind.TEXT:
		var sz := BezelText.painted_size(BezelArt.text_of(p, tr(p.text_key)), p.width, p.stroke_w, p.tracking)
		var x0 := p.points[0].x - (sz.x * 0.5 if p.centered else 0.0)
		return Rect2(x0, p.points[0].y, sz.x, sz.y)
	if p.kind == BezelPiece.Kind.PIXELS:
		hi += Vector2(p.width, p.width)
	return Rect2(lo, hi - lo)


func test_piece_lists_are_deterministic() -> void:
	assert_array(_signature(BezelArt.build_left())).is_equal(_signature(BezelArt.build_left()))
	assert_array(_signature(BezelArt.build_right())).is_equal(_signature(BezelArt.build_right()))
	assert_int(BezelArt.hash_int(7)).is_equal(BezelArt.hash_int(7))


func test_both_columns_are_not_empty_and_differ() -> void:
	assert_int(BezelArt.build_left().size()).is_greater(40)
	assert_int(BezelArt.build_right().size()).is_greater(40)
	assert_array(_signature(BezelArt.build_left())).is_not_equal(_signature(BezelArt.build_right()))


func test_piece_ids_are_unique() -> void:
	var seen := {}
	for p in _both():
		assert_bool(seen.has(p.id)).override_failure_message("duplicate piece id %s" % p.id).is_false()
		seen[p.id] = true
		assert_bool(String(p.id).begins_with(String(p.column) + "_")).is_true()


func test_every_piece_has_geometry_inside_its_column() -> void:
	for p in _both():
		assert_int(p.points.size()).override_failure_message("%s has no points" % p.id).is_greater(0)
		var b := _bounds(p)
		assert_bool(COLUMN.grow(BLEED).encloses(b)) \
			.override_failure_message("%s %s runs further than the bleed off the column" % [p.id, b]).is_true()
		if p.kind in [BezelPiece.Kind.FILL, BezelPiece.Kind.OUTLINE, BezelPiece.Kind.HALFTONE]:
			assert_int(p.points.size()).override_failure_message("%s needs 3+ points" % p.id).is_greater(2)


func test_every_ink_exists_in_the_bezel_inks() -> void:
	var inks := BezelInks.default() as BezelInks
	for p in _both():
		assert_bool(inks.has_ink(p.ink)).override_failure_message("%s uses unknown ink %s" % [p.id, p.ink]).is_true()


func test_inks_are_printed_values_outside_the_neon_palette() -> void:
	var inks := BezelInks.default() as BezelInks
	assert_bool(inks.ink(&"key_black").is_equal_approx(Color8(0x14, 0x10, 0x18))).is_true()
	assert_bool(inks.ink(&"cream").is_equal_approx(Color8(0xF1, 0xE6, 0xC8))).is_true()
	assert_bool(inks.ink(&"chrome_dark").is_equal_approx(Color8(0x5A, 0x60, 0x70))).is_true()
	for id: StringName in [&"key_black", &"navy", &"process_blue", &"cyan", &"magenta", &"warm_red", &"yellow", &"orange", &"cream", &"brass", &"chrome_light", &"chrome_dark"]:
		assert_bool(inks.has_ink(id)).override_failure_message("missing ink %s" % id).is_true()
	assert_str(inks.ds_namespace).is_equal("ds_cabinet.bezel")


func test_pieces_are_sorted_by_z() -> void:
	for list in [BezelArt.build_left(), BezelArt.build_right()]:
		var last := -1
		for p: BezelPiece in list:
			assert_int(p.z).is_greater_equal(last)
			last = p.z


## The print clips to its SIDE x 360 box (art bleeds off the outer, top and bottom edges), so what reaches the
## window is each piece's bounds clipped to the column: none of that touches the screen.
func test_no_piece_covers_the_screen() -> void:
	for p in _both():
		var b := _bounds(p).intersection(COLUMN)
		var offset := Vector2(CabinetBezel.right_x() if p.column == &"right" else CabinetBezel.left_x(), 0.0)
		assert_bool(Rect2(b.position + offset, b.size).intersects(SCREEN)) \
			.override_failure_message("%s reaches the screen" % p.id).is_false()
	var print_node := BezelPrint.new()
	add_child(print_node)
	auto_free(print_node)
	assert_bool(print_node.clip_contents).is_true()


func test_each_column_has_its_screen_lip() -> void:
	var left_lip: BezelPiece = null
	for p in BezelArt.build_left():
		if p.id == &"left_lip":
			left_lip = p
	assert_object(left_lip).is_not_null()
	assert_float(_bounds(left_lip).position.x).is_equal(CabinetBezel.SIDE - 2.0)
	for p in BezelArt.build_right():
		if p.id == &"right_lip":
			assert_float(_bounds(p).end.x).is_equal(2.0)


func test_how_to_play_lines_fit_the_panel_in_vector_text() -> void:
	var width := BezelArt.howto_line_width()
	var cap := BezelArt.howto_cap(BezelArt.HOWTO_KEYS, width, BezelArt.HOWTO_CAP)
	assert_float(cap).is_greater(3.0)          # still legible (about 9 px at 1080p)
	for key in BezelArt.HOWTO_KEYS + BezelArt.SHEET_KEYS:
		var s := tr(key)
		assert_str(s).override_failure_message("%s has no translation" % key).is_not_equal(key)
	for key in BezelArt.HOWTO_KEYS:
		assert_float(BezelText.painted_size(tr(key), cap, cap * 0.2, 0.5).x) \
			.override_failure_message("%s is wider than the panel" % key).is_less_equal(width)
		assert_int(tr(key).length()).is_less_equal(12)


func test_new_keys_exist_in_the_source_locale() -> void:
	var po := FileAccess.get_file_as_string("res://locale/en.po")
	for key in BezelArt.SHEET_KEYS + BezelArt.HOWTO_KEYS + ["CAB_BEZEL_SLOGAN"]:
		assert_bool(po.contains("msgid \"%s\"" % key)).override_failure_message("%s missing from en.po" % key).is_true()


## Every string the bezel prints goes through tr() with a stable key and is drawn with VectorText, never
## PixelText: PixelText stays inside the arcade screen.
func test_every_bezel_string_is_a_tr_key_drawn_with_vector_text() -> void:
	var po := FileAccess.get_file_as_string("res://locale/en.po")
	var texts := 0
	for p in _both():
		if p.kind != BezelPiece.Kind.TEXT:
			continue
		texts += 1
		assert_str(p.text_key).override_failure_message("%s has no tr key" % p.id).is_not_empty()
		assert_bool(po.contains("msgid \"%s\"" % p.text_key)).override_failure_message("%s: %s not in en.po" % [p.id, p.text_key]).is_true()
		assert_float(p.width).override_failure_message("%s has no cap height" % p.id).is_greater(1.0)
		assert_float(p.stroke_w).is_greater(0.0)
	assert_int(texts).is_greater(10)
	for path in ["res://features/cabinet/bezel_print.gd", "res://features/cabinet/bezel_art.gd", "res://features/cabinet/bezel_sticker.gd",
			"res://features/cabinet/bezel_marquee.gd", "res://features/cabinet/cabinet_bezel.gd", "res://features/cabinet/coin_slot.gd",
			"res://features/cabinet/cabinet_hud.gd", "res://features/cabinet/bezel_text.gd", "res://scenes/attract/attract_frame.gd"]:
		var code := FileAccess.get_file_as_string(path)
		var live: PackedStringArray = []
		for line in code.split("\n"):
			if not line.strip_edges().begins_with("#") and line.contains("PixelText"):
				live.append(line)
		assert_array(live).override_failure_message("%s draws PixelText on the bezel" % path).is_empty()


## The BezelPiece list is still the zoom seam: unique ids, a pivot and a z on every piece.
func test_the_piece_list_survives_with_ids_pivots_and_z() -> void:
	var seen := {}
	for p in _both():
		assert_bool(seen.has(p.id)).is_false()
		seen[p.id] = true
		assert_bool(p.pivot.is_finite()).is_true()
	assert_int(seen.size()).is_greater(100)


## The sheet is full-bleed, not floating cards: no bordered card or frame pieces, and halftone pieces are tone ramps.
func test_the_sheet_has_no_floating_cards_and_tones_are_ramps() -> void:
	var tones := 0
	for p in _both():
		var id := String(p.id)
		assert_bool(id in ["left_vigil_frame", "right_sep_frame", "left_howto_shadow", "left_howto_line", "left_vigil_bg", "right_sep_bg"]).override_failure_message(id).is_false()
		if p.kind == BezelPiece.Kind.HALFTONE:
			tones += 1
			assert_float(p.tone0).is_between(0.0, 1.0)
			assert_float(p.tone1).is_between(0.0, 1.0)
			assert_float(p.tone_at(p.pivot)).is_between(0.0, 1.0)
	assert_int(tones).is_greater(8)


## The big logo lives in the left column's upper art (Q-T32) and is the game title.
func test_the_big_logo_is_the_title_in_the_upper_left_art() -> void:
	var found := 0
	for p in BezelArt.build_left():
		if String(p.id).begins_with("left_logo_fill"):
			found += 1
			assert_str(p.text_key).is_equal("GAME_TITLE")
			assert_float(p.width).is_greater_equal(14.0)         # big
			assert_float(p.points[0].y).is_less(70.0)             # upper art
	assert_int(found).is_equal(2)


## The entity motifs keep the §12.7a rule: exactly one slit eye on the Sepulchre, no mouth and no skull piece.
func test_entity_motifs_keep_the_one_eye_rule() -> void:
	var eyes := 0
	for p in BezelArt.build_right():
		var id := String(p.id)
		if id == "right_sep_eye":
			eyes += 1
		assert_bool(id.contains("mouth") or id.contains("skull") or id.contains("jaw")).override_failure_message(id).is_false()
	assert_int(eyes).is_equal(1)


func test_bezel_draws_after_the_screen_and_the_crt_is_the_screens_material() -> void:
	var state := (load(GAME_SCENE) as PackedScene).get_state()
	var order := {}
	for i in state.get_node_count():
		order[String(state.get_node_name(i))] = i
	assert_bool(order.has("CrtLayer")).override_failure_message("the CRT is the screen's material now").is_false()
	assert_bool(order.has("BezelLayer")).is_false()
	assert_int(order["Hud"]).is_greater(order["ArcadeScreen"])
	assert_int(order["Overlays"]).is_greater(order["Hud"])
	assert_str(str(state.get_node_path(order["Hud"]))).contains("Rig/Hud")
	assert_str(str(state.get_node_path(order["Messages"]))).contains("Rig/ArcadeScreen/ScreenViewport/")


func test_attract_frame_panel_and_coin_slot_draw_after_the_arcade_screen() -> void:
	var state := (load(ATTRACT_SCENE) as PackedScene).get_state()
	var order := {}
	for i in state.get_node_count():
		order[String(state.get_node_name(i))] = i
	assert_bool(order.has("Crt")).override_failure_message("the attract CRT is the arcade screen's material now (Q-T80)").is_false()
	assert_int(order["Frame"]).is_greater(order["ArcadeScreen"])
	assert_int(order["ControlPanel"]).is_greater(order["Frame"])
	assert_int(order["CoinSlot"]).is_greater(order["Frame"])
	assert_int(order["PowerOn"]).is_less(order["Frame"])


func test_the_hole_comes_from_the_spec_and_the_columns_sit_flush_against_it() -> void:
	assert_object(CabinetBezel.hole()).is_equal(SCREEN)
	assert_float(CabinetBezel.left_x() + CabinetBezel.SIDE).is_equal(SCREEN.position.x)
	assert_float(CabinetBezel.right_x()).is_equal(SCREEN.end.x)
	assert_object(CabinetBezel.coin_plate()).is_equal(Rect2(CabinetBezel.right_x() + 12.0, 252, 56, 80))


## At every target window the print field plus the two columns leave no uncovered window area outside
## the hole, and nothing (field, edge, column, coin plate) paints over the hole.
func test_field_and_columns_tile_the_window_and_never_touch_the_hole() -> void:
	var field := BezelField.new()
	add_child(field)
	auto_free(field)
	var spec := load("res://data/cabinet/cabinet_screen.tres") as CabinetScreenSpec
	var sizes: Array[Vector2i] = [Vector2i(1920, 1080), Vector2i(2560, 1440), Vector2i(2560, 1600), Vector2i(3840, 2160),
		Vector2i(3440, 1440), Vector2i(1920, 1200), Vector2i(1366, 768), Vector2i(1280, 800)]
	for win in sizes:
		var area := ScreenFit.bezel_rect(win, spec.grid)
		field.set_area(area)
		var parts: Array[Rect2] = field.bands()
		var left_col := Rect2(CabinetBezel.left_x(), SCREEN.position.y, CabinetBezel.SIDE, SCREEN.size.y)
		var right_col := Rect2(CabinetBezel.right_x(), SCREEN.position.y, CabinetBezel.SIDE, SCREEN.size.y)
		parts.append_array([left_col, right_col])
		var covered := 0.0
		for p in parts:
			covered += p.get_area()
			assert_bool(p.intersects(SCREEN)).override_failure_message("%s overlaps the hole at %s" % [p, win]).is_false()
			assert_bool(area.encloses(p)).override_failure_message("%s leaves the window at %s" % [p, win]).is_true()
		# the parts and the hole tile the window exactly: no gap, no overlap
		assert_float(covered + SCREEN.get_area()).is_equal_approx(area.get_area(), 0.5)
		for e in field.edges():
			assert_bool(e.intersects(SCREEN)).is_false()
	assert_int(field.painted().size()).is_equal(6)


func test_coin_plate_and_columns_stay_out_of_the_hole() -> void:
	assert_bool(CabinetBezel.coin_plate().intersects(SCREEN)).is_false()
	assert_bool(Rect2(CabinetBezel.left_x(), 0, CabinetBezel.SIDE, 360).intersects(SCREEN)).is_false()
	assert_bool(Rect2(CabinetBezel.right_x(), 0, CabinetBezel.SIDE, 360).intersects(SCREEN)).is_false()
