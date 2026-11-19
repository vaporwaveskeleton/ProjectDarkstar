extends GdUnitTestSuite
## M1 sandbox torus (Q-T58): one arena size source (the Cabinet's field), Vigil wrap after its
## physics step with velocity kept, camera continuity through the seam, shortest-delta follow,
## shots kept on the Vigil's image, near depth (no grid, Q-T163) continuous across the seam.

const SCENE := "res://scenes/sector/sector_stub.tscn"
const CAM_STATS := preload("res://data/sector/sector_camera.tres")
const DEPTH_BACK := preload("res://data/sector/sector_depth_back.tres")
const DEPTH_FRONT := preload("res://data/sector/sector_depth_front.tres")
const STAGES := ["res://data/cabinet/stage_first_vigil.tres", "res://data/cabinet/stage_last_normal_day.tres"]


func after_test() -> void:
	get_tree().paused = false


func _vigil(runner: GdUnitSceneRunner) -> Vigil:
	var v: Vigil = runner.get_property("vigil")
	v.input.read_devices = false
	return v


# --- one source ----------------------------------------------------------------------------------

func test_arena_is_the_cabinet_field_size() -> void:
	var runner := scene_runner(SCENE)
	await runner.simulate_frames(1)
	var t: Torus = runner.get_property("torus")
	assert_object(t).is_not_null()
	for path: String in STAGES:
		assert_vector(t.size).is_equal((load(path) as CabinetStage).field_size)
	assert_vector(t.size).is_equal(CabinetStage.new().field_size)
	assert_vector(t.size).is_equal(Vector2(1920, 720))   # SYS-001 §9 sandbox row (✱)
	var compass: LedgerCompass = runner.find_child("LedgerCompass")
	assert_object(compass.world_rect).is_equal(Rect2(Vector2.ZERO, t.size))


func test_torus_is_injected_everywhere() -> void:
	var runner := scene_runner(SCENE)
	await runner.simulate_frames(1)
	var t: Torus = runner.get_property("torus")
	var cam: SectorCamera = runner.find_child("SectorCamera")
	var wrap: SectorWrap = runner.find_child("SectorWrap")
	assert_object(cam.torus).is_same(t)
	assert_object(wrap.torus).is_same(t)
	assert_object(wrap.anchor).is_same(runner.get_property("vigil"))
	assert_object(runner.find_child("Walls")).is_null()


# --- wrap ----------------------------------------------------------------------------------------

func test_vigil_wraps_after_its_physics_step_and_keeps_velocity() -> void:
	var runner := scene_runner(SCENE)
	await runner.simulate_frames(1)
	var v := _vigil(runner)
	var t: Torus = runner.get_property("torus")
	v.global_position = Vector2(t.size.x - 2.0, 100.0)
	v.velocity = Vector2(v.motor.stats.max_speed, 0.0)
	v.input.move_dir = Vector2.RIGHT
	(runner.find_child("SectorCamera") as SectorCamera).snap_to_target()
	var crossed := false
	for i in 10:
		await get_tree().physics_frame
		assert_float(v.global_position.x).is_between(0.0, t.size.x)
		if v.global_position.x < 100.0:
			crossed = true
	assert_bool(crossed).is_true()
	assert_float(v.velocity.x).is_greater(v.motor.stats.max_speed * 0.9)
	assert_float(v.velocity.y).is_equal_approx(0.0, 0.01)


func test_vertical_wrap_from_the_top() -> void:
	var runner := scene_runner(SCENE)
	await runner.simulate_frames(1)
	var v := _vigil(runner)
	var t: Torus = runner.get_property("torus")
	v.global_position = Vector2(300.0, 1.0)
	v.velocity = Vector2(0.0, -v.motor.stats.max_speed)
	v.input.move_dir = Vector2.UP
	for i in 4:
		await get_tree().physics_frame
	assert_float(v.global_position.y).is_greater(t.size.y - 40.0)
	assert_float(v.global_position.y).is_less(t.size.y)
	assert_float(v.velocity.y).is_less(0.0)


