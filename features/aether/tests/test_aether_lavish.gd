extends GdUnitTestSuite
## Aether pass 7 (ART-001 §16.6i, PM rulings under the owner autonomy grant, TECH-001 §11.2): the Q-T129
## reveal trace of where the Aether is already gone (T3+, lantern down only, phosphor), the sister
## spheres the entity eats one per tier (never black, never in the play core, Pal roles only), the
## Presence more present at T2, and the richer Pale Marches life.

const U := preload("res://features/aether/tests/aether_test_util.gd")
const PM01 := "res://data/aether/pm01_pale_marches_t1.tres"
const LADDER_DIR := "res://data/aether/ladder/"
## The lantern's rest position and radius in the gallery frame (logical px).
const LANTERN := Vector2(320.0, 202.0)
const LANTERN_R := 120.0


func _backdrop(look: AetherLook) -> AetherBackdrop:
	var b := (load(U.BACKDROP) as PackedScene).instantiate() as AetherBackdrop
	b.look = look
	add_child(b)
	b.set_process(false)
	return auto_free(b)


func _ladder(i: int) -> AetherLook:
	return load(LADDER_DIR + "pm_t%d.tres" % i) as AetherLook


func _lantern_down(b: AetherBackdrop) -> void:
	b.set_lantern_lit(false)
	for k in 30:
		b.advance_clock(0.05)
	b.refresh()


# --- Q-T129: the reveal traces where the Aether is already gone --------------------------------------

func test_ghost_trace_only_at_t3_plus_with_the_lantern_down() -> void:
	for i in range(1, 6):
		var b := _backdrop(_ladder(i))
		await get_tree().process_frame
		assert_float(b.ghost_trace()).override_failure_message("pm_t%d lantern up" % i).is_equal(0.0)
		_lantern_down(b)
		var far := b.find_child("FarFog", true, false) as AetherFogBand
		var g := float(far.get_param(&"ghost"))
		if i >= AetherBackdrop.GHOST_FROM_TIER:
			assert_float(g).override_failure_message("pm_t%d ghost" % i).is_equal(1.0)
		else:
			assert_float(g).override_failure_message("pm_t%d ghost" % i).is_equal(0.0)


func test_ghost_trace_follows_the_reveal_ramp_and_is_phosphor() -> void:
	var b := _backdrop(_ladder(4))
	await get_tree().process_frame
	b.set_lantern_lit(false)
	var last := 0.0
	for k in 20:
		b.advance_clock(0.05)
		assert_float(b.ghost_trace()).is_greater_equal(last)   # monotonic: no flicker
		last = b.ghost_trace()
	var far := b.find_child("FarFog", true, false) as AetherFogBand
	assert_str(U.pal_name(far.get_param(&"ghost_col") as Color)).starts_with("PHOS-")


# --- the sister spheres --------------------------------------------------------------------------------

func test_ladder_sisters_go_out_one_per_tier() -> void:
	for i in range(1, 6):
		var look := _ladder(i)
		assert_int(look.sister_spheres).is_equal(SisterSpheres.SPHERES.size())
		assert_int(look.sister_spheres_eaten).is_equal(i - 1)
	# the last sister is never eaten by the ladder: T5 keeps one last pearl
	assert_int(_ladder(5).sister_spheres_eaten).is_less(_ladder(5).sister_spheres)


func test_sisters_draw_on_the_ladder_and_keep_on_low() -> void:
	var b := _backdrop(_ladder(3))
	await get_tree().process_frame
	assert_bool(b.active_layers().has("sisters")).is_true()
	b.apply_quality(load("res://data/aether/quality/quality_low.tres") as AetherQuality)
	assert_bool(b.active_layers().has("sisters")).is_true()
	# looks that do not ask for them draw none
	var other := _backdrop(load(PM01) as AetherLook)
	await get_tree().process_frame
	assert_bool(other.active_layers().has("sisters")).is_false()


func test_sisters_never_black_and_pal_roles_only() -> void:
	var s := SisterSpheres.new()
	s.configure(_ladder(5))
	for c in s.colours_used():
		assert_bool(U.is_black(c)).is_false()
		var name := U.pal_name(c)
		var flat := Pal.VOID_1.lerp(Pal.VOID_4, 0.22)
		if U.same_rgb(c, flat):
			continue   # the missing slice's flat VOID (pass 6 rule), between two Pal entries
		assert_str(name).override_failure_message("%s is not a Pal entry" % c).is_not_empty()
		for bad in ["SIGNAL", "NULL", "GAS-", "CHOIR-"]:
			assert_bool(name.begins_with(bad)).override_failure_message(name).is_false()
	s.free()


func test_sisters_stay_out_of_the_play_core_and_eat_most_beautiful_first() -> void:
	var last_r := INF
	for i in SisterSpheres.SPHERES.size():
		var sp: Vector3 = SisterSpheres.SPHERES[i]
		assert_float(Vector2(sp.x, sp.y).distance_to(LANTERN)).is_greater(LANTERN_R + sp.z)
		# order of beauty: biggest first (never grows down the list)
		assert_float(sp.z).is_less_equal(last_r)
		last_r = sp.z
	var s := SisterSpheres.new()
	s.configure(_ladder(3))
	assert_float(s.eaten_amount(0)).is_equal(1.0)
	assert_float(s.eaten_amount(1)).is_equal(1.0)
	assert_float(s.eaten_amount(2)).is_equal(0.0)
	s.free()


func test_sisters_hold_still_under_reduced_motion() -> void:
	var s := SisterSpheres.new()
	s.configure(_ladder(1))
	s.set_state(37.0, 0.0, 0.0, true)
	assert_bool(s.still).is_true()
	s.free()


# --- the Presence more present, the life richer ---------------------------------------------------------

func test_presence_is_more_present_at_t2_and_the_sector_law_holds() -> void:
	assert_float(_ladder(2).presence_lit).is_greater(_ladder(1).presence_lit)
	# PM-01 (the sector look) keeps the lantern-up law: a vague mass
	assert_float((load(PM01) as AetherLook).presence_lit).is_equal(0.0)
	var b := _backdrop(_ladder(2))
	await get_tree().process_frame
	var p := b.find_child("FrostPresence", true, false) as FrostPresence
	assert_float(p.reveal).is_equal_approx(_ladder(2).presence_lit, 0.0001)
	_lantern_down(b)
	assert_float(p.reveal).is_equal(1.0)


func test_pale_marches_life_thins_down_the_ladder() -> void:
	for i in range(1, 6):
		var look := _ladder(i)
		assert_bool(look.jellies and look.school).is_true()
		if i > 1:
			assert_float(look.life_density).is_less(_ladder(i - 1).life_density)
