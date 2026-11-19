extends GdUnitTestSuite
## Act 0 cabinet rules, driven tick by tick through the real scene (no frame loop, no audio).
## Every expected value comes from CabinetTuning (SYS-001), never restated here.

const SCENE := preload("res://features/cabinet/cabinet_game.tscn")
const DT := 1.0 / 60.0

var game: Node
var world: ArcadeWorld
var t: CabinetTuning


func before_test() -> void:
	AudioService.muted_for_tests = true
	SaveService.set_backend(MemorySaveBackend.new())
	game = SCENE.instantiate()
	add_child(game)
	game.set_process(false)
	world = game.get_node("%World")
	world.paused_sim = true        # the test drives world.step()
	t = world.tuning


func after_test() -> void:
	if is_instance_valid(game):
		game.free()
	AudioService.muted_for_tests = false
	SaveService.set_backend(FileSaveBackend.new())
	get_tree().paused = false


## A bare stage: nothing spawns unless the test asks for it.
func _stage(goal: int = CabinetStage.Goal.UNMAKE_ENTITY, segments: int = 0, wakes: bool = true) -> CabinetStage:
	var s := CabinetStage.new()
	s.geodes = 0
	s.grubs = 0
	s.acolytes = 0
	s.guard_acolytes = 0
	s.sepulchre_start_segments = segments
	s.sepulchre_wakes = wakes
	s.chant = false
	s.goal = goal
	return s


func _steps(seconds: float) -> void:
	for i in roundi(seconds / DT):
		world.step(DT)


# --- Torus ------------------------------------------------------------------------------

func test_torus_takes_the_short_way_round() -> void:
	var tor := Torus.new(Vector2(1000, 500))
	assert_vector(tor.wrap(Vector2(-10, 510))).is_equal(Vector2(990, 10))
	assert_vector(tor.delta(Vector2(990, 250), Vector2(10, 250))).is_equal(Vector2(20, 0))
	assert_float(tor.distance(Vector2(5, 5), Vector2(995, 495))).is_equal_approx(sqrt(200.0), 0.001)


# --- Score and lives (SYS-001 §7.1, GDD §9.4) ----------------------------------------------

## PM Q-T107 (2026-11-19): 10,000, 30,000, then every +40,000 (70k, 110k …), cap 5.
func test_the_extra_life_schedule_defaults() -> void:
	assert_int(t.extra_life_first).is_equal(10000)
	assert_int(t.extra_life_second).is_equal(30000)
	assert_int(t.extra_life_every).is_equal(40000)
	assert_int(t.lives_start).is_equal(3)
	assert_int(t.lives_cap).is_equal(5)


func test_extra_vigils_at_10k_30k_70k_110k() -> void:
	var tt := t.duplicate() as CabinetTuning
	tt.lives_cap = 99                      # watch the thresholds, not the cap
	var sk := ScoreKeeper.new(tt)
	var start := sk.lives
	var expected: Array[int] = [10000, 30000, 70000, 110000, 150000]
	for k in expected.size():
		assert_int(sk.next_extra_at()).is_equal(expected[k])
		sk.add(expected[k] - 1 - sk.score)
		assert_int(sk.lives).override_failure_message("before %d" % expected[k]).is_equal(start + k)
		sk.add(1)
		assert_int(sk.lives).override_failure_message("at %d" % expected[k]).is_equal(start + k + 1)


func test_extra_vigils_respect_the_cap_and_reset() -> void:
	var sk := ScoreKeeper.new(t)
	var awarded := [0]
	sk.extra_life_awarded.connect(func() -> void: awarded[0] += 1)
	sk.add(110000)                         # four thresholds at once: 3 + 4 capped at 5
	assert_int(sk.lives).is_equal(t.lives_cap)
	assert_int(awarded[0]).is_equal(t.lives_cap - t.lives_start)
	assert_int(sk.next_extra_at()).is_equal(150000)
	sk.reset()
	assert_int(sk.next_extra_at()).is_equal(t.extra_life_first)
	sk.add(t.extra_life_first)
	assert_int(sk.next_extra_at()).is_equal(t.extra_life_second)


# --- Geodes (SYS-001 §1.3) ---------------------------------------------------------------