func test_nearest_image_and_wrap_actors() -> void:
	var t := Torus.new(Vector2(1920, 720))
	assert_vector(SectorWrap.nearest_image(t, Vector2(1915, 10), Vector2(5, 10))).is_equal(Vector2(-5, 10))
	assert_vector(SectorWrap.nearest_image(t, Vector2(5, 700), Vector2(5, 10))).is_equal(Vector2(5, -20))
	var actors: Node2D = auto_free(Node2D.new())
	add_child(actors)
	var anchor := Node2D.new()
	var shot := Node2D.new()
	actors.add_child(anchor)
	actors.add_child(shot)
	anchor.global_position = Vector2(1925, 10)    # just crossed the seam
	shot.global_position = Vector2(1935, 10)      # flying ahead of it
	var w: SectorWrap = auto_free(SectorWrap.new())
	w.actors = actors
	w.torus = t
	w.anchor = anchor
	w.wrap_actors()
	assert_vector(anchor.global_position).is_equal(Vector2(5, 10))
	assert_vector(shot.global_position).is_equal(Vector2(15, 10))   # still 10 px ahead, on screen


func test_lance_shot_crosses_the_seam_and_still_expires() -> void:
	var runner := scene_runner(SCENE)
	await runner.simulate_frames(1)
	var v := _vigil(runner)
	var t: Torus = runner.get_property("torus")
	v.global_position = Vector2(t.size.x - 20.0, 200.0)
	v.velocity = Vector2.ZERO
	v.emitter.enabled = false   # fire exactly one shot by hand
	v.emitter.facing_node.global_rotation = 0.0
	var shot := v.emitter.advance(1.0, true)
	assert_object(shot).is_not_null()
	var start_gap := t.delta(v.global_position, shot.global_position).x
	var frames := ceili(shot.stats.lifetime_s * Engine.physics_ticks_per_second) + 3
	var seen_gap: Array[float] = []
	for i in frames:
		await get_tree().physics_frame
		if is_instance_valid(shot):
			var d := shot.global_position - v.global_position   # plain difference: same image
			assert_float(absf(d.y)).is_less(1.0)
			seen_gap.append(d.x)
	assert_bool(seen_gap.size() > 10).is_true()
	assert_float(seen_gap[0]).is_greater(start_gap - 1.0)
	for i in range(1, seen_gap.size()):
		assert_float(seen_gap[i]).is_greater(seen_gap[i - 1])   # monotonic: no jump at the seam
	assert_bool(is_instance_valid(shot)).is_false()


# --- camera --------------------------------------------------------------------------------------

func test_camera_view_is_continuous_through_the_seam() -> void:
	var runner := scene_runner(SCENE)
	await runner.simulate_frames(1)
	var v := _vigil(runner)
	var t: Torus = runner.get_property("torus")
	var cam: SectorCamera = runner.find_child("SectorCamera")
	v.global_position = Vector2(t.size.x - 150.0, t.size.y - 100.0)
	cam.snap_to_target()
	v.input.move_dir = Vector2(1, 1).normalized()
	var prev_screen := v.global_position - cam.global_position
	var max_step := 0.0
	var wrapped_x := false
	var wrapped_y := false
	for i in 90:
		await get_tree().physics_frame
		var screen := v.global_position - cam.global_position   # where the Vigil sits on screen
		max_step = maxf(max_step, (screen - prev_screen).length())
		prev_screen = screen
		wrapped_x = wrapped_x or v.global_position.x < 200.0
		wrapped_y = wrapped_y or v.global_position.y < 200.0
		assert_float(screen.length()).is_less(100.0)
	assert_bool(wrapped_x and wrapped_y).is_true()
	# 340 px/s is under 6 px a tick; a seam jump would be hundreds of px.
	assert_float(max_step).is_less(12.0)


func test_deadzone_and_follow_use_the_shortest_delta() -> void:
	var t := Torus.new(Vector2(1920, 720))
	var target: Node2D = auto_free(Node2D.new())
	add_child(target)
	target.global_position = Vector2(1910, 360)
	var cam: SectorCamera = auto_free(SectorCamera.new())
	cam.stats = CAM_STATS
	cam.target = target
	cam.torus = t
	add_child(cam)
	cam.set_physics_process(false)
	cam.snap_to_target()
	target.global_position = Vector2(40, 360)   # wrapped: 50 px to the right across the seam
	cam.step(1.0 / 60.0)
	# Focus was rebased to the target's image, then dragged by the deadzone only (not 1870 px).
	assert_float(t.distance(cam.focus, target.global_position)).is_equal_approx(CAM_STATS.deadzone_px, 0.01)
	assert_float(cam.focus.x).is_between(0.0, 40.0)
	assert_float(target.global_position.x - cam.global_position.x).is_between(0.0, 60.0)
	for i in 120:
		cam.step(1.0 / 60.0)
	assert_float(cam.global_position.x).is_equal_approx(40.0 - CAM_STATS.deadzone_px, 0.1)


