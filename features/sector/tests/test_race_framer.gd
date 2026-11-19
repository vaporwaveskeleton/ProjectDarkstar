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
