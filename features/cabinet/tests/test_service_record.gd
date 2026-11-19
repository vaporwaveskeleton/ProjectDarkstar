extends GdUnitTestSuite
## S7: the credits tell you what you did. Run-wide, in-memory, honest counts (ServiceRecord) and
## the stat lines they put in the stage-2 credits roll.

const SCENE := preload("res://features/cabinet/cabinet_game.tscn")
const DT := 1.0 / 60.0
const STAT_ENTRIES := [3, 4, 5, 6]

var game: Node
var world: ArcadeWorld
var t: CabinetTuning
var messages: CabinetMessages
var seen: Array[int] = []


func before_test() -> void:
	AudioService.muted_for_tests = true
	SaveService.set_backend(MemorySaveBackend.new())
	game = SCENE.instantiate()
	add_child(game)
	game.set_process(false)
	world = game.get_node("%World")
	world.paused_sim = true
	t = world.tuning
	messages = game.get_node("%Messages")
	messages.set_process(false)           # the test advances credits_t and asks for the announcements itself
	seen = []


func after_test() -> void:
	if is_instance_valid(game):
		game.free()
	AudioService.muted_for_tests = false
	SaveService.set_backend(FileSaveBackend.new())
	get_tree().paused = false


func _stage(segments: int = 0) -> CabinetStage:
	var s := CabinetStage.new()
	s.geodes = 0
	s.grubs = 0
	s.acolytes = 0
	s.guard_acolytes = 0
	s.sepulchre_start_segments = segments
	s.sepulchre_wakes = true
	s.chant = false
	s.goal = CabinetStage.Goal.UNMAKE_ENTITY
	return s


## Advance the roll to `to` seconds in small steps, the way _process would.
func _roll_to(to: float) -> void:
	while messages.credits_t < to:
		messages.credits_t = minf(to, messages.credits_t + 0.05)
		messages._emit_stat_lines()


func _listen() -> void:
	messages.credits_stat_shown.connect(func(i: int) -> void: seen.append(i))


# --- the counters -------------------------------------------------------------------------

func test_the_game_hands_one_record_to_the_world() -> void:
	assert_object(game.record).is_not_null()
	assert_object(world.record).is_same(game.record)


func test_a_grub_killed_by_the_lance_counts_one_eaten_by_the_entity_does_not() -> void:
	var s := _stage()
	s.grubs = 2
	world.start(s)
	var a: GrubFlock.Grub = world.grubs.items[0]
	var b: GrubFlock.Grub = world.grubs.items[1]
	world.grubs.kill(b, false)
	assert_int(world.record.grubs_destroyed).is_equal(0)
	a.hp = 1
	assert_bool(world.grubs.lance_test(a.pos)).is_true()
	assert_int(world.record.grubs_destroyed).is_equal(1)


func test_mining_counts_the_shards_freed_not_the_ones_an_acolyte_frees() -> void:
	world.start(_stage())
	var g := world.geodes.add_geode(world.vigil.pos + Vector2(200, 0), 2)
	for k in t.face_hits * 3:
		world.time += 0.5
		world.geodes.lance_hit(g)
	assert_bool(g.alive).is_false()
	assert_int(world.glass.shards.size()).is_equal(t.shards_calm + 1)
	assert_int(world.record.glass_mined).is_equal(world.glass.shards.size())
	var before := world.record.glass_mined
	var h := world.geodes.add_geode(world.vigil.pos + Vector2(-200, 0), 0)
	for k in t.face_hits:
		world.time += 0.5
		world.geodes.lance_hit(h, false)
	assert_bool(h.alive).is_false()
	assert_int(world.record.glass_mined).override_failure_message("an Acolyte's mining is not the player's").is_equal(before)


func test_the_entity_devouring_a_geode_counts_nothing() -> void:
	world.start(_stage())
	var g := world.geodes.add_geode(world.vigil.pos + Vector2(200, 0), 1)
	world.geodes.devour(g)
	assert_int(world.record.glass_mined).is_equal(0)


func test_a_detonation_counts_what_it_scatters() -> void:
	world.start(_stage())
	world.glass.set_charges(0)
	# held lance through the real fire path (scripted input, world.step) until the geode goes
	var g := world.geodes.add_geode(world.vigil.pos + Vector2(120, 0), 2)
	g.vel = Vector2.ZERO
	var v := world.vigil
	v.shield = 0.0
	v.use_scripted = true
	v.scripted_aim = Vector2.RIGHT * 10.0
	v.facing = 0.0
	v.scripted_fire = true
	for i in roundi(3.0 * t.face_hits / t.lance_rate / DT):
		world.step(DT)
		if not g.alive:
			break
	v.scripted_fire = false
	assert_bool(g.alive).is_false()
	assert_int(g.faces_left).override_failure_message("detonated, not mined out").is_greater(0)
	assert_int(world.record.glass_mined).is_equal(world.glass.shards.size() + world.glass.charges)


