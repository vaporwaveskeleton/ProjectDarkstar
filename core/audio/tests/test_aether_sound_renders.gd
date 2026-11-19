extends GdUnitTestSuite
## The AUDIO-001 §12.18 cues: listed, rendered, the right shape (loop / one-shot, mono / stereo), and a
## level check of every render read straight from the WAV (peak at or under -12 dBFS: headroom, after
## the earlier audition flagged two near-full-scale peaks). Also the golden-path wiring ids.

const AudioServiceScript := preload("res://autoload/audio_service.gd")
const MONO_LOOPS: Array[StringName] = [&"flight_engine", &"flight_boiler", &"flight_rigging", &"flight_lantern"]
const MONO_SHOTS: Array[StringName] = [&"flight_creak", &"flight_ballast", &"unmaking_lamp_out"]
const STEREO_LOOPS: Array[StringName] = [&"ruins_room", &"ruins_first_visit", &"pm01_threat_1", &"pm01_threat_2"]
const PEAK_CEILING_DBFS := -12.0   ## ✱ AUDIO-001 §12.18 level check


func _all() -> Array[StringName]:
	var out: Array[StringName] = []
	out.append_array(MONO_LOOPS)
	out.append_array(MONO_SHOTS)
	out.append_array(STEREO_LOOPS)
	return out


func test_every_new_cue_is_listed_render_only() -> void:
	var ids: CueIds = load(AudioServiceScript.CUE_IDS_PATH)
	for id in _all():
		var row := ids.entry(id)
		assert_object(row).override_failure_message("missing cue row %s" % id).is_not_null()
		assert_bool(row.has_synth_fallback).is_false()
		assert_bool(row.is_loop).is_equal(not (id in MONO_SHOTS))


func test_shapes() -> void:
	for id in _all():
		var s := AudioServiceScript.chirp_stream(id) as AudioStreamWAV
		assert_object(s).override_failure_message("no render for %s" % id).is_not_null()
		assert_bool(s.stereo).override_failure_message("%s channels" % id).is_equal(id in STEREO_LOOPS)
		var loops := s.loop_mode != AudioStreamWAV.LOOP_DISABLED
		assert_bool(loops).override_failure_message("%s loop" % id).is_equal(not (id in MONO_SHOTS))


func test_one_shot_policy() -> void:
	var pol: CuePolicy = load(AudioServiceScript.CUE_POLICY_PATH)
	for id in MONO_SHOTS:
		assert_bool(pol.has_entry(id)).is_true()
		assert_str(pol.entry_for(id).bus).is_equal("BUS-FLY")
	assert_int(pol.entry_for(&"unmaking_lamp_out").priority).is_equal(1)   # the last close sound is never stolen


func test_every_new_render_keeps_headroom() -> void:
	for id in _all():
		var peak := _peak_dbfs("%s/%s.wav" % [AudioServiceScript.CHIRP_DIR, id])
		assert_float(peak).override_failure_message("%s peaks at %.2f dBFS" % [id, peak]).is_less_equal(PEAK_CEILING_DBFS)
		assert_float(peak).override_failure_message("%s is silent" % id).is_greater(-60.0)


func test_ruins_room_tone_ids() -> void:
	var ruins: GDScript = load("res://scenes/ruins/ruins_stub.gd")
	assert_str(ruins.call(&"room_tone_id", true)).is_equal("ruins_first_visit")
	assert_str(ruins.call(&"room_tone_id", false)).is_equal("ruins_room")


func test_lamp_out_ends_at_the_black() -> void:
	# starts as the front reaches the lamp, and its tail is done by the protected black (no overlap)
	var s := AudioServiceScript.chirp_stream(&"unmaking_lamp_out")
	var window := UnmakingTimeline.BLACK_AT - UnmakingTimeline.LAMP_REACH_AT
	assert_float(s.get_length()).is_less_equal(window + 0.05)
	assert_float(s.get_length()).is_greater(window - 0.5)


## Peak of a 16-bit PCM WAV's data chunk, in dBFS (the source file, not the QOA import).
static func _peak_dbfs(path: String) -> float:
	var f := FileAccess.open(path, FileAccess.READ)
	if f == null:
		return 0.0
	f.seek(12)
	var peak := 0
	while f.get_position() + 8 <= f.get_length():
		var tag := f.get_buffer(4).get_string_from_ascii()
		var size := f.get_32()
		if tag == "data":
			var buf := f.get_buffer(size)
			for i in range(0, buf.size() - 1, 2):
				peak = maxi(peak, absi(buf.decode_s16(i)))
			break
		f.seek(f.get_position() + size + (size & 1))
	return linear_to_db(maxf(float(peak) / 32768.0, 0.000001))
