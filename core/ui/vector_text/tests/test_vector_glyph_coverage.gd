extends GdUnitTestSuite
## VectorText glyph coverage: every character the English locale can show has a stroke glyph
## (a missing glyph draws a visible box and fails here; L10N-001).

const PO_PATH := "res://locale/en.po"


static func locale_chars() -> Dictionary:
	var chars: Dictionary = {}
	var in_msgstr := false
	var header := false
	var last_id := ""
	for raw in FileAccess.get_file_as_string(PO_PATH).split("\n"):
		var line: String = raw.strip_edges()
		var body := ""
		if line.begins_with("msgid \""):
			last_id = line.substr(7, line.length() - 8)
			in_msgstr = false
			continue
		elif line.begins_with("msgstr \""):
			in_msgstr = true
			header = last_id == ""
			body = line.substr(8, line.length() - 9)
		elif in_msgstr and line.begins_with("\""):
			body = line.substr(1, line.length() - 2)
		else:
			in_msgstr = false
			continue
		if header:
			continue
		body = body.replace("\\\"", "\"").replace("\\n", "").replace("\\\\", "\\")
		for ch in body:
			chars[ch] = true
	return chars


func test_every_locale_character_has_a_glyph() -> void:
	var gs: VectorGlyphSet = VectorText.default_glyphs()
	var chars: Dictionary = locale_chars()
	assert_int(chars.size()).is_greater(30)
	var missing: Array[String] = []
	for k: Variant in chars.keys():
		var ch: String = str(k)
		if not gs.has_glyph(ch):
			missing.append(ch)
	assert_array(missing).is_empty()


func test_alphabet_digits_and_marks_are_covered() -> void:
	var gs: VectorGlyphSet = VectorText.default_glyphs()
	var wanted := "ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789 .,:;!?'\"-/%+()[]&\u00a2\u00a9\u00b7\u00d7\u2013\u2014"
	for ch in wanted:
		assert_bool(gs.has_glyph(ch)).override_failure_message("no glyph for '%s'" % ch).is_true()


func test_glyph_strokes_stay_in_the_em_box() -> void:
	var gs: VectorGlyphSet = VectorText.default_glyphs()
	for ch in gs.characters():
		for st in gs.get_strokes(ch):
			for p in st:
				assert_bool(p.x > -0.05 and p.x < 1.5 and p.y > -0.05 and p.y < 1.4).override_failure_message("'%s' out of box: %s" % [ch, p]).is_true()
		if ch != " ":
			assert_int(gs.get_strokes(ch).size()).override_failure_message("'%s' has no strokes" % ch).is_greater(0)
		assert_float(gs.get_advance(ch)).is_greater(0.0)


func test_missing_glyph_draws_a_box_and_is_reported() -> void:
	var gs: VectorGlyphSet = VectorText.default_glyphs()
	var lay: VectorLayout = VectorText.layout("\u4e2d", gs, VectorText.default_face())
	assert_int(lay.strokes.size()).is_equal(1)
	assert_int(lay.strokes[0].size()).is_equal(5)
	assert_array(lay.missing).contains(["\u4e2d"])
	assert_bool(gs.has_glyph("\u4e2d")).is_false()