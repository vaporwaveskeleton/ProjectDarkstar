extends GdUnitTestSuite
## The AudioService ambience slot and the five Aether cues (AUDIO-001 §12.12, §1.4 bed-return rule).
## Each test builds a fresh service with its own _process switched off and drives `_process(delta)` by hand.

const AudioServiceScript := preload("res://autoload/audio_service.gd")
const BEDS: Array[StringName] = [&"aether_bed_t1", &"aether_bed_t2", &"aether_bed_t3", &"aether_bed_t4", &"aether_bed_t5"]
const ONE_SHOTS: Array[StringName] = [&"aether_swell", &"aether_wrong"]
const DT := 1.0 / 60.0


func _make() -> AudioServiceScript:
	var svc := AudioServiceScript.new()
	add_child(svc)
	svc.set_process(false)
	auto_free(svc)
	return svc


func _run(svc: AudioServiceScript, seconds: float) -> void:
	var n := int(round(seconds / DT))
	for i in n:
		svc._process(DT)


func _gain(svc: AudioServiceScript, i: int) -> float:
	return sin(svc._amb_fade[i] * PI * 0.5)


# --- cue tables --------------------------------------------------------------------------------

func test_five_aether_cues_are_listed_and_rendered() -> void:
	var ids: CueIds = load(AudioServiceScript.CUE_IDS_PATH)
	for id in BEDS + ONE_SHOTS:
		var row := ids.entry(id)
		assert_object(row).is_not_null()
		assert_bool(row.has_synth_fallback).is_false()
		assert_bool(row.act0_only).is_false()
		assert_bool(row.is_loop).is_equal(id in BEDS)
		assert_object(AudioServiceScript.chirp_stream(id)).is_not_null()


func test_beds_carry_loop_info_and_are_stereo() -> void:
	for id in BEDS:
		var s := AudioServiceScript.chirp_stream(id) as AudioStreamWAV
		assert_object(s).is_not_null()
		assert_int(s.loop_mode).is_not_equal(AudioStreamWAV.LOOP_DISABLED)
		assert_bool(s.stereo).is_true()
	for id in ONE_SHOTS:
		var s := AudioServiceScript.chirp_stream(id) as AudioStreamWAV
		assert_bool(s.stereo).is_true()
		assert_int(s.loop_mode).is_equal(AudioStreamWAV.LOOP_DISABLED)


func test_swell_and_wrong_policy_is_on_the_ambience_bus() -> void:
	var pol: CuePolicy = load(AudioServiceScript.CUE_POLICY_PATH)
	for id in ONE_SHOTS:
		var r := pol.entry_for(id)
		assert_str(r.bus).is_equal("BUS-AMB")
		assert_int(r.priority).is_equal(5)
		assert_int(r.max_concurrent).is_equal(1)
		assert_int(r.min_retrigger_ms).is_equal(2000)
		assert_float(r.pitch_jitter_cents).is_equal(0.0)
		assert_int(AudioServer.get_bus_index(r.bus)).is_not_equal(-1)


func test_one_shots_register_and_beds_cannot_be_played() -> void:
	var svc := _make()
	svc.now_ms_override = 1000
	for id in ONE_SHOTS:
		assert_bool(svc.has_cue(id)).is_true()
	for id in BEDS:
		assert_bool(svc.has_cue(id)).is_false()
		svc.play(id)
	assert_int(svc.active_count()).is_equal(0)


# --- set_ambience ------------------------------------------------------------------------------

func test_fade_time_respects_the_bed_return_floor() -> void:
	assert_float(AudioServiceScript.AMBIENCE_FADE_S).is_greater_equal(0.6)
	assert_float(AudioServiceScript.AMBIENCE_FADE_S).is_equal(2.0)


func test_crossfade_is_smooth_and_takes_the_fade_time() -> void:
	var svc := _make()
	svc.set_ambience(&"aether_bed_t1")
	_run(svc, 2.5)
	var a: int = svc._amb_active
	assert_bool(svc._amb[a].playing).is_true()
	assert_float(svc._amb_fade[a]).is_equal(1.0)
	svc.set_ambience(&"aether_bed_t2")
	var b: int = svc._amb_active
	assert_int(b).is_not_equal(a)
	assert_object(svc._amb[b].stream).is_not_same(svc._amb[a].stream)
	var prev_in := 0.0
	var prev_out := 1.0
	var t := 0.0
	while t < 2.0 - DT * 0.5:
		svc._process(DT)
		t += DT
		var gi := _gain(svc, b)
		var go := _gain(svc, a)
		assert_float(gi).is_greater_equal(prev_in)
		assert_float(go).is_less_equal(prev_out)
		assert_float(gi - prev_in).is_less(0.05)    # no jump larger than a frame's step
		assert_float(prev_out - go).is_less(0.05)
		prev_in = gi
		prev_out = go
	assert_float(prev_in).is_greater(0.95)
	assert_float(prev_out).is_less(0.05)
	_run(svc, 0.1)
	assert_bool(svc._amb[a].playing).is_false()
	assert_bool(svc._amb[b].playing).is_true()
	assert_str(svc.ambience_id()).is_equal("aether_bed_t2")
	assert_str(svc._amb[b].bus).is_equal("BUS-AMB")


