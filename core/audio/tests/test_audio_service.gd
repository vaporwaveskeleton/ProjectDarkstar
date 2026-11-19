extends GdUnitTestSuite
## AudioService voice policy, lazy fallback and the cue tables (AUDIO-001 §12.6, §12.7 C1, C2, C5, C6).
## Each test builds a fresh AudioService node (not the autoload) and drives its clock, so nothing
## depends on real time or on the audio device.

const AudioServiceScript := preload("res://autoload/audio_service.gd")
const T0 := 1000


## A fresh service with an injected clock; `rows` = [[id, priority, max_concurrent], ...] builds a
## custom policy (otherwise the real data/audio/cue_policy.tres is used).
func _make(rows: Array = []) -> AudioServiceScript:
	var svc := AudioServiceScript.new()
	svc.now_ms_override = T0
	if not rows.is_empty():
		var pol := CuePolicy.new()
		for r: Array in rows:
			var e := CuePolicyEntry.new()
			e.id = r[0]
			e.priority = r[1]
			e.max_concurrent = r[2]
			pol.entries.append(e)
		svc.policy = pol
	add_child(svc)
	auto_free(svc)
	return svc


func _cue_slots(svc: AudioServiceScript, id: StringName) -> Array[int]:
	var out: Array[int] = []
	for i in svc._voices.size():
		if svc._voice_cue[i] == id and svc._voice_end_ms[i] > svc._now_ms():
			out.append(i)
	return out


# --- steal order -------------------------------------------------------------------------------

func test_lowest_priority_oldest_voice_is_stolen_first() -> void:
	var svc := _make([[&"wake_hit", 0, 0], [&"grub_die", 4, 0], [&"lance", 5, 0]])
	svc.play(&"wake_hit")
	for i in 10:
		svc.now_ms_override += 1
		svc.play(&"grub_die")
	for i in 13:
		svc.now_ms_override += 1
		svc.play(&"lance")
	assert_int(svc.active_count()).is_equal(24)
	svc.now_ms_override += 1
	svc.play(&"grub_die")
	# the oldest P5 voice (the first lance, slot 11) was taken; P0 and P4 voices were not
	assert_int(svc._voice_cue.count(&"lance")).is_equal(12)
	assert_str(svc._voice_cue[11]).is_equal("grub_die")
	assert_str(svc._voice_cue[0]).is_equal("wake_hit")


func test_a_finished_voice_is_used_before_any_steal() -> void:
	var svc := _make([[&"wake_hit", 0, 0], [&"grub_die", 4, 0], [&"lance", 5, 0]])
	svc.play(&"wake_hit")
	for i in 10:
		svc.now_ms_override += 1
		svc.play(&"grub_die")
	for i in 13:
		svc.now_ms_override += 1
		svc.play(&"lance")
	svc.now_ms_override = T0 + 100   # the 70 ms lances have ended, the grub cries have not
	svc.play(&"grub_die")
	assert_int(svc._voice_cue.count(&"grub_die")).is_equal(11)
	assert_str(svc._voice_cue[11]).is_equal("grub_die")   # first finished slot
	assert_int(svc.active_count(&"wake_hit")).is_equal(1)


func test_same_cue_oldest_voice_is_stolen_when_pool_is_full_of_it() -> void:
	var svc := _make([[&"lance", 5, 0]])
	for i in 24:
		svc.now_ms_override += 1
		svc.play(&"lance")
	var oldest_start: int = svc._voice_start_ms[0]
	svc.now_ms_override += 1
	svc.play(&"lance")
	assert_int(svc._voice_start_ms[0]).is_greater(oldest_start)
	assert_int(svc.active_count(&"lance")).is_equal(24)


func test_request_is_dropped_when_nothing_is_stealable() -> void:
	var svc := _make([[&"wake_hit", 0, 0], [&"lance", 5, 0]])
	for i in 24:
		svc.play(&"wake_hit")
	svc.play(&"lance")
	assert_int(svc.active_count(&"lance")).is_equal(0)
	assert_int(svc.active_count(&"wake_hit")).is_equal(24)


func test_lower_priority_cue_never_steals_a_more_important_voice() -> void:
	var svc := _make([[&"acolyte_fire", 3, 0], [&"lance", 5, 0]])
	for i in 24:
		svc.play(&"acolyte_fire")
	svc.play(&"lance")
	assert_int(svc.active_count(&"lance")).is_equal(0)


