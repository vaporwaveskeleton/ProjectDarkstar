extends GdUnitTestSuite
## ShardField (TECH-001 §4.3): data, magnet maths, collection to the cap with overflow staying,
## pool exhaustion, grid query correctness on a torus with a partial last row, Grub hook.

const SCENE := "res://features/charges/shard_field.tscn"
const STATS := "res://data/charges/shard_field.tres"
const MAG_STATS := "res://data/charges/charge_magazine.tres"
const DT := 1.0 / 60.0
## The M1 torus (Q-T57, 1920×720 ✱): 30 × 11.25 cells of 64 px.
const WORLD := Vector2(1920, 720)

var field: ShardField
var magazine: ChargeMagazine
var collector: Node2D


func before_test() -> void:
	SettingsService.persist = false
	magazine = auto_free(ChargeMagazine.new())
	magazine.stats = load(MAG_STATS)
	add_child(magazine)
	collector = auto_free(Node2D.new())
	add_child(collector)
	field = auto_free((load(SCENE) as PackedScene).instantiate())
	field.magazine = magazine
	add_child(field)
	field.set_physics_process(false)
	field.setup(Torus.new(WORLD))
	field.collector_radius_px = 6.0


func after_test() -> void:
	SettingsService.persist = true


func test_data_matches_sys001_and_rulings() -> void:
	var s: ShardFieldStats = load(STATS)
	assert_int(s.pool_size).is_equal(144)
	assert_float(s.grid_cell_px).is_equal(64.0)
	assert_float(s.magnet_radius_px).is_equal(96.0)
	assert_float(s.magnet_pull_px_s).is_equal(170.0)
	assert_float(s.drag_per_s).is_equal(1.2)
	assert_int(s.grub_query_interval_ticks).is_equal(6)
	assert_int(s.score_per_shard).is_equal(200)
	assert_bool(s.magnet_inverted).is_false()
	assert_str(s.ds_namespace).is_equal("ds_charges.shards")


func test_grid_covers_a_partial_last_row() -> void:
	assert_int(ShardField.cell_count(1920.0, 64.0)).is_equal(30)
	assert_int(ShardField.cell_count(720.0, 64.0)).is_equal(12)
	assert_object(field.grid_size()).is_equal(Vector2i(30, 12))
	var i := field.spawn(Vector2(5, 719.5), Vector2.ZERO)
	assert_int(field.cell_of(field.positions[i])).is_equal(11 * 30 + 0)


func test_cell_span_wraps_and_clamps() -> void:
	assert_array(Array(ShardField.cell_span(10.0, 100.0, 720.0, 64.0, 12))).is_equal([0, 1])
	# crosses the bottom seam: the partial row 11 (704..720) then rows 0..1
	assert_array(Array(ShardField.cell_span(700.0, 800.0, 720.0, 64.0, 12))).is_equal([10, 11, 0, 1])
	# crosses the top seam from a negative coordinate
	assert_array(Array(ShardField.cell_span(-20.0, 30.0, 720.0, 64.0, 12))).is_equal([10, 11, 0])
	assert_array(Array(ShardField.cell_span(-10.0, 30.0, 720.0, 64.0, 12))).is_equal([11, 0])
	# wider than the world: every row once
	assert_int(ShardField.cell_span(-500.0, 500.0, 720.0, 64.0, 12).size()).is_equal(12)
	# overlap after wrapping is listed once
	assert_array(Array(ShardField.cell_span(600.0, 1300.0, 720.0, 64.0, 12))).is_equal([9, 10, 11, 0, 1, 2, 3, 4, 5, 6, 7, 8])


func test_grid_query_matches_brute_force_on_the_torus() -> void:
	var rng := RunSeed.new(77).stream(RunSeed.STREAM_VFX)
	for k in 144:
		field.spawn(Vector2(rng.randf() * WORLD.x, rng.randf() * WORLD.y), Vector2.ZERO)
	var probes: Array[Vector2] = [Vector2(2, 3), Vector2(1918, 717), Vector2(960, 0), Vector2(0, 360),
		Vector2(1900, 710), Vector2(30, 705)]
	for k in 40:
		probes.append(Vector2(rng.randf() * WORLD.x, rng.randf() * WORLD.y))
	for at in probes:
		for r in [20.0, 96.0, 150.0]:
			var got := Array(field.query_circle(at, r))
			got.sort()
			var want := []
			for i in field.live_indices():
				if field.torus.distance(at, field.positions[i]) <= r:
					want.append(i)
			want.sort()
			assert_array(got).override_failure_message("query at %s r=%s" % [at, r]).is_equal(want)


func test_grid_stays_correct_while_shards_move() -> void:
	var rng := RunSeed.new(5).stream(RunSeed.STREAM_VFX)
	for k in 60:
		field.spawn(Vector2(rng.randf() * WORLD.x, rng.randf() * WORLD.y),
			Vector2.from_angle(rng.randf() * TAU) * 400.0)
	for t in 120:
		field.step(DT)
	var total := 0
	for c in field.grid_size().x * field.grid_size().y:
		total += field.cell_population(c)
	assert_int(total).is_equal(60)
	for i in field.live_indices():
		assert_int(field.cell_of(field.positions[i])).is_between(0, 30 * 12 - 1)
		assert_bool(field.query_circle(field.positions[i], 0.5).has(i)).is_true()


