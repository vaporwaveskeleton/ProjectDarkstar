extends GdUnitTestSuite
## W0-12 Hauntings and the cursed turn (TECH-001 Q-T250–Q-T266, PM under owner direction 2026-11-19
## overnight push; WARP-001 W0-07, W0-11, W0-12; ART-001 §12.7b, §12.7c; AUDIO-001 §12.19).
## Hauntings: seeded and rare, each kind once per visit, costume only, never during play, never a readout,
## no flash (the litany stays under 3 dips a second; the figure is one field), and the moving ones are gone
## under photosensitivity / reduced motion. The cursed turn: the glass bulges and the picture collapses
## off-centre, and the wound opens there with no disc, no eye and no ring.

const SCENE := preload("res://features/cabinet/cabinet_game.tscn")
const HAUNT := "res://data/cabinet/cabinet_haunt.tres"
const DECAY := "res://data/cabinet/cabinet_decay.tres"
const SPEC := "res://data/cabinet/cabinet_screen.tres"

var _saved_backend: SaveBackend


func before_test() -> void:
	AudioService.muted_for_tests = true
	_saved_backend = SaveService.backend
	SaveService.set_backend(MemorySaveBackend.new())
	SettingsService.persist = false


func after_test() -> void:
	SettingsService.persist = true
	AudioService.muted_for_tests = false
	SaveService.set_backend(_saved_backend)


func _t() -> CabinetHauntTuning:
	return load(HAUNT) as CabinetHauntTuning


func _decay() -> CabinetDecayTuning:
	return load(DECAY) as CabinetDecayTuning


# --- the numbers (SYS-001 §9 ds_cabinet.haunt.*, PROPOSED) ---

func test_the_numbers_are_sys001s_proposed_rows() -> void:
	var t := _t()
	assert_str(t.ds_namespace).is_equal("ds_cabinet.haunt")
	assert_int(t.min_wear_level).is_equal(1)
	assert_int(t.attract_min_stage).is_equal(2)
	assert_float(t.chance_ready).is_equal(0.35)
	assert_float(t.chance_hold).is_equal(0.3)
	assert_float(t.chance_attract).is_equal(0.2)
	assert_float(t.chance_coin).is_equal(0.25)
	assert_float(t.chance_demo).is_equal(0.3)
	assert_int(t.figure_frames).is_equal(1)
	assert_array(Array(t.litany_dips)).is_equal([3, 3, 2])
	var d := _decay()
	assert_vector(d.focus_play).is_equal(Vector2(0.7, 0.38))
	assert_float(d.bulge_max).is_equal(0.6)
	assert_float(d.breath_hz).is_equal(0.22)


# --- the deck: seeded, rare, once per kind, moment-bound ---

func test_the_same_seed_tells_the_same_story() -> void:
	var moments: Array[StringName] = [&"attract", &"attract", &"coin", &"attract", &"attract", &"attract", &"coin", &"attract"]
	var a := CabinetHauntDeck.new(_t(), 4242)
	var b := CabinetHauntDeck.new(_t(), 4242)
	for m in moments:
		assert_str(String(a.draw(m))).is_equal(String(b.draw(m)))


func test_each_kind_happens_at_most_once_and_only_at_its_moments() -> void:
	for s in 40:
		var d := CabinetHauntDeck.new(_t(), s)
		var seen: Dictionary = {}
		for i in 60:
			for m: StringName in [&"ready", &"hold", &"attract", &"coin", &"demo"]:
				var k := d.draw(m)
				if k == &"":
					continue
				assert_bool(seen.has(k)).override_failure_message("seed %d drew %s twice" % [s, k]).is_false()
				seen[k] = true
				assert_bool((CabinetHauntDeck.MOMENT_KINDS[m] as Array).has(k)).is_true()


func test_hauntings_are_rare() -> void:
	# over many seeds, a READY card haunts about chance_ready of the time (one draw each)
	var fired := 0
	for s in 2000:
		if CabinetHauntDeck.new(_t(), s).draw(&"ready") != &"":
			fired += 1
	assert_float(fired / 2000.0).is_between(0.28, 0.42)


