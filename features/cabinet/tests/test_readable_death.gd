extends GdUnitTestSuite
## S6 readable death: a chalk ring round what killed the Vigil, a chalk arc on the Vigil, an edge
## tick when the killer is off-view. Deterministic (no world.rng), cleared on respawn / stage start.

const SCENE := preload("res://features/cabinet/cabinet_game.tscn")
const DT := 1.0 / 60.0

var game: Node
var world: ArcadeWorld
var fx: CabinetFxTuning
var _saved_reduced := false


func before_test() -> void:
	AudioService.muted_for_tests = true
	SaveService.set_backend(MemorySaveBackend.new())
	SettingsService.persist = false
	_saved_reduced = SettingsService.get_value(&"reduced_motion")
	SettingsService.set_value(&"reduced_motion", false)
	game = SCENE.instantiate()
	add_child(game)
	game.set_process(false)
	world = game.get_node("%World")
	world.paused_sim = true
	fx = world.fx_tuning
	world.start(_stage())
	world.vigil.shield = 0.0
	world.vigil.use_scripted = true


func after_test() -> void:
	SettingsService.set_value(&"reduced_motion", _saved_reduced)
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
	s.goal = CabinetStage.Goal.UNMAKE_ENTITY
	return s


func _shoot_vigil() -> void:
	world.shots.fire_censer(world.vigil.pos + Vector2(30, 0), Vector2.LEFT)
	for i in 60:
		world.step(DT)
		if not world.vigil.alive:
			return


func test_hostile_shot_kill_marks_the_shot() -> void:
	_shoot_vigil()
	assert_bool(world.vigil.alive).is_false()
	assert_int(world.fx.death_marks.size()).is_equal(1)
	var m: FxLayer.DeathMark = world.fx.death_marks[0]
	assert_float(world.torus.distance(m.killer_pos, world.vigil.pos)).is_less_equal(world.vigil.radius + 2.0 + 0.01)
	assert_float(m.from_dir.x).is_greater(0.99)   # the shot came from the right
	assert_float(m.killer_radius).is_equal(ShotLayer.HOSTILE_SHOT_RADIUS)
	assert_vector(m.vigil_pos).is_equal(world.vigil.pos)


func test_entity_contact_kill_marks_the_entity_with_its_drawn_radius() -> void:
	for i in roundi((world.tuning.awakening_silence + world.tuning.stagger_window + 0.1) / DT):
		world.step(DT)
	world.vigil.pos = world.torus.wrap(world.ritual.entity_pos + Vector2(60, 0))
	for i in 240:
		world.step(DT)
		if not world.vigil.alive:
			break
	assert_bool(world.vigil.alive).is_false()
	var m: FxLayer.DeathMark = world.fx.death_marks[0]
	assert_vector(m.killer_pos).is_equal(world.ritual.entity_pos)
	assert_float(m.killer_radius).is_equal(SepulchreRitual.BODY_DRAWN_RADIUS)
	assert_float(world.fx.death_ring_radius(m)).is_equal(SepulchreRitual.BODY_DRAWN_RADIUS + fx.death_ring_pad_px)
	assert_float(m.from_dir.length()).is_equal_approx(1.0, 0.001)


func test_ring_clears_the_silhouette_by_at_least_two_px() -> void:
	var dup := fx.duplicate() as CabinetFxTuning
	dup.death_ring_pad_px = 0.0
	world.fx_tuning = dup
	world.fx.death_mark(Vector2(10, 10), 3.0, Vector2.RIGHT, Vector2.ZERO)
	assert_float(world.fx.death_ring_radius(world.fx.death_marks[0])).is_greater_equal(5.0)


func test_default_kill_still_works_and_makes_no_mark() -> void:
	world.vigil.kill()
	assert_bool(world.vigil.alive).is_false()
	assert_int(world.fx.death_marks.size()).is_equal(0)


func test_shielded_kill_makes_no_mark() -> void:
	world.vigil.shield = 1.0
	world.vigil.kill(Vector2(5, 5), Vector2.RIGHT, 3.0)
	assert_bool(world.vigil.alive).is_true()
	assert_int(world.fx.death_marks.size()).is_equal(0)


