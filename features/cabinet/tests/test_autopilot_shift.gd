extends GdUnitTestSuite
## The autopilot plays the whole Act 0 shift (a0_1 → a0_5) honestly: the real CabinetGame scene,
## its default lives and extra-life schedule, its own death → respawn → GAME OVER state machine.
## The bot only reads the world and writes the Vigil's scripted inputs; nothing here touches lives,
## shields or stage data. Seeds vary by giving every stage `seed + k * SEED_STRIDE` (k = 0 is the
## shipped shift). Driven tick by tick, no audio, saves in memory.

const SCENE := preload("res://features/cabinet/cabinet_game.tscn")
const DT := 1.0 / 60.0
const SEED_STRIDE := 1000
const STAGE_LIMIT_S := 420.0       ## sim seconds a stage may take before the run counts as stalled
const State := CabinetGame.State

## The fixed seeds this suite plays, and the honest floor: at least MIN_REACHED of them clear all
## MIN_STAGES stages (the whole shift, a0_1–a0_5) with the default lives. Measured 2026-11-19 on seeds
## +0…+7 at the Act 0 scale (65,536 px field, Vigil neighbourhood, Grubs and Acolytes spawning in the box;
## SYS-001 §1.7, PROPOSED): 4/8 full shifts cleared (+3, +4, +5, +6), 0 games lost; the other four stall in
## a0_2 (Acolytes and 7 pilfering Grubs keep the bot in a duel with 2 Charges) or a0_5. At the old 1,920 px
## field it was 19/20. A smarter bot is open work; stages take 20–390 sim s here.
const SEEDS: Array[int] = [0, 1, 2, 3, 4, 5, 6, 7]
const MIN_STAGES := 5
const MIN_REACHED := 4


func before_test() -> void:
	AudioService.muted_for_tests = true
	SaveService.set_backend(MemorySaveBackend.new())


func after_test() -> void:
	AudioService.muted_for_tests = false
	SaveService.set_backend(FileSaveBackend.new())
	get_tree().paused = false


## The shipped roster with every stage's seed moved by k * SEED_STRIDE (k = 0: unchanged).
static func shifted_roster(k: int) -> CabinetStageRoster:
	var base := CabinetStageRoster.default_roster()
	var r := CabinetStageRoster.new()
	var out: Array[CabinetStage] = []
	for st in base.stages:
		var s := st.duplicate() as CabinetStage
		s.seed = st.seed + k * SEED_STRIDE
		out.append(s)
	r.stages = out
	return r


## Plays one whole shift on seed offset `k` (or on `roster` when given). Returns {cleared: bool, stage: int (index reached),
## lives: int (left at the end), seconds: float (sim), stalled: bool}.
func play_shift(k: int, roster: CabinetStageRoster = null) -> Dictionary:
	var game := SCENE.instantiate() as CabinetGame
	game.roster = roster if roster != null else shifted_roster(k)
	add_child(game)
	game.set_process(false)
	(game.get_node("%Messages") as Node).set_process(false)
	var world: ArcadeWorld = game.world
	world.paused_sim = true
	var pilot: CabinetAutopilot = game.autopilot
	pilot.enabled = true
	pilot.set_physics_process(false)
	var last := game.stages.size() - 1
	var seconds := 0.0
	var stage_t := 0.0
	var at_stage := game.stage_index
	var result := {"cleared": false, "stage": 0, "lives": 0, "seconds": 0.0, "stalled": false}
	var stage_secs := PackedStringArray()      # sim seconds each stage took (for the test log)
	while true:
		pilot._physics_process(DT)
		world.step(DT)
		# CabinetGame._process's timer, without the CRT/clear-colour presentation
		if game._timer > 0.0:
			game._timer -= DT
			if game._timer <= 0.0:
				if game.state == State.GAME_OVER:
					break
				if game.state == State.CREDITS and game.stage_index == last:
					break
				game._on_timer()
		seconds += DT
		if game.stage_index != at_stage:
			stage_secs.append("%.0f" % stage_t)
			at_stage = game.stage_index
			stage_t = 0.0
		stage_t += DT
		if game.stage_index == last and (game.state == State.CLEARED or game.state == State.UNMADE):
			result["cleared"] = true
			break
		if game.state == State.GAME_OVER:
			break
		if stage_t > STAGE_LIMIT_S:
			result["stalled"] = true
			break
	result["stage"] = game.stage_index
	result["lives"] = game.score.lives
	result["seconds"] = seconds
	result["stage_secs"] = ",".join(stage_secs)
	var r := world.ritual
	result["diag"] = "grubs_killed %d deposits %d grubs %d phase %d awake %s segments %d hits_left %d charges %d acolytes %d shards %d geodes %d" % [game.record.grubs_destroyed, game.record.glass_carried, world.grubs.items.size(), r.phase,
			r.awake, r.segments, r.hits_left, world.glass.charges, world.acolytes.living_count(),
			world.glass.shards.size(), world.geodes.items.size()]
	game.free()
	return result


## Stages cleared in a play_shift() result: all of them when cleared, else the index it ended on.
static func stages_cleared(r: Dictionary, total: int) -> int:
	return total if bool(r["cleared"]) else int(r["stage"])


func test_autopilot_plays_the_shift_with_default_lives() -> void:
	var total := CabinetStageRoster.default_roster().stages.size()
	var reached := 0
	var clears := 0
	var lines := PackedStringArray()
	for k in SEEDS:
		var r := play_shift(k)
		var n := stages_cleared(r, total)
		if n >= MIN_STAGES:
			reached += 1
		if bool(r["cleared"]):
			clears += 1
		var how := "CLEARED" if r["cleared"] else ("stalled" if r["stalled"] else "game over")
		lines.append("seed+%d: %s, %d/%d stages cleared, lives %d, %.0f sim s (stage s: %s) | %s" % [k, how, n, total,
				int(r["lives"]), float(r["seconds"]), str(r["stage_secs"]), str(r["diag"])])
	print("autopilot shift: %d/%d cleared all, %d/%d cleared >= %d stages\n  %s" % [clears, SEEDS.size(), reached,
			SEEDS.size(), MIN_STAGES, "\n  ".join(lines)])
	assert_int(reached).override_failure_message("with default lives the autopilot cleared >= %d stages on %d of %d seeds (floor %d):\n%s"
			% [MIN_STAGES, reached, SEEDS.size(), MIN_REACHED, "\n".join(lines)]).is_greater_equal(MIN_REACHED)