func test_calm_mining_frees_glass_face_by_face() -> void:
	world.start(_stage())
	var g := world.geodes.add_geode(world.vigil.pos + Vector2(200, 0), 2)   # 3 faces
	for k in t.face_hits:
		world.time += 0.5          # calm: never inside the over-fire window
		world.geodes.lance_hit(g)
	assert_int(world.glass.shards.size()).is_equal(1)
	assert_bool(g.alive).is_true()
	for k in t.face_hits * 2:
		world.time += 0.5
		world.geodes.lance_hit(g)
	assert_bool(g.alive).is_false()
	assert_int(world.glass.shards.size()).is_equal(t.shards_calm + 1)


## A still 3-face geode dead ahead, and the Vigil holding the lance through the real fire path
## (scripted input, world.step, the tuned lance_rate). Returns the geode once it is gone or after
## `max_s`.
func _hold_lance_on_geode(max_s: float) -> GeodeField.Geode:
	var g := world.geodes.add_geode(world.vigil.pos + Vector2(120, 0), 2)
	g.vel = Vector2.ZERO
	var v := world.vigil
	v.shield = 0.0
	v.use_scripted = true
	v.scripted_move = Vector2.ZERO
	v.scripted_aim = Vector2.RIGHT * 10.0
	v.facing = 0.0
	v.scripted_fire = true
	for i in roundi(max_s / DT):
		world.step(DT)
		if not g.alive:
			break
	v.scripted_fire = false
	return g


func test_held_lance_overfires_and_scatters() -> void:
	world.start(_stage())
	world.glass.set_charges(0)
	# calm mining of this geode takes 3 × face_hits hits; held fire must detonate it long before
	var g := _hold_lance_on_geode(3.0 * t.face_hits / t.lance_rate)
	assert_bool(g.alive).is_false()
	assert_int(g.faces_left).override_failure_message("detonated, not mined out").is_greater(0)
	assert_int(g.recent.size()).is_equal(t.overfire_hits)
	var freed := world.glass.shards.size() + world.glass.charges
	assert_int(freed).is_between(t.shards_detonated_min, t.shards_detonated_max)


# --- Glass and Charges (SYS-001 §1.4) -----------------------------------------------------

func test_shard_becomes_a_charge_until_the_magazine_is_full() -> void:
	world.start(_stage())
	world.glass.set_charges(t.magazine - 1)
	world.glass.spawn_shard(world.vigil.pos + Vector2(20, 0), Vector2.ZERO)
	world.glass.spawn_shard(world.vigil.pos + Vector2(-20, 0), Vector2.ZERO)
	_steps(1.0)
	assert_int(world.glass.charges).is_equal(t.magazine)
	assert_int(world.glass.shards.size()).override_failure_message("overflow glass must stay in the world").is_equal(1)


func test_charge_homes_and_knocks_modules_off_the_sepulchre() -> void:
	world.start(_stage(CabinetStage.Goal.CLEAR_SEPULCHRE, 6, false))
	var cleared := [false]
	world.sepulchre_cleared.connect(func() -> void: cleared[0] = true)
	world.vigil.pos = world.torus.wrap(world.ritual.pos + Vector2(-150, 90))
	world.glass.set_charges(1)
	# thrown the wrong way: it must turn round and still arrive
	assert_bool(world.glass.launch(world.vigil.pos, Vector2.LEFT)).is_true()
	_steps(5.0)
	var left := world.ritual.segments
	assert_int(left).is_between(6 - t.knock_max, 6 - t.knock_min)
	assert_bool(cleared[0]).is_false()
	world.glass.set_charges(5)
	for i in 5:
		world.glass.launch(world.vigil.pos, Vector2.RIGHT)
		_steps(3.0)
	assert_int(world.ritual.segments).is_equal(0)
	assert_bool(cleared[0]).is_true()


