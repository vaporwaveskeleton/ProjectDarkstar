extends GdUnitTestSuite
## Race framing (Reviewer rank 6, v3 gap 6): the camera leans to the centre of the race's box (Q-T354),
## never so far that the Vigil leaves the screen; when the race still does not fit it pulls out to the
## fitted zoom (Q-T355), for a Charge's whole flight or at most `race_pull_max_s` for a Grub theft, and
## never under reduced motion (Q-T356). SettingsService never persists here.

const SCENE := "res://scenes/sector/sector_stub.tscn"
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


func test_no_race_no_lean() -> void:
	assert_vector(RaceFramer.lean_goal(PackedVector2Array(), 560.0, Vector2(100, 60))).is_equal(Vector2.ZERO)


func test_one_point_leans_to_its_midpoint() -> void:
	var g := RaceFramer.lean_goal(PackedVector2Array([Vector2(100, -40)]), 560.0, Vector2(500, 500))
	assert_vector(g).is_equal_approx(Vector2(50, -20), Vector2(0.001, 0.001))


func test_lean_frames_both_ends_not_the_mean() -> void:
	# A Charge just off the bow and the Sepulchre far ahead, plus a Grub near the Charge: the mean would
	# sit near the cluster; the box centre sits halfway to the Sepulchre (both ends of the race).
	var offs := PackedVector2Array([Vector2(40, 0), Vector2(50, 10), Vector2(400, 0)])
	var g := RaceFramer.lean_goal(offs, 900.0, Vector2(500, 500))
	assert_vector(g).is_equal_approx(Vector2(200, 5), Vector2(0.001, 0.001))


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


func test_fit_zoom() -> void:
	var half := Vector2(320, 180)
	# Fits already: zoom 1.
	assert_float(RaceFramer.fit_zoom(PackedVector2Array([Vector2(200, 0)]), Vector2(100, 0), half, 24.0, 0.8, 1.0)).is_equal(1.0)
	# 600 px span centred: each end 300 px out, room 296 px -> 296 / 300.
	var z := RaceFramer.fit_zoom(PackedVector2Array([Vector2(600, 0)]), Vector2(300, 0), half, 24.0, 0.8, 1.0)
	assert_float(z).is_equal_approx(296.0 / 300.0, 0.0001)
	# Too wide for the floor: clamped to the floor.
	assert_float(RaceFramer.fit_zoom(PackedVector2Array([Vector2(1800, 0)]), Vector2(300, 0), half, 24.0, 0.8, 1.0)).is_equal(0.8)
	# Nothing to fit.
	assert_float(RaceFramer.fit_zoom(PackedVector2Array(), Vector2.ZERO, half, 24.0, 0.8, 1.0)).is_equal(1.0)


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
	# Both ends of the race are on screen, or the part that is not has an edge marker (Q-T357).
	if sector.race_on_screen < sector.race_points:
		assert_int(sector.race_markers).is_greater_equal(sector.race_points - sector.race_on_screen)


# --- pull-out (Q-T211, Q-T355, Q-T356) ------------------------------------------------------------

func test_offscreen_helper() -> void:
	assert_bool(RaceFramer.offscreen(Vector2(330, 0), Vector2(320, 180))).is_true()
	assert_bool(RaceFramer.offscreen(Vector2(0, -190), Vector2(320, 180))).is_true()
	assert_bool(RaceFramer.offscreen(Vector2(300, 170), Vector2(320, 180))).is_false()


func test_pull_out_is_bounded_by_its_data() -> void:
	assert_float(STATS.race_pull_zoom).is_greater(0.0)
	assert_float(STATS.race_pull_zoom).is_less(STATS.zoom)   # a pull OUT, never in
	assert_float(STATS.race_pull_max_s).is_greater(0.0)
	assert_float(STATS.race_fit_margin_px).is_greater_equal(0.0)
	assert_bool(STATS.race_pull_off_under_reduced_motion).is_true()


## A framer over a bare camera whose race is `pts` (offsets from the Vigil at the origin).
func _framer_with(pts: PackedVector2Array, charge: bool = false) -> Array:
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
	f.points = func() -> PackedVector2Array: return pts
	f.charge_flying = func() -> bool: return charge
	auto_free(f)
	return [f, cam]


func _run(f: RaceFramer, seconds: float) -> void:
	for i in roundi(seconds * 60.0):
		f.step(1.0 / 60.0)


func test_grub_theft_pulls_out_then_returns_after_the_cap() -> void:
	var pair := _framer_with(PackedVector2Array([Vector2(300, 0), Vector2(850, 0)]))
	var f: RaceFramer = pair[0]
	var cam: SectorCamera = pair[1]
	_run(f, 1.0)
	assert_bool(f.pulling).is_true()
	assert_float(cam.zoom.x).is_less(STATS.zoom)
	assert_float(cam.zoom.x).is_greater_equal(STATS.race_pull_zoom - 0.01)
	_run(f, STATS.race_pull_max_s + 2.0)
	assert_bool(f.pulling).is_false()
	assert_float(cam.zoom.x).is_equal_approx(STATS.zoom, 0.02)


func test_a_charge_flight_holds_the_pull_past_the_cap() -> void:
	var pair := _framer_with(PackedVector2Array([Vector2(300, 0), Vector2(850, 0)]), true)
	var f: RaceFramer = pair[0]
	var cam: SectorCamera = pair[1]
	_run(f, STATS.race_pull_max_s + 1.0)
	assert_bool(f.pulling).is_true()
	assert_float(cam.zoom.x).is_less(STATS.zoom)


func test_the_pull_is_fitted_not_fixed() -> void:
	# A race just too wide for zoom 1 pulls out only as far as it needs (above the floor).
	var pair := _framer_with(PackedVector2Array([Vector2(560, 0)]), true)
	var f: RaceFramer = pair[0]
	_run(f, 2.0)
	assert_bool(f.pulling).is_true()
	assert_float(f.fit).is_greater(STATS.race_pull_zoom)
	assert_float(f.fit).is_less(STATS.zoom)


func test_onscreen_race_keeps_zoom_one() -> void:
	var pair := _framer_with(PackedVector2Array([Vector2(100, 40)]), true)
	var f: RaceFramer = pair[0]
	var cam: SectorCamera = pair[1]
	_run(f, 1.0)
	assert_bool(f.pulling).is_false()
	assert_float(cam.zoom.x).is_equal_approx(STATS.zoom, 0.001)


func test_reduced_motion_never_moves_the_zoom() -> void:
	SettingsService.set_value(&"reduced_motion", true)
	var pair := _framer_with(PackedVector2Array([Vector2(300, 0), Vector2(850, 0)]), true)
	var f: RaceFramer = pair[0]
	var cam: SectorCamera = pair[1]
	for i in 120:
		f.step(1.0 / 60.0)
		assert_float(cam.zoom.x).is_equal(STATS.zoom)
	assert_bool(f.pulling).is_false()
	assert_float(f.lean.length()).is_greater(1.0)   # the lean still pans
