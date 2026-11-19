extends GdUnitTestSuite
## Last-Charge slow-mo (owner-approved numbers in CabinetFxTuning (SYS-001 §9)): the world slows, nothing else does.

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
	for i in roundi((world.tuning.awakening_silence + world.tuning.stagger_window + 0.1) / DT):
		world.step(DT)
	world.hitstop_left = 0
	world.vigil.shield = 1000.0
	world.vigil.pos = world.torus.wrap(world.ritual.entity_pos + world.torus.size * 0.5)


func after_test() -> void:
	SettingsService.set_value(&"reduced_motion", _saved_reduced)
	if is_instance_valid(game):
		game.free()
	AudioService.set_bed_pitch_scale(1.0)
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


## A flying Charge `dist` px from the entity, heading at it.
func _charge(dist: float) -> GlassField.Charge:
	var c := GlassField.Charge.new()
	c.pos = world.torus.wrap(world.ritual.entity_pos + Vector2(dist, 0.0))
	c.dir = Vector2.LEFT
	world.glass.charges_flying.append(c)
	return c


func _steps(n: int) -> void:
	for i in n:
		world.step(DT)


func _ramp_steps() -> int:
	return ceili(fx.slowmo_ramp_in_s / DT) + 3


func test_tuning_scale_is_within_the_audio_clamp() -> void:
	assert_float(fx.slowmo_scale).is_between(0.25, 1.0)


func test_entity_is_awake_for_these_tests() -> void:
	assert_bool(world.ritual.awake).is_true()


func test_not_lethal_with_many_hits_left_and_one_charge() -> void:
	world.ritual.hits_left = 13
	_charge(60.0)
	assert_object(world.glass.lethal_charge()).is_null()
	_steps(_ramp_steps())
	assert_float(world.sim_scale).is_equal(1.0)


func test_lethal_charge_inside_trigger_ramps_down_to_the_scale() -> void:
	world.ritual.hits_left = 1
	_charge(fx.slowmo_trigger_px - 2.0)
	_steps(_ramp_steps())
	assert_float(world.sim_scale).is_equal_approx(fx.slowmo_scale, 0.0001)


func test_lethal_charge_outside_trigger_does_not_slow() -> void:
	world.ritual.hits_left = 1
	_charge(fx.slowmo_trigger_px + 60.0)
	_steps(3)
	assert_float(world.sim_scale).is_equal(1.0)


func test_slowed_world_time_is_scaled_but_the_crt_clock_is_real() -> void:
	world.ritual.hits_left = 1
	_charge(fx.slowmo_trigger_px - 2.0)
	_steps(_ramp_steps())
	var t0 := world.time
	var s0 := world.shader_time
	world.step(DT)
	assert_float(world.time - t0).is_less(DT)
	assert_float(world.time - t0).is_equal_approx(DT * fx.slowmo_scale, 0.0001)
	assert_float(world.shader_time - s0).is_equal_approx(DT, 0.00001)


func test_the_vigil_keeps_real_speed_while_the_world_slows() -> void:
	world.ritual.hits_left = 1
	_charge(fx.slowmo_trigger_px - 2.0)
	_steps(_ramp_steps())
	assert_float(world.sim_scale).is_less(1.0)
	var v := world.vigil
	v.use_scripted = true
	v.scripted_move = Vector2.RIGHT
	v.vel = Vector2(50.0, 0.0)
	var p0 := v.pos
	world.step(DT)
	var moved := world.torus.delta(p0, v.pos)
	assert_float(moved.x).is_equal_approx(v.vel.x * DT, 0.0001)


func test_with_two_hits_left_the_farther_of_two_charges_is_lethal() -> void:
	world.ritual.hits_left = 2
	var near := _charge(38.0)
	var far := _charge(fx.slowmo_trigger_px + 80.0)
	assert_object(near).is_not_null()
	assert_object(world.glass.lethal_charge()).is_same(far)
	# the nearer one is inside the trigger but not lethal: no slow-mo
	world.step(DT)
	assert_float(world.sim_scale).is_equal(1.0)


func test_two_hits_left_slows_by_the_farther_charges_distance() -> void:
	world.ritual.hits_left = 2
	_charge(fx.slowmo_trigger_px - 2.0)
	_charge(60.0)
	_steps(_ramp_steps())
	assert_float(world.sim_scale).is_less(1.0)


func test_a_lost_charge_ramps_back_to_normal() -> void:
	world.ritual.hits_left = 1
	var c := _charge(fx.slowmo_trigger_px - 2.0)
	_steps(_ramp_steps())
	assert_float(world.sim_scale).is_less(1.0)
	c.alive = false
	_steps(ceili(fx.slowmo_ramp_out_s / DT) + 3)
	assert_float(world.sim_scale).is_equal(1.0)