func test_a_grub_in_the_way_intercepts_a_charge() -> void:
	var s := _stage(CabinetStage.Goal.CLEAR_SEPULCHRE, 6, false)
	s.grubs = 1
	world.start(s)
	var grub: GrubFlock.Grub = world.grubs.items[0]
	world.vigil.pos = world.torus.wrap(world.ritual.pos + Vector2(-300, 0))
	grub.pos = world.torus.wrap(world.ritual.pos + Vector2(-150, 0))
	world.grubs.set_physics_process(false)
	world.glass.set_charges(1)
	world.glass.launch(world.vigil.pos, Vector2.RIGHT)
	for i in 240:
		grub.pos = world.torus.wrap(world.ritual.pos + Vector2(-150, 0))   # hold it in the lane
		world.glass._tick_charges(DT)
	assert_int(world.ritual.segments).override_failure_message("an intercepted Charge must not reach the Sepulchre").is_equal(6)
	assert_int(world.glass.charges_flying.size()).is_equal(0)


# --- Grubs and the build (SYS-001 §2, §3) -------------------------------------------------

func test_grubs_carry_glass_and_every_three_deposits_add_a_segment() -> void:
	var s := _stage()
	s.grubs = 1
	world.start(s)
	world.vigil.pos = world.torus.wrap(world.ritual.pos + Vector2(900, 300))   # far away: no fear
	for k in t.shards_per_segment:
		world.glass.spawn_shard(world.torus.wrap(world.ritual.pos + Vector2(120, 0)), Vector2.ZERO)
	_steps(20.0)
	assert_int(world.ritual.segments).is_equal(1)


## A Grub that fled the lamp while it held a live claim goes back to its shard once the lamp has passed
## (it used to stay in FLEE for good; found by the autopilot shift harness, 2026-11-19).
func test_a_grub_that_fled_returns_to_its_claimed_shard() -> void:
	for pilfer in [false, true]:
		var s := _stage()
		s.grubs = 1
		s.grub_pilfer = pilfer
		world.start(s)
		var g: GrubFlock.Grub = world.grubs.items[0]
		world.vigil.pos = world.torus.wrap(world.ritual.pos + Vector2(900, 300))
		var shard := world.glass.spawn_shard(world.torus.wrap(g.pos + Vector2(300, 0)), Vector2.ZERO)
		_steps(0.5)                                         # it claims the shard and sets off
		assert_object(g.shard).is_same(shard)
		world.vigil.pos = world.torus.wrap(g.pos + Vector2(-20, 0))   # the lamp arrives: it flees
		world.step(DT)
		assert_int(g.state).is_equal(GrubFlock.State.FLEE)
		world.vigil.pos = world.torus.wrap(world.ritual.pos + Vector2(900, 300))   # and leaves
		_steps(1.0)
		assert_bool(g.state == GrubFlock.State.SEEK or g.state == GrubFlock.State.CARRY).override_failure_message("pilfer=%s: still fleeing an absent lamp (state %d)" % [pilfer, g.state]).is_true()


func test_cold_sepulchre_never_wakes() -> void:
	world.start(_stage(CabinetStage.Goal.CLEAR_SEPULCHRE, t.segments_total - 1, false))
	for k in t.shards_per_segment:
		world.ritual.deposit()
	_steps(6.0)
	assert_int(world.ritual.segments).is_equal(t.segments_total)
	assert_bool(world.ritual.awake).is_false()
	assert_int(world.ritual.phase).is_not_equal(SepulchreRitual.Phase.AWAKENING)


# --- The Waking (SYS-001 §2, §2.1; AUDIO-001 §4.1) ---------------------------------------

func test_twenty_segments_wake_it_after_silence_with_the_line() -> void:
	world.start(_stage(CabinetStage.Goal.UNMAKE_ENTITY, t.segments_total - 1))
	var lines: Array[String] = []
	world.entity_line.connect(func(k: String) -> void: lines.append(k))
	for k in t.shards_per_segment:
		world.ritual.deposit()
	assert_int(world.ritual.phase).is_equal(SepulchreRitual.Phase.AWAKENING)
	_steps(t.awakening_silence * 0.5)
	assert_array(lines).is_empty()
	_steps(t.awakening_silence)
	assert_array(lines).is_equal(["ENTITY_IT_WAKES"])
	_steps(t.stagger_window)
	assert_bool(world.ritual.awake).is_true()
	assert_int(world.ritual.phase).is_equal(SepulchreRitual.Phase.RAMPAGE)


