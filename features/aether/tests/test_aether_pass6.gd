extends GdUnitTestSuite
## Aether pass 6 guards (G-2 tier sort + The Reviewer's three fixes).
## (a) ONE monotonic "missing" cue: AetherLook.missing is 0 at T1 and strictly grows with the tier;
##     it drives the fog's saturation drain, star dropout and the VOID slice, and the sphere's
##     saturation and its keep mask (wiring pinned). The slice starts off-centre, never reaches the
##     frame edge and stays out of the play core (CPU mirror of a_missing's extent).
## (b) T1 is the most intact: no dark disc at the armillary's heart (a LIT brass sun), no dark ring
##     edge, and the sun is not darker than T1's fog.
## (c) No closed circles in ORGANIC / FOG shapes near the play centre (PM scoping, 2026-11-19; the
##     orrery rings and crystal spheres are geometric and exempt): the entity's near and mid loss
##     steps ride two spiral arms that break every half turn (CPU mirror of the threshold), so no arc
##     of either boundary turns past ~half a turn and the boundary is not a circle.
## (d) B2 / B3 wiring: the crazing erodes inward (gradient of disintegration); dim panes get rims.

const COMMON := "res://shaders/aether/aether_common.gdshaderinc"
const FOG := "res://shaders/aether/aether_fog_band.gdshader"
const SPHERE := "res://shaders/aether/crystal_sphere.gdshader"
const ENTITY := "res://shaders/aether/entity_presence.gdshader"
const CRACK := "res://shaders/aether/sky_crack.gdshader"
const P4 := preload("res://features/aether/tests/test_aether_pass4.gd")
const U := preload("res://features/aether/tests/aether_test_util.gd")
## ✱ the logical frame and the gallery camera's drift margin (look.camera_drift_px default).
const FRAME := Vector2(640.0, 360.0)
const DRIFT := 18.0


func _code(path: String) -> String:
	var r: Resource = load(path)
	if r is Shader:
		return (r as Shader).code
	return (r as ShaderInclude).code


static func _luma(c: Color) -> float:
	return c.r * 0.299 + c.g * 0.587 + c.b * 0.114


func _looks_by_tier() -> Dictionary:
	var out := {}
	for path in U.look_paths():
		var look := load(path) as AetherLook
		out[look.tier] = look
	return out


# --- (a) the missing curve ---------------------------------------------------------------------------

func test_missing_is_zero_at_t1_and_strictly_grows_by_tier() -> void:
	var by_tier := _looks_by_tier()
	assert_int(by_tier.size()).is_equal(5)
	assert_float((by_tier[1] as AetherLook).missing).is_equal(0.0)
	for t in range(2, 6):
		var lo := (by_tier[t - 1] as AetherLook).missing
		var hi := (by_tier[t] as AetherLook).missing
		assert_float(hi).override_failure_message("missing T%d %.2f !> T%d %.2f" % [t, hi, t - 1, lo]).is_greater(lo)
		assert_float(hi).is_less_equal(1.0)
	assert_bool((by_tier[1] as AetherLook).tunable_properties().has("missing")).is_true()


func test_missing_drives_saturation_slice_and_stars_together() -> void:
	var c := _code(COMMON)
	assert_bool(c.contains("float a_missing(vec2 spx, float m) {")).is_true()
	var fog := _code(FOG)
	for line: String in [
		"uniform float missing = 0.0;",
		"float mz = a_missing(spx, missing) * (1.0 - loss.y);",
		"if (h > 0.955 + 0.04 * missing) {",
		"col = mix(col, vec3(a_luma(col)), missing * A_MISS_DESAT);",
		"col = mix(col, mix(void_lo, void_hi, 0.22), mz);",
		"* (1.0 - 0.8 * drain) * (1.0 - mz);",
	]:
		assert_bool(fog.contains(line)).override_failure_message("fog band lost: " + line).is_true()
	# the saturation drain sits before the law-4 cap and the lantern (the pool stays the warm thing)
	assert_int(fog.find("missing * A_MISS_DESAT")).is_less(fog.find("col = a_cap_luma(col, A_PLAY_FOG_LUMA, pw);"))
	var sph := _code(SPHERE)
	assert_bool(sph.contains("float keep = (1.0 - loss.y) * (1.0 - a_missing(spx, missing));")).is_true()
	assert_bool(sph.contains("max(drain * 0.6, missing * A_MISS_DESAT)")).is_true()
	var band := (load("res://features/aether/aether_fog_band.gd") as GDScript).source_code
	assert_bool(band.contains("set_param(&\"missing\", look.missing)")).is_true()
	var bd := (load("res://features/aether/aether_backdrop.gd") as GDScript).source_code
	assert_bool(bd.contains("_sphere.set_param(&\"missing\", look.missing)")).is_true()


