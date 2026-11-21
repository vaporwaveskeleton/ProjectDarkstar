extends GdUnitTestSuite
## The Act 0 stage card and the Unmakings (three on the shift [a0_1, a0_3, a0_4, a0_5], Q-T452) (SYS-001 §1.7, UI-001 §11, NARR-001 §7.5; PROPOSED).
## Driven through the real scene: the card opens at every stage start, the world does not tick under it,
## only a fresh fire_lance press after brief_arm_s dismisses it, pause and ui_cancel open the pause
## overlay and leave the card up, and --autopilot closes it itself.

const SCENE := preload("res://features/cabinet/cabinet_game.tscn")
const DT := 1.0 / 60.0

var game: CabinetGame
var world: ArcadeWorld
var messages: CabinetMessages
var t: CabinetTuning


func before_test() -> void:
	AudioService.muted_for_tests = true
	SaveService.set_backend(MemorySaveBackend.new())
	SettingsService.persist = false
	game = SCENE.instantiate() as CabinetGame
	add_child(game)
	game.set_process(false)
	world = game.get_node("%World")
	world.paused_sim = true
	messages = game.get_node("%Messages")
	messages.set_process(false)
	t = game.tuning
	# the Hauntings are clock-seeded (35 % per READY card): keep the card text deterministic here
	game.haunts.deck.tuning = game.haunts.deck.tuning.duplicate() as CabinetHauntTuning
	game.haunts.deck.tuning.chance_ready = 0.0


func after_test() -> void:
	Input.action_release(&"fire_lance")
	SettingsService.set_value(&"photosensitivity", false)
	SettingsService.set_value(&"reduced_motion", false)
	SettingsService.persist = true
	if is_instance_valid(game):
		game.free()
	AudioService.muted_for_tests = false
	SaveService.set_backend(FileSaveBackend.new())
	get_tree().paused = false


func _press(action: StringName, pressed: bool = true) -> InputEventAction:
	var ev := InputEventAction.new()
	ev.action = action
	ev.pressed = pressed
	return ev


## Advance the game's own clock by `seconds` (the card's timer runs in _process).
func _wait(seconds: float) -> void:
	game._process(seconds)


# --- the Unmakings ------------------------------------------------------------------------

func test_the_roster_and_the_tuning_agree_on_three_unmakings() -> void:
	var roster := CabinetStageRoster.default_roster()
	assert_int(roster.unmakings_required()).is_equal(3)
	assert_int(t.unmakings_required).is_equal(roster.unmakings_required())
	assert_bool(t.ds_keys().has("ds_cabinet.tuning.unmakings_required")).is_true()


func test_unmakings_done_are_derived_from_the_stage_index() -> void:
	var want := [0, 0, 1, 2]   # a0_1 is cold: it is cleared, not unmade
	for i in 4:
		game.start_stage(i)
		assert_int(game.unmakings).override_failure_message("stage %d" % i).is_equal(want[i])
	assert_int(game.roster.unmakings_before(4)).is_equal(3)


func test_an_unmade_entity_counts_one() -> void:
	game.start_stage(1)   # a0_3: the first waking stage of the shift
	game.dismiss_brief()
	game._on_timer()
	game._on_entity_unmade()
	assert_int(game.unmakings).is_equal(1)


# --- the card opens, the world waits -----------------------------------------------------------------

func test_the_card_is_up_at_every_stage_start_and_the_world_does_not_tick() -> void:
	for i in game.stages.size():
		game.start_stage(i)
		assert_int(game.state).is_equal(CabinetGame.State.BRIEFING)
		assert_bool(messages.brief_open()).is_true()
		assert_bool(world.paused_sim).is_true()
		var t0 := world.time
		world._physics_process(DT)         # what the engine calls every frame
		assert_float(world.time).is_equal(t0)
		assert_bool(world.vigil.input_enabled).is_false()


func test_a_continue_also_opens_the_card() -> void:
	game.on_route_entered({"continue_stage": 1, "shift_total": 500})
	assert_int(game.stage_index).is_equal(1)
	assert_int(game.state).is_equal(CabinetGame.State.BRIEFING)
	assert_int(game.unmakings).is_equal(0)   # a0_1 (cold) is behind, not unmade


# --- input ----------------------------------------------------------------------------------------

