extends GdUnitTestSuite
## M2 slice, Aether art PR A: the pre-wired far layer and its forwarders, the Pale Marches Presence
## (never a collider, never black, bigger than the playfield, flees), the CH-3 lantern-down reveal
## (fades in and out within REVEAL_FADE_S, monotonic), the low rung keeping the flee, the PM-01 look's
## T1 warp contracts (WARP-001 §2.2) and the Pale Marches damage ladder (data/aether/ladder/).

const U := preload("res://features/aether/tests/aether_test_util.gd")
const FAR_LAYER := "res://features/aether/aether_far_layer.tscn"
const PM01 := "res://data/aether/pm01_pale_marches_t1.tres"
const LADDER_DIR := "res://data/aether/ladder/"


func _backdrop(path: String) -> AetherBackdrop:
	var b := (load(U.BACKDROP) as PackedScene).instantiate() as AetherBackdrop
	b.look = load(path) as AetherLook
	add_child(b)
	b.set_process(false)
	return auto_free(b)


func _presence(b: AetherBackdrop) -> FrostPresence:
	return b.find_child("FrostPresence", true, false) as FrostPresence


func _ladder(i: int) -> AetherLook:
	return load(LADDER_DIR + "pm_t%d.tres" % i) as AetherLook


# --- the far layer ----------------------------------------------------------------------------------

func test_far_layer_is_prewired_and_forwards() -> void:
	var f := (load(FAR_LAYER) as PackedScene).instantiate() as AetherFarLayer
	add_child(f)
	auto_free(f)
	await get_tree().process_frame
	assert_object(f.backdrop).is_not_null()
	assert_object(f.view).is_not_null()
	assert_bool(f.view.world.is_ancestor_of(f.backdrop)).is_true()
	assert_int(f.backdrop.tier).is_equal(f.look.tier)
	f.apply_look(load(PM01) as AetherLook)
	assert_str(f.backdrop.look.ds_namespace).is_equal("ds_aether.pm01_pale_marches_t1")
	f.set_tier(3)
	assert_int(f.backdrop.tier).is_equal(3)
	f.set_camera(Vector2(400.0, 250.0), 1.0)
	assert_vector(f.backdrop.camera_centre).is_equal(Vector2(400.0, 250.0))
	var cam := f.find_child("Camera", true, false) as Camera2D
	assert_vector(cam.position).is_equal(Vector2(400.0, 250.0))
	# world → screen: the camera centre lands on the middle of the logical frame
	var half := f.backdrop.get_viewport_rect().size * 0.5
	f.set_lantern(Vector2(400.0, 272.0), 120.0, true)
	assert_vector(f.backdrop.lantern_screen).is_equal_approx(half + Vector2(0.0, 22.0), Vector2(0.01, 0.01))
	assert_float(f.backdrop.lantern_radius).is_equal(120.0)
	assert_bool(f.backdrop.lantern_lit).is_true()
	f.set_camera(Vector2(400.0, 250.0), 2.0)
	f.set_lantern(Vector2(410.0, 250.0), 100.0, false)
	assert_vector(f.backdrop.lantern_screen).is_equal_approx(half + Vector2(20.0, 0.0), Vector2(0.01, 0.01))
	assert_float(f.backdrop.lantern_radius).is_equal(200.0)
	assert_bool(f.backdrop.lantern_lit).is_false()
	# zero or negative zoom counts as 1
	f.set_camera(Vector2(320.0, 180.0), 0.0)
	assert_float(f.camera_zoom).is_equal(1.0)
	assert_float(f.flee_progress()).is_equal(0.0)
	f.presence_flee()
	assert_bool(_presence(f.backdrop).fleeing).is_true()


func test_far_layer_has_no_collision_and_no_play_light() -> void:
	var f := (load(FAR_LAYER) as PackedScene).instantiate() as AetherFarLayer
	add_child(f)
	auto_free(f)
	await get_tree().process_frame
	assert_int(f.find_children("*", "CollisionObject2D", true, false).size()).is_equal(0)
	assert_int(f.find_children("*", "CollisionShape2D", true, false).size()).is_equal(0)
	assert_int(f.find_children("*", "PointLight2D", true, false).size()).is_equal(0)


