extends GdUnitTestSuite
## The shift's stage flow (PM 2026-11-19, Q-T104c): every stage's credits lead to the next stage,
## cleared or unmade; only the last stage rolls the full credits and opens THE PRETENCE; GAME OVER
## hands attract the stage a CONTINUE restarts; the cabinet routed with it starts a new game there.

const SCENE := preload("res://features/cabinet/cabinet_game.tscn")

var game: Node
var world: ArcadeWorld
var messages: CabinetMessages


func before_test() -> void:
	AudioService.muted_for_tests = true
	SaveService.set_backend(MemorySaveBackend.new())
	game = SCENE.instantiate()
	add_child(game)
	game.set_process(false)
	world = game.get_node("%World")
	world.paused_sim = true
	messages = game.get_node("%Messages")
	messages.set_process(false)


func after_test() -> void:
	if is_instance_valid(game):
		game.free()
	AudioService.muted_for_tests = false
	SaveService.set_backend(FileSaveBackend.new())
	get_tree().paused = false


func _last() -> int:
	return game.stages.size() - 1


# --- credits → next stage -----------------------------------------------------------------

func test_a_mid_shift_unmade_rolls_the_short_credits_then_starts_the_next_stage() -> void:
	game.start_stage(2)    # a0_3: the entity wakes, but the shift goes on
	game.state = game.State.UNMADE
	game._on_timer()
	assert_int(game.state).is_equal(game.State.CREDITS)
	assert_int(messages.credits.size()).is_equal(3)
	for line in messages.credits:
		assert_bool(line.contains(":")).override_failure_message("no service record mid-shift").is_false()
	game._on_timer()
	assert_int(game.state).is_equal(game.State.INTRO)
	assert_int(game.stage_index).is_equal(3)
	assert_str(String(world.stage.id)).is_equal("a0_4")


func test_a_cleared_stage_starts_the_next_stage() -> void:
	game.start_stage(1)    # a0_2: cold
	game.state = game.State.CLEARED
	game._on_timer()
	game._on_timer()
	assert_int(game.state).is_equal(game.State.INTRO)
	assert_int(game.stage_index).is_equal(2)


func test_every_stage_but_the_last_has_a_next_stage() -> void:
	for i in _last():
		game.stage_index = i
		assert_bool(game.is_last_stage()).is_false()
		assert_int(game.next_stage_index()).is_equal(i + 1)
	game.stage_index = _last()
	assert_bool(game.is_last_stage()).is_true()
	assert_int(game.next_stage_index()).override_failure_message("after the last stage comes THE PRETENCE").is_equal(-1)


func test_the_last_stage_unmade_rolls_the_full_credits() -> void:
	game.start_stage(_last())
	game.state = game.State.UNMADE
	game._on_timer()
	assert_int(game.state).is_equal(game.State.CREDITS)
	assert_int(messages.credits.size()).is_equal(game.CREDIT_KEYS.size() + game.STAT_KEYS.size())
	assert_float(game._timer).is_equal(world.fx_tuning.credits_full_seconds)


# --- GAME OVER and CONTINUE -----------------------------------------------------------------

func test_game_over_hands_attract_the_current_stage() -> void:
	game.start_stage(3)
	assert_dict(game._game_over_params()).is_equal({"continue_stage": 3})


func test_the_demo_game_over_hands_nothing() -> void:
	game.demo = true
	assert_dict(game._game_over_params()).is_empty()


func test_continue_starts_a_new_game_at_that_stage() -> void:
	game.score.add(500)
	game.score.lose_life()
	game.record.grubs_destroyed = 4
	game.on_route_entered({"continue_stage": 3})
	assert_int(game.stage_index).is_equal(3)
	assert_str(String(world.stage.id)).is_equal("a0_4")
	assert_int(game.state).is_equal(game.State.INTRO)
	assert_int(game.score.score).is_equal(0)
	assert_int(game.score.lives).is_equal(game.tuning.lives_start)
	assert_int(game.record.grubs_destroyed).is_equal(0)
	assert_bool(game.demo).is_false()


func test_invalid_continue_values_keep_stage_zero() -> void:
	for bad: Variant in [-1, 99, "3", null]:
		game.on_route_entered({"continue_stage": bad})
		assert_int(game.stage_index).override_failure_message("continue_stage %s" % [bad]).is_equal(0)
	game.on_route_entered({})
	assert_int(game.stage_index).is_equal(0)


func test_continue_stage_parsing() -> void:
	assert_int(game.continue_stage_of({"continue_stage": 4}, 5)).is_equal(4)
	assert_int(game.continue_stage_of({&"continue_stage": 2}, 5)).is_equal(2)
	assert_int(game.continue_stage_of({"continue_stage": 2.0}, 5)).is_equal(2)
	assert_int(game.continue_stage_of({"continue_stage": 5}, 5)).is_equal(-1)
	assert_int(game.continue_stage_of({"continue_stage": -2}, 5)).is_equal(-1)
	assert_int(game.continue_stage_of({"continue_stage": "1"}, 5)).is_equal(-1)
	assert_int(game.continue_stage_of({}, 5)).is_equal(-1)


func test_the_continue_line_counts_stages_from_one() -> void:
	var s: String = game.continue_line(2)
	assert_str(s).contains("3")
	assert_bool(s.contains("{stage}")).is_false()


# --- the READY card's zone line --------------------------------------------------------------

func test_the_ready_card_shows_the_zone_line_when_the_stage_has_one() -> void:
	game.start_stage(0)
	assert_str(messages.ready_zone()).is_empty()
	game.start_stage(1)
	assert_str(messages.ready_zone()).is_equal(tr("CAB_ZONE_DRIFT"))
	var top := messages.ready_zone_top()
	assert_float(top).is_greater_equal(0.0)
	assert_float(top + messages.block_height(messages.ready_zone(), 1)).is_less_equal(messages.ready_title_top())


## Reviewer, PR #57: the Vigil spawns at the play-view centre, so no READY card may reach it.
func test_every_ready_card_ends_above_the_vigil_spawn() -> void:
	for i in game.stages.size():
		game.start_stage(i)
		assert_float(messages.ready_bottom()).override_failure_message("stage %d card reaches the Vigil" % i) \
			.is_less_equal(messages.size.y * 0.5 - 12.0)
		var top := messages.ready_zone_top() if not messages.ready_zone().is_empty() else messages.ready_title_top()
		assert_float(top).override_failure_message("stage %d card leaves the screen" % i).is_greater_equal(0.0)
