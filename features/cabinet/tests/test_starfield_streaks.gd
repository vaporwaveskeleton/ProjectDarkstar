extends GdUnitTestSuite
## Distant streaks (Starfield, draw-only): one thin dim line every 6-14 s, off under photosensitivity or
## reduced motion, never touching world.rng.

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


func after_test() -> void:
	if is_instance_valid(game):
		game.free()
	SettingsService.set_value(&"photosensitivity", false)
	SettingsService.set_value(&"reduced_motion", false)
	AudioService.muted_for_tests = false
	SaveService.set_backend(FileSaveBackend.new())
	get_tree().paused = false


func _count_streaks(seconds: float) -> int:
	var n := 0
	var was := false
	var t := 0.0
	while t < seconds:
		world.time += 0.05
		t += 0.05
		star._update_streak()
		if star.streak_active() and not was:
			n += 1
		was = star.streak_active()
	return n


func test_streaks_arrive_every_6_to_14_seconds() -> void:
	assert_object(star).is_not_null()
	var n := _count_streaks(120.0)
	assert_int(n).is_between(120 / 15, 120 / 6 + 1)


func test_streaks_are_off_under_photosensitivity_and_reduced_motion() -> void:
	for key in [&"photosensitivity", &"reduced_motion"]:
		SettingsService.set_value(&"photosensitivity", false)
		SettingsService.set_value(&"reduced_motion", false)
		SettingsService.set_value(key, true)
		assert_int(_count_streaks(60.0)).override_failure_message(str(key)).is_equal(0)


func test_streaks_never_draw_from_the_world_rng() -> void:
	var before := world.rng.state
	_count_streaks(60.0)
	assert_int(world.rng.state).is_equal(before)
