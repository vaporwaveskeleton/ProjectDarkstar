extends GdUnitTestSuite
## VectorLabel: lays out lazily, re-lays out only on real changes, no leaks.


func _label() -> VectorLabel:
	var l: VectorLabel = auto_free(VectorLabel.new())
	add_child(l)
	return l


func test_default_colour_never_blooms() -> void:
	var l: VectorLabel = _label()
	assert_bool(l.color.r <= 1.0 and l.color.g <= 1.0 and l.color.b <= 1.0).is_true()


func test_text_overrides_key() -> void:
	var l: VectorLabel = _label()
	l.key = &"CAB_PANEL_POWER"
	l.text = "HELLO"
	assert_str(l.shown_text()).is_equal("HELLO")
	assert_array(l.get_layout().lines).is_equal(PackedStringArray(["HELLO"]))


func test_relayout_on_key_change_only() -> void:
	var l: VectorLabel = _label()
	l.key = &"CAB_PANEL_POWER"
	var first: VectorLayout = l.get_layout()
	var n: int = l.layout_count
	assert_object(l.get_layout()).is_same(first)
	assert_int(l.layout_count).is_equal(n)
	l.key = &"MENU_SETTINGS"
	var second: VectorLayout = l.get_layout()
	assert_int(l.layout_count).is_equal(n + 1)
	assert_object(second).is_not_same(first)
	assert_str(second.lines[0]).is_equal(l.tr(&"MENU_SETTINGS"))


func test_relayout_on_face_filter_and_translation_change() -> void:
	var l: VectorLabel = _label()
	l.text = "AB"
	l.get_layout()
	var n: int = l.layout_count
	var f: VectorFace = VectorFace.new()
	f.size = 24.0
	l.face = f
	l.get_layout()
	assert_int(l.layout_count).is_equal(n + 1)
	l.glyph_filter = func(_c: String, _i: int) -> Variant: return null
	l.get_layout()
	assert_int(l.layout_count).is_equal(n + 2)
	l.notification(Node.NOTIFICATION_TRANSLATION_CHANGED)
	l.get_layout()
	assert_int(l.layout_count).is_equal(n + 3)


func test_minimum_size_follows_text() -> void:
	var l: VectorLabel = _label()
	l.text = "H"
	var small: Vector2 = l.get_combined_minimum_size()
	l.text = "HHHH"
	assert_float(l.get_combined_minimum_size().x).is_greater(small.x)


func test_wrap_uses_control_width() -> void:
	var l: VectorLabel = _label()
	l.wrap = true
	l.size = Vector2(60, 100)
	l.text = "HHHH HHHH HHHH"
	assert_int(l.get_layout().line_count()).is_greater(1)