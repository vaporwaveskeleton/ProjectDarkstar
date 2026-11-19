extends GdUnitTestSuite
## Aether pass 5 guards.
## (a) T5 satin fix: the play-core strands are cut into short ragged streaks (a dash field that is a
##     function of w.y + h(w.x) only) and shaded flat / along the strand only. The strip property
##     still holds: the CPU mirror (test_aether_pass4 helpers) flood-fills streak + dash (+ T5 chalk).
## (b) Law 4 (nothing outshines the lantern, ART-001 §16.3): an ANALYTIC bound, not a render (no
##     GPU headless). For every look, the brightest the fog can be over the play core beside the
##     ship (fog capped at A_PLAY_FOG_LUMA, plus the lantern's own in-scatter at pool weight
##     BESIDE_LP) stays under POOL_RATIO × the dimmest the pool heart can be (lantern at pool weight
##     1 over the darkest fog). Mirrors aether_fog_band.gdshader's colour, lantern, drain and
##     band-alpha terms (pinned). Not mirrored: the grade (T5 channel subtraction moves channels
##     toward their own luminance, spared at the pool; drain cold cast), bloom, and non-fog layers
##     (sphere, life, shafts, cracks); the play RING is a blend toward the free fog and is not bounded.
## (c) No black strokes outside the true-black mass: the entity shader writes black exactly once,
##     under s < 0; everything it draws outside is a Pal VOID colour, never black.
## (d) Q-T94 trim: the loss mask's bite stride and early-out are conservative (pinned + numeric).

const COMMON := "res://shaders/aether/aether_common.gdshaderinc"
const FOG := "res://shaders/aether/aether_fog_band.gdshader"
const ENTITY := "res://shaders/aether/entity_presence.gdshader"
const P4 := preload("res://features/aether/tests/test_aether_pass4.gd")
const U := preload("res://features/aether/tests/aether_test_util.gd")
const GRID := 110
const SPAN := 1.1
## Mirror constant (pinned below).
const FOG_DASH := 9.0
## ✱ "beside the ship": pool weight lp = exp(-4 d²/r²) of 0.5 is d ≈ 0.42 lantern radii (~50 px).
const BESIDE_LP := 0.5
## ✱ the margin: the fog beside the ship at most this fraction of the pool heart's luminance.
const POOL_RATIO := 0.8


func _code(path: String) -> String:
	var r: Resource = load(path)
	if r is Shader:
		return (r as Shader).code
	return (r as ShaderInclude).code


static func _luma(c: Color) -> float:
	return c.r * 0.299 + c.g * 0.587 + c.b * 0.114


# --- (a) satin: short ragged streaks, flat shade, still strips -------------------------------------

static func _dash_phase(w: Vector2, sd: float) -> float:
	return w.y * FOG_DASH + 1.8 * P4._noise(Vector2(w.x * 7.0, sd * 2.0 + 5.0)) + 0.5 * P4._noise(Vector2(w.x * 23.0, sd * 2.0 + 8.0))


static func _fog_dash(ph: float, sd: float) -> float:
	return smoothstep(0.28, 0.6, P4._noise(Vector2(ph, sd * 4.0 + 11.0)))


func test_streak_dash_and_flat_shade_are_wired_as_specified() -> void:
	var c := _code(COMMON)
	for line: String in [
		"const float A_FOG_DASH = 9.0;",
		"return w.y * A_FOG_DASH + 1.8 * a_noise(vec2(w.x * 7.0, sd * 2.0 + 5.0)) + 0.5 * a_noise(vec2(w.x * 23.0, sd * 2.0 + 8.0));",
		"return smoothstep(0.28, 0.6, a_noise(vec2(ph, sd * 4.0 + 11.0)));",
		# the shade is a function of the dash phase alone: it never varies across a strand's width
		"float a_streak_shade(float ph, float sd) {",
		"return 0.4 + 0.12 * a_noise(vec2(ph * 0.37, sd * 4.0 + 29.0));",
	]:
		assert_bool(c.contains(line)).override_failure_message("common include lost: " + line).is_true()
	var fog := _code(FOG)
	for line: String in [
		"n = min(n, mix(1.0, a_fog_dash(ph, seed), play));",
		"n_shade = mix(n, a_streak_shade(ph, seed), play);",
		"vec3 col = mix(col_deep, col_mid, smoothstep(0.25, 0.65, n_shade));",
		"col = mix(col, col_high, smoothstep(0.5, 0.85, n_shade) * (0.55 + 0.45 * m));",
		"col = mix(col, col_glow, smoothstep(0.45, 0.8, n_shade) * lumb * 0.85);",
		"m = mix(m, 0.5, play);",
	]:
		assert_bool(fog.contains(line)).override_failure_message("fog band lost: " + line).is_true()
	# the T5 chalk cuts density only, after the shade value was taken
	assert_int(fog.find("n_shade = mix(n, a_streak_shade(ph, seed), play);")).is_less(fog.find("n = min(n, mix(1.0, a_chalk_strand(sw.x, seed), 0.7));"))
	# low contrast: the shade spans 0.12 of the fog value, all of it inside the mid → high ramp
	assert_float(0.12).is_less(0.15)


