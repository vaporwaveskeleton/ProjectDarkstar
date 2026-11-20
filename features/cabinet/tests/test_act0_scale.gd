extends GdUnitTestSuite
## Act 0 scale (SYS-001 §1.7, Q-T365–Q-T377; every number PROPOSED ✱): the 65,536 px field, the Vigil's
## neighbourhood box, the Sepulchre's start and leash, the 48 px HUD band, the local Ledger Compass, the
## new unit sizes, Acolyte mining and the Acolyte entry hold. Driven tick by tick through the real scene.

const SCENE := preload("res://features/cabinet/cabinet_game.tscn")
const DT := 1.0 / 60.0
const STAGE_FILES := {
	&"a0_1": "res://data/cabinet/stage_first_vigil.tres",
	&"a0_2": "res://data/cabinet/stage_drift.tres",
	&"a0_3": "res://data/cabinet/stage_censer_watch.tres",
	&"a0_4": "res://data/cabinet/stage_shoal.tres",
	&"a0_5": "res://data/cabinet/stage_last_normal_day.tres",
}

var game: Node
var world: ArcadeWorld
var t: CabinetTuning


func before_test() -> void:
	AudioService.muted_for_tests = true
	SaveService.set_backend(MemorySaveBackend.new())
	game = SCENE.instantiate()
	add_child(game)
	game.set_process(false)
	(game.get_node("%Messages") as Node).set_process(false)
	world = game.get_node("%World")
	world.paused_sim = true
	t = world.tuning


func after_test() -> void:
	if is_instance_valid(game):
		game.free()
	AudioService.muted_for_tests = false
	SaveService.set_backend(FileSaveBackend.new())
	get_tree().paused = false


func _stage() -> CabinetStage:
	var s := CabinetStage.new()
	s.geodes = 0
	s.grubs = 0
	s.acolytes = 0
	s.guard_acolytes = 0
	s.sepulchre_wakes = false
	s.chant = false
	s.goal = CabinetStage.Goal.CLEAR_SEPULCHRE
	return s


func _start(s: CabinetStage) -> void:
	world.start(s)
	world.vigil.use_scripted = true
	world.vigil.shield = 999.0


func _spec() -> CabinetScreenSpec:
	return load("res://data/cabinet/cabinet_screen.tres") as CabinetScreenSpec


# --- field, screen split ----------------------------------------------------------------------

func test_the_field_is_65536_square_for_every_stage() -> void:
	assert_vector(CabinetStage.new().field_size).is_equal(Vector2(65536, 65536))
	for id: StringName in STAGE_FILES:
		assert_vector((load(STAGE_FILES[id]) as CabinetStage).field_size).is_equal(Vector2(65536, 65536))


func test_hud_strip_is_48_and_the_play_view_is_256_square() -> void:
	var spec := _spec()
	assert_int(spec.hud_strip_height).is_equal(48)
	assert_vector(spec.play_size()).is_equal(Vector2(256, 256))
	assert_object(spec.compass_box).is_equal(Rect2(106, 2, 44, 44))
	assert_object(spec.compass_inner()).is_equal(Rect2(108, 4, 40, 40))
	assert_bool(spec.strip_rect().grow(-1.0).encloses(spec.compass_box)).is_true()


func test_acolyte_mine_is_set_on_exactly_a0_3_to_a0_5() -> void:
	for id: StringName in STAGE_FILES:
		var st := load(STAGE_FILES[id]) as CabinetStage
		var want := id == &"a0_3" or id == &"a0_4" or id == &"a0_5"
		assert_bool(st.acolyte_mine).override_failure_message("%s acolyte_mine" % id).is_equal(want)
	assert_bool(CabinetStage.new().acolyte_mine).is_false()


