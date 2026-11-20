extends GdUnitTestSuite
## P2 "pressure" (PM Q-T105, 2026-11-19): per-stage switches on CabinetStage whose defaults are the
## pre-P2 game. Censer-bell reinforcements, geode drift-in, Grubs after the wake, Grub pilfer,
## Acolyte escort, Charge carry-over. Driven tick by tick through the real scene, no audio.

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
	(game.get_node("%Messages") as Node).set_process(false)
	world = game.get_node("%World")
	world.paused_sim = true        # the test drives world.step()
	t = world.tuning


func after_test() -> void:
	if is_instance_valid(game):
		game.free()
	AudioService.muted_for_tests = false
	SaveService.set_backend(FileSaveBackend.new())
	get_tree().paused = false


## A bare stage: nothing spawns unless the test asks for it; every P2 switch at its default.
func _stage(wakes: bool = false, segments: int = 0) -> CabinetStage:
	var s := CabinetStage.new()
	s.geodes = 0
	s.grubs = 0
	s.acolytes = 0
	s.guard_acolytes = 0
	s.sepulchre_start_segments = segments
	s.sepulchre_wakes = wakes
	s.chant = false
	s.goal = CabinetStage.Goal.UNMAKE_ENTITY if wakes else CabinetStage.Goal.CLEAR_SEPULCHRE
	return s


## Start `s` with the Vigil parked, under control, unkillable and silent (it never fires).
func _start(s: CabinetStage, far: bool = false) -> void:
	world.start(s)
	var v := world.vigil
	if far:
		v.pos = _far_vigil()
		world.view_centre = v.pos
	v.input_enabled = true        # CabinetGame turns it on after the READY card; the tests skip the card
	v.use_scripted = true
	v.scripted_move = Vector2.ZERO
	v.scripted_fire = false
	v.shield = 1.0e9


func _steps(seconds: float) -> void:
	for i in roundi(seconds / DT):
		world.step(DT)


## Far from the Sepulchre and from the lanes the tests use (the long way round the torus).
func _far_vigil() -> Vector2:
	return world.torus.wrap(world.ritual.pos + Vector2(-610, 0))


# --- Censer bells: Acolyte reinforcements ------------------------------------------------------

func _bell_stage(reinforce: float, cap: int) -> CabinetStage:
	var s := _stage()
	s.acolyte_reinforce_s = reinforce
	s.acolyte_cap = cap
	return s


## Steps until a warning starts (or `max_s` passes); returns the sim seconds it took, -1 if none.
func _until_bell(max_s: float) -> float:
	var sq := world.acolytes
	var secs := 0.0
	while secs < max_s:
		world.step(DT)
		secs += DT
		if sq.reinforcement_pending():
			return secs
	return -1.0


func test_default_stage_never_reinforces() -> void:
	var s := _stage()
	s.acolyte_cap = 5                       # a cap alone does nothing: acolyte_reinforce_s 0 is off
	_start(s)
	for i in roundi(90.0 / DT):
		world.step(DT)
		assert_bool(world.acolytes.reinforcement_pending()).is_false()
	assert_int(world.acolytes.items.size()).is_equal(0)


