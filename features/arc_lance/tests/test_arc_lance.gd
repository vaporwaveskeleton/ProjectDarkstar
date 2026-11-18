extends GdUnitTestSuite
## Arc-Lance: data values, fire cadence, projectile speed / lifetime / range, one hit per projectile.
## Numbers come from data/arc_lance/arc_lance.tres; the test restates only the SYS-001 §1.3 values
## it exists to guard (6/s, 340 px/s, 14 px, 306 px range).

const STATS := preload("res://data/arc_lance/arc_lance.tres")
const DT := 1.0 / 60.0

var _holder: Node2D
var _facing: Node2D
var _emitter: ArcLanceEmitter


func before_test() -> void:
	_holder = auto_free(Node2D.new())
	add_child(_holder)
	_facing = Node2D.new()
	_holder.add_child(_facing)
	_emitter = ArcLanceEmitter.new()
	_emitter.stats = STATS
	_emitter.facing_node = _facing
	_emitter.projectile_parent = _holder
	_emitter.enabled = false   # tests drive advance() directly
	_holder.add_child(_emitter)


func _shot(dir: Vector2 = Vector2.RIGHT) -> LanceProjectile:
	var s := auto_free(preload("res://features/arc_lance/lance_projectile.tscn").instantiate()) as LanceProjectile
	_holder.add_child(s)
	s.launch(STATS, Vector2.ZERO, dir)
	return s


func test_data_matches_sys001() -> void:
	assert_float(STATS.fire_rate_per_s).is_equal(6.0)
	assert_float(STATS.projectile_speed).is_equal(340.0)
	assert_float(STATS.visual_length_px).is_equal(14.0)
	assert_int(STATS.hits_per_projectile).is_equal(1)
	assert_int(STATS.damage).is_equal(1)
	assert_float(STATS.range_px()).is_equal_approx(306.0, 0.01)


func test_fire_cadence_is_six_per_second() -> void:
	var fired := 0
	for i in 60:
		if _emitter.advance(DT, true) != null:
			fired += 1
	assert_int(fired).is_between(6, 7)   # first shot is instant, then every 1/6 s
	var second := 0
	for i in 60:
		if _emitter.advance(DT, true) != null:
			second += 1
	assert_int(second).is_equal(6)


func test_no_fire_when_not_held() -> void:
	for i in 60:
		assert_object(_emitter.advance(DT, false)).is_null()


func test_release_and_repress_cannot_beat_the_rate() -> void:
	var fired := 0
	for i in 60:
		if _emitter.advance(DT, i % 2 == 0) != null:
			fired += 1
	assert_int(fired).is_less_equal(7)


func test_fires_along_facing() -> void:
	_facing.rotation = PI * 0.5
	var s := _emitter.advance(DT, true)
	assert_vector(s.direction).is_equal_approx(Vector2.DOWN, Vector2(0.001, 0.001))
	assert_vector(s.global_position).is_equal_approx(Vector2(0, STATS.muzzle_offset_px), Vector2(0.001, 0.001))


func test_projectile_speed() -> void:
	var s := _shot()
	for i in 6:
		s.advance(DT)
	assert_float(s.position.x).is_equal_approx(STATS.projectile_speed * DT * 6.0, 0.01)


func test_projectile_expires_at_lifetime_with_range() -> void:
	var s := _shot()
	var ticks := 0
	while s.advance(DT) and ticks < 1000:
		ticks += 1
	assert_bool(s.is_spent()).is_true()
	assert_float(s.age_s).is_equal_approx(STATS.lifetime_s, DT)
	assert_float(s.position.x).is_equal_approx(STATS.range_px(), STATS.projectile_speed * DT)


func test_one_hit_per_projectile() -> void:
	var s := _shot()
	var hits: Array[int] = [0]
	s.lance_hit.connect(func(_t: Node) -> void: hits[0] += 1)
	var target: Node2D = auto_free(Node2D.new())
	assert_bool(s.register_hit(target)).is_true()
	assert_bool(s.register_hit(target)).is_false()
	assert_int(hits[0]).is_equal(1)
	assert_bool(s.is_spent()).is_true()


func test_hit_damages_hurtbox_by_one() -> void:
	var hs := HealthStats.new()
	hs.max_hp = 5
	var hp := auto_free(HealthComponent.new()) as HealthComponent
	hp.stats = hs
	_holder.add_child(hp)
	var hb := auto_free(HurtboxComponent.new()) as HurtboxComponent
	hb.health = hp
	_holder.add_child(hb)
	_shot().register_hit(hb)
	assert_int(hp.current_hp).is_equal(4)
	_shot().register_hit(hb)   # a new shot is a new window
	assert_int(hp.current_hp).is_equal(3)


func test_projectile_uses_vigil_shots_layer() -> void:
	var s := _shot()
	assert_int(s.collision_layer).is_equal(PhysicsLayers.bit(PhysicsLayers.VIGIL_SHOTS))
