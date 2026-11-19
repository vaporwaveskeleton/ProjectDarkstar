extends GdUnitTestSuite
## HudModel honesty seam (TECH-001 §5.2–§5.4, WARP-001 §4.4, §4.7): the compass draws what the
## model presents; with Steady Ledger on (default) that is the true world state; no lie path exists
## yet (the lie hook returns the honest state); the own-position readout never lies.

const STATS := preload("res://data/hud/ledger_compass.tres")

var _was_steady: bool = true
var _was_persist: bool = true


func before_test() -> void:
	_was_persist = SettingsService.persist
	_was_steady = bool(SettingsService.get_value(&"steady_ledger"))
	SettingsService.persist = false


func after_test() -> void:
	SettingsService.set_value(&"steady_ledger", _was_steady)
	SettingsService.persist = _was_persist


func _node(at: Vector2, vigil: bool = false) -> Node2D:
	var n: Node2D = auto_free(Node2D.new())
	add_child(n)
	n.global_position = at
	if vigil:
		n.add_to_group(LedgerCompass.VIGIL_GROUP)
	else:
		LedgerCompass.register(n, &"geode")
	return n


func _compass(torus: Torus) -> LedgerCompass:
	var c: LedgerCompass = auto_free(LedgerCompass.new())
	c.stats = STATS
	c.world_rect = Rect2(Vector2.ZERO, torus.size)
	c.torus = torus
	add_child(c)
	c.set_process(false)
	return c


func test_steady_ledger_ships_on() -> void:
	assert_bool(bool(SettingsService.DEFAULTS[&"steady_ledger"])).is_true()


func test_drawn_markers_equal_true_world_positions_under_steady_ledger() -> void:
	SettingsService.set_value(&"steady_ledger", true)
	var torus := Torus.new(Vector2(1920, 720))
	var v := _node(Vector2(100, 100), true)
	var others: Array[Node2D] = []
	for i in 5:
		others.append(_node(Vector2(300 * i + 50, 120 * i + 30)))
	var c := _compass(torus)
	var mk: LedgerCompassMarkers = c.get_node(^"Markers")
	for f in 120:
		v.global_position += Vector2(37, -11)          # crosses the seam both ways
		for i in others.size():
			others[i].global_position += Vector2(-23 * (i + 1), 9)
		c.tick(1.0 / 60.0)
		assert_bool(c.model.presented() == c.model).is_true()
		var truth: Array[Node2D] = [v]
		truth.append_array(others)
		assert_int(c.marker_points.size()).is_equal(truth.size())
		for i in truth.size():
			var expected := c.layout.to_widget(torus.wrap(truth[i].global_position), c.world_rect)
			assert_vector(c.marker_points[i]).is_equal_approx(expected, Vector2(1e-4, 1e-4))
			assert_vector(mk.points[i]).is_equal_approx(expected, Vector2(1e-4, 1e-4))
		assert_vector(c.model.own_position).is_equal_approx(torus.wrap(v.global_position), Vector2(1e-4, 1e-4))
		assert_vector(c.own_position_point()).is_equal_approx(c.marker_points[0], Vector2(1e-4, 1e-4))


func test_lie_hook_returns_the_honest_state() -> void:
	var m := HudModel.new()
	m.marker_world = PackedVector2Array([Vector2(1, 2), Vector2(3, 4)])
	m.own_position = Vector2(1, 2)
	assert_object(HudModel.lie_hook(m)).is_same(m)


func test_no_lie_path_with_steady_ledger_off() -> void:
	SettingsService.set_value(&"steady_ledger", false)
	assert_bool(HudModel.steady_ledger_on()).is_false()
	var torus := Torus.new(Vector2(1920, 720))
	var v := _node(Vector2(1500, 600), true)
	var c := _compass(torus)
	c.refresh()
	assert_object(c.model.presented()).is_same(c.model)
	assert_vector(c.marker_points[0]).is_equal_approx(
		c.layout.to_widget(v.global_position, c.world_rect), Vector2(1e-4, 1e-4))


func test_own_position_is_the_vigil() -> void:
	var torus := Torus.new(Vector2(1920, 720))
	_node(Vector2(10, 10))
	var v := _node(Vector2(-100, 800), true)   # an image outside the torus
	var c := _compass(torus)
	c.refresh()
	assert_bool(c.model.has_own_position).is_true()
	assert_vector(c.model.own_position).is_equal(torus.wrap(v.global_position))
	assert_str(str(c.model.marker_kinds[0])).is_equal("vigil")


func test_no_entity_marker_in_m1() -> void:
	assert_bool(HudModel.new().entity_marker_visible).is_false()
