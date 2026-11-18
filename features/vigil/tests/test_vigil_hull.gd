extends GdUnitTestSuite
## D-08 hull A/B switch: HP 1 vs 2 at runtime, grace only at HP >= 2, driven by ds_vigil.hull.max_hp.

const SCENE := preload("res://features/vigil/vigil.tscn")


func _vigil() -> Vigil:
	var v := auto_free(SCENE.instantiate()) as Vigil
	add_child(v)
	v.input.read_devices = false
	return v


func _hit(v: Vigil, source: int) -> bool:
	return v.health.apply_hit(HitInfo.make(1, source, 1))


func test_data_default_is_one_hit() -> void:
	var reg := TunableRegistry.new().scan()
	var v := _vigil()
	v.set_hull_max_hp(int(reg.get_value("ds_vigil.hull.max_hp")))
	assert_int(v.get_hull_max_hp()).is_equal(1)


func test_mode_a_one_hp_breaches_on_first_hit_and_no_grace() -> void:
	var v := _vigil()
	v.set_hull_max_hp(1)
	var breached: Array[int] = [0]
	v.hull_breached.connect(func() -> void: breached[0] += 1)
	assert_bool(_hit(v, 1)).is_true()
	assert_int(v.health.current_hp).is_equal(0)
	assert_int(breached[0]).is_equal(1)
	assert_bool(v.health.is_invulnerable()).is_false()


func test_mode_b_two_hp_survives_one_hit_with_grace() -> void:
	var v := _vigil()
	v.set_hull_max_hp(2)
	assert_int(v.health.current_hp).is_equal(2)
	assert_bool(_hit(v, 1)).is_true()
	assert_int(v.health.current_hp).is_equal(1)
	assert_bool(v.health.is_invulnerable()).is_true()
	assert_bool(_hit(v, 2)).is_false()   # inside the grace window
	for i in 46:   # 0.75 s at 60 Hz plus slack
		v.health.advance(1.0 / 60.0)
	assert_bool(_hit(v, 3)).is_true()
	assert_int(v.health.current_hp).is_equal(0)


func test_switch_back_and_forth_at_runtime() -> void:
	var v := _vigil()
	v.set_hull_max_hp(2)
	assert_int(v.get_hull_max_hp()).is_equal(2)
	v.set_hull_max_hp(1)
	assert_int(v.get_hull_max_hp()).is_equal(1)
	assert_int(v.health.current_hp).is_equal(1)
	v.set_hull_max_hp(0)   # clamped
	assert_int(v.get_hull_max_hp()).is_equal(1)


func test_switch_does_not_mutate_shared_hull_resource() -> void:
	var shared := load("res://data/vigil/vigil_hull.tres") as HealthStats
	var before := shared.max_hp
	_vigil().set_hull_max_hp(2)
	assert_int(shared.max_hp).is_equal(before)


func test_vigil_carries_an_arc_lance_emitter() -> void:
	var v := _vigil()
	assert_object(v.emitter).is_not_null()
	assert_object(v.emitter.input).is_same(v.input)
