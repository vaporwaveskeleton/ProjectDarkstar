extends GdUnitTestSuite
## AudioService.set_subtraction: the entity heard as sound removed (AUDIO-001 §12.14).
## Fresh service nodes (not the autoload); _process is driven by hand.

const AudioServiceScript := preload("res://autoload/audio_service.gd")
const TOUCHED: Array[StringName] = [&"BUS-AMB", &"BUS-MUS"]
const UNTOUCHED: Array[StringName] = [&"BUS-ENT", &"BUS-CHO", &"BUS-FLY", &"BUS-UI"]


func _make() -> AudioServiceScript:
	var svc := AudioServiceScript.new()
	add_child(svc)
	auto_free(svc)
	return svc


func _cutoff(bus: StringName) -> float:
	var b := AudioServer.get_bus_index(bus)
	for i in AudioServer.get_bus_effect_count(b):
		var lp := AudioServer.get_bus_effect(b, i) as AudioEffectLowPassFilter
		if lp != null:
			return lp.cutoff_hz
	return -1.0


func _fx_enabled(bus: StringName) -> bool:
	var b := AudioServer.get_bus_index(bus)
	for i in AudioServer.get_bus_effect_count(b):
		if AudioServer.get_bus_effect(b, i) is AudioEffectLowPassFilter:
			return AudioServer.is_bus_effect_enabled(b, i)
	return false


func _db(bus: StringName) -> float:
	return AudioServer.get_bus_volume_db(AudioServer.get_bus_index(bus))


func test_starts_at_zero_with_the_filter_bypassed() -> void:
	var svc := _make()
	assert_float(svc.subtraction()).is_equal(0.0)
	for bus in TOUCHED:
		assert_bool(_fx_enabled(bus)).is_false()
		assert_float(_db(bus)).is_equal(0.0)


func test_ramp_zero_is_immediate_with_endpoint_cutoffs_and_cut() -> void:
	var svc := _make()
	svc.set_subtraction(1.0)
	assert_float(svc.subtraction()).is_equal(1.0)
	for bus in TOUCHED:
		assert_bool(_fx_enabled(bus)).is_true()
		assert_float(_cutoff(bus)).is_equal_approx(AudioServiceScript.SUBTRACTION_CLOSED_HZ, 0.5)
		assert_float(_db(bus)).is_equal_approx(AudioServiceScript.SUBTRACTION_CUT_DB, 0.001)


func test_cutoff_is_exponential_and_volume_linear_in_amount() -> void:
	var svc := _make()
	svc.set_subtraction(0.5)
	var want := AudioServiceScript.SUBTRACTION_OPEN_HZ * sqrt(AudioServiceScript.SUBTRACTION_CLOSED_HZ / AudioServiceScript.SUBTRACTION_OPEN_HZ)
	assert_float(_cutoff(&"BUS-AMB")).is_equal_approx(want, 1.0)
	assert_float(_db(&"BUS-MUS")).is_equal_approx(AudioServiceScript.SUBTRACTION_CUT_DB * 0.5, 0.001)


func test_ramp_runs_linearly_over_ramp_s() -> void:
	var svc := _make()
	svc.set_subtraction(1.0, 4.0)
	assert_float(svc.subtraction()).is_equal(0.0)
	svc._process(1.0)
	assert_float(svc.subtraction()).is_equal_approx(0.25, 0.0001)
	svc._process(1.0)
	assert_float(svc.subtraction()).is_equal_approx(0.5, 0.0001)
	svc._process(1.0)
	svc._process(1.0)
	assert_float(svc.subtraction()).is_equal(1.0)
	svc._process(1.0)
	assert_float(svc.subtraction()).is_equal(1.0)


func test_ramp_back_down_starts_from_where_it_was() -> void:
	var svc := _make()
	svc.set_subtraction(1.0)
	svc.set_subtraction(0.0, 2.0)
	svc._process(1.0)
	assert_float(svc.subtraction()).is_equal_approx(0.5, 0.0001)
	svc._process(1.0)
	assert_float(svc.subtraction()).is_equal(0.0)
	assert_bool(_fx_enabled(&"BUS-AMB")).is_false()
	assert_float(_db(&"BUS-AMB")).is_equal(0.0)


func test_amount_is_clamped() -> void:
	var svc := _make()
	svc.set_subtraction(3.0)
	assert_float(svc.subtraction()).is_equal(1.0)
	svc.set_subtraction(-2.0)
	assert_float(svc.subtraction()).is_equal(0.0)


func test_only_ambience_and_music_buses_are_touched() -> void:
	var svc := _make()
	svc.set_subtraction(1.0)
	for bus in UNTOUCHED:
		var b := AudioServer.get_bus_index(bus)
		assert_float(_db(bus)).is_equal(0.0)
		for i in AudioServer.get_bus_effect_count(b):
			assert_bool(AudioServer.get_bus_effect(b, i) is AudioEffectLowPassFilter).is_false()


func test_zero_restores_bypass_and_original_volume() -> void:
	var svc := _make()
	svc.set_subtraction(0.7)
	svc.set_subtraction(0.0)
	for bus in TOUCHED:
		assert_bool(_fx_enabled(bus)).is_false()
		assert_float(_db(bus)).is_equal_approx(0.0, 0.0001)
		assert_float(_cutoff(bus)).is_equal_approx(AudioServiceScript.SUBTRACTION_OPEN_HZ, 0.5)


func test_stop_all_resets_instantly_even_mid_ramp() -> void:
	var svc := _make()
	svc.set_subtraction(1.0, 10.0)
	svc._process(5.0)
	assert_float(svc.subtraction()).is_greater(0.0)
	svc.stop_all()
	assert_float(svc.subtraction()).is_equal(0.0)
	assert_bool(_fx_enabled(&"BUS-AMB")).is_false()
	svc._process(5.0)
	assert_float(svc.subtraction()).is_equal(0.0)


func test_second_service_reuses_the_filter_and_does_not_stack_effects() -> void:
	var a := _make()
	var count := AudioServer.get_bus_effect_count(AudioServer.get_bus_index(&"BUS-AMB"))
	var b := _make()
	assert_int(AudioServer.get_bus_effect_count(AudioServer.get_bus_index(&"BUS-AMB"))).is_equal(count)
	assert_float(b.subtraction()).is_equal(0.0)
	assert_object(a).is_not_null()


func test_without_a_caller_nothing_changes() -> void:
	var svc := _make()
	svc._process(1.0)
	assert_float(svc.subtraction()).is_equal(0.0)
	assert_bool(_fx_enabled(&"BUS-MUS")).is_false()
