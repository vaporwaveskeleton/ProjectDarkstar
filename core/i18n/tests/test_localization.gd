extends GdUnitTestSuite
## L10N-001 validation (English only): missing / unused keys, placeholders, English fallback,
## plurals, number formatting, glyph coverage of the current UI font.

const PO_PATH := "res://locale/en.po"
const SCAN_ROOTS := ["res://scenes", "res://features", "res://core", "res://autoload", "res://data"]
## Key prefixes that mark a string literal as a translation key.
const KEY_PREFIXES := ["GAME_", "MENU_", "PAUSE_", "CONFIRM_", "SETTINGS_", "HUD_", "MSG_",
	"NARR_", "CX_", "ACH_", "CAB_", "ENTITY_", "REVEAL_", "RUINS_", "ATTRACT_"]

var _saved_locale := ""


func before_test() -> void:
	_saved_locale = TranslationServer.get_locale()


func after_test() -> void:
	TranslationServer.set_locale(_saved_locale)


static func po_keys() -> Dictionary:
	var keys := {}
	var text := FileAccess.get_file_as_string(PO_PATH)
	var re := RegEx.create_from_string("(?m)^msgid(?:_plural)? \"([A-Z][A-Z0-9_]+)\"")
	for m in re.search_all(text):
		keys[m.get_string(1)] = true
	return keys


static func po_entries() -> Dictionary:
	var out := {}
	var text := FileAccess.get_file_as_string(PO_PATH)
	var re := RegEx.create_from_string("(?m)^msgid \"([A-Z][A-Z0-9_]+)\"\\n(?:msgid_plural .*\\n)?msgstr(?:\\[0\\])? \"(.*)\"")
	for m in re.search_all(text):
		out[m.get_string(1)] = m.get_string(2)
	return out


static func used_keys() -> Dictionary:
	var used := {}
	var re := RegEx.create_from_string("\"([A-Z][A-Z0-9_]{2,})\"")
	for root in SCAN_ROOTS:
		for path in _files(root):
			if "/tests/" in path:
				continue
			for m in re.search_all(FileAccess.get_file_as_string(path)):
				var k := m.get_string(1)
				for p in KEY_PREFIXES:
					if k.begins_with(p):
						used[k] = path
	return used


static func _files(root: String) -> PackedStringArray:
	var out := PackedStringArray()
	var dir := DirAccess.open(root)
	if dir == null:
		return out
	dir.list_dir_begin()
	var n := dir.get_next()
	while n != "":
		var full := root.path_join(n)
		if dir.current_is_dir() and not n.begins_with("."):
			out.append_array(_files(full))
		elif n.ends_with(".gd") or n.ends_with(".tscn") or n.ends_with(".tres"):
			out.append(full)
		n = dir.get_next()
	return out


func test_every_used_key_exists_in_source_locale() -> void:
	var have := po_keys()
	var missing: Array[String] = []
	var used := used_keys()
	for k in used:
		if not have.has(k):
			missing.append("%s (%s)" % [k, used[k]])
	assert_array(missing).override_failure_message("keys missing from en.po: %s" % [missing]).is_empty()


func test_no_unused_keys() -> void:
	var used := used_keys()
	# dynamic keys: plural ids built by LocFormat.tr_count
	for k in used.keys():
		used["%s_PLURAL" % k] = true
	var unused: Array[String] = []
	for k in po_keys():
		if not used.has(k):
			unused.append(k)
	assert_array(unused).override_failure_message("unused keys in en.po: %s" % [unused]).is_empty()


func test_no_empty_or_placeholder_translations() -> void:
	for k in po_entries():
		var v: String = po_entries()[k]
		assert_str(v).override_failure_message("%s is empty" % k).is_not_empty()
		assert_bool(v.to_upper().contains("TODO") or v.contains("TBD")).override_failure_message("%s has placeholder text" % k).is_false()


func test_unsupported_locale_falls_back_to_english() -> void:
	assert_str(TranslationServer.get_locale()).is_equal("en")
	TranslationServer.set_locale("xx")
	assert_str(TranslationServer.translate("MENU_NEW_VIGIL")).is_equal("New Vigil")


func test_plural_forms_and_count_placeholder() -> void:
	TranslationServer.set_locale("en")
	assert_str(LocFormat.tr_count("HUD_HULL_COUNT", 1)).is_equal("Hull 1")
	assert_str(LocFormat.tr_count("HUD_HULL_COUNT", 2)).is_equal("Hull 2")
	assert_str(LocFormat.tr_count("HUD_HULL_COUNT", 1200)).is_equal("Hull 1,200")


func test_english_number_formatting() -> void:
	assert_str(LocFormat.format_int(1234567)).is_equal("1,234,567")
	assert_str(LocFormat.format_int(-1000)).is_equal("-1,000")
	assert_str(LocFormat.format_int(999)).is_equal("999")
	assert_str(LocFormat.format_decimal(1234.5, 1)).is_equal("1,234.5")
	assert_str(LocFormat.format_decimal(0.25, 2)).is_equal("0.25")


func test_ui_font_covers_every_source_glyph() -> void:
	var font := ThemeDB.fallback_font
	var theme := UiTheme.get_theme()
	if theme and theme.default_font:
		font = theme.default_font
	var missing := {}
	for k in po_entries():
		var s: String = po_entries()[k]
		for i in s.length():
			var c := s.unicode_at(i)
			if c > 32 and not font.has_char(c):
				missing[char(c)] = k
	assert_dict(missing).override_failure_message("glyphs missing from UI font: %s" % [missing]).is_empty()