## Screen point of the slice's centre line at arc offset `u` (signed, slice-relative units) for m.
static func _slice_point(c: String, sphere: Vector3, m: float, u: float) -> Vector2:
	var seam := P4._const_float(c, "A_MISS_SEAM")
	var x0 := P4._const_float(c, "A_MISS_X")
	var lv := P4._const_vec2(c, "A_MISS_LEN")
	var inward := P4._const_float(c, "A_MISS_INWARD")
	var rr := sphere.z + seam
	var arc0 := asin(clampf((x0 - sphere.x) / rr, -1.0, 1.0)) * rr
	var half := lv.x + lv.y * m
	var arc := arc0 + (u * half if u < 0.0 else u * half * inward)
	var ang := arc / rr
	return Vector2(sphere.x + sin(ang) * rr, sphere.y - cos(ang) * rr)


func test_slice_starts_off_centre_and_never_reaches_the_frame_edge_or_the_play_core() -> void:
	var c := _code(COMMON)
	var sph := CrystalSphere.new()
	var sphere := Vector3(sph.sphere_centre.x, sph.sphere_centre.y, sph.sphere_radius)
	sph.free()
	var hw := P4._const_vec2(c, "A_MISS_W")
	var core := P4._const_float(c, "A_PLAY_CORE") * FRAME.y
	var centre := FRAME * 0.5
	for look: AetherLook in _looks_by_tier().values():
		var m := look.missing
		if m <= 0.0:
			continue
		var w := hw.x + hw.y * m * m
		for k in 41:
			var u := lerpf(-1.0, 1.0, float(k) / 40.0)
			var pt := _slice_point(c, sphere, m, u)
			var tag := "T%d u %.2f at %s" % [look.tier, u, pt]
			# from inside the picture (N8): the slice and its width stay clear of every frame edge
			assert_bool(pt.x - w > DRIFT and pt.x + w < FRAME.x - DRIFT and pt.y - w > DRIFT and pt.y + w < FRAME.y - DRIFT) \
				.override_failure_message("slice reaches the frame edge: " + tag).is_true()
			# and out of the play core
			assert_float(pt.distance_to(centre) - w).override_failure_message("slice in the play core: " + tag).is_greater(core)
	# its start is off-centre (left of the play core)
	assert_float(P4._const_float(c, "A_MISS_X")).is_less(centre.x - core)


# --- (b) T1 is the most intact -----------------------------------------------------------------------

func test_t1_armillary_has_a_lit_sun_not_a_dark_disc() -> void:
	var src := (load("res://features/aether/far_set_pieces.gd") as GDScript).source_code
	assert_bool(src.contains("draw_circle(orrery_centre, 14.0, _c(brass_shadow")).override_failure_message("dark globe is back").is_false()
	assert_bool(src.contains("draw_circle(orrery_centre, 14.0, _c(sun_body, 1.0))")).is_true()
	var sp := FarSetPieces.new()
	var t1 := _looks_by_tier()[1] as AetherLook
	sp.configure(t1)
	assert_bool(U.is_ramp(sp.sun_body, "BONE")).is_true()
	assert_bool(U.is_ramp(sp.sun_hi, "BONE")).is_true()
	# nothing in T1 darker than its fog: the sun is at least as light as the fog's mid tone
	assert_float(_luma(sp.sun_body)).is_greater_equal(_luma(t1.fog_mid))
	sp.free()
	# the armillary's own rings draw no dark engraved edge (shadow 0) and are calmer than pass 5
	assert_int(src.count("* ORRERY_CALM, 0.0)")).is_equal(2)
	assert_float(FarSetPieces.ORRERY_CALM).is_less(1.0)


# --- (c) no closed circles in organic / fog shapes near the play centre ------------------------------

## CPU mirror of the loss steps' outward reach at angle `ang` (entity-normalised): A_LOSS_ARM ×
## fract(ang / π + seed × 0.37). The tear (±0.025) and aa are left out: they are small next to the
## arm's break.
static func _arm(c: String, ang: float, sd: float) -> float:
	return P4._const_float(c, "A_LOSS_ARM") * fposmod(ang / PI + sd * 0.37, 1.0)


