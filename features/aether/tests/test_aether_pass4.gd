extends GdUnitTestSuite
## Aether pass 4 guards. ART-001 rule (adopted): no closed holes in organic shapes near the play
## centre, and no thin appendages hanging from the entity. Also the meridian numerals (Q-T92:
## engraved I–XII art, not UI text) and the no-right-angle bites.
##
## PROXIES, stated honestly: headless runs have no GPU, so nothing here renders a shader.
## (a) Play-centre holes: the play-core fog and the T5 chalk are built ONLY from strip fields
##     (aether_common.gdshaderinc: a_strip_coords / a_fog_streak / a_chalk_strand). This suite mirrors
##     that math on the CPU (float64, so hash values differ from the GPU's float32 — the strip
##     STRUCTURE, which is what guarantees no holes, is identical) and flood-fills thresholded masks
##     over a grid of seeds, drift directions, drift times and thresholds. The source lines are
##     pinned so the mirror cannot drift from the shader. Not covered: the play RING (core → free
##     fog blend); the opaque far band (its own soft field — T5 chalk narrows it by a strip min, but
##     its base fog is free fbm); the colour terms (only the density field is checked).
##     Entity drain no longer bends the strips (strip coords are taken before the drain stretch).
## (b) Entity appendages: fractures are gated in the shader to 0 < s < A_ENT_CRACK_BAND * grow and
##     stop there as a hairline; this suite pins that gating and proves numerically, from the
##     shader's own constants, that the band lies inside the mid loss step (so inside the outer
##     loss band) for every seed. The old filament (tendril) code must be gone.

const COMMON := "res://shaders/aether/aether_common.gdshaderinc"
const ENTITY := "res://shaders/aether/entity_presence.gdshader"
const FOG := "res://shaders/aether/aether_fog_band.gdshader"
const SPHERE := "res://shaders/aether/crystal_sphere.gdshader"
const U := preload("res://features/aether/tests/aether_test_util.gd")
## Mirror constants (pinned against the shader source below).
const FOG_STREAK := 3.2
const GRID := 110
const SPAN := 1.1      ## noise units sampled per side (the play core is ~0.5 units in radius at fog_scale 150)


func _code(path: String) -> String:
	var r: Resource = load(path)
	if r is Shader:
		return (r as Shader).code
	return (r as ShaderInclude).code


# --- CPU mirror of the shader noise (aether_common.gdshaderinc) ---------------------------------

static func _fract(x: float) -> float:
	return x - floorf(x)


static func _hash(p: Vector2) -> float:
	var p3 := Vector3(_fract(p.x * 0.1031), _fract(p.y * 0.1031), _fract(p.x * 0.1031))
	var k := p3.dot(Vector3(p3.y, p3.z, p3.x) + Vector3(33.33, 33.33, 33.33))
	p3 += Vector3(k, k, k)
	return _fract((p3.x + p3.y) * p3.z)


static func _noise(p: Vector2) -> float:
	var i := Vector2(floorf(p.x), floorf(p.y))
	var f := p - i
	var u := f * f * (Vector2(3.0, 3.0) - 2.0 * f)
	var a := lerpf(_hash(i), _hash(i + Vector2(1, 0)), u.x)
	var b := lerpf(_hash(i + Vector2(0, 1)), _hash(i + Vector2(1, 1)), u.x)
	return lerpf(a, b, u.y)


static func _fbm(p: Vector2, octaves: int) -> float:
	var v := 0.0
	var a := 0.5
	for i in octaves:
		v += a * _noise(p)
		p = Vector2(0.8 * p.x - 0.6 * p.y, 0.6 * p.x + 0.8 * p.y) * 2.03 + Vector2(1.7, 9.2)
		a *= 0.5
	return v


static func _strip_coords(p: Vector2, dir: Vector2, sd: float) -> Vector2:
	var fd := dir.normalized()
	var al := p.dot(fd)
	var ac := p.dot(Vector2(-fd.y, fd.x))
	return Vector2(ac + 0.7 * _noise(Vector2(al * 0.45, sd * 5.0)) + 0.22 * _noise(Vector2(al * 1.9, sd * 5.0 + 3.0)),
		al / FOG_STREAK + 0.9 * _noise(Vector2(ac * 0.6, sd * 3.0 + 9.0)) + 0.45 * _noise(Vector2(ac * 2.1, sd * 3.0 + 1.0)))