func test_photosensitivity_and_reduced_motion_remove_the_moving_kinds() -> void:
	for s in 60:
		var d := CabinetHauntDeck.new(_t(), s, true)
		for i in 30:
			for m: StringName in [&"ready", &"hold", &"attract", &"demo"]:
				var k := d.draw(m)
				assert_bool(CabinetHauntDeck.MOVING.has(k)).is_false()


func test_a_forced_kind_happens_at_the_first_moment_that_offers_it() -> void:
	var d := CabinetHauntDeck.new(_t(), 1)
	d.forced = &"after_image"
	assert_str(String(d.draw(&"attract"))).is_not_equal("after_image")
	assert_str(String(d.draw(&"ready"))).is_equal("after_image")
	assert_str(String(d.forced)).is_empty()


# --- no flash, no startle ---

func test_the_litany_is_eight_dips_one_short_and_under_three_a_second() -> void:
	var t := _t()
	var times := t.litany_times()
	assert_int(times.size()).is_equal(8)        # nine syllables sung in eight (NARR-001 §2.1)
	for i in range(1, times.size()):
		assert_float(times[i] - times[i - 1]).is_greater_equal(1.0 / 3.0)
	# smooth: zero at every dip's edge, never deeper than litany_depth, never a hard step
	var prev := 0.0
	var step := 1.0 / 60.0
	var x := 0.0
	while x <= t.litany_s() + step:
		var v := t.litany_dim(x)
		assert_float(v).is_between(0.0, t.litany_depth + 0.0001)
		assert_float(absf(v - prev)).is_less(0.05)
		prev = v
		x += step
	assert_float(t.litany_dim(t.litany_s() + 0.1)).is_equal(0.0)


func test_the_after_image_fades_in_and_out_inside_the_ready_card() -> void:
	var t := _t()
	assert_float(t.after_image_s()).is_less_equal(CabinetGame.READY_SECONDS)
	assert_float(t.after_image_k(0.0)).is_equal(0.0)
	assert_float(t.after_image_k(t.after_image_in_s + 0.1)).is_equal(1.0)
	assert_float(t.after_image_k(t.after_image_s())).is_equal(0.0)
	var prev := 0.0
	var x := 0.0
	while x < t.after_image_s():
		var k := t.after_image_k(x)
		assert_float(absf(k - prev)).is_less(0.05)   # ≤ VOID_2 × 0.05 per frame: far under the 0.02 luma step bound
		prev = k
		x += 1.0 / 60.0


func test_the_breath_has_no_onset() -> void:
	var t := _t()
	assert_float(t.breath_gain_db(0.0)).is_equal_approx(0.0, 0.001)
	assert_float(t.breath_gain_db(t.breath_s * 0.5)).is_equal_approx(t.breath_db, 0.001)
	assert_float(t.breath_gain_db(t.breath_s - 0.001)).is_less(0.01)
	var d := _decay()
	var m := d.marks()
	assert_float(CabinetDecayAudio.breath_db(d, m[1] - 0.01)).is_equal(0.0)
	assert_float(CabinetDecayAudio.breath_db(d, m[1])).is_equal_approx(0.0, 0.001)
	assert_float(CabinetDecayAudio.breath_db(d, m[3])).is_equal(0.0)


# --- the screen layer: costume only, in the play view, no face ---

func test_the_figure_stands_at_the_right_edge_of_the_play_view_away_from_the_centre() -> void:
	var spec := load(SPEC) as CabinetScreenSpec
	var play := spec.play_rect()
	var pts := CabinetHauntScreen.figure_outline(play)
	for p in pts:
		assert_bool(play.has_point(p)).is_true()
		assert_float(p.x).is_greater(play.position.x + play.size.x * 0.75)


func test_the_after_image_is_the_column_the_reveal_will_empty_and_never_touches_the_strip() -> void:
	var spec := load(SPEC) as CabinetScreenSpec
	var hs := CabinetHauntScreen.new()
	add_child(hs)
	var want := MawView.column_outline(MawView.focus_point(spec, _decay()), spec.play_rect().size.y)
	assert_array(Array(hs._outline)).is_equal(Array(want))
	for p in want:
		assert_float(p.y).is_greater_equal(spec.strip_rect().end.y)
	hs.free()