func test_same_id_changes_level_without_restart() -> void:
	var svc := _make()
	svc.set_ambience(&"aether_bed_t1", 1.0)
	_run(svc, 2.5)
	var a: int = svc._amb_active
	var full: float = svc._amb[a].volume_db
	svc.set_ambience(&"aether_bed_t1", 0.5)
	assert_int(svc._amb_active).is_equal(a)
	assert_float(svc._amb_fade[a]).is_equal(1.0)    # no fade restart
	_run(svc, 2.0)
	assert_bool(svc._amb[a].playing).is_true()
	assert_float(svc._amb[a].volume_db).is_less(full - 5.0)
	assert_float(full).is_equal_approx(AudioServiceScript.AMBIENCE_MAX_DB, 0.01)
	assert_float(svc._amb[a].volume_db).is_equal_approx(lerpf(-40.0, AudioServiceScript.AMBIENCE_MAX_DB, 0.5), 0.05)


func test_empty_id_fades_out_then_stops() -> void:
	var svc := _make()
	svc.set_ambience(&"aether_bed_t3")
	_run(svc, 2.5)
	var a: int = svc._amb_active
	svc.set_ambience(&"")
	_run(svc, 1.0)
	assert_bool(svc._amb[a].playing).is_true()
	assert_float(_gain(svc, a)).is_between(0.1, 0.9)
	_run(svc, 1.2)
	assert_bool(svc._amb[a].playing).is_false()
	assert_str(svc.ambience_id()).is_equal("")


func test_unknown_or_non_loop_id_is_a_silent_no_op() -> void:
	var svc := _make()
	svc.set_ambience(&"not_a_cue")
	svc.set_ambience(&"aether_swell")
	svc.set_ambience(&"lance")
	svc.set_ambience(&"chant")
	assert_str(svc.ambience_id()).is_equal("")
	_run(svc, 1.0)
	assert_bool(svc._amb[0].playing or svc._amb[1].playing).is_false()
	svc.set_ambience(&"aether_bed_t1")
	svc.set_ambience(&"not_a_cue")
	assert_str(svc.ambience_id()).is_equal("aether_bed_t1")


func test_silence_stops_hard_and_the_bed_returns_with_a_fade() -> void:
	var svc := _make()
	svc.set_ambience(&"aether_bed_t1")
	_run(svc, 2.5)
	var a: int = svc._amb_active
	svc.silence(1.0)
	assert_bool(svc._amb[a].playing).is_false()
	_run(svc, 0.5)
	assert_bool(svc._amb[a].playing).is_false()
	_run(svc, 0.6)    # silence over
	assert_bool(svc._amb[a].playing).is_true()
	assert_float(_gain(svc, a)).is_less(0.2)
	var t := 0.0
	var prev := _gain(svc, a)
	while _gain(svc, a) < 0.99 and t < 5.0:
		svc._process(DT)
		t += DT
		assert_float(_gain(svc, a) - prev).is_less(0.05)
		prev = _gain(svc, a)
	assert_float(t).is_greater_equal(0.6)
	assert_str(svc.ambience_id()).is_equal("aether_bed_t1")


func test_stop_all_clears_the_slot() -> void:
	var svc := _make()
	svc.set_ambience(&"aether_bed_t2")
	_run(svc, 1.0)
	svc.stop_all()
	assert_str(svc.ambience_id()).is_equal("")
	_run(svc, 0.5)
	assert_bool(svc._amb[0].playing or svc._amb[1].playing).is_false()


func test_muted_for_tests_never_plays_the_ambience() -> void:
	var svc := _make()
	svc.muted_for_tests = true
	svc.set_ambience(&"aether_bed_t1")
	_run(svc, 1.0)
	assert_bool(svc._amb[0].playing or svc._amb[1].playing).is_false()


func test_bed_pitch_scale_stays_chant_only() -> void:
	var svc := _make()
	svc.set_ambience(&"aether_bed_t1")
	svc.set_bed_pitch_scale(0.5)
	_run(svc, 1.0)
	assert_float(svc._amb[svc._amb_active].pitch_scale).is_equal(1.0)
