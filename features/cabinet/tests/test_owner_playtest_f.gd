extends GdUnitTestSuite
## Owner playtest 2026-11-20 (research/owner_playtest_feedback_2026-11-20.md): F-1 a waking stage must
## not strand a human who knocks the Sepulchre down; F-2 no floating numbers on the arcade screen;
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


# --- F-1 -------------------------------------------------------------------------------------

## Cause: the autopilot never throws Charges at a waking stage's unbuilt Sepulchre, a human does. Four
## knocks took a0_3's Sepulchre (4 segments) to 0; its goal is UNMAKE_ENTITY, which needs the Sepulchre
## built to 20 and woken, and nothing re-seeded it, so the stage sat on an empty altar (no Grubs left
## to carry glass in the worst case). The fix re-seeds a knocked-down waking Sepulchre.
func test_a_human_who_knocks_a_waking_sepulchre_to_nothing_does_not_strand_the_stage() -> void:
	world.start(_stage(4))
	var captions: Array[String] = []
	world.caption.connect(func(k: String) -> void: captions.append(k))
	world.vigil.pos = world.torus.wrap(world.ritual.pos + Vector2(-120, 0))
	for i in 6:
		if world.ritual.segments <= 0:
			break
		world.glass.set_charges(1)
		world.glass.launch(world.vigil.pos, Vector2.RIGHT)
		_steps(2.0)
	assert_int(world.ritual.segments).is_equal(0)
	assert_bool(captions.has("CAB_CAPTION_REBUILDS")).is_true()
	_steps(t.waking_reseed_s + 0.5)
	assert_int(world.ritual.segments).override_failure_message("stage stays on an empty altar").is_equal(t.waking_reseed_segments)
	assert_int(world.ritual.phase).is_not_equal(SepulchreRitual.Phase.SEED)


func test_a_cold_stage_is_not_reseeded_it_clears() -> void:
	var s := _stage(1)
	s.sepulchre_wakes = false
	s.goal = CabinetStage.Goal.CLEAR_SEPULCHRE
	world.start(s)
	var cleared := [false]
	world.sepulchre_cleared.connect(func() -> void: cleared[0] = true)
	world.vigil.pos = world.torus.wrap(world.ritual.pos + Vector2(-120, 0))
	world.glass.set_charges(1)
	world.glass.launch(world.vigil.pos, Vector2.RIGHT)
	_steps(t.waking_reseed_s + 3.0)
	assert_bool(cleared[0]).is_true()
	assert_int(world.ritual.segments).is_equal(0)


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
