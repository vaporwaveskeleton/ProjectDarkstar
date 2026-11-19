extends GdUnitTestSuite
## SectorGeode (SYS-001 §1.3): face hits, calm kill totals, over-fire window and detonation counts,
## scatter bound, seeded determinism, hurtbox one-hit-per-window, torus wrap.

const GEODE := "res://features/charges/sector_geode.tscn"
const STATS := "res://data/charges/geode.tres"
const DT := 1.0 / 60.0
const WORLD := Vector2(1920, 720)

var holder: Node2D
var field: ShardField
var torus: Torus


func before_test() -> void:
	SettingsService.persist = false
	holder = auto_free(Node2D.new())
	add_child(holder)
	torus = Torus.new(WORLD)
	field = (load("res://features/charges/shard_field.tscn") as PackedScene).instantiate()
	holder.add_child(field)
	field.set_physics_process(false)
	field.setup(torus)


func after_test() -> void:
	SettingsService.persist = true


func _geode(size_class: int, at: Vector2 = Vector2(400, 300), seed_value: int = 1) -> SectorGeode:
	var g: SectorGeode = (load(GEODE) as PackedScene).instantiate()
	g.configure(load(STATS), size_class, at, torus, field, RunSeed.new(seed_value).stream(RunSeed.STREAM_LOOT),
		RunSeed.new(seed_value).stream(RunSeed.STREAM_VFX))
	holder.add_child(g)
	g.set_physics_process(false)
	return g


## Lance hits at the base fire rate (6/s): one hit every 10 ticks.
func _calm_hit(g: SectorGeode) -> SectorGeode.Outcome:
	for t in 10:
		g.advance(DT)
	return g.register_lance_hit()


func test_data_matches_sys001() -> void:
	var s: GeodeStats = load(STATS)
	assert_int(s.face_hits).is_equal(5)
	assert_int(s.overfire_hits).is_equal(9)
	assert_float(s.overfire_window_s).is_equal(1.2)
	assert_int(s.overfire_warn_hits).is_equal(6)
	assert_int(s.shards_calm).is_equal(3)
	assert_int(s.shards_mined_bonus).is_equal(1)
	assert_int(s.shards_detonated_min).is_equal(4)
	assert_int(s.shards_detonated_max).is_equal(6)
	assert_float(s.detonation_scatter_px).is_equal(140.0)
	assert_array(Array(s.faces_by_class)).is_equal([1, 2, 3])
	assert_array(Array(s.radius_by_class)).is_equal([10.0, 15.0, 21.0])


func test_size_class_sets_faces_radius_and_hurtbox() -> void:
	var g := _geode(2)
	assert_int(g.faces).is_equal(3)
	assert_float(g.radius).is_equal(21.0)
	assert_float((g.get_node("%HurtShape").shape as CircleShape2D).radius).is_equal(21.0)
	assert_int(g.hurtbox.collision_layer).is_equal(PhysicsLayers.bit(PhysicsLayers.WORLD))
	assert_bool(g.hurtbox.monitorable).is_true()
	assert_int(g.health.max_hp).is_equal(15)


func test_small_geode_calm_kill_frees_four() -> void:
	var g := _geode(0)
	for k in 4:
		assert_int(_calm_hit(g)).is_equal(SectorGeode.Outcome.HIT)
	assert_int(_calm_hit(g)).is_equal(SectorGeode.Outcome.CALM_KILL)
	assert_int(field.live_count()).is_equal(4)
	assert_bool(g.alive).is_false()
	assert_bool(g.detonated).is_false()


func test_large_geode_face_by_face_totals_calm_plus_one() -> void:
	var g := _geode(2)
	var outcomes := []
	for k in 15:
		outcomes.append(_calm_hit(g))
	assert_int(outcomes[4]).is_equal(SectorGeode.Outcome.FACE_SHATTERED)
	assert_int(outcomes[9]).is_equal(SectorGeode.Outcome.FACE_SHATTERED)
	assert_int(outcomes[14]).is_equal(SectorGeode.Outcome.CALM_KILL)
	assert_int(field.live_count()).is_equal(4)   # 1 + 1 + max(1, 4 - 2)
	assert_bool(g.detonated).is_false()


