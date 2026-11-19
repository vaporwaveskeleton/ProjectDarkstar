extends GdUnitTestSuite
## OublietteGrub (SYS-001 §3): seek via the ShardField hooks, steal, carry along the route, deposit,
## flee the lantern (not while carrying), death drop + keening, lance damage, determinism, torus.

const GRUB := "res://features/choir/oubliette_grub.tscn"
const STATS := "res://data/choir/grub.tres"
const SEPULCHRE := "res://features/sepulchre/sepulchre.tscn"
const SEP_STATS := "res://data/sepulchre/sepulchre.tres"
const FIELD := "res://features/charges/shard_field.tscn"
const DT := 1.0 / 60.0
const WORLD := Vector2(1920, 720)
const SEP_AT := Vector2(1480, 400)
const ROUTE := [Vector2(900, 560), Vector2(1150, 600), Vector2(1360, 500)]

var holder: Node2D
var torus: Torus
var field: ShardField
var sep: Sepulchre
var lantern: Node2D
var cues: Array = []


func before_test() -> void:
	SettingsService.persist = false
	cues = []
	holder = auto_free(Node2D.new())
	add_child(holder)
	torus = Torus.new(WORLD)
	field = (load(FIELD) as PackedScene).instantiate()
	holder.add_child(field)
	field.set_physics_process(false)
	field.setup(torus)
	sep = (load(SEPULCHRE) as PackedScene).instantiate()
	sep.configure(load(SEP_STATS), torus, SEP_AT)
	sep.sfx = _record
	holder.add_child(sep)
	sep.set_physics_process(false)
	lantern = Node2D.new()
	holder.add_child(lantern)
	lantern.global_position = Vector2(100, 100)


func after_test() -> void:
	SettingsService.persist = true


func _record(id: StringName, _db: float = 0.0) -> void:
	cues.append(id)


func _route() -> PackedVector2Array:
	return PackedVector2Array(ROUTE)


func _grub(at: Vector2, index: int = 0, p_field: ShardField = null, p_sep: Sepulchre = null) -> OublietteGrub:
	var g: OublietteGrub = (load(GRUB) as PackedScene).instantiate()
	g.configure(load(STATS), torus, p_field if p_field else field, p_sep if p_sep else sep, lantern, _route(), index, at)
	g.sfx = _record
	holder.add_child(g)
	g.set_physics_process(false)
	return g


func _run(g: OublietteGrub, ticks: int) -> void:
	for _t in ticks:
		g.step(DT)


func _run_until(g: OublietteGrub, cond: Callable, limit: int) -> int:
	for t in limit:
		if cond.call():
			return t
		g.step(DT)
	return -1


func test_data_matches_sys001() -> void:
	var s: GrubStats = load(STATS)
	assert_str(s.ds_namespace).is_equal("ds_choir.grub")
	assert_int(s.hp).is_equal(4)
	assert_float(s.carry_speed_px_s).is_equal(130.0)
	assert_float(s.flee_speed_px_s).is_equal(190.0)
	assert_float(s.seek_speed_px_s).is_equal(160.0)
	assert_float(s.flee_radius_px).is_equal(110.0)
	assert_float(s.respawn_s).is_equal(6.0)
	assert_int(s.score).is_equal(150)


func test_hurtbox_is_a_biting_choir_hurtbox_with_four_hp() -> void:
	var g := _grub(Vector2(600, 300))
	assert_int(g.hurtbox.collision_layer).is_equal(PhysicsLayers.bit(PhysicsLayers.CHOIR_HURTBOX))
	assert_bool(g.hurtbox.bites).is_true()
	assert_bool(LanceProjectile.can_bite(g.hurtbox)).is_true()
	assert_int(g.health.max_hp).is_equal(4)


func test_idles_round_the_sepulchre_without_glass() -> void:
	var g := _grub(SEP_AT + Vector2(60, 0))
	_run(g, 120)
	assert_int(g.state).is_equal(OublietteGrub.State.IDLE)
	assert_float(torus.distance(g.home(), SEP_AT)).is_less(130.0)


