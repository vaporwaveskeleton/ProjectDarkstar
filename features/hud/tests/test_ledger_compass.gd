extends GdUnitTestSuite
## Ledger Compass: 64 × 64 module (Q-T120), honest flag, marker cap (8 ✱) with the Vigil first and
## rank kept, markers every frame, cached static layer (redraws only on invalidation, ≤ 10 Hz ✱),
## the empty entity frame, the one-cell sector list stub, torus mapping, palette-only colours.

const STATS := preload("res://data/hud/ledger_compass.tres")


func _compass() -> LedgerCompass:
	var c: LedgerCompass = auto_free(LedgerCompass.new())
	c.stats = STATS
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


func _vigil(at: Vector2) -> Node2D:
	var v: Node2D = auto_free(Node2D.new())
	add_child(v)
	v.add_to_group(LedgerCompass.VIGIL_GROUP)
	v.global_position = at
	return v


func test_data_values() -> void:
	assert_str(STATS.ds_namespace).is_equal("ds_hud.compass")
	assert_int(STATS.max_markers).is_equal(8)
	assert_float(STATS.redraw_hz).is_equal_approx(10.0, 1e-6)
	assert_vector(STATS.size_px).is_equal(Vector2(64, 64))
	assert_float(STATS.bezel_px).is_equal_approx(4.0, 1e-6)
	assert_vector(STATS.grid_world_px).is_equal(Vector2(640, 360))


func test_size_is_one_64_module() -> void:
	var c := _compass()
	assert_vector(c.size).is_equal(Vector2(64, 64))
	assert_vector(c.custom_minimum_size).is_equal(Vector2(64, 64))


func test_layout_sits_on_the_4px_subgrid_inside_the_face() -> void:
	var l := LedgerCompassLayout.make(Vector2(64, 64), 4.0, Vector2(1920, 720))
	assert_that(l.face).is_equal(Rect2(4, 4, 56, 56))
	assert_that(l.map).is_equal(Rect2(8, 8, 48, 20))
	assert_that(l.list_cell(0)).is_equal(Rect2(8, 36, 16, 8))
	assert_that(l.entity_frame).is_equal(Rect2(40, 36, 16, 16))
	for r: Rect2 in [l.map, l.list_cell(0), l.entity_frame]:
		assert_bool(l.face.encloses(r)).is_true()
		assert_float(fmod(r.position.x, 4.0)).is_equal(0.0)
		assert_float(fmod(r.size.y, 4.0)).is_equal(0.0)
	assert_bool(l.map.intersects(l.entity_frame)).is_false()


func test_compass_is_honest() -> void:
	assert_bool(LedgerCompass.HONEST).is_true()


func test_marker_cap_and_vigil_first() -> void:
	for i in 12:
		_marker(Vector2(10 * i, 10))
	_vigil(Vector2(320, 180))
	var c := _compass()
	c.refresh()
	assert_int(c.marker_points.size()).is_equal(8)
	assert_int(c.marker_kinds.size()).is_equal(8)
	assert_str(str(c.marker_kinds[0])).is_equal("vigil")
	# the centre of the world maps to the centre of the map rect (8, 8, 48, 20 at 640×360 aspect)
	assert_vector(c.marker_points[0]).is_equal_approx(c.layout.map.get_center(), Vector2(1e-3, 1e-3))


func test_collect_dedupes_and_caps() -> void:
	var a: Node2D = auto_free(Node2D.new())
	var b: Node2D = auto_free(Node2D.new())
	var nodes: Array[Node] = [a, a, b]
	assert_int(LedgerCompass.collect(nodes, 8).size()).is_equal(2)
	assert_int(LedgerCompass.collect(nodes, 1).size()).is_equal(1)


func test_markers_are_sampled_every_frame() -> void:
	var m := _marker(Vector2(100, 100))
	var c := _compass()
	var before := c.refresh_count
	for i in 60:
		m.global_position = Vector2(100 + i, 100)
		c.tick(1.0 / 60.0)
		assert_vector(c.marker_points[0]).is_equal_approx(
			c.layout.to_widget(m.global_position, c.world_rect), Vector2(1e-4, 1e-4))
	assert_int(c.refresh_count - before).is_equal(60)


func test_static_layer_draws_once_when_nothing_changes() -> void:
	_marker(Vector2(100, 100))
	var c := _compass()
	var redraws := 0
	for i in 600:   # ten seconds at 60 fps, markers moving, macro map unchanged
		if c.tick(1.0 / 60.0):
			redraws += 1
	assert_int(redraws).is_equal(1)
	assert_int(c.static_redraw_count).is_equal(1)


