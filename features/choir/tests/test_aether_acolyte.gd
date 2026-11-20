extends GdUnitTestSuite
## AetherAcolyte (PM-02 Dark Throat): lantern-scaled detection, post leash, acquisition loss, turret
## lag, the tell then the shot (only inside range), 6 lance hits to die, Charge interception, score.

const ACOLYTE := "res://features/choir/aether_acolyte.tscn"
const STATS := "res://data/choir/acolyte.tres"
const VIGIL := "res://features/vigil/vigil.tscn"
const CHARGE := "res://features/charges/null_iron_charge.tscn"
const CHARGE_STATS := "res://data/charges/charge.tres"
const DT := 1.0 / 60.0
const WORLD := Vector2(1920, 720)
const POST := Vector2(500, 400)

var holder: Node2D
var torus: Torus
var vigil: Vigil
var cues: Array = []


func before_test() -> void:
	SettingsService.persist = false
	cues = []
	holder = auto_free(Node2D.new())
	add_child(holder)
	torus = Torus.new(WORLD)
	vigil = (load(VIGIL) as PackedScene).instantiate() as Vigil
	holder.add_child(vigil)
	vigil.set_physics_process(false)
	vigil.global_position = POST + Vector2(900, 0)


func after_test() -> void:
	SettingsService.persist = true


func _record(id: StringName, _db: float = 0.0) -> void:
	cues.append(id)


func _acolyte() -> AetherAcolyte:
	var a: AetherAcolyte = (load(ACOLYTE) as PackedScene).instantiate()
	a.configure(load(STATS), torus, POST, vigil, vigil.lantern)
	a.sfx = _record
	a.shot_parent = holder
	holder.add_child(a)
	a.set_physics_process(false)
	return a


func _run(a: AetherAcolyte, ticks: int) -> void:
	for _t in ticks:
		a.step(DT)


func _shots() -> int:
	return holder.get_children().filter(func(n: Node) -> bool: return n is AcolyteShot).size()


func test_detection_radius_follows_the_lantern() -> void:
	var a := _acolyte()
	vigil.lantern.is_up = true
	assert_float(a.detect_radius()).is_equal_approx(308.0, 0.01)
	vigil.lantern.is_up = false
	assert_float(a.detect_radius()).is_equal_approx(44.0, 0.01)


func test_detects_inside_the_scaled_radius_only() -> void:
	var a := _acolyte()
	vigil.global_position = POST + Vector2(300, 0)
	vigil.lantern.is_up = true
	a.step(DT)
	assert_bool(a.detecting).is_true()
	vigil.lantern.is_up = false                     # running dark: 44 px
	a.step(DT)
	assert_bool(a.detecting).is_false()
	vigil.global_position = POST + Vector2(40, 0)
	a.step(DT)
	assert_bool(a.detecting).is_true()


func test_keeps_tracking_for_the_acquisition_loss_time() -> void:
	var a := _acolyte()
	vigil.global_position = POST + Vector2(200, 0)
	a.step(DT)
	assert_bool(a.tracking).is_true()
	vigil.global_position = POST + Vector2(900, 0)
	_run(a, 60)                                     # 1.0 s later
	assert_bool(a.detecting).is_false()
	assert_bool(a.tracking).is_true()
	_run(a, 90)                                     # 2.5 s: past 2.2 s
	assert_bool(a.tracking).is_false()


func test_stays_within_the_post_leash() -> void:
	var a := _acolyte()
	vigil.global_position = POST + Vector2(250, 0)
	for _i in 300:
		a.step(DT)
		assert_float(torus.distance(a.global_position, POST)).is_less_equal(40.0 + 0.01)
	assert_float(torus.distance(a.global_position, POST)).is_greater(30.0)   # it drifted toward the Vigil
	vigil.global_position = POST + Vector2(900, 0)
	_run(a, 600)
	assert_float(torus.distance(a.global_position, POST)).is_less(1.0)      # and came home


func test_turret_aim_lags_behind_the_vigil() -> void:
	var a := _acolyte()
	a.aim = Vector2.RIGHT
	vigil.global_position = POST + Vector2(0, 200)  # straight below
	a.step(DT)
	assert_float(absf(a.aim.angle_to(Vector2.DOWN))).is_greater(0.5)         # not there yet
	_run(a, 90)                                                              # 1.5 s = 6 lag constants
	assert_float(absf(a.aim.angle_to(Vector2.DOWN))).is_less(0.15)