func test_a_charge_counts_only_when_it_actually_launches() -> void:
	world.start(_stage())
	world.glass.set_charges(0)
	assert_bool(world.glass.launch(world.vigil.pos, Vector2.RIGHT)).is_false()
	assert_int(world.record.charges_thrown).is_equal(0)
	world.glass.set_charges(1)
	assert_bool(world.glass.launch(world.vigil.pos, Vector2.RIGHT)).is_true()
	assert_int(world.record.charges_thrown).is_equal(1)


func test_a_deposit_counts_as_glass_carried() -> void:
	world.start(_stage())
	world.ritual.deposit()
	world.ritual.deposit()
	assert_int(world.record.glass_carried).is_equal(2)


func test_a_grub_really_carrying_glass_to_the_sepulchre_counts() -> void:
	var s := _stage()
	s.grubs = 1
	world.start(s)
	world.vigil.pos = world.torus.wrap(world.ritual.pos + Vector2(900, 300))   # far away: no fear
	world.glass.spawn_shard(world.torus.wrap(world.ritual.pos + Vector2(120, 0)), Vector2.ZERO)
	for i in roundi(20.0 / DT):
		world.step(DT)
	assert_int(world.record.glass_carried).is_equal(1)


func test_the_record_survives_a_new_stage_and_reset_zeroes_it() -> void:
	world.start(_stage())
	world.ritual.deposit()
	var r := world.record
	world.start(_stage())
	assert_object(world.record).is_same(r)
	assert_int(world.record.glass_carried).is_equal(1)
	r.reset()
	assert_int(r.glass_carried).is_equal(0)


func test_a_bare_world_without_a_record_still_runs() -> void:
	world.record = null
	world.start(_stage())
	world.ritual.deposit()
	world.glass.set_charges(1)
	world.glass.launch(world.vigil.pos, Vector2.RIGHT)
	assert_int(world.ritual.shard_points).is_equal(1)


# --- the roll -----------------------------------------------------------------------------

func _unmake_for_real() -> void:
	game.record.grubs_destroyed = 7
	game.record.glass_mined = 21
	game.record.charges_thrown = 15
	game.record.glass_carried = 12
	game.stage_index = game.stages.size() - 1   # the full roll belongs to the shift's last stage
	world.start(_stage(t.segments_total))
	world.ritual.hits_left = 1
	world.ritual._hit_entity(world.ritual.entity_pos)    # the last Charge: emits entity_unmade
	assert_int(game.state).is_equal(game.State.UNMADE)
	game._on_timer()
	assert_int(game.state).is_equal(game.State.CREDITS)


func test_the_full_roll_has_the_four_true_stat_lines_after_your_quota_is_met() -> void:
	_unmake_for_real()
	var c := messages.credits
	assert_int(c.size()).is_equal(11)
	assert_str(c[2]).is_equal(tr("CAB_CREDITS_3"))
	assert_str(c[3]).is_equal("GRUBS DESTROYED: 7")
	assert_str(c[4]).is_equal("GLASS MINED: 21")
	assert_str(c[5]).is_equal("CHARGES THROWN: 15")
	assert_str(c[6]).is_equal("GLASS CARRIED: 12")
	assert_str(c[7]).is_equal(tr("CAB_CREDITS_4"))
	assert_str(c[10]).is_equal(tr("CAB_CREDITS_7"))


## PM 2026-11-19: a mid-shift stage end shows its banner only, so a0_5's roll is the first credits.
func test_a_mid_shift_stage_end_rolls_nothing() -> void:
	game.record.grubs_destroyed = 7
	game.state = game.State.CLEARED
	game._on_timer()
	assert_float(messages.credits_t).is_less(0.0)
	assert_int(messages.credits.size()).is_equal(0)


