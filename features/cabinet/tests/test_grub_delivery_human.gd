extends GdUnitTestSuite
## F-12 (owner playtest round 3, Q-T449): "the Grubs never complete the Sepulchre, so it never wakes".
## Measured with real held input in the real CabinetGame flow (the Vigil reads Input; the bot below only presses
## actions: move/aim sticks and fire_lance, like a human mining the nearest geode and never homing on the altar).
## Cause: delivery is trip-limited. Glass lives round the Vigil (Neighbourhood) while the Sepulchre stays put
## 2,600-4,100 px away, so one carry+return cycle took 55 s and 6-14 Grubs delivered 0.1-0.27 shards/s against
## the 48 a waking stage needs. The autopilot homes on the altar (autopilot 2b) and never saw it.
## Before: a0_3 wakes at ~180 s, a0_5 at ~300 s (HP 4). After the far haul sprint (grub_haul_catchup_*): ~130 s / ~220 s.

const SCENE := preload("res://features/cabinet/cabinet_game.tscn")
const DT := 1.0 / 60.0
const ACTIONS: Array[StringName] = [&"move_left", &"move_right", &"move_up", &"move_down",
		&"aim_left", &"aim_right", &"aim_up", &"aim_down", &"fire_lance"]

var game: Node
var world: ArcadeWorld


func before_test() -> void:
	AudioService.muted_for_tests = true
	SaveService.set_backend(MemorySaveBackend.new())
	game = SCENE.instantiate()
	add_child(game)
	game.set_process(false)
	world = game.get_node("%World")


func after_test() -> void:
	for a in ACTIONS:
		Input.action_release(a)
	if is_instance_valid(game):
		game.free()
	AudioService.muted_for_tests = false
	SaveService.set_backend(FileSaveBackend.new())


func _stick(neg_x: StringName, pos_x: StringName, neg_y: StringName, pos_y: StringName, v: Vector2) -> void:
	for a in [neg_x, pos_x, neg_y, pos_y]:
		Input.action_release(a)
	if v.length() < 0.01:
		return
	v = v.normalized()
	Input.action_press(neg_x if v.x < 0.0 else pos_x, absf(v.x))
	Input.action_press(neg_y if v.y < 0.0 else pos_y, absf(v.y))


func _nearest_geode() -> GeodeField.Geode:
	var best: GeodeField.Geode = null
	var bd := INF
	for g in world.geodes.items:
		if g.alive:
			var d := world.torus.distance(world.vigil.pos, g.pos)
			if d < bd:
				bd = d
				best = g
	return best


## A miner who never goes near the altar: seconds until the Sepulchre is complete (AWAKENING), or -1.
func _seconds_to_wake(stage_i: int, limit_s: float, min_far_px: float) -> float:
	game.start_stage(stage_i)
	game.dismiss_brief()
	world.paused_sim = true
	game._on_timer()
	world.vigil.use_scripted = false
	world.vigil.input_enabled = true
	world.vigil.shield = 100000.0          # an Acolyte shot must not end the run: this measures the build
	var far_sum := 0.0
	var steps := 0
	for i in roundi(limit_s / DT):
		var g := _nearest_geode()
		if g != null:
			var d := world.torus.delta(world.vigil.pos, g.pos)
			_stick(&"move_left", &"move_right", &"move_up", &"move_down", d if d.length() > g.radius + 60.0 else Vector2.ZERO)
			_stick(&"aim_left", &"aim_right", &"aim_up", &"aim_down", d)
			if d.length() < 250.0:
				Input.action_press(&"fire_lance")
			else:
				Input.action_release(&"fire_lance")
		world.step(DT)
		far_sum += world.torus.distance(world.vigil.pos, world.ritual.pos)
		steps += 1
		if world.ritual.phase >= SepulchreRitual.Phase.AWAKENING:
			assert_float(far_sum / steps).override_failure_message("the run must be a far one (the altar never homed on)").is_greater(min_far_px)
			return i * DT
	return -1.0


func test_a_far_working_human_wakes_the_sepulchre_on_a0_4() -> void:
	var s := _seconds_to_wake(CabinetStageRoster.default_roster().index_of(&"a0_4"), 170.0, 1500.0)
	assert_float(s).override_failure_message("a0_4 did not wake inside 170 s of mining (limit PROPOSED, Q-T452: a0_3 left the shift)").is_greater(0.0)


func test_a_far_working_human_wakes_the_sepulchre_on_the_scarce_a0_5() -> void:
	var s := _seconds_to_wake(CabinetStageRoster.default_roster().index_of(&"a0_5"), 270.0, 1500.0)
	assert_float(s).override_failure_message("a0_5 did not wake inside 270 s of mining").is_greater(0.0)


func test_a_far_laden_grub_hauls_faster_than_a_near_one() -> void:
	world.start(CabinetStage.new())
	var t := world.tuning
	var g := GrubFlock.Grub.new()
	g.pos = world.torus.wrap(world.ritual.pos + Vector2(t.grub_haul_catchup_px + 100.0, 0))
	assert_float(world.grubs.haul_speed(g)).is_equal(t.grub_haul_catchup_speed)
	g.pos = world.torus.wrap(world.ritual.pos + Vector2(t.grub_haul_catchup_px - 100.0, 0))
	assert_float(world.grubs.haul_speed(g)).is_equal(t.grub_speed_carry)
	assert_float(t.grub_haul_catchup_speed).override_failure_message("the haul must not out-run the Vigil (SYS-001 §1.1)").is_less(world.move_stats.max_speed)
