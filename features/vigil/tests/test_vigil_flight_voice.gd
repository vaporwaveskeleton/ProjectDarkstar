extends GdUnitTestSuite
## VigilFlightVoice (AUDIO-001 §12.19, TECH-001 Q-T42): pushes the Vigil's motion as fractions of its own
## VigilMoveStats, only on change, and stops the ship's sound on hull loss and exit.

const SCENE := preload("res://features/vigil/vigil.tscn")


class Spy:
	extends RefCounted
	var pushes: Array = []
	var stops := 0

	func set_flight(speed01: float, thrust01: float, turn01: float, braking: bool) -> void:
		pushes.append([speed01, thrust01, turn01, braking])

	func stop_flight() -> void:
		stops += 1


func _make() -> Array:
	var v := SCENE.instantiate() as Vigil
	add_child(v)
	auto_free(v)
	v.motor.enabled = false
	v.input.set_physics_process(false)
	v.input.set_process(false)
	var voice := VigilFlightVoice.new()
	voice.vigil = v
	var spy := Spy.new()
	voice.sink = spy
	v.add_child(voice)
	voice.set_physics_process(false)
	return [v, voice, spy]


func test_pushes_speed_and_thrust_as_fractions() -> void:
	var made := _make()
	var v: Vigil = made[0]
	var voice: VigilFlightVoice = made[1]
	var spy: Spy = made[2]
	v.velocity = Vector2(v.motor.stats.max_speed * 0.5, 0.0)
	v.input.move_dir = Vector2(1.0, 0.0)
	v.input.braking = false
	voice._physics_process(1.0 / 60.0)
	assert_int(spy.pushes.size()).is_equal(1)
	var p: Array = spy.pushes[0]
	assert_float(float(p[0])).is_equal_approx(0.5, 0.001)
	assert_float(float(p[1])).is_equal(1.0)
	assert_bool(bool(p[3])).is_false()


func test_braking_zeroes_thrust_and_no_change_means_no_push() -> void:
	var made := _make()
	var v: Vigil = made[0]
	var voice: VigilFlightVoice = made[1]
	var spy: Spy = made[2]
	v.velocity = Vector2(0.0, v.motor.stats.max_speed)
	v.input.move_dir = Vector2(0.0, 1.0)
	v.input.braking = true
	voice._physics_process(1.0 / 60.0)
	voice._physics_process(1.0 / 60.0)   # nothing moved: no second push
	assert_int(spy.pushes.size()).is_equal(1)
	var p: Array = spy.pushes[0]
	assert_float(float(p[1])).is_equal(0.0)
	assert_bool(bool(p[3])).is_true()


func test_turn_rate_is_a_fraction_of_snap_turn() -> void:
	var made := _make()
	var v: Vigil = made[0]
	var voice: VigilFlightVoice = made[1]
	var spy: Spy = made[2]
	var dt := 1.0 / 60.0
	v.motor.facing_node.rotation = 0.0
	voice._physics_process(dt)
	v.motor.facing_node.rotation = deg_to_rad(v.motor.stats.snap_turn) * dt * 0.5   # half the max rate
	voice._physics_process(dt)
	var p: Array = spy.pushes[spy.pushes.size() - 1]
	assert_float(float(p[2])).is_equal_approx(0.5, 0.01)


func test_hull_loss_stops_the_ship_sound() -> void:
	var made := _make()
	var v: Vigil = made[0]
	var voice: VigilFlightVoice = made[1]
	var spy: Spy = made[2]
	v.hull_breached.emit()
	assert_int(spy.stops).is_greater_equal(1)
	var before := spy.pushes.size()
	v.velocity = Vector2(100.0, 0.0)
	voice._physics_process(1.0 / 60.0)
	assert_int(spy.pushes.size()).is_equal(before)   # a dead ship is silent
