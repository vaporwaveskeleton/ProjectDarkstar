extends GdUnitTestSuite
## The shift's stage flow (PM 2026-11-19, Q-T104c): a mid-shift stage end (cleared or unmade) holds
## its banner, then the next stage starts, with no roll; only the last stage rolls the full credits
## and opens THE PRETENCE; GAME OVER hands attract the stage a CONTINUE restarts and the shift total;
## the cabinet routed with them starts a new game there. The profile keeps the furthest stage reached.

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

func test_a_mid_shift_unmade_holds_the_banner_then_starts_the_next_stage() -> void:
	game.start_stage(0)    # a0_3: the entity wakes, but the shift goes on
	game.state = game.State.UNMADE
	game._on_timer()
	assert_int(game.state).is_equal(game.State.CREDITS)
	assert_float(messages.credits_t).override_failure_message("no roll mid-shift: banner only").is_less(0.0)
	assert_str(messages._banner).is_equal(tr("CAB_ENTITY_DOWN"))
	assert_float(messages._banner_t).is_equal(game.MID_SHIFT_HOLD_SECONDS)
	assert_float(game._timer).is_equal(game.MID_SHIFT_HOLD_SECONDS)
	game._on_timer()
	assert_int(game.state).is_equal(game.State.BRIEFING)   # the next stage opens on its stage card
	assert_int(game.stage_index).is_equal(1)
	assert_str(String(world.stage.id)).is_equal("a0_4")


func test_a_cleared_stage_starts_the_next_stage() -> void:
	game.start_stage(0)    # (a cold stage is off the shift since F-14; the hand-off does not depend on the goal)
	game.state = game.State.CLEARED
	game._on_timer()
	assert_float(messages.credits_t).override_failure_message("no roll mid-shift: banner only").is_less(0.0)
	assert_str(messages._banner).is_equal(tr("CAB_VIGIL_COMPLETE"))
	game._on_timer()
	assert_int(game.state).is_equal(game.State.BRIEFING)   # the next stage opens on its stage card
	assert_int(game.stage_index).is_equal(1)


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

func test_game_over_hands_attract_the_current_stage_and_the_shift_total() -> void:
	game.on_route_entered({})
	game.start_stage(1)
	game.score.add(1500)
	assert_dict(game._game_over_params()).is_equal({"continue_stage": 1, "shift_total": 1500})


func test_the_demo_game_over_hands_nothing() -> void:
	game.demo = true
	assert_dict(game._game_over_params()).is_empty()


func test_continue_starts_a_new_game_at_that_stage() -> void:
	game.score.add(500)
	game.score.lose_life()
	game.record.grubs_destroyed = 4
	game.on_route_entered({"continue_stage": 1})
	assert_int(game.stage_index).is_equal(1)
	assert_str(String(world.stage.id)).is_equal("a0_4")
	assert_int(game.state).is_equal(game.State.BRIEFING)   # the next stage opens on its stage card
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
	game.dismiss_brief()                # the READY card follows the stage card
	assert_str(messages.ready_zone()).is_equal(tr("CAB_ZONE_CENSER_WATCH"))
	game.start_stage(1)
	game.dismiss_brief()
	var top := messages.ready_zone_top()
	assert_str(messages.ready_zone()).is_equal(tr("CAB_ZONE_SHOAL"))
	assert_float(top).is_greater_equal(0.0)
	assert_float(top + messages.block_height(messages.ready_zone(), 1)).is_less_equal(messages.ready_title_top())


## Reviewer, PR #57: the Vigil spawns at the play-view centre, so no READY card may reach it.
func test_every_ready_card_ends_above_the_vigil_spawn() -> void:
	for i in game.stages.size():
		game.start_stage(i)
		game.dismiss_brief()
		assert_float(messages.ready_bottom()).override_failure_message("stage %d card reaches the Vigil" % i) \
			.is_less_equal(messages.size.y * 0.5 - 12.0)
		var top := messages.ready_zone_top() if not messages.ready_zone().is_empty() else messages.ready_title_top()
		assert_float(top).override_failure_message("stage %d card leaves the screen" % i).is_greater_equal(0.0)


# --- the shift total (route-carried, never saved) and the furthest stage (profile) -----------