func test_marks_never_touch_the_rng_even_when_drawn() -> void:
	var st0 := world.rng.state
	world.vigil.kill(world.vigil.pos + Vector2(20, 0), Vector2.RIGHT, 3.0)
	var st1 := world.rng.state   # kill's bursts draw rng; the mark itself must not
	world.fx.death_mark(Vector2(1, 1), 3.0, Vector2.UP, Vector2(2, 2))
	world.fx.death_outline_frac(world.fx.death_marks[0])
	world.fx.death_arrow_frac(world.fx.death_marks[0])
	world.fx.death_edge_tick(world.fx.death_marks[0])
	assert_int(world.rng.state).is_equal(st1)
	await await_idle_frame()
	assert_int(world.rng.state).is_equal(st1)
	assert_bool(st0 != st1).is_true()   # sanity: kill() itself does burst


func test_marks_clear_on_respawn_and_on_world_start() -> void:
	world.fx.death_mark(Vector2(1, 1), 3.0, Vector2.UP, Vector2(2, 2))
	game.state = game.State.DEAD
	game._on_timer()
	assert_int(world.fx.death_marks.size()).is_equal(0)
	world.fx.death_mark(Vector2(1, 1), 3.0, Vector2.UP, Vector2(2, 2))
	world.start(_stage())
	assert_int(world.fx.death_marks.size()).is_equal(0)


func test_off_view_killer_gets_an_edge_tick_toward_it() -> void:
	var v := world.vigil.pos
	world.fx.death_mark(world.torus.wrap(v + Vector2(0, world.view_size.y)), 3.0, Vector2.DOWN, v)
	var tick := world.fx.death_edge_tick(world.fx.death_marks[0])
	assert_int(tick.size()).is_equal(2)
	assert_bool(world.view_rect.has_point(tick[0])).is_true()
	assert_float(tick[0].y).is_greater(world.screen_centre.y)    # killer is below
	assert_float(tick[1].y).is_less(tick[0].y)                    # tick points back inward


func test_off_view_tick_follows_the_short_way_across_the_wrap() -> void:
	var size := world.torus.size
	var v := Vector2(8.0, size.y * 0.5)
	world.fx.death_mark(Vector2(size.x - 2.0 * world.view_size.x, v.y), 3.0, Vector2.LEFT, v)
	# the long way round is to the right; the torus delta says the killer is to the LEFT or nearer wrap
	var d := world.torus.delta(v, world.fx.death_marks[0].killer_pos)
	var tick := world.fx.death_edge_tick(world.fx.death_marks[0])
	assert_int(tick.size()).is_equal(2)
	assert_bool(signf(tick[0].x - world.screen_centre.x) == signf(d.x)).is_true()


func test_in_view_killer_gets_no_edge_tick() -> void:
	var v := world.vigil.pos
	world.fx.death_mark(v + Vector2(20, 0), 3.0, Vector2.RIGHT, v)
	assert_int(world.fx.death_edge_tick(world.fx.death_marks[0]).size()).is_equal(0)


func test_ring_gap_exceeds_the_entity_plate_spacing() -> void:
	var plate_spacing := TAU * SepulchreRitual.BODY_RADIUS / float(world.tuning.segments_total)
	assert_float(fx.death_ring_pad_px).is_greater(plate_spacing * 0.5)   # clear gap vs the ~5 px between plates
	assert_float(fx.death_ring_pad_px).is_greater(5.0)




func _seg_len(segs: Array[PackedVector2Array]) -> Array[float]:
	var out: Array[float] = []
	for s in segs:
		out.append(s[0].distance_to(s[1]))
	return out


func test_dash_rhythms_are_2_on_1_off_small_and_3_3_for_the_big_ring() -> void:
	assert_float(FxLayer.DASH_SMALL_ON).is_equal(2.0)
	assert_float(FxLayer.DASH_SMALL_OFF).is_equal(1.0)
	assert_float(FxLayer.DASH_RING_ON).is_equal(3.0)
	assert_float(FxLayer.DASH_RING_OFF).is_equal(3.0)
	# a straight 30 px path: dashes start every 3 px and are 2 px long
	var segs := world.fx.dash_path(PackedVector2Array([Vector2.ZERO, Vector2(30, 0)]), 1.0)
	assert_int(segs.size()).is_equal(10)
	assert_float(segs[0][0].x).is_equal(0.0)
	assert_float(segs[0][1].x).is_equal(2.0)
	assert_float(segs[1][0].x).is_equal(3.0)
	assert_array(world.fx.dash_path(PackedVector2Array([Vector2.ZERO, Vector2(30, 0)]), 1.0)).is_equal(segs)   # fixed pattern
	assert_int(world.fx.dash_path(PackedVector2Array([Vector2.ZERO, Vector2(30, 0)]), 0.5).size()).is_less(segs.size())
	# the ring round a shot (radius 9, diameter 18 > hull 15) is coarse; a tiny ring would be fine
	assert_bool(world.fx.ring_uses_coarse_dashes(16.0)).is_true()
	assert_bool(world.fx.ring_uses_coarse_dashes(9.0)).is_false()   # 18 px across < the 2x hull (30)
	var spans := world.fx.dash_spans(9.0, 1.0)
	assert_int(spans.size()).is_greater(3)
	for i in spans.size():
		var nxt := spans[(i + 1) % spans.size()]
		var gap: float = (nxt.x - spans[i].y) if i + 1 < spans.size() else (nxt.x + TAU - spans[i].y)
		assert_float(gap * 9.0).is_greater(1.5)