func test_rebase_shifts_focus_and_position_but_not_velocity() -> void:
	var t := Torus.new(Vector2(1920, 720))
	var cam: SectorCamera = auto_free(SectorCamera.new())
	cam.stats = CAM_STATS
	cam.torus = t
	add_child(cam)
	cam.set_physics_process(false)
	cam.focus = Vector2(1915, 700)
	cam.global_position = Vector2(1918, 702)
	cam.follow_velocity = Vector2(300, 100)
	var shift := cam.rebase_to(Vector2(3, 5))
	assert_vector(shift).is_equal(Vector2(-1920, -720))
	assert_vector(cam.focus).is_equal(Vector2(-5, -20))
	assert_vector(cam.global_position).is_equal(Vector2(-2, -18))
	assert_vector(cam.follow_velocity).is_equal(Vector2(300, 100))
	assert_vector(cam.rebase_to(Vector2(3, 5))).is_equal(Vector2.ZERO)


# --- near depth (Q-T163: no grid in the Aether) ---------------------------------------------------

func test_depth_styles_are_palette_and_well_formed() -> void:
	for st: SectorDepthStyle in [DEPTH_BACK, DEPTH_FRONT]:
		assert_int(st.layer_count()).is_greater(0)
		for i in st.layer_count():
			assert_float(st.cell_px[i]).is_greater(0.0)
			var c := st.colour[i]
			var known: Array = Pal.ALL.values() + Pal.AETHER.values()   # AETHER: post-Pretence ramp
			assert_bool(known.any(func(p: Color) -> bool: return p.is_equal_approx(c))).is_true()
	# behind the play layer the far motes move slower than the world; in front, faster
	for p in DEPTH_BACK.parallax:
		assert_float(p).is_less(1.0)
	for p in DEPTH_FRONT.parallax:
		assert_float(p).is_greater(1.0)


func test_sector_has_no_grid_and_depth_follows_the_continuous_centre() -> void:
	var runner := scene_runner(SCENE)
	await runner.simulate_frames(1)
	var sector: Node = runner.scene()
	assert_object(sector.find_child("Floor")).is_null()
	var back: SectorDepth = runner.find_child("DepthBack")
	var front: SectorDepth = runner.find_child("DepthFront")
	assert_int((back.get_parent() as CanvasLayer).layer).is_less(0)
	assert_int((front.get_parent() as CanvasLayer).layer).is_greater(0)
	var v := _vigil(runner)
	var t: Torus = runner.get_property("torus")
	var cam: SectorCamera = runner.find_child("SectorCamera")
	# cross the seam: the depth centre is the far layer's continuous one, so it never jumps a field
	var before: Vector2 = back.camera_centre
	v.global_position = Vector2(t.size.x - 2.0, 180.0)
	cam.snap_to_target()
	await runner.simulate_frames(2)
	v.global_position = Vector2(t.size.x + 6.0, 180.0)
	await runner.simulate_frames(2)
	assert_vector(back.camera_centre).is_equal(sector.far_centre)
	assert_vector(front.camera_centre).is_equal(sector.far_centre)
	assert_bool(back.draw_count > 0).is_true()
	assert_float(absf(back.camera_centre.x - before.x)).is_less(t.size.x * 0.5)


func test_depth_layer_offset_and_hash_are_deterministic() -> void:
	assert_vector(SectorDepth.layer_offset(Vector2(100, 50), 0.5, Vector2.ZERO)).is_equal(Vector2(-50, -25))
	assert_float(SectorDepth.cell_hash(3, -4, 1, 2)).is_equal(SectorDepth.cell_hash(3, -4, 1, 2))
	var h := SectorDepth.cell_hash(-7, 9, 0, 1)
	assert_bool(h >= 0.0 and h < 1.0).is_true()
