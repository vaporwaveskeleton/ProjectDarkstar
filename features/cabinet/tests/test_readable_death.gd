extends GdUnitTestSuite
## S6 readable death: a chalk ring round what killed the Vigil, a chalk arc on the Vigil, an edge
## tick when the killer is off-view. Deterministic (no world.rng), cleared on respawn / stage start.

const SCENE := preload("res://features/cabinet/cabinet_game.tscn")
const DT := 1.0 / 60.0

var game: Node
var world: ArcadeWorld
var fx: CabinetFxTuning
var _saved_reduced := false


func before_test() -> void:
	AudioService.muted_for_tests = true
	SaveService.set_backend(MemorySaveBackend.new())
	SettingsService.persist = false
	_saved_reduced = SettingsService.get_value(&"reduced_motion")
	SettingsService.set_value(&"reduced_motion", false)
	game = SCENE.instantiate()
	add_child(game)
	game.set_process(false)
	world = game.get_node("%World")
	world.paused_sim = true
	fx = world.fx_tuning
	world.start(_stage())
	world.vigil.shield = 0.0
	world.vigil.use_scripted = true


func after_test() -> void:
	SettingsService.set_value(&"reduced_motion", _saved_reduced)
	SettingsService.persist = true
	if is_instance_valid(game):
		game.free()
	AudioService.muted_for_tests = false
	SaveService.set_backend(FileSaveBackend.new())


func _stage() -> CabinetStage:
	var s := CabinetStage.new()
	s.geodes = 0
	s.grubs = 0
	s.acolytes = 0
	s.guard_acolytes = 0
	s.sepulchre_start_segments = world.tuning.segments_total
	s.sepulchre_wakes = true
	s.chant = false
	s.goal = CabinetStage.Goal.UNMAKE_ENTITY
	return s


func _shoot_vigil() -> void:
	world.shots.fire_censer(world.vigil.pos + Vector2(30, 0), Vector2.LEFT)
	for i in 60:
		world.step(DT)
		if not world.vigil.alive:
			return


func test_hostile_shot_kill_marks_the_shot() -> void:
	_shoot_vigil()
	assert_bool(world.vigil.alive).is_false()
	assert_int(world.fx.death_marks.size()).is_equal(1)
	var m: FxLayer.DeathMark = world.fx.death_marks[0]
	assert_float(world.torus.distance(m.killer_pos, world.vigil.pos)).is_less_equal(world.vigil.radius + 2.0 + 0.01)
	assert_float(m.from_dir.x).is_greater(0.99)   # the shot came from the right
	assert_float(m.killer_radius).is_equal(ShotLayer.HOSTILE_SHOT_RADIUS)
	assert_vector(m.vigil_pos).is_equal(world.vigil.pos)


func test_entity_contact_kill_marks_the_entity_with_its_drawn_radius() -> void:
	for i in roundi((world.tuning.awakening_silence + world.tuning.stagger_window + 0.1) / DT):
		world.step(DT)
	world.vigil.pos = world.torus.wrap(world.ritual.entity_pos + Vector2(60, 0))
	for i in 240:
		world.step(DT)
		if not world.vigil.alive:
			break
	assert_bool(world.vigil.alive).is_false()
	var m: FxLayer.DeathMark = world.fx.death_marks[0]
	assert_vector(m.killer_pos).is_equal(world.ritual.entity_pos)
	assert_float(m.killer_radius).is_equal(SepulchreRitual.BODY_DRAWN_RADIUS)
	assert_float(world.fx.death_ring_radius(m)).is_equal(SepulchreRitual.BODY_DRAWN_RADIUS + fx.death_ring_pad_px)
	assert_float(m.from_dir.length()).is_equal_approx(1.0, 0.001)


func test_ring_clears_the_silhouette_by_at_least_two_px() -> void:
	var dup := fx.duplicate() as CabinetFxTuning
	dup.death_ring_pad_px = 0.0
	world.fx_tuning = dup
	world.fx.death_mark(Vector2(10, 10), 3.0, Vector2.RIGHT, Vector2.ZERO)
	assert_float(world.fx.death_ring_radius(world.fx.death_marks[0])).is_greater_equal(5.0)


