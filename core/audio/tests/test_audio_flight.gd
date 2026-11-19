extends GdUnitTestSuite
## The Aether Vigil's sound of flying (AUDIO-001 §12.18, C11–C16; TECH-001 Q-T42): the pure FlightMix
## mapping, and the AudioService flight layers driven through set_flight / stop_flight / silence.

const AudioServiceScript := preload("res://autoload/audio_service.gd")
const DT := 1.0 / 60.0

var _s: AudioMixStats


func before_test() -> void:
	_s = load("res://data/audio/mix_stats.tres") as AudioMixStats


func _make() -> AudioServiceScript:
	var svc := AudioServiceScript.new()
	add_child(svc)
	svc.set_process(false)
	auto_free(svc)
	return svc


func _run(svc: AudioServiceScript, seconds: float) -> void:
	for i in int(round(seconds / DT)):
		svc._process(DT)


func _db(t: Dictionary, id: StringName) -> float:
	var v: Vector2 = t[id]
	return v.x


func _pitch(t: Dictionary, id: StringName) -> float:
	var v: Vector2 = t[id]
	return v.y


# --- the mapping ------------------------------------------------------------------------------------

func test_mix_stats_namespace_and_keys() -> void:
	assert_object(_s).is_not_null()
	assert_str(_s.ds_namespace).is_equal("ds_audio.mix")
	assert_bool(_s.ds_keys().has("ds_audio.mix.engine_idle_db")).is_true()
	assert_bool(_s.ds_keys().has("ds_audio.mix.duck_attack_s")).is_true()


func test_at_rest_only_engine_idle_and_lantern_sound() -> void:
	var t := FlightMix.targets(0.0, 0.0, 0.0, _s)
	assert_float(_db(t, FlightMix.ENGINE)).is_equal_approx(_s.engine_idle_db, 0.001)
	assert_float(_pitch(t, FlightMix.ENGINE)).is_equal_approx(_s.engine_pitch_min, 0.001)
	assert_float(_db(t, FlightMix.BOILER)).is_equal(_s.flight_floor_db)
	assert_float(_db(t, FlightMix.RIGGING)).is_equal(_s.flight_floor_db)
	assert_float(_db(t, FlightMix.LANTERN)).is_equal_approx(_s.lantern_db, 0.001)


func test_thrust_opens_the_boiler_and_drift_sings_the_rigging() -> void:
	var thrusting := FlightMix.targets(1.0, 1.0, 0.0, _s)
	var drifting := FlightMix.targets(1.0, 0.0, 0.0, _s)
	assert_float(_db(thrusting, FlightMix.BOILER)).is_equal_approx(_s.boiler_full_db, 0.001)
	assert_float(_db(drifting, FlightMix.BOILER)).is_equal(_s.flight_floor_db)
	assert_float(_db(drifting, FlightMix.RIGGING)).is_equal_approx(_s.rigging_full_db, 0.001)
	assert_float(_db(thrusting, FlightMix.RIGGING)).is_equal(_s.flight_floor_db)
	# a hard turn under thrust still loads the rigging
	var turning := FlightMix.targets(1.0, 1.0, 1.0, _s)
	assert_float(_db(turning, FlightMix.RIGGING)).is_greater(_s.flight_floor_db + 10.0)


func test_engine_rises_with_speed_monotonically() -> void:
	var last_db := -1000.0
	var last_pitch := 0.0
	for i in 11:
		var t := FlightMix.targets(i / 10.0, 0.0, 0.0, _s)
		assert_float(_db(t, FlightMix.ENGINE)).is_greater_equal(last_db)
		assert_float(_pitch(t, FlightMix.ENGINE)).is_greater(last_pitch)
		last_db = _db(t, FlightMix.ENGINE)
		last_pitch = _pitch(t, FlightMix.ENGINE)
	assert_float(last_db).is_equal_approx(_s.engine_full_db, 0.001)


func test_inputs_are_clamped() -> void:
	assert_dict(FlightMix.targets(5.0, -2.0, 9.0, _s)).is_equal(FlightMix.targets(1.0, 0.0, 1.0, _s))


func test_no_flight_layer_runs_hot() -> void:
	# every layer at every corner stays at or under 0 dB of render gain (headroom, AUDIO-001 §12.18)
	for sp in [0.0, 1.0]:
		for th in [0.0, 1.0]:
			for tu in [0.0, 1.0]:
				var t := FlightMix.targets(sp, th, tu, _s)
				for id: StringName in FlightMix.LAYERS:
					assert_float(_db(t, id)).is_less_equal(0.0)


