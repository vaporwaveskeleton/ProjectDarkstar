extends GdUnitTestSuite
## Canary, run late (zz): no routed scene may be left under /root by an earlier suite. A test that calls
## SceneRouter.go_to without a registered host makes the router fall back to change_scene_to_packed,
## which leaves the scene alive for the rest of the run (Q-T247: a stray attract's 30 s demo timer
## routed cabinet inside other tests). Use FakeRouteHost (tests/support) in such tests.


func test_no_routed_scene_is_left_under_root() -> void:
	var routed: Array[String] = []
	for id: Variant in SceneRouter.table.routes.keys():
		routed.append(SceneRouter.table.path_for(StringName(str(id))))
	var stray: Array[String] = []
	for n in get_tree().root.get_children():
		if n.scene_file_path != "" and routed.has(n.scene_file_path):
			stray.append("%s (%s)" % [n.name, n.scene_file_path])
	assert_array(stray).override_failure_message("routed scenes left under /root: %s" % [stray]).is_empty()