func test_outline_is_the_vigils_hull_at_the_death_spot_and_facing() -> void:
	world.vigil.facing = 0.7
	var v0 := world.vigil.pos
	world.vigil.kill(v0 + Vector2(10, 0), Vector2.RIGHT, 3.0)
	var m: FxLayer.DeathMark = world.fx.death_marks[0]
	assert_float(m.facing).is_equal(0.7)
	var out := world.fx.death_outline(m)
	assert_int(out.size()).is_equal(4)
	var c0 := world.to_screen(v0).round()
	var expect := world.vigil.hull_points(c0, 0.7)
	for i in 4:
		expect[i] = (c0 + (expect[i] - c0) * fx.death_outline_scale).round()
	for i in 4:
		assert_vector(out[i]).is_equal(expect[i])
	# 15 px nose to tail
	var f := Vector2.from_angle(0.7)
	assert_float((out[0] - (out[1] + out[3]) * 0.5).dot(f)).is_equal_approx(VigilShip.HULL_LENGTH * fx.death_outline_scale, 1.0)


func test_arrow_is_at_least_a_hull_long_and_points_in_from_the_killers_side() -> void:
	var v0 := world.vigil.pos
	world.fx.death_mark(v0 + Vector2(60, 0), 3.0, Vector2.RIGHT, v0)   # killer to the right
	var m: FxLayer.DeathMark = world.fx.death_marks[0]
	var arrow := world.fx.death_arrow(m)
	var c := world.to_screen(v0).round()
	assert_float(arrow[0].distance_to(arrow[1])).is_greater_equal(VigilShip.HULL_LENGTH * fx.death_outline_scale)
	assert_float(fx.death_arrow_px).is_equal(VigilShip.HULL_LENGTH * fx.death_outline_scale)
	assert_float(arrow[0].x).is_greater(arrow[1].x)         # tail is out toward the killer
	assert_float(arrow[1].x).is_greater(c.x)                # tip lands inside the outline, on the killer's side
	assert_float(arrow[1].x - c.x).is_equal(4.0 * fx.death_outline_scale)   # the tip inset scales too
	assert_float(arrow[2].x).is_greater(arrow[1].x)         # barbs sweep back toward the killer
	assert_float(arrow[3].x).is_greater(arrow[1].x)
	assert_float(arrow[2].y).is_not_equal(arrow[3].y)
	assert_int(world.fx.death_marks.size()).is_equal(1)


func test_leader_only_when_the_killer_is_far_and_it_tracks_the_live_entity() -> void:
	var v0 := world.vigil.pos
	# adjacent (a shot, or the body touching): the arrow alone
	world.ritual.entity_pos = v0 + Vector2(40, 0)
	world.fx.death_mark(world.ritual.entity_pos, SepulchreRitual.BODY_DRAWN_RADIUS, Vector2.RIGHT, v0)
	var m: FxLayer.DeathMark = world.fx.death_marks[0]
	assert_int(world.fx.death_leader(m).size()).is_equal(0)
	# far: the leader appears and follows the live position, not the death-time one
	world.ritual.entity_pos = v0 + Vector2(90, 0)
	var a := world.fx.death_leader(m)
	assert_int(a.size()).is_equal(2)
	assert_vector(a[0]).is_equal(world.fx.death_arrow(m)[0])        # it continues the shaft
	world.ritual.entity_pos = v0 + Vector2(110, 0)
	var b := world.fx.death_leader(m)
	assert_float(b[1].x - a[1].x).is_equal_approx(20.0, 1.0)
	assert_vector(m.killer_pos).is_equal(v0 + Vector2(40, 0))        # the death-time anchor is untouched
	# a shot never tracks: it stays where it killed
	var s0 := FxLayer.DeathMark.new()
	s0.killer_pos = v0 + Vector2(5, 0)
	s0.vigil_pos = v0
	s0.from_dir = Vector2.RIGHT
	s0.killer_radius = ShotLayer.HOSTILE_SHOT_RADIUS
	world.ritual.entity_pos = v0 + Vector2(500, 500)
	assert_vector(world.fx.death_killer_pos(s0)).is_equal(v0 + Vector2(5, 0))
	assert_int(world.fx.death_leader(s0).size()).is_equal(0)