## Mount a new cabinet over a fresh in-memory profile slot holding `profile` (none when empty).
func _remount(profile: Dictionary) -> void:
	game.free()
	SaveService.set_backend(MemorySaveBackend.new())
	if not profile.is_empty():
		SaveService.save_slot(&"profile", profile, &"cabinet_score")
	game = SCENE.instantiate()
	add_child(game)
	game.set_process(false)
	world = game.get_node("%World")
	world.paused_sim = true
	messages = game.get_node("%Messages")
	messages.set_process(false)


func _saved() -> Dictionary:
	var r := SaveService.load_slot(&"profile")
	var p: Dictionary = r.payload
	return p


func _reached() -> int:
	return int(_saved().get("act0_stage_reached", -99))


func test_a_fresh_shift_starts_at_zero_and_restarts_the_furthest_stage() -> void:
	_remount({"act0_stage_reached": 3, "cabinet_hi_score": 1234, "pretence_seen": true, "cabinet_tape_peeled": true})
	game.on_route_entered({})
	assert_int(game.shift_total()).is_equal(0)
	var p := _saved()
	assert_int(int(p.get("act0_stage_reached", -99))).is_equal(0)
	assert_int(int(p.get("cabinet_hi_score", 0))).override_failure_message("existing keys are merged, not dropped").is_equal(1234)
	assert_bool(bool(p.get("pretence_seen", false))).is_true()
	assert_bool(bool(p.get("cabinet_tape_peeled", false))).is_true()
	assert_bool(p.has("act0_shift_total")).override_failure_message("the shift total is never saved").is_false()


func test_stage_start_saves_the_furthest_stage_as_a_max() -> void:
	game.on_route_entered({})
	game.start_stage(1)
	assert_int(_reached()).is_equal(1)
	game.start_stage(0)
	assert_int(_reached()).is_equal(1)
	game.start_stage(2)
	assert_int(_reached()).is_equal(2)


func test_an_unrouted_start_opens_a_fresh_shift_once_the_frame_ends() -> void:
	_remount({"act0_stage_reached": 2})
	assert_int(_reached()).override_failure_message("no write before the route decides").is_equal(2)
	await get_tree().process_frame
	await get_tree().process_frame
	assert_int(_reached()).is_equal(0)


func test_game_over_then_continue_carries_the_shift_total() -> void:
	game.on_route_entered({})
	game.start_stage(2)
	game.score.add(1500)
	game.score.lives = 1
	game.state = game.State.DEAD
	game._on_timer()                                   # last life: GAME OVER, hi-score saved
	assert_int(game.state).is_equal(game.State.GAME_OVER)
	assert_bool(_saved().has("act0_shift_total")).is_false()
	var params: Dictionary = game._game_over_params()
	assert_dict(params).is_equal({"continue_stage": 2, "shift_total": 1500})
	_remount(_saved())                                 # attract → CONTINUE mounts a new cabinet
	game.on_route_entered(params)
	assert_int(game.stage_index).is_equal(2)
	assert_int(game.score.score).override_failure_message("the on-screen score resets per credit").is_equal(0)
	assert_int(game.shift_total()).is_equal(1500)
	game.score.add(200)
	assert_int(game.shift_total()).is_equal(1700)
	assert_int(_reached()).is_equal(2)
	var again: Dictionary = game._game_over_params()
	assert_int(int(again.get("shift_total", 0))).is_equal(1700)


func test_a_continue_without_a_shift_total_starts_from_zero() -> void:
	game.on_route_entered({"continue_stage": 2})
	assert_int(game.shift_total()).is_equal(0)
	assert_int(_reached()).is_equal(2)


func test_shift_total_parsing() -> void:
	assert_int(game.shift_total_of({})).is_equal(0)
	assert_int(game.shift_total_of({"shift_total": 1500})).is_equal(1500)
	assert_int(game.shift_total_of({&"shift_total": 1500.0})).is_equal(1500)
	assert_int(game.shift_total_of({"shift_total": "1500"})).is_equal(0)
	assert_int(game.shift_total_of({"shift_total": -5})).is_equal(0)
	assert_int(game.shift_total_of({"shift_total": null})).is_equal(0)


func test_the_reveal_clears_the_furthest_stage() -> void:
	game.on_route_entered({})
	game.start_stage(2)
	game.score.add(300)
	game._save_act0_complete()
	var p := _saved()
	assert_int(int(p.get("act0_stage_reached", -99))).is_equal(-1)
	assert_bool(bool(p.get("act0_complete", false))).is_true()
	assert_bool(p.has("act0_shift_total")).is_false()
	assert_int(int(p.get("act0_pending_vi", -1))).is_equal(300)   # Q-T141
	var to_ruins: Dictionary = game._reveal_params()
	assert_dict(to_ruins).is_equal({"shift_total": 300, "act0_vigil_index": 300})   # TECH-001 §4.2a


