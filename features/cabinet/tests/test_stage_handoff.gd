extends GdUnitTestSuite
## The stage hand-off (Q-T457, owner 2026-11-20): the last module falls with same-frame feedback, and the
## sky dissolves and warps into the next stage's signature instead of a cut. Draw-only; the sim is untouched.

const SCENE := preload("res://features/cabinet/cabinet_game.tscn")

var game: Node
var world: ArcadeWorld
var star: Starfield


func before_test() -> void:
	AudioService.muted_for_tests = true
	SettingsService.persist = false
	SaveService.set_backend(MemorySaveBackend.new())
	SettingsService.set_value(&"photosensitivity", false)
	SettingsService.set_value(&"reduced_motion", false)
	game = SCENE.instantiate()
	add_child(game)
	game.set_process(false)
	(game.get_node("%Messages") as Node).set_process(false)
	world = game.get_node("%World")
	world.paused_sim = true
	star = world.stars
	game.start_stage(1)   # a0_3, "chains"


func after_test() -> void:
	if is_instance_valid(game):
		game.free()
	SettingsService.set_value(&"photosensitivity", false)
	SettingsService.set_value(&"reduced_motion", false)
	AudioService.muted_for_tests = false
	SaveService.set_backend(FileSaveBackend.new())
	get_tree().paused = false


func test_the_last_module_gives_feedback_on_the_same_frame() -> void:
	var seen: Array = []
	world.hitstop_started.connect(func(beat: StringName) -> void: seen.append(beat))
	var cleared: Array = []
	world.sepulchre_cleared.connect(func() -> void: cleared.append(true))
	var ritual: SepulchreRitual = world.ritual
	ritual.segments = 1
	ritual._knock_modules(ritual.pos)
	assert_int(cleared.size()).is_equal(1)
	assert_array(seen).contains([&"sepulchre_down"])
	assert_int(world.hitstop_left).is_greater_equal(world.fx_tuning.hitstop_sepulchre_down_frames)
	assert_int(world.hitstop_left).is_less_equal(world.fx_tuning.hitstop_max_frames)


func test_the_hand_off_numbers_stay_inside_the_flash_and_motion_caps() -> void:
	var ft := world.fx_tuning
	assert_float(ft.handoff_collapse_s + ft.handoff_morph_s).is_less(2.0)
	assert_float(ft.sepulchre_down_shake_amp).is_less_equal(4.0)
	assert_float(ft.sepulchre_down_shake_dur).is_less_equal(0.25)
	assert_int(ft.hitstop_sepulchre_down_frames).is_less_equal(ft.hitstop_max_frames)


func test_the_morph_runs_from_zero_to_one_and_reset_ends_it() -> void:
	star.begin_morph(&"shoal", 1.0)
	assert_bool(star.morphing()).is_true()
	star.tick(0.5)
	assert_float(star.morph).is_equal_approx(0.5, 0.001)
	star.tick(2.0)
	assert_float(star.morph).is_equal(1.0)
	star.reset()
	assert_bool(star.morphing()).is_false()
	assert_float(star.morph).is_equal(0.0)


func test_the_dissolve_hands_every_mark_to_exactly_one_look() -> void:
	star.begin_morph(&"shoal", 1.0)
	for m in [0.0, 0.3, 0.7, 1.0]:
		star.morph = m
		var keep := 0
		for i in 200:
			if star.morph_keeps_old(i):
				keep += 1
		if m == 0.0:
			assert_int(keep).is_equal(200)
		elif m == 1.0:
			assert_int(keep).is_equal(0)
		else:
			assert_float(float(keep) / 200.0).is_between(1.0 - m - 0.08, 1.0 - m + 0.08)


func test_the_warp_is_a_bell_and_off_when_calm() -> void:
	star.begin_morph(&"shoal", 1.0)
	star.morph = 0.5
	var peak := 0.0
	for y in range(0, 300, 3):
		peak = maxf(peak, absf(star.warp_dx(float(y))))
	assert_float(peak).is_greater(0.0)
	assert_float(peak).is_less_equal(world.fx_tuning.handoff_warp_px)
	star.morph = 1.0
	assert_float(absf(star.warp_dx(40.0))).is_less(0.01)
	star.morph = 0.5
	SettingsService.set_value(&"photosensitivity", true)
	assert_float(star.warp_dx(40.0)).is_equal(0.0)
	SettingsService.set_value(&"photosensitivity", false)
	SettingsService.set_value(&"reduced_motion", true)
	assert_float(star.warp_dx(40.0)).is_equal(0.0)


func test_morph_marks_stay_numbered_and_in_the_playfield() -> void:
	star.begin_morph(&"shoal", 1.0)
	star.morph = 0.5
	var plain := star._marks_of(&"chains", false)
	var warped := star._marks_of(&"chains", true)
	assert_int(warped.size()).override_failure_message("a clipped mark keeps its slot").is_greater_equal(plain.size())
	for r in warped:
		if r.has_area():
			assert_bool(world.playfield_rect.encloses(r)).is_true()


func test_the_look_only_uses_register_colours() -> void:
	# never a blended colour: each look draws in its own VOID register
	for k in [&"chains", &"shoal", &"horizon", &"currents"]:
		var c := star.backdrop_color(k)
		assert_bool([Look.c(Pal.VOID_3), Look.c(Pal.VOID_4), Look.c(Pal.VOID_5)].has(c)).is_true()
