extends GdUnitTestSuite
## Act 0 density (the 1983 reference shows 4-8 actors and 1-3 rocks per screen; every number PROPOSED ✱):
## each stage is played by the autopilot for 80 sim s on three seeds; every 2 s between 20 s and 80 s the
## live geodes and actors (Grubs + Acolytes) inside the 256 x 256 play view are counted. Loose bands only;
## the means per stage are printed. Driven tick by tick, no audio, saves in memory.

const SCENE := preload("res://features/cabinet/cabinet_game.tscn")
const Shift := preload("res://features/cabinet/tests/test_autopilot_shift.gd")
const DT := 1.0 / 60.0
const SEEDS: Array[int] = [0, 1, 2]
const SAMPLE_FROM_S := 20.0
const SAMPLE_TO_S := 80.0
const SAMPLE_EVERY_S := 2.0

var _means := {}


func before_test() -> void:
	AudioService.muted_for_tests = true
	SaveService.set_backend(MemorySaveBackend.new())


func after_test() -> void:
	AudioService.muted_for_tests = false
	SaveService.set_backend(FileSaveBackend.new())
	get_tree().paused = false


## Mean {geodes, actors} in view for stage `idx` over SEEDS.
func _measure(idx: int) -> Dictionary:
	var geodes := 0.0
	var actors := 0.0
	var grubs := 0.0
	var n := 0
	for k in SEEDS:
		var game := SCENE.instantiate() as CabinetGame
		game.roster = Shift.shifted_roster(k)
		add_child(game)
		game.set_process(false)
		(game.get_node("%Messages") as Node).set_process(false)
		var world: ArcadeWorld = game.world
		world.paused_sim = true
		var pilot: CabinetAutopilot = game.autopilot
		pilot.enabled = true
		pilot.set_physics_process(false)
		game.start_stage(idx)
		var secs := 0.0
		var next_sample := SAMPLE_FROM_S
		while secs < SAMPLE_TO_S and game.state != CabinetGame.State.GAME_OVER:
			if game.state == CabinetGame.State.BRIEFING:
				game.dismiss_brief()
			pilot._physics_process(DT)
			world.step(DT)
			if game._timer > 0.0:
				game._timer -= DT
				if game._timer <= 0.0:
					game._on_timer()
			secs += DT
			if secs >= next_sample:
				next_sample += SAMPLE_EVERY_S
				geodes += _in_view(world, world.geodes.items)
				grubs += _in_view(world, world.grubs.items)
				actors += _in_view(world, world.grubs.items) + _in_view(world, world.acolytes.items)
				n += 1
		game.free()
	return {"geodes": geodes / maxf(1.0, n), "actors": actors / maxf(1.0, n), "grubs": grubs / maxf(1.0, n)}


static func _in_view(world: ArcadeWorld, items: Array) -> int:
	var c := 0
	for x in items:
		if x.alive and world.on_screen(x.pos, 0.0):
			c += 1
	return c


func test_each_stage_shows_a_busy_screen_shaped_by_its_trait() -> void:
	var lines := PackedStringArray()
	for i in 5:
		_means[i] = _measure(i)
		lines.append("a0_%d: %.2f geodes, %.2f actors in view (%.2f Grubs)" % [i + 1, _means[i]["geodes"], _means[i]["actors"], _means[i]["grubs"]])
	print("act0 density (mean over seeds %s, %.0f-%.0f s every %.0f s):\n  %s" % [str(SEEDS), SAMPLE_FROM_S, SAMPLE_TO_S, SAMPLE_EVERY_S, "\n  ".join(lines)])
	# floors are about 80 % of the measured means (the bot kills Acolytes on sight, so a human sees more actors)
	var msg := "\n".join(lines)
	assert_float(_means[0]["actors"]).override_failure_message("a0_1 actors\n%s" % msg).is_greater_equal(3.0)
	for i in [1, 2, 3]:
		assert_float(_means[i]["actors"]).override_failure_message("a0_%d actors\n%s" % [i + 1, msg]).is_greater_equal(3.2)
		assert_float(_means[i]["geodes"]).override_failure_message("a0_%d geodes\n%s" % [i + 1, msg]).is_greater_equal(1.2)
	assert_float(_means[4]["geodes"]).override_failure_message("a0_5 stays sparse\n%s" % msg).is_less_equal(0.6)
	assert_float(_means[4]["geodes"]).override_failure_message("a0_5 sparser than a0_4\n%s" % msg).is_less_equal(_means[3]["geodes"])
	assert_float(_means[4]["actors"]).override_failure_message("a0_5 actors\n%s" % msg).is_greater_equal(1.6)
