extends GdUnitTestSuite
## VectorText.layout(): pure and deterministic, metrics, wrap, alignment, the glyph-lie seam.

var _gs: VectorGlyphSet
var _face: VectorFace


func before_test() -> void:
	_gs = VectorText.default_glyphs()
	_face = VectorFace.new()
	_face.size = 10.0
	_face.stroke_width = 1.0


func _flat(lay: VectorLayout) -> PackedVector2Array:
	var all := PackedVector2Array()
	for s in lay.strokes:
		all.append_array(s)
	return all


func test_exact_strokes_at_zero_jitter() -> void:
	var lay: VectorLayout = VectorText.layout("L", _gs, _face)
	assert_int(lay.strokes.size()).is_equal(1)
	assert_array(lay.strokes[0]).is_equal(PackedVector2Array([Vector2(0, 0), Vector2(0, 10), Vector2(6.5, 10)]))


func test_same_input_same_output() -> void:
	var a: VectorLayout = VectorText.layout("Hello VIGIL", _gs, _face)
	var b: VectorLayout = VectorText.layout("Hello VIGIL", _gs, _face)
	assert_int(a.strokes.size()).is_equal(b.strokes.size())
	assert_array(_flat(a)).is_equal(_flat(b))
	assert_object(a.size).is_equal(b.size)


func test_jitter_comes_from_seed_only() -> void:
	var plain: VectorLayout = VectorText.layout("DARKSTAR", _gs, _face)
	var f1: VectorFace = _face.duplicate() as VectorFace
	f1.jitter = 0.5
	f1.seed = 7
	var f2: VectorFace = f1.duplicate() as VectorFace
	f2.seed = 8
	var a: VectorLayout = VectorText.layout("DARKSTAR", _gs, f1)
	var a2: VectorLayout = VectorText.layout("DARKSTAR", _gs, f1)
	var b: VectorLayout = VectorText.layout("DARKSTAR", _gs, f2)
	assert_array(_flat(a)).is_equal(_flat(a2))
	assert_array(_flat(a)).is_not_equal(_flat(b))
	assert_array(_flat(a)).is_not_equal(_flat(plain))
	var f0: VectorFace = _face.duplicate() as VectorFace
	f0.seed = 12345   # a seed with no jitter or grain changes nothing
	assert_array(_flat(VectorText.layout("DARKSTAR", _gs, f0))).is_equal(_flat(plain))


func test_wobble_is_bounded() -> void:
	var f1: VectorFace = _face.duplicate() as VectorFace
	f1.jitter = 0.4
	f1.seed = 3
	var plain: PackedVector2Array = _flat(VectorText.layout("MWQ", _gs, _face))
	var wob: PackedVector2Array = _flat(VectorText.layout("MWQ", _gs, f1))
	assert_int(wob.size()).is_equal(plain.size())
	for i in plain.size():
		assert_float(plain[i].distance_to(wob[i])).is_less(0.4 * 1.5)


func test_grain_adds_points_and_is_deterministic() -> void:
	var f1: VectorFace = _face.duplicate() as VectorFace
	f1.size = 40.0
	f1.grain = 0.3
	f1.seed = 2
	var a: VectorLayout = VectorText.layout("T", _gs, f1)
	var b: VectorLayout = VectorText.layout("T", _gs, f1)
	assert_array(_flat(a)).is_equal(_flat(b))
	assert_int(_flat(a).size()).is_greater(4)


func test_measure_matches_layout_and_tracks() -> void:
	var lay: VectorLayout = VectorText.layout("HH", _gs, _face)
	assert_float(lay.size.x).is_equal_approx(17.0, 0.001)   # advance 10 + ink 7
	assert_object(VectorText.measure("HH", _gs, _face)).is_equal(lay.size)
	var f2: VectorFace = _face.duplicate() as VectorFace
	f2.tracking = 2.0
	assert_float(VectorText.measure("HH", _gs, f2).x).is_equal_approx(19.0, 0.001)
	assert_float(lay.size.y).is_equal_approx(13.0, 0.001)   # cap 10 + descent 3


func test_newline_makes_lines() -> void:
	var lay: VectorLayout = VectorText.layout("H\nHH", _gs, _face)
	assert_int(lay.line_count()).is_equal(2)
	assert_float(lay.line_widths[0]).is_equal_approx(7.0, 0.001)
	assert_float(lay.line_widths[1]).is_equal_approx(17.0, 0.001)
	assert_float(lay.size.y).is_equal_approx(13.0 + lay.line_height, 0.001)
	assert_float(lay.line_height).is_equal_approx(16.0, 0.001)


