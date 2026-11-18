extends GdUnitTestSuite
## D-08 hull switch: CLI parse, validation and application at Vigil._ready.

const SCENE := preload("res://features/vigil/vigil.tscn")


func test_parse_valid_values() -> void:
	assert_int(HullMode.parse_args(PackedStringArray(["--hull=1"]))).is_equal(1)
	assert_int(HullMode.parse_args(PackedStringArray(["--stage=3", "--hull=2"]))).is_equal(2)


func test_parse_absent_or_invalid_is_minus_one() -> void:
	assert_int(HullMode.parse_args(PackedStringArray())).is_equal(-1)
	for bad in ["--hull=", "--hull=0", "--hull=3", "--hull=-1", "--hull=abc", "--hull=1.5"]:
		assert_int(HullMode.parse_args(PackedStringArray([bad]))).is_equal(-1)


func test_resolve_falls_back_to_data() -> void:
	assert_int(HullMode.resolve(-1, 1)).is_equal(1)
	assert_int(HullMode.resolve(7, 1)).is_equal(1)
	assert_int(HullMode.resolve(2, 1)).is_equal(2)
	assert_int(HullMode.resolve(1, 2)).is_equal(1)


func test_vigil_defaults_to_data_value_without_flag() -> void:
	var v := auto_free(SCENE.instantiate()) as Vigil
	add_child(v)
	assert_int(v.get_hull_max_hp()).is_equal(1)


func test_override_applies_and_invalid_keeps_data() -> void:
	var v := auto_free(SCENE.instantiate()) as Vigil
	add_child(v)
	v.apply_hull_override(2)
	assert_int(v.get_hull_max_hp()).is_equal(2)
	assert_int(v.health.current_hp).is_equal(2)
	var w := auto_free(SCENE.instantiate()) as Vigil
	add_child(w)
	w.apply_hull_override(9)
	assert_int(w.get_hull_max_hp()).is_equal(1)
