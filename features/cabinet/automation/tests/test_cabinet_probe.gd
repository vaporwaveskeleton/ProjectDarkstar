extends GdUnitTestSuite
## Cabinet automation probe: ids, allow-listed props, entity lifetimes, dev ops, snapshot, events.
## Driven tick by tick through the real scene (no frame loop), like test_cabinet_rules.gd.

const SCENE := preload("res://features/cabinet/cabinet_game.tscn")
const Probe := preload("res://features/cabinet/automation/cabinet_probe.gd")
const DT := 1.0 / 60.0

var game: Node
var world: ArcadeWorld
var probe: RefCounted


func before_test() -> void:
	AudioService.muted_for_tests = true
	SaveService.set_backend(MemorySaveBackend.new())
	game = SCENE.instantiate()
	add_child(game)
	game.set_process(false)
	world = game.get_node("%World")
	world.paused_sim = true
	world.start(_stage())
	probe = Probe.new()
	probe.setup(game)


func after_test() -> void:
	probe.disconnect_events()
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
	s.sepulchre_start_segments = 0
	s.sepulchre_wakes = true
	s.chant = false
	s.goal = CabinetStage.Goal.UNMAKE_ENTITY
	return s


func _val(id: String, prop: String) -> Variant:
	var r: Dictionary = probe.read(id, prop)
	assert_bool(r.ok).override_failure_message("%s.%s: %s" % [id, prop, r.error]).is_true()
	return r.value


# --- ids and props -----------------------------------------------------------------------------

func test_singleton_props() -> void:
	assert_str(_val("cabinet/game", "state")).is_equal("intro")
	assert_int(_val("cabinet/game", "stage_index")).is_equal(0)
	assert_bool(_val("cabinet/game", "demo")).is_false()
	assert_int(_val("cabinet/score", "lives")).is_equal(game.score.lives)
	assert_int(_val("cabinet/score", "score")).is_equal(0)
	for k in ["grubs_destroyed", "glass_mined", "charges_thrown", "glass_carried"]:
		assert_int(_val("cabinet/record", k)).is_equal(0)
	assert_bool(_val("cabinet/vigil", "alive")).is_true()
	assert_float(_val("cabinet/vigil", "shield")).is_equal(world.vigil.shield)
	assert_float(_val("cabinet/vigil", "pos_x")).is_equal(world.vigil.pos.x)
	assert_float(_val("cabinet/vigil", "pos_y")).is_equal(world.vigil.pos.y)
	assert_bool(_val("cabinet/vigil", "use_scripted")).is_false()


func test_world_props() -> void:
	for k in ["acolytes", "grubs", "geodes", "shots", "hostile_shots", "charges", "hitstop_left"]:
		assert_int(_val("cabinet/world", k)).is_equal(0)
	assert_bool(_val("cabinet/world", "paused_sim")).is_true()
	assert_float(_val("cabinet/world", "sim_scale")).is_equal(1.0)
	assert_float(_val("cabinet/world", "time")).is_equal(0.0)
	world.step(DT)
	assert_float(_val("cabinet/world", "time")).is_greater(0.0)


func test_allow_list_rejects_other_props_and_unknown_ids() -> void:
	var r: Dictionary = probe.read("cabinet/vigil", "vel")
	assert_bool(r.ok).is_false()
	assert_str(r.error).contains("not readable")
	assert_bool(probe.read("cabinet/game", "stages").ok).is_false()
	assert_str(probe.read("cabinet/nope", "x").error).contains("unknown id")
	assert_bool(probe.read("cabinet/acolyte/77", "alive").ok).is_false()
	assert_str(probe.read("cabinet/acolyte/77", "alive").error).contains("no entity")
	assert_bool(probe.has("cabinet/vigil")).is_true()
	assert_bool(probe.has("cabinet/nope")).is_false()
	assert_bool(probe.has("cabinet/acolyte/abc")).is_false()
	assert_bool(probe.has("ruins/vigil")).is_false()


func test_acolyte_ids_increment_and_survive_a_restart() -> void:
	var a := world.acolytes.spawn(world.vigil.pos + Vector2(10, 0))
	var b := world.acolytes.spawn(world.vigil.pos + Vector2(20, 0))
	assert_int(b.id).is_equal(a.id + 1)
	world.start(_stage())   # reset: ids must keep counting
	var c := world.acolytes.spawn(world.vigil.pos + Vector2(10, 0))
	assert_int(c.id).is_greater(b.id)


