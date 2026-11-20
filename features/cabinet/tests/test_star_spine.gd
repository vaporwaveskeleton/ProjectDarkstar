extends GdUnitTestSuite
## S8 star-spine secret: in THE LAST NORMAL DAY only, 20 faint stars trace the entity's spine. When the
## reveal's `stars.pull` begins they brighten and hold, then travel to the maw's vertebrae and vanish as
## each is shown. Deterministic (formula, no rng). Driven only through Starfield.pull / MawView.reveal.

const SCENE := preload("res://features/cabinet/cabinet_game.tscn")
const STAGE_3 := preload("res://data/cabinet/stage_last_normal_day.tres")

var game: Node
var world: ArcadeWorld
var stars: Starfield
var maw: MawView


func before_test() -> void:
	AudioService.muted_for_tests = true
	SaveService.set_backend(MemorySaveBackend.new())
	SettingsService.persist = false
	game = SCENE.instantiate()
	add_child(game)
	game.set_process(false)
	world = game.get_node("%World")
	world.paused_sim = true
	stars = world.stars
	maw = game.get_node("%Reveal").maw


func after_test() -> void:
	SettingsService.persist = true
	if is_instance_valid(game):
		game.free()
	AudioService.muted_for_tests = false
	SaveService.set_backend(FileSaveBackend.new())


func _start(spine: bool) -> void:
	var s := STAGE_3.duplicate() as CabinetStage
	s.spine_stars = spine
	world.start(s)


func test_flag_is_on_only_in_the_last_normal_day() -> void:
	assert_bool(STAGE_3.spine_stars).is_true()
	assert_bool(load("res://data/cabinet/stage_first_vigil.tres").spine_stars).is_false()


func test_flag_false_has_no_spine_stars() -> void:
	_start(false)
	assert_int(stars.spine_star_count()).is_equal(0)


func test_flag_true_has_forty_deterministic_stars_in_bone_2() -> void:
	_start(true)
	world.view_centre = Vector2.ZERO     # the tile wrap of a star column depends on the camera: read it at the origin
	assert_int(stars.spine_star_count()).is_equal(Starfield.SPINE_STARS)
	var a: Array[Vector2] = []
	for i in 40:
		a.append(stars.spine_star_pos(i))
	_start(true)
	world.view_centre = Vector2.ZERO
	for i in 40:
		assert_vector(stars.spine_star_pos(i)).is_equal(a[i])
	assert_object(stars.spine_star_color()).is_equal(Look.c(Pal.BONE_2))
	# the S curve: a column that runs top to bottom and sways both ways
	assert_float(a[38].y).is_greater(a[0].y)
	var xs: Array[float] = []
	for p in a:
		xs.append(p.x)
	assert_float(xs.max() - xs.min()).is_greater(10.0)


func _arrival_pull() -> float:
	return world.fx_tuning.spine_hold_pull + world.fx_tuning.spine_pull_span


func test_hold_then_travel_to_the_vertebra_slots() -> void:
	_start(true)
	maw.centre = Vector2(200, 150)
	var home: Array[Vector2] = []
	for i in 40:
		home.append(stars.spine_star_pos(i))
	var hold := world.fx_tuning.spine_hold_pull
	stars.pull = hold * 0.5
	assert_object(stars.spine_star_color()).is_equal(Look.c(Pal.BONE_5))
	for i in 40:
		assert_vector(stars.spine_star_pos(i)).is_equal(home[i])
	# past the hold: both stars of pair i move toward vertebra i's slot
	stars.pull = hold + world.fx_tuning.spine_pull_span * 0.5
	for i in 40:
		var want := home[i].lerp(maw.vertebra_star_pos(i >> 1, i & 1), 0.5)
		assert_vector(stars.spine_star_pos(i)).is_equal_approx(want, Vector2(0.01, 0.01))
	# done: side by side at the slot, 2 x SPINE_PAIR_GAP apart across the ring tangent
	stars.pull = hold + world.fx_tuning.spine_pull_span
	for i in 20:
		var a := stars.spine_star_pos(2 * i)
		var b := stars.spine_star_pos(2 * i + 1)
		assert_vector((a + b) * 0.5).is_equal_approx(maw.vertebra_screen_pos(i), Vector2(0.01, 0.01))
		assert_float(a.distance_to(b)).is_equal_approx(MawView.SPINE_PAIR_GAP * 2.0, 0.01)


func test_star_pair_i_is_hidden_once_vertebra_i_is_shown() -> void:
	_start(true)
	maw.reveal = 0.0
	for i in 40:
		assert_bool(stars.spine_star_hidden(i)).is_false()
	maw.reveal = 0.26      # ceil(5.2) = 6 vertebrae shown
	for i in 40:
		assert_bool(stars.spine_star_hidden(i)).is_equal((i >> 1) < 6)
	maw.reveal = 1.0
	for i in 40:
		assert_bool(stars.spine_star_hidden(i)).is_true()


func test_no_rng_is_consumed_and_regular_stars_unchanged() -> void:
	_start(true)
	var before := world.rng.state
	stars.pull = 0.5
	for i in 40:
		stars.spine_star_pos(i)
	assert_int(world.rng.state).is_equal(before)
	# the three regular layers are identical with and without the spine (same seed-77 draw)
	var with: Array = stars._stars.duplicate(true)
	_start(false)
	assert_array(stars._stars).is_equal(with)
	assert_int(stars._stars[0].size() + stars._stars[1].size() + stars._stars[2].size()).is_equal(180)


