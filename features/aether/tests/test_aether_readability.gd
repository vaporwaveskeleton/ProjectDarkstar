extends GdUnitTestSuite
## Pass 8, readability (ART-001 §16.6k; TECH-001 §11.2 Q-T295..309): the far layer's value cap keeps
## the play layer on top (Grubs are never the faintest thing on screen), the Presence is a presence
## (subtraction, a breathing edge, an eye that turns toward the Vigil), and lantern down shows vast
## shapes close around the Vigil. Role laws, never-black, flash and reduced-motion bounds hold.

const U := preload("res://features/aether/tests/aether_test_util.gd")
const PM01 := "res://data/aether/pm01_pale_marches_t1.tres"
const GRUB_VIEW := "res://features/choir/grub_view.gd"
const FAR_LAYER := "res://features/aether/aether_far_layer.tscn"


func _backdrop(path: String) -> AetherBackdrop:
	var b := (load(U.BACKDROP) as PackedScene).instantiate() as AetherBackdrop
	b.look = load(path) as AetherLook
	add_child(b)
	b.set_process(false)
	return auto_free(b)


func _vast_alone() -> RevealVast:
	var v := RevealVast.new()
	v.shader = load("res://shaders/aether/reveal_vast.gdshader") as Shader
	return v


func _lantern_down(b: AetherBackdrop) -> void:
	b.set_lantern_lit(false)
	for i in 30:
		b.advance_clock(0.05)


static func _lin(c: float) -> float:
	return c / 12.92 if c <= 0.04045 else pow((c + 0.055) / 1.055, 2.4)


## Linear luma of a Pal colour (the HDR world's space, as the grade sees it).
static func _luma(c: Color) -> float:
	return 0.2126 * _lin(c.r) + 0.7152 * _lin(c.g) + 0.0722 * _lin(c.b)


## The grade's cap (aether_grade.gdshader) outside the lantern pool.
static func _capped(l: float, look: AetherLook) -> float:
	return l if l <= look.far_value_cap else look.far_value_cap + (l - look.far_value_cap) * look.far_cap_slope


# --- the value hierarchy ------------------------------------------------------------------------------

func test_pm01_caps_the_far_layer_in_the_present_pass() -> void:
	var look := load(PM01) as AetherLook
	assert_float(look.far_value_cap).is_greater(0.0)
	assert_float(look.far_cap_slope).is_less(1.0)
	var far: AetherFarLayer = auto_free((load(FAR_LAYER) as PackedScene).instantiate())
	far.look = look
	add_child(far)
	await get_tree().process_frame
	var m := (far.view.get_node("%Screen") as TextureRect).material as ShaderMaterial
	assert_float(float(m.get_shader_parameter(&"cap_knee"))).is_equal_approx(look.far_value_cap, 0.0001)
	assert_bool(U.same_rgb(m.get_shader_parameter(&"veil_col") as Color, look.fog_deep.srgb_to_linear())).is_true()
	# folded into the present pass (Q-T317): the cap alone no longer switches on the grade's copy
	assert_bool(far.backdrop.active_layers().has("grade")).is_false()
	var code := (load("res://shaders/aether/aether_present.gdshader") as Shader).code
	assert_bool(code.contains("c = max(c, floor_col);")).is_true()
	assert_bool(code.contains("bool entity = max(c.r, max(c.g, c.b)) <= 0.0;")).is_true()


func test_lantern_down_turns_the_far_layer_to_night() -> void:
	var look := load(PM01) as AetherLook
	assert_float(look.lantern_night).is_greater(0.0)
	var b := _backdrop(PM01)
	await get_tree().process_frame
	var m := ShaderMaterial.new()
	m.shader = load("res://shaders/aether/aether_present.gdshader") as Shader
	AetherView.night_material(m, b)
	assert_float(float(m.get_shader_parameter(&"night"))).is_equal(0.0)
	# the night follows the reveal's monotonic ramp: no step, no flicker
	b.set_lantern_lit(false)
	var last := 0.0
	for i in 30:
		b.advance_clock(0.05)
		AetherView.night_material(m, b)
		var n := float(m.get_shader_parameter(&"night"))
		assert_float(n).is_greater_equal(last)
		assert_float(n - last).is_less_equal(0.2)
		last = n
	assert_float(last).is_equal_approx(look.lantern_night, 0.0001)
	# other looks never go to night
	for path in U.look_paths():
		if path != PM01:
			assert_float((load(path) as AetherLook).lantern_night).is_equal(0.0)


