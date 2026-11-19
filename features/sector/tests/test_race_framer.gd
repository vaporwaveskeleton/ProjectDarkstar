extends GdUnitTestSuite
## Race framing (Reviewer rank 6): the camera leans toward the race without zoom (Q-T25 Z1), never so
## far that the Vigil leaves the screen, and the sector's race points put the Charge and the
## Sepulchre in one frame.

const SCENE := "res://scenes/sector/sector_stub.tscn"
const STATS := preload("res://data/sector/sector_camera.tres")


func test_no_race_no_lean() -> void:
	assert_vector(RaceFramer.lean_goal(PackedVector2Array(), 560.0, Vector2(100, 60))).is_equal(Vector2.ZERO)


func test_lean_is_half_the_mean_offset() -> void:
	var g := RaceFramer.lean_goal(PackedVector2Array([Vector2(100, 0), Vector2(60, 40)]), 560.0, Vector2(500, 500))
	assert_vector(g).is_equal_approx(Vector2(40, 10), Vector2(0.001, 0.001))


func test_lean_ignores_far_points_and_is_clamped() -> void:
	var far := RaceFramer.lean_goal(PackedVector2Array([Vector2(2000, 0)]), 560.0, Vector2(100, 60))
	assert_vector(far).is_equal(Vector2.ZERO)
	var big := RaceFramer.lean_goal(PackedVector2Array([Vector2(500, -300)]), 600.0, Vector2(100, 60))
	assert_vector(big).is_equal(Vector2(100, -60))


func test_the_vigil_stays_on_screen_at_full_lean() -> void:
	var half := Vector2(640, 360) * 0.5
	var lean := half * STATS.race_lean_max_frac
	assert_bool(lean.x < half.x and lean.y < half.y).is_true()
	assert_float(STATS.race_reach_px).is_greater(0.0)
	assert_float(STATS.race_lean_time_s).is_greater(0.0)


func test_a_charge_in_flight_brings_the_sepulchre_into_frame() -> void:
	var runner := scene_runner(SCENE)
	await runner.simulate_frames(2)
	var sector: Node = runner.scene()
	assert_int(sector.race_points).is_equal(0)
	var launcher: ChargeLauncher = runner.find_child("ChargeLauncher")
	var magazine: ChargeMagazine = runner.find_child("ChargeMagazine")
	var sep: Node2D = (runner.find_child("ProcessionSandbox") as ProcessionSandbox).sepulchre
	var vigil: Vigil = sector.vigil
	var t: Torus = sector.torus
	magazine.try_add(1)
	var d := t.delta(vigil.global_position, sep.global_position)
	if d.length() > STATS.race_reach_px:
		vigil.global_position = sep.global_position - d.normalized() * 420.0
		(runner.find_child("SectorCamera") as SectorCamera).snap_to_target()
		d = t.delta(vigil.global_position, sep.global_position)
	launcher.fire(vigil.global_position, d.normalized())
	assert_int(sector.race_points).is_greater_equal(2)
	await runner.simulate_frames(60)
	var framer: RaceFramer = runner.find_child("RaceFramer")
	assert_float(framer.lean.length()).is_greater(1.0)
	assert_float(framer.lean.dot(d)).is_greater(0.0)   # it leans toward the Sepulchre


# --- Q-T211 pull-out ------------------------------------------------------------------------------

func test_offscreen_helper() -> void:
	assert_bool(RaceFramer.offscreen(Vector2(330, 0), Vector2(320, 180))).is_true()
	assert_bool(RaceFramer.offscreen(Vector2(0, -190), Vector2(320, 180))).is_true()
	assert_bool(RaceFramer.offscreen(Vector2(300, 170), Vector2(320, 180))).is_false()


func test_pull_out_is_bounded_by_its_data() -> void:
	assert_float(STATS.race_pull_zoom).is_greater(0.0)
	assert_float(STATS.race_pull_zoom).is_less(STATS.zoom)   # a pull OUT, never in
	assert_float(STATS.race_pull_max_s).is_greater(0.0)


func _framer_with(target: Vector2) -> Array:
	var cam := SectorCamera.new()
	cam.stats = STATS
	var anchor := Node2D.new()
	add_child(anchor)
	add_child(cam)
	auto_free(cam)
	auto_free(anchor)
	var f := RaceFramer.new()
	f.camera = cam
	f.anchor = anchor
	f.pull_target = func() -> PackedVector2Array: return PackedVector2Array([target])
	auto_free(f)
	return [f, cam]


func test_offscreen_sepulchre_pulls_out_then_returns_after_the_cap() -> void:
	var pair := _framer_with(Vector2(900, 0))
	var f: RaceFramer = pair[0]
	var cam: SectorCamera = pair[1]
	for i in 60:
		f.step(1.0 / 60.0)
	assert_bool(f.pulling).is_true()
	assert_float(cam.zoom.x).is_less(STATS.zoom)
	for i in roundi(STATS.race_pull_max_s * 60.0) + 120:
		f.step(1.0 / 60.0)
	assert_bool(f.pulling).is_false()
	assert_float(cam.zoom.x).is_equal_approx(STATS.zoom, 0.02)


func test_onscreen_sepulchre_keeps_zoom_one() -> void:
	var pair := _framer_with(Vector2(100, 40))
	var f: RaceFramer = pair[0]
	var cam: SectorCamera = pair[1]
	for i in 60:
		f.step(1.0 / 60.0)
	assert_bool(f.pulling).is_false()
	assert_float(cam.zoom.x).is_equal_approx(STATS.zoom, 0.001)
