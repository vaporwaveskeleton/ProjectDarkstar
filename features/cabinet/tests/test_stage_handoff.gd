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
	var cleared: Array = []
	world.sepulchre_cleared.connect(func() -> void: cleared.append(true))
	var ritual: SepulchreRitual = world.ritual
	ritual.segments = 1
	ritual._knock_modules(ritual.pos)
	assert_int(cleared.size()).is_equal(1)
	assert_int(world.hitstop_left).override_failure_message("only the knock's own 2-frame hit-stop: a longer one cost the autopilot 3 of 20 shifts").is_less_equal(world.fx_tuning.hitstop_modules_knocked_frames)


func test_the_hand_off_numbers_stay_inside_the_flash_and_motion_caps() -> void:
	var ft := world.fx_tuning
	assert_float(ft.handoff_collapse_s + ft.handoff_morph_s).is_less(2.0)
	assert_float(ft.sepulchre_down_shake_amp).is_less_equal(4.0)
	assert_float(ft.sepulchre_down_shake_dur).is_less_equal(0.25)


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
	for m in [0.0, 0.3, 0.5, 0.7, 1.0]:
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
			assert_float(float(keep) / 200.0).is_between(1.0 - star.dissolve() - 0.08, 1.0 - star.dissolve() + 0.08)


func test_the_sky_pulls_back_before_it_tears_and_settles_clean() -> void:
	star.begin_morph(&"shoal", 1.0)
	star.morph = 0.05
	assert_float(star.disturbance(0)).override_failure_message("an anticipation beat the other way").is_less(0.0)
	star.morph = 0.5
	assert_float(star.disturbance(0)).is_greater(0.5)
	assert_float(star.disturbance(2)).override_failure_message("deeper layers lag").is_not_equal(star.disturbance(0))
	star.morph = 1.0
	assert_float(absf(star.disturbance(0))).is_less(0.01)


func test_the_warp_is_bounded_off_when_calm_and_stronger_with_wear() -> void:
	star.begin_morph(&"shoal", 1.0)
	star.morph = 0.4
	var ft := world.fx_tuning
	var peak := 0.0
	for y in range(0, 300, 1):
		peak = maxf(peak, absf(star.warp_dx(float(y))))
	assert_float(peak).is_greater(0.0)
	assert_float(peak).is_less_equal(ft.handoff_warp_px + ft.handoff_tear_px + 1.0)
	star.begin_morph(&"shoal", 1.0, 2.0)
	star.morph = 0.4
	var strong := 0.0
	for y in range(0, 300, 1):
		strong = maxf(strong, absf(star.warp_dx(float(y))))
	assert_float(strong).is_greater(peak)
	star.morph = 0.4
	SettingsService.set_value(&"photosensitivity", true)
	assert_float(star.warp_dx(40.0)).is_equal(0.0)
	assert_float(star.wash()).is_equal(0.0)
	SettingsService.set_value(&"photosensitivity", false)
	SettingsService.set_value(&"reduced_motion", true)
	assert_float(star.warp_dx(40.0)).is_equal(0.0)


func test_the_kill_wash_is_one_soft_pulse_under_the_cap() -> void:
	star.begin_morph(&"shoal", 1.4)
	star.morph = 0.01 / 1.4
	assert_float(star.wash()).is_greater(0.0)
	star.morph = 0.5
	assert_float(star.wash()).is_equal(0.0)
	assert_float(world.fx_tuning.handoff_wash).is_less_equal(0.2)


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
	for k in [&"chains", &"shoal", &"horizon", &"currents"]:
		var c := star.backdrop_color(k)
		assert_bool([Look.c(Pal.VOID_3), Look.c(Pal.VOID_4), Look.c(Pal.VOID_5)].has(c)).is_true()