func test_base_fire_rate_never_overfires_but_warns() -> void:
	# 6/s puts at most 8 hits inside 1.2 s, so calm fire can never reach 9 (see report).
	var g := _geode(2)
	for k in 14:
		_calm_hit(g)
		assert_int(g.recent_hits()).is_less_equal(8)
	assert_bool(g.detonated).is_false()
	assert_int(g.overfire_warnings).is_greater_equal(1)


func test_nine_hits_inside_the_window_detonates() -> void:
	var g := _geode(2)
	var last := SectorGeode.Outcome.NONE
	for k in 9:
		g.advance(1.2 / 10.0)
		last = g.register_lance_hit()
	assert_int(last).is_equal(SectorGeode.Outcome.DETONATED)
	assert_bool(g.detonated).is_true()
	assert_int(g.overfire_warnings).is_equal(1)
	# one face was mined first (1 shard), so the detonation adds total - 1; total is 4..6
	assert_int(field.live_count()).is_between(4, 6)


func test_hits_outside_the_window_do_not_count() -> void:
	var g := _geode(2)
	for k in 8:
		g.advance(0.01)
		g.register_lance_hit()
	g.advance(1.3)
	assert_int(g.recent_hits()).is_equal(0)
	assert_int(g.register_lance_hit()).is_not_equal(SectorGeode.Outcome.DETONATED)
	assert_bool(g.alive).is_true()


func test_detonation_with_no_prior_mining_frees_four_to_six() -> void:
	for s in range(1, 20):   # 19 × at most 6 stays inside the 144 pool
		var g := _geode(2, Vector2(400, 300), s)
		var before := field.live_count()
		g.detonate()
		assert_int(field.live_count() - before).is_between(4, 6)


func test_detonation_after_heavy_mining_still_frees_one() -> void:
	var g := _geode(2)
	g.shards_freed = 6
	g.detonate()
	assert_int(field.live_count()).is_equal(1)


func test_detonated_shards_come_to_rest_inside_the_scatter() -> void:
	var home := Vector2(1910, 5)   # near both seams
	for s in range(1, 20):
		var g := _geode(1, home, s)
		g.detonate()
	for t in 60 * 20:
		field.step(DT)
	assert_int(field.live_count()).is_greater(0)
	for i in field.live_indices():
		assert_float(torus.distance(home, field.positions[i])).is_less_equal(140.0)
		var p := field.positions[i]
		assert_bool(p.x >= 0.0 and p.x < WORLD.x and p.y >= 0.0 and p.y < WORLD.y).is_true()


func test_detonation_is_seeded_and_deterministic() -> void:
	var a := _geode(1, Vector2(800, 400), 42)
	a.detonate()
	var first := []
	for i in field.live_indices():
		first.append(field.positions[i])
	var field2: ShardField = (load("res://features/charges/shard_field.tscn") as PackedScene).instantiate()
	holder.add_child(field2)
	field2.setup(torus)
	var b: SectorGeode = (load(GEODE) as PackedScene).instantiate()
	b.configure(load(STATS), 1, Vector2(800, 400), torus, field2, RunSeed.new(42).stream(RunSeed.STREAM_LOOT))
	holder.add_child(b)
	b.detonate()
	var second := []
	for i in field2.live_indices():
		second.append(field2.positions[i])
	assert_array(second).is_equal(first)


func test_hurtbox_feeds_mining_once_per_window() -> void:
	var g := _geode(0)
	assert_bool(g.hurtbox.receive_hit(HitInfo.make(1, 99, 1, &"arc_lance"))).is_true()
	assert_bool(g.hurtbox.receive_hit(HitInfo.make(1, 99, 1, &"arc_lance"))).is_false()
	assert_int(g.hits_on_face).is_equal(1)
	assert_bool(g.hurtbox.receive_hit(HitInfo.make(1, 99, 2, &"arc_lance"))).is_true()
	assert_int(g.hits_on_face).is_equal(2)


func test_home_is_wrapped_into_the_torus() -> void:
	var g := _geode(0, Vector2(-10, 730))
	assert_vector(g.home).is_equal_approx(Vector2(1910, 10), Vector2(0.001, 0.001))
