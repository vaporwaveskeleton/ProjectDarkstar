extends GdUnitTestSuite
## Owner report (2026-11-20): "After the third unmaking the game says 'thank you for playing' but does not
## move to the reveal." A human shift is always clean-handed (Act 0 has no Surgelight; only the autopilot
## spoils it), so every human's last credits roll into ending 5: Theodora's ten held screens, the first of
## which reads THANK YOU FOR PLAYING. They were held for `ui_accept` only (Enter/Space), with no prompt, so a
## player who plays with the mouse/lance button sat on screen 1 for ever. Scenarios flew with the autopilot,
## which is never clean, so none of them ever reached ending 5.
## Real input, real flow: last stage unmade → full credits → ending 5 → Decay (reveal proper), for the data
## roster (four stages) AND a debug-menu roster (three stages). TECH-001 §2.10, Q-T186, Q-T452, Q-T454.

const SCENE := preload("res://features/cabinet/cabinet_game.tscn")

var game: Node
var messages: CabinetMessages


func before_test() -> void:
	AudioService.muted_for_tests = true
	SaveService.set_backend(MemorySaveBackend.new())


func after_test() -> void:
	if is_instance_valid(game):
		game.free()
	AudioService.muted_for_tests = false
	SaveService.set_backend(FileSaveBackend.new())
	get_tree().paused = false


## A game on its last stage, unmade, as a human leaves it (no autopilot, no Surgelight).
func _human_shift(stage_count: int) -> void:
	game = SCENE.instantiate()
	add_child(game)
	game.set_process(false)
	messages = game.get_node("%Messages")
	messages.set_process(false)
	game.get_node("%World").paused_sim = true
	if stage_count < game.roster.stages.size():   # what the debug menu's "in shift" lamps build
		var picked: Array[CabinetStage] = []
		for i in stage_count:
			picked.append(game.roster.stages[game.roster.stages.size() - stage_count + i])
		var r := CabinetStageRoster.new()
		r.stages = picked
		game.roster = r
	assert_int(game.stages.size()).is_equal(stage_count)
	game.autopilot.enabled = false
	game.clean_hands = true
	game.start_stage(stage_count - 1)
	game.dismiss_brief()
	game.state = game.State.UNMADE
	game._on_timer()                       # the last Unmaking ends: the full credits roll
	assert_int(game.state).is_equal(game.State.CREDITS)
	game._on_timer()                       # the credits end: THE PRETENCE
	assert_int(game.state).is_equal(game.State.REVEAL)


func _press(action: StringName) -> void:
	var down := InputEventAction.new()
	down.action = action
	down.pressed = true
	Input.parse_input_event(down)
	await get_tree().process_frame
	var up := InputEventAction.new()
	up.action = action
	up.pressed = false
	Input.parse_input_event(up)
	await get_tree().process_frame


func _reach_decay(action: StringName) -> void:
	await get_tree().process_frame
	await get_tree().process_frame
	assert_str(messages.held_screen()).is_equal(tr("CAB_E5_SCREEN_01"))   # THANK YOU FOR PLAYING.
	var shown := 1
	while messages.held_screen() != tr("REVEAL_PRETENCE") and shown < 12:
		var before := messages.held_screen()
		await _press(action)
		await get_tree().process_frame
		assert_str(messages.held_screen()).override_failure_message("a %s press must leave screen %d" % [action, shown]).is_not_equal(before)
		shown += 1
	assert_int(shown).is_equal(PretenceReveal.ENDING5_KEYS.size() + 1)


func test_ending5_screen_one_says_thank_you_and_shows_how_to_go_on() -> void:
	_human_shift(4)
	await get_tree().process_frame
	await get_tree().process_frame
	assert_str(messages.held_screen()).is_equal(tr("CAB_E5_SCREEN_01"))
	assert_bool(messages.held_prompt()).override_failure_message("a held screen must tell the player to press fire").is_true()


func test_the_lance_button_moves_on_through_ending5_to_the_decay_on_the_data_roster() -> void:
	_human_shift(4)
	await _reach_decay(&"fire_lance")


func test_the_lance_button_moves_on_through_ending5_to_the_decay_on_a_debug_menu_roster() -> void:
	_human_shift(3)
	await _reach_decay(&"fire_lance")


func test_enter_and_space_still_move_on() -> void:
	_human_shift(4)
	await _reach_decay(&"ui_accept")


func test_ending5_never_runs_for_an_autopilot_shift() -> void:
	_human_shift(4)
	game.reveal._running = false
	game.autopilot.enabled = true
	game.clean_hands = true
	game._note_hands()
	assert_bool(game.clean_hands).is_false()
