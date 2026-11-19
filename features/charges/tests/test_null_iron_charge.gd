extends GdUnitTestSuite
## NullIronCharge (GDD §8.3, SYS-001 §1.4): speed, homing turn rate, life and gutter, interception
## by Grub and geode hurtboxes, hitting the target (the Sepulchre), torus-aware steering.

const SCENE := "res://features/charges/null_iron_charge.tscn"
const STATS := "res://data/charges/charge.tres"
const SEPULCHRE := "res://features/sepulchre/sepulchre.tscn"
const DT := 1.0 / 60.0
const WORLD := Vector2(1920, 720)

var holder: Node2D
var torus: Torus
var cues: Array = []


func before_test() -> void:
	SettingsService.persist = false
	holder = auto_free(Node2D.new())
	add_child(holder)
	torus = Torus.new(WORLD)
	cues = []


func after_test() -> void:
	SettingsService.persist = true


func _record(id: StringName, _db: float = 0.0) -> void:
	cues.append(id)


func _charge(at: Vector2, dir: Vector2, target: HurtboxComponent = null, t: Torus = null) -> NullIronCharge:
	var c: NullIronCharge = (load(SCENE) as PackedScene).instantiate()
	c.launch(load(STATS), t, at, dir, target)
	c.sfx = _record
	holder.add_child(c)
	c.set_physics_process(false)
	return c


## A bare hurtbox on `layer` (no health), placed at `at`.
func _hurtbox(layer: int, at: Vector2 = Vector2.ZERO) -> HurtboxComponent:
	var h: HurtboxComponent = auto_free(HurtboxComponent.new())
	holder.add_child(h)
	h.collision_layer = PhysicsLayers.bit(layer)
	h.global_position = at
	return h


func test_data_matches_sys001() -> void:
	var s: ChargeStats = load(STATS)
	assert_str(s.ds_namespace).is_equal("ds_charges.charge")
	assert_float(s.speed_px_s).is_equal(210.0)
	assert_float(s.turn_authority_s).is_equal(1.6)
	assert_float(s.life_s).is_equal(6.0)
	assert_int(s.hp).is_equal(1)
	assert_int(s.grub_contact_damage).is_equal(1)
	assert_int(s.geode_contact_damage).is_equal(1)
	assert_int(s.target_hits).is_equal(1)
	assert_float(s.turn_rate()).is_equal_approx(PI / 1.6, 1e-6)


func test_layers_hit_world_and_choir_hurtboxes() -> void:
	var c := _charge(Vector2.ZERO, Vector2.RIGHT)
	assert_int(c.collision_layer).is_equal(PhysicsLayers.bit(PhysicsLayers.VIGIL_SHOTS))
	assert_int(c.collision_mask).is_equal(PhysicsLayers.mask([PhysicsLayers.WORLD, PhysicsLayers.CHOIR_HURTBOX]))
	assert_bool(c.monitorable).is_false()


func test_flies_straight_at_speed_without_a_target() -> void:
	var c := _charge(Vector2(100, 100), Vector2.RIGHT)
	for _t in 60:
		c.advance(DT)
	assert_vector(c.global_position).is_equal_approx(Vector2(310, 100), Vector2(0.01, 0.01))
	assert_bool(c.is_flying()).is_true()


func test_turn_rate_is_limited_by_turn_authority() -> void:
	# target straight behind: each tick turns exactly PI / 1.6 * dt
	var target := _hurtbox(PhysicsLayers.WORLD, Vector2(-500, 0.5))
	var c := _charge(Vector2.ZERO, Vector2.RIGHT, target)
	c.advance(DT)
	assert_float(absf(c.direction.angle())).is_equal_approx(PI / 1.6 * DT, 1e-4)
	assert_float(c.direction.length()).is_equal_approx(1.0, 1e-5)


