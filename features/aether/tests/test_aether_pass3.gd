extends GdUnitTestSuite
## Aether pass 3 guards: the stepped subtraction keeps the only black inside the entity, the far
## set pieces sort the tiers by silhouette and never use GAS, mid fog is the CH-7 lever, and the
## Presence passes over the lantern instead of enclosing it.

const U := preload("res://features/aether/tests/aether_test_util.gd")
## Lantern y in the gallery (CAMERA_HOME.y + LANTERN_OFFSET.y, aether_gallery.gd) — layer px.
const LANTERN_Y := 202.0
## Largest undulation of the leviathan's centre line (a_lev_profile: 26 px * (0.5 + 1.0)).
const LEV_WAVE_MAX := 39.0


func _backdrop_with(path: String) -> AetherBackdrop:
	var b := (load(U.BACKDROP) as PackedScene).instantiate() as AetherBackdrop
	b.look = load(path) as AetherLook
	add_child(b)
	return b


func test_entity_is_the_only_black_write_and_the_middle_step_is_void() -> void:
	var ent := (load("res://shaders/aether/entity_presence.gdshader") as Shader).code
	assert_int(ent.count("COLOR =")).is_equal(1)
	assert_bool(ent.contains("COLOR = vec4(0.0, 0.0, 0.0, 1.0);")).is_true()
	var fog := (load("res://shaders/aether/aether_fog_band.gdshader") as Shader).code
	# the middle step is a flat cold VOID made from the band's void colours, then floored
	assert_bool(fog.contains("col = mix(col, mix(void_lo, void_hi, 0.22), loss.z);")).is_true()
	assert_bool(fog.contains("col = max(col, floor_col);")).is_true()
	for path in U.look_paths():
		var b := _backdrop_with(path)
		await get_tree().process_frame
		var nodes: Array[Node] = []
		U.walk(b, nodes)
		for n in nodes:
			if n is AetherFogBand:
				var band := n as AetherFogBand
				for p: StringName in [&"void_lo", &"void_hi"]:
					var c: Color = band.get_param(p)
					assert_bool(U.is_black(c)).override_failure_message("%s %s.%s is black" % [path, n.name, p]).is_false()
		b.free()


func test_set_pieces_never_use_gas() -> void:
	for path in U.look_paths():
		var b := _backdrop_with(path)
		await get_tree().process_frame
		var nodes: Array[Node] = []
		U.walk(b, nodes)
		var copies := 0
		for n in nodes:
			if n is FarSetPieces:
				copies += 1
				for c: Color in (n as FarSetPieces).colours_used():
					assert_bool(U.is_ramp(c, "GAS")).override_failure_message("%s %s uses GAS" % [path, n.name]).is_false()
		assert_int(copies).is_equal(2)
		b.free()


func test_each_tier_has_its_own_set_piece_silhouette() -> void:
	var expect := {
		1: "orrery", 2: "greenhouse", 3: "dome", 4: "ribs", 5: "fragments",
	}
	var seen := {}
	for path in U.look_paths():
		var look := load(path) as AetherLook
		var fams: Array[String] = []
		if look.set_orrery_rings:
			fams.append("orrery")
		if look.set_greenhouse:
			fams.append("greenhouse")
		if look.set_dome:
			fams.append("dome")
		if look.set_ring_fragments:
			fams.append("fragments")
		if look.orrery:
			fams.append("ribs")
		if look.set_lattice:
			fams.append("lattice")
		var family: String = expect.get(look.tier, "")
		if seen.has(look.tier):
			continue
		seen[look.tier] = true
		assert_array(fams).override_failure_message("%s set pieces %s" % [path, fams]).is_equal([family])
	assert_int(seen.size()).is_equal(5)


func test_back_copy_draws_only_the_armillary() -> void:
	var sp := FarSetPieces.new()
	sp.half = FarSetPieces.Half.BACK
	sp.show_greenhouse = true
	sp.show_dome = true
	sp.show_fragments = true
	assert_bool(sp.any_shown()).is_false()
	sp.show_orrery = true
	assert_bool(sp.any_shown()).is_true()
	sp.free()


func test_mid_fog_is_the_low_rung_lever() -> void:
	for lv in AetherQuality.LEVELS:
		var q := load(AetherQuality.path_for(lv)) as AetherQuality
		assert_float(q.mid_fog_resolution_scale).is_less_equal(q.fog_resolution_scale)
	var lo := load(AetherQuality.path_for("low")) as AetherQuality
	assert_float(lo.mid_fog_resolution_scale).is_less_equal(0.25)


func test_leviathan_belly_passes_above_the_lantern() -> void:
	var code := (load("res://shaders/aether/aether_common.gdshaderinc") as ShaderInclude).code
	assert_bool(code.contains("const float A_LEV_BELLY = 0.4;")).is_true()
	var lev := AetherLeviathan.new()
	var belly := lev.body_y + lev.thickness * 0.4 + LEV_WAVE_MAX
	assert_float(belly).is_less(LANTERN_Y)
	lev.free()