func test_entities_appear_and_disappear() -> void:
	assert_str(probe.dev_op("spawn", {"kind": "acolyte", "dx": 0, "dy": -90})).is_empty()
	var a: AcolyteSquad.Acolyte = world.acolytes.items[0]
	var id := "cabinet/acolyte/%d" % a.id
	assert_bool(probe.has(id)).is_true()
	assert_bool(_val(id, "alive")).is_true()
	assert_int(_val(id, "hp")).is_equal(a.hp)
	assert_float(_val(id, "pos_x")).is_equal(a.pos.x)
	assert_float(_val(id, "dx")).is_equal_approx(0.0, 0.01)
	assert_float(_val(id, "dy")).is_equal_approx(-90.0, 0.01)
	assert_bool(_val(id, "on_screen")).is_true()
	world.acolytes.kill(a)
	world.step(DT)   # dead acolytes are purged on the next tick
	assert_bool(probe.has(id)).is_false()
	var g := world.geodes.add_geode(world.vigil.pos + Vector2(100, 0), 1)
	var gid := "cabinet/geode/%d" % (world.geodes.items.size() - 1)
	assert_int(_val(gid, "faces_left")).is_equal(g.faces_left)
	assert_bool(_val(gid, "alive")).is_true()
	assert_bool(probe.has("cabinet/geode/99")).is_false()
	assert_bool(probe.has("cabinet/geode/-1")).is_false()


func test_grub_props() -> void:
	world.start(_grub_stage())
	var g: GrubFlock.Grub = world.grubs.items[0]
	var id := "cabinet/grub/%d" % g.id
	assert_bool(probe.has(id)).is_true()
	assert_bool(_val(id, "carrying")).is_false()
	assert_int(_val(id, "hp")).is_equal(g.hp)
	assert_float(_val(id, "pos_y")).is_equal(g.pos.y)
	assert_int(_val("cabinet/world", "grubs")).is_equal(1)


func _grub_stage() -> CabinetStage:
	var s := _stage()
	s.grubs = 1
	return s


func test_on_screen_is_false_far_away_and_dx_wraps_the_torus() -> void:
	probe.dev_op("teleport", {"x": 10, "y": 360})
	probe.dev_op("spawn", {"kind": "acolyte", "dx": -40, "dy": 0})   # wraps to the far side of the torus
	var a: AcolyteSquad.Acolyte = world.acolytes.items[0]
	assert_float(a.pos.x).is_equal_approx(world.torus.size.x - 30.0, 0.01)
	assert_float(_val("cabinet/acolyte/%d" % a.id, "dx")).is_equal_approx(-40.0, 0.01)
	probe.dev_op("spawn", {"kind": "acolyte", "dx": 600, "dy": 0})
	var far: AcolyteSquad.Acolyte = world.acolytes.items[1]
	assert_bool(_val("cabinet/acolyte/%d" % far.id, "on_screen")).is_false()


# --- dev ops -----------------------------------------------------------------------------------

func test_teleport_wraps_and_zeroes_velocity() -> void:
	world.vigil.vel = Vector2(50, 50)
	assert_str(probe.dev_op("teleport", {"x": -10, "y": world.torus.size.y + 5})).is_empty()
	assert_vector(world.vigil.pos).is_equal_approx(Vector2(world.torus.size.x - 10, 5), Vector2(0.01, 0.01))
	assert_vector(world.vigil.vel).is_equal(Vector2.ZERO)
	assert_str(probe.dev_op("teleport", {"x": 99999, "y": 0})).contains("4000")
	assert_str(probe.dev_op("teleport", {"x": INF, "y": 0})).contains("finite")


func test_spawn_kinds_and_failures() -> void:
	var at := world.vigil.pos
	assert_str(probe.dev_op("spawn", {"kind": "geode", "dx": 60, "dy": 0})).is_empty()
	assert_vector(world.geodes.items[0].pos).is_equal_approx(at + Vector2(60, 0), Vector2(0.01, 0.01))
	assert_str(probe.dev_op("spawn", {"kind": "shard", "dx": 0, "dy": 30})).is_empty()
	assert_int(world.glass.shards.size()).is_equal(1)
	assert_vector(world.glass.shards[0].pos).is_equal_approx(at + Vector2(0, 30), Vector2(0.01, 0.01))
	assert_str(probe.dev_op("spawn", {"kind": "dragon", "dx": 0, "dy": 0})).contains("unknown kind")
	assert_str(probe.dev_op("spawn", {"kind": "geode", "dx": 5000, "dy": 0})).contains("4000")
	assert_str(probe.dev_op("spawn", {"kind": "geode", "dx": "x", "dy": 0})).contains("finite")


