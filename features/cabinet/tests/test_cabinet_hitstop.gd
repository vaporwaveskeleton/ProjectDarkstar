extends GdUnitTestSuite
## Hit-stop (✱ PROPOSED frames in CabinetFxTuning): the sim hangs, nothing else does.

const SCENE := preload("res://features/cabinet/cabinet_game.tscn")
const DT := 1.0 / 60.0

var game: Node
var world: ArcadeWorld
var fx: CabinetFxTuning
var _saved_reduced := false


func before_test() -> void:
	AudioService.muted_for_tests = true
	SaveService.set_backend(MemorySaveBackend.new())
	_saved_reduced = SettingsService.get_value(&"reduced_motion")
	SettingsService.set_value(&"reduced_motion", false)
	game = SCENE.instantiate()
	add_child(game)
	game.set_process(false)
	world = game.get_node("%World")
	world.paused_sim = true
	fx = world.fx_tuning
	world.start(_stage())


func after_test() -> void:
	SettingsService.set_value(&"reduced_motion", _saved_reduced)
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


func test_freeze_ticks_no_layer_and_holds_time_then_resumes() -> void:
	var rot0: float = world.ritual._rot
	world.hitstop(3)
	var t0 := world.time
	for i in 3:
		world.step(DT)
		assert_float(world.time).is_equal(t0)
		assert_float(world.ritual._rot).is_equal(rot0)
	world.step(DT)
	assert_float(world.time).is_greater(t0)
	assert_float(world.ritual._rot).is_not_equal(rot0)


func test_freeze_holds_the_shake() -> void:
	world.shake(4.0, 0.25)
	world.hitstop(2)
	world.step(DT)
	world.step(DT)
	assert_float(world._shake).is_equal(0.25)
	world.step(DT)
	assert_float(world._shake).is_less(0.25)


func test_stacking_takes_the_max_not_the_sum() -> void:
	world.hitstop(3)
	world.hitstop(5)
	assert_int(world.hitstop_left).is_equal(5)
	world.hitstop(2)
	assert_int(world.hitstop_left).is_equal(5)


func test_clamped_to_max_frames() -> void:
	world.hitstop(fx.hitstop_max_frames + 50)
	assert_int(world.hitstop_left).is_equal(fx.hitstop_max_frames)


func test_zero_frames_is_a_no_op() -> void:
	world.hitstop(0)
	assert_int(world.hitstop_left).is_equal(0)
	var t0 := world.time
	world.step(DT)
	assert_float(world.time).is_greater(t0)


func test_reduced_motion_scales_the_freeze() -> void:
	SettingsService.set_value(&"reduced_motion", true)
	world.hitstop(8)
	assert_int(world.hitstop_left).is_equal(roundi(8 * fx.hitstop_reduced_motion_scale))


func test_reduced_motion_scale_zero_disables() -> void:
	SettingsService.set_value(&"reduced_motion", true)
	var dup := fx.duplicate() as CabinetFxTuning
	dup.hitstop_reduced_motion_scale = 0.0
	world.fx_tuning = dup
	world.hitstop(8)
	assert_int(world.hitstop_left).is_equal(0)


func test_start_clears_the_counter() -> void:
	world.hitstop(5)
	world.start(_stage())
	assert_int(world.hitstop_left).is_equal(0)


func test_a_charge_hit_on_the_entity_freezes_the_sim() -> void:
	for i in roundi((world.tuning.awakening_silence + world.tuning.stagger_window + 0.1) / DT):
		world.step(DT)
	assert_int(world.hitstop_left).is_equal(0)
	world.ritual.charge_contact(world.ritual.entity_pos, 1.0)
	assert_int(world.hitstop_left).is_equal(fx.hitstop_charge_hits_entity_frames)


func test_vigil_death_freezes_the_sim() -> void:
	world.vigil.shield = 0.0
	world.vigil.kill()
	assert_int(world.hitstop_left).is_equal(fx.hitstop_vigil_death_frames)


func test_the_crt_clock_keeps_running_through_the_freeze() -> void:
	world.hitstop(2)
	var s0 := world.shader_time
	world.step(DT)
	assert_float(world.shader_time).is_greater(s0)


func _collect_beats() -> Array:
	var beats: Array = []
	world.hitstop_started.connect(func(b: StringName) -> void: beats.append(b))
	return beats


func test_signal_fires_with_the_beat_on_a_real_freeze() -> void:
	var beats := _collect_beats()
	world.hitstop(3, &"vigil_death")
	assert_array(beats).is_equal([&"vigil_death"])


func test_signal_fires_on_extension_but_not_when_a_larger_freeze_runs() -> void:
	var beats := _collect_beats()
	world.hitstop(5, &"a")
	world.hitstop(3, &"b")
	world.hitstop(5, &"c")
	world.hitstop(7, &"d")
	assert_array(beats).is_equal([&"a", &"d"])


func test_signal_silent_for_zero_frames_and_reduced_scale_zero() -> void:
	var beats := _collect_beats()
	world.hitstop(0, &"x")
	SettingsService.set_value(&"reduced_motion", true)
	var dup := fx.duplicate() as CabinetFxTuning
	dup.hitstop_reduced_motion_scale = 0.0
	world.fx_tuning = dup
	world.hitstop(8, &"y")
	assert_array(beats).is_empty()


func test_real_beats_pass_their_ids() -> void:
	var beats := _collect_beats()
	world.vigil.shield = 0.0
	world.vigil.kill()
	assert_array(beats).is_equal([&"vigil_death"])