func test_the_figure_lasts_exactly_one_field() -> void:
	var hs := CabinetHauntScreen.new()
	add_child(hs)
	hs.show_figure()
	assert_bool(hs.is_showing_figure()).is_true()
	await get_tree().process_frame
	await get_tree().process_frame
	assert_bool(hs.is_showing_figure()).is_false()
	hs.free()


func test_a_ghost_press_sinks_the_cap_and_does_nothing() -> void:
	var b := ArcadeButton.new()
	add_child(b)
	var presses := [0]
	b.pressed.connect(func() -> void: presses[0] += 1)
	b.ghost_press(0.5)
	assert_bool(b.is_ghost_pressed()).is_true()
	b._process(0.2)
	assert_float(float(b.face_material().get_shader_parameter(&"press"))).is_greater(0.0)
	b._process(0.4)
	assert_bool(b.is_ghost_pressed()).is_false()
	assert_int(presses[0]).is_equal(0)
	b.free()


# --- the shift: only from a0_3, never during play; the stage loop is detuned by Wear ---

func test_a0_1_and_a0_2_never_haunt_and_a0_3_may() -> void:
	var game := SCENE.instantiate() as CabinetGame
	add_child(game)
	game.set_process(false)
	game.start_stage(0)
	assert_bool(game.haunts.enabled).is_false()
	game.start_stage(1)
	assert_bool(game.haunts.enabled).is_false()
	game.start_stage(2)
	assert_bool(game.haunts.enabled).is_true()
	game.free()


func test_a_forced_after_image_shows_on_the_ready_card_and_leaves_the_readouts_alone() -> void:
	var game := SCENE.instantiate() as CabinetGame
	add_child(game)
	game.set_process(false)
	var hud := game.hud
	var score_before := hud.score
	game.haunts.deck.forced = &"after_image"
	game.start_stage(3)
	assert_str(String(game.haunts.last_kind)).is_equal("after_image")
	await get_tree().process_frame
	await get_tree().process_frame
	assert_float(game.haunt_screen.after_image_k()).is_greater(0.0)
	assert_int(hud.score).is_equal(score_before)
	assert_int(game.state).is_equal(CabinetGame.State.INTRO)   # a READY card, not play
	game.free()


func test_a0_4_and_a0_5_have_the_stage_loop_detuned_by_wear() -> void:
	var game := SCENE.instantiate() as CabinetGame
	add_child(game)
	game.set_process(false)
	assert_str(String(game.stages[3].music)).is_equal("a0_stage_loop")
	assert_str(String(game.stages[4].music)).is_equal("a0_stage_loop")
	assert_str(String(game.stages[2].music)).is_empty()
	game.start_stage(4)
	var d := _decay()
	assert_float(game.music.pitch_scale()).is_equal_approx(CabinetDecayTuning.cents_to_pitch(d.wear_detune_cents_per_level * 3.0), 0.00001)
	assert_float(game.music.pitch_scale()).is_less(1.0)
	game.free()


# --- the cursed turn ---

func test_the_glass_leans_out_from_d2_and_holds_through_the_collapse() -> void:
	var d := _decay()
	var m := d.marks()
	assert_float(d.bulge_k(m[1])).is_equal(0.0)
	assert_float(d.bulge_k(m[3])).is_equal(1.0)
	assert_float(d.bulge_k(m[4])).is_equal(1.0)
	var prev := 0.0
	var x := 0.0
	while x <= m[4]:
		var k := d.bulge_k(x)
		assert_float(k).is_greater_equal(prev)    # one way only
		prev = k
		x += 0.05


func test_the_focus_is_off_centre_inside_the_play_view() -> void:
	var spec := load(SPEC) as CabinetScreenSpec
	var f := MawView.focus_point(spec, _decay())
	assert_bool(spec.play_rect().has_point(f)).is_true()
	assert_float(f.distance_to(spec.play_centre())).is_greater(spec.play_size().y * 0.15)