func test_set_lives_emits_and_validates() -> void:
	var seen: Array[int] = []
	game.score.lives_changed.connect(func(n: int) -> void: seen.append(n))
	assert_str(probe.dev_op("set_lives", {"lives": 5})).is_empty()
	assert_int(game.score.lives).is_equal(5)
	assert_array(seen).is_equal([5])
	assert_str(probe.dev_op("set_lives", {"lives": 12})).contains("0..9")
	assert_int(game.score.lives).is_equal(5)


func test_set_stage_returns_to_intro() -> void:
	game._enter(game.State.PLAY)
	assert_str(_val("cabinet/game", "state")).is_equal("play")
	assert_str(probe.dev_op("set_stage", {"index": 1})).is_empty()
	assert_str(_val("cabinet/game", "state")).is_equal("intro")
	assert_int(_val("cabinet/game", "stage_index")).is_equal(1)
	assert_str(probe.dev_op("set_stage", {"index": 99})).contains("outside")


func test_shoot_vigil_kills_the_vigil_after_the_flight() -> void:
	world.vigil.shield = 0.0
	assert_str(probe.dev_op("shoot_vigil", {"dx": 0, "dy": -90})).is_empty()
	assert_int(_val("cabinet/world", "hostile_shots")).is_equal(1)
	assert_int(_val("cabinet/world", "shots")).is_equal(1)
	var died := [false]
	world.vigil_destroyed.connect(func() -> void: died[0] = true)
	for i in 40:   # 90 px at 240 px/s is 22 ticks
		world.step(DT)
	assert_bool(died[0]).is_true()
	assert_bool(_val("cabinet/vigil", "alive")).is_false()
	assert_int(_val("cabinet/world", "hostile_shots")).is_equal(0)


func test_shoot_vigil_rejects_a_zero_offset_and_respects_shield() -> void:
	assert_str(probe.dev_op("shoot_vigil", {"dx": 0, "dy": 0})).contains("both be 0")
	assert_int(_val("cabinet/world", "shots")).is_equal(0)
	world.vigil.shield = 5.0
	probe.dev_op("shoot_vigil", {"dx": 0, "dy": -40})
	for i in 40:
		world.step(DT)
	assert_bool(_val("cabinet/vigil", "alive")).is_true()


func test_kill_all_clears_acolytes_grubs_and_hostile_shots_only() -> void:
	world.start(_grub_stage())
	probe.dev_op("spawn", {"kind": "acolyte", "dx": 0, "dy": -90})
	probe.dev_op("spawn", {"kind": "geode", "dx": 80, "dy": 0})
	probe.dev_op("shoot_vigil", {"dx": 0, "dy": -200})
	world.shots.fire_lance(world.vigil.pos, Vector2.UP, Vector2.ZERO)
	var phase_before: int = world.ritual.phase
	assert_str(probe.dev_op("kill_all", {})).is_empty()
	assert_int(_val("cabinet/world", "acolytes")).is_equal(0)
	assert_int(_val("cabinet/world", "grubs")).is_equal(0)
	assert_int(_val("cabinet/world", "hostile_shots")).is_equal(0)
	assert_int(_val("cabinet/world", "shots")).is_equal(1)    # the Vigil's own lance bolt stays
	assert_int(_val("cabinet/world", "geodes")).is_equal(1)
	assert_int(world.ritual.phase).is_equal(phase_before)


func test_pause_and_step_sim() -> void:
	assert_str(probe.dev_op("pause_sim", {"on": false})).is_empty()
	assert_bool(world.paused_sim).is_false()
	assert_str(probe.dev_op("step_sim", {"frames": 5})).contains("needs paused_sim")
	assert_float(world.time).is_equal(0.0)
	assert_str(probe.dev_op("pause_sim", {"on": true})).is_empty()
	assert_str(probe.dev_op("step_sim", {"frames": 30})).is_empty()
	assert_float(world.time).is_equal_approx(0.5, 0.001)
	assert_str(probe.dev_op("step_sim", {"frames": 0})).contains("1..")
	assert_str(probe.dev_op("step_sim", {"frames": 4000})).contains("1..")
	assert_int(game.state).is_equal(game.State.INTRO)   # the state machine did not run


func test_unknown_op_and_not_ready() -> void:
	assert_str(probe.dev_op("explode", {})).contains("unknown cabinet op")
	var bare: RefCounted = Probe.new()
	assert_str(bare.dev_op("kill_all", {})).contains("not ready")
	assert_bool(bare.read("cabinet/vigil", "alive").ok).is_false()
	assert_bool(bare.has("cabinet/vigil")).is_false()
	assert_str(bare.snapshot().route).is_equal("cabinet")