func test_other_looks_keep_the_cap_off() -> void:
	for path in U.look_paths():
		if path == PM01:
			continue
		assert_float((load(path) as AetherLook).far_value_cap).override_failure_message("%s caps the far layer" % path).is_equal(0.0)


func test_grubs_outshine_the_capped_far_layer() -> void:
	var look := load(PM01) as AetherLook
	var gv: GDScript = load(GRUB_VIEW)
	# the Grub body is CHOIR-4 and its rim CHOIR-5 (pass 8); the brightest far colours, once capped,
	# sit below them: the fog highlight below the body, anything at all below the rim
	var body := _luma(Pal.CHOIR_4)
	var rim := _luma(Pal.CHOIR_5)
	assert_float(_capped(_luma(look.fog_high), look)).is_less(body)
	assert_float(_capped(_luma(look.presence_pearl), look)).is_less(rim)
	assert_float(_capped(_luma(Pal.BONE_5), look)).is_less(rim)
	assert_float(float(gv.get_script_constant_map()["DRAW_SCALE"])).is_greater(1.0)


# --- the Presence: a presence, not rock ------------------------------------------------------------------

func test_presence_subtracts_with_its_screen_copy() -> void:
	var b := _backdrop(PM01)
	await get_tree().process_frame
	var p := b.find_child("FrostPresence", true, false) as FrostPresence
	var copy := b.find_child("PresenceCopy", true, false) as BackBufferCopy
	assert_bool(FrostPresence.subtracts(b.look)).is_true()
	assert_bool(copy.visible).is_true()
	assert_float(float(p.get_param(&"subtract"))).is_equal(1.0)
	assert_float(float(p.get_param(&"eye_k"))).is_greater(0.0)
	assert_float(float(p.get_param(&"breath_px"))).is_greater(0.0)
	# the copy sits right before the Presence in its layer, so it reads only what lies behind it
	assert_int(copy.get_index()).is_equal(p.get_index() - 1)
	# never black: the eye and the drink go to VOID tones, the floor holds
	var code := (load("res://shaders/aether/frost_presence.gdshader") as Shader).code
	assert_bool(code.contains("col = max(col, floor_col);")).is_true()
	assert_int(code.count("vec4(0.0, 0.0, 0.0")).is_equal(0)
	for k: Variant in U.colour_uniforms(p.mat).keys():
		assert_bool(U.is_black(U.colour_uniforms(p.mat)[k] as Color)).override_failure_message("presence %s is black" % k).is_false()


func test_looks_without_subtraction_hide_the_copy() -> void:
	var b := _backdrop("res://data/aether/pale_marches_t1.tres")
	await get_tree().process_frame
	assert_bool((b.find_child("PresenceCopy", true, false) as BackBufferCopy).visible).is_false()


func test_presence_gaze_turns_toward_the_vigil_slowly() -> void:
	var b := _backdrop(PM01)
	await get_tree().process_frame
	var p := b.find_child("FrostPresence", true, false) as FrostPresence
	b.refresh()
	var xf := p.get_global_transform_with_canvas()
	var eye := xf * FrostPresence.EYE
	var target := eye + Vector2(-300.0, 40.0)
	var want := xf.basis_xform_inv(target - eye).angle()
	var start := p.gaze_angle
	p.watch(target, 0.1, false)
	# rate-limited: one 0.1 s step turns at most GAZE_RATE × 0.1
	assert_float(absf(angle_difference(start, p.gaze_angle))).is_less_equal(FrostPresence.GAZE_RATE * 0.1 + 0.0001)
	for i in 200:
		p.watch(target, 0.1, false)
	assert_float(absf(angle_difference(p.gaze_angle, want))).is_less(0.01)
	# reduced motion: held at rest
	p.watch(target, 0.1, true)
	assert_float(p.gaze_angle).is_equal(FrostPresence.GAZE_REST)


# --- lantern down: the vast shapes ---------------------------------------------------------------------

func test_vast_shapes_show_only_with_the_lantern_down() -> void:
	var b := _backdrop(PM01)
	await get_tree().process_frame
	var v := b.find_child("RevealVast", true, false) as RevealVast
	assert_int(v.count).is_equal((load(PM01) as AetherLook).reveal_vast_count)
	assert_int(v.count).is_greater(0)
	b.advance_clock(0.05)
	assert_bool(v.visible).is_false()
	assert_bool(b.active_layers().has("vast")).is_false()
	_lantern_down(b)
	assert_bool(v.visible).is_true()
	assert_bool(b.active_layers().has("vast")).is_true()
	assert_float(float(v.get_param(&"reveal"))).is_equal(1.0)
	b.set_lantern_lit(true)
	for i in 30:
		b.advance_clock(0.05)
	assert_bool(v.visible).is_false()