func test_the_demo_never_writes() -> void:
	_remount({})
	game.on_route_entered({"demo": true})
	game.start_stage(1)
	game._save_hi_score()
	game._save_act0_complete()
	await get_tree().process_frame                     # the deferred fresh-shift fallback, too
	await get_tree().process_frame
	assert_bool(SaveService.has_slot(&"profile")).is_false()


func test_saved_continue_stage_edge_cases() -> void:
	assert_int(game.saved_continue_stage({}, 3)).is_equal(-1)
	assert_int(game.saved_continue_stage({"act0_stage_reached": -1}, 3)).is_equal(-1)
	assert_int(game.saved_continue_stage({"act0_stage_reached": "2"}, 3)).is_equal(-1)
	assert_int(game.saved_continue_stage({"act0_stage_reached": 1}, 3)).is_equal(1)
	assert_int(game.saved_continue_stage({"act0_stage_reached": 1.0}, 3)).override_failure_message("JSON numbers load as floats").is_equal(1)
	assert_int(game.saved_continue_stage({"act0_stage_reached": 2, "act0_complete": true}, 3)).is_equal(-1)
	assert_int(game.saved_continue_stage({"act0_stage_reached": 2, "act0_complete": false}, 3)).is_equal(2)
	assert_int(CabinetGame.saved_continue_stage({"act0_stage_reached": 2}, CabinetStageRoster.default_size())).is_equal(2)


## F-14: a profile saved by the five-stage build (stage_reached 3 or 4) clamps to the last of the three stages.
func test_a_stage_reached_from_the_five_stage_build_clamps_to_the_last_stage() -> void:
	var n := CabinetStageRoster.default_size()
	assert_int(n).is_equal(3)
	assert_int(CabinetGame.saved_continue_stage({"act0_stage_reached": 3}, n)).is_equal(2)
	assert_int(CabinetGame.saved_continue_stage({"act0_stage_reached": 4}, n)).is_equal(2)
	assert_int(CabinetGame.saved_continue_stage({"act0_stage_reached": 4.0}, n)).is_equal(2)
	assert_int(CabinetGame.saved_continue_stage({"act0_stage_reached": 0}, n)).is_equal(0)
	assert_int(CabinetGame.saved_continue_stage({"act0_stage_reached": 4, "act0_complete": true}, n)).is_equal(-1)


func test_stage_record_start_is_taken_at_each_stage_start() -> void:
	game.record.grubs_destroyed = 4
	game.start_stage(1)
	assert_array(game.stage_record_start).is_equal([4, 0, 0, 0])
	game.record.glass_mined = 2
	game.start_stage(2)
	assert_array(game.stage_record_start).is_equal([4, 2, 0, 0])
	game.new_game(0)
	assert_array(game.stage_record_start).is_equal([0, 0, 0, 0])


# --- the golden path: THE PRETENCE → the first Unmaking → the Ruins (TECH-001 §2.1, §2.10) ----------

func test_the_reveal_hands_off_to_the_unmaking_without_a_curtain() -> void:
	game.on_route_entered({})
	game.start_stage(2)
	game.score.add(300)
	var to_aether: Dictionary = game.unmaking_params()
	assert_str(String(game.UNMAKING_ROUTE)).is_equal("aether")
	assert_bool(SceneRouter.skips_curtain(to_aether)).is_true()
	assert_bool(to_aether.get("can_skip")).is_false()   # first time: unskippable (GDD §6.1)
	# the Unmaking forwards exactly the Ruins keys, plus first_visit (AetherArrival.ruins_params)
	var Arrival := load("res://features/aether/aether_arrival.gd")
	var to_ruins: Dictionary = Arrival.ruins_params(to_aether)
	assert_dict(to_ruins).is_equal({"shift_total": 300, "act0_vigil_index": 300, "first_visit": true})


func test_the_unmaking_is_skippable_once_the_pretence_was_seen() -> void:
	game.on_route_entered({})
	game._reveal_seen_before = true
	assert_bool(game.unmaking_params().get("can_skip")).is_true()
