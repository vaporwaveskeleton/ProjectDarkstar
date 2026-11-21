extends GdUnitTestSuite
## Owner playtest 2026-11-20 (research/owner_playtest_feedback_2026-11-20.md): F-1/F-6 knocking a Sepulchre down ends the
## stage on every stage (round 2: it replaced the re-seed); F-7 a built Sepulchre comes for the Vigil; F-2 no floating numbers on the arcade screen;
## F-3 Grubs die to intercept Charges; F-4 the awake entity out-runs the Vigil and is warned of first.

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
	get_tree().paused = false


func _stage(segments: int, grubs: int = 0) -> CabinetStage:
	var s := CabinetStage.new()
	s.geodes = 0
	s.grubs = grubs
	s.acolytes = 0
	s.guard_acolytes = 0
	s.sepulchre_start_segments = segments
	s.sepulchre_wakes = true
	s.chant = false
	s.goal = CabinetStage.Goal.UNMAKE_ENTITY
	return s


func _steps(seconds: float) -> void:
	for i in roundi(seconds / DT):
		world.step(DT)


# --- F-1 / F-6 / F-7 (round 2: knock-downs end the stage; a built Sepulchre comes for the Vigil) ---

## A human at the controls: real held input (the Vigil reads Input, not scripted moves) and Charges thrown
## the way the deploy_charge action throws them (GlassField.launch from the Vigil along its aim).
func _human_start(stage_i: int) -> void:
	game.start_stage(stage_i)
	game.dismiss_brief()
	world.paused_sim = true          # the test steps the sim itself
	game._on_timer()                 # READY card done: PLAY
	world.vigil.use_scripted = false
	world.vigil.input_enabled = true
	# a quiet field: Grubs dive into Charges (F-3), Acolytes shoot, geodes take Charges; each would only add noise here
	world.grubs.items.clear()
	world.acolytes.items.clear()
	world.geodes.items.clear()


func _throw_at_sepulchre() -> void:
	world.vigil.pos = world.torus.wrap(world.ritual.pos + Vector2(-120, 0))
	world.vigil.vel = Vector2.ZERO
	world.glass.set_charges(1)
	world.glass.launch(world.vigil.pos, Vector2.RIGHT)
	_steps(2.0)


## F-6 cause: only a cold stage (goal CLEAR_SEPULCHRE) listened for the Sepulchre going down; on a0_3-a0_5
## (goal UNMAKE_ENTITY) the knock-downs reached 0 segments and nothing ended the stage (#120 then re-seeded
## it after 8 s, which made three knock-downs three rebuilds). A human throws at an unbuilt Sepulchre; the
## autopilot never does, so no scenario saw it. Now 0 segments clears the stage, whatever the goal.
func test_knocking_a_waking_stages_sepulchre_to_nothing_ends_the_stage() -> void:
	_human_start(2)                                   # a0_3: goal UNMAKE_ENTITY, Sepulchre starts at 4 segments
	assert_int(world.stage.goal).is_equal(CabinetStage.Goal.UNMAKE_ENTITY)
	var cleared := [0]
	world.sepulchre_cleared.connect(func() -> void: cleared[0] += 1)
	for i in 8:
		if world.ritual.segments <= 0:
			break
		_throw_at_sepulchre()
	assert_int(world.ritual.segments).is_equal(0)
	assert_int(cleared[0]).override_failure_message("the stage must end exactly once").is_equal(1)
	assert_int(game.state).is_equal(game.State.CLEARED)
	assert_bool(world.vigil.input_enabled).is_false()
	game._on_timer()                                  # banner holds ...
	game._on_timer()                                  # ... then the next stage opens on its card
	assert_int(game.stage_index).is_equal(3)


func test_three_knock_downs_in_a_row_progress_the_shift() -> void:
	for stage_i in [2, 3, 4]:
		game.stage_index = stage_i
		_human_start(stage_i)
		for i in 12:
			if game.state != game.State.PLAY:
				break
			_throw_at_sepulchre()
		assert_int(game.state).override_failure_message("stage %d did not end" % stage_i).is_equal(game.State.CLEARED)


