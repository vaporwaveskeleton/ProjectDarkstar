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


func test_release_prewarms_takes_the_pending_loads() -> void:
	SceneRouter.prewarm(&"ruins")
	SceneRouter.release_prewarms()
	assert_object(SceneRouter.prewarmed(&"ruins")).is_null()