func test_rampage_contact_kills_the_vigil() -> void:
	world.start(_stage(CabinetStage.Goal.UNMAKE_ENTITY, t.segments_total))
	_steps(t.awakening_silence + t.stagger_window + 0.1)
	world.vigil.shield = 0.0
	world.vigil.pos = world.torus.wrap(world.ritual.entity_pos + Vector2(60, 0))
	world.vigil.use_scripted = true
	var died := [false]
	world.vigil_destroyed.connect(func() -> void: died[0] = true)
	_steps(2.0)
	assert_bool(died[0]).is_true()


func test_the_lance_does_not_bite_the_entity() -> void:
	world.start(_stage(CabinetStage.Goal.UNMAKE_ENTITY, t.segments_total))
	_steps(t.awakening_silence + t.stagger_window + 0.1)
	var before := world.ritual.hits_left
	var sparks_before := world.fx.sparks.size()
	var ticks_before := world.fx.chalk_ticks.size()
	assert_bool(world.ritual.lance_test(world.ritual.entity_pos, Vector2.RIGHT)).is_true()
	assert_int(world.ritual.hits_left).is_equal(before)
	assert_int(world.fx.chalk_ticks.size()).is_equal(ticks_before + 1)   # the no-bite tick teaches the rule
	assert_int(world.fx.sparks.size()).is_equal(sparks_before)           # and it is not a hit-looking spark burst


func test_thirteen_charges_unmake_it_for_fifteen_thousand() -> void:
	world.start(_stage(CabinetStage.Goal.UNMAKE_ENTITY, t.segments_total))
	_steps(t.awakening_silence + t.stagger_window + 0.1)
	var points := [0]
	var unmade := [false]
	world.score_awarded.connect(func(p: int, _a: Vector2) -> void: points[0] += p)
	world.entity_unmade.connect(func() -> void: unmade[0] = true)
	for i in t.unravel_hits:
		assert_bool(unmade[0]).is_false()
		world.ritual.charge_contact(world.ritual.entity_pos, 1.0)
	assert_bool(unmade[0]).is_true()
	assert_int(world.ritual.phase).is_equal(SepulchreRitual.Phase.UNMADE)
	assert_int(points[0]).is_equal(t.score_entity + t.unravel_hits * t.score_module)


# --- Acolytes (SYS-001 §3) -----------------------------------------------------------------

func test_acolyte_censer_lags_the_vigil_by_a_quarter_second() -> void:
	var s := _stage()
	s.acolytes = 1
	world.start(s)
	var a: AcolyteSquad.Acolyte = world.acolytes.items[0]
	world.vigil.use_scripted = true
	a.pos = world.torus.wrap(world.vigil.pos + Vector2(150, 0))
	var lag := roundi(t.acolyte_turret_lag * Engine.physics_ticks_per_second)
	var angles: Array[float] = []
	for i in lag + 30:
		world.vigil.pos = world.torus.wrap(world.vigil.pos + Vector2(0, 2))
		a.pos = world.torus.wrap(world.vigil.pos + Vector2(150, -float(i) * 2.0))
		angles.append(world.torus.delta(a.pos, world.vigil.pos).angle())   # what it sees this tick
		world.acolytes.tick(DT)
	assert_float(a.turret).is_equal_approx(angles[angles.size() - lag], 0.0001)


# --- End to end ----------------------------------------------------------------------------

func test_autopilot_can_clear_the_first_vigil() -> void:
	var stage: CabinetStage = (game.stages[0] as CabinetStage)
	world.start(stage)
	var cleared := [false]
	world.sepulchre_cleared.connect(func() -> void: cleared[0] = true)
	var pilot: CabinetAutopilot = game.get_node("%Autopilot")
	pilot.enabled = true
	pilot.set_physics_process(false)
	var lives := 99
	world.vigil_destroyed.connect(func() -> void:
		lives -= 1
		world.vigil.respawn(world.random_point(world.ritual.pos, 400.0)))
	var seconds := 0.0
	while not cleared[0] and seconds < 240.0:
		pilot._physics_process(DT)
		world.step(DT)
		seconds += DT
	assert_bool(cleared[0]).override_failure_message("the First Vigil was not cleared in 240 s of simulated play").is_true()
	print("autopilot cleared the First Vigil in %.1f simulated s, %d lives lost" % [seconds, 99 - lives])
	assert_float(seconds).override_failure_message("clearing must take real play, not happen at once").is_greater(10.0)