# --- snapshot ----------------------------------------------------------------------------------

func test_snapshot_shape_and_caps() -> void:
	probe.dev_op("spawn", {"kind": "acolyte", "dx": 0, "dy": -90})
	probe.dev_op("spawn", {"kind": "geode", "dx": 60, "dy": 0})
	var s: Dictionary = probe.snapshot()
	for k in ["route", "game", "score", "record", "vigil", "world", "acolytes", "grubs", "geodes"]:
		assert_bool(s.has(k)).override_failure_message(k).is_true()
	assert_str(s.game.state).is_equal("intro")
	assert_int(s.acolytes.size()).is_equal(1)
	var a: Dictionary = s.acolytes[0]
	assert_array(a.keys()).contains(["id", "alive", "hp", "pos_x", "pos_y", "on_screen", "dx", "dy"])
	assert_int(s.geodes[0].index).is_equal(0)
	assert_array(s.geodes[0].keys()).contains(["index", "alive", "faces_left"])
	assert_bool(JSON.stringify(s) != "").is_true()
	for i in 250:
		world.acolytes.spawn(Vector2(float(i), 10.0))
		world.geodes.add_geode(Vector2(float(i), 20.0), 0)
	var big: Dictionary = probe.snapshot()
	assert_int(big.acolytes.size()).is_equal(200)
	assert_int(big.geodes.size()).is_equal(200)


func test_describe_lists_ids_events_and_ops() -> void:
	var d: Dictionary = probe.describe()
	assert_array(d.ids).contains(["cabinet/game", "cabinet/vigil", "cabinet/acolyte/*"])
	assert_array(d.events).contains(["vigil_destroyed", "score_awarded", "hitstop_started"])
	assert_array(d.dev_ops).contains(["set_stage", "step_sim"])
	assert_array(probe.event_names()).contains(["vigil_destroyed"])


# --- events ------------------------------------------------------------------------------------

func test_events_fire_and_disconnect_leaves_nothing_connected() -> void:
	var seen: Array = []
	probe.connect_events(func(id: String, args: Array) -> void: seen.append([id, args]))
	world.vigil.shield = 0.0
	probe.dev_op("shoot_vigil", {"dx": 0, "dy": -60})
	for i in 40:
		world.step(DT)
	var ids: Array = seen.map(func(e: Array) -> String: return e[0])
	assert_array(ids).contains(["vigil_destroyed"])
	assert_array(ids).contains(["hitstop_started"])
	var hs: Array = seen.filter(func(e: Array) -> bool: return e[0] == "hitstop_started")[0]
	assert_array(hs[1]).is_equal(["vigil_death"])
	world.award(150, Vector2(3, 4))
	var sa: Array = seen.filter(func(e: Array) -> bool: return e[0] == "score_awarded")[0]
	assert_array(sa[1]).is_equal([150, 3.0, 4.0])
	world.glass.set_charges(2)
	assert_array(seen.filter(func(e: Array) -> bool: return e[0] == "charges_changed")[0][1]).is_equal([2])
	probe.disconnect_events()
	for sig in [world.vigil_destroyed, world.score_awarded, world.hitstop_started, world.slowmo_changed,
			world.sepulchre_cleared, world.entity_unmade, world.phase_changed, world.segments_changed, world.charges_changed]:
		var mine := 0
		for c: Dictionary in (sig as Signal).get_connections():
			if (c.callable as Callable).get_object() == probe:
				mine += 1
		assert_int(mine).override_failure_message("a probe connection is left on " + str(sig)).is_equal(0)
	var n := seen.size()
	world.vigil_destroyed.emit()
	assert_int(seen.size()).is_equal(n)


func test_phase_and_other_events_carry_scalars() -> void:
	var seen: Array = []
	probe.connect_events(func(id: String, args: Array) -> void: seen.append([id, args]))
	world.phase_changed.emit(SepulchreRitual.Phase.GUARD)
	world.segments_changed.emit(4)
	world.slowmo_changed.emit(0.5)
	world.sepulchre_cleared.emit()
	world.entity_unmade.emit()
	assert_array(seen[0]).is_equal(["phase_changed", ["guard"]])
	assert_array(seen[1]).is_equal(["segments_changed", [4]])
	assert_array(seen[2]).is_equal(["slowmo_changed", [0.5]])
	assert_str(seen[3][0]).is_equal("sepulchre_cleared")
	assert_str(seen[4][0]).is_equal("entity_unmade")
