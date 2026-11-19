extends GdUnitTestSuite
## S5 Surgelight afterimage and thrust wake: a draw-only trail of the Vigil's past ticks.
## Never changes pos / vel / collision, never touches world.rng, freezes in hit-stop.

const SCENE := preload("res://features/cabinet/cabinet_game.tscn")
const DT := 1.0 / 60.0

var game: Node
var world: ArcadeWorld
var v: VigilShip


func before_test() -> void:
	AudioService.muted_for_tests = true
	SaveService.set_backend(MemorySaveBackend.new())
	SettingsService.persist = false
	_boot()


func _boot() -> void:
	if is_instance_valid(game):
		game.free()
	game = SCENE.instantiate()
	add_child(game)
	game.set_process(false)
	world = game.get_node("%World")
	world.paused_sim = true
	var s := CabinetStage.new()
	s.geodes = 0
	s.grubs = 0
	s.acolytes = 0
	s.guard_acolytes = 0
	s.sepulchre_start_segments = 0
	s.chant = false
	world.start(s)
	v = world.vigil
	v.shield = 0.0
	v.use_scripted = true


func after_test() -> void:
	SettingsService.persist = true
	if is_instance_valid(game):
		game.free()
	AudioService.muted_for_tests = false
	SaveService.set_backend(FileSaveBackend.new())


func _run(n: int, move: Vector2 = Vector2.RIGHT) -> Array[Vector2]:
	v.scripted_move = move
	var seen: Array[Vector2] = []
	for i in n:
		world.step(DT)
		seen.append(v.pos)
	return seen


func test_buffer_length_follows_the_tuning() -> void:
	var ft := world.fx_tuning
	_run(1)
	assert_int(v._trail_pos.size()).is_equal(maxi(ft.ghost_count * ft.ghost_spacing_ticks, ft.wake_dots * ft.wake_spacing_ticks) + 1)


func test_trail_records_one_position_per_tick() -> void:
	var seen := _run(8)
	for k in 8:
		assert_bool(v.trail_has(k)).is_true()
		assert_vector(v.trail_pos(k)).is_equal(seen[7 - k])


func test_trail_does_not_advance_during_hitstop() -> void:
	_run(4)
	var head := v._trail_head
	var count := v._trail_count
	world.hitstop(3)
	for i in 3:
		world.step(DT)
	assert_int(v._trail_head).is_equal(head)
	assert_int(v._trail_count).is_equal(count)
	world.step(DT)
	assert_int(v._trail_head).is_not_equal(head)


func test_ghost_samples_are_the_expected_ticks_back() -> void:
	var ft := world.fx_tuning
	var seen := _run(ft.ghost_count * ft.ghost_spacing_ticks + 2)
	var n := seen.size()
	for i in range(1, ft.ghost_count + 1):
		var k := i * ft.ghost_spacing_ticks
		assert_vector(v.trail_pos(k)).is_equal(seen[n - 1 - k])
		assert_vector(v.trail_offset(k)).is_equal(world.torus.delta(v.pos, seen[n - 1 - k]))


func test_afterimage_shows_during_surge_and_for_the_hold_then_goes() -> void:
	var ft := world.fx_tuning
	assert_bool(v.afterimage_active()).is_false()
	v._surge = 3.5 * DT
	v.scripted_move = Vector2.RIGHT
	world.step(DT)
	assert_bool(v.afterimage_active()).is_true()
	for i in 6:
		world.step(DT)
	assert_float(v._surge).is_less_equal(0.0)
	assert_bool(v.afterimage_active()).is_true()    # inside the hold
	for i in int(ceil(ft.ghost_hold_s / DT)) + 1:
		world.step(DT)
	assert_bool(v.afterimage_active()).is_false()


func test_afterimage_hidden_when_dead() -> void:
	v._surge = 1.0
	_run(2)
	v.alive = false
	assert_bool(v.afterimage_active()).is_false()
	assert_bool(v.wake_active()).is_false()


