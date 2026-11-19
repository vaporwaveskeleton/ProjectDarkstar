extends GdUnitTestSuite
## ART-001 §16: the only pure black is the entity. Every black colour source in the backdrop
## belongs to a node in group `entity_presence`; fog colours never fall below VOID_0.

const U := preload("res://features/aether/tests/aether_test_util.gd")


func _backdrop_with(path: String) -> AetherBackdrop:
	var b := (load(U.BACKDROP) as PackedScene).instantiate() as AetherBackdrop
	b.look = load(path) as AetherLook
	add_child(b)
	return b


func test_every_black_source_belongs_to_the_entity() -> void:
	for path in U.look_paths():
		var b := _backdrop_with(path)
		b.set_drain(1.0)
		await get_tree().process_frame
		var nodes: Array[Node] = []
		U.walk(b, nodes)
		var bad: Array[String] = []
		for n in nodes:
			if not (n is CanvasItem):
				continue
			var ci := n as CanvasItem
			if U.is_black(ci.modulate) or U.is_black(ci.self_modulate):
				if not U.in_entity_group(n):
					bad.append("%s modulate" % n.name)
			if n is ColorRect and U.is_black((n as ColorRect).color) and not U.in_entity_group(n):
				bad.append("%s color" % n.name)
			var mats: Array[ShaderMaterial] = []
			if ci.material is ShaderMaterial:
				mats.append(ci.material as ShaderMaterial)
			if n is GPUParticles2D and (n as GPUParticles2D).process_material is ShaderMaterial:
				mats.append((n as GPUParticles2D).process_material as ShaderMaterial)
			for m in mats:
				var cols := U.colour_uniforms(m)
				for k: Variant in cols.keys():
					if U.is_black(cols[k] as Color) and not U.in_entity_group(n):
						bad.append("%s.%s" % [n.name, k])
		assert_array(bad).override_failure_message("%s: black outside entity_presence: %s" % [path, bad]).is_empty()
		b.free()


func test_fog_band_colours_sit_on_or_above_void_0() -> void:
	var floor_l := Pal.VOID_0.get_luminance()
	for path in U.look_paths():
		var b := _backdrop_with(path)
		await get_tree().process_frame
		var nodes: Array[Node] = []
		U.walk(b, nodes)
		var bands := 0
		for n in nodes:
			if n is AetherFogBand:
				bands += 1
				var band := n as AetherFogBand
				for p in band.colour_params():
					var c: Color = band.get_param(p)
					assert_float(c.get_luminance()).override_failure_message("%s %s.%s below VOID_0" % [path, n.name, p]).is_greater_equal(floor_l - 0.001)
				assert_bool(U.same_rgb(band.get_param(&"floor_col") as Color, Pal.VOID_0)).is_true()
		assert_int(bands).is_greater_equal(3)
		b.free()


func test_entity_nodes_are_in_the_group_and_unlit() -> void:
	var b := _backdrop_with("res://data/aether/the_black_t5.tres")
	await get_tree().process_frame
	var ents := get_tree().get_nodes_in_group(EntityPresence.GROUP)
	assert_int(ents.size()).is_greater_equal(4)
	for e: Node in ents:
		assert_int((e as CanvasItem).light_mask).is_equal(0)
	var code := (load("res://shaders/aether/entity_presence.gdshader") as Shader).code
	assert_bool(code.contains("COLOR = vec4(0.0, 0.0, 0.0, 1.0);")).is_true()
	b.free()


func test_grade_keeps_a_floor_and_spares_entity_pixels() -> void:
	var code := (load("res://shaders/aether/aether_grade.gdshader") as Shader).code
	assert_bool(code.contains("max(sub, floor_col)")).is_true()
	var fog := (load("res://shaders/aether/aether_fog_band.gdshader") as Shader).code
	assert_bool(fog.contains("col = max(col, floor_col);")).is_true()