# --- the service -------------------------------------------------------------------------------------

func test_flight_layers_load_on_the_ship_bus_and_never_as_beds() -> void:
	var svc := _make()
	for id: StringName in FlightMix.LAYERS:
		assert_bool(svc._flight.has(id)).override_failure_message("no flight player %s" % id).is_true()
		assert_str((svc._flight[id] as AudioStreamPlayer).bus).is_equal("BUS-FLY")
		assert_bool(svc._beds.has(id)).is_false()
	svc.set_ambience(FlightMix.ENGINE)
	assert_str(svc.ambience_id()).is_equal("")   # a flight layer is not an ambience bed


func test_set_flight_starts_layers_and_stop_flight_releases_them() -> void:
	var svc := _make()
	svc.set_flight(0.8, 1.0, 0.0, false)
	_run(svc, 1.0)
	assert_bool(svc.flight_active()).is_true()
	assert_bool((svc._flight[FlightMix.ENGINE] as AudioStreamPlayer).playing).is_true()
	assert_bool((svc._flight[FlightMix.BOILER] as AudioStreamPlayer).playing).is_true()
	assert_float(svc.flight_layer_db(FlightMix.BOILER)).is_greater(_s.flight_floor_db + 20.0)
	assert_float((svc._flight[FlightMix.ENGINE] as AudioStreamPlayer).pitch_scale).is_greater(1.0)
	svc.stop_flight()
	_run(svc, 3.0)
	for id: StringName in FlightMix.LAYERS:
		assert_bool((svc._flight[id] as AudioStreamPlayer).playing).override_failure_message("%s still playing" % id).is_false()


func test_silence_stops_the_ship_and_it_returns_with_a_ramp() -> void:
	var svc := _make()
	svc.set_flight(0.5, 0.0, 0.0, false)
	_run(svc, 1.0)
	svc.silence(0.5)
	_run(svc, 0.25)
	assert_bool((svc._flight[FlightMix.ENGINE] as AudioStreamPlayer).playing).is_false()
	_run(svc, 0.3)   # silence over: back, but still ramping
	var early := svc.flight_layer_db(FlightMix.ENGINE)
	_run(svc, 1.5)
	assert_float(svc.flight_layer_db(FlightMix.ENGINE)).is_greater(early)
	assert_float(_s.flight_return_s).is_greater_equal(0.6)   # AUDIO-001 §1.4 return rule


func test_creak_fires_once_per_hard_turn_and_rearms() -> void:
	var svc := _make()
	svc.now_ms_override = 10000
	svc.set_flight(0.5, 0.5, 0.9, false)
	assert_int(svc.active_count(&"flight_creak")).is_equal(1)
	svc.now_ms_override = 20000
	svc.set_flight(0.5, 0.5, 0.95, false)   # still turning hard: no second creak
	assert_int(svc.active_count(&"flight_creak")).is_equal(0)
	svc.set_flight(0.5, 0.5, 0.1, false)    # eased off: re-armed
	svc.set_flight(0.5, 0.5, 0.9, false)
	assert_int(svc.active_count(&"flight_creak")).is_equal(1)


func test_ballast_fires_on_the_brake_edge_at_speed_only() -> void:
	var svc := _make()
	svc.now_ms_override = 10000
	svc.set_flight(0.1, 0.0, 0.0, true)     # too slow to shift the ballast
	assert_int(svc.active_count(&"flight_ballast")).is_equal(0)
	svc.set_flight(0.1, 0.0, 0.0, false)
	svc.set_flight(0.8, 0.0, 0.0, true)
	assert_int(svc.active_count(&"flight_ballast")).is_equal(1)
	svc.now_ms_override = 30000
	svc.set_flight(0.7, 0.0, 0.0, true)     # held, not a new edge
	assert_int(svc.active_count(&"flight_ballast")).is_equal(0)


func test_stop_all_stops_flight() -> void:
	var svc := _make()
	svc.set_flight(1.0, 1.0, 0.0, false)
	svc.stop_all()
	assert_bool(svc.flight_active()).is_false()


# --- the Vigil's voice ---------------------------------------------------------------------------------

func test_fraction_is_clamped_and_safe() -> void:
	assert_float(VigilFlightVoice.fraction(170.0, 340.0)).is_equal_approx(0.5, 0.0001)
	assert_float(VigilFlightVoice.fraction(900.0, 340.0)).is_equal(1.0)
	assert_float(VigilFlightVoice.fraction(10.0, 0.0)).is_equal(0.0)