func test_100_lance_calls_cannot_steal_wake_hit() -> void:
	# real policy: the lance cap alone keeps the pool bounded
	var svc := _make()
	svc.play(&"wake_hit")
	var started: int = svc._voice_start_ms[0]
	for i in 100:
		svc.now_ms_override += 5
		svc.play(&"lance")
	assert_int(svc.active_count(&"wake_hit")).is_equal(1)
	assert_int(svc.active_count(&"lance")).is_less_equal(4)
	assert_int(svc._voice_start_ms[_cue_slots(svc, &"wake_hit")[0]]).is_equal(started)
	# and with no concurrency cap at all, the P0 voice is still never stolen
	var wide := _make([[&"wake_hit", 0, 1], [&"lance", 5, 0]])
	wide.play(&"wake_hit")
	for i in 100:
		wide.now_ms_override += 1
		wide.play(&"lance")
	assert_int(wide.active_count(&"wake_hit")).is_equal(1)


# --- policy: concurrency, gate, bus, jitter ----------------------------------------------------

func test_max_concurrent_caps_a_cue() -> void:
	var svc := _make()
	for i in 6:
		svc.play(&"lance")
	assert_int(svc.active_count(&"lance")).is_equal(4)
	svc.play(&"menu_move")
	svc.play(&"menu_move")
	assert_int(svc.active_count(&"menu_move")).is_equal(1)


func test_one_voice_p1_cue_is_not_retriggered_over_itself() -> void:
	var svc := _make()
	svc.play(&"charge_lost")
	svc.now_ms_override += 10
	svc.play(&"charge_lost")
	assert_int(svc.active_count(&"charge_lost")).is_equal(1)


func test_min_retrigger_gate() -> void:
	var svc := _make()
	svc.play(&"geode_hit")
	svc.now_ms_override = T0 + 39
	svc.play(&"geode_hit")
	assert_int(svc.active_count(&"geode_hit")).is_equal(1)
	svc.now_ms_override = T0 + 40
	svc.play(&"geode_hit")
	assert_int(svc.active_count(&"geode_hit")).is_equal(2)


func test_bus_routing_per_cue_and_reset_on_reuse() -> void:
	var svc := _make()
	svc.play(&"menu_accept")
	assert_str(svc._voices[0].bus).is_equal("BUS-UI")
	svc.now_ms_override = T0 + 1000   # the menu cue ended; slot 0 is reused
	svc.play(&"lance")
	assert_str(svc._voices[0].bus).is_equal("BUS-FLY")
	svc.play(&"wake_hit")
	assert_str(svc._voices[_cue_slots(svc, &"wake_hit")[0]].bus).is_equal("BUS-ENT")


func test_cue_without_a_policy_entry_gets_the_safe_default() -> void:
	var svc := _make([[&"lance", 5, 4]])
	svc.play(&"coin")
	var slot := _cue_slots(svc, &"coin")[0]
	assert_str(svc._voices[slot].bus).is_equal("BUS-FLY")
	assert_int(svc._voice_priority[slot]).is_equal(CuePolicy.DEFAULT_PRIORITY)
	for i in 6:
		svc.play(&"coin")
	assert_int(svc.active_count(&"coin")).is_equal(CuePolicy.DEFAULT_MAX_CONCURRENT)


func test_pitch_jitter_is_bounded_and_reset_per_play() -> void:
	var svc := _make()
	var limit := pow(2.0, 20.0 / 1200.0)
	var seen_off_unity := false
	for i in 40:
		svc.now_ms_override += 100   # each lance has ended: slot 0 every time
		svc.play(&"lance")
		var pitch := svc._voices[0].pitch_scale
		assert_float(pitch).is_between(1.0 / limit - 0.0001, limit + 0.0001)
		if not is_equal_approx(pitch, 1.0):
			seen_off_unity = true
	assert_bool(seen_off_unity).is_true()
	svc.now_ms_override += 100
	svc.play(&"menu_move")
	assert_float(svc._voices[0].pitch_scale).is_equal(1.0)


func test_muted_for_tests_plays_nothing() -> void:
	var svc := _make()
	svc.muted_for_tests = true
	svc.play(&"lance")
	assert_int(svc.active_count()).is_equal(0)


# --- silence, stop_all, chant ------------------------------------------------------------------