func test_a_bell_warns_then_an_acolyte_arrives_outside_the_view_at_the_entry() -> void:
	_start(_bell_stage(5.0, 2))
	var sq := world.acolytes
	var secs := _until_bell(10.0)
	assert_float(secs).is_between(5.0 - 2.0 * DT, 5.0 + 2.0 * DT)
	assert_float(sq.reinforcement_time_left()).is_between(t.reinforce_tell_s - 2.0 * DT, t.reinforce_tell_s)
	var n := sq.reinforcement_edge()
	assert_bool(AcolyteSquad.REINFORCE_EDGES.has(n)).is_true()
	var entry := sq.reinforcement_entry()
	# the entry sits reinforce_entry_px outside the view edge it names
	var sp := world.to_screen(entry)
	assert_bool(world.on_screen(entry, 0.0)).override_failure_message("entry must be off-view").is_false()
	var half := world.view_size * 0.5
	var depth := (world.screen_centre - sp).dot(n)
	assert_float(depth).is_equal_approx(absf(n.x) * half.x + absf(n.y) * half.y + t.reinforce_entry_px, 0.01)
	assert_int(sq.items.size()).is_equal(0)
	var last_entry := entry
	var waited := 0.0
	while sq.reinforcement_pending() and waited < t.reinforce_tell_s + 0.5:
		last_entry = sq.reinforcement_entry()
		world.step(DT)
		waited += DT
	assert_float(waited).is_between(t.reinforce_tell_s - 2.0 * DT, t.reinforce_tell_s + 2.0 * DT)
	assert_int(sq.items.size()).is_equal(1)
	var a: AcolyteSquad.Acolyte = sq.items[0]
	assert_vector(a.pos).is_equal_approx(last_entry, Vector2(0.01, 0.01))
	assert_bool(world.on_screen(a.pos, 0.0)).is_false()
	assert_bool(a.guard).is_false()
	assert_int(a.hp).is_equal(t.acolyte_hp)
	assert_int(a.id).is_greater(0)
	assert_object(sq.find_by_id(a.id)).is_same(a)
	assert_vector(sq.reinforcement_entry()).is_equal(Vector2.ZERO)
	assert_vector(sq.reinforcement_edge()).is_equal(Vector2.ZERO)
	assert_float(sq.reinforcement_time_left()).is_equal(0.0)


## Curve retune (PM under owner autonomy grant, 2026-11-19): a0_3's bells stop at the wake.
func test_bells_fall_silent_at_the_wake_when_the_stage_says_so() -> void:
	var s := _bell_stage(5.0, 4)
	s.reinforce_after_wake = false
	_start(s)
	var sq := world.acolytes
	assert_float(_until_bell(10.0)).is_greater(0.0)          # asleep: the bells ring as before
	world.ritual.awake = true
	world.step(DT)
	assert_bool(sq.reinforcement_pending()).override_failure_message("the pending bell is called off at the wake").is_false()
	var before := sq.items.size()
	assert_float(_until_bell(30.0)).is_equal(-1.0)
	assert_int(sq.items.size()).is_equal(before)


func test_bells_keep_ringing_after_the_wake_by_default() -> void:
	_start(_bell_stage(5.0, 4))
	world.ritual.awake = true
	assert_float(_until_bell(10.0)).is_between(5.0 - 2.0 * DT, 5.0 + 2.0 * DT)


func test_reinforcements_never_exceed_the_cap_and_a_kill_makes_room() -> void:
	_start(_bell_stage(5.0, 2))
	var sq := world.acolytes
	for i in roundi(40.0 / DT):
		world.step(DT)
		assert_int(sq.living_count()).is_less_equal(2)
	assert_int(sq.living_count()).is_equal(2)
	var ids: Array[int] = []
	for a in sq.items:
		ids.append(a.id)
	sq.kill(sq.items[0])
	_steps(5.0 + t.reinforce_tell_s + 0.2)
	assert_int(sq.living_count()).is_equal(2)
	var fresh := 0
	for a in sq.items:
		if not ids.has(a.id):
			fresh += 1
	assert_int(fresh).override_failure_message("the dead one is replaced by a new Acolyte with a new id").is_equal(1)


func test_bell_timers_freeze_in_hitstop() -> void:
	_start(_bell_stage(5.0, 2))
	var sq := world.acolytes
	assert_float(_until_bell(10.0)).is_greater(0.0)
	world.step(DT)
	var left := sq.reinforcement_time_left()
	var clock: float = sq._reinforce_clock
	world.hitstop_left = 5             # what world.hitstop() sets (without the Reduced Motion scaling)
	for i in 5:
		world.step(DT)
		assert_float(sq.reinforcement_time_left()).is_equal(left)
		assert_float(sq._reinforce_clock).is_equal(clock)
	world.step(DT)
	assert_float(sq.reinforcement_time_left()).is_less(left)


