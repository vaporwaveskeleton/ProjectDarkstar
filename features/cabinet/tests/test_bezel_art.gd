extends GdUnitTestSuite
## The printed bezel (BezelArt / BezelInks, owner decision D-B): deterministic piece lists, valid
## inks, nothing on the screen, how-to-play text that fits, and the layer / draw order that keeps the
## print out from under the CRT.

const GAME_SCENE := "res://features/cabinet/cabinet_game.tscn"
const ATTRACT_SCENE := "res://scenes/attract/attract_mode.tscn"
const COLUMN := Rect2(0, 0, 80, 360)
const SCREEN := Rect2(80, 0, 480, 360)    ## the field, in screen space


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


## Column-local bounds of a piece, text included (1× PixelText of the translated key).
func _bounds(p: BezelPiece) -> Rect2:
	var lo := Vector2(INF, INF)
	var hi := Vector2(-INF, -INF)
	for q in p.points:
		lo = lo.min(q)
		hi = hi.max(q)
	if p.kind == BezelPiece.Kind.TEXT:
		var w := float(PixelText.width(tr(p.text_key)))
		var x0 := p.points[0].x - (w * 0.5 if p.centered else 0.0)
		return Rect2(x0, p.points[0].y, w, PixelText.H)
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
		assert_bool(COLUMN.encloses(b)) \
			.override_failure_message("%s %s leaves the 80 x 360 column" % [p.id, b]).is_true()
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


func test_no_piece_covers_the_screen() -> void:
	for p in _both():
		var b := _bounds(p)
		var offset := Vector2(CabinetBezel.RIGHT_X if p.column == &"right" else 0.0, 0.0)
		assert_bool(Rect2(b.position + offset, b.size).intersects(SCREEN)) \
			.override_failure_message("%s reaches the screen" % p.id).is_false()


func test_each_column_has_its_screen_lip() -> void:
	var left_lip: BezelPiece = null
	for p in BezelArt.build_left():
		if p.id == &"left_lip":
			left_lip = p
	assert_object(left_lip).is_not_null()
	assert_float(_bounds(left_lip).position.x).is_equal(78.0)
	for p in BezelArt.build_right():
		if p.id == &"right_lip":
			assert_float(_bounds(p).end.x).is_equal(2.0)


func test_how_to_play_lines_fit_the_card() -> void:
	var width := CabinetBezel.LEFT_HOWTO.size.x - 2.0
	for key in BezelArt.HOWTO_KEYS + ["CAB_HOWTO_TITLE", "CAB_BEZEL_SLOGAN"]:
		var s := tr(key)
		assert_str(s).override_failure_message("%s has no translation" % key).is_not_equal(key)
		assert_bool(float(PixelText.width(s)) <= width) \
			.override_failure_message("%s '%s' is wider than %s px" % [key, s, width]).is_true()
	for key in BezelArt.HOWTO_KEYS:
		assert_int(tr(key).length()).is_less_equal(12)


func test_new_keys_exist_in_the_source_locale() -> void:
	var po := FileAccess.get_file_as_string("res://locale/en.po")
	for key in ["CAB_HOWTO_TITLE", "CAB_BEZEL_SLOGAN"] + BezelArt.HOWTO_KEYS:
		assert_bool(po.contains("msgid \"%s\"" % key)).override_failure_message("%s missing from en.po" % key).is_true()


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


func test_attract_frame_and_coin_slot_draw_after_the_crt() -> void:
	var state := (load(ATTRACT_SCENE) as PackedScene).get_state()
	var order := {}
	for i in state.get_node_count():
		order[String(state.get_node_name(i))] = i
	assert_int(order["Frame"]).is_greater(order["Crt"])
	assert_int(order["CoinSlot"]).is_greater(order["Crt"])
	assert_int(order["PowerOn"]).is_less(order["Crt"])
