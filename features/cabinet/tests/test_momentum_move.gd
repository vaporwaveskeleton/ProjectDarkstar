extends GdUnitTestSuite
## Owner F-9 / Q-T445: the Act 0 momentum ship (the arcade original's one-stick tank, MomentumMove) and
## the Sepulchre's eased chase (Q-T446). Pure steps first, then the real Vigil under held input.

const SCENE := preload("res://features/cabinet/cabinet_game.tscn")
const DT := 1.0 / 60.0

var t: CabinetTuning = load("res://data/cabinet/cabinet_tuning.tres")
var _game: Node


func before_test() -> void:
	AudioService.muted_for_tests = true
	SaveService.set_backend(MemorySaveBackend.new())


func after_test() -> void:
	Input.action_release(&"move_right")
	Input.action_release(&"brake")
	if is_instance_valid(_game):
		_game.free()
	AudioService.muted_for_tests = false
	SaveService.set_backend(FileSaveBackend.new())


func test_momentum_is_the_default_and_the_old_model_stays_selectable() -> void:
	assert_int(t.move_model).is_equal(CabinetTuning.MoveModel.MOMENTUM)
	var old := t.duplicate() as CabinetTuning
	old.move_model = CabinetTuning.MoveModel.DIRECT
	assert_int(old.move_model).is_not_equal(t.move_model)


func test_thrust_only_inside_the_arc_and_only_along_the_heading() -> void:
	assert_bool(MomentumMove.thrusts(0.0, Vector2.from_angle(deg_to_rad(44.0)), t)).is_true()
	assert_bool(MomentumMove.thrusts(0.0, Vector2.from_angle(deg_to_rad(46.0)), t)).is_false()
	assert_bool(MomentumMove.thrusts(0.0, Vector2.ZERO, t)).is_false()
	# a stick 90 degrees off the heading turns the hull but adds no velocity this tick
	var h := MomentumMove.step_heading(0.0, Vector2.DOWN, DT, t)
	assert_float(h).is_greater(0.0)
	var v := Vector2(50.0, 0.0)
	assert_vector(MomentumMove.step_velocity(v, 0.0, Vector2.DOWN, DT, t)).is_equal(v)
	# thrust goes along the heading, not along the stick
	var v2 := MomentumMove.step_velocity(Vector2.ZERO, 0.0, Vector2.from_angle(deg_to_rad(30.0)), DT, t)
	assert_float(v2.y).is_equal_approx(0.0, 0.0001)
	assert_float(v2.x).is_greater(0.0)


func test_velocity_eases_to_a_fixed_max_at_any_deflection_and_never_beyond() -> void:
	for defl in [0.4, 1.0]:
		var v := Vector2.ZERO
		for i in 60 * 12:
			v = MomentumMove.step_velocity(v, 0.0, Vector2.RIGHT * defl, DT, t)
			assert_float(v.length()).is_less_equal(t.momentum_max_speed + 0.001)
		assert_float(v.length()).override_failure_message("max is the same at deflection %s" % defl).is_equal_approx(t.momentum_max_speed, 1.0)
	# full stick: about 0.8 s to 95 % (source), far lazier than the direct model's 0.13 s
	var w := Vector2.ZERO
	for i in 48:
		w = MomentumMove.step_velocity(w, 0.0, Vector2.RIGHT, DT, t)
	assert_float(w.x / t.momentum_max_speed).is_between(0.9, 0.99)


func test_no_drag_and_no_brake_the_ship_coasts() -> void:
	var v := Vector2(200.0, -120.0)
	for i in 600:
		v = MomentumMove.step_velocity(v, 0.0, Vector2.ZERO, DT, t)
	assert_vector(v).is_equal(Vector2(200.0, -120.0))


func test_the_step_is_frame_rate_independent() -> void:
	var a := Vector2.ZERO
	var b := Vector2.ZERO
	for i in 60:
		a = MomentumMove.step_velocity(a, 0.0, Vector2.RIGHT, 1.0 / 60.0, t)
	for i in 30:
		b = MomentumMove.step_velocity(b, 0.0, Vector2.RIGHT, 1.0 / 30.0, t)
	assert_float(a.x).is_equal_approx(b.x, 0.01)
	var one := MomentumMove.step_heading(0.0, Vector2.UP, 1.0, t)
	var two := MomentumMove.step_heading(MomentumMove.step_heading(0.0, Vector2.UP, 0.5, t), Vector2.UP, 0.5, t)
	assert_float(one).is_equal_approx(two, 0.0001)


func test_a_surgelight_excess_eases_back_to_the_cap() -> void:
	var v := Vector2(t.momentum_max_speed + 200.0, 0.0)
	for i in 60 * 3:
		v = MomentumMove.step_velocity(v, 0.0, Vector2.ZERO, DT, t)
	assert_float(v.x).is_equal_approx(t.momentum_max_speed, 1.0)