static func _fog_streak(w: Vector2, sd: float, octaves: int) -> float:
	var g := _fbm(Vector2(w.x * 2.6, sd * 3.0), octaves)
	var e := _fbm(Vector2(w.y * 1.3, sd * 3.0 + 17.0), 2)
	return 0.5 + (minf(g, e + 0.25) - 0.5) * 0.75


static func _chalk_strand(wx: float, sd: float) -> float:
	return smoothstep(0.42, 0.62, _fbm(Vector2(wx * 4.2, sd * 7.0 + 2.0), 3))


# --- flood fill ---------------------------------------------------------------------------------

## Cells of `low` (true = below threshold) not 8-connected to the grid border: enclosed holes.
static func _enclosed_holes(low: PackedByteArray, n: int) -> int:
	var seen := PackedByteArray()
	seen.resize(n * n)
	var stack: Array[int] = []
	for i in n:
		for idx: int in [i, (n - 1) * n + i, i * n, i * n + n - 1]:
			if low[idx] == 1 and seen[idx] == 0:
				seen[idx] = 1
				stack.append(idx)
	while not stack.is_empty():
		var c: int = stack.pop_back()
		var cx := c % n
		var cy := floori(float(c) / float(n))
		for dy in range(-1, 2):
			for dx in range(-1, 2):
				var x := cx + dx
				var y := cy + dy
				if x < 0 or y < 0 or x >= n or y >= n:
					continue
				var j := y * n + x
				if low[j] == 1 and seen[j] == 0:
					seen[j] = 1
					stack.append(j)
	var holes := 0
	for i in n * n:
		if low[i] == 1 and seen[i] == 0:
			holes += 1
	return holes


static func _mask(values: PackedFloat32Array, t: float) -> PackedByteArray:
	var low := PackedByteArray()
	low.resize(values.size())
	for i in values.size():
		low[i] = 1 if values[i] < t else 0
	return low


# --- (a) play-centre fog and chalk: no enclosed holes ---------------------------------------------

func test_shader_builds_the_play_core_from_strip_fields_only() -> void:
	var c := _code(COMMON)
	for line: String in [
		"const float A_FOG_STREAK = 3.2;",
		"return vec2(ac + 0.7 * a_noise(vec2(al * 0.45, sd * 5.0)) + 0.22 * a_noise(vec2(al * 1.9, sd * 5.0 + 3.0)),",
		"al / A_FOG_STREAK + 0.9 * a_noise(vec2(ac * 0.6, sd * 3.0 + 9.0)) + 0.45 * a_noise(vec2(ac * 2.1, sd * 3.0 + 1.0)));",
		"float g = a_fbm(vec2(w.x * 2.6, sd * 3.0), oct);",
		"float e = a_fbm(vec2(w.y * 1.3, sd * 3.0 + 17.0), 2);",
		"return 0.5 + (min(g, e + 0.25) - 0.5) * 0.75;",
		"return smoothstep(0.42, 0.62, a_fbm(vec2(wx * 4.2, sd * 7.0 + 2.0), 3));",
	]:
		assert_bool(c.contains(line)).override_failure_message("common include lost: " + line).is_true()
	var fog := _code(FOG)
	# the core is the streak field outright (play = 1 there); T5 chalk only ever narrows it by a min
	assert_bool(fog.contains("n = mix(n, a_fog_streak(sw, seed, max(octaves - 2, 2)), play);")).is_true()
	assert_bool(fog.contains("n = min(n, mix(1.0, a_chalk_strand(sw.x, seed), 0.7));")).is_true()
	assert_bool(fog.contains("vec2 sw = a_strip_coords(p + drift_dir * t, drift_dir, seed);")).is_true()
	# the old contour-ring chalk (closed loops with holes beside the lantern) is gone
	assert_bool(fog.contains("fract(n * 5.0")).is_false()


func test_flood_fill_finds_a_ring_hole() -> void:
	# negative control: the old construction (contour rings of a blob) must be caught
	var n := 40
	var vals := PackedFloat32Array()
	vals.resize(n * n)
	for y in n:
		for x in n:
			var r := Vector2(x - n * 0.5, y - n * 0.5).length() / (n * 0.5)
			vals[y * n + x] = absf(_fract(r * 2.0) - 0.5) * 2.0
	assert_int(_enclosed_holes(_mask(vals, 0.5), n)).is_greater(0)


