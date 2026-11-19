extends GdUnitTestSuite
## GeodeSandbox: 10 geodes, seeded layout (map stream), clear spawn ring on the torus, compass
## registration, torus images near the reference.

const STATS := "res://data/charges/geode_sandbox.tres"
const GEODE_STATS := "res://data/charges/geode.tres"
const WORLD := Vector2(1920, 720)


func _layout(seed_value: int, world: Vector2 = WORLD) -> Array[Dictionary]:
	var s: GeodeSandboxStats = load(STATS)
	return GeodeSandbox.layout(RunSeed.new(seed_value), s, 3, Torus.new(world), Vector2(320, 180))


func test_data_values() -> void:
	var s: GeodeSandboxStats = load(STATS)
	assert_int(s.geode_count).is_equal(10)
	assert_str(s.ds_namespace).is_equal("ds_charges.sandbox")


func test_layout_is_deterministic_per_seed() -> void:
	assert_array(_layout(8)).is_equal(_layout(8))
	assert_array(_layout(8)).is_not_equal(_layout(9))


func test_layout_classes_positions_and_clear_ring() -> void:
	var s: GeodeSandboxStats = load(STATS)
	var t := Torus.new(WORLD)
	for seed_value in range(1, 40):
		var lay := _layout(seed_value)
		assert_int(lay.size()).is_equal(10)
		for e in lay:
			assert_int(int(e.size_class)).is_between(0, 2)
			var p: Vector2 = e.pos
			assert_bool(p.x >= 0.0 and p.x < WORLD.x and p.y >= 0.0 and p.y < WORLD.y).is_true()
			assert_float(t.distance(p, Vector2(320, 180))).is_greater_equal(s.spawn_clear_radius_px)


func test_populate_registers_geodes_and_places_images_near_reference() -> void:
	var holder: Node2D = auto_free(Node2D.new())
	add_child(holder)
	var field: ShardField = (load("res://features/charges/shard_field.tscn") as PackedScene).instantiate()
	holder.add_child(field)
	var torus := Torus.new(WORLD)
	field.setup(torus)
	var sandbox := GeodeSandbox.new()
	sandbox.stats = load(STATS)
	sandbox.geode_stats = load(GEODE_STATS)
	sandbox.shard_field = field
	holder.add_child(sandbox)
	var ref := Node2D.new()
	holder.add_child(ref)
	ref.global_position = Vector2(1900, 700)
	sandbox.populate(torus, Vector2(320, 180), ref)
	assert_int(sandbox.alive_count()).is_equal(10)
	for g in sandbox.geodes:
		assert_bool(g.is_in_group(LedgerCompass.GROUP)).is_true()
		assert_str(str(LedgerCompass.kind_of(g))).is_equal("geode")
		var d := g.global_position - ref.global_position
		assert_bool(absf(d.x) <= WORLD.x * 0.5 and absf(d.y) <= WORLD.y * 0.5).is_true()
		assert_vector(torus.wrap(g.global_position)).is_equal_approx(g.home, Vector2(0.01, 0.01))
	sandbox.geodes[0].detonate()
	assert_int(sandbox.alive_count()).is_equal(9)
	assert_int(field.live_count()).is_between(4, 6)