# --- the Presence -----------------------------------------------------------------------------------

func test_presence_is_far_vast_never_a_collider_never_black() -> void:
	var b := _backdrop(PM01)
	await get_tree().process_frame
	var p := _presence(b)
	assert_bool(p.visible).is_true()
	assert_bool(b.active_layers().has("presence")).is_true()
	# far layer only: it sits in its own slow Parallax2D, behind the mid fog
	var layer := p.get_parent() as Parallax2D
	assert_object(layer).is_not_null()
	assert_float(layer.scroll_scale.x).is_less(0.15)
	assert_int(layer.get_index()).is_less(b.find_child("MidLayerA", true, false).get_index())
	# bigger than the playfield (only ever seen cropped)
	assert_float(p.size.x).is_greater(640.0 * 2.0)
	assert_float(p.size.y).is_greater(360.0 * 2.0)
	assert_int(p.find_children("*", "CollisionObject2D", true, false).size()).is_equal(0)
	assert_int(p.find_children("*", "Light2D", true, false).size()).is_equal(0)
	for k: Variant in U.colour_uniforms(p.mat).keys():
		var c: Color = U.colour_uniforms(p.mat)[k]
		assert_bool(U.is_black(c)).override_failure_message("presence %s is black" % k).is_false()
		assert_bool(U.is_ramp(c, "GAS")).override_failure_message("presence %s is GAS" % k).is_false()
	var code := (load("res://shaders/aether/frost_presence.gdshader") as Shader).code
	assert_bool(code.contains("col = max(col, floor_col);")).is_true()
	assert_int(code.count("vec4(0.0, 0.0, 0.0")).is_equal(0)
	# heartbeat: two bumps per beat stay at or under 1 Hz
	assert_float(2.0 / FrostPresence.BEAT_PERIOD_S).is_less_equal(1.0)


func test_flee_progress_rises_after_presence_flee() -> void:
	var b := _backdrop(PM01)
	await get_tree().process_frame
	var p := _presence(b)
	assert_float(b.presence_flee_progress()).is_equal(0.0)
	b.advance_clock(1.0)
	assert_float(b.presence_flee_progress()).is_equal(0.0)
	var start_presence := p.presence()
	b.presence_flee()
	var last := 0.0
	for i in 4:
		b.advance_clock(0.5)
		var now := b.presence_flee_progress()
		assert_float(now).is_greater(last)
		last = now
	b.refresh()
	assert_float(p.presence()).is_less(start_presence)
	b.advance_clock(FrostPresence.FLEE_S)
	assert_float(b.presence_flee_progress()).is_equal(1.0)
	assert_bool(b.active_layers().has("presence")).is_false()
	assert_bool(p.visible).is_false()


func test_presence_flees_the_entity_on_its_own() -> void:
	var b := _backdrop(PM01)
	await get_tree().process_frame
	b.set_drain(0.0)
	assert_bool(_presence(b).fleeing).is_false()
	b.set_drain(0.3)
	assert_bool(_presence(b).fleeing).is_true()


func test_low_rung_keeps_the_presence_and_its_flee() -> void:
	var b := _backdrop(PM01)
	await get_tree().process_frame
	b.apply_quality(load(AetherQuality.path_for("low")) as AetherQuality)
	assert_bool(b.active_layers().has("presence")).is_true()
	b.presence_flee()
	b.advance_clock(1.0)
	assert_float(b.presence_flee_progress()).is_greater(0.0)
	# and the erasure edge (the entity) is still there on low
	b.set_drain(1.0)
	assert_bool(b.active_layers().has("entity")).is_true()


# --- CH-3 lantern-down reveal -------------------------------------------------------------------------

