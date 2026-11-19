extends GdUnitTestSuite
## Stage identity in a still (Reviewer v2 §I "the stages don't announce themselves in a still"; PM under
## owner autonomy grant, 2026-11-19): each stage of the shift draws its own backdrop signature behind
## the stars, in dim VOID registers only, inside the playfield, placed by formula (no spawn RNG).

const SCENE := preload("res://features/cabinet/cabinet_game.tscn")

var game: CabinetGame
var world: ArcadeWorld


func before_test() -> void:
	AudioService.muted_for_tests = true
	SaveService.set_backend(MemorySaveBackend.new())
	game = SCENE.instantiate() as CabinetGame
	add_child(game)
	game.set_process(false)
	world = game.world
	world.paused_sim = true
	game.messages.set_process(false)


func after_test() -> void:
	if is_instance_valid(game):
		game.free()
	AudioService.muted_for_tests = false
	SaveService.set_backend(FileSaveBackend.new())


func _marks_for(st: CabinetStage) -> Array[Rect2]:
	world.start(st)
	return world.stars.backdrop_marks()


func test_every_stage_has_its_own_backdrop() -> void:
	var seen: Dictionary = {}
	for st: CabinetStage in game.stages:
		assert_bool(Starfield.BACKDROPS.has(st.backdrop)).override_failure_message("%s backdrop %s" % [st.id, st.backdrop]).is_true()
		assert_bool(seen.has(st.backdrop)).override_failure_message("%s repeats backdrop %s" % [st.id, st.backdrop]).is_false()
		seen[st.backdrop] = true
	assert_int(seen.size()).is_equal(5)
	assert_str(String((game.stages[0] as CabinetStage).backdrop)).is_empty()   # a0_1 keeps the plain sky


func test_signatures_are_drawn_inside_the_playfield_and_differ() -> void:
	var shapes: Array[String] = []
	for st: CabinetStage in game.stages:
		var marks := _marks_for(st)
		if st.backdrop == &"":
			assert_int(marks.size()).is_equal(0)
		else:
			assert_int(marks.size()).override_failure_message("%s draws no signature" % st.id).is_greater(10)
		var wide := 0
		for m in marks:
			assert_bool(world.playfield_rect.encloses(m)).override_failure_message("%s mark %s outside %s" % [st.id, m, world.playfield_rect]).is_true()
			if m.size.x > 4.0:
				wide += 1
		shapes.append("%d/%d" % [marks.size(), wide])
	for i in shapes.size():
		for j in range(i + 1, shapes.size()):
			assert_str(shapes[i]).override_failure_message("stages %d and %d look alike: %s" % [i, j, shapes[i]]).is_not_equal(shapes[j])


func test_signatures_use_void_registers_only() -> void:
	var allowed := [Look.c(Pal.VOID_3), Look.c(Pal.VOID_4), Look.c(Pal.VOID_5)]
	for st: CabinetStage in game.stages:
		world.start(st)
		assert_bool(allowed.has(world.stars.backdrop_color())).override_failure_message("%s backdrop colour" % st.id).is_true()


func test_the_signature_never_touches_the_spawn_rng() -> void:
	var st := (game.stages[1] as CabinetStage).duplicate() as CabinetStage
	st.backdrop = &""
	world.start(st)
	var plain := world.rng.state
	st.backdrop = &"currents"
	world.start(st)
	world.stars.backdrop_marks()
	assert_int(world.rng.state).is_equal(plain)


func test_the_currents_flow_with_sim_time() -> void:
	var a := _marks_for(game.stages[1] as CabinetStage)
	world.time += 2.0
	var b := world.stars.backdrop_marks()
	assert_bool(a == b).is_false()

