extends GdUnitTestSuite
## M1 Lance bite (counterpart of the Cabinet's S4): muzzle star, visual-only recoil, impact flecks,
## and the chalk tick + lance_dull on a hurtbox the lance cannot bite. Cosmetic only, no RNG.
## Values come from data/arc_lance/arc_lance_fx.tres; test_data_matches_sys001 restates SYS-001 §9.

const VIGIL_SCENE := preload("res://features/vigil/vigil.tscn")
const FX_STATS := preload("res://data/arc_lance/arc_lance_fx.tres")
const DT := 1.0 / 60.0

var _holder: Node2D
var _vigil: Vigil
var _emitter: ArcLanceEmitter
var _fx: ArcLanceFx
var _recoil: LanceRecoil
var _visual: Node2D
var _calls: Array = []
var _saved_photo: Variant
var _saved_reduced: Variant
var _saved_muzzle: Variant
var _saved_persist: bool
var _saved_muted: bool


func before_test() -> void:
	_saved_muted = AudioService.muted_for_tests
	AudioService.muted_for_tests = true
	_saved_persist = SettingsService.persist
	SettingsService.persist = false   # never write the player's settings.cfg
	_saved_photo = SettingsService.get_value(&"photosensitivity")
	_saved_reduced = SettingsService.get_value(&"reduced_motion")
	_saved_muzzle = SettingsService.get_value(&"muzzle_flash")
	SettingsService.set_value(&"photosensitivity", false)
	SettingsService.set_value(&"reduced_motion", false)
	SettingsService.set_value(&"muzzle_flash", true)
	_holder = auto_free(Node2D.new())
	add_child(_holder)
	_vigil = VIGIL_SCENE.instantiate() as Vigil
	_holder.add_child(_vigil)
	_vigil.set_physics_process(false)
	_vigil.motor.set_physics_process(false)
	_vigil.position = Vector2(100, 50)
	_emitter = _vigil.emitter
	_emitter.enabled = false   # tests drive advance() directly
	_emitter.projectile_parent = _holder
	_fx = _vigil.get_node("%ArcLanceFx") as ArcLanceFx
	_fx.set_process(false)
	_calls = []
	var calls := _calls
	_fx.sfx_player = func(id: StringName, db: float) -> void: calls.append([id, db])
	_recoil = _vigil.get_node("%LanceRecoil") as LanceRecoil
	_recoil.set_process(false)
	_visual = _vigil.get_node("%Visual") as Node2D


func after_test() -> void:
	SettingsService.set_value(&"photosensitivity", _saved_photo)
	SettingsService.set_value(&"reduced_motion", _saved_reduced)
	SettingsService.set_value(&"muzzle_flash", _saved_muzzle)
	SettingsService.persist = _saved_persist
	AudioService.muted_for_tests = _saved_muted


func _fire() -> LanceProjectile:
	return _emitter.advance(DT, true)


func _hurtbox(bites: bool) -> Array:
	var hs := HealthStats.new()
	hs.max_hp = 5
	var hp := HealthComponent.new()
	hp.stats = hs
	_holder.add_child(hp)
	var hb := HurtboxComponent.new()
	hb.health = hp
	hb.bites = bites
	_holder.add_child(hb)
	return [hb, hp]


func test_data_matches_sys001() -> void:
	assert_str(FX_STATS.ds_namespace).is_equal("ds_arc_lance.fx")
	assert_int(FX_STATS.muzzle_star_px).is_equal(3)
	assert_int(FX_STATS.muzzle_star_frames).is_equal(1)
	assert_int(FX_STATS.recoil_px).is_equal(1)
	assert_int(FX_STATS.recoil_frames).is_equal(2)
	assert_float(FX_STATS.fleck_speed_px_s).is_equal(60.0)
	assert_float(FX_STATS.fleck_life_s).is_equal(0.12)
	assert_int(FX_STATS.tick_len_px).is_equal(3)
	assert_float(FX_STATS.tick_life_s).is_equal(0.15)
	assert_float(FX_STATS.lance_dull_db).is_equal(0.0)