func test_leader_starts_from_the_outline_edge_facing_a_killer_that_moved_round() -> void:
	# The entity killed from the right, then rampaged round to the left: the leader must leave
	# from the outline's left edge, never run back across the outline and the arrow.
	var v0 := world.vigil.pos
	world.ritual.entity_pos = v0 + Vector2(40, 0)
	world.fx.death_mark(world.ritual.entity_pos, SepulchreRitual.BODY_DRAWN_RADIUS, Vector2.RIGHT, v0)
	var m: FxLayer.DeathMark = world.fx.death_marks[0]
	world.ritual.entity_pos = v0 + Vector2(-110, 0)
	var lead := world.fx.death_leader(m)
	assert_int(lead.size()).is_equal(2)
	var c := world.to_screen(v0).round()
	var left_edge := 0.0
	for p in world.fx.death_outline(m):
		left_edge = minf(left_edge, p.x - c.x)
	assert_float(lead[0].x - c.x).is_less(left_edge)           # starts beyond the outline's left edge
	assert_float(lead[1].x).is_less(lead[0].x)                 # and runs away from it, toward the killer
	assert_float(world.fx.death_arrow(m)[0].x).is_greater(c.x) # the arrow stays on its (right) side


func test_off_view_entity_ends_the_leader_at_the_edge_tick() -> void:
	var v0 := world.vigil.pos
	world.ritual.entity_pos = v0 + Vector2(40, 0)
	world.fx.death_mark(world.ritual.entity_pos, SepulchreRitual.BODY_DRAWN_RADIUS, Vector2.RIGHT, v0)
	var m: FxLayer.DeathMark = world.fx.death_marks[0]
	world.ritual.entity_pos = world.torus.wrap(v0 + Vector2(0, world.view_size.y))
	var tick := world.fx.death_edge_tick(m)
	assert_int(tick.size()).is_equal(2)
	var lead := world.fx.death_leader(m)
	assert_int(lead.size()).is_equal(2)
	assert_vector(lead[1]).is_equal(tick[1])


func test_a_shot_gets_the_silhouette_ring_as_well_as_the_outline() -> void:
	var v0 := world.vigil.pos
	world.fx.death_mark(v0 + Vector2(10, 0), ShotLayer.HOSTILE_SHOT_RADIUS, Vector2.RIGHT, v0)
	var m: FxLayer.DeathMark = world.fx.death_marks[0]
	assert_bool(world.fx.death_is_big(m)).is_false()
	assert_float(world.fx.death_ring_radius(m)).is_equal(ShotLayer.HOSTILE_SHOT_RADIUS + fx.death_ring_pad_px)
	assert_int(world.fx.death_outline(m).size()).is_equal(4)


func test_the_finished_outline_is_a_solid_closed_hull() -> void:
	# Review round 4: solid = you, dashed = pointing. The drawn outline covers the whole perimeter
	# with no gaps and closes on itself.
	world.vigil.kill(world.vigil.pos + Vector2(80, 0), Vector2.RIGHT, 30.0)
	var m: Variant = world.fx.death_marks[0]
	var hull := world.fx.death_outline(m)
	var segs: Array[PackedVector2Array] = world.fx.death_outline_segments(m, 1.0)
	assert_int(segs.size()).is_equal(hull.size())          # one unbroken piece per hull edge
	for i in segs.size():
		assert_vector(segs[i][0]).is_equal(hull[i])
		assert_vector(segs[i][1]).is_equal(hull[(i + 1) % hull.size()])
	# Half drawn on: still unbroken pieces, ending part-way round.
	var half: Array[PackedVector2Array] = world.fx.death_outline_segments(m, 0.5)
	assert_int(half.size()).is_less(hull.size() + 1)
	assert_vector(half[0][0]).is_equal(hull[0])


