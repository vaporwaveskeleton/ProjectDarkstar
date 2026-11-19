extends GdUnitTestSuite
## Vigil in the physics world: walls (built by the test; the sandbox itself wraps) stop it (no tunnelling, even far above max speed), overlap
## recovery, hurtbox overlap with a live hitbox lands exactly one hit per window, hull breach.

const SCENE := "res://scenes/sector/sector_stub.tscn"


func after_test() -> void:
	get_tree().paused = false


func _vigil(runner: GdUnitSceneRunner) -> Vigil:
	var v: Vigil = runner.get_property("vigil")
	v.input.read_devices = false
	return v


func _radius(v: Vigil) -> float:
	return v.motor.stats.hitbox_circle_px * 0.5


## The sandbox is a wrapping torus with no boundary walls (Q-T58), so wall tests build the old
## 640×360 frame of WORLD-layer walls themselves (the same shapes the stub used to carry).
func _add_frame_walls(runner: GdUnitSceneRunner) -> void:
	var walls := StaticBody2D.new()
	walls.collision_layer = PhysicsLayers.bit(PhysicsLayers.WORLD)
	walls.collision_mask = 0
	for spec: Array in [[Vector2(320, -16), Vector2(704, 32)], [Vector2(320, 376), Vector2(704, 32)],
			[Vector2(-16, 180), Vector2(32, 424)], [Vector2(656, 180), Vector2(32, 424)]]:
		var cs := CollisionShape2D.new()
		var rect := RectangleShape2D.new()
		rect.size = spec[1]
		cs.shape = rect
		cs.position = spec[0]
		walls.add_child(cs)
	runner.scene().add_child(walls)


func test_collision_radius_comes_from_data() -> void:
	var runner := scene_runner(SCENE)
	await runner.simulate_frames(1)
	var v := _vigil(runner)
	assert_float((v.find_child("BodyShape") as CollisionShape2D).shape.radius).is_equal(_radius(v))
	assert_float((v.find_child("HurtShape") as CollisionShape2D).shape.radius).is_equal(_radius(v))


func test_wall_stops_vigil_at_max_speed() -> void:
	var runner := scene_runner(SCENE)
	await runner.simulate_frames(1)
	_add_frame_walls(runner)
	await get_tree().physics_frame
	var v := _vigil(runner)
	v.input.move_dir = Vector2.RIGHT
	for i in 120:
		await get_tree().physics_frame
	assert_float(v.global_position.x).is_less_equal(640.0 - _radius(v) + 0.5)
	assert_float(v.global_position.x).is_greater(600.0)


func test_no_tunnelling_far_above_max_speed() -> void:
	var runner := scene_runner(SCENE)
	await runner.simulate_frames(1)
	_add_frame_walls(runner)
	await get_tree().physics_frame
	var v := _vigil(runner)
	var fast: VigilMoveStats = v.motor.stats.duplicate()
	fast.max_speed = 6000.0   # 100 px per tick vs a 32 px wall
	fast.accel = 1_000_000.0
	v.motor.stats = fast
	v.input.move_dir = Vector2.LEFT
	for i in 30:
		await get_tree().physics_frame
	assert_float(v.global_position.x).is_greater_equal(_radius(v) - 0.5)


func test_overlap_with_wall_recovers() -> void:
	var runner := scene_runner(SCENE)
	await runner.simulate_frames(1)
	_add_frame_walls(runner)
	await get_tree().physics_frame
	var v := _vigil(runner)
	v.global_position = Vector2(638, 180)   # embedded in the right wall
	v.input.move_dir = Vector2.LEFT
	for i in 10:
		await get_tree().physics_frame
	assert_float(v.global_position.x).is_less(640.0 - _radius(v))


func test_live_hitbox_lands_one_hit_per_window_then_breaches() -> void:
	var runner := scene_runner(SCENE)
	await runner.simulate_frames(1)
	var v := _vigil(runner)
	var hull := (v.health.stats as HealthStats).duplicate() as HealthStats
	hull.max_hp = 2
	hull.invulnerable_after_hit_s = 0.0   # isolate the window rule; grace has its own test
	v.health.stats = hull
	v.health.reset()
	var breached := [false]
	v.hull_breached.connect(func(): breached[0] = true)
	var hb := HitboxComponent.new()
	hb.collision_layer = 0
	hb.collision_mask = PhysicsLayers.bit(PhysicsLayers.VIGIL_HURTBOX)
	var shape := CollisionShape2D.new()
	var circle := CircleShape2D.new()
	circle.radius = 8.0
	shape.shape = circle
	hb.add_child(shape)
	hb.global_position = v.global_position
	runner.scene().add_child(hb)
	hb.open_window()
	for i in 10:
		await get_tree().physics_frame
	assert_int(v.health.current_hp).is_equal(1)
	hb.close_window()
	await get_tree().physics_frame
	hb.open_window()
	for i in 5:
		await get_tree().physics_frame
	assert_int(v.health.current_hp).is_equal(0)
	assert_bool(breached[0]).is_true()
	assert_bool(v.motor.enabled).is_false()
	assert_str((runner.find_child("HullLabel") as Label).text).is_equal("Hull breached")
	hb.queue_free()


func test_plating_grace_blocks_a_second_window_then_expires() -> void:
	# SYS-001 §1.2 Post-hit grace: only relevant while Hull HP >= 2 (plating).
	var runner := scene_runner(SCENE)
	await runner.simulate_frames(1)
	var v := _vigil(runner)
	var hull := (v.health.stats as HealthStats).duplicate() as HealthStats
	hull.max_hp = 3
	v.health.stats = hull
	v.health.reset()
	assert_float(hull.invulnerable_after_hit_s).is_greater(0.0)
	v.health.apply_hit(HitInfo.make(1, 1, 1))
	assert_bool(v.health.apply_hit(HitInfo.make(1, 2, 1))).is_false()   # inside grace
	var ticks := ceili(hull.invulnerable_after_hit_s * Engine.physics_ticks_per_second) + 2
	for i in ticks:
		await get_tree().physics_frame
	assert_bool(v.health.apply_hit(HitInfo.make(1, 2, 1))).is_true()
	assert_int(v.health.current_hp).is_equal(1)
