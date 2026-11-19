extends GdUnitTestSuite
## Ledger Compass stub: honest flag, marker cap (8 ✱), redraw throttle (≤ 10 Hz ✱), Vigil first,
## world-to-widget mapping, palette-only colours.

const STATS := preload("res://data/hud/ledger_compass.tres")


func _compass() -> LedgerCompass:
	var c: LedgerCompass = auto_free(LedgerCompass.new())
	c.stats = STATS
	c.size = Vector2(64, 36)
	c.world_rect = Rect2(0, 0, 640, 360)
	add_child(c)
	c.set_process(false)
	return c


func _marker(at: Vector2, kind: StringName = LedgerCompass.KIND_DEFAULT) -> Node2D:
	var n: Node2D = auto_free(Node2D.new())
	add_child(n)
	n.global_position = at
	LedgerCompass.register(n, kind)
	return n


func test_data_values() -> void:
	assert_str(STATS.ds_namespace).is_equal("ds_hud.compass")
	assert_int(STATS.max_markers).is_equal(8)
	assert_float(STATS.redraw_hz).is_equal_approx(10.0, 1e-6)


func test_compass_is_honest() -> void:
	assert_bool(LedgerCompass.HONEST).is_true()


func test_marker_cap_and_vigil_first() -> void:
	for i in 12:
		_marker(Vector2(10 * i, 10))
	var v: Node2D = auto_free(Node2D.new())
	add_child(v)
	v.add_to_group(LedgerCompass.VIGIL_GROUP)
	v.global_position = Vector2(320, 180)
	var c := _compass()
	c.refresh()
	assert_int(c.marker_points.size()).is_equal(8)
	assert_int(c.marker_kinds.size()).is_equal(8)
	assert_str(str(c.marker_kinds[0])).is_equal("vigil")
	assert_vector(c.marker_points[0]).is_equal_approx(Vector2(32, 18), Vector2(1e-3, 1e-3))


func test_collect_dedupes_and_caps() -> void:
	var a: Node2D = auto_free(Node2D.new())
	var b: Node2D = auto_free(Node2D.new())
	var nodes: Array[Node] = [a, a, b]
	assert_int(LedgerCompass.collect(nodes, 8).size()).is_equal(2)
	assert_int(LedgerCompass.collect(nodes, 1).size()).is_equal(1)


func test_redraw_is_throttled_to_ten_hz() -> void:
	var c := _compass()
	var refreshed := 0
	for i in 60:   # one second at 60 fps
		if c.tick(1.0 / 60.0):
			refreshed += 1
	assert_int(refreshed).is_less_equal(10)
	assert_int(refreshed).is_greater_equal(9)
	refreshed = 0
	for i in 144:  # one second at 144 fps
		if c.tick(1.0 / 144.0):
			refreshed += 1
	assert_int(refreshed).is_less_equal(10)


func test_should_refresh_interval() -> void:
	assert_bool(LedgerCompass.should_refresh(0.05, 10.0)).is_false()
	assert_bool(LedgerCompass.should_refresh(0.1, 10.0)).is_true()


func test_map_point_clamps_off_map_targets() -> void:
	var r := Rect2(0, 0, 640, 360)
	assert_vector(LedgerCompass.map_point(Vector2(640, 360), r, Vector2(64, 36))).is_equal(Vector2(64, 36))
	assert_vector(LedgerCompass.map_point(Vector2(-500, 900), r, Vector2(64, 36))).is_equal(Vector2(0, 36))


func test_kind_colours_are_palette_entries() -> void:
	var allowed: Array = Pal.ALL.values()
	for kind: StringName in [LedgerCompass.KIND_VIGIL, LedgerCompass.KIND_THREAT, LedgerCompass.KIND_DEFAULT, &"other"]:
		assert_bool(allowed.has(LedgerCompass.color_for(kind))).is_true()


func test_registered_kind_is_read() -> void:
	var m := _marker(Vector2(1, 1), LedgerCompass.KIND_THREAT)
	assert_str(str(LedgerCompass.kind_of(m))).is_equal("threat")


func test_choir_kinds_use_the_choir_hue() -> void:
	assert_object(LedgerCompass.color_for(LedgerCompass.KIND_SEPULCHRE)).is_equal(Pal.CHOIR_4)
	assert_object(LedgerCompass.color_for(LedgerCompass.KIND_GRUB)).is_equal(Pal.CHOIR_4)


func test_lower_rank_first_and_stable() -> void:
	var a := _marker(Vector2(1, 1), &"geode")
	var b := _marker(Vector2(2, 2), &"geode")
	var s: Node2D = auto_free(Node2D.new())
	add_child(s)
	LedgerCompass.register(s, LedgerCompass.KIND_SEPULCHRE, 0)
	var nodes: Array[Node] = [a, b, s]
	var out := LedgerCompass.by_rank(nodes)
	assert_object(out[0]).is_same(s)
	assert_object(out[1]).is_same(a)
	assert_object(out[2]).is_same(b)


func test_torus_wraps_actor_images_before_mapping() -> void:
	var c := _compass()
	c.world_rect = Rect2(0, 0, 1920, 720)
	c.torus = Torus.new(Vector2(1920, 720))
	var m := _marker(Vector2(-960, 360))   # an image left of the field = x 960 on the torus
	m.set_meta(LedgerCompass.RANK_META, 0)
	c.refresh()
	assert_bool(c.marker_points.size() >= 1).is_true()
	var expected := LedgerCompass.map_point(Vector2(960, 360), c.world_rect, c.size)
	assert_bool(c.marker_points.has(expected)).is_true()