func test_muzzle_star_spawns_at_the_muzzle_for_the_tuned_frames() -> void:
	_vigil.get_node("%Facing").rotation = PI * 0.5
	_fire()
	assert_int(_fx.star_frames_left).is_equal(FX_STATS.muzzle_star_frames)
	var want := Vector2(100, 50) + Vector2.DOWN * _emitter.stats.muzzle_offset_px
	assert_vector(_fx.star_pos).is_equal_approx(want, Vector2(0.001, 0.001))
	for i in FX_STATS.muzzle_star_frames:
		assert_int(_fx.star_frames_left).is_greater(0)
		_fx.advance_draw_frame()
	assert_int(_fx.star_frames_left).is_equal(0)


func test_muzzle_star_off_when_muzzle_flash_off_but_recoil_stays() -> void:
	SettingsService.set_value(&"muzzle_flash", false)
	_fire()
	assert_int(_fx.star_frames_left).is_equal(0)
	assert_int(_recoil.frames_left).is_equal(FX_STATS.recoil_frames)


func test_muzzle_star_off_under_photosensitivity_even_with_flash_on() -> void:
	SettingsService.set_value(&"muzzle_flash", true)
	SettingsService.set_value(&"photosensitivity", true)
	_fire()
	assert_int(_fx.star_frames_left).is_equal(0)


func test_recoil_is_visual_only_and_opposite_the_aim() -> void:
	var facing := _vigil.get_node("%Facing") as Node2D
	facing.rotation = PI * 0.5   # aim down
	var body_before := _vigil.global_position
	var vel_before := _vigil.velocity
	var visual_rest := _visual.position
	_fire()
	assert_int(_recoil.frames_left).is_equal(FX_STATS.recoil_frames)
	assert_vector(_recoil.offset()).is_equal_approx(Vector2.UP * float(FX_STATS.recoil_px), Vector2(0.001, 0.001))
	_recoil.apply()
	var nudged := _visual.global_position - facing.global_position
	assert_vector(nudged).is_equal_approx(Vector2.UP * float(FX_STATS.recoil_px), Vector2(0.001, 0.001))
	assert_vector(_vigil.global_position).is_equal(body_before)
	assert_vector(_vigil.velocity).is_equal(vel_before)
	assert_float(facing.rotation).is_equal_approx(PI * 0.5, 0.0001)
	assert_vector(facing.position).is_equal(Vector2.ZERO)
	for i in FX_STATS.recoil_frames:
		_recoil.advance_draw_frame()
	_recoil.apply()
	assert_vector(_recoil.offset()).is_equal(Vector2.ZERO)
	assert_vector(_visual.position).is_equal(visual_rest)


func test_recoil_absent_under_reduced_motion() -> void:
	SettingsService.set_value(&"reduced_motion", true)
	_fire()
	assert_int(_recoil.frames_left).is_equal(0)
	assert_vector(_recoil.offset()).is_equal(Vector2.ZERO)


func test_flecks_are_two_perpendicular_specks_that_expire() -> void:
	_fx.fleck(Vector2(10, 10), Vector2.RIGHT)
	assert_int(_fx.flecks.size()).is_equal(2)
	var a: ArcLanceFx.Fleck = _fx.flecks[0]
	var b: ArcLanceFx.Fleck = _fx.flecks[1]
	assert_vector(a.pos).is_equal(Vector2(10, 10))
	assert_float(a.vel.dot(Vector2.RIGHT)).is_equal_approx(0.0, 0.0001)
	assert_vector(a.vel + b.vel).is_equal_approx(Vector2.ZERO, Vector2(0.0001, 0.0001))
	assert_float(a.vel.length()).is_equal_approx(FX_STATS.fleck_speed_px_s, 0.001)
	assert_float(a.max_life).is_equal(FX_STATS.fleck_life_s)
	_fx.tick(0.1)
	assert_int(_fx.flecks.size()).is_equal(2)
	assert_float(a.pos.distance_to(Vector2(10, 10))).is_equal_approx(FX_STATS.fleck_speed_px_s * 0.1, 0.001)
	_fx.tick(FX_STATS.fleck_life_s - 0.1 + 0.001)
	assert_int(_fx.flecks.size()).is_equal(0)