## The stage tally content (Sizzle's P3 card): the 1-based title, then this stage's deltas only.
func test_the_tally_lines_hold_the_title_and_the_per_stage_counts() -> void:
	var now: Array[int] = [7, 21, 15, 12]
	var at_start: Array[int] = [3, 1, 15, 2]
	var lines: PackedStringArray = CabinetGame.tally_lines(2, now, at_start)
	assert_array(Array(lines)).is_equal(["VIGIL 2 TALLY", "GRUBS DESTROYED: 4", "GLASS MINED: 20",
		"CHARGES THROWN: 0", "GLASS CARRIED: 10"])
	for i: int in CabinetGame.TALLY_STAT_INDICES:
		assert_bool(lines[i].contains(":")).override_failure_message("tally line %d is a stat line" % i).is_true()
	assert_bool(lines[0].contains("{n}")).is_false()


func test_the_last_line_is_in_view_when_the_roll_ends() -> void:
	_unmake_for_real()
	var end_t: float = world.fx_tuning.credits_full_seconds
	var last := messages.credits.size() - 1
	var top := messages.credit_entry_top(last, end_t)
	var h := PixelText.wrap(messages.credits[last], 2, messages.size.x - 2.0 * CabinetMessages.MARGIN).size() * 18.0
	print("S7 measured: last line top y=%.1f, bottom y=%.1f, credits window %.1f..%.1f at t=%.1f s" % [top, top + h, messages.credits_top(), messages.credits_bottom(), end_t])
	assert_float(top + h).override_failure_message("the last line must be fully inside the credits window at the end of the roll").is_less_equal(messages.credits_bottom())
	assert_float(top).is_greater_equal(messages.credits_top())


func test_stat_lines_announce_once_each_in_order() -> void:
	_unmake_for_real()
	_listen()
	messages.credits_t = 0.0
	_roll_to(world.fx_tuning.credits_full_seconds)
	assert_array(seen).is_equal([0, 1, 2, 3])
	messages.credits_t += 1.0
	messages._emit_stat_lines()
	assert_array(seen).is_equal([0, 1, 2, 3])


func test_no_stat_line_is_announced_before_it_is_in_view() -> void:
	_unmake_for_real()
	_listen()
	messages.credits_t = 0.0
	_roll_to(0.5)
	assert_array(seen).is_empty()
	assert_float(messages.credit_entry_top(3, 0.5) + CabinetMessages.CREDIT_LINE_H).is_greater(messages.credits_bottom())


func test_roll_credits_and_clear_reset_the_announcements() -> void:
	_unmake_for_real()
	_listen()
	var end_t: float = world.fx_tuning.credits_full_seconds
	_roll_to(end_t)
	assert_int(seen.size()).is_equal(4)
	messages.roll_credits(messages.credits, PackedInt32Array(STAT_ENTRIES))
	_roll_to(end_t)
	assert_int(seen.size()).is_equal(8)
	messages.clear()
	messages.roll_credits(messages.credits, PackedInt32Array(STAT_ENTRIES))
	_roll_to(end_t)
	assert_int(seen.size()).is_equal(12)


func test_drawing_does_not_emit() -> void:
	_unmake_for_real()
	_listen()
	messages.credits_t = world.fx_tuning.credits_full_seconds
	messages.queue_redraw()
	await get_tree().process_frame     # a real draw pass
	await get_tree().process_frame
	assert_array(seen).is_empty()


## The roll keeps clear of the HUD rule, the Vigil and the footer (Reviewer v2 §I; PM under owner
## autonomy grant, 2026-11-19): every line drawn at any moment of the roll sits inside the window above
## the Vigil, which ends READY_CLEAR above the play-view centre where the Vigil is drawn.
func test_the_credits_never_cross_the_hud_rule_the_vigil_or_the_footer() -> void:
	_unmake_for_real()
	var vigil_top := messages.size.y * 0.5 - CabinetMessages.READY_CLEAR
	var footer_top := world.playfield_rect.end.y - world.view_rect.position.y
	var shown := 0
	var at := 0.0
	while at <= world.fx_tuning.credits_full_seconds:
		for r: Rect2 in messages.visible_credit_rects(at):
			shown += 1
			assert_float(r.position.y).override_failure_message("t=%.2f line under the HUD rule: %s" % [at, r]).is_greater_equal(CabinetMessages.MARGIN)
			assert_float(r.end.y).override_failure_message("t=%.2f line over the Vigil: %s" % [at, r]).is_less_equal(vigil_top)
			assert_float(r.end.y).override_failure_message("t=%.2f line over the footer: %s" % [at, r]).is_less_equal(footer_top)
		at += 0.05
	assert_int(shown).override_failure_message("the roll must show lines").is_greater(0)
