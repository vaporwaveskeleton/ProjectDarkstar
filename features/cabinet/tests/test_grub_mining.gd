extends GdUnitTestSuite
## F-13 (owner playtest round 3, Q-T451): an idle Grub with no loose glass slowly gnaws a geode for glass
## (the source Sinistar's miners work a planetoid; research note sinistar_mining.md). Provisional data.

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
	world.paused_sim = true
	t = world.tuning


func after_test() -> void:
	if is_instance_valid(game):
		game.free()
	AudioService.muted_for_tests = false
	SaveService.set_backend(FileSaveBackend.new())


func _stage(mine: bool) -> CabinetStage:
	var s := CabinetStage.new()
	s.geodes = 0
	s.grubs = 1
	s.acolytes = 0
	s.guard_acolytes = 0
	s.sepulchre_start_segments = 4
	s.sepulchre_wakes = true
	s.chant = false
	s.grub_mine = mine
	return s


func _setup(mine: bool) -> GeodeField.Geode:
	world.start(_stage(mine))
	world.grubs.items[0].pos = world.torus.wrap(world.vigil.pos + Vector2(0, 400))     # far from the lamp
	var rock := world.geodes.add_geode(world.torus.wrap(world.vigil.pos + Vector2(120, 400)), 0)
	rock.vel = Vector2.ZERO
	return rock


func _steps(seconds: float) -> void:
	for i in roundi(seconds / DT):
		world.step(DT)


func test_a_grub_with_no_loose_glass_gnaws_a_geode_and_frees_glass() -> void:
	var rock := _setup(true)
	_steps(60.0)
	assert_bool(rock.alive and rock.faces_left == rock.faces and world.glass.shards.is_empty()).override_failure_message("the Grub never worked the geode").is_false()
	assert_int(world.record.glass_mined).override_failure_message("a Grub's mining is not the player's glass").is_equal(0)
	assert_int(world.grubs.items.size()).is_equal(1)


func test_it_is_slow_one_bite_per_period() -> void:
	var rock := _setup(true)
	_steps(2.0 + 3.0 * t.grub_mine_period_s)
	assert_int(rock.hits_on_face).override_failure_message("a Grub must not out-mine one bite per period").is_less_equal(4)
	assert_float(t.grub_mine_period_s).override_failure_message("slower than the Acolyte (2 / lance_rate)").is_greater(2.0 / t.lance_rate)


func test_a_lone_gnawing_grub_never_detonates_a_geode() -> void:
	var rock := _setup(true)
	_steps(90.0)
	assert_bool(rock.recent.size() < t.overfire_hits).is_true()


func test_the_switch_is_off_by_default_and_off_means_idle() -> void:
	assert_bool(CabinetStage.new().grub_mine).is_false()
	var rock := _setup(false)
	_steps(30.0)
	assert_int(rock.faces_left).is_equal(rock.faces)
	assert_int(rock.hits_on_face).is_equal(0)


func test_the_wake_stages_mine_and_the_cold_ones_do_not() -> void:
	var roster := CabinetStageRoster.default_roster()
	for id: StringName in [&"a0_3", &"a0_4", &"a0_5"]:
		var st: CabinetStage = load("res://data/cabinet/stage_%s.tres" % {&"a0_3": "censer_watch", &"a0_4": "shoal", &"a0_5": "last_normal_day"}[id])
		assert_bool(st.grub_mine).override_failure_message("%s grub_mine" % id).is_true()
	for path in ["res://data/cabinet/stage_first_vigil.tres", "res://data/cabinet/stage_drift.tres"]:
		assert_bool((load(path) as CabinetStage).grub_mine).override_failure_message(path).is_false()
	assert_object(roster).is_not_null()