func test_play_core_fog_and_chalk_masks_have_no_enclosed_holes() -> void:
	var dirs: Array[Vector2] = [Vector2(1.0, 0.25), Vector2(-0.6, 1.0), Vector2(0.3, -1.0)]
	var seeds: Array[float] = [0.0, 4.2]
	var drifts: Array[float] = [0.0, 7.5]   # adv = drift_dir * t: the domain only translates
	var thresholds: Array[float] = [0.3, 0.42, 0.55, 0.68]
	for dir in dirs:
		for sd in seeds:
			for t in drifts:
				var fog := PackedFloat32Array()
				var chalk := PackedFloat32Array()
				fog.resize(GRID * GRID)
				chalk.resize(GRID * GRID)
				var origin := dir.normalized() * t - Vector2(SPAN, SPAN) * 0.5
				for y in GRID:
					for x in GRID:
						var p := origin + Vector2(x, y) * (SPAN / float(GRID - 1))
						var w := _strip_coords(p, dir, sd)
						var v := _fog_streak(w, sd, 4)
						fog[y * GRID + x] = v
						chalk[y * GRID + x] = minf(v, lerpf(1.0, _chalk_strand(w.x, sd), 0.7))
				for th in thresholds:
					var case_name := "dir %s seed %.2f t %.1f th %.2f" % [dir, sd, t, th]
					assert_int(_enclosed_holes(_mask(fog, th), GRID)).override_failure_message("fog hole: " + case_name).is_equal(0)
					assert_int(_enclosed_holes(_mask(chalk, th), GRID)).override_failure_message("chalk hole: " + case_name).is_equal(0)


# --- (b) entity: no free-ending appendage outside the loss band ------------------------------------

func test_entity_fractures_never_leave_the_loss_band() -> void:
	var ent := _code(ENTITY)
	assert_bool(ent.contains("tendril")).override_failure_message("filament (limb) code is back").is_false()
	assert_bool(ent.contains("float band = A_ENT_CRACK_BAND * grow;")).is_true()
	assert_bool(ent.contains("if (!inside && band > 0.0 && s < band) {")).is_true()
	assert_bool(ent.contains("float hw = mix(0.9, 0.35, s_frac) / radius;")).is_true()
	assert_bool(ent.contains("uniform float grow = 0.0;")).is_true()
	var c := _code(COMMON)
	var band := _const_float(c, "A_ENT_CRACK_BAND")
	# the entity draws its fractures against its 4-octave outline s4; the loss layers read the
	# 2-octave outline s2. |s4 - s2| is bounded by the extra terms' amplitudes (ridge, noise in ±0.5)
	for line: String in ["d += 0.065 * a_ridge(w * 9.5 + seed);", "d += 0.03 * (a_noise(w * 24.0 - seed) - 0.5);",
			"d += 0.016 * (a_noise(w * 61.0 + seed * 2.0) - 0.5);", "float tear = 0.05 * a_ridge(p * 5.1 + sd * 5.0);",
			"float s_out = s - dot(p / max(length(p), 0.001), vec2(0.05, -0.03));",
			"float mid_l = 1.0 - smoothstep(0.4 + tear - aa, 0.4 + tear + aa, s_out);",
			"float near_l = 1.0 - smoothstep(0.5 + tear - aa, 0.5 + tear + aa, s_out);",
			"float aa = 1.2 / e.z;"]:
		assert_bool(c.contains(line)).override_failure_message("loss math changed: " + line).is_true()
	var octave_gap := (0.065 + 0.03 + 0.016) * 0.5
	var offset := Vector2(0.05, -0.03).length()
	# every (radius, growth) pair the backdrop can ask for: the T5 holes at HOLE_GROWTH, and the main
	# entity along its drain ramp (aether_backdrop.gd set_drain: radius and growth both from `g`)
	var pairs: Array[Vector2] = []
	for h in AetherBackdrop.HOLES:
		pairs.append(Vector2(h.z, AetherBackdrop.HOLE_GROWTH))
	for k in 101:
		var g := k / 100.0
		pairs.append(Vector2(AetherBackdrop.ENTITY_MAX_RADIUS * smoothstep(0.0, 1.0, g), smoothstep(0.1, 1.0, g)))
	for pr in pairs:
		if pr.x < 0.5 or pr.y <= 0.0:
			continue   # not drawn, or no fractures yet
		var aa := 1.2 / pr.x
		var worst_s_out := band * pr.y + octave_gap + offset
		var mid_edge_min := 0.4 - 0.05 * 0.5 - aa              # tear >= -0.025
		assert_float(worst_s_out).override_failure_message("fracture band past the mid loss step at radius %.1f growth %.2f" % [pr.x, pr.y]).is_less(mid_edge_min)
	assert_float(0.4 + 0.025).is_less(0.5 - 0.025)              # the mid step sits inside the outer one


