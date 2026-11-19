extends GdUnitTestSuite
## Sector camera: SYS-001 §9 values in data, deadzone, damping convergence, lookahead, shake cap,
## reduced motion (D-3). SettingsService never persists here.

const STATS := preload("res://data/sector/sector_camera.tres")

var _prev_persist: bool
var _prev_rm: bool


func before_test() -> void:
	_prev_persist = SettingsService.persist
	SettingsService.persist = false
	_prev_rm = bool(SettingsService.get_value(&"reduced_motion"))
	SettingsService.set_value(&"reduced_motion", false)


func after_test() -> void:
	SettingsService.set_value(&"reduced_motion", _prev_rm)
	SettingsService.persist = _prev_persist


func _camera(target: Node2D) -> SectorCamera:
	var cam: SectorCamera = auto_free(SectorCamera.new())
	cam.stats = STATS
	cam.target = target
	add_child(cam)
	cam.set_physics_process(false)
	return cam


func _target(at: Vector2) -> Node2D:
	var t: Node2D = auto_free(Node2D.new())
	add_child(t)
	t.global_position = at
	return t


func test_data_matches_sys001_section_9() -> void:
	assert_str(STATS.ds_namespace).is_equal("ds_camera")
	assert_float(STATS.follow_time_s).is_equal_approx(0.12, 1e-6)
	assert_float(STATS.deadzone_px).is_equal_approx(24.0, 1e-6)
	assert_float(STATS.aim_lookahead_frac).is_equal_approx(0.015, 1e-6)
	assert_float(STATS.shake_max_px).is_equal_approx(4.0, 1e-6)
	assert_float(STATS.shake_max_s).is_equal_approx(0.25, 1e-6)
	assert_float(STATS.zoom).is_equal_approx(1.0, 1e-6)
	assert_bool(STATS.shake_off_under_reduced_motion).is_true()


func test_deadzone_holds_inside_and_drags_outside() -> void:
	var f := Vector2(100, 100)
	assert_vector(SectorCamera.apply_deadzone(f, f + Vector2(23.9, 0), 24.0)).is_equal(f)
	assert_vector(SectorCamera.apply_deadzone(f, f + Vector2(0, -24), 24.0)).is_equal(f)
	var moved := SectorCamera.apply_deadzone(f, f + Vector2(30, 40), 24.0)   # 50 px away
	assert_float(moved.distance_to(f + Vector2(30, 40))).is_equal_approx(24.0, 1e-4)
	assert_float((moved - f).normalized().dot(Vector2(0.6, 0.8))).is_equal_approx(1.0, 1e-4)


func test_spring_converges_without_overshoot() -> void:
	var omega := SectorCamera.omega_for(STATS.follow_time_s)
	var pos := Vector2.ZERO
	var vel := Vector2.ZERO
	var goal := Vector2(100, 0)
	var max_x := 0.0
	var at_t: float = -1.0
	for i in 100:   # 1 s at dt = 0.01 s
		var r := SectorCamera.spring_step(pos, vel, goal, omega, 0.01)
		pos = r[0]
		vel = r[1]
		max_x = maxf(max_x, pos.x)
		if i == 11:   # t = 0.12 s
			at_t = pos.x
	# critically damped: never overshoots; at T = 0.12 s it has covered 1 - 3e^-2 ≈ 59 %
	assert_float(max_x).is_less_equal(100.0 + 1e-3)
	assert_float(at_t).is_equal_approx(100.0 * (1.0 - 3.0 * exp(-2.0)), 0.5)
	assert_float(pos.x).is_equal_approx(100.0, 0.01)


func test_spring_is_frame_rate_independent() -> void:
	var omega := SectorCamera.omega_for(STATS.follow_time_s)
	var a: Array[Vector2] = [Vector2.ZERO, Vector2.ZERO]
	var b: Array[Vector2] = [Vector2.ZERO, Vector2.ZERO]
	for i in 30:
		a = SectorCamera.spring_step(a[0], a[1], Vector2(64, -32), omega, 1.0 / 30.0)
	for i in 144:
		b = SectorCamera.spring_step(b[0], b[1], Vector2(64, -32), omega, 1.0 / 144.0)
	assert_float(a[0].distance_to(b[0])).is_less(0.01)


func test_lookahead_is_fraction_of_view_along_aim() -> void:
	var view := Vector2(640, 360)
	assert_vector(SectorCamera.lookahead(Vector2.RIGHT, view, 0.015)).is_equal_approx(Vector2(9.6, 0), Vector2(1e-4, 1e-4))
	assert_vector(SectorCamera.lookahead(Vector2(0, -2), view, 0.015)).is_equal_approx(Vector2(0, -5.4), Vector2(1e-4, 1e-4))
	assert_vector(SectorCamera.lookahead(Vector2.ZERO, view, 0.015)).is_equal(Vector2.ZERO)


func test_camera_follows_target_out_of_deadzone() -> void:
	var t := _target(Vector2(320, 180))
	var cam := _camera(t)
	assert_vector(cam.global_position).is_equal(Vector2(320, 180))
	t.global_position = Vector2(330, 180)   # inside the deadzone
	for i in 60:
		cam.step(1.0 / 60.0)
	assert_vector(cam.global_position).is_equal_approx(Vector2(320, 180), Vector2(0.01, 0.01))
	t.global_position = Vector2(420, 180)   # 100 px: camera settles 24 px behind
	for i in 120:
		cam.step(1.0 / 60.0)
	assert_float(cam.global_position.x).is_equal_approx(396.0, 0.05)


func test_shake_is_capped_and_ends_within_ceiling() -> void:
	var cam := _camera(_target(Vector2.ZERO))
	assert_bool(cam.shake(40.0, 3.0)).is_true()
	var frames := 0
	var biggest := 0.0
	while cam.is_shaking() and frames < 600:
		cam.step(1.0 / 60.0)
		biggest = maxf(biggest, cam.offset.length())
		frames += 1
	assert_float(biggest).is_less_equal(4.0 + 1e-4)
	assert_float(biggest).is_greater(0.0)
	assert_int(frames).is_less_equal(int(ceil(0.25 * 60.0)) + 1)
	cam.step(1.0 / 60.0)
	assert_vector(cam.offset).is_equal(Vector2.ZERO)


func test_overlapping_shakes_never_sum() -> void:
	var cam := _camera(_target(Vector2.ZERO))
	cam.shake(4.0, 0.25)
	cam.shake(2.0, 0.20)   # warp-sized shake inside the ceiling
	for i in 20:
		cam.step(1.0 / 60.0)
		assert_float(cam.offset.length()).is_less_equal(4.0 + 1e-4)


func test_reduced_motion_suppresses_shake() -> void:
	var cam := _camera(_target(Vector2.ZERO))
	SettingsService.set_value(&"reduced_motion", true)
	assert_bool(cam.shake(4.0, 0.25)).is_false()
	cam.step(1.0 / 60.0)
	assert_vector(cam.offset).is_equal(Vector2.ZERO)


func test_reduced_motion_mid_shake_stops_it() -> void:
	var cam := _camera(_target(Vector2.ZERO))
	cam.shake(4.0, 0.25)
	cam.step(1.0 / 60.0)
	SettingsService.set_value(&"reduced_motion", true)
	cam.step(1.0 / 60.0)
	assert_vector(cam.offset).is_equal(Vector2.ZERO)
	assert_bool(cam.is_shaking()).is_false()


func test_zoom_is_fixed_at_data_value() -> void:
	var cam := _camera(_target(Vector2.ZERO))
	assert_vector(cam.zoom).is_equal(Vector2.ONE)
