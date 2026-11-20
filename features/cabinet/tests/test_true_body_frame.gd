extends GdUnitTestSuite
## S2 true-body impact frame: a Charge hit on the costume entity swaps the costume for the entity's true
## body for `true_frame_frames` DRAWN frames: a spine (the shared vertebral curve, MawView.spine_points),
## not a disc. GDD §20 (closed 2026-11-17): silhouette only; NARR-001 §3.4: no face. Deterministic (no rng).

const SCENE := preload("res://features/cabinet/cabinet_game.tscn")
const DT := 1.0 / 60.0

var game: Node
var world: ArcadeWorld
var ritual: SepulchreRitual


func before_test() -> void:
	AudioService.muted_for_tests = true
	SaveService.set_backend(MemorySaveBackend.new())
	SettingsService.persist = false
	game = SCENE.instantiate()
	add_child(game)
	game.set_process(false)
	world = game.get_node("%World")
	world.paused_sim = true
	world.start(_stage())
	ritual = world.ritual


func after_test() -> void:
	SettingsService.persist = true
	if is_instance_valid(game):
		game.free()
	AudioService.muted_for_tests = false
	SaveService.set_backend(FileSaveBackend.new())


func _stage() -> CabinetStage:
	var s := CabinetStage.new()
	s.geodes = 0
	s.grubs = 0
	s.acolytes = 0
	s.guard_acolytes = 0
	s.sepulchre_start_segments = world.tuning.segments_total
	s.sepulchre_wakes = true
	s.chant = false
	return s


func _awake() -> void:
	for i in 400:
		world.step(DT)
		if ritual.awake:
			return


func _length() -> float:
	return SepulchreRitual.TRUE_LENGTH_MULT * SepulchreRitual.BODY_DRAWN_RADIUS


## Distance from `p` to the polyline `curve`.
func _dist_to(curve: PackedVector2Array, p: Vector2) -> float:
	var best := INF
	for i in curve.size() - 1:
		best = minf(best, p.distance_to(Geometry2D.get_closest_point_to_segment(p, curve[i], curve[i + 1])))
	return best


func test_a_hit_sets_the_counter_and_it_counts_drawn_frames() -> void:
	_awake()
	assert_bool(ritual.awake).is_true()
	assert_bool(ritual.showing_true_frame()).is_false()
	var frames := world.fx_tuning.true_frame_frames
	assert_int(frames).is_equal(1)
	ritual._hit_entity(ritual.entity_pos)
	assert_bool(ritual.showing_true_frame()).is_true()
	# hit-stop freezes the sim: sim steps do not consume the frame, drawn frames do
	assert_int(world.hitstop_left).is_greater(0)
	world.step(DT)
	assert_bool(ritual.showing_true_frame()).is_true()
	for i in frames:
		ritual.advance_draw_frame()
	assert_bool(ritual.showing_true_frame()).is_false()


func test_a_longer_setting_lasts_that_many_drawn_frames() -> void:
	_awake()
	world.fx_tuning = world.fx_tuning.duplicate() as CabinetFxTuning
	world.fx_tuning.true_frame_frames = 3
	ritual._hit_entity(ritual.entity_pos)
	for i in 2:
		ritual.advance_draw_frame()
		assert_bool(ritual.showing_true_frame()).is_true()
	ritual.advance_draw_frame()
	assert_bool(ritual.showing_true_frame()).is_false()


func test_a_real_draw_consumes_the_frame() -> void:
	_awake()
	ritual._hit_entity(ritual.entity_pos)
	assert_bool(ritual.showing_true_frame()).is_true()
	ritual.queue_redraw()
	await get_tree().process_frame
	await get_tree().process_frame
	assert_bool(ritual.showing_true_frame()).is_false()


func test_the_shared_curve_is_twenty_tapering_deterministic_points() -> void:
	var a := MawView.spine_points()
	assert_int(a.size()).is_equal(20)
	assert_array(a).is_equal(MawView.spine_points())
	assert_vector(a[0]).is_equal(Vector2.ZERO)
	var first := a[1].distance_to(a[0])
	var last := a[19].distance_to(a[18])
	assert_float(first).is_greater(last * 1.5)       # vertebra spacing tapers toward the tail
	# an asymmetric S: it swings both ways, and the halves differ
	var above := 0
	var below := 0
	for p in a:
		if p.y > 0.005:
			above += 1
		elif p.y < -0.005:
			below += 1
	assert_int(above).is_greater(2)
	assert_int(below).is_greater(2)
	assert_float(absf(a[3].y + a[16].y)).is_greater(0.002)


## For outline point `p`: [distance to the curve, position along it (segment index + fraction), side (+1/-1)].
func _locate(curve: PackedVector2Array, p: Vector2) -> Array:
	var best := INF
	var par := 0.0
	var side := 1.0
	for i in curve.size() - 1:
		var q := Geometry2D.get_closest_point_to_segment(p, curve[i], curve[i + 1])
		var d := p.distance_to(q)
		if d < best:
			best = d
			var seg := curve[i + 1] - curve[i]
			par = i + (q - curve[i]).length() / seg.length()
			side = 1.0 if seg.cross(p - q) >= 0.0 else -1.0
	return [best, par, side]


