extends GdUnitTestSuite
## ChargeLauncher: one Charge per press from the magazine (decrement), dry fire on empty, counts
## outcomes and frees spent Charges; VigilInput's deploy latch.

const STATS := "res://data/charges/charge.tres"
const MAG_STATS := "res://data/charges/charge_magazine.tres"
const DT := 1.0 / 60.0

var holder: Node2D
var magazine: ChargeMagazine
var launcher: ChargeLauncher
var cues: Array = []


func before_test() -> void:
	SettingsService.persist = false
	cues = []
	holder = auto_free(Node2D.new())
	add_child(holder)
	magazine = ChargeMagazine.new()
	magazine.stats = load(MAG_STATS)
	holder.add_child(magazine)
	launcher = ChargeLauncher.new()
	launcher.stats = load(STATS)
	launcher.magazine = magazine
	launcher.torus = Torus.new(Vector2(1920, 720))
	launcher.projectile_parent = holder
	launcher.sfx = _record
	holder.add_child(launcher)
	launcher.set_physics_process(false)


func after_test() -> void:
	SettingsService.persist = true


func _record(id: StringName, _db: float = 0.0) -> void:
	cues.append(id)


func test_empty_magazine_dry_fires() -> void:
	assert_object(launcher.fire(Vector2.ZERO, Vector2.RIGHT)).is_null()
	assert_int(launcher.dry_fires).is_equal(1)
	assert_int(launcher.fired).is_equal(0)
	assert_int(launcher.in_flight()).is_equal(0)
	assert_array(cues).is_equal([&"dry_fire"])


func test_fire_spends_one_charge_and_plays_charge_fire() -> void:
	magazine.try_add(3)
	var c := launcher.fire(Vector2(10, 20), Vector2.DOWN)
	assert_object(c).is_not_null()
	assert_int(magazine.count).is_equal(2)
	assert_int(launcher.in_flight()).is_equal(1)
	assert_object(c.get_parent()).is_same(holder)
	assert_vector(c.direction).is_equal(Vector2.DOWN)
	assert_bool(cues.has(&"charge_fire")).is_true()
	assert_bool(cues.has(&"dry_fire")).is_false()
	# the Charge got the launcher's cue sink
	c.set_physics_process(false)
	c.resolve_contact(_choir_hurtbox())
	assert_bool(cues.has(&"charge_lost")).is_true()


func test_magazine_runs_dry_after_its_charges() -> void:
	magazine.try_add(5)
	for k in 5:
		assert_object(launcher.fire(Vector2.ZERO, Vector2.RIGHT)).is_not_null()
	assert_int(magazine.count).is_equal(0)
	assert_object(launcher.fire(Vector2.ZERO, Vector2.RIGHT)).is_null()
	assert_int(launcher.dry_fires).is_equal(1)


func test_outcomes_are_counted_and_spent_charges_freed() -> void:
	magazine.try_add(3)
	var lost := launcher.fire(Vector2.ZERO, Vector2.RIGHT)
	var gutter := launcher.fire(Vector2.ZERO, Vector2.RIGHT)
	var flying := launcher.fire(Vector2.ZERO, Vector2.RIGHT)
	for c in [lost, gutter, flying]:
		(c as NullIronCharge).set_physics_process(false)
	lost.resolve_contact(_choir_hurtbox())
	for _t in 360:
		gutter.advance(DT)
	assert_int(launcher.lost()).is_equal(1)        # counted before the prune too
	assert_int(launcher.guttered()).is_equal(1)
	launcher.prune()
	assert_int(launcher.lost()).is_equal(1)
	assert_int(launcher.guttered()).is_equal(1)
	assert_int(launcher.hits()).is_equal(0)
	assert_int(launcher.in_flight()).is_equal(1)
	assert_int(launcher.flying.size()).is_equal(1)
	assert_bool(lost.is_queued_for_deletion()).is_true()
	assert_bool(flying.is_queued_for_deletion()).is_false()


func test_lost_charge_costs_half_composure_once_guttered_costs_nothing() -> void:
	# SYS-001 §1.5: Charge lost to an interceptor −0.5; a guttered Charge is not a row.
	var comp := auto_free(Composure.new()) as Composure
	comp.stats = load("res://data/composure/composure.tres")
	comp.sfx = Callable()
	holder.add_child(comp)
	comp.set_physics_process(false)
	launcher.composure = comp
	magazine.try_add(2)
	var lost := launcher.fire(Vector2.ZERO, Vector2.RIGHT)
	var gutter := launcher.fire(Vector2.ZERO, Vector2.RIGHT)
	for c in [lost, gutter]:
		(c as NullIronCharge).set_physics_process(false)
	lost.resolve_contact(_choir_hurtbox())
	for _t in 360:
		gutter.advance(DT)
	assert_float(comp.value).is_equal(10.0)   # applied when the launcher counts the outcome
	launcher.prune()
	assert_float(comp.value).is_equal(9.5)
	launcher.prune()
	assert_float(comp.value).is_equal(9.5)    # once per Charge


func test_magazine_try_spend() -> void:
	assert_bool(magazine.try_spend()).is_false()
	magazine.try_add(2)
	assert_bool(magazine.try_spend(3)).is_false()
	assert_int(magazine.count).is_equal(2)
	assert_bool(magazine.try_spend()).is_true()
	assert_int(magazine.count).is_equal(1)
	assert_bool(magazine.try_spend(0)).is_false()


func test_vigil_input_deploy_latch_is_consumed_once() -> void:
	var input: VigilInput = auto_free(VigilInput.new())
	input.read_devices = false
	assert_bool(input.consume_deploy()).is_false()
	input.deploy_requested = true
	assert_bool(input.consume_deploy()).is_true()
	assert_bool(input.consume_deploy()).is_false()


func _choir_hurtbox() -> HurtboxComponent:
	var h: HurtboxComponent = auto_free(HurtboxComponent.new())
	h.collision_layer = PhysicsLayers.bit(PhysicsLayers.CHOIR_HURTBOX)
	holder.add_child(h)
	return h