func test_seeks_the_nearest_free_shard_on_a_query_tick_and_claims_it() -> void:
	var near := field.spawn(Vector2(1300, 400), Vector2.ZERO)
	var far := field.spawn(Vector2(600, 400), Vector2.ZERO)
	var g := _grub(Vector2(1400, 400))
	_run(g, 6)   # one query interval (6 ticks ✱)
	assert_int(g.shard).is_equal(near)
	assert_bool(field.is_claimed(near)).is_true()
	assert_bool(field.is_claimed(far)).is_false()
	assert_int(g.state).is_equal(OublietteGrub.State.SEEK)
	assert_int(field.free_count()).is_equal(1)


func test_queries_only_once_per_interval() -> void:
	field.spawn(Vector2(1300, 400), Vector2.ZERO)
	var g := _grub(Vector2(1400, 400), 1)   # index 1: due when (tick + 1) % 6 == 0, i.e. tick 5
	_run(g, 4)
	assert_int(g.shard).is_equal(ShardField.NONE)
	_run(g, 1)
	assert_int(g.shard).is_not_equal(ShardField.NONE)


func test_seek_speed_converges_to_160() -> void:
	field.spawn(Vector2(400, 400), Vector2.ZERO)
	var g := _grub(Vector2(1400, 400))
	_run(g, 90)
	assert_int(g.state).is_equal(OublietteGrub.State.SEEK)
	assert_float(g.velocity.length()).is_equal_approx(160.0, 1.0)


func test_steals_one_shard_then_carries_along_the_route_and_deposits() -> void:
	var s := field.spawn(Vector2(800, 500), Vector2.ZERO)
	field.spawn(Vector2(806, 500), Vector2.ZERO)   # a second shard right next to it
	var g := _grub(Vector2(760, 500))
	var t := _run_until(g, func() -> bool: return g.carrying, 120)
	assert_int(t).is_greater(0)
	assert_bool(field.is_alive(s)).is_false()
	assert_int(field.live_count()).is_equal(1)   # carries 1 shard only
	assert_int(field.stolen_total).is_equal(1)
	assert_array(cues).contains([&"grub_steal"])
	assert_int(g.route_at).is_equal(0)   # joins the route at its nearest waypoint
	# carry speed converges to 130
	_run(g, 90)
	assert_int(g.state).is_equal(OublietteGrub.State.CARRY)
	assert_float(g.velocity.length()).is_equal_approx(130.0, 1.0)
	var passed := []
	var dep := _run_until(g, func() -> bool:
		if not passed.has(g.route_at):
			passed.append(g.route_at)
		return sep.deposited_shards > 0, 60 * 20)
	assert_int(dep).is_greater(0)
	assert_array(passed).contains([2, 3])   # walked the rest of the route in order before the deposit
	assert_bool(g.carrying).is_false()
	assert_int(g.deposits).is_equal(1)
	assert_array(cues).contains([&"segment_deposit"])


func test_flees_the_lantern_but_not_while_carrying() -> void:
	var g := _grub(Vector2(600, 300))
	lantern.global_position = Vector2(650, 300)   # 50 px: inside the 110 px flee radius
	_run(g, 10)
	assert_int(g.state).is_equal(OublietteGrub.State.FLEE)
	assert_float(g.velocity.x).is_less(0.0)   # away from the lantern
	for _t in 90:   # a lantern that keeps up: the flee speed converges to 190
		lantern.global_position = g.home() + Vector2(40, 0)
		g.step(DT)
	assert_int(g.state).is_equal(OublietteGrub.State.FLEE)
	assert_float(g.velocity.length()).is_equal_approx(190.0, 2.0)
	# outside the radius: no fear
	lantern.global_position = g.home() + Vector2(200, 0)
	_run(g, 1)
	assert_int(g.state).is_not_equal(OublietteGrub.State.FLEE)
	# carrying: devotion beats fear
	g.carrying = true
	g.route_at = 0
	lantern.global_position = g.home() + Vector2(40, 0)
	_run(g, 1)
	assert_int(g.state).is_equal(OublietteGrub.State.CARRY)