func test_streaks_with_dashes_and_chalk_have_no_enclosed_holes() -> void:
	var dirs: Array[Vector2] = [Vector2(1.0, 0.25), Vector2(-0.6, 1.0)]
	var seeds: Array[float] = [0.5, 4.2]
	var thresholds: Array[float] = [0.3, 0.45, 0.6]
	for dir in dirs:
		for sd in seeds:
			var fog := PackedFloat32Array()
			var chalk := PackedFloat32Array()
			fog.resize(GRID * GRID)
			chalk.resize(GRID * GRID)
			var origin := -Vector2(SPAN, SPAN) * 0.5 + dir.normalized() * 3.0
			for y in GRID:
				for x in GRID:
					var p := origin + Vector2(x, y) * (SPAN / float(GRID - 1))
					var w := P4._strip_coords(p, dir, sd)
					var v := minf(P4._fog_streak(w, sd, 3), _fog_dash(_dash_phase(w, sd), sd))
					fog[y * GRID + x] = v
					chalk[y * GRID + x] = minf(v, lerpf(1.0, P4._chalk_strand(w.x, sd), 0.7))
			for th in thresholds:
				var case_name := "dir %s seed %.2f th %.2f" % [dir, sd, th]
				assert_int(P4._enclosed_holes(P4._mask(fog, th), GRID)).override_failure_message("streak hole: " + case_name).is_equal(0)
				assert_int(P4._enclosed_holes(P4._mask(chalk, th), GRID)).override_failure_message("chalk hole: " + case_name).is_equal(0)


# --- (b) law 4: the play core stays clearly under the lantern pool --------------------------------

func test_fog_cap_and_lantern_terms_are_pinned() -> void:
	var fog := _code(FOG)
	for line: String in [
		"col = a_cap_luma(col, A_PLAY_FOG_LUMA, pw);",
		"float lp = exp(-ld * ld * 4.0);",
		"vec3 lc = mix(lantern_outer, lantern_col, smoothstep(0.15, 0.8, lp)) * lantern_energy;",
		"vec3 fog_term = mix(col, vec3(a_luma(col)), 0.7) * 0.8;",
		"col += lc * lp * (fog_term + vec3(scatter) * (0.35 + 0.65 * max(dens, is_far)));",
		"col = mix(col, cold(col), drain * 0.92 * (1.0 - lp * 0.85));",
		"float edge = mix(play_fog_ceiling, 1.25, smoothstep(0.2, 0.9, r_scr));",
		"float a = dens * alpha_max * edge * min(0.6 + 0.4 * lumb + 0.25 * lp, 1.0);",
	]:
		assert_bool(fog.contains(line)).override_failure_message("fog band lost: " + line).is_true()
	# the cap comes after every term that can brighten the fog's own colour (glow, lift, tint, stars)
	assert_int(fog.find("col = a_cap_luma(col, A_PLAY_FOG_LUMA, pw);")).is_greater(fog.find("col += star_col * s * stars;"))
	assert_int(fog.find("col = a_cap_luma(col, A_PLAY_FOG_LUMA, pw);")).is_less(fog.find("float ld = length(spx - lantern_px)"))
	var c := _code(COMMON)
	assert_bool(c.contains("return l > cap ? mix(c, c * (cap / l), w) : c;")).is_true()
	var band := (load("res://features/aether/aether_fog_band.gd") as GDScript).source_code
	for line: String in ["set_param(&\"alpha_max\", look.band_alpha * (1.0 - 0.12 * float(i)))",
			"set_param(&\"scatter\", look.lantern_scatter * (1.0 if far else 1.4))"]:
		assert_bool(band.contains(line)).override_failure_message("fog band script lost: " + line).is_true()


static func _lantern_rgb(lp: float, energy: float) -> Color:
	var c := Pal.GAS_3.lerp(Pal.GAS_4, smoothstep(0.15, 0.8, lp))
	return Color(c.r * energy, c.g * energy, c.b * energy)


