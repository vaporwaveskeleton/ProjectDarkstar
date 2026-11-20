extends GdUnitTestSuite
## Q-T340: SceneWarmup finds shaders whose material a node builds in code (AetherShaderRect), and the
## router drops pending prewarms (Q-T341).

const BACKDROP := "res://features/aether/aether_backdrop.tscn"


func test_materials_of_wraps_the_exported_shader_of_a_code_material_node() -> void:
	var sh := load("res://shaders/aether/frost_presence.gdshader") as Shader
	var rect := AetherShaderRect.new()
	rect.shader = sh
	var mats := SceneWarmup.materials_of(rect)
	rect.free()
	assert_int(mats.size()).is_equal(1)
	assert_bool((mats[0] as ShaderMaterial).shader == sh).is_true()


func test_materials_of_the_aether_backdrop_covers_every_layer_shader() -> void:
	var inst := (load(BACKDROP) as PackedScene).instantiate()
	var want := {}
	var stack: Array[Node] = [inst]
	while not stack.is_empty():
		var n: Node = stack.pop_back()
		stack.append_array(n.get_children())
		if n is AetherShaderRect and (n as AetherShaderRect).shader != null:
			want[(n as AetherShaderRect).shader] = true
	var got := {}
	for m in SceneWarmup.materials_of(inst):
		if m is ShaderMaterial and (m as ShaderMaterial).shader != null:
			got[(m as ShaderMaterial).shader] = true
	inst.free()
	assert_bool(want.size() >= 8).is_true()
	for sh: Variant in want.keys():
		assert_bool(got.has(sh)).override_failure_message("shader not warmed: %s" % [(sh as Shader).resource_path]).is_true()


func test_warm_spread_draws_every_job_over_several_frames_and_finishes() -> void:
	var host := Node.new()
	add_child(host)
	var state := {}
	var frames := 0
	SceneWarmup.warm_spread(host, BACKDROP, state)
	while not bool(state["done"]) and frames < 600:
		await get_tree().process_frame
		frames += 1
	host.queue_free()
	assert_bool(bool(state["done"])).is_true()
	assert_int(int(state["jobs"])).is_greater(10)
	assert_int(int(state["left"])).is_equal(0)
	assert_int(frames).is_greater(2)


func test_shader_jobs_of_the_unmaking_cover_layers_and_particles_without_instancing() -> void:
	var jobs := SceneWarmup.shader_jobs("res://features/aether/aether_arrival.tscn")
	var paths: Array[String] = []
	var particles_with_draw := 0
	for j: Variant in jobs:
		var d := j as Dictionary
		paths.append((d["shader"] as Shader).resource_path)
		if (d["shader"] as Shader).get_mode() == Shader.MODE_PARTICLES and d["draw"] != null:
			particles_with_draw += 1
	assert_array(paths).contains(["res://shaders/aether/frost_presence.gdshader", "res://shaders/aether/aether_present.gdshader"])
	assert_int(particles_with_draw).is_equal(1)
	assert_array(paths).not_contains(["res://shaders/aether/aether_life_draw.gdshader"])


func test_release_prewarms_takes_the_pending_loads() -> void:
	SceneRouter.prewarm(&"ruins")
	SceneRouter.release_prewarms()
	assert_object(SceneRouter.prewarmed(&"ruins")).is_null()