func test_a_cleared_sepulchre_takes_no_more_glass_and_never_wakes() -> void:
	_human_start(2)
	while world.ritual.segments > 0:
		_throw_at_sepulchre()
	assert_bool(world.ritual.accepts_deposits()).is_false()
	_steps(t.awakening_silence + t.stagger_window + 1.0)
	assert_bool(world.ritual.awake).is_false()
	assert_int(world.ritual.segments).is_equal(0)


func test_a_cold_stage_still_clears() -> void:
	var s := _stage(1)
	s.sepulchre_wakes = false
	s.goal = CabinetStage.Goal.CLEAR_SEPULCHRE
	world.start(s)
	var cleared := [false]
	world.sepulchre_cleared.connect(func() -> void: cleared[0] = true)
	world.vigil.pos = world.torus.wrap(world.ritual.pos + Vector2(-120, 0))
	world.glass.set_charges(1)
	world.glass.launch(world.vigil.pos, Vector2.RIGHT)
	_steps(3.0)
	assert_bool(cleared[0]).is_true()
	assert_int(world.ritual.segments).is_equal(0)


## F-7 cause: a human is almost never near the Sepulchre when it completes (Grubs carry glass while the
## Vigil mines elsewhere; it starts 2,560 px out and the view is 256 px wide), and the awake entity chased at
## 380 px/s against the Vigil's 340: closing 40 px/s, over a minute to arrive, and nothing on screen. It
## woke, it just never came. Now it sprints while the Vigil is far (rampage_catchup_*), as the source
## Sinistar does (Q-T446), then closes at rampage_speed. Real held input, the Vigil fleeing flat out.
func test_a_completed_sepulchre_reaches_a_fleeing_human_vigil() -> void:
	_human_start(2)
	world.vigil.pos = world.torus.wrap(world.ritual.pos + Vector2(t.field_sepulchre_start_px, 0))
	world.vigil.vel = Vector2.ZERO
	world.ritual.segments = t.segments_total - 1
	world.ritual.shard_points = t.shards_per_segment - 1
	world.ritual.deposit()                            # the last piece: BEWARE, the silence, then it wakes
	assert_int(world.ritual.phase).is_equal(SepulchreRitual.Phase.AWAKENING)
	world.vigil.shield = 1000.0                       # an Acolyte shot must not end the run early; contact is measured, not suffered
	Input.action_press(&"move_right")                 # flee flat out, directly away
	var woke_at := -1.0
	var caught_at := -1.0
	for i in roundi(60.0 / DT):
		world.step(DT)
		if woke_at < 0.0 and world.ritual.awake:
			woke_at = i * DT
		if world.torus.distance(world.ritual.entity_pos, world.vigil.pos) <= SepulchreRitual.BODY_RADIUS + world.vigil.radius:
			caught_at = i * DT
			break
	Input.action_release(&"move_right")
	assert_float(woke_at).override_failure_message("it must wake").is_greater(0.0)
	assert_float(caught_at).override_failure_message("a fleeing Vigil must be caught inside 40 s of the wake").is_between(0.1, woke_at + 40.0)


func test_the_sprint_only_applies_while_the_vigil_is_far() -> void:
	world.start(_stage(t.segments_total))
	_steps(t.awakening_silence + t.stagger_window + 0.1)
	world.vigil.shield = 100.0
	var r := world.ritual
	var dir := Vector2.RIGHT
	r.entity_dir = dir
	r.entity_pos = world.torus.wrap(world.vigil.pos - dir * (t.rampage_catchup_px + 200.0))
	r.entity_vel = dir * t.rampage_catchup_speed    # steady state of the far row (the eased chase, Q-T446)
	var p0 := r.entity_pos
	r._rampage(DT)
	assert_float(world.torus.distance(p0, r.entity_pos)).is_equal_approx(t.rampage_catchup_speed * DT, 0.01)
	r.entity_pos = world.torus.wrap(world.vigil.pos - dir * 200.0)
	r.entity_vel = dir * t.rampage_speed
	p0 = r.entity_pos
	r._rampage(DT)
	assert_float(world.torus.distance(p0, r.entity_pos)).is_equal_approx(t.rampage_speed * DT, 0.01)
	# the sprint is spent once it has arrived: a Vigil that kites it out again is not sprinted after
	r.entity_pos = world.torus.wrap(world.vigil.pos - dir * (t.rampage_catchup_px + 200.0))
	r.entity_vel = dir * t.rampage_speed
	p0 = r.entity_pos
	r._rampage(DT)
	assert_float(world.torus.distance(p0, r.entity_pos)).is_equal_approx(t.rampage_speed * DT, 0.01)