func test_vast_shapes_are_huge_close_and_far_layer_only() -> void:
	var b := _backdrop(PM01)
	await get_tree().process_frame
	var v := b.find_child("RevealVast", true, false) as RevealVast
	for body: Dictionary in RevealVast.BODIES:
		assert_float(float(body["len"])).is_greater(360.0)   # longer than the frame is tall
	assert_int(v.find_children("*", "CollisionObject2D", true, false).size()).is_equal(0)
	assert_int(v.find_children("*", "Light2D", true, false).size()).is_equal(0)
	# behind the play layer: inside the backdrop, under the life and fog layers that sit in front
	assert_int(v.get_parent().get_index()).is_less(b.find_child("LifeLayer", true, false).get_index())
	for k: Variant in U.colour_uniforms(v.mat).keys():
		var c: Color = U.colour_uniforms(v.mat)[k]
		assert_bool(U.is_black(c)).override_failure_message("vast %s is black" % k).is_false()
		assert_bool(U.is_ramp(c, "GAS")).override_failure_message("vast %s is GAS" % k).is_false()
		assert_bool(U.is_ramp(c, "CHOIR")).override_failure_message("vast %s is CHOIR" % k).is_false()
		assert_str(U.pal_name(c)).override_failure_message("vast %s is not a Pal entry" % k).is_not_empty()
	var code := (load("res://shaders/aether/reveal_vast.gdshader") as Shader).code
	assert_bool(code.contains("max(acc.rgb / max(acc.a, 0.0001), floor_col)")).is_true()
	# the photophore wave is 0.2 Hz (2π × 0.2 = 1.2566 rad/s): far under the 3 Hz flicker cap
	assert_bool(code.contains("t * 1.2566")).is_true()


func test_vast_heads_turn_toward_the_lantern_and_hold_still_under_reduced_motion() -> void:
	var v: RevealVast = auto_free(_vast_alone())
	add_child(v)
	await get_tree().process_frame
	var look := load(PM01) as AetherLook
	v.configure(look)
	var lantern := Vector2(320.0, 180.0)
	v.step(0.016, lantern, Vector2.ZERO, false)
	var before: Array[float] = v.headings.duplicate()
	v.step(0.5, lantern, Vector2.ZERO, false)
	for i in v.count:
		assert_float(absf(angle_difference(before[i], v.headings[i]))).is_less_equal(RevealVast.TURN_RATE * 0.5 + 0.0001)
		# their heads turn toward the Vigil: the head points closer to it than the body's own axis
		var to_l := (lantern - v.positions[i]).normalized()
		var axis := Vector2.from_angle(float(RevealVast.BODIES[i]["heading"]))
		assert_float(Vector2.from_angle(v.headings[i]).dot(to_l)).is_greater(axis.dot(to_l))
		assert_float(absf(angle_difference(float(RevealVast.BODIES[i]["heading"]), v.headings[i]))).is_less_equal(RevealVast.MAX_BEND + 0.0001)
	# reduced motion: fixed places around the lantern, no drift
	v.step(0.5, lantern, Vector2(40.0, 0.0), true)
	var held: Array[Vector2] = v.positions.duplicate()
	v.step(3.0, lantern, Vector2(40.0, 0.0), true)
	for i in v.count:
		assert_bool(v.positions[i].is_equal_approx(held[i])).is_true()
		assert_bool(v.positions[i].is_equal_approx(v.target(i, lantern, 0.0, true))).is_true()


func test_vast_lags_the_camera_travel_then_closes_back_in() -> void:
	var v: RevealVast = auto_free(_vast_alone())
	add_child(v)
	await get_tree().process_frame
	v.configure(load(PM01) as AetherLook)
	var lantern := Vector2(320.0, 180.0)
	v.step(0.016, lantern, Vector2.ZERO, false)
	var p0 := v.positions[1]
	v.step(0.016, lantern, Vector2(100.0, 0.0), false)
	# the camera moved right: they are left behind by about PARALLAX × the step, then follow slowly
	assert_float(v.positions[1].x).is_less(p0.x - 100.0 * float(RevealVast.BODIES[1]["par"]) + RevealVast.FOLLOW_PX_S * 0.016 + 1.0)


