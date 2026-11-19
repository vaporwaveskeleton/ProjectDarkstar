extends GdUnitTestSuite
## Sepulchre phases 0–1 (SYS-001 §2): deposits → segments (3 shards = 1 segment, 20 cap), Charge
## hits knock 1 off (bites = false: the lance does nothing), torus deposit reach, sandbox layout.

const SCENE := "res://features/sepulchre/sepulchre.tscn"
const STATS := "res://data/sepulchre/sepulchre.tres"
const SANDBOX := "res://data/sepulchre/procession_sandbox.tres"
const WORLD := Vector2(1920, 720)

var holder: Node2D
var torus: Torus
var sep: Sepulchre
var cues: Array = []


func before_test() -> void:
	SettingsService.persist = false
	cues = []
	holder = auto_free(Node2D.new())
	add_child(holder)
	torus = Torus.new(WORLD)
	sep = (load(SCENE) as PackedScene).instantiate()
	sep.configure(load(STATS), torus, Vector2(1480, 400))
	sep.sfx = _record
	holder.add_child(sep)


func after_test() -> void:
	SettingsService.persist = true


func _record(id: StringName, _db: float = 0.0) -> void:
	cues.append(id)


func test_data_matches_sys001_and_pm() -> void:
	var s: SepulchreStats = load(STATS)
	assert_str(s.ds_namespace).is_equal("ds_sepulchre.sepulchre")
	assert_int(s.shards_per_segment).is_equal(3)
	assert_int(s.segments_total).is_equal(20)
	assert_int(s.segments_knocked_per_hit).is_equal(1)
	assert_int(s.score_per_segment_knocked).is_equal(500)
	var b: ProcessionSandboxStats = load(SANDBOX)
	assert_str(b.ds_namespace).is_equal("ds_sepulchre.sandbox")
	assert_int(b.grub_count).is_equal(4)
	assert_int(b.route.size()).is_equal(3)


func test_starts_in_phase_0_seed() -> void:
	assert_int(sep.phase).is_equal(Sepulchre.Phase.SEED)
	assert_int(sep.segments).is_equal(0)
	assert_bool(sep.is_complete()).is_false()


func test_three_shards_make_one_segment_and_enter_procession() -> void:
	sep.deposit()
	sep.deposit()
	assert_int(sep.segments).is_equal(0)
	assert_int(sep.phase).is_equal(Sepulchre.Phase.SEED)
	sep.deposit()
	assert_int(sep.segments).is_equal(1)
	assert_int(sep.shard_points).is_equal(0)
	assert_int(sep.phase).is_equal(Sepulchre.Phase.PROCESSION)
	assert_int(sep.deposited_shards).is_equal(3)
	assert_array(cues).is_equal([&"segment_deposit", &"segment_deposit", &"segment_deposit"])


func test_sixty_shards_complete_twenty_segments_and_cap() -> void:
	for _k in 60:
		sep.deposit()
	assert_int(sep.segments).is_equal(20)
	assert_bool(sep.is_complete()).is_true()
	for _k in 5:
		sep.deposit()
	assert_int(sep.segments).is_equal(20)
	assert_int(sep.deposited_shards).is_equal(65)


func test_charge_hit_knocks_one_segment_off() -> void:
	for _k in 6:
		sep.deposit()
	cues.clear()
	sep.hurtbox.receive_hit(HitInfo.make(1, 9, 1, NullIronCharge.KIND))
	assert_int(sep.segments).is_equal(1)
	assert_int(sep.segments_knocked).is_equal(1)
	assert_int(sep.score).is_equal(500)
	assert_int(sep.charge_hits).is_equal(1)
	assert_array(cues).is_equal([&"segment_knocked"])
	sep.hurtbox.receive_hit(HitInfo.make(1, 9, 2, NullIronCharge.KIND))
	assert_int(sep.segments).is_equal(0)
	assert_int(sep.phase).is_equal(Sepulchre.Phase.SEED)


func test_charge_hit_in_phase_0_knocks_nothing() -> void:
	assert_int(sep.take_charge_hit()).is_equal(0)
	assert_int(sep.segments).is_equal(0)
	assert_int(sep.charge_hits).is_equal(1)
	assert_int(sep.score).is_equal(0)
	assert_array(cues).is_empty()


func test_lance_does_not_bite_but_a_charge_does() -> void:
	for _k in 9:
		sep.deposit()
	assert_bool(sep.hurtbox.bites).is_false()
	assert_int(sep.hurtbox.collision_layer).is_equal(PhysicsLayers.bit(PhysicsLayers.WORLD))
	assert_bool(LanceProjectile.can_bite(sep.hurtbox)).is_false()
	var shot: LanceProjectile = (load("res://features/arc_lance/lance_projectile.tscn") as PackedScene).instantiate()
	shot.launch(load("res://data/arc_lance/arc_lance.tres"), Vector2.ZERO, Vector2.RIGHT, 5)
	holder.add_child(shot)
	shot.set_physics_process(false)
	assert_bool(shot.register_hit(sep.hurtbox)).is_true()   # the shot is used up …
	assert_int(sep.segments).is_equal(3)                     # … and does nothing
	# other hit kinds do nothing either
	sep.hurtbox.receive_hit(HitInfo.make(1, 5, 1, &"arc_lance"))
	assert_int(sep.segments).is_equal(3)
	sep.hurtbox.receive_hit(HitInfo.make(1, 6, 1, NullIronCharge.KIND))
	assert_int(sep.segments).is_equal(2)


func test_deposit_reach_wraps_the_seam() -> void:
	var s2: Sepulchre = (load(SCENE) as PackedScene).instantiate()
	s2.configure(load(STATS), torus, Vector2(5, 400))
	holder.add_child(s2)
	assert_bool(s2.in_deposit_reach(Vector2(1915, 400))).is_true()
	assert_bool(s2.in_deposit_reach(Vector2(60, 400))).is_false()
	assert_vector(s2.home).is_equal(Vector2(5, 400))
	var s3: Sepulchre = (load(SCENE) as PackedScene).instantiate()
	s3.configure(load(STATS), torus, Vector2(-10, 730))
	holder.add_child(s3)
	assert_vector(s3.home).is_equal(Vector2(1910, 10))


func test_sandbox_layout_is_off_the_spawn_view_and_wrapped() -> void:
	var b: ProcessionSandboxStats = load(SANDBOX)
	var spawn := Vector2(320, 180)   # sector_stub VigilSpawn
	var view_half := Vector2(320, 180)
	var d := torus.delta(spawn, b.sepulchre_pos)
	assert_bool(absf(d.x) > view_half.x or absf(d.y) > view_half.y).is_true()
	for p in b.route:
		var dp := torus.delta(spawn, p)
		assert_bool(absf(dp.x) > view_half.x or absf(dp.y) > view_half.y).is_true()
	var ps := ProcessionSandbox.new()
	ps.stats = b
	var r := ps.route_on(torus)
	assert_int(r.size()).is_equal(3)
	ps.free()