func test_loss_step_boundary_breaks_every_half_turn_and_is_not_a_circle() -> void:
	var c := _code(COMMON)
	assert_bool(c.contains("float arm = A_LOSS_ARM * fract(atan(p.y, p.x) * 0.31830989 + sd * 0.37);")).is_true()
	var arm := P4._const_float(c, "A_LOSS_ARM")
	# the break must be clearly larger than the torn edge's own wobble (tear ±0.025, both sides)
	assert_float(arm).is_greater(0.05 * 2.0)
	var n := 720
	for sd: float in [0.7, 3.1, 5.9, 8.4]:
		var breaks: Array[int] = []
		var lo := INF
		var hi := -INF
		for k in n:
			var a0 := TAU * float(k) / float(n) - PI
			var a1 := TAU * float(k + 1) / float(n) - PI
			var r0 := 1.4 + _arm(c, a0, sd)
			var r1 := 1.4 + _arm(c, a1, sd)
			lo = minf(lo, r0)
			hi = maxf(hi, r0)
			if absf(r1 - r0) > arm * 0.5:
				breaks.append(k)
		assert_int(breaks.size()).override_failure_message("seed %.1f: %d breaks" % [sd, breaks.size()]).is_greater_equal(2)
		# the longest unbroken run of the boundary turns no further than about half a turn
		var longest := 0
		for i in breaks.size():
			var nxt: int = breaks[(i + 1) % breaks.size()] + (n if i + 1 >= breaks.size() else 0)
			longest = maxi(longest, nxt - breaks[i])
		assert_float(TAU * float(longest) / float(n)).override_failure_message("seed %.1f: an arc of %.2f rad" % [sd, TAU * float(longest) / float(n)]).is_less_equal(PI * 1.02)
		# not a circle: the radius varies by the whole arm
		assert_float(hi - lo).is_greater(arm * 0.9)
	# the soft side and the arms only push the steps outward (lower edges unchanged)
	assert_bool(c.contains("smoothstep(0.4 + arm + tear - aa, 0.4 + arm + tear + aa + soft, s_out)")).is_true()


func test_drain_stretch_is_twisted_into_a_spiral_arm() -> void:
	var fog := _code(FOG)
	assert_bool(fog.contains("pd -= sax * dot(pd, sax) * 0.55 * toward.z;")).is_true()
	assert_bool(fog.contains("pd -= toward.xy * dot(pd, toward.xy)")).override_failure_message("radial (ring) stretch is back").is_false()
	assert_float(P4._const_float(fog, "A_DRAIN_TWIST")).is_greater(0.3)


# --- (d) B2 crazing gradient, B3 dim-pane rims -------------------------------------------------------

func test_crazing_erodes_inward_and_dims_inward() -> void:
	var code := _code(ENTITY)
	for line: String in [
		"float er = A_ENT_ERODE * cell * pow(1.0 - s_frac, A_ENT_ERODE_K);",
		"} else if (dn < hw || cd.y < er) {",
		"} else if (dn < hw + rim_w || cd.y < er + rim_w) {",
		"float lit = mix(0.15, 1.0, smoothstep(0.0, 0.75, s_frac)) * (1.0 - 0.7 * smoothstep(0.88, 1.0, s_frac));",
	]:
		assert_bool(code.contains(line)).override_failure_message("crazing lost: " + line).is_true()
	# erosion: at the mass most of a cell is gone (specks), at the outer edge none
	var erode := P4._const_float(code, "A_ENT_ERODE")
	assert_float(erode).is_between(0.3, 0.5)
	# the rims are brighter at the outer side than at the mass
	var lit_in := lerpf(0.15, 1.0, smoothstep(0.0, 0.75, 0.05))
	var lit_out := lerpf(0.15, 1.0, smoothstep(0.0, 0.75, 0.8)) * (1.0 - 0.7 * smoothstep(0.88, 1.0, 0.8))
	assert_float(lit_out).is_greater(lit_in * 2.0)


func test_dim_panes_get_the_open_panes_lit_rim() -> void:
	var code := _code(CRACK)
	assert_bool(code.contains("float rimmed = max(max(opened, ob), max(dimmed, db));")).is_true()
	assert_bool(code.contains("float keep = rimmed > 0.5 ? 1.0 :")).is_true()
	assert_bool(code.contains("float wgt = rimmed > 0.5 ? 1.0 :")).is_true()
	assert_bool(code.contains("line = min(line, drawn_rim * px_k);")).is_true()