func test_vast_identity_and_scale() -> void:
	var v: RevealVast = auto_free(_vast_alone())
	add_child(v)
	await get_tree().process_frame
	v.configure(load(PM01) as AetherLook)
	var lantern := Vector2(320.0, 180.0)
	v.step(0.016, lantern, Vector2.ZERO, true)
	# one crosses in front of the distant glow: its body (head to tail) lies inside the glow's ellipse
	var b0 := RevealVast.BODIES[0]
	assert_bool(b0["anchor"] == &"horizon").is_true()
	var head := v.positions[0]
	var tail := head - Vector2.from_angle(float(b0["heading"])) * float(b0["len"])
	for q: Vector2 in [head, (head + tail) * 0.5]:
		var n := (q - RevealVast.HORIZON) / RevealVast.HORIZON_R
		assert_float(n.length()).is_less(1.0)
	# the scale cue: one body's flank lights are scaled up so one light is about the Vigil's size
	var biggest := 0.0
	for b: Dictionary in RevealVast.BODIES:
		biggest = maxf(biggest, float(b["light"]))
	assert_float(biggest).is_greater_equal(3.0)
	var code := (load("res://shaders/aether/reveal_vast.gdshader") as Shader).code
	for part in ["neck", "fins", "tendrils", "portholes", "rim"]:
		assert_bool(code.contains(part)).override_failure_message("vast shader lost its %s" % part).is_true()


# --- pass 8 c: no eye reads, the lantern-down floor, the normal state's hues -------------------------------

func test_presence_has_no_eye_only_a_lightless_disc() -> void:
	var code := (load("res://shaders/aether/frost_presence.gdshader") as Shader).code
	for gone in ["iris_c", "pupil", "glint_col", "uniform float lock", "slit"]:
		assert_bool(code.contains(gone)).override_failure_message("the Presence still has %s" % gone).is_false()
	assert_bool(code.contains("vec3 eye_col = mix(floor_col, void_col, 0.15);")).is_true()
	# the serpents carry no head light where an eye would be
	var vast := (load("res://shaders/aether/reveal_vast.gdshader") as Shader).code
	assert_bool(vast.contains("head_l")).is_false()
	assert_bool(vast.contains("head_col")).is_false()


func test_night_floor_is_coloured_and_the_normal_state_has_three_hues() -> void:
	var look := load(PM01) as AetherLook
	assert_float(look.far_split_tone).is_greater(0.0)
	var m := ShaderMaterial.new()
	m.shader = load("res://shaders/aether/aether_present.gdshader") as Shader
	AetherView.grade_material(m, look)
	var nf: Color = m.get_shader_parameter(&"night_floor")
	# deep indigo, never neutral: blue well above red and green, and above the VOID-0 floor
	assert_float(nf.b).is_greater(nf.r * 2.0)
	assert_float(nf.b).is_greater(Pal.VOID_0.srgb_to_linear().b)
	assert_float(float(m.get_shader_parameter(&"tone_k"))).is_equal(look.far_split_tone)
	# the three tones are Pal hues: AETHER-5 teal, AETHER-4 rose-pearl, GAS-3 only in the lantern's pool
	assert_bool(U.same_rgb(m.get_shader_parameter(&"tone_deep") as Color, Pal.AETHER_5.srgb_to_linear())).is_true()
	assert_bool(U.same_rgb(m.get_shader_parameter(&"tone_lit") as Color, Pal.AETHER_4.srgb_to_linear())).is_true()
	assert_bool(U.same_rgb(m.get_shader_parameter(&"tone_pool") as Color, Pal.GAS_3.srgb_to_linear())).is_true()
	var code := (load("res://shaders/aether/aether_present.gdshader") as Shader).code
	assert_bool(code.contains("float w_pool = 0.35 * spare")).is_true()   # amber only inside the lantern pool


func test_geodes_sink_with_a_glint_and_the_vigil_keeps_an_ember() -> void:
	var g: SectorGeode = auto_free(SectorGeode.new())
	assert_float(SectorGeode.DARK_KEEP).is_equal_approx(0.3, 0.05)
	g.set_dark(2.0)
	assert_float(g.dark).is_equal(1.0)
	g.set_dark(0.0)
	assert_float(g.dark).is_equal(0.0)
	var rig: AetherVigilRig = auto_free(AetherVigilRig.new())
	assert_float(rig._ember_level(1.0)).is_equal(0.0)          # lantern up: no ember
	assert_float(rig._ember_level(0.15)).is_greater(0.5)       # lantern down: a dim ember stays
	rig._breached = true
	assert_float(rig._ember_level(0.0)).is_equal(0.0)          # a breach gutters it out