func test_biting_hurtbox_takes_damage_and_leaves_flecks() -> void:
	var pair := _hurtbox(true)
	var hp := pair[1] as HealthComponent
	var shot := _fire()
	shot.register_hit(pair[0] as HurtboxComponent)
	assert_int(hp.current_hp).is_equal(4)
	assert_int(_fx.flecks.size()).is_equal(2)
	assert_int(_fx.chalk_ticks.size()).is_equal(0)
	assert_array(_calls).is_empty()


func test_non_biting_hurtbox_takes_no_damage_ticks_and_plays_lance_dull() -> void:
	var pair := _hurtbox(false)
	var hb := pair[0] as HurtboxComponent
	var hp := pair[1] as HealthComponent
	var received: Array[int] = [0]
	hb.hit_received.connect(func(_h: HitInfo, _a: bool) -> void: received[0] += 1)
	_vigil.get_node("%Facing").rotation = PI * 0.5   # shoot down
	var shot := _fire()
	var at := shot.global_position
	assert_bool(shot.register_hit(hb)).is_true()
	assert_int(hp.current_hp).is_equal(5)
	assert_int(received[0]).is_equal(0)
	assert_bool(shot.is_spent()).is_true()   # the shot is still absorbed
	assert_int(_fx.flecks.size()).is_equal(0)
	assert_int(_fx.chalk_ticks.size()).is_equal(1)
	var t: ArcLanceFx.ChalkTick = _fx.chalk_ticks[0]
	assert_vector(t.pos).is_equal(at)
	assert_float(absf(t.dir.dot(Vector2.DOWN))).is_equal_approx(0.0, 0.0001)   # perpendicular to the lance
	assert_float(t.life).is_equal(FX_STATS.tick_life_s)
	assert_array(_calls).is_equal([[&"lance_dull", FX_STATS.lance_dull_db]])
	_fx.tick(FX_STATS.tick_life_s + 0.001)
	assert_int(_fx.chalk_ticks.size()).is_equal(0)


func test_bites_defaults_true_and_only_the_lance_honours_it() -> void:
	assert_bool((auto_free(HurtboxComponent.new()) as HurtboxComponent).bites).is_true()
	var pair := _hurtbox(false)
	var hp := pair[1] as HealthComponent
	(pair[0] as HurtboxComponent).receive_hit(HitInfo.make(1, 7, 8, &"charge"))   # a Charge still lands
	assert_int(hp.current_hp).is_equal(4)


func test_wall_hit_leaves_flecks() -> void:
	var wall: Node2D = auto_free(Node2D.new())
	_fire().register_hit(wall)
	assert_int(_fx.flecks.size()).is_equal(2)
	assert_array(_calls).is_empty()


func test_bite_feedback_is_deterministic() -> void:
	var runs: Array = []
	for r in 2:
		_fx.flecks.clear()
		_fx.chalk_ticks.clear()
		_fx.fleck(Vector2(3, 4), Vector2(1, 1))
		_fx.chalk_tick(Vector2(7, 8), Vector2(0, 1))
		_fx.tick(0.05)
		var snap: Array = []
		for f: ArcLanceFx.Fleck in _fx.flecks:
			snap.append([f.pos, f.vel, f.life])
		for k: ArcLanceFx.ChalkTick in _fx.chalk_ticks:
			snap.append([k.pos, k.dir, k.life])
		runs.append(snap)
	assert_array(runs[1]).is_equal(runs[0])
