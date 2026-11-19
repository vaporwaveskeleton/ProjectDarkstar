extends GdUnitTestSuite
## CabinetFxTuning: the presentation numbers behave exactly as the legacy literals did, and
## never exceed the SYS-001 §9 shake caps (4.0 px / 0.25 s).

const PATH := "res://data/cabinet/cabinet_fx_tuning.tres"
const SHAKE_AMP_CAP := 4.0
const SHAKE_DUR_CAP := 0.25


func test_resource_loads_with_namespace() -> void:
	var fx := load(PATH) as CabinetFxTuning
	assert_object(fx).is_not_null()
	assert_str(fx.ds_namespace).is_equal("ds_cabinet.fx")


func test_keys_are_registered() -> void:
	var reg := TunableRegistry.new().scan()
	assert_array(Array(reg.errors)).is_empty()
	assert_bool(reg.has_key("ds_cabinet.fx.entity_unmade_shake_amp")).is_true()
	assert_float(reg.get_value("ds_cabinet.fx.entity_unmade_shake_amp")).is_equal(4.0)
	assert_int(reg.get_value("ds_cabinet.fx.acolyte_death_burst_count")).is_equal(22)


func test_shake_fields_never_exceed_the_caps() -> void:
	var fx := load(PATH) as CabinetFxTuning
	var seen := 0
	for p in fx.tunable_properties():
		if p.ends_with("_shake_amp"):
			seen += 1
			assert_float(fx.get(p)).is_less_equal(SHAKE_AMP_CAP)
		elif p.ends_with("_shake_dur"):
			seen += 1
			assert_float(fx.get(p)).is_less_equal(SHAKE_DUR_CAP)
	assert_int(seen).is_greater(0)


func test_defaults_equal_the_legacy_literals() -> void:
	var fx := load(PATH) as CabinetFxTuning
	# Charge hit on the entity
	assert_int(fx.entity_hit_burst_count).is_equal(16)
	assert_float(fx.entity_hit_burst_speed).is_equal(140.0)
	assert_float(fx.entity_hit_ring_radius).is_equal(50.0)
	assert_float(fx.entity_hit_shake_amp).is_equal(4.0)
	assert_float(fx.entity_hit_shake_dur).is_equal(0.25)
	# Entity unmade
	assert_int(fx.entity_unmade_burst_a_count).is_equal(80)
	assert_float(fx.entity_unmade_burst_a_speed).is_equal(220.0)
	assert_int(fx.entity_unmade_burst_b_count).is_equal(40)
	assert_float(fx.entity_unmade_burst_b_speed).is_equal(160.0)
	assert_float(fx.entity_unmade_ring_radius).is_equal(160.0)
	# Vigil death
	assert_int(fx.vigil_death_burst_a_count).is_equal(40)
	assert_float(fx.vigil_death_burst_a_speed).is_equal(160.0)
	assert_int(fx.vigil_death_burst_b_count).is_equal(20)
	assert_float(fx.vigil_death_burst_b_speed).is_equal(90.0)
	assert_float(fx.vigil_death_ring_radius).is_equal(60.0)
	# IT WAKES
	assert_float(fx.it_wakes_ring_radius).is_equal(200.0)
	assert_float(fx.it_wakes_shake_amp).is_equal(4.0)
	# Modules knocked
	assert_int(fx.modules_knocked_burst_per_module).is_equal(10)
	assert_float(fx.modules_knocked_burst_speed).is_equal(120.0)
	assert_float(fx.modules_knocked_ring_radius).is_equal(40.0)
	assert_float(fx.modules_knocked_shake_amp).is_equal(3.0)
	assert_float(fx.modules_knocked_shake_dur).is_equal(0.2)
	# Acolyte and geode
	assert_int(fx.acolyte_death_burst_count).is_equal(22)
	assert_float(fx.acolyte_death_shake_amp).is_equal(2.0)
	assert_float(fx.geode_violent_ring_scale).is_equal(3.0)
	assert_float(fx.geode_break_ring_scale).is_equal(1.6)
