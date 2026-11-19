extends GdUnitTestSuite
## ART-001 §4 / §16: the lantern is the key light. No other PointLight2D reaches its energy,
## GAS (gaslight) appears only on the lantern, and background emitters stay under its core.

const U := preload("res://features/aether/tests/aether_test_util.gd")
const GALLERY := "res://scenes/dev/aether_gallery/aether_gallery.tscn"


func test_only_the_lantern_light_is_strongest() -> void:
	var g: Node = (load(GALLERY) as PackedScene).instantiate()
	add_child(g)
	await get_tree().process_frame
	var nodes: Array[Node] = []
	U.walk(g, nodes)
	var lantern: LanternMarker = null
	for n in nodes:
		if n is LanternMarker:
			lantern = n as LanternMarker
	assert_object(lantern).is_not_null()
	for i in 6:
		g.call("show_exhibit", i)
		await get_tree().process_frame
		var key := lantern.light.energy
		assert_float(key).is_greater(0.0)
		assert_bool(U.is_ramp(lantern.light.color, "GAS")).is_true()
		for n in nodes:
			if n is PointLight2D and n != lantern.light:
				assert_float((n as PointLight2D).energy).override_failure_message("%s out-shines the lantern" % n.name).is_less(key)
	g.free()


func test_emitters_are_never_gas_and_stay_under_the_lantern() -> void:
	for path in U.look_paths():
		var look := load(path) as AetherLook
		var b := (load(U.BACKDROP) as PackedScene).instantiate() as AetherBackdrop
		b.look = look
		add_child(b)
		await get_tree().process_frame
		var nodes: Array[Node] = []
		U.walk(b, nodes)
		for n in nodes:
			if n is AetherLife and (n as AetherLife).visible:
				var life := n as AetherLife
				assert_bool(U.is_ramp(life.colour, "GAS")).override_failure_message("%s %s is GAS" % [path, n.name]).is_false()
				var glow: float = life.draw_mat.get_shader_parameter(&"glow")
				assert_float(glow).is_less(LanternMarker.CORE_HDR)
		for c: Color in [look.sphere_glass, look.life_glow, look.life_secondary, look.crack_edge, look.behind_a,
				look.behind_b, look.shaft_tint, look.fog_deep, look.fog_mid, look.fog_high, look.far_silhouette]:
			assert_bool(U.is_ramp(c, "GAS")).override_failure_message("%s uses GAS off the lantern" % path).is_false()
		assert_float(look.shaft_intensity).is_less(0.5)
		assert_float(look.glow_threshold).is_less(LanternMarker.CORE_HDR)
		b.free()