func test_static_layer_redraws_on_macro_map_change() -> void:
	var c := _compass()
	c.tick(1.0 / 60.0)
	var base := c.static_redraw_count
	for i in 30:
		c.tick(1.0 / 60.0)
	assert_int(c.static_redraw_count).is_equal(base)
	c.world_rect = Rect2(0, 0, 1920, 720)
	for i in 6:   # 0.1 s
		c.tick(1.0 / 60.0)
	assert_int(c.static_redraw_count).is_equal(base + 1)
	c.torus = Torus.new(Vector2(1920, 720))
	for i in 6:
		c.tick(1.0 / 60.0)
	assert_int(c.static_redraw_count).is_equal(base + 2)


func test_static_redraws_are_capped_at_ten_hz() -> void:
	var c := _compass()
	var redraws := 0
	for i in 60:   # invalidated every frame for one second at 60 fps
		c.invalidate_static()
		if c.tick(1.0 / 60.0):
			redraws += 1
	assert_int(redraws).is_less_equal(10)
	assert_int(redraws).is_greater_equal(9)
	redraws = 0
	for i in 144:  # one second at 144 fps
		c.invalidate_static()
		if c.tick(1.0 / 144.0):
			redraws += 1
	assert_int(redraws).is_less_equal(10)


func test_static_layer_draw_pass_follows_the_requests() -> void:
	var c := _compass()
	c.tick(1.0 / 60.0)
	await await_idle_frame()
	var s: LedgerCompassStatic = c.get_node(^"Static")
	var drawn := s.draw_count
	for i in 30:
		c.tick(1.0 / 60.0)
	await await_idle_frame()
	assert_int(s.draw_count).is_equal(drawn)
	var mk: LedgerCompassMarkers = c.get_node(^"Markers")
	assert_int(mk.draw_count).is_greater(0)


func test_entity_marker_frame_is_drawn_and_empty() -> void:
	_vigil(Vector2(10, 10))
	for i in 3:
		_marker(Vector2(600, 350))
	var c := _compass()
	c.refresh()
	assert_bool(c.model.entity_marker_visible).is_false()
	for p in c.marker_points:
		assert_bool(c.layout.entity_frame.has_point(p)).is_false()
		assert_bool(c.layout.map.grow(0.001).has_point(p)).is_true()
	assert_bool(c.marker_kinds.has(&"entity")).is_false()


func test_sector_list_is_a_one_cell_stub() -> void:
	var c := _compass()
	assert_int(c.model.sector_list_cells).is_equal(1)


func test_should_refresh_interval() -> void:
	assert_bool(LedgerCompass.should_refresh(0.05, 10.0)).is_false()
	assert_bool(LedgerCompass.should_refresh(0.1, 10.0)).is_true()


func test_map_point_clamps_off_map_targets() -> void:
	var r := Rect2(0, 0, 640, 360)
	assert_vector(LedgerCompass.map_point(Vector2(640, 360), r, Vector2(48, 20))).is_equal(Vector2(48, 20))
	assert_vector(LedgerCompass.map_point(Vector2(-500, 900), r, Vector2(48, 20))).is_equal(Vector2(0, 20))


func test_grid_has_one_cell_per_screen_on_the_m1_torus() -> void:
	assert_int(LedgerCompassLayout.grid_lines(1920, 640).size()).is_equal(2)
	assert_int(LedgerCompassLayout.grid_lines(720, 360).size()).is_equal(1)
	assert_int(LedgerCompassLayout.grid_lines(720, 0).size()).is_equal(0)


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


func test_rank_kept_under_the_cap() -> void:
	_vigil(Vector2(5, 5))
	for i in 10:
		_marker(Vector2(20 * i, 20), &"geode")
	var s := _marker(Vector2(300, 300), LedgerCompass.KIND_SEPULCHRE)
	s.set_meta(LedgerCompass.RANK_META, 0)
	var c := _compass()
	c.refresh()
	assert_int(c.marker_kinds.size()).is_equal(8)
	assert_str(str(c.marker_kinds[0])).is_equal("vigil")
	assert_str(str(c.marker_kinds[1])).is_equal("sepulchre")


func test_torus_wraps_actor_images_before_mapping() -> void:
	var c := _compass()
	c.world_rect = Rect2(0, 0, 1920, 720)
	c.torus = Torus.new(Vector2(1920, 720))
	var m := _marker(Vector2(-960, 360))   # an image left of the field = x 960 on the torus
	m.set_meta(LedgerCompass.RANK_META, 0)
	c.refresh()
	assert_bool(c.marker_points.size() >= 1).is_true()
	var expected := c.layout.to_widget(Vector2(960, 360), c.world_rect)
	assert_vector(c.marker_points[0]).is_equal_approx(expected, Vector2(1e-4, 1e-4))
	assert_vector(expected).is_equal_approx(c.layout.map.get_center(), Vector2(1e-4, 1e-4))
