extends GdUnitTestSuite
## HandlingTree: Aether readings of Lantern Tree nodes (LOOP-001 §3.3, §3.8), all from data.

const BASE := preload("res://data/vigil/vigil_aether_move.tres")


func _apply(ids: Array[String]) -> VigilAetherStats:
	return HandlingTree.apply(BASE, PackedStringArray(ids))


func test_no_nodes_is_base_and_base_untouched() -> void:
	var s := _apply([])
	for p in BASE.tunable_properties():
		assert_that(s.get(p)).is_equal(BASE.get(p))
	_apply(["HULL-1", "LANTERN-10"])
	assert_float(BASE.drag).is_equal(0.9)


func test_each_node() -> void:
	assert_int(_apply(["LANTERN-1"]).surge_charges).is_equal(2)
	assert_float(_apply(["LANTERN-5"]).lantern_down_thrust).is_equal_approx(0.85, 0.0001)
	assert_float(_apply(["LANTERN-6"]).surge_impulse).is_equal_approx(240.0 * 1.2, 0.001)
	assert_float(_apply(["LANTERN-7"]).surge_cooldown).is_equal_approx(2.0 * 0.75, 0.0001)
	assert_float(_apply(["LANTERN-9"]).drag).is_equal_approx(0.9 * 0.8, 0.0001)
	var h1 := _apply(["HULL-1"])
	assert_float(h1.drag).is_equal_approx(0.9 * 1.25, 0.0001)
	assert_float(h1.thrust_lateral).is_equal_approx(0.6, 0.0001)
	var h7 := _apply(["HULL-7"])
	assert_float(h7.drag).is_equal_approx(0.9 * 1.3, 0.0001)
	assert_float(h7.thrust_lateral).is_equal_approx(0.75, 0.0001)
	assert_float(_apply(["HULL-3"]).brake).is_equal_approx(700.0 * 1.25, 0.001)
	assert_float(_apply(["HULL-5"]).brake).is_equal_approx(700.0 * 1.15, 0.001)
	assert_float(_apply(["HULL-15"]).brake).is_equal_approx(700.0 * 1.25, 0.001)


func test_cooldown_floor_holds() -> void:
	var s := _apply(["LANTERN-7", "LANTERN-16"])
	assert_float(s.surge_cooldown).is_greater_equal(BASE.surge_cooldown_floor)
	assert_float(s.surge_cooldown).is_less(BASE.surge_cooldown * 0.75)


func test_keel_nodes_additive_to_234() -> void:
	assert_float(_apply(["LANTERN-10"]).hull_turn).is_equal_approx(180.0 * 1.15, 0.001)
	assert_float(_apply(["LANTERN-10", "LANTERN-13"]).hull_turn).is_equal_approx(234.0, 0.001)


func test_speed_cap_and_reversal_ratio() -> void:
	var one := _apply(["LANTERN-10"])
	assert_float(one.max_speed).is_equal_approx(220.0 * 1.06, 0.001)
	var both := _apply(["LANTERN-10", "LANTERN-13"])
	assert_float(both.max_speed).is_equal_approx(220.0 * 1.12, 0.001)
	# A larger source of speed still cannot push past +12%.
	var fx := HandlingTree.EFFECTS.duplicate() as HandlingNodeEffects
	fx.effects = fx.effects.duplicate(true)
	fx.effects["LANTERN-10"] = [{"field": "", "op": "speed_frac", "value": 0.2}]
	var capped := HandlingTree.apply(BASE, PackedStringArray(["LANTERN-10", "LANTERN-13"]), fx)
	assert_float(capped.max_speed).is_less_equal(220.0 * 1.12 + 0.001)
	# The full-reversal ratio max_speed / accel is preserved.
	assert_float(both.max_speed / both.accel).is_equal_approx(BASE.max_speed / BASE.accel, 0.0001)


func test_unknown_and_duplicate_ids_ignored() -> void:
	var s := _apply(["NOPE-1", "HULL-1", "HULL-1"])
	assert_float(s.drag).is_equal_approx(0.9 * 1.25, 0.0001)


func test_parse_args() -> void:
	var ids := HandlingTree.parse_args(PackedStringArray(["--tree=HULL-1, lantern-10", "--x"]))
	assert_int(ids.size()).is_equal(2)
	assert_str(ids[0]).is_equal("HULL-1")
	assert_str(ids[1]).is_equal("LANTERN-10")
	assert_int(HandlingTree.parse_args(PackedStringArray(["--hull=2"])).size()).is_equal(0)
	assert_int(HandlingTree.parse_args(PackedStringArray(["--tree="])).size()).is_equal(0)