func test_reversing_swings_the_velocity_round_at_the_ease_rate() -> void:
	# flying right, stick pushed left: the hull turns (fast), then thrust swings the velocity through zero
	var h := 0.0
	var v := Vector2(t.momentum_max_speed, 0.0)
	var crossed := -1.0
	for i in 120:
		h = MomentumMove.step_heading(h, Vector2.LEFT, DT, t)
		v = MomentumMove.step_velocity(v, h, Vector2.LEFT, DT, t)
		if crossed < 0.0 and v.x <= 0.0:
			crossed = i * DT
	assert_float(crossed).override_failure_message("a full reversal passes through zero speed, it does not snap").is_between(0.15, 0.7)


# --- the real ship ---------------------------------------------------------------------------

func _world() -> ArcadeWorld:
	_game = SCENE.instantiate()
	add_child(_game)
	_game.set_process(false)
	var world: ArcadeWorld = _game.get_node("%World")
	world.paused_sim = true
	_game.start_stage(0)
	_game.dismiss_brief()
	world.paused_sim = true
	_game._on_timer()
	world.vigil.use_scripted = false
	world.vigil.input_enabled = true
	world.geodes.items.clear()
	world.grubs.items.clear()
	world.acolytes.items.clear()
	world.vigil.shield = 1000.0
	return world


func test_a_held_key_turns_then_accelerates_and_letting_go_coasts() -> void:
	var world := _world()
	var v := world.vigil
	Input.action_press(&"move_right")
	for i in 12:
		world.step(DT)
	assert_float(v.vel.length()).override_failure_message("0.2 s in, nowhere near the direct model's full speed").is_less(world.tuning.momentum_max_speed * 0.6)
	for i in 120:
		world.step(DT)
	assert_float(v.vel.x).is_greater(world.tuning.momentum_max_speed * 0.9)
	Input.action_release(&"move_right")
	var coast := v.vel
	for i in 120:
		world.step(DT)
	assert_vector(v.vel).override_failure_message("no drag, no brake").is_equal_approx(coast, Vector2(0.5, 0.5))
	# the brake action does nothing in this model (GDD §4.1 inputs are unchanged; the original has no brake)
	Input.action_press(&"brake")
	for i in 30:
		world.step(DT)
	assert_vector(v.vel).is_equal_approx(coast, Vector2(0.5, 0.5))


func test_the_direct_model_still_flies_the_old_way() -> void:
	var world := _world()
	world.tuning.move_model = CabinetTuning.MoveModel.DIRECT
	Input.action_press(&"move_right")
	for i in 12:
		world.step(DT)
	assert_float(world.vigil.vel.x).override_failure_message("accel 2600: about 340 in 0.13 s").is_greater(300.0)
	world.tuning.move_model = CabinetTuning.MoveModel.MOMENTUM


# --- the autopilot's stick (momentum) ---------------------------------------------------------

func test_the_bot_holds_by_reversing_then_letting_go() -> void:
	assert_vector(CabinetAutopilot.stick_for(Vector2.ZERO, Vector2(300, 0), true)).is_equal(Vector2.LEFT)
	assert_vector(CabinetAutopilot.stick_for(Vector2.ZERO, Vector2(10, 0), true)).is_equal(Vector2.ZERO)
	assert_vector(CabinetAutopilot.stick_for(Vector2.RIGHT, Vector2(300, 0), true)).is_equal(Vector2.RIGHT)
	# an arrival ramp too short for the stop brakes early; a dodge in the move never does
	assert_vector(CabinetAutopilot.stick_for(Vector2(0.3, 0), Vector2(300, 0), true)).is_equal(Vector2.LEFT)
	assert_vector(CabinetAutopilot.stick_for(Vector2(0.3, 0), Vector2(300, 0), false)).is_equal(Vector2(0.3, 0))


func test_the_bot_leads_its_lance_by_the_ships_drift() -> void:
	var aim := CabinetAutopilot.lead_aim(Vector2.RIGHT, Vector2(0, 340), 340.0)
	assert_float(aim.y).is_less(0.0)       # aims against the drift so the lance (which carries half the velocity) lands on the line
	assert_vector(CabinetAutopilot.lead_aim(Vector2.RIGHT, Vector2.ZERO, 340.0).normalized()).is_equal(Vector2.RIGHT)


# --- the chase (Q-T446) ----------------------------------------------------------------------

func test_the_awake_chase_is_eased_and_data_driven() -> void:
	assert_float(t.rampage_ease_rate).is_greater(0.0)
	assert_float(t.rampage_catchup_ease_rate).is_greater(0.0)
	assert_float(t.rampage_catchup_ease_rate).is_less(t.rampage_ease_rate)   # the source's far row is the lazier shift
