extends GdUnitTestSuite
## Gate: argument parsing, --out confinement, and runners that finish refused/invalid instead of crashing.

const Gate := preload("res://core/automation/automation_gate.gd")


func _runner(args: PackedStringArray) -> Node:
	return auto_free(Gate.create_runner(args))


func test_arg_parsing() -> void:
	var a := PackedStringArray(["--no-save", "--scenario=abc", "--out=user://x"])
	assert_str(Gate.arg_value(a, "scenario")).is_equal("abc")
	assert_str(Gate.arg_value(a, "out")).is_equal("user://x")
	assert_str(Gate.arg_value(a, "missing")).is_equal("")
	assert_bool(Gate.has_scenario_arg(a)).is_true()
	assert_bool(Gate.has_scenario_arg(PackedStringArray(["--smoke"]))).is_false()


func test_valid_scenario_gets_default_out_dir() -> void:
	var r := _runner(PackedStringArray(["--scenario=a0_first_contact"]))
	assert_bool(r.get("_preset").is_empty()).is_true()
	assert_str(r.get("_scenario").id).is_equal("a0_first_contact")
	assert_str(r.get("_opts").out_dir).is_equal("user://automation/a0_first_contact")
	assert_bool(r.get("_opts").quit_on_finish).is_true()


func test_invalid_ids_and_missing_files_are_exit_2() -> void:
	for arg in ["--scenario=Bad Id", "--scenario=", "--scenario=../x", "--scenario=no_such_scenario"]:
		var p: Dictionary = _runner(PackedStringArray([arg])).get("_preset")
		assert_str(p.outcome).is_equal("invalid")
		assert_int(p.code).is_equal(2)


func test_out_confinement() -> void:
	var reports := ProjectSettings.globalize_path("res://reports").replace("\\", "/")
	assert_str(Gate.confine_out("user://automation/x")).is_not_empty()
	assert_str(Gate.confine_out(reports + "/automation/x")).is_not_empty()
	assert_str(Gate.confine_out("user://a/../b")).is_empty()
	assert_str(Gate.confine_out(reports + "/../elsewhere")).is_empty()
	assert_str(Gate.confine_out("C:/Windows/Temp/x")).is_empty()
	assert_str(Gate.confine_out("/etc/x")).is_empty()
	assert_str(Gate.confine_out("relative/dir")).is_empty()
	var p: Dictionary = _runner(PackedStringArray(["--scenario=a0_first_contact", "--out=C:/Windows/Temp/x"])).get("_preset")
	assert_str(p.outcome).is_equal("refused")
	assert_int(p.code).is_equal(3)


func test_boot_helper_returns_null_without_the_arg() -> void:
	var boot: Node = auto_free(load("res://scenes/boot/boot.gd").new())
	assert_object(boot.call("_make_automation_runner")).is_null()


func test_record_arg_and_node_factory() -> void:
	var a := PackedStringArray(["--record=my_run", "--no-save"])
	assert_bool(Gate.has_record_arg(a)).is_true()
	assert_bool(Gate.has_record_arg(PackedStringArray(["--scenario=x"]))).is_false()
	var rec: Node = auto_free(Gate.create_node(a))
	assert_str(rec.get_script().resource_path).is_equal("res://core/automation/recorder.gd")
	var run: Node = auto_free(Gate.create_node(PackedStringArray(["--scenario=a0_first_contact"])))
	assert_str(run.get_script().resource_path).is_equal("res://core/automation/scenario_runner.gd")