func test_wake_only_while_thrusting() -> void:
	_run(3, Vector2.ZERO)
	assert_bool(v.wake_active()).is_false()
	_run(1, Vector2.RIGHT)
	assert_bool(v.wake_active()).is_true()
	_run(1, Vector2.ZERO)
	assert_bool(v.wake_active()).is_false()


func test_buffer_clears_on_respawn_and_reset() -> void:
	_run(6)
	assert_int(v._trail_count).is_equal(6)
	v.respawn(Vector2(100, 100))
	assert_int(v._trail_count).is_equal(0)
	assert_bool(v.trail_has(0)).is_false()
	_run(2)
	v._ghost_hold = 1.0
	v.reset()
	assert_int(v._trail_count).is_equal(0)
	assert_float(v._ghost_hold).is_equal(0.0)


func test_ghosts_are_open_never_closed_polygons() -> void:
	var hull := PackedVector2Array([Vector2(9, 0), Vector2(-6, 6), Vector2(-3, 0), Vector2(-6, -6)])
	var last_edges := 99
	for i in range(1, 6):
		var line := v.ghost_outline(hull, i)
		assert_int(line.size()).is_less(5)                 # the closed hull would need 5 points
		assert_bool(line[0] != line[line.size() - 1]).is_true()
		assert_int(line.size()).is_greater_equal(2)
		assert_int(line.size() - 1).is_less_equal(last_edges)
		last_edges = line.size() - 1
	assert_int(v.ghost_outline(hull, 1).size() - 1).is_equal(3)
	assert_int(v.ghost_outline(hull, 2).size() - 1).is_equal(2)
	assert_int(v.ghost_outline(hull, 3).size() - 1).is_equal(1)


func test_ghost_colours_step_gas3_gas2_gas1() -> void:
	assert_object(v.ghost_color(1)).is_equal(Look.c(Pal.GAS_3))
	assert_object(v.ghost_color(2)).is_equal(Look.c(Pal.GAS_2))
	assert_object(v.ghost_color(3)).is_equal(Look.c(Pal.GAS_1))


func test_torus_wrap_draws_relative_not_across_the_field() -> void:
	v.pos = Vector2(3.0, world.torus.size.y * 0.5)
	v.vel = Vector2(-120.0, 0.0)
	var wrapped := false
	var ft := world.fx_tuning
	v.scripted_move = Vector2.LEFT
	for i in 20:
		world.step(DT)
		if v.pos.x > world.torus.size.x * 0.5:
			wrapped = true
		for k in range(1, ft.ghost_count * ft.ghost_spacing_ticks + 1):
			if v.trail_has(k):
				# a ship doing < 600 px/s can move at most 10 px per tick
				assert_float(v.trail_offset(k).length()).is_less_equal(10.0 * k)
	assert_bool(wrapped).is_true()


func test_sim_is_identical_with_the_feature_off_and_rng_untouched() -> void:
	var on := _scripted_run()
	var rng_on := world.rng.state
	_boot()
	var off_tuning := world.fx_tuning.duplicate() as CabinetFxTuning
	off_tuning.ghost_count = 0
	off_tuning.wake_dots = 0
	world.fx_tuning = off_tuning
	v._clear_trail()
	var off := _scripted_run()
	assert_vector(on[0]).is_equal(off[0])
	assert_vector(on[1]).is_equal(off[1])
	assert_int(world.rng.state).is_equal(rng_on)


func _scripted_run() -> Array[Vector2]:
	v._surge = 0.2
	for i in 90:
		v.scripted_move = Vector2.RIGHT if i < 60 else Vector2(1, -1)
		world.step(DT)
	return [v.pos, v.vel]


func test_drawing_does_not_touch_rng() -> void:
	v._surge = 0.5
	_run(12)
	var st := world.rng.state
	await await_idle_frame()
	assert_int(world.rng.state).is_equal(st)