func test_lantern_down_fades_the_reveal_in_and_out() -> void:
	var b := _backdrop(PM01)
	await get_tree().process_frame
	var p := _presence(b)
	var life := b.find_child("RevealLife", true, false) as AetherLife
	assert_float(b.reveal).is_equal(0.0)
	assert_bool(life.visible).is_false()
	assert_float(AetherBackdrop.REVEAL_FADE_S).is_less_equal(1.0)
	b.set_lantern_lit(false)
	var last := 0.0
	var t := 0.0
	while t < 1.0:
		b.advance_clock(0.05)
		t += 0.05
		assert_float(b.reveal).is_greater_equal(last)   # monotonic: no flicker
		last = b.reveal
	assert_float(b.reveal).is_equal(1.0)
	assert_bool(life.visible).is_true()
	assert_float(life.modulate.a).is_equal(1.0)
	assert_float(float(p.get_param(&"reveal"))).is_equal(1.0)
	assert_bool(b.active_layers().has("reveal")).is_true()
	# the warm pool is gone from the fog while the lantern is down
	b.refresh()
	var far := b.find_child("FarFog", true, false) as AetherFogBand
	assert_float(float(far.get_param(&"lantern_energy"))).is_equal(0.0)
	b.set_lantern_lit(true)
	t = 0.0
	last = 1.0
	while t < 1.0:
		b.advance_clock(0.05)
		t += 0.05
		assert_float(b.reveal).is_less_equal(last)
		last = b.reveal
	assert_float(b.reveal).is_equal(0.0)
	assert_bool(life.visible).is_false()
	b.refresh()
	assert_float(float(far.get_param(&"lantern_energy"))).is_greater(0.0)


# --- PM-01 look: the T1 warp effects that are Aether visuals -----------------------------------------

func test_pm01_represents_its_aether_warp_effects() -> void:
	var look := load(PM01) as AetherLook
	assert_int(look.tier).is_equal(1)
	assert_bool(look.frost_presence).is_true()
	assert_bool(look.reveal_life_count > 0).is_true()
	assert_array(Array(look.warp_effects)).contains_exactly_in_any_order(["W1-01", "W1-03"])
	# W1-01 Wrong Three: three hues from no ramp the player has learned (the post-Pretence AETHER ramp)
	var aether := {}
	for field in look.colour_fields():
		var c: Color = look.get(field)
		var name := U.pal_name(c)
		if c.a > 0.0 and name.begins_with("AETHER"):
			aether[name] = true
	assert_int(aether.size()).override_failure_message("AETHER hues: %s" % [aether.keys()]).is_greater_equal(3)
	# W1-03 Parallax Arrives: parallax bands behind the field, camera untouched (no drift at T1)
	assert_float(look.camera_drift_px).is_equal(0.0)
	assert_int(look.fog_band_count).is_greater_equal(3)
	assert_float(look.band_scroll(0)).is_less(look.band_scroll(1))
	assert_float(look.band_scroll(1)).is_less(look.band_scroll(2))


func test_chromatic_edge_is_off_by_default_and_respects_photosensitivity() -> void:
	var b := _backdrop(PM01)
	await get_tree().process_frame
	b.photosensitive = false
	assert_bool(b.chromatic_edge).is_false()
	assert_bool(b.active_layers().has("edge_split")).is_false()
	b.set_chromatic_edge(true)
	assert_bool(b.active_layers().has("edge_split")).is_true()
	assert_bool((b.find_child("EdgeSplit", true, false) as CanvasItem).visible).is_true()
	b.photosensitive = true
	b.set_chromatic_edge(true)
	assert_bool(b.active_layers().has("edge_split")).is_false()
	assert_bool((b.find_child("EdgeSplit", true, false) as CanvasItem).visible).is_false()


func test_pale_marches_tier_look_shows_the_presence() -> void:
	assert_bool((load("res://data/aether/pale_marches_t1.tres") as AetherLook).frost_presence).is_true()
	assert_bool((load("res://data/aether/drowned_observatory_t3.tres") as AetherLook).leviathan).is_true()


# --- the Pale Marches damage ladder (G-2, Q-T126) ------------------------------------------------------