func test_no_bells_while_the_vigil_is_down() -> void:
	_start(_bell_stage(5.0, 2))
	world.vigil.alive = false
	_steps(12.0)
	assert_bool(world.acolytes.reinforcement_pending()).is_false()
	assert_int(world.acolytes.items.size()).is_equal(0)
	world.vigil.alive = true
	assert_float(_until_bell(6.0)).is_greater(0.0)


func _bell_entries(rng_seed: int, bells: int) -> Array[Vector2]:
	var s := _bell_stage(5.0, bells)
	s.seed = rng_seed
	_start(s)
	var out: Array[Vector2] = []
	var was := false
	for i in roundi((5.0 * bells + 1.0) / DT):
		world.step(DT)
		var now := world.acolytes.reinforcement_pending()
		if now and not was:
			out.append(world.acolytes.reinforcement_entry())
		was = now
	return out


func test_same_seed_same_entry_points() -> void:
	var a := _bell_entries(1234, 3)
	var b := _bell_entries(1234, 3)
	assert_int(a.size()).is_equal(3)
	assert_array(b).is_equal(a)


# --- Geode drift-in ----------------------------------------------------------------------------

func _thin_geodes(keep: int) -> void:
	for i in range(keep, world.geodes.items.size()):
		world.geodes.items[i].alive = false
	world.step(DT)


func test_default_stage_has_no_drift_in() -> void:
	var s := _stage()
	s.geodes = 8
	_start(s)
	_thin_geodes(2)
	_steps(30.0)
	assert_int(world.geodes.items.size()).is_equal(2)


func test_drift_in_refills_to_the_floor_off_view_and_far_from_the_vigil() -> void:
	var s := _stage()
	s.geodes = 8
	s.geode_drift_s = 2.0
	_start(s)
	var floor_n := floori(s.geodes * t.geode_drift_floor)
	_thin_geodes(floor_n - 2)
	var count := world.geodes.items.size()
	assert_int(count).is_equal(floor_n - 2)
	var arrivals := 0
	for i in roundi(30.0 / DT):
		world.step(DT)
		var n := world.geodes.items.size()
		if n > count:
			arrivals += 1
			var g: GeodeField.Geode = world.geodes.items.back()
			assert_bool(world.on_screen(g.pos, g.radius)).override_failure_message("drift-in must appear off-view").is_false()
			assert_float(world.torus.distance(g.pos, world.vigil.pos)).is_greater_equal(t.geode_drift_clear_px)
		assert_int(n).is_less_equal(floor_n)
		count = n
	assert_int(arrivals).is_equal(2)
	assert_int(world.geodes.items.size()).is_equal(floor_n)


# --- Grubs after the wake ----------------------------------------------------------------------

func _wake_with_a_dead_grub(after_wake: bool) -> void:
	var s := _stage(true, t.segments_total)   # awakening at once; awake after silence + stagger window
	s.grubs = 1
	s.grubs_after_wake = after_wake
	_start(s, true)
	world.grubs.kill(world.grubs.items[0], false)   # its replacement is due after the wake
	_steps(t.grub_respawn + 0.2)
	assert_bool(world.ritual.awake).is_true()


func test_default_no_grubs_are_born_after_the_wake() -> void:
	_wake_with_a_dead_grub(false)
	assert_int(world.grubs.items.size()).is_equal(0)


func test_grubs_after_wake_are_born_and_are_meals() -> void:
	_wake_with_a_dead_grub(true)
	assert_int(world.grubs.items.size()).is_equal(1)
	var g: GrubFlock.Grub = world.grubs.items[0]
	world.ritual.hits_left = t.unravel_hits - 2
	world.ritual.entity_pos = g.pos
	world.step(DT)
	assert_bool(g.alive).override_failure_message("the entity eats a newborn Grub like any other").is_false()
	assert_int(world.ritual.hits_left).is_equal(t.unravel_hits - 1)