func test_steer_turns_through_half_a_circle_in_turn_authority() -> void:
	var rate := PI / 1.6
	var d := Vector2.RIGHT
	for _t in 96:   # 1.6 s
		d = NullIronCharge.steer(d, Vector2(-1, 0.001), rate * DT)
	assert_float(d.x).is_less(-0.99)
	# a small error is corrected inside one tick, never overshot
	var e := NullIronCharge.steer(Vector2.RIGHT, Vector2.from_angle(0.01), rate * DT)
	assert_float(e.angle()).is_equal_approx(0.01, 1e-5)
	assert_vector(NullIronCharge.steer(Vector2.UP, Vector2.ZERO, 1.0)).is_equal(Vector2.UP)


func test_gutters_at_life_and_counts_as_spent() -> void:
	var c := _charge(Vector2.ZERO, Vector2.RIGHT)
	for _t in 359:
		assert_bool(c.advance(DT)).is_true()
	assert_bool(c.advance(DT)).is_false()   # 360 ticks = 6.0 s
	assert_int(c.outcome).is_equal(NullIronCharge.Outcome.GUTTERED)
	assert_array(cues).is_equal([&"charge_gutter"])
	assert_bool(c.advance(DT)).is_false()


func test_grub_contact_intercepts_and_plays_charge_lost() -> void:
	var grub := _hurtbox(PhysicsLayers.CHOIR_HURTBOX)
	var c := _charge(Vector2.ZERO, Vector2.RIGHT)
	c.resolve_contact(grub)
	assert_int(c.outcome).is_equal(NullIronCharge.Outcome.LOST)
	assert_array(cues).is_equal([&"charge_lost"])
	c.resolve_contact(grub)   # spent: nothing more
	assert_array(cues).is_equal([&"charge_lost"])


func test_geode_contact_intercepts_without_hurting_the_geode() -> void:
	var g: SectorGeode = (load("res://features/charges/sector_geode.tscn") as PackedScene).instantiate()
	g.configure(load("res://data/charges/geode.tres"), 0, Vector2(50, 50), torus, null, RunSeed.new(1).stream(RunSeed.STREAM_LOOT))
	holder.add_child(g)
	var hp_before := g.health.current_hp
	var c := _charge(Vector2.ZERO, Vector2.RIGHT)
	c.resolve_contact(g.hurtbox)
	assert_int(c.outcome).is_equal(NullIronCharge.Outcome.LOST)
	assert_int(g.health.current_hp).is_equal(hp_before)
	assert_array(cues).is_equal([&"charge_lost"])


func test_non_hurtbox_areas_are_ignored() -> void:
	var a: Area2D = auto_free(Area2D.new())
	holder.add_child(a)
	var c := _charge(Vector2.ZERO, Vector2.RIGHT)
	c.resolve_contact(a)
	assert_bool(c.is_flying()).is_true()


func test_hitting_the_sepulchre_knocks_a_segment_off() -> void:
	var sep: Sepulchre = (load(SEPULCHRE) as PackedScene).instantiate()
	sep.configure(load("res://data/sepulchre/sepulchre.tres"), torus, Vector2(300, 0))
	sep.sfx = _record
	holder.add_child(sep)
	sep.segments = 4
	var c := _charge(Vector2.ZERO, Vector2.RIGHT, sep.hurtbox, torus)
	c.resolve_contact(sep.hurtbox)
	assert_int(c.outcome).is_equal(NullIronCharge.Outcome.HIT)
	assert_int(sep.segments).is_equal(3)
	assert_int(sep.charge_hits).is_equal(1)
	assert_array(cues).is_equal([&"segment_knocked", &"charge_hit"])


func test_homing_takes_the_short_way_round_the_torus() -> void:
	# Charge just right of the left seam, target near the right edge: shortest way is left (-x).
	var target := _hurtbox(PhysicsLayers.WORLD, Vector2(1700, 100))
	var c := _charge(Vector2(50, 100), Vector2.UP, target, torus)
	for _t in 60:
		c.advance(DT)
	assert_float(c.direction.x).is_less(-0.5)
	assert_float(c.global_position.x).is_less(50.0)
	# trail points are torus positions
	for p in c.trail:
		assert_bool(p.x >= 0.0 and p.x < WORLD.x).is_true()