func test_word_wrap() -> void:
	assert_int(VectorText.layout("HH HH", _gs, _face, VectorText.Align.LEFT, 100.0).line_count()).is_equal(1)
	var wrapped: VectorLayout = VectorText.layout("HH HH", _gs, _face, VectorText.Align.LEFT, 20.0)
	assert_int(wrapped.line_count()).is_equal(2)
	assert_array(wrapped.lines).is_equal(PackedStringArray(["HH", "HH"]))
	# A word wider than the box keeps its own line instead of being cut.
	var long: VectorLayout = VectorText.layout("HHHHHH H", _gs, _face, VectorText.Align.LEFT, 20.0)
	assert_array(long.lines).is_equal(PackedStringArray(["HHHHHH", "H"]))
	assert_object(VectorText.measure("HH HH", _gs, _face, 20.0)).is_equal(wrapped.size)


func test_alignment() -> void:
	var left: VectorLayout = VectorText.layout("H\nHHH", _gs, _face, VectorText.Align.LEFT)
	var centre: VectorLayout = VectorText.layout("H\nHHH", _gs, _face, VectorText.Align.CENTER)
	var right: VectorLayout = VectorText.layout("H\nHHH", _gs, _face, VectorText.Align.RIGHT)
	assert_float(left.strokes[0][0].x).is_equal_approx(0.0, 0.001)
	assert_float(centre.strokes[0][0].x).is_equal_approx(10.0, 0.001)   # (27 - 7) / 2
	assert_float(right.strokes[0][0].x).is_equal_approx(20.0, 0.001)
	var wide: VectorLayout = VectorText.layout("H", _gs, _face, VectorText.Align.RIGHT, 50.0)
	assert_float(wide.strokes[0][0].x).is_equal_approx(43.0, 0.001)


func test_filter_replaces_by_char() -> void:
	var f: Callable = func(ch: String, i: int) -> Variant:
		return "B" if (ch == "A" and i == 1) else null
	var lay: VectorLayout = VectorText.layout("AAA", _gs, _face, VectorText.Align.LEFT, 0.0, f)
	var want: VectorLayout = VectorText.layout("ABA", _gs, _face)
	assert_array(_flat(lay)).is_equal(_flat(want))


func test_filter_replaces_by_strokes_and_null_keeps() -> void:
	var s: Array[PackedVector2Array] = [PackedVector2Array([Vector2(0, 0), Vector2(0.5, 1.0)])]
	var f: Callable = func(_ch: String, i: int) -> Variant:
		return s if i == 0 else null
	var lay: VectorLayout = VectorText.layout("HH", _gs, _face, VectorText.Align.LEFT, 0.0, f)
	assert_array(lay.strokes[0]).is_equal(PackedVector2Array([Vector2(0, 0), Vector2(5, 10)]))
	var kept: VectorLayout = VectorText.layout("H", _gs, _face)
	assert_array(lay.strokes.slice(1)[0]).is_equal(PackedVector2Array([Vector2(10, 0), Vector2(10, 10)]))
	assert_int(lay.strokes.size()).is_equal(1 + kept.strokes.size())


func test_filter_sees_every_index() -> void:
	var seen: Array[int] = []
	var f: Callable = func(_ch: String, i: int) -> Variant:
		seen.append(i)
		return null
	VectorText.layout("AB C", _gs, _face, VectorText.Align.LEFT, 0.0, f)
	assert_array(seen).is_equal([0, 1, 2, 3])


func test_mesh_is_built_for_text_only() -> void:
	var lay: VectorLayout = VectorText.layout("A.", _gs, _face)
	var mesh: ArrayMesh = VectorText.build_mesh(lay, 1.0)
	assert_object(mesh).is_not_null()
	var arrays: Array = mesh.surface_get_arrays(0)
	var v: PackedVector2Array = arrays[Mesh.ARRAY_VERTEX] if arrays[Mesh.ARRAY_VERTEX] is PackedVector2Array else PackedVector2Array()
	assert_bool(v.size() > 0 and v.size() % 3 == 0).is_true()
	assert_object(VectorText.build_mesh(VectorText.layout("", _gs, _face), 1.0)).is_null()

func test_thin_diagonals_never_vanish() -> void:
	var tiny: VectorFace = VectorFace.new()
	tiny.size = 5.0
	tiny.stroke_width = 0.3   # far below one physical pixel
	for scale in [1.0, 3.0, 6.0]:
		var w: float = VectorText.effective_stroke_width(tiny.stroke_width, scale)
		assert_float(w * scale).is_greater_equal(VectorText.MIN_PHYSICAL_STROKE - 0.0001)
		for sample in ["X", "/", "7", "V", "Z"]:
			var lay: VectorLayout = VectorText.layout(sample, _gs, tiny)
			var mesh: ArrayMesh = VectorText.build_mesh(lay, w)
			assert_object(mesh).is_not_null()
			var v: PackedVector2Array = mesh.surface_get_arrays(0)[Mesh.ARRAY_VERTEX]
			var area := 0.0
			for i in range(0, v.size(), 3):
				var a: float = absf((v[i + 1] - v[i]).cross(v[i + 2] - v[i])) * 0.5
				assert_float(a).is_greater(0.0)   # no degenerate triangle
				area += a
			var want := 0.0
			for st in lay.strokes:
				for k in st.size() - 1:
					want += st[k].distance_to(st[k + 1]) * w
			assert_float(area).is_greater_equal(want * 0.99)