static func _cold_luma(l: float) -> float:
	return lerpf(_luma(Pal.VOID_1), _luma(Pal.VOID_4), clampf(l * 2.4, 0.0, 1.0))


## Luminance after the drain's cold cast (it depends on luminance only, and is monotone in it).
static func _drained(l: float, drain: float, lp: float) -> float:
	var d := drain * 0.92 * (1.0 - lp * 0.85)
	return lerpf(l, _cold_luma(l), d)


## Exact luminance of one band at pool weight lp over fog colour `col` (RGB mirror).
static func _lit_exact(col: Color, lp: float, energy: float, scatter: float, densf: float) -> float:
	var lc := _lantern_rgb(lp, energy)
	var l := _luma(col)
	var ft := col.lerp(Color(l, l, l), 0.7)
	var k := scatter * (0.35 + 0.65 * densf)
	var o := Color(col.r + lc.r * lp * (ft.r * 0.8 + k), col.g + lc.g * lp * (ft.g * 0.8 + k), col.b + lc.b * lp * (ft.b * 0.8 + k))
	return _luma(o)


## Upper bound of one band's luminance at pool weight lp over ANY fog colour of luminance <= cap:
## luma(lc ⊙ col) <= max_channel(lc) · luma(col).
static func _lit_upper(cap: float, lp: float, energy: float, scatter: float, densf: float) -> float:
	var lc := _lantern_rgb(lp, energy)
	var mc := maxf(lc.r, maxf(lc.g, lc.b))
	var k := scatter * (0.35 + 0.65 * densf)
	return cap + lp * (0.8 * cap * (0.3 * mc + 0.7 * _luma(lc)) + _luma(lc) * k)


## Greedy composite of the translucent bands over `base` (alpha-over is monotone in what is under
## it, so the per-band extreme is the global extreme). `upper` picks max, else min.
static func _composite(base: float, look: AetherLook, bands: int, lp: float, r_scr: float, upper: bool, fog_lo: Color, cap: float) -> float:
	var energy := look.lantern_energy if look.lantern_light else 0.0
	var acc := _drained(base, look.base_drain, lp)
	var edge := lerpf(look.play_fog_ceiling, 1.25, smoothstep(0.2, 0.9, r_scr))
	for i in range(1, bands):
		var amax := look.band_alpha * (1.0 - 0.12 * float(i)) * edge
		var best := acc
		for k in 21:
			var dens := k / 20.0
			var a := clampf(dens * amax, 0.0, 1.0)
			var v := _lit_upper(cap, lp, energy, look.lantern_scatter * 1.4, dens) if upper else _lit_exact(fog_lo, lp, energy, look.lantern_scatter * 1.4, dens)
			v = _drained(v, look.base_drain, lp)
			var mixed := lerpf(acc, v, a)
			best = maxf(best, mixed) if upper else minf(best, mixed)
		acc = best
	return acc


func test_play_core_fog_stays_clearly_under_the_lantern_pool() -> void:
	var cap := P4._const_float(_code(COMMON), "A_PLAY_FOG_LUMA")
	assert_float(cap).is_greater(0.0)
	var q := load("res://data/aether/quality/quality_high.tres") as AetherQuality
	var report: Array[String] = []
	for path in U.look_paths():
		var look := load(path) as AetherLook
		if not look.lantern_light:
			continue
		var bands := mini(look.fog_band_count, q.max_fog_bands)
		var e := look.lantern_energy
		# pool heart: lp = 1 over the darkest fog (far band: col_deep under the engraving hatch)
		var far_lo := look.fog_deep * (1.0 - 0.28 * look.hatch_strength)
		far_lo.a = 1.0
		var heart := _composite(_lit_exact(far_lo, 1.0, e, look.lantern_scatter, 1.0), look, bands, 1.0, 0.06, false, look.fog_deep, cap)
		# beside the ship, anywhere in the play core: the fog at its cap, lantern at BESIDE_LP
		var beside := _composite(_lit_upper(cap, BESIDE_LP, e, look.lantern_scatter, 1.0), look, bands, BESIDE_LP, 0.22, true, look.fog_deep, cap)
		report.append("%s heart>=%.3f beside<=%.3f ratio %.2f" % [look.biome, heart, beside, beside / heart])
		assert_float(beside).override_failure_message("%s: fog beside the ship (<= %.3f) is not clearly under the pool heart (>= %.3f)" % [path, beside, heart]).is_less_equal(heart * POOL_RATIO)
		# and the fog's own light (no lantern) is far under the heart
		assert_float(cap).is_less(heart * 0.5)
	print("AETHER_LAW4 cap=%.3f %s" % [cap, "; ".join(report)])


