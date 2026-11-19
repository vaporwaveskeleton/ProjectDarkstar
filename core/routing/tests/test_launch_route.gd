extends GdUnitTestSuite
## Dev launch switch `--route=<id>`: parse, validation against the route table, release gate.

const TABLE := preload("res://data/routes/route_table.tres")


func _args(list: Array[String]) -> PackedStringArray:
	return PackedStringArray(list)


func test_arg_value_reads_key_value() -> void:
	assert_str(LaunchRoute.arg_value(_args(["--no-save", "--route=sector"]), "route")).is_equal("sector")
	assert_str(LaunchRoute.arg_value(_args(["--hull=2"]), "route")).is_equal("")
	assert_str(LaunchRoute.arg_value(_args(["--router=x"]), "route")).is_equal("")


func test_valid_route_wins_in_dev_build() -> void:
	var r := LaunchRoute.resolve(_args(["--route=sector", "--hull=2", "--no-save"]), TABLE, true)
	assert_str(str(r)).is_equal("sector")


func test_unknown_or_empty_route_falls_back() -> void:
	for bad in ["--route=", "--route=nowhere", "--route=../sector", "--route=SECTOR"]:
		assert_str(str(LaunchRoute.resolve(_args([bad]), TABLE, true))).is_equal(str(TABLE.initial_route))
	assert_str(str(LaunchRoute.resolve(_args([]), TABLE, true))).is_equal(str(TABLE.initial_route))


func test_release_build_ignores_switch() -> void:
	var r := LaunchRoute.resolve(_args(["--route=sector"]), TABLE, false)
	assert_str(str(r)).is_equal(str(TABLE.initial_route))


func test_gate_uses_automation_feature_tags() -> void:
	assert_array(LaunchRoute.DEV_FEATURES).contains_exactly(["editor", "automation_dev", "automation_qa"])
	var expected := OS.has_feature("editor") or OS.has_feature("automation_dev") or OS.has_feature("automation_qa")
	assert_bool(LaunchRoute.is_dev_build()).is_equal(expected)


func test_null_table_returns_empty() -> void:
	assert_str(str(LaunchRoute.resolve(_args(["--route=sector"]), null, true))).is_equal("")
