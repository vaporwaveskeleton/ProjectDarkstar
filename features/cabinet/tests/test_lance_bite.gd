extends GdUnitTestSuite
## The Lance bites: muzzle star, visual-only recoil, impact flecks, and the chalk tick that
## teaches "the lance cannot hurt it". All feedback is cosmetic and never touches world.rng.

const SCENE := preload("res://features/cabinet/cabinet_game.tscn")
const DT := 1.0 / 60.0

var game: Node
var world: ArcadeWorld
var _saved_photo: Variant
var _saved_reduced: Variant


func before_test() -> void:
	AudioService.muted_for_tests = true
	SaveService.set_backend(MemorySaveBackend.new())
	_saved_photo = SettingsService.get_value(&"photosensitivity")
	_saved_reduced = SettingsService.get_value(&"reduced_motion")
	SettingsService.set_value(&"photosensitivity", false)
	SettingsService.set_value(&"reduced_motion", false)
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


func after_test() -> void:
	SettingsService.set_value(&"photosensitivity", _saved_photo)
	SettingsService.set_value(&"reduced_motion", _saved_reduced)
	if is_instance_valid(game):
		game.free()
	AudioService.muted_for_tests = false
	SaveService.set_backend(FileSaveBackend.new())


func _fire_once() -> void:
	var v := world.vigil
	v.shield = 0.0
	v.use_scripted = true
	v.scripted_aim = Vector2.RIGHT * 10.0
	v.facing = 0.0
	v.scripted_fire = true
	world.step(DT)
	v.scripted_fire = false


func test_muzzle_star_lasts_exactly_the_tuned_drawn_frames() -> void:
	_fire_once()
	var n: int = world.fx_tuning.muzzle_star_frames
	assert_int(world.vigil.muzzle_frames_left).is_equal(n)
	for i in n:
		assert_int(world.vigil.muzzle_frames_left).is_greater(0)
		world.vigil.advance_draw_frame()
	assert_int(world.vigil.muzzle_frames_left).is_equal(0)


func test_muzzle_star_is_suppressed_under_photosensitivity() -> void:
	SettingsService.set_value(&"photosensitivity", true)
	_fire_once()
	assert_int(world.vigil.muzzle_frames_left).is_equal(0)


func test_recoil_is_visual_only() -> void:
	_fire_once()
	var v := world.vigil
	assert_int(v.recoil_frames_left).is_equal(world.fx_tuning.recoil_frames)
	var off := v.recoil_offset()
	assert_float(off.length()).is_greater_equal(1.0)
	assert_float(off.dot(Vector2.RIGHT)).is_less(0.0)   # opposite the aim
	# a twin run without the nudge has identical pos/vel
	var pos_a := v.pos
	var vel_a := v.vel
	v.recoil_frames_left = 0
	assert_vector(v.recoil_offset()).is_equal(Vector2.ZERO)
	assert_vector(v.pos).is_equal(pos_a)
	assert_vector(v.vel).is_equal(vel_a)
	assert_float(v.facing).is_equal(0.0)


func test_recoil_counts_down_in_drawn_frames_and_is_absent_under_reduced_motion() -> void:
	_fire_once()
	for i in world.fx_tuning.recoil_frames:
		world.vigil.advance_draw_frame()
	assert_vector(world.vigil.recoil_offset()).is_equal(Vector2.ZERO)
	world.vigil.shield = 0.0
	SettingsService.set_value(&"reduced_motion", true)
	world.vigil._fire_cooldown = 0.0
	_fire_once()
	assert_int(world.vigil.recoil_frames_left).is_equal(0)
	assert_vector(world.vigil.recoil_offset()).is_equal(Vector2.ZERO)


func test_fleck_spawns_two_perpendicular_specks_without_touching_rng() -> void:
	var st := world.rng.state
	world.fx.fleck(Vector2(100, 100), Vector2.RIGHT)
	assert_int(world.rng.state).is_equal(st)
	assert_int(world.fx.flecks.size()).is_equal(2)
	var a: FxLayer.Fleck = world.fx.flecks[0]
	var b: FxLayer.Fleck = world.fx.flecks[1]
	assert_float(a.vel.dot(Vector2.RIGHT)).is_equal_approx(0.0, 0.001)
	assert_vector(a.vel + b.vel).is_equal_approx(Vector2.ZERO, Vector2(0.001, 0.001))
	assert_float(a.vel.length()).is_equal_approx(world.fx_tuning.fleck_speed_px_s, 0.001)
	world.fx.tick(world.fx_tuning.fleck_life_s + 0.01)
	assert_int(world.fx.flecks.size()).is_equal(0)


func test_a_lance_bolt_on_a_geode_leaves_flecks() -> void:
	var g := world.geodes.add_geode(Vector2(400, 300), 2)
	g.vel = Vector2.ZERO
	world.shots.fire_lance(g.pos - Vector2(40, 0), Vector2.RIGHT, Vector2.ZERO)
	for i in 30:
		world.shots.tick(DT)
	assert_int(world.fx.flecks.size()).is_greater_equal(2)


func test_chalk_tick_takes_no_rng_and_expires() -> void:
	var st := world.rng.state
	world.fx.chalk_tick(Vector2(50, 50), Vector2.RIGHT)
	assert_int(world.rng.state).is_equal(st)
	assert_int(world.fx.chalk_ticks.size()).is_equal(1)
	assert_float(world.fx.chalk_ticks[0].dir.dot(Vector2.RIGHT)).is_equal_approx(0.0, 0.001)
	world.fx.tick(world.fx_tuning.tick_life_s + 0.01)
	assert_int(world.fx.chalk_ticks.size()).is_equal(0)


func test_lance_dull_sfx_path_is_safe_muted() -> void:
	world.sfx(&"lance_dull", world.fx_tuning.lance_dull_db)
	assert_bool(AudioService.muted_for_tests).is_true()


func test_fx_reset_clears_the_new_items() -> void:
	world.fx.fleck(Vector2.ZERO, Vector2.RIGHT)
	world.fx.chalk_tick(Vector2.ZERO, Vector2.RIGHT)
	world.fx.reset()
	assert_int(world.fx.flecks.size()).is_equal(0)
	assert_int(world.fx.chalk_ticks.size()).is_equal(0)
