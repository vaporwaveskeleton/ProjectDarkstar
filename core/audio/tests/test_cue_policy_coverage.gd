extends GdUnitTestSuite
## Every shipped one-shot cue has an explicit policy row (so CuePolicy's fallback is never hit by a
## shipped cue), the fallback still works for an unknown id, and a service that has played cues
## shuts down without leaking (TECH-001 Q-T79). Loops do not go through play(): no row needed.

const AudioServiceScript := preload("res://autoload/audio_service.gd")


func test_every_non_loop_cue_has_a_policy_row() -> void:
	var ids: CueIds = load(AudioServiceScript.CUE_IDS_PATH)
	var pol: CuePolicy = load(AudioServiceScript.CUE_POLICY_PATH)
	var missing: Array[String] = []
	for e in ids.entries:
		if not e.is_loop and not pol.has_entry(e.id):
			missing.append(String(e.id))
	assert_array(missing).is_empty()


func test_new_rows_hold_their_values() -> void:
	var pol: CuePolicy = load(AudioServiceScript.CUE_POLICY_PATH)
	var want := {
		&"lance_armour": [3, 3, 40, 15.0], &"geode_crack": [3, 2, 60, 0.0],
		&"dry_fire": [5, 1, 80, 0.0], &"hull_hit": [1, 1, 0, 0.0], &"surgelight": [2, 1, 0, 0.0]}
	for id: StringName in want:
		assert_bool(pol.has_entry(id)).is_true()
		var r := pol.entry_for(id)
		var w: Array = want[id]
		assert_str(r.bus).is_equal("BUS-FLY")
		assert_int(r.priority).is_equal(w[0])
		assert_int(r.max_concurrent).is_equal(w[1])
		assert_int(r.min_retrigger_ms).is_equal(w[2])
		assert_float(r.pitch_jitter_cents).is_equal(w[3])
	assert_bool(pol.entry_for(&"hull_hit").is_stealable()).is_false()   # damage is never stolen


func test_unknown_id_gets_the_default_entry() -> void:
	var pol := CuePolicy.new()
	assert_bool(pol.has_entry(&"no_such_cue")).is_false()
	var r := pol.entry_for(&"no_such_cue")
	assert_str(r.bus).is_equal(String(CuePolicy.DEFAULT_BUS))
	assert_int(r.priority).is_equal(CuePolicy.DEFAULT_PRIORITY)
	assert_int(r.max_concurrent).is_equal(CuePolicy.DEFAULT_MAX_CONCURRENT)
	assert_object(pol.entry_for(&"another")).is_same(r)


func test_service_with_default_path_and_sounding_voices_frees_cleanly() -> void:
	var svc := AudioServiceScript.new()
	svc.policy = CuePolicy.new()   # no rows: every cue takes the default entry
	add_child(svc)
	svc.play(&"coin")
	svc.play(&"no_such_cue")
	assert_int(svc.active_count()).is_greater(0)
	remove_child(svc)
	svc.free()
	# GdUnit's orphan monitor fails this test if the service or its players outlive the free()
