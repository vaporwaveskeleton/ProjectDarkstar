extends GdUnitTestSuite
## CH-7 quality ladder: data/aether/quality/quality_{high,medium,low}.tres load as AetherQuality
## with ds_aether.quality.* namespaces, step down monotonically, and every rung (low included)
## keeps the sphere curve, the entity's exact black and the play-band fog cap.

const U := preload("res://features/aether/tests/aether_test_util.gd")


func _q(level: String) -> AetherQuality:
	return load(AetherQuality.path_for(level)) as AetherQuality


func test_every_rung_loads_with_its_namespace() -> void:
	for level in AetherQuality.LEVELS:
		var q := _q(level)
		assert_object(q).override_failure_message("%s did not load" % level).is_not_null()
		assert_str(q.level).is_equal(level)
		assert_str(q.ds_namespace).is_equal("ds_aether.quality.%s" % level)
		for p in q.tunable_properties():
			var v: Variant = q.get(p)
			assert_bool(typeof(v) == TYPE_INT or typeof(v) == TYPE_FLOAT).override_failure_message("%s.%s is not numeric" % [level, p]).is_true()
	assert_str(AetherQuality.path_for("nonsense")).is_equal(AetherQuality.path_for("high"))


func test_rungs_step_down() -> void:
	var hi := _q("high")
	var md := _q("medium")
	var lo := _q("low")
	assert_int(lo.fog_octave_drop).is_greater_equal(md.fog_octave_drop)
	assert_int(md.fog_octave_drop).is_greater_equal(hi.fog_octave_drop)
	assert_float(lo.fog_resolution_scale).is_less_equal(0.5)
	assert_float(hi.fog_resolution_scale).is_equal(1.0)
	assert_float(lo.particle_scale).is_less(hi.particle_scale)
	assert_int(lo.animated_shafts).is_equal(0)
	assert_int(lo.max_fog_bands).is_less_equal(hi.max_fog_bands)


func test_low_keeps_sphere_entity_black_and_fog_cap() -> void:
	var b := (load(U.BACKDROP) as PackedScene).instantiate() as AetherBackdrop
	var look := load("res://data/aether/drowned_observatory_t3.tres") as AetherLook
	b.look = look
	add_child(b)
	await get_tree().process_frame
	b.apply_quality(_q("low"))
	b.set_drain(1.0)
	await get_tree().process_frame
	var layers := b.active_layers()
	for must in ["far_fog", "sky", "mid_fog", "entity"]:
		assert_bool(layers.has(must)).override_failure_message("low dropped %s" % must).is_true()
	var sphere := b.find_child("Sphere", true, false) as CrystalSphere
	assert_bool(sphere.visible).is_true()
	assert_float(float(sphere.get_param(&"radius"))).is_greater(0.0)
	var e := b.find_child("Entity", true, false) as EntityPresence
	assert_bool(e.visible).is_true()
	var code := (load("res://shaders/aether/entity_presence.gdshader") as Shader).code
	assert_bool(code.contains("COLOR = vec4(0.0, 0.0, 0.0, 1.0);")).is_true()
	var drawn := 0
	for n: Node in b.find_children("*", "AetherFogBand", true, false):
		var band := n as AetherFogBand
		assert_float(float(band.get_param(&"play_fog_ceiling"))).is_equal_approx(look.play_fog_ceiling, 0.0001)
		if band.is_drawn():
			drawn += 1
			assert_bool(band.is_offscreen()).override_failure_message("%s not half-res on low" % band.name).is_true()
	assert_int(drawn).is_greater_equal(2)
	b.free()


func test_high_draws_fog_in_place() -> void:
	var b := (load(U.BACKDROP) as PackedScene).instantiate() as AetherBackdrop
	b.look = load("res://data/aether/pale_marches_t1.tres") as AetherLook
	add_child(b)
	await get_tree().process_frame
	b.apply_quality(_q("high"))
	for n: Node in b.find_children("*", "AetherFogBand", true, false):
		assert_bool((n as AetherFogBand).is_offscreen()).is_false()
	assert_bool(b.offscreen_rids().is_empty()).is_true()
	b.free()