func test_step_velocity_drag_and_pull_maths() -> void:
	var s: ShardFieldStats = load(STATS)
	var damp := exp(-s.drag_per_s * DT)
	var steer := clampf(DT * s.magnet_steer_per_s, 0.0, 1.0)
	var v := ShardField.step_velocity(Vector2(100, 0), Vector2.ZERO, false, damp, steer, s.magnet_pull_px_s)
	assert_vector(v).is_equal_approx(Vector2(100.0 * exp(-1.2 / 60.0), 0), Vector2(1e-4, 1e-4))
	var p := ShardField.step_velocity(Vector2.ZERO, Vector2(0, 50), true, damp, steer, s.magnet_pull_px_s)
	assert_vector(p).is_equal_approx(Vector2(0, 170.0 * 0.1), Vector2(1e-4, 1e-4))
	# a shard held inside the radius converges on the pull speed
	var w := Vector2.ZERO
	for t in 120:
		w = ShardField.step_velocity(w, Vector2(1, 0), true, damp, steer, s.magnet_pull_px_s)
	assert_float(w.x).is_equal_approx(170.0, 0.01)


func test_drag_only_outside_the_magnet() -> void:
	collector.global_position = Vector2(100, 100)
	field.collector = collector
	var i := field.spawn(Vector2(400, 100), Vector2(50, 0))
	field.step(DT)
	assert_float(field.velocities[i].x).is_equal_approx(50.0 * exp(-1.2 * DT), 1e-4)
	assert_int(field.latch_count).is_equal(0)


func test_magnet_pulls_inside_the_radius_and_latches_once() -> void:
	collector.global_position = Vector2(100, 100)
	field.collector = collector
	var i := field.spawn(Vector2(180, 100), Vector2.ZERO)
	field.step(DT)
	assert_float(field.velocities[i].x).is_less(0.0)
	field.step(DT)
	assert_int(field.latch_count).is_equal(1)


func test_magnet_pulls_across_the_wrap_seam() -> void:
	collector.global_position = Vector2(10, 360)
	field.collector = collector
	var i := field.spawn(Vector2(1900, 360), Vector2.ZERO)   # 30 px away through the seam
	field.step(DT)
	assert_float(field.velocities[i].x).is_greater(0.0)
	for t in 60:
		field.step(DT)
	assert_int(magazine.count).is_equal(1)
	assert_bool(field.is_alive(i)).is_false()


func test_inverted_magnet_pushes_away() -> void:
	field.stats = (load(STATS) as ShardFieldStats).duplicate()
	field.stats.magnet_inverted = true
	collector.global_position = Vector2(100, 100)
	field.collector = collector
	var i := field.spawn(Vector2(150, 100), Vector2.ZERO)
	field.step(DT)
	assert_float(field.velocities[i].x).is_greater(0.0)


func test_collection_fills_the_magazine_and_overflow_stays() -> void:
	collector.global_position = Vector2(500, 300)
	field.collector = collector
	for k in 7:
		field.spawn(Vector2(500 + k, 300), Vector2.ZERO)
	field.step(DT)
	assert_int(magazine.count).is_equal(5)
	assert_bool(magazine.is_full()).is_true()
	assert_int(field.live_count()).is_equal(2)
	assert_int(field.score).is_equal(1000)
	assert_int(field.collected_total).is_equal(5)
	# magnet is off at the cap: the overflow glass is neither pulled nor collected
	for t in 120:
		field.step(DT)
	assert_int(field.live_count()).is_equal(2)
	assert_bool(field.magnet_active()).is_false()


func test_pool_exhaustion_refuses_without_crash() -> void:
	for k in field.pool_size():
		assert_int(field.spawn(Vector2(k * 10, 50), Vector2.ZERO)).is_greater_equal(0)
	assert_int(field.spawn(Vector2(1, 1), Vector2.ZERO)).is_equal(-1)
	assert_int(field.spawns_refused).is_equal(1)
	assert_int(field.live_count()).is_equal(144)
	# a collected shard frees its slot
	collector.global_position = Vector2(0, 50)
	field.collector = collector
	field.step(DT)
	assert_int(field.spawn(Vector2(1, 1), Vector2.ZERO)).is_greater_equal(0)


func test_shards_never_despawn() -> void:
	field.spawn(Vector2(10, 10), Vector2(300, 0))
	for t in 60 * 120:
		field.step(DT)
	assert_int(field.live_count()).is_equal(1)


func test_grub_hook_nearest_free_and_claims() -> void:
	var a := field.spawn(Vector2(100, 100), Vector2.ZERO)
	var b := field.spawn(Vector2(130, 100), Vector2.ZERO)
	field.spawn(Vector2(1000, 100), Vector2.ZERO)
	assert_int(field.nearest_free(Vector2(95, 100), 96.0)).is_equal(a)
	assert_bool(field.claim(a)).is_true()
	assert_bool(field.claim(a)).is_false()
	assert_int(field.nearest_free(Vector2(95, 100), 96.0)).is_equal(b)
	assert_int(field.free_count()).is_equal(2)
	field.release_claim(a)
	assert_int(field.free_count()).is_equal(3)
	assert_int(field.nearest_free(Vector2(1910, 100), 20.0)).is_equal(-1)
	var due := 0
	for t in 60:
		if field.grub_query_due(t):
			due += 1
	assert_int(due).is_equal(10)


func test_render_uses_one_multimesh_for_all_shards() -> void:
	for k in 12:
		field.spawn(Vector2(k * 20, 40), Vector2.ZERO)
	field.update_render()
	var mmi: MultiMeshInstance2D = field.get_node("%ShardMesh")
	assert_int(mmi.multimesh.instance_count).is_equal(144)
	assert_int(mmi.multimesh.visible_instance_count).is_equal(12)
