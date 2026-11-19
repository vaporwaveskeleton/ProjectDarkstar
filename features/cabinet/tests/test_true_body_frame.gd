extends GdUnitTestSuite
## S2 true-body impact frame: a Charge hit on the costume entity swaps the costume for the entity's
## silhouette for `true_frame_frames` DRAWN frames. GDD §20 (closed 2026-11-17): in Act 0 the entity is
## seen only as a silhouette; NARR-001 §3.4: no face. Deterministic (no world.rng).

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


func test_silhouette_is_a_closed_polygon_with_twenty_notches() -> void:
	_awake()
	var c := Vector2(100, 80)
	for t in [0.0, 1.3, 7.9]:
		var poly := ritual.true_frame_polygon_at(c, t)
		var n := poly.size()
		assert_int(n).is_greater(MawView.SEGMENTS * 2)
		var rad: Array[float] = []
		for p in poly:
			rad.append(p.distance_to(c))
		var minima := 0
		for i in n:
			if rad[i] < rad[(i + n - 1) % n] and rad[i] < rad[(i + 1) % n]:
				minima += 1
		assert_int(minima).is_equal(MawView.SEGMENTS)
		var top := 0.0
		for r in rad:
			top = maxf(top, r)
		assert_float(top).is_equal_approx(SepulchreRitual.BODY_DRAWN_RADIUS, 1.0)
		# a simple (non self-overlapping) polygon: it triangulates
		assert_bool(Geometry2D.triangulate_polygon(poly).size() > 0).is_true()


func test_only_null_and_bone_3_are_used() -> void:
	assert_object(SepulchreRitual.TRUE_FRAME_FILL).is_equal(Pal.NULL)
	assert_object(SepulchreRitual.TRUE_FRAME_LINE).is_equal(Pal.BONE_3)
	var src := FileAccess.get_file_as_string("res://features/cabinet/sim/sepulchre_ritual.gd")
	var start := src.find("func _draw_true_frame")
	var end := src.find("func true_frame_polygon")
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