func test_sizes_come_from_tuning() -> void:
	assert_float(t.size_grub_px).is_equal(11.0)
	assert_float(t.size_acolyte_px).is_equal(15.0)
	assert_float(t.size_shard_px).is_equal(5.0)
	assert_array(t.size_geode_radii).is_equal([9.0, 12.0, 15.0])
	_start(_stage())
	for k in 3:
		assert_float(world.geodes.add_geode(Vector2.ZERO, k).radius).is_equal(t.size_geode_radii[k])
	assert_float(world.grubs.radius()).is_equal(t.size_grub_px * 0.5 - 1.0)
	assert_float(world.acolytes.radius()).is_equal(t.size_acolyte_px * 0.5 - 1.0)
	assert_float(world.vigil.radius).is_equal(6.0)
	for key in ["field_neighbourhood_half_px", "field_sepulchre_start_px", "field_sepulchre_leash_px", "field_sepulchre_drift_px_s",
			"compass_px_per_dot", "size_grub_px", "size_acolyte_px", "size_geode_radii", "size_shard_px", "acolyte_enter_hold_s"]:
		assert_bool(t.ds_keys().has("ds_cabinet.tuning.%s" % key)).override_failure_message(key).is_true()


# --- neighbourhood ----------------------------------------------------------------------------

func test_a_free_object_beyond_the_box_re_enters_on_the_opposite_edge() -> void:
	_start(_stage())
	var v := world.vigil.pos
	var g := world.geodes.add_geode(v + Vector2(900, 300), 1)
	world.neighbourhood.step()
	var d := world.torus.delta(v, g.pos)
	assert_float(d.x).is_equal_approx(900.0 - 2.0 * t.field_neighbourhood_half_px, 0.01)
	assert_float(d.y).is_equal_approx(300.0, 0.01)
	var s := world.glass.spawn_shard(v + Vector2(-200, -1000), Vector2.ZERO)
	var gr := world.grubs._spawn(v + Vector2(830, 0))
	var a := world.acolytes.spawn(v + Vector2(0, 900))
	world.neighbourhood.step()
	assert_float(world.torus.delta(v, s.pos).y).is_equal_approx(-1000.0 + 2.0 * t.field_neighbourhood_half_px, 0.01)
	assert_float(world.torus.delta(v, gr.pos).x).is_equal_approx(830.0 - 2.0 * t.field_neighbourhood_half_px, 0.01)
	assert_float(world.torus.delta(v, a.pos).y).is_equal_approx(900.0 - 2.0 * t.field_neighbourhood_half_px, 0.01)


func test_inside_the_box_nothing_moves() -> void:
	_start(_stage())
	var v := world.vigil.pos
	var p := v + Vector2(700, -700)
	var g := world.geodes.add_geode(p, 0)
	world.neighbourhood.step()
	assert_vector(g.pos).is_equal(p)


func test_laden_grubs_escorts_guards_the_sepulchre_and_carried_glass_are_never_moved() -> void:
	_start(_stage())
	var v := world.vigil.pos
	var far := v + Vector2(1800, 0)
	var laden := world.grubs._spawn(far)
	laden.carrying = true
	var carried := world.glass.spawn_shard(far, Vector2.ZERO)
	carried.carried = true
	var escort := world.acolytes.spawn(far)
	escort.escorting = true
	var guard := world.acolytes.spawn(far)
	guard.guard = true
	var sep := world.ritual.pos
	world.neighbourhood.step()
	assert_vector(laden.pos).is_equal(far)
	assert_vector(carried.pos).is_equal(far)
	assert_vector(escort.pos).is_equal(far)
	assert_vector(guard.pos).is_equal(far)
	assert_vector(world.ritual.pos).is_equal(sep)


func test_a_re_wrapped_object_never_lands_in_the_view() -> void:
	_start(_stage())
	var v := world.vigil.pos
	# 900 px left of the Vigil re-enters 636 px right of it (out of view) ...
	var ok := world.geodes.add_geode(v + Vector2(-900, 0), 0)
	world.neighbourhood.step()
	assert_bool(world.on_screen(ok.pos, 0.0)).is_false()
	# 1,586 px away (a Vigil teleport) the local wrap would land 50 px from the Vigil, inside the view: it is pushed to the view edge
	for off: Vector2 in [Vector2(1586, 20), Vector2(-1586, -20), Vector2(30, 1580), Vector2(20, -1560)]:
		var g := world.geodes.add_geode(v + off, 2)
		world.neighbourhood.step()
		assert_bool(world.on_screen(g.pos, 0.0)).override_failure_message("geode landed in view for %s" % off).is_false()
		assert_bool(world.neighbourhood.outside(g.pos)).is_false()