func test_death_while_carrying_drops_the_shard_and_keens() -> void:
	field.spawn(Vector2(800, 500), Vector2.ZERO)
	var g := _grub(Vector2(760, 500))
	_run_until(g, func() -> bool: return g.carrying, 120)
	assert_int(field.live_count()).is_equal(0)
	cues.clear()
	g.die()
	assert_bool(g.dead).is_true()
	assert_int(field.live_count()).is_equal(1)
	var i := field.live_indices()[0]
	assert_float(torus.distance(field.positions[i], g.home())).is_less(0.01)
	assert_bool(field.is_claimed(i)).is_false()
	assert_array(cues).is_equal([&"grub_keen", &"grub_die"])
	g.die()   # once only
	assert_int(field.live_count()).is_equal(1)
	var ticks_at_death := g.ticks
	_run(g, 10)   # a dead Grub is inert
	assert_int(g.ticks).is_equal(ticks_at_death)


func test_death_while_seeking_releases_the_claim_without_keening() -> void:
	var s := field.spawn(Vector2(400, 400), Vector2.ZERO)
	var g := _grub(Vector2(1400, 400))
	_run(g, 6)
	assert_bool(field.is_claimed(s)).is_true()
	cues.clear()
	g.die()
	assert_bool(field.is_claimed(s)).is_false()
	assert_array(cues).is_equal([&"grub_die"])


func test_four_lance_hits_kill_it() -> void:
	var g := _grub(Vector2(600, 300))
	for w in 3:
		g.hurtbox.receive_hit(HitInfo.make(1, 77, w + 1, &"arc_lance"))
	assert_bool(g.dead).is_false()
	assert_int(g.health.current_hp).is_equal(1)
	g.hurtbox.receive_hit(HitInfo.make(1, 77, 4, &"arc_lance"))
	assert_bool(g.dead).is_true()
	assert_bool(g.visible).is_false()


func test_lost_claim_when_the_vigil_collects_the_shard() -> void:
	var s := field.spawn(Vector2(400, 400), Vector2.ZERO)
	var g := _grub(Vector2(1400, 400))
	_run(g, 6)
	assert_int(g.shard).is_equal(s)
	field._remove(s)   # what a magnet pickup does
	_run(g, 1)
	assert_int(g.shard).is_equal(ShardField.NONE)
	assert_int(g.state).is_equal(OublietteGrub.State.IDLE)


func test_wraps_the_short_way_across_the_seam() -> void:
	field.spawn(Vector2(30, 300), Vector2.ZERO)
	var g := _grub(Vector2(1890, 300))
	var t := _run_until(g, func() -> bool: return g.carrying, 120)
	assert_int(t).is_greater(0)
	assert_float(g.global_position.x).is_greater(1900.0)   # crossed rightwards (not wrapped here)
	assert_float(g.home().x).is_less(60.0)                  # torus position is across the seam


func test_nearest_waypoint_is_torus_aware() -> void:
	var r := PackedVector2Array([Vector2(10, 10), Vector2(960, 10)])
	assert_int(OublietteGrub.nearest_waypoint(torus, r, Vector2(1900, 10))).is_equal(0)
	assert_int(OublietteGrub.nearest_waypoint(torus, r, Vector2(900, 10))).is_equal(1)


func test_same_inputs_give_the_same_path() -> void:
	var a := _sim_once()
	var b := _sim_once()
	assert_array(a).is_equal(b)
	assert_int(a.size()).is_equal(4)


## Builds a fresh field + Sepulchre + Grub, scatters shards from a seeded `loot` stream, runs 10 s.
func _sim_once() -> Array:
	var f: ShardField = (load(FIELD) as PackedScene).instantiate()
	holder.add_child(f)
	f.set_physics_process(false)
	f.setup(torus)
	var rng := RunSeed.new(146).stream(RunSeed.STREAM_LOOT)
	for _k in 5:
		f.spawn(Vector2(rng.randf() * WORLD.x, rng.randf() * WORLD.y), Vector2.ZERO)
	var s2: Sepulchre = (load(SEPULCHRE) as PackedScene).instantiate()
	s2.configure(load(SEP_STATS), torus, SEP_AT)
	s2.sfx = _record
	holder.add_child(s2)
	var g := _grub(SEP_AT + Vector2(60, 0), 2, f, s2)
	for _t in 600:
		f.step(DT)
		g.step(DT)
	return [g.home(), g.velocity, s2.deposited_shards, f.live_count()]
