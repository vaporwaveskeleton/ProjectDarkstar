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


func test_flag_true_has_twenty_deterministic_stars_in_bone_2() -> void:
	_start(true)
	assert_int(stars.spine_star_count()).is_equal(Starfield.SPINE_COUNT)
	var a: Array[Vector2] = []
	for i in 20:
		a.append(stars.spine_star_pos(i))
	_start(true)
	for i in 20:
		assert_vector(stars.spine_star_pos(i)).is_equal(a[i])
	assert_object(stars.spine_star_color()).is_equal(Look.c(Pal.BONE_2))
	# the S curve: a column that runs top to bottom and sways both ways
	assert_float(a[19].y).is_greater(a[0].y)
	var xs: Array[float] = []
	for p in a:
		xs.append(p.x)
	assert_float(xs.max() - xs.min()).is_greater(10.0)


func test_hold_then_travel_to_the_vertebrae() -> void:
	_start(true)
	maw.centre = Vector2(200, 150)
	var home: Array[Vector2] = []
	for i in 20:
		home.append(stars.spine_star_pos(i))
	var hold := world.fx_tuning.spine_hold_pull
	stars.pull = hold * 0.5
	assert_object(stars.spine_star_color()).is_equal(Look.c(Pal.BONE_5))
	for i in 20:
		assert_vector(stars.spine_star_pos(i)).is_equal(home[i])
	# past the hold: moving toward vertebra i
	stars.pull = hold + world.fx_tuning.spine_pull_span * 0.5
	for i in 20:
		var want := home[i].lerp(maw.vertebra_screen_pos(i), 0.5)
		assert_vector(stars.spine_star_pos(i)).is_equal_approx(want, Vector2(0.01, 0.01))
	# done: they coincide with the vertebrae
	stars.pull = hold + world.fx_tuning.spine_pull_span
	for i in 20:
		assert_vector(stars.spine_star_pos(i)).is_equal_approx(maw.vertebra_screen_pos(i), Vector2(1, 1))


func test_star_i_is_hidden_once_vertebra_i_is_shown() -> void:
	_start(true)
	maw.reveal = 0.0
	for i in 20:
		assert_bool(stars.spine_star_hidden(i)).is_false()
	maw.reveal = 0.26      # ceil(5.2) = 6 vertebrae shown
	for i in 20:
		assert_bool(stars.spine_star_hidden(i)).is_equal(i < 6)
	maw.reveal = 1.0
	for i in 20:
		assert_bool(stars.spine_star_hidden(i)).is_true()


func test_no_rng_is_consumed_and_regular_stars_unchanged() -> void:
	_start(true)
	var before := world.rng.state
	stars.pull = 0.5
	for i in 20:
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
	var arrival_pull := world.fx_tuning.spine_hold_pull + world.fx_tuning.spine_pull_span
	assert_float(arrival_pull).is_less(pull_when_reveal_starts)