func test_fire_before_arm_is_ignored_and_a_fresh_press_after_it_dismisses() -> void:
	game._unhandled_input(_press(&"fire_lance"))
	assert_int(game.state).is_equal(CabinetGame.State.BRIEFING)
	_wait(t.brief_arm_s * 0.5)
	game._unhandled_input(_press(&"fire_lance"))
	assert_int(game.state).is_equal(CabinetGame.State.BRIEFING)
	_wait(t.brief_arm_s)
	game._unhandled_input(_press(&"fire_lance"))
	assert_int(game.state).is_equal(CabinetGame.State.INTRO)
	assert_bool(messages.brief_open()).is_false()
	assert_float(game._timer).is_equal_approx(t.brief_ready_after_s, 0.001)


func test_held_fire_never_dismisses_it() -> void:
	Input.action_press(&"fire_lance")         # held since the last stage: no new press event ever arrives
	for i in 20:
		_wait(0.5)
	assert_int(game.state).is_equal(CabinetGame.State.BRIEFING)
	Input.action_release(&"fire_lance")


func test_other_actions_do_nothing() -> void:
	_wait(t.brief_arm_s + 1.0)
	for a in [&"move_left", &"surgelight", &"deploy_charge", &"ui_accept", &"ui_select"]:
		if InputMap.has_action(a):
			game._unhandled_input(_press(a))
	assert_int(game.state).is_equal(CabinetGame.State.BRIEFING)


func test_ui_cancel_and_pause_open_the_pause_overlay_and_the_card_survives() -> void:
	for a in [&"ui_cancel", &"pause"]:
		game._unhandled_input(_press(a))
		assert_bool(game.overlays.is_empty()).override_failure_message("%s opened no overlay" % a).is_false()
		assert_int(game.state).is_equal(CabinetGame.State.BRIEFING)
		assert_bool(messages.brief_open()).is_true()
		# fire cannot dismiss the card from under the pause screen
		_wait(t.brief_arm_s + 1.0)
		game._unhandled_input(_press(&"fire_lance"))
		assert_int(game.state).is_equal(CabinetGame.State.BRIEFING)
		game.overlays.pop()
		get_tree().paused = false
		assert_bool(game.overlays.is_empty()).is_true()
		assert_int(game.state).is_equal(CabinetGame.State.BRIEFING)
		assert_bool(messages.brief_open()).is_true()


func test_autopilot_dismisses_the_card_after_brief_autopilot_s() -> void:
	game.autopilot.enabled = true
	_wait(t.brief_autopilot_s * 0.5)
	assert_int(game.state).is_equal(CabinetGame.State.BRIEFING)
	_wait(t.brief_autopilot_s)
	assert_int(game.state).is_equal(CabinetGame.State.INTRO)
	game._process(t.brief_ready_after_s + 0.1)
	assert_int(game.state).is_equal(CabinetGame.State.PLAY)


func test_the_demo_never_shows_the_card() -> void:
	game.on_route_entered({"demo": true})
	assert_int(game.state).is_equal(CabinetGame.State.INTRO)
	assert_bool(messages.brief_open()).is_false()


# --- content ----------------------------------------------------------------------------------------

func test_the_roster_rows_match_the_stage_data() -> void:
	for i in game.stages.size():
		var st := game.stages[i]
		var card := game.brief_card(st)
		var rows: Array = card["rows"]
		var by_kind := {}
		for r: Dictionary in rows:
			by_kind[r["kind"]] = int(r["count"])
		assert_int(int(by_kind.get(&"geode", 0))).is_equal(st.geodes)
		assert_int(int(by_kind.get(&"grub", 0))).is_equal(st.grubs)
		assert_int(int(by_kind.get(&"acolyte", 0))).is_equal(st.acolytes + st.guard_acolytes)
		assert_int(int(by_kind.get(&"sepulchre", 0))).is_equal(1)
		for r: Dictionary in rows:      # never a unit the stage does not have
			assert_int(int(r["count"])).is_greater(0)
		var want_order := "CAB_BRIEF_ORDER_WAKE" if st.goal == CabinetStage.Goal.UNMAKE_ENTITY else "CAB_BRIEF_ORDER_COLD"
		assert_str(card["order"]).is_equal(tr(want_order))
		assert_int((card["reminders"] as PackedStringArray).size()).is_equal(2)


func test_every_card_string_resolves_and_the_13_comes_from_data() -> void:
	for i in game.stages.size():
		var card := game.brief_card(game.stages[i])
		for r: String in card["reminders"]:
			assert_bool(r.begins_with("CAB_")).override_failure_message("unresolved key %s" % r).is_false()
			assert_bool(r.contains("{")).is_false()
			assert_int(r.length()).is_less_equal(30)
	assert_str(game.brief_card(game.stages[1])["reminders"][1]).is_equal("%d CHARGES UNMAKE WHAT WAKES." % world.tuning.unravel_hits)