func test_the_decay_drives_the_bulge_and_the_off_centre_dot() -> void:
	var mat := ShaderMaterial.new()
	mat.shader = load("res://shaders/crt.gdshader")
	var dec := CabinetDecay.new()
	dec.tuning = _decay()
	dec.crt = mat
	dec.play_top = 0.2
	add_child(dec)
	dec.begin(0, 0)
	dec.seek(dec.tuning.marks()[3])
	assert_float(float(mat.get_shader_parameter(&"bulge"))).is_equal_approx(dec.tuning.bulge_max, 0.0001)
	assert_vector(mat.get_shader_parameter(&"focus") as Vector2).is_equal_approx(dec.tuning.focus_uv(0.2), Vector2(0.0001, 0.0001))
	dec.still = true
	dec.seek(dec.tuning.marks()[3])
	assert_float(float(mat.get_shader_parameter(&"bulge"))).is_equal(0.0)   # reduced motion: no swell
	dec.stop()
	dec.free()


func test_the_wound_is_the_aether_erasure_with_no_disc_no_eye_no_ring() -> void:
	var game := SCENE.instantiate() as CabinetGame
	add_child(game)
	game.set_process(false)
	var maw := game.get_node("%Maw") as MawView
	var wound: EntityPresence = null
	for c in maw.get_children():
		if c is EntityPresence:
			wound = c
	assert_object(wound).is_not_null()
	assert_bool(wound.is_in_group(EntityPresence.GROUP)).is_true()
	maw.radius = 40.0
	assert_float(wound.radius).is_equal(40.0)
	assert_vector(wound.centre).is_equal(maw.centre)
	# the body is a column out of the wound, not a ring round it
	var col := maw.column_points()
	assert_float(col[0].distance_to(maw.centre)).is_less(3.0)
	assert_float(col[col.size() - 1].distance_to(maw.centre)).is_greater(150.0)
	game.free()


# --- attract ---

func test_the_attract_is_clean_until_a0_3() -> void:
	var t := _t()
	assert_bool(AttractMode_haunting_unlocked({}, t)).is_false()
	assert_bool(AttractMode_haunting_unlocked({"act0_stage_reached": 1}, t)).is_false()
	assert_bool(AttractMode_haunting_unlocked({"act0_stage_reached": 2}, t)).is_true()
	assert_bool(AttractMode_haunting_unlocked({"act0_complete": true}, t)).is_true()
	assert_bool(AttractMode_haunting_unlocked({"act0_stage_reached": "x"}, t)).is_false()


func AttractMode_haunting_unlocked(p: Dictionary, t: CabinetHauntTuning) -> bool:
	var script := load("res://scenes/attract/attract_mode.gd") as GDScript
	return bool(script.call(&"haunting_unlocked", p, t))


func test_the_stranger_is_an_extra_row_tied_with_you_shown_once() -> void:
	var pages := AttractPages.new()
	pages.tuning = load("res://data/cabinet/cabinet_boot_tuning.tres") as CabinetBootTuning
	pages.scores = load("res://data/cabinet/cabinet_tuning.tres") as CabinetTuning
	add_child(pages)
	pages.hi_score = 12340
	pages.show_stranger()
	var guard := 0
	while pages.page != AttractPages.Page.ROLL and guard < 10:
		pages._process(pages.tuning.page_seconds + 0.01)
		guard += 1
	var rows := pages.roll_rows()
	assert_int(rows.size()).is_equal(3)
	assert_str(rows[1][1]).is_equal(LocFormat.format_int(12340))   # your row stays honest
	assert_str(rows[2][0]).is_equal(tr("CAB_ROLL_STRANGER"))
	assert_str(rows[2][1]).is_equal(rows[1][1])                    # tied with you
	pages._process(pages.tuning.page_seconds + 0.01)               # leave the roll
	while pages.page != AttractPages.Page.ROLL:
		pages._process(pages.tuning.page_seconds + 0.01)
	assert_int(pages.roll_rows().size()).is_equal(2)               # once only
	pages.free()