# --- Grub pilfer -------------------------------------------------------------------------------

## One Grub heading for a far shard; then a loose shard appears close beside it. Returns [grub, far, near].
func _pilfer_setup(pilfer: bool) -> Array:
	var s := _stage()
	s.grubs = 1
	s.grub_pilfer = pilfer
	_start(s, true)
	var g: GrubFlock.Grub = world.grubs.items[0]
	var far := world.glass.spawn_shard(world.torus.wrap(g.pos + Vector2(0, 300)), Vector2.ZERO)
	_steps(0.3)
	assert_object(g.shard).is_same(far)
	var near := world.glass.spawn_shard(world.torus.wrap(g.pos + Vector2(100, 0)), Vector2.ZERO)
	_steps(0.5)
	return [g, far, near]


func test_default_grubs_keep_their_claim() -> void:
	var r := _pilfer_setup(false)
	var g: GrubFlock.Grub = r[0]
	assert_object(g.shard).is_same(r[1])


func test_a_pilfering_grub_takes_the_nearer_loose_shard_and_drops_it_when_killed() -> void:
	var r := _pilfer_setup(true)
	var g: GrubFlock.Grub = r[0]
	var far: GlassField.Shard = r[1]
	var near: GlassField.Shard = r[2]
	assert_object(g.shard).is_same(near)
	assert_int(near.claimed_by).is_equal(g.id)
	assert_int(far.claimed_by).override_failure_message("the old claim is released").is_equal(0)
	for i in roundi(3.0 / DT):
		world.step(DT)
		if g.carrying:
			break
	assert_bool(g.carrying).is_true()
	assert_bool(near.carried).is_true()
	world.grubs.kill(g, true)
	assert_bool(near.alive).is_true()
	assert_bool(near.carried).is_false()
	assert_int(near.claimed_by).is_equal(0)


func test_glass_in_the_magnet_is_not_pilferable() -> void:
	_start(_stage(), true)
	world.glass.set_charges(0)
	var pulled := world.glass.spawn_shard(world.torus.wrap(world.vigil.pos + Vector2(t.magnet_radius * 0.5, 0)), Vector2.ZERO)
	var loose := world.glass.spawn_shard(world.torus.wrap(world.vigil.pos + Vector2(t.magnet_radius * 3.0, 0)), Vector2.ZERO)
	assert_bool(world.glass.pilferable(pulled)).is_false()
	assert_bool(world.glass.pilferable(loose)).is_true()
	world.glass.set_charges(t.magazine)       # a full magazine pulls nothing
	assert_bool(world.glass.pilferable(pulled)).is_true()


# --- Acolyte escort ----------------------------------------------------------------------------

## Makes `g` laden and returns the spot (500 px out from the altar) where the tests hold it still.
func _laden_grub(g: GrubFlock.Grub) -> Vector2:
	var at := world.torus.wrap(world.ritual.pos + Vector2(500, 0))
	g.pos = at
	var sh := world.glass.spawn_shard(g.pos, Vector2.ZERO)
	sh.claimed_by = g.id
	sh.carried = true
	g.shard = sh
	g.carrying = true
	return at


## Steps `seconds`, putting the Grub back on `at` every tick (it would otherwise reach the altar).
func _steps_pinned(g: GrubFlock.Grub, at: Vector2, seconds: float) -> void:
	for i in roundi(seconds / DT):
		world.step(DT)
		g.pos = at
	assert_bool(g.carrying).override_failure_message("the Grub must still be laden").is_true()