# --- F-2 -------------------------------------------------------------------------------------

func test_no_floating_numbers_exist_on_the_arcade_screen() -> void:
	world.start(_stage(t.segments_total))
	_steps(t.awakening_silence + t.stagger_window + 0.1)
	world.award(500, world.ritual.entity_pos)
	world.ritual._hit_entity(world.ritual.entity_pos)
	assert_bool(world.fx.has_method("float_text")).is_false()
	assert_bool("texts" in world.fx).is_false()


# --- F-3 -------------------------------------------------------------------------------------

func test_a_grub_dies_to_intercept_a_charge_for_the_sepulchre() -> void:
	world.start(_stage(6, 1))
	var captions: Array[String] = []
	world.caption.connect(func(k: String) -> void: captions.append(k))
	var grub: GrubFlock.Grub = world.grubs.items[0]
	world.vigil.pos = world.torus.wrap(world.ritual.pos + Vector2(-300, 0))
	grub.pos = world.torus.wrap(world.ritual.pos + Vector2(-150, 40))
	world.glass.set_charges(1)
	world.glass.launch(world.vigil.pos, Vector2.RIGHT)
	var before := world.record.grubs_destroyed
	_steps(3.0)
	assert_int(world.ritual.segments).override_failure_message("the Charge must not reach the Sepulchre").is_equal(6)
	assert_bool(captions.has("CAB_CAPTION_GRUB_INTERCEPT")).is_true()
	assert_int(world.record.grubs_destroyed).override_failure_message("a sacrifice is not the player's kill").is_equal(before)
	assert_bool(grub.alive).is_false()


func test_grubs_do_not_dive_once_the_entity_is_awake() -> void:
	world.start(_stage(t.segments_total, 1))
	_steps(t.awakening_silence + t.stagger_window + 0.1)
	var grub: GrubFlock.Grub = world.grubs.items[0]
	world.glass.set_charges(1)
	world.glass.launch(world.vigil.pos, Vector2.RIGHT)
	assert_object(world.grubs._charge_to_intercept(grub)).is_null()


# --- F-4 -------------------------------------------------------------------------------------

func test_the_awake_entity_is_faster_than_the_vigil() -> void:
	assert_float(t.rampage_speed).override_failure_message("fleeing must not work (owner F-4)").is_greater(world.move_stats.max_speed)


func test_the_completed_sepulchre_warns_before_it_wakes() -> void:
	world.start(_stage(t.segments_total - 1))
	var captions: Array[String] = []
	world.caption.connect(func(k: String) -> void: captions.append(k))
	for i in t.shards_per_segment:
		world.ritual.deposit()
	assert_bool(captions.has("CAB_CAPTION_BEWARE")).is_true()
	assert_bool(world.ritual.awake).is_false()
	_steps(t.awakening_silence + t.stagger_window + 0.1)
	assert_bool(world.ritual.awake).is_true()


func test_the_awake_entity_closes_on_a_fleeing_vigil() -> void:
	world.start(_stage(t.segments_total))
	_steps(t.awakening_silence + t.stagger_window + 0.1)
	world.vigil.shield = 100.0
	var gap0 := world.torus.distance(world.ritual.entity_pos, world.vigil.pos)
	# the Vigil flees at full speed along the line away from the entity
	var away := world.torus.delta(world.ritual.entity_pos, world.vigil.pos).normalized()
	for i in 240:
		world.vigil.pos = world.torus.wrap(world.vigil.pos + away * world.move_stats.max_speed * DT)
		world.ritual._rampage(DT)
	var gap1 := world.torus.distance(world.ritual.entity_pos, world.vigil.pos)
	assert_float(gap1).is_less(gap0)