func test_default_kill_still_works_and_makes_no_mark() -> void:
	world.vigil.kill()
	assert_bool(world.vigil.alive).is_false()
	assert_int(world.fx.death_marks.size()).is_equal(0)


func test_shielded_kill_makes_no_mark() -> void:
	world.vigil.shield = 1.0
	world.vigil.kill(Vector2(5, 5), Vector2.RIGHT, 3.0)
	assert_bool(world.vigil.alive).is_true()
	assert_int(world.fx.death_marks.size()).is_equal(0)


func test_marks_never_touch_the_rng_even_when_drawn() -> void:
	var st0 := world.rng.state
	world.vigil.kill(world.vigil.pos + Vector2(20, 0), Vector2.RIGHT, 3.0)
	var st1 := world.rng.state   # kill's bursts draw rng; the mark itself must not
	world.fx.death_mark(Vector2(1, 1), 3.0, Vector2.UP, Vector2(2, 2))
	world.fx.death_sweep(world.fx.death_marks[0])
	world.fx.death_edge_tick(world.fx.death_marks[0])
	assert_int(world.rng.state).is_equal(st1)
	await await_idle_frame()
	assert_int(world.rng.state).is_equal(st1)
	assert_bool(st0 != st1).is_true()   # sanity: kill() itself does burst


func test_marks_clear_on_respawn_and_on_world_start() -> void:
	world.fx.death_mark(Vector2(1, 1), 3.0, Vector2.UP, Vector2(2, 2))
	game.state = game.State.DEAD
	game._on_timer()
	assert_int(world.fx.death_marks.size()).is_equal(0)
	world.fx.death_mark(Vector2(1, 1), 3.0, Vector2.UP, Vector2(2, 2))
	world.start(_stage())
	assert_int(world.fx.death_marks.size()).is_equal(0)


func test_sweep_grows_over_sim_time_and_is_full_under_reduced_motion() -> void:
	world.fx.death_mark(Vector2(1, 1), 3.0, Vector2.UP, Vector2(2, 2))
	var m: FxLayer.DeathMark = world.fx.death_marks[0]
	assert_float(world.fx.death_sweep(m)).is_equal(0.0)
	for i in 6:
		world.fx.tick(DT)
	var part := world.fx.death_sweep(m)
	assert_float(part).is_between(0.2, 0.8)
	for i in 30:
		world.fx.tick(DT)
	assert_float(world.fx.death_sweep(m)).is_equal(1.0)
	m.age = 0.0
	SettingsService.set_value(&"reduced_motion", true)
	assert_float(world.fx.death_sweep(m)).is_equal(1.0)


func test_off_view_killer_gets_an_edge_tick_toward_it() -> void:
	var v := world.vigil.pos
	world.fx.death_mark(world.torus.wrap(v + Vector2(0, world.view_size.y)), 3.0, Vector2.DOWN, v)
	var tick := world.fx.death_edge_tick(world.fx.death_marks[0])
	assert_int(tick.size()).is_equal(2)
	assert_bool(world.view_rect.has_point(tick[0])).is_true()
	assert_float(tick[0].y).is_greater(world.screen_centre.y)    # killer is below
	assert_float(tick[1].y).is_less(tick[0].y)                    # tick points back inward


func test_off_view_tick_follows_the_short_way_across_the_wrap() -> void:
	var size := world.torus.size
	var v := Vector2(8.0, size.y * 0.5)
	world.fx.death_mark(Vector2(size.x - 2.0 * world.view_size.x, v.y), 3.0, Vector2.LEFT, v)
	# the long way round is to the right; the torus delta says the killer is to the LEFT or nearer wrap
	var d := world.torus.delta(v, world.fx.death_marks[0].killer_pos)
	var tick := world.fx.death_edge_tick(world.fx.death_marks[0])
	assert_int(tick.size()).is_equal(2)
	assert_bool(signf(tick[0].x - world.screen_centre.x) == signf(d.x)).is_true()


func test_in_view_killer_gets_no_edge_tick() -> void:
	var v := world.vigil.pos
	world.fx.death_mark(v + Vector2(20, 0), 3.0, Vector2.RIGHT, v)
	assert_int(world.fx.death_edge_tick(world.fx.death_marks[0]).size()).is_equal(0)
