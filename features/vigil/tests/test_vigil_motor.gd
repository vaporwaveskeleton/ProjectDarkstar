extends GdUnitTestSuite
## VigilMotor pure-step tests: speed cap, drag, brake, frame-rate independence, reversal, turn rate.
## Values come from data/vigil/vigil_move.tres — the test never restates SYS-001 numbers except
## the 🔒 derived "full reversal 0.28 s" it exists to check.

const STATS := preload("res://data/vigil/vigil_move.tres")
const FULL_REVERSAL_S := 0.28        ## SYS-001 §1.1 🔒 derived
const REVERSAL_TOLERANCE_S := 0.03   ## ✱


func _simulate(v: Vector2, dir: Vector2, braking: bool, seconds: float, hz: float) -> Vector2:
	var dt := 1.0 / hz
	for i in roundi(seconds * hz):
		v = VigilMotor.step_velocity(v, dir, braking, dt, STATS)
	return v


func test_speed_never_exceeds_max() -> void:
	var v := _simulate(Vector2.ZERO, Vector2.RIGHT, false, 2.0, 60.0)
	assert_float(v.length()).is_equal_approx(STATS.max_speed, 0.001)
	var diag := _simulate(Vector2.ZERO, Vector2(1, 1).normalized(), false, 2.0, 60.0)
	assert_float(diag.length()).is_less_equal(STATS.max_speed + 0.001)


func test_coasting_decays_with_drag() -> void:
	var v := _simulate(Vector2(STATS.max_speed, 0), Vector2.ZERO, false, 1.0, 60.0)
	assert_float(v.x).is_equal_approx(STATS.max_speed * exp(-STATS.drag), 0.01)


func test_brake_stops_without_reversing() -> void:
	var v := _simulate(Vector2(STATS.max_speed, 0), Vector2.ZERO, true, 1.0, 60.0)
	assert_vector(v).is_equal(Vector2.ZERO)


func test_frame_rate_independence_30_60_144() -> void:
	var results: Array[Vector2] = []
	for hz in [30.0, 60.0, 144.0]:
		# durations are whole tick counts at every rate (1/6 s = 5, 10, 24 ticks)
		var v := _simulate(Vector2.ZERO, Vector2.RIGHT, false, 1.0 / 6.0, hz)   # accelerate to cap
		v = _simulate(v, Vector2.ZERO, false, 0.5, hz)                           # coast		results.append(v)
	for r in results:
		assert_float(r.x).is_equal_approx(results[1].x, results[1].x * 0.02)


func test_full_reversal_time_matches_design() -> void:
	var dt := 1.0 / 240.0
	var v := Vector2(STATS.max_speed, 0)
	var t := 0.0
	while v.x > -STATS.max_speed + 0.5 and t < 2.0:
		v = VigilMotor.step_velocity(v, Vector2.LEFT, false, dt, STATS)
		t += dt
	assert_float(t).is_equal_approx(FULL_REVERSAL_S, REVERSAL_TOLERANCE_S)


func test_turn_rate_is_limited() -> void:
	var r := VigilMotor.step_facing(0.0, PI, 1.0 / 60.0, STATS)
	assert_float(absf(r)).is_equal_approx(deg_to_rad(STATS.snap_turn) / 60.0, 0.0001)
	# small differences snap exactly
	assert_float(VigilMotor.step_facing(0.0, 0.01, 1.0 / 60.0, STATS)).is_equal_approx(0.01, 0.00001)


func test_turn_takes_shortest_path_across_pi() -> void:
	var r := VigilMotor.step_facing(PI - 0.05, -PI + 0.05, 1.0 / 60.0, STATS)
	assert_float(r).is_greater(PI - 0.05)
