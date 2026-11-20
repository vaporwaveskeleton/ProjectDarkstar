extends GdUnitTestSuite
## Pass 8, readability (ART-001 §16.6k; TECH-001 §11.2 Q-T295..309): the far layer's value cap keeps
## the play layer on top (Grubs are never the faintest thing on screen), the Presence is a presence
## (subtraction, a breathing edge, an eye that turns toward the Vigil), and lantern down shows vast
## shapes close around the Vigil. Role laws, never-black, flash and reduced-motion bounds hold.

const U := preload("res://features/aether/tests/aether_test_util.gd")
const PM01 := "res://data/aether/pm01_pale_marches_t1.tres"
const GRUB_VIEW := "res://features/choir/grub_view.gd"


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

func test_pm01_caps_the_far_layer_and_the_grade_draws_it() -> void:
	var look := load(PM01) as AetherLook
	assert_float(look.far_value_cap).is_greater(0.0)
	assert_float(look.far_cap_slope).is_less(1.0)
	var b := _backdrop(PM01)
	await get_tree().process_frame
	assert_bool(b.active_layers().has("grade")).is_true()
	var grade := b.find_child("Grade", true, false) as AetherShaderRect
	assert_float(float(grade.get_param(&"cap_knee"))).is_equal_approx(look.far_value_cap, 0.0001)
	assert_bool(U.same_rgb(grade.get_param(&"veil_col") as Color, look.fog_deep)).is_true()
	var code := (load("res://shaders/aether/aether_grade.gdshader") as Shader).code
	assert_bool(code.contains("max(sub, floor_col)")).is_true()


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
		assert_float(float(body["dist"])).is_less(320.0)     # their heads come inside the frame's half-width
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
		assert_float(v.facing(i, lantern)).is_greater(0.0)   # their heads lean toward the Vigil
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
	var p0 := v.positions[0]
	v.step(0.016, lantern, Vector2(100.0, 0.0), false)
	# the camera moved right: they are left behind by about PARALLAX × the step, then follow slowly
	assert_float(v.positions[0].x).is_less(p0.x - 100.0 * RevealVast.PARALLAX + RevealVast.FOLLOW_PX_S * 0.016 + 1.0)
