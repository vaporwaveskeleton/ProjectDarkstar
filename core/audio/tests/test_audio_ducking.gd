extends GdUnitTestSuite
## The AUDIO-001 §7.2 ducking chain (a sidechain per bus, 60 ms attack, 400 ms release) and §7.3's
## never-ducked rules, plus the ambience threat stems (§12.18): layers, not level.

const AudioServiceScript := preload("res://autoload/audio_service.gd")
const DT := 1.0 / 60.0


func _make() -> AudioServiceScript:
	var svc := AudioServiceScript.new()
	add_child(svc)
	svc.set_process(false)
	auto_free(svc)
	return svc


func _run(svc: AudioServiceScript, seconds: float) -> void:
	for i in int(round(seconds / DT)):
		svc._process(DT)


func _bus_db(bus: StringName) -> float:
	return AudioServer.get_bus_volume_db(AudioServer.get_bus_index(bus))


func _policy(bus: StringName, priority: int) -> CuePolicy:
	var e := CuePolicyEntry.new()
	e.id = &"coin"
	e.bus = bus
	e.priority = priority
	e.max_concurrent = 0
	var pol := CuePolicy.new()
	pol.entries = [e]
	return pol


func test_duck_table_matches_audio_001() -> void:
	var m: AudioMixStats = load(AudioServiceScript.MIX_STATS_PATH)
	assert_float(m.duck_db(0)).is_equal(-6.0)
	assert_float(m.duck_db(1)).is_equal(-5.0)
	assert_float(m.duck_db(2)).is_equal(-5.0)
	assert_float(m.duck_db(3)).is_equal(-4.0)
	assert_float(m.duck_db(4)).is_equal(-3.0)
	assert_float(m.duck_attack_s).is_equal(0.06)
	assert_float(m.duck_release_s).is_equal(0.4)
	assert_bool(&"BUS-CHO" in AudioServiceScript.DUCK_BUSES).is_false()
	assert_bool(&"BUS-ENT" in AudioServiceScript.DUCK_BUSES).is_false()


func test_an_entity_cue_ducks_ambience_and_releases() -> void:
	var svc := _make()
	svc.policy = _policy(&"BUS-ENT", 0)
	var base := _bus_db(&"BUS-AMB")
	svc.play(&"coin")
	assert_float(svc.duck_target(&"BUS-AMB")).is_equal(-6.0)
	assert_float(svc.duck_target(&"BUS-CHO")).is_equal(0.0)   # never ducked (§7.3)
	_run(svc, 0.3)   # five attack time constants
	assert_float(svc.duck_db(&"BUS-AMB")).is_less(-5.5)
	assert_float(_bus_db(&"BUS-AMB")).is_equal_approx(base - 6.0, 0.6)
	svc.stop_all()
	_run(svc, 2.5)
	assert_float(svc.duck_db(&"BUS-AMB")).is_equal(0.0)
	assert_float(_bus_db(&"BUS-AMB")).is_equal_approx(base, 0.01)


func test_release_is_slower_than_attack() -> void:
	var svc := _make()
	svc.policy = _policy(&"BUS-ENT", 0)
	svc.play(&"coin")
	_run(svc, 0.1)
	var after_attack := svc.duck_db(&"BUS-MUS")
	svc.stop_all()
	_run(svc, 0.1)
	var after_release := svc.duck_db(&"BUS-MUS")
	assert_float(after_attack).is_less(-4.0)
	assert_float(after_release).is_less(-2.0)   # 0.1 s into a 0.4 s release: still well ducked


func test_a_bus_carrying_a_p1_cue_is_never_ducked() -> void:
	var svc := _make()
	var chime := CuePolicyEntry.new()
	chime.id = &"charge_lost"
	chime.bus = &"BUS-FLY"
	chime.priority = 1
	var ent := CuePolicyEntry.new()
	ent.id = &"wake_hit"
	ent.bus = &"BUS-ENT"
	ent.priority = 0
	var pol := CuePolicy.new()
	pol.entries = [chime, ent]
	svc.policy = pol
	svc.play(&"wake_hit")
	assert_float(svc.duck_target(&"BUS-FLY")).is_equal(-6.0)
	svc.play(&"charge_lost")
	assert_float(svc.duck_target(&"BUS-FLY")).is_equal(0.0)   # the glass chime is heard in the dark


func test_a_cue_never_ducks_its_own_bus() -> void:
	var svc := _make()
	svc.policy = _policy(&"BUS-AMB", 5)
	svc.play(&"coin")
	assert_float(svc.duck_target(&"BUS-AMB")).is_equal(0.0)