func test_silhouette_is_a_beaded_column_with_both_edges_in_phase() -> void:
	var c := Vector2(100, 80)
	for d in [Vector2.DOWN, Vector2.UP]:
		var poly := MawView.spine_silhouette(c, d, _length())
		var curve := MawView.spine_place(MawView.spine_points(), c, d, _length())
		assert_bool(Geometry2D.triangulate_polygon(poly).size() > 0).is_true()
		var n := poly.size()
		var info: Array = []
		for p in poly:
			info.append(_locate(curve, p))
		var peaks := {1.0: [], -1.0: []}
		var pinches := {1.0: [], -1.0: []}
		for i in n:
			var cur: Array = info[i]
			var prv: Array = info[(i + n - 1) % n]
			var nxt: Array = info[(i + 1) % n]
			var par: float = cur[1]
			if cur[0] < 2.0:
				continue
			if cur[0] > prv[0] and cur[0] > nxt[0]:
				peaks[cur[2]].append(par)
			elif cur[0] < prv[0] and cur[0] < nxt[0] and par > 0.2 and par < 18.8:      # the end caps are not gaps
				pinches[cur[2]].append(par)
		for sd in [1.0, -1.0]:
			assert_int(peaks[sd].size()).is_equal(MawView.SEGMENTS)          # one wide lobe per vertebra on each edge
			assert_int(pinches[sd].size()).is_equal(MawView.SEGMENTS - 1)    # pinched at every gap between two vertebrae
		peaks[1.0].sort()
		peaks[-1.0].sort()
		pinches[1.0].sort()
		pinches[-1.0].sort()
		for i in MawView.SEGMENTS:
			assert_float(peaks[1.0][i]).is_equal_approx(peaks[-1.0][i], 0.25)     # both edges bulge at the same place along the curve
			assert_float(peaks[1.0][i]).is_equal_approx(float(i), 0.2)            # ... which is the vertebra
		for i in MawView.SEGMENTS - 1:
			assert_float(pinches[1.0][i]).is_equal_approx(pinches[-1.0][i], 0.25)
		# narrower at the tail than at the head
		assert_float(MawView.spine_half_width(19)).is_less(MawView.spine_half_width(0) * 0.6)


func test_it_is_a_column_not_a_ring() -> void:
	_awake()
	var c := Vector2(160, 60)
	ritual._true_dir = Vector2.DOWN
	var poly := ritual.true_frame_polygon(c)
	# head on the costume centre, inside the body
	assert_bool(Geometry2D.is_point_in_polygon(c, poly)).is_true()
	# overruns the costume's drawn bounds on one side, by a lot
	var top := 0.0
	var ext_fwd := 0.0
	var ext_back := 0.0
	for p in poly:
		top = maxf(top, p.distance_to(c))
		ext_fwd = maxf(ext_fwd, (p - c).y)
		ext_back = maxf(ext_back, -(p - c).y)
	assert_float(top).is_greater(SepulchreRitual.BODY_DRAWN_RADIUS * 3.0)
	assert_float(ext_fwd).is_greater(ext_back * 2.0)
	# no radial symmetry: the centroid is far from the head
	var sum := Vector2.ZERO
	for p in poly:
		sum += p
	assert_float((sum / poly.size()).distance_to(c)).is_greater(SepulchreRitual.BODY_DRAWN_RADIUS)


func test_the_column_trails_toward_the_middle_of_the_screen() -> void:
	_awake()
	var mid := world.screen_centre
	assert_vector(ritual.true_frame_dir_for(mid - Vector2(0, 40))).is_equal(Vector2.DOWN)
	assert_vector(ritual.true_frame_dir_for(mid + Vector2(0, 40))).is_equal(Vector2.UP)


func test_only_null_and_bone_3_are_used() -> void:
	assert_object(SepulchreRitual.TRUE_FRAME_FILL).is_equal(Pal.NULL)
	assert_object(SepulchreRitual.TRUE_FRAME_LINE).is_equal(Pal.BONE_3)
	var src := FileAccess.get_file_as_string("res://features/cabinet/sim/sepulchre_ritual.gd")
	var start := src.find("func _draw_true_frame")
	var end := src.find("func true_frame_dir_for")
	var body := src.substr(start, end - start)
	assert_int(body.find("Pal.")).is_equal(-1)          # colours only via the two constants
	assert_int(body.count("TRUE_FRAME_FILL")).is_equal(1)
	assert_int(body.count("TRUE_FRAME_LINE")).is_equal(1)
	assert_int(body.find("PHOS")).is_equal(-1)          # no eye, veins


func test_no_rng_is_consumed() -> void:
	_awake()
	ritual._hit_entity(ritual.entity_pos)     # the hit's own bursts use fx rng; the true frame adds none
	var before := world.rng.state
	ritual.true_frame_polygon(Vector2(50, 50))
	ritual.advance_draw_frame()
	ritual.queue_redraw()
	await get_tree().process_frame
	await get_tree().process_frame
	assert_int(world.rng.state).is_equal(before)


func test_the_reveal_ring_maths_is_unchanged() -> void:
	# the refactor must place vertebrae exactly as the old inline code did
	var t := 3.7
	for i in MawView.SEGMENTS:
		var a_old := t * 0.08 + TAU * i / MawView.SEGMENTS
		var r_old := MawView.RING * (1.0 + 0.03 * sin(t * 1.3)) + sin(t * 1.7 + i * 0.9) * 2.0
		assert_float(MawView.vertebra_angle(i, t)).is_equal(a_old)
		assert_float(MawView.vertebra_radius(i, t)).is_equal(r_old)
