extends GdUnitTestSuite
## Data lint (TECH-001 §3.3): every tunable .tres under res://data has a valid, unique ds_ namespace,
## and the keys the bootstrap code depends on exist and hold usable values.

const REQUIRED_KEYS := [
	"ds_vigil.move.max_speed", "ds_vigil.move.accel", "ds_vigil.move.drag", "ds_vigil.move.brake",
	"ds_vigil.move.snap_turn", "ds_vigil.move.hitbox_circle_px",
	"ds_vigil.hull.max_hp", "ds_vigil.hull.invulnerable_after_hit_s",
]


func test_data_folder_lints_clean() -> void:
	var reg := TunableRegistry.new().scan()
	assert_array(Array(reg.errors)).is_empty()


func test_required_keys_present() -> void:
	var reg := TunableRegistry.new().scan()
	for key in REQUIRED_KEYS:
		assert_bool(reg.has_key(key)).override_failure_message("missing tunable %s" % key).is_true()


func test_vigil_movement_values_are_positive() -> void:
	var reg := TunableRegistry.new().scan()
	for key in REQUIRED_KEYS:
		if key.begins_with("ds_vigil.move."):
			assert_float(float(reg.get_value(key))).override_failure_message("%s must be > 0" % key).is_greater(0.0)


func test_hull_max_hp_is_one_or_more() -> void:
	# D-08 open: the value may be 1 or 2, never 0 (SYS-001 §1.2).
	var reg := TunableRegistry.new().scan()
	assert_int(int(reg.get_value("ds_vigil.hull.max_hp"))).is_greater_equal(1)


func test_duplicate_namespace_is_reported() -> void:
	var root := "user://lint_dup_%d" % Time.get_ticks_usec()
	DirAccess.make_dir_recursive_absolute(root)
	for i in 2:
		var s := HealthStats.new()
		s.ds_namespace = "ds_test.dup"
		ResourceSaver.save(s, root.path_join("dup_%d.tres" % i))
	var reg := TunableRegistry.new().scan(root)
	assert_int(reg.errors.size()).is_greater(0)
	for i in 2:
		DirAccess.remove_absolute(root.path_join("dup_%d.tres" % i))
	DirAccess.remove_absolute(root)


func test_malformed_namespace_is_reported() -> void:
	var root := "user://lint_bad_%d" % Time.get_ticks_usec()
	DirAccess.make_dir_recursive_absolute(root)
	var s := HealthStats.new()
	s.ds_namespace = "Vigil Hull"
	ResourceSaver.save(s, root.path_join("bad.tres"))
	var reg := TunableRegistry.new().scan(root)
	assert_int(reg.errors.size()).is_equal(1)
	DirAccess.remove_absolute(root.path_join("bad.tres"))
	DirAccess.remove_absolute(root)