func test_fires_only_after_the_tell_and_inside_range() -> void:
	var a := _acolyte()
	vigil.global_position = POST + Vector2(250, 0)
	a.step(DT)
	assert_array(cues).contains([&"acolyte_tell"])
	assert_int(a.shots_fired).is_equal(0)
	_run(a, 19)                                      # 20 ticks in: still telling (21 needed)
	assert_int(a.shots_fired).is_equal(0)
	_run(a, 2)
	assert_int(a.shots_fired).is_equal(1)
	assert_array(cues).contains([&"acolyte_fire"])
	assert_int(_shots()).is_equal(1)
	_run(a, 60)                                      # the cycle (1.8 s) is not over
	assert_int(a.shots_fired).is_equal(1)
	_run(a, 60)
	assert_int(a.shots_fired).is_equal(2)


func test_no_shot_beyond_range_even_when_detected() -> void:
	var a := _acolyte()
	vigil.lantern.is_up = true
	vigil.global_position = POST + Vector2(320, 0)   # outside the 308 detection and the 300 range
	_run(a, 200)
	assert_int(a.shots_fired).is_equal(0)
	vigil.global_position = POST + Vector2(305, 0)   # detected (<= 308) but beyond the 300 px range
	_run(a, 3)
	assert_bool(a.detecting).is_true()
	assert_int(a.shots_fired).is_equal(0)


func test_a_tell_is_cancelled_when_the_vigil_goes_dark() -> void:
	var a := _acolyte()
	vigil.global_position = POST + Vector2(200, 0)
	_run(a, 5)
	assert_float(a.tell_left).is_greater_equal(0.0)
	vigil.lantern.is_up = false
	_run(a, 60)
	assert_int(a.shots_fired).is_equal(0)


func test_shot_hurts_the_vigil_hull() -> void:
	var a := _acolyte()
	var s := a.fire()
	var hp := vigil.health.current_hp
	s.resolve_contact(vigil.hurtbox)
	assert_int(vigil.health.current_hp).is_equal(hp - 1)
	assert_bool(s.spent).is_true()


func test_shot_flies_and_expires() -> void:
	var a := _acolyte()
	a.aim = Vector2.RIGHT
	var s := a.fire()
	var x0 := s.global_position.x
	s.advance(0.5)
	assert_float(s.global_position.x - x0).is_equal_approx(120.0, 0.5)
	s.advance(1.1)
	assert_bool(s.spent).is_true()


func test_dies_after_six_hits_and_goes_inert() -> void:
	var a := _acolyte()
	for i in 5:
		a.hurtbox.receive_hit(HitInfo.make(1, 77, i))
		assert_bool(a.dead).is_false()
	a.hurtbox.receive_hit(HitInfo.make(1, 77, 5))
	assert_bool(a.dead).is_true()
	assert_array(cues).contains([&"acolyte_die"])
	var shots := a.shots_fired
	vigil.global_position = POST + Vector2(100, 0)
	_run(a, 120)
	assert_int(a.shots_fired).is_equal(shots)
	assert_int((load(STATS) as AcolyteStats).score).is_equal(500)


func test_it_is_on_the_choir_hurtbox_layer_and_intercepts_a_charge() -> void:
	var a := _acolyte()
	assert_int(a.hurtbox.collision_layer).is_equal(PhysicsLayers.bit(PhysicsLayers.CHOIR_HURTBOX))
	var c: NullIronCharge = (load(CHARGE) as PackedScene).instantiate()
	c.launch(load(CHARGE_STATS), torus, POST + Vector2(-50, 0), Vector2.RIGHT, null)
	c.sfx = _record
	holder.add_child(c)
	c.set_physics_process(false)
	c.resolve_contact(a.hurtbox)
	assert_int(c.outcome).is_equal(NullIronCharge.Outcome.LOST)
	assert_array(cues).contains([&"charge_lost"])


func test_reduced_motion_holds_the_sway_still() -> void:
	var a := _acolyte()
	SettingsService.set_value(&"reduced_motion", true)
	a.view._time = 0.0
	var p0 := a.view.censer_pos()
	a.view._time = 1.0
	assert_vector(a.view.censer_pos()).is_equal(p0)
	SettingsService.set_value(&"reduced_motion", false)