func test_a_heal_ramps_back_to_normal() -> void:
	world.ritual.hits_left = 1
	_charge(fx.slowmo_trigger_px - 2.0)
	_steps(_ramp_steps())
	assert_float(world.sim_scale).is_less(1.0)
	world.ritual.hits_left = 2        # healed: one Charge no longer suffices
	_steps(ceili(fx.slowmo_ramp_out_s / DT) + 3)
	assert_float(world.sim_scale).is_equal(1.0)


func test_contact_on_the_entity_snaps_to_one_and_hitstops() -> void:
	world.ritual.hits_left = 1
	_charge(fx.slowmo_trigger_px - 2.0)
	_steps(_ramp_steps())
	assert_float(world.sim_scale).is_less(1.0)
	var unmade: Array = []
	world.entity_unmade.connect(func() -> void: unmade.append(world.sim_scale))
	world.ritual.charge_contact(world.ritual.entity_pos, 1.0)
	assert_float(world.sim_scale).is_equal(1.0)
	assert_int(world.hitstop_left).is_greater(0)
	assert_array(unmade).is_equal([1.0])
	var t0 := world.time
	world.step(DT)
	assert_float(world.time).is_equal(t0)


func test_signal_values_fall_to_the_scale_then_end_exactly_at_one() -> void:
	var vals: Array = []
	world.slowmo_changed.connect(func(s: float) -> void: vals.append(s))
	world.ritual.hits_left = 1
	var c := _charge(fx.slowmo_trigger_px - 2.0)
	_steps(_ramp_steps())
	for i in vals.size():
		assert_float(vals[i]).is_greater_equal(fx.slowmo_scale)
		if i > 0:
			assert_float(vals[i]).is_less(vals[i - 1])
	var held := vals.size()
	for i in 5:
		c.pos = world.torus.wrap(world.ritual.entity_pos + Vector2(fx.slowmo_trigger_px - 2.0, 0.0))
		world.step(DT)
	assert_int(vals.size()).is_equal(held)      # nothing changed, nothing emitted
	c.alive = false
	_steps(ceili(fx.slowmo_ramp_out_s / DT) + 3)
	assert_float(vals[vals.size() - 1]).is_equal(1.0)
	var done := vals.size()
	_steps(5)
	assert_int(vals.size()).is_equal(done)


func test_no_signal_when_nothing_is_slowed() -> void:
	var vals: Array = []
	world.slowmo_changed.connect(func(s: float) -> void: vals.append(s))
	world.end_slowmo()
	_steps(5)
	assert_array(vals).is_empty()


func test_reduced_motion_never_slows() -> void:
	SettingsService.set_value(&"reduced_motion", true)
	world.ritual.hits_left = 1
	_charge(fx.slowmo_trigger_px - 2.0)
	_steps(_ramp_steps() + 5)
	assert_float(world.sim_scale).is_equal(1.0)


func test_failsafe_ends_an_episode_and_locks_until_the_condition_clears() -> void:
	var dup := fx.duplicate() as CabinetFxTuning
	dup.slowmo_max_real_s = 0.5
	world.fx_tuning = dup
	world.ritual.hits_left = 1
	var c := _charge(fx.slowmo_trigger_px - 2.0)
	# keep the Charge hovering in range for the whole episode
	for i in ceili(0.5 / DT) + ceili(dup.slowmo_ramp_out_s / DT) + 6:
		c.pos = world.torus.wrap(world.ritual.entity_pos + Vector2(fx.slowmo_trigger_px - 2.0, 0.0))
		world.step(DT)
	assert_float(world.sim_scale).is_equal(1.0)
	for i in 20:
		c.pos = world.torus.wrap(world.ritual.entity_pos + Vector2(fx.slowmo_trigger_px - 2.0, 0.0))
		world.step(DT)
	assert_float(world.sim_scale).is_equal(1.0)
	# the condition clears, then returns: slow-mo is available again
	c.alive = false
	world.step(DT)
	_charge(fx.slowmo_trigger_px - 2.0)
	_steps(_ramp_steps())
	assert_float(world.sim_scale).is_less(1.0)


func test_start_resets_the_scale_and_announces_it() -> void:
	world.ritual.hits_left = 1
	_charge(fx.slowmo_trigger_px - 2.0)
	_steps(_ramp_steps())
	assert_float(world.sim_scale).is_less(1.0)
	var vals: Array = []
	world.slowmo_changed.connect(func(s: float) -> void: vals.append(s))
	world.start(_stage())
	assert_float(world.sim_scale).is_equal(1.0)
	assert_array(vals).is_equal([1.0])