func test_spine_stars_arrive_before_the_maw_shows_its_first_vertebra() -> void:
	# pretence_reveal.gd tweens stars.pull 0 -> 1 over 8 s (TRANS_QUAD, EASE_IN, so pull = (t/8)^2)
	# and starts maw.reveal 2.5 s later. Every spine star must have finished travelling by then,
	# so the stars visibly BECOME the vertebrae instead of vanishing mid-flight.
	var pull_when_reveal_starts := pow(2.5 / 8.0, 2.0)
	assert_float(_arrival_pull()).is_less(pull_when_reveal_starts)


func test_pairs_straddle_the_curve_at_the_s2_width() -> void:
	_start(true)
	var length := world.view_size.y * Starfield.SPINE_LENGTH_FRAC
	var head := Vector2(world.view_size.x * Starfield.SPINE_X_FRAC, world.view_size.y * Starfield.SPINE_TOP_FRAC)
	var curve := MawView.spine_place(MawView.spine_points(), head, Vector2.DOWN, length)
	var width_scale := length / (SepulchreRitual.TRUE_LENGTH_MULT * SepulchreRitual.BODY_DRAWN_RADIUS)
	for i in 20:
		var a: Vector2 = stars._spine[2 * i]
		var b: Vector2 = stars._spine[2 * i + 1]
		assert_vector((a + b) * 0.5).is_equal_approx(curve[i], Vector2(0.01, 0.01))                 # straddle the curve point
		var w := MawView.spine_half_width(i) * width_scale
		assert_float(a.distance_to(curve[i])).is_equal_approx(w, 0.01)
		assert_float(b.distance_to(curve[i])).is_equal_approx(w, 0.01)
		assert_float(a.distance_to(b)).is_equal_approx(2.0 * w, 0.01)                              # opposite sides
	# identical across resets
	var first: PackedVector2Array = stars._spine.duplicate()
	_start(true)
	assert_array(stars._spine).is_equal(first)


func test_formed_beat_is_bone_5_two_by_two_while_play_stars_stay_faint_pixels() -> void:
	_start(true)
	assert_vector(stars.spine_star_size()).is_equal(Vector2.ONE)
	assert_object(stars.spine_star_color()).is_equal(Look.c(Pal.BONE_2))
	stars.pull = world.fx_tuning.spine_hold_pull * 0.5
	assert_vector(stars.spine_star_size()).is_equal(Vector2(2, 2))
	assert_object(stars.spine_star_color()).is_equal(Look.c(Pal.BONE_5))
	for i in 40:
		assert_bool(stars.spine_star_drawn(i)).is_true()


func test_hand_off_the_starfield_stops_and_the_maw_draws_both_stars_until_the_vertebra_shows() -> void:
	_start(true)
	maw.stars = stars
	maw.reveal = 0.0
	stars.pull = _arrival_pull() * 0.5
	assert_bool(stars.spine_star_arrived()).is_false()
	assert_int(maw.spine_star_rects().size()).is_equal(0)
	for i in 40:
		assert_bool(stars.spine_star_drawn(i)).is_true()
	stars.pull = _arrival_pull()
	assert_bool(stars.spine_star_arrived()).is_true()
	for i in 40:
		assert_bool(stars.spine_star_drawn(i)).is_false()
	var rects := maw.spine_star_rects()
	assert_int(rects.size()).is_equal(40)
	for i in 40:
		assert_vector(rects[i].position).is_equal(maw.vertebra_star_pos(i >> 1, i & 1).round())
		assert_vector(rects[i].size).is_equal(Vector2(2, 2))
	# vertebra i shown: MawView stops drawing both stars of pair i
	maw.reveal = 0.26      # ceil(5.2) = 6 vertebrae
	rects = maw.spine_star_rects()
	assert_int(rects.size()).is_equal(28)
	assert_vector(rects[0].position).is_equal(maw.vertebra_star_pos(6, 0).round())
	maw.reveal = 1.0
	assert_int(maw.spine_star_rects().size()).is_equal(0)


func test_coordinate_spaces_match_at_arrival() -> void:
	_start(true)
	maw.stars = stars
	stars.pull = _arrival_pull()
	assert_vector(maw.centre).is_equal_approx(stars.pull_target, Vector2(1, 1))
	var to_canvas_stars := stars.get_global_transform_with_canvas()
	var to_canvas_maw := maw.get_global_transform_with_canvas()
	for i in 40:
		var s := to_canvas_stars * stars.spine_star_pos(i)
		var m := to_canvas_maw * maw.vertebra_star_pos(i >> 1, i & 1)
		assert_vector(s).is_equal_approx(m, Vector2(1, 1))
		assert_vector(stars.spine_star_pos(i).round()).is_equal_approx(maw.spine_star_rects()[i].position, Vector2(1, 1))


func test_hand_off_draws_no_rng() -> void:
	_start(true)
	maw.stars = stars
	stars.pull = _arrival_pull()
	var before := world.rng.state
	maw.spine_star_rects()
	for i in 40:
		stars.spine_star_drawn(i)
	assert_int(world.rng.state).is_equal(before)
