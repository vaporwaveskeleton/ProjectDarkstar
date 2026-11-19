extends GdUnitTestSuite
## RunSession autoload smoke (TECH-001 §2.8, §4.1, §4.2a): registered, stage −20, pausable, owns
## exactly one core built from the shipped stats, and is a thin forwarder. Reads only; never
## mutates the autoload's live state. The `run/session` automation id resolves on it.

const UiView := preload("res://core/automation/ui_view.gd")


func test_registered_in_project_settings() -> void:
	assert_str(str(ProjectSettings.get_setting("autoload/RunSession", ""))).is_equal("*res://autoload/run_session.gd")
	assert_object(get_tree().root.get_node_or_null("RunSession")).is_not_null()


func test_priority_and_process_mode() -> void:
	var rs: Node = get_tree().root.get_node("RunSession")
	assert_int(rs.process_physics_priority).is_equal(-20)
	assert_int(rs.process_mode).is_equal(Node.PROCESS_MODE_PAUSABLE)


func test_owns_exactly_one_core_with_shipped_stats() -> void:
	var rs: Node = get_tree().root.get_node("RunSession")
	assert_object(rs.core).is_not_null()
	assert_bool(rs.core is RunSessionCore).is_true()
	assert_str((rs.core as RunSessionCore).stats.resource_path).is_equal("res://data/run/run_session.tres")
	var cores := 0
	for p in rs.get_property_list():
		if rs.get(p.name) is RunSessionCore:
			cores += 1
	assert_int(cores).is_equal(1)


func test_unscaled_delta_ignores_time_scale() -> void:
	var script: GDScript = load("res://autoload/run_session.gd")
	var before := Engine.time_scale
	Engine.time_scale = 0.25
	assert_float(script.unscaled(0.25)).is_equal_approx(1.0, 0.0001)
	Engine.time_scale = before


func test_probe_id_reads_the_autoload() -> void:
	var view := UiView.new(null)
	for prop in ["ember", "act0_banked", "hourglass_left", "skies_dark", "seam_index", "clock_paused"]:
		var r: Dictionary = view.read("run/session", prop)
		assert_bool(r.ok).override_failure_message("%s: %s" % [prop, r.error]).is_true()
	assert_bool(view.read("run/session", "core").ok).is_false()