func test_ladder_has_t1_to_t5_of_one_biome() -> void:
	for i in range(1, 6):
		var look := _ladder(i)
		assert_object(look).override_failure_message("pm_t%d missing" % i).is_not_null()
		assert_int(look.tier).is_equal(i)
		assert_str(look.biome).is_equal("pale_marches")
		assert_str(look.ds_namespace).is_equal("ds_aether.ladder.pm_t%d" % i)
		# same camera and the same set pieces on every rung
		assert_float(look.camera_drift_px).is_equal(0.0)
		assert_bool(look.set_orrery_rings).is_true()
		assert_bool(look.frost_presence).is_true()
		for flag in ["set_greenhouse", "set_dome", "set_ring_fragments", "orrery", "leviathan"]:
			assert_bool(bool(look.get(flag))).override_failure_message("pm_t%d.%s" % [i, flag]).is_false()


func test_ladder_damage_is_monotonic_and_grows_every_tier() -> void:
	var prev: Dictionary = {}
	for i in range(1, 6):
		var look := _ladder(i)
		var d := {
			"life_thin": 1.0 - look.life_density,
			"stalled": float(look.rings_stalled),
			"broken": float(look.rings_broken),
			"fled": look.presence_fled,
			"cracks": look.crack_amount if look.sky_cracks else 0.0,
			"subtraction": look.subtraction_amount if look.subtraction else 0.0,
		}
		if not prev.is_empty():
			var grew := false
			for k: String in d.keys():
				assert_float(float(d[k])).override_failure_message("pm_t%d %s went down" % [i, k]).is_greater_equal(float(prev[k]))
				if float(d[k]) > float(prev[k]):
					grew = true
			assert_bool(grew).override_failure_message("pm_t%d adds no damage" % i).is_true()
		prev = d
	# the named steps: T2 life thinner + one ring stalled; T3 the Presence fleeing + first crack;
	# T4 a ring broken + panes open; T5 subtraction
	assert_int(_ladder(2).rings_stalled).is_greater_equal(1)
	assert_float(_ladder(3).presence_fled).is_greater(0.0)
	assert_bool(_ladder(3).sky_cracks).is_true()
	assert_bool(_ladder(2).sky_cracks).is_false()
	assert_int(_ladder(4).rings_broken).is_greater_equal(1)
	assert_int(_ladder(3).rings_broken).is_equal(0)
	assert_bool(_ladder(5).subtraction).is_true()
	assert_bool(_ladder(4).subtraction).is_false()


func test_ladder_colours_follow_the_role_laws() -> void:
	for i in range(1, 6):
		var look := _ladder(i)
		for field in look.colour_fields():
			var c: Color = look.get(field)
			if c.a <= 0.0:
				continue
			var name := U.pal_name(c)
			assert_str(name).override_failure_message("pm_t%d.%s is not a Pal entry" % [i, field]).is_not_empty()
			for bad in ["SIGNAL", "NULL"]:
				assert_str(name).is_not_equal(bad)
			assert_bool(name.begins_with("GAS-") or name.begins_with("CHOIR-")).override_failure_message("pm_t%d.%s is %s" % [i, field, name]).is_false()


func test_ladder_rings_stall_and_break() -> void:
	var sp := FarSetPieces.new()
	sp.configure(_ladder(1))
	assert_int(sp.rings_stalled).is_equal(0)
	sp.configure(_ladder(4))
	assert_int(sp.rings_broken).is_equal(1)
	assert_int(sp.rings_stalled).is_greater_equal(sp.rings_broken)
	sp.free()


func test_ladder_presence_holds_its_flee_state() -> void:
	var b := _backdrop(LADDER_DIR + "pm_t3.tres")
	await get_tree().process_frame
	var p := _presence(b)
	assert_float(p.flee_progress).is_equal_approx(_ladder(3).presence_fled, 0.0001)
	assert_bool(p.fleeing).is_false()
	b.advance_clock(2.0)
	assert_float(p.flee_progress).is_equal_approx(_ladder(3).presence_fled, 0.0001)
	b.apply_look(_ladder(4))
	assert_bool(b.active_layers().has("presence")).is_false()