func test_silence_blocks_play_and_stops_voices() -> void:
	var svc := _make()
	svc.play(&"lance")
	svc.play(&"wake_hit")
	svc.silence(0.5)
	assert_int(svc.active_count()).is_equal(0)
	for p in svc._voices:
		assert_bool(p.playing).is_false()
	svc.play(&"lance")
	assert_int(svc.active_count()).is_equal(0)
	svc._process(1.0)   # the silence runs out
	svc.play(&"lance")
	assert_int(svc.active_count(&"lance")).is_equal(1)


func test_stop_all_stops_voices_and_chant() -> void:
	var svc := _make()
	svc.play(&"lance")
	svc.set_chant(0.5)
	svc.stop_all()
	assert_int(svc.active_count()).is_equal(0)
	assert_bool(svc._chant.playing).is_false()
	assert_float(svc._chant_level).is_equal(0.0)


func test_chant_bed_level_and_stop() -> void:
	var svc := _make()
	svc.set_chant(2.0)   # clamped to 1
	assert_float(svc._chant_level).is_equal(1.0)
	assert_bool(svc._chant.playing).is_true()
	svc._process(1.0)
	assert_float(svc._chant.volume_db).is_equal_approx(AudioServiceScript.CHANT_MAX_DB, 0.01)
	svc.set_chant(0.0)
	svc._process(1.0)
	assert_float(svc._chant.volume_db).is_less(-79.0)
	svc._process(1.0)
	assert_bool(svc._chant.playing).is_false()


func test_chant_is_silent_during_a_silence() -> void:
	var svc := _make()
	svc.set_chant(1.0)
	svc.silence(2.0)
	svc._process(0.5)
	svc._process(0.5)
	assert_float(svc._chant.volume_db).is_less(-70.0)


# --- lazy fallback and cue tables --------------------------------------------------------------

func test_fallback_synth_builds_only_cues_whose_render_is_missing() -> void:
	var svc := _make()
	var expected := 0
	for id in svc.cue_ids.fallback_ids():
		if AudioServiceScript.chirp_stream(id) == null:
			expected += 1
	assert_int(svc.synth_cue_count).is_equal(expected)
	# every render that exists is the one that plays
	for id in svc.cue_ids.fallback_ids():
		assert_bool(svc.uses_chirp(id)).is_equal(AudioServiceScript.chirp_stream(id) != null)


func test_render_only_cue_with_no_render_is_a_silent_no_op() -> void:
	var ids := CueIds.new()
	var e := CueIdEntry.new()
	e.id = &"no_such_cue_render"
	e.has_synth_fallback = false
	ids.entries.append(e)
	var f := CueIdEntry.new()
	f.id = &"no_such_cue_fallback"   # claims a fallback that SfxSynth does not have
	f.has_synth_fallback = true
	ids.entries.append(f)
	var svc := AudioServiceScript.new()
	svc.cue_ids = ids
	svc.now_ms_override = T0
	add_child(svc)
	auto_free(svc)
	assert_bool(svc.has_cue(&"no_such_cue_render")).is_false()
	assert_bool(svc.has_cue(&"no_such_cue_fallback")).is_false()
	svc.play(&"no_such_cue_render")
	svc.play(&"no_such_cue_fallback")
	svc.play(&"never_registered")
	assert_int(svc.active_count()).is_equal(0)


func test_id_table_fallback_list_matches_sfx_synth_keys() -> void:
	var ids: CueIds = load(AudioServiceScript.CUE_IDS_PATH)
	var from_table: Array[String] = []
	for id in ids.fallback_ids():
		from_table.append(String(id))
	var from_synth: Array[String] = []
	for id: StringName in SfxSynth.build_cabinet_set().keys():
		from_synth.append(String(id))
	from_table.sort()
	from_synth.sort()
	assert_array(from_table).is_equal(from_synth)


