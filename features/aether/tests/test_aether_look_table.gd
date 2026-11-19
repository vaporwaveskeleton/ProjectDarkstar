extends GdUnitTestSuite
## Every data/aether/*.tres is an AetherLook with a ds_aether namespace and tunables; its colours
## are Pal entries; CHOIR only as the far-band tint at tier 4; never SIGNAL; GAS only as the
## orrery accent (the lamp's own brass, T4).

const U := preload("res://features/aether/tests/aether_test_util.gd")


func test_every_look_loads_with_a_namespace_and_tunables() -> void:
	var paths := U.look_paths()
	assert_int(paths.size()).is_greater_equal(5)
	for path in paths:
		var look := load(path) as AetherLook
		assert_object(look).override_failure_message("%s is not an AetherLook" % path).is_not_null()
		assert_str(look.ds_namespace).starts_with("ds_aether.")
		var props := look.tunable_properties()
		assert_bool(props.is_empty()).is_false()
		for p in props:
			var v: Variant = look.get(p)
			assert_bool(typeof(v) == TYPE_INT or typeof(v) == TYPE_FLOAT).override_failure_message("%s.%s is not numeric" % [path, p]).is_true()


func test_colours_follow_the_role_laws() -> void:
	for path in U.look_paths():
		var look := load(path) as AetherLook
		for field in look.colour_fields():
			var c: Color = look.get(field)
			if c.a <= 0.0:
				continue
			var name := U.pal_name(c)
			assert_str(name).override_failure_message("%s.%s is not a Pal entry" % [path, field]).is_not_empty()
			assert_str(name).override_failure_message("%s.%s: the Aether never uses SIGNAL" % [path, field]).is_not_equal("SIGNAL")
			assert_str(name).override_failure_message("%s.%s: NULL is the entity's alone" % [path, field]).is_not_equal("NULL")
			if name.begins_with("CHOIR-"):
				assert_bool(look.tier == 4 and field == "far_band_tint").override_failure_message("%s.%s: CHOIR only as the T4 far-band tint" % [path, field]).is_true()
			if name.begins_with("GAS-"):
				assert_str(field).override_failure_message("%s.%s: GAS only on the lantern" % [path, field]).is_equal("rib_accent")


func test_registry_accepts_the_aether_keys() -> void:
	var reg := TunableRegistry.new().scan()
	assert_array(Array(reg.errors)).is_empty()
	assert_bool(reg.has_key("ds_aether.pale_marches_t1.play_fog_ceiling")).is_true()
