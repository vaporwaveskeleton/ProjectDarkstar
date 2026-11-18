extends GdUnitTestSuite
## Hitbox -> Hurtbox -> Health path, without the physics server (pure rule checks).
## Physics overlap timing is covered in features/vigil/tests/test_vigil_collision.gd.


func _target(max_hp: int) -> HurtboxComponent:
	var stats := HealthStats.new()
	stats.max_hp = max_hp
	var health := HealthComponent.new()
	health.stats = stats
	var hurt := HurtboxComponent.new()
	hurt.health = health
	hurt.add_child(health)
	add_child(hurt)
	auto_free(hurt)
	return hurt


func _hitbox() -> HitboxComponent:
	var hb: HitboxComponent = auto_free(HitboxComponent.new())
	add_child(hb)
	return hb


func test_closed_window_never_hits() -> void:
	var hurt := _target(3)
	var hb := _hitbox()
	assert_bool(hb.try_hit(hurt)).is_false()
	assert_int(hurt.health.current_hp).is_equal(3)


func test_one_hit_per_target_per_window() -> void:
	var hurt := _target(5)
	var hb := _hitbox()
	hb.open_window()
	for i in 10:   # ten physics ticks of continuous overlap
		hb.try_hit(hurt)
	assert_int(hurt.health.current_hp).is_equal(4)
	hb.close_window()
	hb.open_window()
	hb.try_hit(hurt)
	assert_int(hurt.health.current_hp).is_equal(3)


func test_two_hitboxes_from_same_source_share_window_identity_only_if_same_window() -> void:
	var hurt := _target(5)
	var a := _hitbox()
	var b := _hitbox()
	a.open_window()
	b.open_window()
	a.try_hit(hurt)
	b.try_hit(hurt)
	# different hitbox nodes without an explicit shared `source` count as different attackers
	assert_int(hurt.health.current_hp).is_equal(3)


func test_hit_landed_reports_acceptance() -> void:
	var hurt := _target(1)
	var hb := _hitbox()
	var results: Array[bool] = []
	hb.hit_landed.connect(func(_h, ok): results.append(ok))
	hb.open_window()
	hb.try_hit(hurt)
	hb.open_window()
	hb.try_hit(hurt)   # target already depleted
	assert_array(results).is_equal([true, false])