func test_every_spawn_is_in_the_box_and_off_view() -> void:
	var s := _stage()
	s.geodes = 12
	s.grubs = 5
	s.acolytes = 3
	_start(s)
	var v := world.vigil.pos
	var h := t.field_neighbourhood_half_px
	var spots: Array[Vector2] = []
	for g in world.geodes.items:
		spots.append(g.pos)
	for gr in world.grubs.items:
		spots.append(gr.pos)
	for a in world.acolytes.items:
		spots.append(a.pos)
	assert_int(spots.size()).is_equal(20)
	for p in spots:
		var d := world.torus.delta(v, p)
		assert_bool(absf(d.x) <= h and absf(d.y) <= h).override_failure_message("spawn %s outside the box" % d).is_true()
		assert_bool(world.on_screen(p, 0.0)).override_failure_message("spawn %s in view" % d).is_false()
	# a Grub respawn and a drift-in geode follow the same rule
	s.geode_drift_s = 1.0
	var gd := world.geodes.drift_in()
	assert_object(gd).is_not_null()
	assert_bool(world.neighbourhood.outside(gd.pos)).is_false()
	assert_bool(world.on_screen(gd.pos, 0.0)).is_false()
	world.grubs.kill(world.grubs.items[0], false)
	for i in int(t.grub_respawn / DT) + 5:
		world.grubs.tick(DT)
	var newest: GrubFlock.Grub = world.grubs.items[world.grubs.items.size() - 1]
	assert_bool(world.neighbourhood.outside(newest.pos)).is_false()
	assert_bool(world.on_screen(newest.pos, 0.0)).is_false()


# --- Sepulchre --------------------------------------------------------------------------------

func test_the_sepulchre_starts_2560_px_straight_ahead() -> void:
	_start(_stage())
	var v := world.vigil
	assert_float(world.torus.distance(v.pos, world.ritual.pos)).is_equal_approx(t.field_sepulchre_start_px, 0.5)
	var want := Vector2.from_angle(v.facing)
	assert_vector(world.torus.delta(v.pos, world.ritual.pos).normalized()).is_equal_approx(want, Vector2(0.001, 0.001))


func test_the_sepulchre_drifts_toward_a_vigil_beyond_the_leash_and_not_inside_it() -> void:
	_start(_stage())
	var r := world.ritual
	var before := r.pos
	world.vigil.pos = world.torus.wrap(r.pos - Vector2(t.field_sepulchre_leash_px - 100.0, 0))
	r.tick(1.0)
	assert_vector(r.pos).is_equal(before)             # inside the leash: stays put
	world.vigil.pos = world.torus.wrap(r.pos - Vector2(t.field_sepulchre_leash_px + 500.0, 0))
	var d0 := world.torus.distance(r.pos, world.vigil.pos)
	r.tick(1.0)
	assert_float(d0 - world.torus.distance(r.pos, world.vigil.pos)).is_equal_approx(t.field_sepulchre_drift_px_s, 0.01)
	assert_vector(r.entity_pos).is_equal(r.pos)


func test_a_waking_or_awake_sepulchre_does_not_drift() -> void:
	var s := _stage()
	s.sepulchre_wakes = true
	s.goal = CabinetStage.Goal.UNMAKE_ENTITY
	s.sepulchre_start_segments = 20
	_start(s)
	var r := world.ritual
	var before := r.pos
	world.vigil.pos = world.torus.wrap(r.pos - Vector2(t.field_sepulchre_leash_px + 500.0, 0))
	r.tick(1.0)
	assert_vector(r.pos).is_equal(before)


func test_laden_grubs_still_reach_a_far_sepulchre() -> void:
	var s := _stage()
	s.grubs = 1
	_start(s)
	var r := world.ritual
	var gr: GrubFlock.Grub = world.grubs.items[0]
	var sh := world.glass.spawn_shard(world.vigil.pos + Vector2(300, 0), Vector2.ZERO)
	gr.pos = sh.pos
	gr.carrying = true
	gr.shard = sh
	sh.carried = true
	sh.claimed_by = gr.id
	world.vigil.pos = world.torus.wrap(gr.pos + Vector2(0, 700))
	var d0 := world.torus.distance(gr.pos, r.pos)
	for i in 600:
		world.step(DT)
	assert_float(world.torus.distance(gr.pos, r.pos)).is_less(d0 - 500.0)   # 10 s at the carry speed: ~1,300 px nearer