func _escort_setup(escort: bool, acolytes: int) -> GrubFlock.Grub:
	var s := _stage()
	s.grubs = 1
	s.acolytes = acolytes
	s.acolyte_escort = escort
	_start(s, true)
	var g: GrubFlock.Grub = world.grubs.items[0]
	# the Acolytes now spawn in the Vigil's box: put them where the old guard-ring spawn was, beside the altar
	for a in world.acolytes.items:
		a.pos = world.torus.wrap(world.ritual.pos + Vector2.from_angle(a.slot) * AcolyteSquad.GUARD_ORBIT)
	_steps_pinned(g, _laden_grub(g), 6.0)
	return g


func _near_count(g: GrubFlock.Grub) -> int:
	var n := 0
	for a in world.acolytes.items:
		if world.torus.distance(a.pos, g.pos) < t.escort_distance + 30.0:
			n += 1
	return n


func test_default_acolytes_do_not_escort() -> void:
	var g := _escort_setup(false, 1)
	assert_int(_near_count(g)).is_equal(0)


func test_an_acolyte_escorts_a_laden_grub_one_per_grub() -> void:
	var g := _escort_setup(true, 2)
	assert_int(_near_count(g)).is_equal(1)
	var trailing := 0
	for a in world.acolytes.items:
		var d := world.torus.distance(a.pos, g.pos)
		if absf(d - t.escort_distance) < 20.0:
			trailing += 1
	assert_int(trailing).override_failure_message("it trails at escort_distance").is_equal(1)


func test_guard_ring_acolytes_never_escort() -> void:
	var s := _stage()
	s.acolyte_escort = true
	s.guard_acolytes = 1
	_start(s, true)
	world.acolytes.on_guard_phase()
	assert_bool((world.acolytes.items[0] as AcolyteSquad.Acolyte).guard).is_true()
	var g := world.grubs._spawn(world.ritual.pos)
	_steps_pinned(g, _laden_grub(g), 6.0)
	assert_int(_near_count(g)).is_equal(0)


# --- Charge carry-over -------------------------------------------------------------------------

## A copy of the roster with every stage's carry_charges_in set to `carry`.
func _roster_with_carry(carry: bool) -> void:
	var r := CabinetStageRoster.new()
	var list: Array[CabinetStage] = []
	for st: CabinetStage in game.stages:
		var d := st.duplicate() as CabinetStage
		d.carry_charges_in = carry
		list.append(d)
	r.stages = list
	game.roster = r


func _clear_stage_holding(charges: int) -> void:
	world.glass.set_charges(charges)
	game.state = game.State.PLAY
	game._on_sepulchre_cleared()
	world.glass.set_charges(0)          # what it holds at the stage's END counts, not later
	game._on_timer()                    # CLEARED → CREDITS
	game._on_timer()                    # CREDITS → next stage


func test_the_next_stage_carries_the_charges_in() -> void:
	_roster_with_carry(true)
	game.start_stage(1)
	_clear_stage_holding(4)
	assert_int(game.stage_index).is_equal(2)
	assert_int(world.glass.charges).is_equal(4)


func test_default_next_stage_starts_empty() -> void:
	_roster_with_carry(false)
	game.start_stage(1)
	_clear_stage_holding(4)
	assert_int(game.stage_index).is_equal(2)
	assert_int(world.glass.charges).is_equal(0)


func test_carry_over_is_capped_at_the_magazine() -> void:
	_roster_with_carry(true)
	game.start_stage(2, t.magazine + 7)
	assert_int(world.glass.charges).is_equal(t.magazine)


func test_a_continue_or_a_fresh_start_never_carries() -> void:
	_roster_with_carry(true)
	game.start_stage(1)
	world.glass.set_charges(4)
	game.on_route_entered({"continue_stage": 2})
	assert_int(game.stage_index).is_equal(2)
	assert_int(world.glass.charges).is_equal(0)
	world.glass.set_charges(3)
	game.start_stage(2)
	assert_int(world.glass.charges).is_equal(0)