func test_outline_scale_is_two_hull_sizes() -> void:
	assert_float(fx.death_outline_scale).is_equal(2.0)
	assert_float(fx.death_arrow_px).is_equal(30.0)
	var v0 := world.vigil.pos
	world.fx.death_mark(v0 + Vector2(10, 0), 3.0, Vector2.RIGHT, v0, 0.0)
	var out := world.fx.death_outline(world.fx.death_marks[0])
	var c := world.to_screen(v0).round()
	assert_float(out[0].x - c.x).is_equal(18.0)            # nose at 9 x 2
	assert_float(out[1].x - c.x).is_equal(-12.0)           # tail at -6 x 2


func test_no_chalk_before_the_death_burst_ring_has_faded_then_outline_then_arrow() -> void:
	world.fx.death_mark(Vector2(1, 1), 3.0, Vector2.UP, Vector2(2, 2))
	var m: FxLayer.DeathMark = world.fx.death_marks[0]
	var delay := world.fx.death_chalk_delay()
	assert_float(delay).is_greater_equal(FxLayer.ring_life(fx.vigil_death_ring_radius))
	var seen_partial_outline := false
	var last_outline := 0.0
	for i in 90:
		world.fx.tick(DT)
		var o := world.fx.death_outline_frac(m)
		var a := world.fx.death_arrow_frac(m)
		if m.age < delay:
			assert_float(o).is_equal(0.0)        # no chalk pixel while the burst ring may live
			assert_float(a).is_equal(0.0)
		assert_float(o).is_greater_equal(last_outline)
		last_outline = o
		if a > 0.0:
			assert_float(o).is_equal(1.0)         # the arrow never starts before the outline is complete
		if o > 0.0 and o < 1.0:
			seen_partial_outline = true
			assert_float(a).is_equal(0.0)
	assert_bool(seen_partial_outline).is_true()
	assert_float(world.fx.death_arrow_frac(m)).is_equal(1.0)   # held until respawn


func test_the_real_burst_ring_is_gone_before_any_chalk() -> void:
	world.vigil.kill(world.vigil.pos + Vector2(10, 0), Vector2.RIGHT, 3.0)
	var m: FxLayer.DeathMark = world.fx.death_marks[0]
	for i in 200:
		world.fx.tick(DT)
		var ring_alive := false
		for r in world.fx.rings:
			if r.color == Look.c(Pal.GAS_3) and r.radius == fx.vigil_death_ring_radius:
				ring_alive = true
		if ring_alive:
			assert_float(world.fx.death_outline_frac(m)).is_equal(0.0)
	assert_float(world.fx.death_outline_frac(m)).is_equal(1.0)


func test_reduced_motion_keeps_the_delay_then_shows_everything_at_once() -> void:
	SettingsService.set_value(&"reduced_motion", true)
	world.fx.death_mark(Vector2(1, 1), 3.0, Vector2.UP, Vector2(2, 2))
	var m: FxLayer.DeathMark = world.fx.death_marks[0]
	assert_float(world.fx.death_outline_frac(m)).is_equal(0.0)
	assert_float(world.fx.death_arrow_frac(m)).is_equal(0.0)
	m.age = world.fx.death_chalk_delay() + 0.001
	assert_float(world.fx.death_outline_frac(m)).is_equal(1.0)
	assert_float(world.fx.death_arrow_frac(m)).is_equal(1.0)


func test_real_entity_death_in_the_real_stage_draws_the_outline_and_arrow() -> void:
	var st := (game.stages[1] as CabinetStage).duplicate() as CabinetStage
	st.sepulchre_start_segments = 20
	world.start(st)
	world.vigil.shield = 0.0
	world.vigil.use_scripted = true
	for i in 3000:
		world.step(DT)
		if not world.vigil.alive:
			break
	assert_bool(world.vigil.alive).is_false()
	for i in 75:
		world.step(DT)
	var m: FxLayer.DeathMark = world.fx.death_marks[0]
	var o := world.fx.death_outline_frac(m)
	assert_float(o).is_equal(1.0)
	assert_float(world.fx.death_arrow_frac(m)).is_equal(1.0)
	assert_bool(world.fx.visible_at(m.vigil_pos, fx.death_arrow_px + 12.0)).is_true()
	var segs := world.fx.death_outline_segments(m, o)
	assert_int(segs.size()).is_greater(0)
	# A 1 px quad through integer corners covers no pixel centre on a 45 degree run and vanishes in
	# the real render (headless has no pixels to read): every chalk line must be pixel-centred.
	for seg in segs:
		var e := world.fx.chalk_line_ends(seg[0], seg[1])
		for pt in e:
			assert_float(pt.x - floorf(pt.x)).is_equal(0.5)
			assert_float(pt.y - floorf(pt.y)).is_equal(0.5)