func test_ducking_and_subtraction_stack_and_both_reset() -> void:
	var svc := _make()
	svc.policy = _policy(&"BUS-ENT", 0)
	var base := _bus_db(&"BUS-MUS")
	svc.set_subtraction(1.0)
	svc.play(&"coin")
	_run(svc, 0.5)
	assert_float(_bus_db(&"BUS-MUS")).is_equal_approx(base + AudioServiceScript.SUBTRACTION_CUT_DB - 6.0, 0.6)
	svc.stop_all()
	_run(svc, 3.0)
	assert_float(_bus_db(&"BUS-MUS")).is_equal_approx(base, 0.01)


# --- threat stems ------------------------------------------------------------------------------------

const BED := &"aether_bed_t1"
const STEMS: Array[StringName] = [&"pm01_threat_1", &"pm01_threat_2"]


func test_stems_match_the_bed_length_so_they_stay_locked() -> void:
	var bed := AudioServiceScript.chirp_stream(BED)
	for id in STEMS:
		var s := AudioServiceScript.chirp_stream(id)
		assert_object(s).is_not_null()
		assert_float(s.get_length()).is_equal_approx(bed.get_length(), 0.01)


func test_threat_adds_stems_in_order_and_dips_the_bed() -> void:
	var svc := _make()
	svc.set_ambience(BED, 1.0, STEMS)
	assert_array(svc.ambience_stems()).is_equal(STEMS)
	_run(svc, 3.0)
	var calm_db := svc._amb[svc._amb_active].volume_db
	assert_bool(svc._stems[0].playing).is_false()
	svc.set_threat(0.5)
	_run(svc, 3.0)
	assert_bool(svc._stems[0].playing).is_true()
	assert_bool(svc._stems[1].playing).is_false()
	svc.set_threat(1.0)
	_run(svc, 4.5)
	assert_float(svc.threat()).is_equal(1.0)
	assert_bool(svc._stems[1].playing).is_true()
	var tense_db := svc._amb[svc._amb_active].volume_db
	assert_float(tense_db).is_equal_approx(calm_db + svc.mix.threat_bed_dip_db, 0.2)
	svc.set_threat(0.0)
	_run(svc, 9.0)
	assert_bool(svc._stems[0].playing).is_false()
	assert_bool(svc._stems[1].playing).is_false()


func test_a_new_bed_replaces_stems_and_unknown_stems_are_dropped() -> void:
	var svc := _make()
	var asked: Array[StringName] = [&"pm01_threat_1", &"not_a_cue"]
	svc.set_ambience(BED, 1.0, asked)
	assert_int(svc.ambience_stems().size()).is_equal(1)
	assert_str(svc.ambience_stems()[0]).is_equal("pm01_threat_1")
	svc.set_ambience(&"ruins_room")
	assert_array(svc.ambience_stems()).is_empty()


func test_silence_stops_stems() -> void:
	var svc := _make()
	svc.set_ambience(BED, 1.0, STEMS)
	svc.set_threat(1.0)
	_run(svc, 6.0)
	svc.silence(1.0)
	_run(svc, 0.1)
	assert_bool(svc._stems[0].playing).is_false()


func test_sector_threat_takes_the_strongest_source() -> void:
	var m: AudioMixStats = load(AudioServiceScript.MIX_STATS_PATH)
	assert_float(FlightMix.sector_threat(0, 0, 0.0, m)).is_equal(0.0)
	assert_float(FlightMix.sector_threat(3, 0, 0.0, m)).is_equal(m.threat_hollowed)
	assert_float(FlightMix.sector_threat(0, 99, 0.0, m)).is_equal(m.threat_carrier_cap)
	assert_float(FlightMix.sector_threat(1, 0, 1.0, m)).is_equal(m.threat_sepulchre_weight)
	assert_float(FlightMix.sector_threat(-1, -3, -1.0, m)).is_equal(0.0)


func test_stem_gain_slices_the_range() -> void:
	assert_float(FlightMix.stem_gain(0.5, 0, 2)).is_equal(1.0)
	assert_float(FlightMix.stem_gain(0.5, 1, 2)).is_equal(0.0)
	assert_float(FlightMix.stem_gain(1.0, 1, 2)).is_equal(1.0)
	assert_float(FlightMix.stem_gain(0.3, 0, 0)).is_equal(0.0)
