extends GdUnitTestSuite
## Aether handling profile (SYS-001 §1.1a): derived figures at 60 and 144 Hz, keel, thrust
## factors, lantern multipliers, Surgelight, and Cabinet isolation.

const AETHER := preload("res://data/vigil/vigil_aether_move.tres")
const RATES: Array[float] = [60.0, 144.0]


func test_top_speed_from_rest() -> void:
	for hz in RATES:
		var dt := 1.0 / hz
		var v := Vector2.ZERO
		var t := 0.0
		while v.length() < AETHER.max_speed - 0.001 and t < 5.0:
			v = VigilMotor.step_aether(v, Vector2.RIGHT, false, 0.0, true, dt, AETHER)
			t += dt
		assert_float(t).is_equal_approx(0.39, 0.03)


func test_straight_line_reversal() -> void:
	for hz in RATES:
		var dt := 1.0 / hz
		var v := Vector2(AETHER.max_speed, 0.0)
		var t := 0.0
		# Keel already pointing the new way (factor 1): the derived 2*v/accel straight line.
		while v.x > -AETHER.max_speed + 0.001 and t < 5.0:
			v = VigilMotor.step_aether(v, Vector2.LEFT, false, PI, true, dt, AETHER)
			t += dt
		assert_float(t).is_equal_approx(0.79, 0.03)


func test_coast_distance() -> void:
	for hz in RATES:
		var dt := 1.0 / hz
		var v := Vector2(AETHER.max_speed, 0.0)
		var d := 0.0
		for i in roundi(20.0 * hz):
			v = VigilMotor.step_aether(v, Vector2.ZERO, false, 0.0, true, dt, AETHER)
			d += v.x * dt
		assert_float(d).is_equal_approx(245.0, 6.0)


func test_brake_stop() -> void:
	for hz in RATES:
		var dt := 1.0 / hz
		var v := Vector2(AETHER.max_speed, 0.0)
		var t := 0.0
		while v != Vector2.ZERO and t < 5.0:
			v = VigilMotor.step_aether(v, Vector2.ZERO, true, 0.0, true, dt, AETHER)
			t += dt
		assert_float(t).is_equal_approx(0.31, 0.03)


func test_keel_swing_180_takes_one_second() -> void:
	for hz in RATES:
		var dt := 1.0 / hz
		var h := 0.0
		var t := 0.0
		while absf(wrapf(PI - h, -PI, PI)) > 0.0001 and t < 5.0:
			h = VigilMotor.step_heading(h, Vector2.LEFT, dt, AETHER)
			t += dt
		assert_float(t).is_equal_approx(1.0, 0.02)


func test_heading_holds_without_input() -> void:
	assert_float(VigilMotor.step_heading(1.0, Vector2.ZERO, 0.1, AETHER)).is_equal(1.0)


func test_thrust_factors() -> void:
	assert_float(VigilMotor.thrust_factor(Vector2.RIGHT, 0.0, AETHER)).is_equal_approx(1.0, 0.0001)
	assert_float(VigilMotor.thrust_factor(Vector2.DOWN, 0.0, AETHER)).is_equal_approx(AETHER.thrust_lateral, 0.0001)
	assert_float(VigilMotor.thrust_factor(Vector2.LEFT, 0.0, AETHER)).is_equal_approx(AETHER.thrust_reverse, 0.0001)
	var between := VigilMotor.thrust_factor(Vector2.from_angle(PI / 4.0), 0.0, AETHER)
	assert_float(between).is_greater(AETHER.thrust_lateral)
	assert_float(between).is_less(1.0)


func test_lantern_down_multipliers() -> void:
	var up := VigilMotor.step_aether(Vector2.ZERO, Vector2.RIGHT, false, 0.0, true, 0.1, AETHER)
	var down := VigilMotor.step_aether(Vector2.ZERO, Vector2.RIGHT, false, 0.0, false, 0.1, AETHER)
	assert_float(down.x / up.x).is_equal_approx(AETHER.lantern_down_thrust, 0.0001)
	var c_up := VigilMotor.step_aether(Vector2(100, 0), Vector2.ZERO, false, 0.0, true, 0.5, AETHER)
	var c_down := VigilMotor.step_aether(Vector2(100, 0), Vector2.ZERO, false, 0.0, false, 0.5, AETHER)
	assert_float(c_up.x).is_equal_approx(100.0 * exp(-AETHER.drag * 0.5), 0.001)
	assert_float(c_down.x).is_equal_approx(100.0 * exp(-AETHER.drag * AETHER.lantern_down_drag * 0.5), 0.001)


func _motor() -> VigilMotor:
	var m := VigilMotor.new()
	m.aether_stats = AETHER
	m.reset_surge()
	return auto_free(m)


func test_surge_exceeds_max_then_returns() -> void:
	var m := _motor()
	var dt := 1.0 / 60.0
	var v := Vector2(AETHER.max_speed, 0.0)
	v = m.tick_aether(v, Vector2.RIGHT, false, true, true, dt)
	assert_bool(m.surging).is_true()
	assert_float(v.x).is_greater(AETHER.max_speed)
	assert_int(m.surge_charges_left).is_equal(0)
	var peak := v.x
	for i in 900:
		v = m.tick_aether(v, Vector2.RIGHT, false, false, true, dt)
		peak = maxf(peak, v.x)
	assert_float(peak).is_equal_approx(AETHER.max_speed + AETHER.surge_impulse, 1.0)
	assert_bool(m.surging).is_false()
	assert_float(v.x).is_equal_approx(AETHER.max_speed, 0.5)


func test_surge_without_input_uses_hull_heading_and_recharges() -> void:
	var m := _motor()
	m.hull_heading = PI / 2.0
	var v := m.tick_aether(Vector2.ZERO, Vector2.ZERO, false, true, true, 1.0 / 60.0)
	assert_float(v.y).is_equal_approx(AETHER.surge_impulse, 0.01)
	assert_int(m.surge_charges_left).is_equal(0)
	for i in roundi(AETHER.surge_cooldown * 60.0) + 2:
		m.tick_aether(Vector2.ZERO, Vector2.ZERO, false, false, true, 1.0 / 60.0)
	assert_int(m.surge_charges_left).is_equal(1)


func test_no_second_surge_without_charge() -> void:
	var m := _motor()
	for i in 30:
		m.tick_aether(Vector2.ZERO, Vector2.RIGHT, false, i == 0 or i == 20, true, 1.0 / 60.0)
	assert_int(m.surge_charges_left).is_equal(0)
	assert_bool(m.surging).is_false()


func test_enabled_false_is_cabinet() -> void:
	var disabled := AETHER.duplicate() as VigilAetherStats
	disabled.enabled = false
	var m := VigilMotor.new()
	auto_free(m)
	assert_bool(m.aether_active).is_false()
	m.aether_stats = disabled
	assert_bool(m.aether_active).is_false()
	m.aether_stats = AETHER
	assert_bool(m.aether_active).is_true()


func test_exposed_state() -> void:
	var m := _motor()
	var v := m.tick_aether(Vector2.ZERO, Vector2.RIGHT, false, false, true, 0.1)
	assert_float(m.last_accel.x).is_equal_approx(v.x / 0.1, 0.01)
	assert_float(m.thrust_amount).is_greater(0.0)
	m.tick_aether(v, Vector2.ZERO, true, false, true, 0.1)
	assert_bool(m.braking).is_true()
	assert_float(m.thrust_amount).is_equal(0.0)