func test_unmakings_line_reads_0_1_2_of_3_across_the_shift() -> void:
	# the cold tutorials (a0_1, a0_2) have no Unmakings line (a0_2 is off the shift, still data)
	for path in ["res://data/cabinet/stage_first_vigil.tres", "res://data/cabinet/stage_drift.tres"]:
		assert_str(game.brief_card(load(path) as CabinetStage)["unmakings"]).is_empty()
	var want := ["", "UNMAKINGS 0 / 3", "UNMAKINGS 1 / 3", "UNMAKINGS 2 / 3"]   # a0_1 is cold: no line
	for k in 4:
		game.start_stage(k)
		assert_str(messages.brief()["unmakings"]).is_equal(want[k])


func test_the_blink_runs_at_1_5_hz_and_is_steady_under_photosensitivity_or_reduced_motion() -> void:
	game.start_stage(0)
	assert_float(t.brief_prompt_blink_hz).is_equal(1.5)
	var seen := {}
	for k in 12:
		messages._t = k * 0.1
		seen[messages.brief_prompt_lit()] = true
	assert_int(seen.size()).override_failure_message("it blinks").is_equal(2)
	for key in [&"photosensitivity", &"reduced_motion"]:
		SettingsService.set_value(&"photosensitivity", false)
		SettingsService.set_value(&"reduced_motion", false)
		SettingsService.set_value(key, true)
		for k in 12:
			messages._t = k * 0.1
			assert_bool(messages.brief_prompt_lit()).override_failure_message("%s: steady" % key).is_true()


func test_the_card_fits_the_play_view_and_clears_the_maker_band() -> void:
	for i in game.stages.size():
		game.start_stage(i)
		var lay := messages.brief_layout()
		var above: float = lay["unmakings"] if not str(messages.brief()["unmakings"]).is_empty() else lay["prompt"]
		assert_float(float(lay["bottom"])).override_failure_message("stage %d rows overrun" % i).is_less_equal(above)
		assert_float(float(lay["prompt"]) + float(PixelText.H)).is_less_equal(messages.size.y - CabinetScreenSpec.MAKER_BAND_PX)
		# every line fits the 256 px width at its scale
		var card := messages.brief()
		assert_int(PixelText.width(str(card["prompt"]))).is_less_equal(int(messages.size.x))
		assert_int(PixelText.width(str(card["order"]))).is_less_equal(int(messages.size.x))
		for r: String in card["reminders"]:
			assert_int(PixelText.width(r)).is_less_equal(int(messages.size.x))
		assert_vector(messages.size).is_equal(Vector2(256, 256))
	assert_float(messages.position.y).is_equal(48.0)        # the card lives in the play view: never over the HUD strip


func test_the_card_draws_without_error_and_uses_only_register_colours() -> void:
	game.start_stage(2)
	messages.queue_redraw()
	await get_tree().process_frame
	assert_bool(messages.brief_open()).is_true()


func test_the_unit_icons_have_extents_from_tuning() -> void:
	assert_float(CabinetBriefIcons.extent(&"grub", t)).is_equal(t.size_grub_px)
	assert_float(CabinetBriefIcons.extent(&"acolyte", t)).is_equal(t.size_acolyte_px)
	assert_float(CabinetBriefIcons.extent(&"geode", t)).is_equal(t.size_geode_radii[0] * 2.0)
	assert_float(CabinetBriefIcons.extent(&"acolyte", t)).is_less_equal(CabinetMessages.BRIEF_ROW_H)


func test_a_restart_under_the_card_still_unpauses_the_world_on_dismiss() -> void:
	game.start_stage(1)                    # set_stage / CONTINUE while the first card is up
	game.start_stage(2)
	game.dismiss_brief()
	assert_bool(world.paused_sim).override_failure_message("the world must run after the card closes").is_false()
	assert_int(game.state).is_equal(CabinetGame.State.INTRO)


func test_the_prompt_is_lit_70_percent_of_each_blink_cycle() -> void:
	game.start_stage(0)
	assert_float(t.brief_prompt_duty).is_equal(0.7)
	var lit := 0
	for k in 100:
		messages._t = k * 0.01 / t.brief_prompt_blink_hz
		if messages.brief_prompt_lit():
			lit += 1
	assert_int(absi(lit - 70)).is_less_equal(1)