# --- (c) the entity: black only inside the mass ----------------------------------------------------

func test_entity_writes_black_only_inside_the_mass() -> void:
	var code := _code(ENTITY)
	# exactly one black write, and it is the s < 0 branch
	assert_int(code.count("vec4(0.0, 0.0, 0.0")).is_equal(1)
	assert_int(code.count("COLOR =")).is_equal(2)
	var black := code.find("COLOR = vec4(0.0, 0.0, 0.0, 1.0);")
	var gate := code.find("bool inside = s < 0.0;")
	var branch := code.find("if (inside) {")
	var other := code.find("} else {", branch)
	assert_int(gate).is_greater(-1)
	assert_bool(gate < branch and branch < black and black < other).override_failure_message("the black write is not under s < 0").is_true()
	# outside the mass: only uniform colours (Pal VOIDs), never a literal or a darkened mix to black
	var outside := code.substr(other)
	assert_bool(outside.contains("COLOR = c;")).is_true()
	for bad: String in ["vec3(0.0)", "vec4(0.0, 0.0, 0.0", "* 0.0", "c.rgb *="]:
		assert_bool(outside.contains(bad)).override_failure_message("outside the mass: " + bad).is_false()
	for used: String in ["vec4(gap_col, 1.0)", "vec4(rim_col, 0.5 * lit)", "vec4(mix(gap_col, void_hi, 0.22), 1.0)"]:
		assert_bool(outside.contains(used)).override_failure_message("outside colour changed: " + used).is_true()
	# the colours it is given are Pal VOIDs well above black, and the lit rim stays far under the lantern
	var b := (load(U.BACKDROP) as PackedScene).instantiate() as AetherBackdrop
	b.look = load("res://data/aether/the_black_t5.tres") as AetherLook
	add_child(b)
	await get_tree().process_frame
	var ents := get_tree().get_nodes_in_group(EntityPresence.GROUP)
	assert_int(ents.size()).is_greater_equal(4)
	for n: Node in ents:
		var ep := n as EntityPresence
		for k: StringName in [&"gap_col", &"rim_col", &"void_hi"]:
			var c: Color = ep.get_param(k)
			assert_bool(U.is_black(c)).is_false()
			assert_float(_luma(c)).override_failure_message("%s.%s too dark" % [n.name, k]).is_greater_equal(_luma(Pal.VOID_1) - 0.001)
			assert_bool(U.pal_name(c).begins_with("VOID-")).override_failure_message("%s.%s is not a VOID" % [n.name, k]).is_true()
		assert_float(_luma(ep.get_param(&"rim_col") as Color)).is_less(_luma(Pal.GAS_4))
	b.free()


func test_entity_fractures_stay_in_the_crack_band() -> void:
	var code := _code(ENTITY)
	assert_bool(code.contains("if (!inside && band > 0.0 && s < band) {")).is_true()
	assert_bool(code.contains("if (!drawn) {\n\t\t\tdiscard;") or code.contains("if (!drawn) {\r\n\t\t\tdiscard;")).is_true()


# --- (d) Q-T94: the cheaper loss mask is conservative ---------------------------------------------

func test_loss_mask_trim_is_conservative() -> void:
	var c := _code(COMMON)
	for line: String in [
		"if (i % bite_step != 0) {",
		"float s = a_entity_shape_b(p, sd, entity_time, 2, A_LOSS_BITE_STEP);",
		"if (length(p) > A_LOSS_REACH + 1.2 / e.z) {",
		"return a_entity_shape_b(p, seed, t, oct, 1);",
	]:
		assert_bool(c.contains(line)).override_failure_message("loss trim lost: " + line).is_true()
	# bites only raise d (d = max(d, -bite)), so the 4-bite loss outline <= the 8-bite one
	assert_bool(c.contains("d = max(d, -a_bite(p, ang, depth, open, (h2 - 0.5) * (acute ? 0.5 : 0.2)));")).is_true()
	# past the reach every loss step is 0: s >= |p| - 1 - |warp| - ridge, s_out >= s - |offset|
	var reach := P4._const_float(c, "A_LOSS_REACH")
	var warp := 0.14 * 0.5 * sqrt(2.0)
	var ridge := 0.075 * 0.5
	var offset := Vector2(0.05, -0.03).length()
	var s_out_min := reach - 1.0 - warp - ridge - offset
	assert_float(s_out_min).is_greater(0.5 + 0.05 * 0.5)   # the outer (near) step, before aa