func test_cue_id_table_is_complete_and_consistent() -> void:
	var ids: CueIds = load(AudioServiceScript.CUE_IDS_PATH)
	var seen: Dictionary = {}
	for e in ids.entries:
		assert_bool(seen.has(e.id)).override_failure_message("duplicate cue id %s" % e.id).is_false()
		seen[e.id] = true
		# a cue has a section 6.2 id, or is marked Act 0 only, not both
		assert_bool(e.doc_id.is_empty()).override_failure_message("cue %s: doc_id and act0_only disagree" % e.id).is_equal(e.act0_only)
	# every render in the chirp folder is listed
	var dir := DirAccess.open(AudioServiceScript.CHIRP_DIR)
	assert_object(dir).is_not_null()
	for f in dir.get_files():
		if f.ends_with(".wav"):
			assert_bool(ids.has_id(StringName(f.get_basename()))).override_failure_message("render %s has no row in cue_ids.tres" % f).is_true()
	# the five render-only M1 cues are listed with their section 6.2 ids and no fallback
	var render_only := {&"lance_armour": "A03", &"geode_crack": "A04", &"dry_fire": "A09", &"hull_hit": "C07", &"surgelight": "C04"}
	for id: StringName in render_only:
		var row := ids.entry(id)
		assert_object(row).is_not_null()
		assert_str(row.doc_id).is_equal(render_only[id])
		assert_bool(row.has_synth_fallback).is_false()
	assert_str(ids.entry(&"lance").doc_id).is_equal("A01")


func test_every_listed_cue_has_a_render_or_a_fallback() -> void:
	var ids: CueIds = load(AudioServiceScript.CUE_IDS_PATH)
	for e in ids.entries:
		if e.has_synth_fallback:
			continue
		assert_object(AudioServiceScript.chirp_stream(e.id)).override_failure_message("render-only cue %s has no render" % e.id).is_not_null()


func test_policy_table_matches_the_cue_table_and_the_bus_layout() -> void:
	var ids: CueIds = load(AudioServiceScript.CUE_IDS_PATH)
	var pol: CuePolicy = load(AudioServiceScript.CUE_POLICY_PATH)
	assert_str(pol.ds_namespace).is_equal("ds_audio")
	for e in pol.entries:
		assert_bool(ids.has_id(e.id)).override_failure_message("policy for unknown cue %s" % e.id).is_true()
		assert_int(AudioServer.get_bus_index(e.bus)).override_failure_message("cue %s uses missing bus %s" % [e.id, e.bus]).is_not_equal(-1)
		assert_int(e.priority).is_between(0, 5)
	for id in [&"wake_hit", &"entity_unmade"]:
		assert_int(pol.entry_for(id).priority).is_equal(0)
		assert_int(pol.entry_for(id).max_concurrent).is_equal(1)
	assert_int(pol.entry_for(&"charge_lost").priority).is_equal(1)
	assert_int(pol.entry_for(&"charge_lost").max_concurrent).is_equal(1)
	assert_int(pol.entry_for(&"lance").max_concurrent).is_equal(4)
	assert_float(pol.entry_for(&"lance").pitch_jitter_cents).is_equal(20.0)
	assert_int(pol.entry_for(&"geode_hit").max_concurrent).is_equal(3)
	assert_int(pol.entry_for(&"geode_hit").min_retrigger_ms).is_equal(40)
	assert_str(pol.entry_for(&"menu_accept").bus).is_equal("BUS-UI")
	assert_str(pol.entry_for(&"menu_move").bus).is_equal("BUS-UI")
	var d := pol.entry_for(&"not_in_the_table")
	assert_str(d.bus).is_equal("BUS-FLY")
	assert_int(d.max_concurrent).is_equal(4)
	assert_int(d.min_retrigger_ms).is_equal(0)
	assert_float(d.pitch_jitter_cents).is_equal(0.0)