func test_bites_are_acute_or_obtuse_never_square() -> void:
	var c := _code(COMMON)
	var acute := _const_vec2(c, "A_BITE_ACUTE")
	var obtuse := _const_vec2(c, "A_BITE_OBTUSE")
	assert_float(rad_to_deg(acute.y)).is_less(70.0)
	assert_float(rad_to_deg(obtuse.x)).is_greater(110.0)
	# the obtuse flanks lean at most 0.1 of the opening each way: both stay short of the tangent
	assert_float(obtuse.y * 0.6).is_less(PI * 0.5)
	assert_bool(c.contains("(h2 - 0.5) * (acute ? 0.5 : 0.2)")).is_true()
	# the sharp notch: 180° minus the angle between its two normals (1.2 + 0.89 rad) is not 90°
	assert_bool(c.contains("vec2 a1 = vec2(cos(cb + 1.2), sin(cb + 1.2));")).is_true()
	assert_bool(c.contains("vec2 a2 = vec2(cos(cb - 0.89), sin(cb - 0.89));")).is_true()
	assert_float(absf(rad_to_deg(PI - (1.2 + 0.89)) - 90.0)).is_greater(15.0)


# --- Q-T92 numerals ------------------------------------------------------------------------------

func test_numeral_generator_emits_only_i_v_x_for_one_to_twelve() -> void:
	var code := _code(SPHERE)
	var start := code.find("int codes[12] = int[12](")
	assert_int(start).is_greater(-1)
	var open := code.find("(", code.find("int[12]", start))
	var inner := code.substr(open + 1, code.find(")", open) - open - 1)
	var glyphs := {"1": "I", "2": "V", "3": "X"}
	var expect: Array[String] = ["I", "II", "III", "IV", "V", "VI", "VII", "VIII", "IX", "X", "XI", "XII"]
	var parts := inner.split(",")
	assert_int(parts.size()).is_equal(12)
	for i in parts.size():
		var digits := parts[i].strip_edges()
		var roman := ""
		for k in digits.length():
			var ch := digits.substr(k, 1)
			assert_bool(glyphs.has(ch)).override_failure_message("numeral %d has glyph code %s" % [i + 1, ch]).is_true()
			roman += str(glyphs.get(ch, "?"))
		assert_str(roman).is_equal(expect[i])
	# the stroke generator knows exactly three glyphs: I (ch == 1), V (ch == 2), X (else)
	var fn := code.substr(code.find("float roman_numeral("), code.find("vec3 brass_band(") - code.find("float roman_numeral("))
	assert_int(fn.count("if (ch == 1)")).is_equal(1)
	assert_int(fn.count("else if (ch == 2)")).is_equal(1)
	assert_int(fn.count("} else {")).is_equal(1)
	assert_int(fn.count("ch == 3")).is_equal(0)


func test_meridian_numerals_flag_defaults_on_and_switches_off() -> void:
	for path in U.look_paths():
		assert_bool((load(path) as AetherLook).meridian_numerals).is_true()
	var look := (load(U.look_paths()[0]) as AetherLook).duplicate() as AetherLook
	look.meridian_numerals = false
	var b := (load(U.BACKDROP) as PackedScene).instantiate() as AetherBackdrop
	b.look = look
	add_child(b)
	await get_tree().process_frame
	var sphere := b.get_node("%Sphere") as CrystalSphere
	assert_int(int(sphere.get_param(&"numerals"))).is_equal(0)
	look.meridian_numerals = true
	b.apply_look(look)
	assert_int(int(sphere.get_param(&"numerals"))).is_equal(1)
	b.free()


# --- source helpers -----------------------------------------------------------------------------

static func _const_float(code: String, name: String) -> float:
	var key := "const float %s = " % name
	var i := code.find(key)
	if i < 0:
		return NAN
	var j := code.find(";", i)
	return code.substr(i + key.length(), j - i - key.length()).to_float()


static func _const_vec2(code: String, name: String) -> Vector2:
	var key := "const vec2 %s = vec2(" % name
	var i := code.find(key)
	if i < 0:
		return Vector2(NAN, NAN)
	var j := code.find(")", i)
	var parts := code.substr(i + key.length(), j - i - key.length()).split(",")
	return Vector2(parts[0].to_float(), parts[1].to_float())