# --- compass ----------------------------------------------------------------------------------

func test_compass_scale_range_and_edge_pip_bearing() -> void:
	var inner := _spec().compass_inner()
	assert_float(t.compass_px_per_dot).is_equal(32.0)
	assert_vector(CabinetScreenHud.compass_offset(Vector2(640, -320), t.compass_px_per_dot)).is_equal(Vector2(20, -10))
	assert_bool(CabinetScreenHud.compass_in_range(Vector2(600, 600), inner, t.compass_px_per_dot)).is_true()
	assert_bool(CabinetScreenHud.compass_in_range(Vector2(700, 0), inner, t.compass_px_per_dot)).is_false()
	assert_bool(CabinetScreenHud.compass_in_range(Vector2(0, -2000), inner, t.compass_px_per_dot)).is_false()
	# the pip sits on the inner edge, on the true bearing
	for delta: Vector2 in [Vector2(2560, 0), Vector2(0, -2560), Vector2(-3000, 1500), Vector2(1800, 2200)]:
		var pip := CabinetScreenHud.compass_edge_pip(delta, inner)
		var rel := pip - inner.get_center()
		assert_float(rel.normalized().dot(delta.normalized())).is_greater(0.9999)
		assert_bool(inner.grow(-1.4).has_point(pip) or inner.grow(-1.0).has_point(pip)).is_true()
		assert_bool(absf(rel.x) >= inner.size.x * 0.5 - 1.6 or absf(rel.y) >= inner.size.y * 0.5 - 1.6).is_true()
	var east := CabinetScreenHud.compass_edge_pip(Vector2(2560, 0), inner)
	assert_vector(east).is_equal_approx(inner.get_center() + Vector2(inner.size.x * 0.5 - 1.5, 0), Vector2(0.01, 0.01))


# --- Acolytes ---------------------------------------------------------------------------------

func test_a_mining_acolyte_flies_to_the_nearest_geode_and_lances_it() -> void:
	var s := _stage()
	s.acolyte_mine = true
	_start(s)
	var v := world.vigil.pos
	var geode := world.geodes.add_geode(v + Vector2(600, 600), 0)
	var a := world.acolytes.spawn(v + Vector2(600, 1000))
	var d0 := world.torus.distance(a.pos, geode.pos)
	for i in 120:
		world.acolytes.tick(DT)
	assert_float(world.torus.distance(a.pos, geode.pos)).is_less(d0)
	assert_bool(a.mining).is_true()
	var hits := 0
	for i in 1200:
		world.acolytes.tick(DT)
		world.time += DT
		if geode.hits_on_face > 0 or geode.faces_left < geode.faces:
			hits += 1
			break
	assert_int(hits).is_greater(0)


func test_without_the_flag_an_idle_acolyte_does_not_mine() -> void:
	_start(_stage())
	var v := world.vigil.pos
	world.geodes.add_geode(v + Vector2(600, 600), 0)
	var a := world.acolytes.spawn(v + Vector2(600, 1000))
	for i in 60:
		world.acolytes.tick(DT)
	assert_bool(a.mining).is_false()


func test_an_acolyte_entering_the_view_holds_fire_for_the_entry_hold() -> void:
	_start(_stage())
	var v := world.vigil.pos
	var a := world.acolytes.spawn(v + Vector2(0, -300))     # off view (view half-height is 128), inside engage range
	a.cycle = 0.01
	world.acolytes.tick(DT)
	assert_bool(a.in_view).is_false()
	a.pos = v + Vector2(0, -100)                            # now in view
	world.acolytes.tick(DT)
	assert_float(a.hold).is_greater(0.9)
	assert_bool(world.acolytes.telling(a)).is_false()
	var shots_before := world.shots.shots.size()
	for i in int((t.acolyte_enter_hold_s - 0.1) / DT):
		world.acolytes.tick(DT)
	assert_int(world.shots.shots.size()).is_equal(shots_before)
	assert_float(a.cycle).is_greater_equal(t.acolyte_tell)