func test_m1_slice3_cues_are_listed_rendered_mono_and_have_policy() -> void:
	var ids: CueIds = load(AudioServiceScript.CUE_IDS_PATH)
	var pol: CuePolicy = load(AudioServiceScript.CUE_POLICY_PATH)
	# id: [doc_id, bus, priority, max_concurrent, min_retrigger_ms, jitter_cents]
	var want := {
		&"overfire_warn": ["A07", "BUS-FLY", 3, 1, 300, 0.0],
		&"overfire_burst": ["A08", "BUS-FLY", 2, 2, 0, 0.0],
		&"magnet_latch": ["A13", "BUS-FLY", 5, 3, 30, 30.0],
		&"charge_armed": ["B10", "BUS-FLY", 3, 2, 40, 0.0],
		&"magazine_full": ["B11", "BUS-FLY", 4, 1, 150, 0.0],
		&"charge_gutter": ["B12", "BUS-FLY", 2, 2, 0, 0.0],
		&"grub_steal": ["F11", "BUS-CHO", 3, 2, 80, 25.0],
	}
	for id: StringName in want:
		var w: Array = want[id]
		var row := ids.entry(id)
		assert_object(row).is_not_null()
		assert_str(row.doc_id).is_equal(w[0])
		assert_bool(row.act0_only).is_false()
		assert_bool(row.has_synth_fallback).is_false()
		assert_bool(row.is_loop).is_false()
		var stream := AudioServiceScript.chirp_stream(id)
		assert_object(stream).is_not_null()
		var wav := stream as AudioStreamWAV
		assert_bool(wav != null and not wav.stereo).override_failure_message("%s is not a mono WAV" % id).is_true()
		var rule := pol.entry_for(id)
		assert_str(rule.bus).is_equal(w[1])
		assert_int(rule.priority).is_equal(w[2])
		assert_int(rule.max_concurrent).is_equal(w[3])
		assert_int(rule.min_retrigger_ms).is_equal(w[4])
		assert_float(rule.pitch_jitter_cents).is_equal(w[5])
	assert_str(ids.entry(&"lance_dull").doc_id).is_equal("A14")
	assert_bool(ids.entry(&"lance_dull").act0_only).is_false()
	assert_str(ids.entry(&"grub_die").doc_id).is_equal("F12")
	assert_bool(ids.entry(&"grub_die").act0_only).is_false()


func test_choir_passing_handoff_cues_are_listed_rendered_and_have_policy() -> void:
	var ids: CueIds = load(AudioServiceScript.CUE_IDS_PATH)
	var pol: CuePolicy = load(AudioServiceScript.CUE_POLICY_PATH)
	# id: [doc_id, stereo, bus, priority, max_concurrent, min_retrigger_ms, jitter_cents]
	var want := {
		&"phantom_fire": ["F14", false, "BUS-CHO", 3, 3, 60, 20.0],
		&"listener_heard": ["F03", false, "BUS-CHO", 1, 1, 500, 0.0],
		&"matron_birth": ["F13", false, "BUS-CHO", 2, 1, 1000, 0.0],
		&"matron_silenced": ["F07", false, "BUS-CHO", 2, 1, 0, 0.0],
		&"deceiver_steal": ["B07", false, "BUS-FLY", 1, 1, 0, 0.0],
		&"presence_flee": ["PAS-01", true, "BUS-AMB", 5, 1, 5000, 0.0],
		&"comforters_murmur": ["PAS-02", false, "BUS-CHO", 2, 1, 3000, 0.0],
		&"lie_tell_chalk": ["LIE-01", false, "BUS-UI", 1, 1, 250, 0.0],
		&"lie_tell_glyph": ["LIE-02", false, "BUS-UI", 1, 1, 250, 0.0],
		&"lie_tell_mirror": ["LIE-03", false, "BUS-UI", 1, 1, 250, 0.0],
		&"lie_tell_smear": ["LIE-04", false, "BUS-UI", 1, 1, 250, 0.0],
		&"lie_tell_absence": ["LIE-05", false, "BUS-UI", 1, 1, 250, 0.0],
	}
	for id: StringName in want:
		var w: Array = want[id]
		var row := ids.entry(id)
		assert_object(row).is_not_null()
		assert_str(row.doc_id).is_equal(w[0])
		assert_bool(row.act0_only).is_false()
		assert_bool(row.has_synth_fallback).is_false()
		assert_bool(row.is_loop).is_false()
		var wav := AudioServiceScript.chirp_stream(id) as AudioStreamWAV
		assert_object(wav).is_not_null()
		assert_bool(wav != null and wav.stereo == w[1]).override_failure_message("%s has the wrong channel count" % id).is_true()
		var rule := pol.entry_for(id)
		assert_str(rule.bus).is_equal(w[2])
		assert_int(rule.priority).is_equal(w[3])
		assert_int(rule.max_concurrent).is_equal(w[4])
		assert_int(rule.min_retrigger_ms).is_equal(w[5])
		assert_float(rule.pitch_jitter_cents).is_equal(w[6])


# --- sizzle cues, bed pitch bend, no hit-stop path (AUDIO-001 §12.11) ---------------------------

