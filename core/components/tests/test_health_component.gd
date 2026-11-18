extends GdUnitTestSuite
## HealthComponent: damage, depletion, one-hit-per-window, invulnerability, D-08 data switch.


func _make(max_hp: int, invuln: float = 0.0) -> HealthComponent:
	var stats := HealthStats.new()
	stats.max_hp = max_hp
	stats.invulnerable_after_hit_s = invuln
	var h: HealthComponent = auto_free(HealthComponent.new())
	h.stats = stats
	h.reset()
	return h


func test_one_hit_hull_default_depletes_on_first_hit() -> void:
	var h := _make(1)
	var depleted := [0]
	h.health_depleted.connect(func(): depleted[0] += 1)
	assert_bool(h.apply_hit(HitInfo.make(1, 100, 1))).is_true()
	assert_int(h.current_hp).is_equal(0)
	assert_bool(h.is_depleted).is_true()
	assert_int(depleted[0]).is_equal(1)


func test_d08_two_hp_variant_is_a_data_edit() -> void:
	var h := _make(2)
	h.apply_hit(HitInfo.make(1, 100, 1))
	assert_bool(h.is_depleted).is_false()
	assert_int(h.current_hp).is_equal(1)
	h.apply_hit(HitInfo.make(1, 100, 2))
	assert_bool(h.is_depleted).is_true()


func test_same_attack_window_hits_only_once() -> void:
	var h := _make(3)
	assert_bool(h.apply_hit(HitInfo.make(1, 7, 1))).is_true()
	assert_bool(h.apply_hit(HitInfo.make(1, 7, 1))).is_false()
	assert_bool(h.apply_hit(HitInfo.make(1, 7, 1))).is_false()
	assert_int(h.current_hp).is_equal(2)
	# a new window from the same source, or another source, lands
	assert_bool(h.apply_hit(HitInfo.make(1, 7, 2))).is_true()
	assert_bool(h.apply_hit(HitInfo.make(1, 8, 1))).is_true()
	assert_int(h.current_hp).is_equal(0)


func test_invulnerability_window_blocks_then_expires() -> void:
	var h := _make(3, 0.5)
	h.apply_hit(HitInfo.make(1, 1, 1))
	assert_bool(h.is_invulnerable()).is_true()
	assert_bool(h.apply_hit(HitInfo.make(1, 2, 1))).is_false()
	for i in 30:   # 0.5 s at 60 Hz
		h.advance(1.0 / 60.0)
	assert_bool(h.is_invulnerable()).is_false()
	assert_bool(h.apply_hit(HitInfo.make(1, 2, 1))).is_true()


func test_hits_after_depletion_are_rejected() -> void:
	var h := _make(1)
	h.apply_hit(HitInfo.make(1, 1, 1))
	var reasons: Array[StringName] = []
	h.hit_rejected.connect(func(r): reasons.append(r))
	assert_bool(h.apply_hit(HitInfo.make(5, 2, 1))).is_false()
	assert_array(reasons).contains([&"depleted"])


func test_heal_clamps_to_max_and_not_after_depletion() -> void:
	var h := _make(3)
	h.apply_hit(HitInfo.make(2, 1, 1))
	assert_int(h.heal(10)).is_equal(2)
	assert_int(h.current_hp).is_equal(3)
	h.apply_hit(HitInfo.make(3, 1, 2))
	assert_int(h.heal(1)).is_equal(0)


func test_zero_or_negative_damage_is_ignored() -> void:
	var h := _make(1)
	assert_bool(h.apply_hit(HitInfo.make(0, 1, 1))).is_false()
	assert_bool(h.apply_hit(HitInfo.make(-1, 1, 2))).is_false()
	assert_int(h.current_hp).is_equal(1)


func test_missing_stats_defaults_to_one_hit() -> void:
	var h: HealthComponent = auto_free(HealthComponent.new())
	h.reset()
	assert_int(h.max_hp).is_equal(1)