func test_sizzle_cues_are_listed_rendered_and_have_policy() -> void:
	var ids: CueIds = load(AudioServiceScript.CUE_IDS_PATH)
	var pol: CuePolicy = load(AudioServiceScript.CUE_POLICY_PATH)
	assert_int(ids.entries.size()).is_equal(57)
	assert_int(pol.entries.size()).is_equal(46)
	var want := {&"lance_dull": [2, 3, 40], &"tally_blip": [3, 1, 60]}
	for id: StringName in want:
		assert_bool(ids.has_id(id)).is_true()
		assert_bool(ids.entry(id).has_synth_fallback).is_false()
		assert_object(AudioServiceScript.chirp_stream(id)).is_not_null()
		var rule := pol.entry_for(id)
		var w: Array = want[id]
		assert_str(rule.bus).is_equal("BUS-FLY")
		assert_int(rule.priority).is_equal(w[0])
		assert_int(rule.max_concurrent).is_equal(w[1])
		assert_int(rule.min_retrigger_ms).is_equal(w[2])
		assert_float(rule.pitch_jitter_cents).is_equal(0.0)
	assert_float(pol.entry_for(&"lance").pitch_jitter_cents).is_equal(20.0)


func test_bed_pitch_steps_down_within_fall_time() -> void:
	var svc := _make()
	svc.set_bed_pitch_scale(0.5)
	var prev := svc.bed_pitch_scale()
	var t := 0.0
	var max_step := 0.0
	while t < AudioServiceScript.BED_PITCH_FALL_S + 0.001:
		svc._process(1.0 / 60.0)
		t += 1.0 / 60.0
		max_step = maxf(max_step, absf(svc.bed_pitch_scale() - prev))
		prev = svc.bed_pitch_scale()
	assert_float(svc.bed_pitch_scale()).is_equal(0.5)
	assert_float(max_step).is_less(0.2)   # never a jump: a fraction of the range per 60 Hz frame


func test_bed_pitch_rises_slower_than_it_falls_and_lands_exactly() -> void:
	var svc := _make()
	svc.set_bed_pitch_scale(0.5)
	for i in 60:
		svc._process(1.0 / 60.0)
	assert_float(svc.bed_pitch_scale()).is_equal(0.5)
	svc.set_bed_pitch_scale(1.0)
	for i in 6:   # 0.1 s: not there yet
		svc._process(1.0 / 60.0)
	assert_float(svc.bed_pitch_scale()).is_between(0.5, 0.99)
	var prev := svc.bed_pitch_scale()
	for i in 30:   # past 0.35 s total
		svc._process(1.0 / 60.0)
		assert_float(svc.bed_pitch_scale()).is_greater_equal(prev)
		prev = svc.bed_pitch_scale()
	assert_float(svc.bed_pitch_scale()).is_equal(1.0)


func test_bed_pitch_clamps_and_stop_all_resets() -> void:
	var svc := _make()
	svc.set_bed_pitch_scale(0.0)
	for i in 120:
		svc._process(1.0 / 60.0)
	assert_float(svc.bed_pitch_scale()).is_equal(AudioServiceScript.BED_PITCH_MIN)
	svc.set_bed_pitch_scale(5.0)
	for i in 120:
		svc._process(1.0 / 60.0)
	assert_float(svc.bed_pitch_scale()).is_equal(1.0)
	svc.set_bed_pitch_scale(0.5)
	for i in 120:
		svc._process(1.0 / 60.0)
	svc.stop_all()
	assert_float(svc.bed_pitch_scale()).is_equal(1.0)
	svc._process(0.5)
	assert_float(svc.bed_pitch_scale()).is_equal(1.0)


func test_bed_pitch_does_not_bend_one_shot_voices() -> void:
	var svc := _make()
	svc.set_bed_pitch_scale(0.5)
	svc._process(1.0)
	for p in svc._voices:
		assert_float(p.pitch_scale).is_equal(1.0)


func test_no_hit_stop_freeze_path() -> void:
	var svc := _make()
	assert_int(svc.process_mode).is_equal(Node.PROCESS_MODE_ALWAYS)
	for m in svc.get_method_list():
		var n := String(m["name"]).to_lower()
		assert_bool(n.contains("hitstop") or n.contains("hit_stop") or n.contains("freeze")).override_failure_message("hit-stop method %s" % n).is_false()
	for s in svc.get_signal_list():
		assert_bool(String(s["name"]).to_lower().contains("hitstop")).is_false()
	svc.play(&"lance")
	assert_int(svc.active_count(&"lance")).is_equal(1)
