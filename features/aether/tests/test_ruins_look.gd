extends GdUnitTestSuite
## RuinsLook (the Ruins first-visit look, NARR-001 §5.7, ART-001 §16): loads headless; Tree lamps
## raise the hangar-mouth light monotonically; no pure black colour source outside the entity; the
## hall lantern is the brightest light (law 4); lamps never flash (per-frame step bound ✱); the
## first-visit cold open works. The look is stepped by hand at 60 Hz (its _process is off).

const U := preload("res://features/aether/tests/aether_test_util.gd")
const SCENE := "res://features/aether/ruins_look.tscn"
const DT := 1.0 / 60.0
const LAMPS: Array[Vector2] = [Vector2(370, 242), Vector2(411, 234), Vector2(383, 216), Vector2(420, 260)]

var _look: RuinsLook


func _make(first_visit: bool, data: RuinsLookData = null) -> RuinsLook:
	_look = (load(SCENE) as PackedScene).instantiate() as RuinsLook
	if data != null:
		_look.data = data
	_look.set_first_visit(first_visit)
	add_child(_look)
	_look.set_process(false)
	return _look


func after_test() -> void:
	if is_instance_valid(_look):
		_look.free()


func _steps(look: RuinsLook, seconds: float) -> void:
	for _i in int(ceilf(seconds / DT)):
		look.step(DT)


func _all_lamps(look: RuinsLook) -> Array[RuinsLamp]:
	var out: Array[RuinsLamp] = [look.hall_lantern]
	out.append_array(look.lamps())
	return out


func test_loads_headless() -> void:
	var look := _make(false)
	await get_tree().process_frame
	assert_object(look).is_not_null()
	assert_object(look.backdrop).is_not_null()
	assert_object(look.stage).is_not_null()
	assert_object(look.hall_lantern).is_not_null()
	assert_bool(look.data.outside_look != null).is_true()
	assert_float(look.mouth_light()).is_equal(0.0)
	assert_int(look.lamp_count()).is_equal(0)
	assert_bool(look.data.ds_namespace.begins_with("ds_")).is_true()


func test_light_lamp_raises_the_mouth_light_monotonically() -> void:
	var look := _make(false)
	await get_tree().process_frame
	var mouth := look.get_node("%MouthLight") as PointLight2D
	var prev := look.mouth_light()
	var prev_energy := mouth.energy if mouth.enabled else 0.0
	for p in LAMPS:
		var before := look.mouth_light()
		look.light_lamp(p)
		for _f in int(ceilf((look.data.lamp_catch_s + 0.5) / DT)):
			look.step(DT)
			var m := look.mouth_light()
			var e := mouth.energy if mouth.enabled else 0.0
			assert_float(m).override_failure_message("mouth light fell: %f → %f" % [prev, m]).is_greater_equal(prev - 1e-6)
			assert_float(e).override_failure_message("mouth energy fell: %f → %f" % [prev_energy, e]).is_greater_equal(prev_energy - 1e-6)
			prev = m
			prev_energy = e
		assert_float(look.mouth_light()).override_failure_message("lamp at %s did not raise the mouth" % p).is_greater(before + 0.01)
	assert_float(look.mouth_light()).is_less_equal(1.0)
	# the same place twice is one lamp
	look.light_lamp(LAMPS[0])
	assert_int(look.lamp_count()).is_equal(LAMPS.size())


func test_instant_lamp_is_lit_at_once() -> void:
	var look := _make(false)
	await get_tree().process_frame
	look.light_lamp(LAMPS[0], true)
	assert_float(look.lamps()[0].level).is_equal(1.0)
	assert_float(look.mouth_light()).is_equal_approx(look.data.mouth_share, 1e-5)


func test_no_pure_black_colour_source() -> void:
	var look := _make(true)
	await get_tree().process_frame
	for p in LAMPS:
		look.light_lamp(p)
	_steps(look, 0.5)
	await get_tree().process_frame
	var bad: Array[String] = []
	for f in look.data.colour_fields():
		if U.is_black(look.data.get(f) as Color):
			bad.append("data.%s" % f)
	var nodes: Array[Node] = []
	U.walk(look, nodes)
	var lights := 0
	for n in nodes:
		if U.in_entity_group(n):
			continue
		if n is CanvasModulate and U.is_black((n as CanvasModulate).color):
			bad.append("%s ambient" % n.name)
		if n is Light2D:
			lights += 1
			if U.is_black((n as Light2D).color):
				bad.append("%s light colour" % n.name)
		if not (n is CanvasItem):
			continue
		var ci := n as CanvasItem
		if U.is_black(ci.modulate) or U.is_black(ci.self_modulate):
			bad.append("%s modulate" % n.name)
		if n is ColorRect and U.is_black((n as ColorRect).color):
			bad.append("%s color" % n.name)
		if ci.material is ShaderMaterial:
			var cols := U.colour_uniforms(ci.material as ShaderMaterial)
			for k: Variant in cols.keys():
				if U.is_black(cols[k] as Color):
					bad.append("%s.%s" % [n.name, k])
	for o: Object in [look.get_node("%Set"), look.get_node("%Foreground"), look.get_node("%Placeholders"), look.get_node("%Objects")]:
		for prop: Dictionary in o.get_property_list():
			if int(prop.get("type", 0)) == TYPE_COLOR and U.is_black(o.get(str(prop.name)) as Color):
				bad.append("%s.%s" % [(o as Node).name, prop.name])
	assert_int(lights).is_greater(LAMPS.size())
	assert_array(bad).override_failure_message("black outside the entity: %s" % [bad]).is_empty()


func test_hall_lantern_is_the_brightest_light_at_first_visit() -> void:
	var look := _make(true)
	await get_tree().process_frame
	_steps(look, look.data.entry_delay_s + look.data.entry_catch_s + 0.2)
	assert_float(look.hall_lantern.level).is_equal(1.0)
	_check_lantern_law(look, "first visit")
	# still the brightest with every lamp caught and the mouth fully lit
	for p in LAMPS:
		look.light_lamp(p)
	_steps(look, look.data.lamp_catch_s + 0.2)
	_check_lantern_law(look, "every lamp lit")
	# what shows through the openings: the Aether's emitters sit under GAS_3 luminance (law 4,
	# test_aether_lantern_key.gd) and the veil passes at most (1 − veil) of it
	var through := (1.0 - minf(look.data.hole_veil, look.data.mouth_veil_lit)) * Pal.GAS_3.get_luminance()
	assert_float(look.hall_lantern.core_luminance()).is_greater(through)


func _check_lantern_law(look: RuinsLook, when: String) -> void:
	var hall := look.hall_lantern
	var key := hall.light_energy() * hall.colour.get_luminance()
	var nodes: Array[Node] = []
	U.walk(look.get_node("%Hall"), nodes)
	for n in nodes:
		if n is Light2D and n.get_parent() != hall:
			var l := n as Light2D
			var e := (l.energy if l.enabled else 0.0) * l.color.get_luminance()
			assert_float(e).override_failure_message("%s: %s (%f) outshines the hall lantern (%f)" % [when, n.name, e, key]).is_less(key)
	for lamp in look.lamps():
		assert_float(lamp.core_luminance()).override_failure_message("%s: a Tree lamp's core outshines the lantern" % when).is_less(hall.core_luminance())
		assert_float(lamp.light_energy() * lamp.colour.get_luminance()).is_less(key)


func test_lamps_never_flash() -> void:
	var d := (load("res://data/aether/ruins/ruins_look.tres") as RuinsLookData)
	var bound := d.max_step_per_frame
	# the catch curve's steepest step at 60 Hz, for both catches, sits under the bound
	for s in [d.entry_catch_s, d.lamp_catch_s]:
		assert_float(1.5 / (60.0 * float(s))).is_less_equal(bound)
	assert_float(d.breath_hz).is_less(3.0)
	assert_float(d.breath_depth).is_less(0.1)
	var look := _make(true)
	await get_tree().process_frame
	var prev: Dictionary = {}
	var prev_mouth := 0.0
	var worst := 0.0
	for f in int(8.0 / DT):
		var t := f * DT
		for i in LAMPS.size():
			if look.lamp_count() == i and t >= 2.0 + 0.45 * i:
				look.light_lamp(LAMPS[i])
		look.step(DT)
		for lamp in _all_lamps(look):
			var o := lamp.output()
			var was: float = prev.get(lamp, 0.0)
			worst = maxf(worst, absf(o - was))
			if lamp.catching:
				assert_float(o).override_failure_message("%s dimmed during its catch" % lamp.name).is_greater_equal(was - 1e-6)
			prev[lamp] = o
		var m := look.mouth_light()
		worst = maxf(worst, absf(m - prev_mouth))
		prev_mouth = m
	assert_int(look.lamp_count()).is_equal(LAMPS.size())
	assert_float(worst).override_failure_message("per-frame step %f over the bound %f" % [worst, bound]).is_less_equal(bound)


func test_catch_curve_is_monotonic() -> void:
	var prev := -1.0
	for i in 101:
		var v := RuinsLamp.catch_curve(i / 100.0)
		assert_float(v).is_greater_equal(prev)
		prev = v
	assert_float(RuinsLamp.catch_curve(0.0)).is_equal(0.0)
	assert_float(RuinsLamp.catch_curve(1.0)).is_equal(1.0)


func _hall_veil(look: RuinsLook) -> float:
	var s := (look.get_node("%Surface") as ColorRect).material as ShaderMaterial
	return float(s.get_shader_parameter(&"mouth_veil"))


func test_pre_lamp_mouth_is_near_black() -> void:
	var look := _make(false)
	await get_tree().process_frame
	var d := look.data
	assert_float(d.mouth_aether_hint).is_equal(0.0)
	# darker than the old dim glimpse, and what the hall shader gets
	assert_float(d.mouth_veil_dark).is_greater(d.mouth_veil_glimpse)
	assert_float(look.mouth_veil()).is_greater_equal(d.mouth_veil_dark - 1e-6)
	assert_float(_hall_veil(look)).is_equal_approx(look.mouth_veil(), 1e-5)
	# the veil's own colour is never black: the mouth floors at the VOID ramp, not 0,0,0
	assert_bool(U.is_black(d.veil)).is_false()
	assert_float(d.veil.get_luminance()).is_greater_equal(Pal.VOID_0.get_luminance() - 1e-4)
	# lamps clear it monotonically; once the first lamp has caught it is the lit curve as before
	var prev := look.mouth_veil()
	for p in LAMPS:
		look.light_lamp(p)
		for _f in int(ceilf((d.lamp_catch_s + 0.3) / DT)):
			look.step(DT)
			var v := look.mouth_veil()
			assert_float(v).override_failure_message("mouth veil rose: %f → %f" % [prev, v]).is_less_equal(prev + 1e-6)
			assert_float(absf(v - prev)).override_failure_message("veil step %f" % absf(v - prev)).is_less_equal(d.max_step_per_frame)
			prev = v
		var m := look.mouth_light()
		assert_float(look.mouth_veil()).is_equal_approx(lerpf(d.mouth_veil_glimpse, d.mouth_veil_lit, m), 1e-5)


func test_mouth_aether_hint_raises_the_glimpse_monotonically() -> void:
	var d := (load("res://data/aether/ruins/ruins_look.tres") as RuinsLookData).duplicate() as RuinsLookData
	var look := _make(false, d)
	await get_tree().process_frame
	var prev := 2.0
	for i in 5:
		d.mouth_aether_hint = i / 4.0
		look.step(DT)
		var v := _hall_veil(look)
		assert_float(v).override_failure_message("hint %f did not lift the glimpse" % d.mouth_aether_hint).is_less(prev)
		prev = v
	# full hint = the dim glimpse, never more
	assert_float(prev).is_equal_approx(d.mouth_veil_glimpse, 1e-5)
	assert_float(look.mouth_light()).is_equal(0.0)


func _prop(colour: Color = Color.WHITE) -> Node2D:
	var n := Node2D.new()
	n.modulate = colour
	return n


func test_add_prop_parents_under_stage_at_pos() -> void:
	var look := _make(false)
	await get_tree().process_frame
	var a := _prop()
	var holder := Node.new()
	holder.add_child(a)   # M1's node may come from elsewhere: it is reparented
	look.add_prop(&"desk", a, Vector2(204, 288))
	assert_object(a.get_parent()).is_same(look.stage)
	assert_vector(a.position).is_equal(Vector2(204, 288))
	assert_bool(look.has_prop(&"desk")).is_true()
	assert_object(look.prop_node(&"desk")).is_same(a)
	assert_str(str(look.prop_state(&"desk"))).is_equal("idle")
	# the same node again only moves it
	look.add_prop(&"desk", a, Vector2(210, 288))
	assert_bool(is_instance_valid(a) and not a.is_queued_for_deletion()).is_true()
	assert_vector(a.position).is_equal(Vector2(210, 288))
	look.remove_prop(&"desk")
	assert_bool(look.has_prop(&"desk")).is_false()
	assert_str(str(look.prop_state(&"desk"))).is_equal("")
	holder.free()
	await get_tree().process_frame
	assert_bool(is_instance_valid(a)).is_false()


func test_props_added_before_ready_attach_on_ready() -> void:
	_look = (load(SCENE) as PackedScene).instantiate() as RuinsLook
	var a := _prop()
	_look.add_prop(&"hourglass", a, Vector2(438, 290))
	add_child(_look)
	_look.set_process(false)
	await get_tree().process_frame
	assert_object(a.get_parent()).is_same(_look.stage)
	assert_vector(a.position).is_equal(Vector2(438, 290))


func test_replacing_a_prop_frees_the_old() -> void:
	var look := _make(false)
	await get_tree().process_frame
	var a := _prop()
	var b := _prop()
	look.add_prop(&"codex", a, Vector2(300, 288))
	look.add_prop(&"codex", b, Vector2(302, 288))
	assert_bool(not is_instance_valid(a) or a.is_queued_for_deletion()).is_true()
	assert_object(look.prop_node(&"codex")).is_same(b)
	assert_object(b.get_parent()).is_same(look.stage)
	await get_tree().process_frame
	assert_bool(is_instance_valid(a)).is_false()
	var count := 0
	for c in look.stage.get_children():
		if c == b:
			count += 1
	assert_int(count).is_equal(1)


func test_prop_states_change_the_look_within_the_step_bound() -> void:
	var look := _make(false)
	await get_tree().process_frame
	var base := Pal.BONE_2
	var a := _prop(base)
	look.add_prop(&"desk", a, Vector2(204, 288))
	var bound := look.data.max_step_per_frame
	var idle_lum := a.modulate.get_luminance()
	var lums: Dictionary = {}
	for state: StringName in [&"focused", &"used", &"idle"]:
		look.set_prop_state(&"desk", state)
		assert_str(str(look.prop_state(&"desk"))).is_equal(str(state))
		var prev := a.modulate.get_luminance()
		for _f in 90:
			look.step(DT)
			var l := a.modulate.get_luminance()
			assert_float(absf(l - prev)).override_failure_message("%s: luminance step %f over %f" % [state, absf(l - prev), bound]).is_less_equal(bound + 1e-6)
			assert_bool(U.is_black(a.modulate)).is_false()
			prev = l
		lums[state] = a.modulate.get_luminance()
		assert_float(a.modulate.a).is_equal_approx(base.a, 1e-6)
	assert_float(float(lums[&"focused"])).is_greater(idle_lum + 0.01)
	assert_float(float(lums[&"used"])).is_less(idle_lum - 0.01)
	assert_float(float(lums[&"idle"])).is_equal_approx(idle_lum, 1e-4)
	# focused leans toward chalk (BONE-4), it does not just get brighter
	look.set_prop_state(&"desk", &"focused")
	_steps(look, 1.5)
	var want := look.prop_target_tint(&"focused")
	assert_float(a.modulate.r).is_equal_approx(base.r * want.r, 1e-4)
	assert_float(a.modulate.b).is_equal_approx(base.b * want.b, 1e-4)


func test_unknown_prop_state_is_ignored() -> void:
	var look := _make(false)
	await get_tree().process_frame
	var a := _prop()
	look.add_prop(&"desk", a, Vector2(204, 288))
	look.set_prop_state(&"desk", &"focused")
	look.set_prop_state(&"desk", &"glowing")
	assert_str(str(look.prop_state(&"desk"))).is_equal("focused")
	# an unknown id is ignored too (no prop is made)
	look.set_prop_state(&"nothing", &"used")
	assert_bool(look.has_prop(&"nothing")).is_false()


func test_set_first_visit() -> void:
	var look := _make(true)
	await get_tree().process_frame
	var d := look.data
	assert_float(look.hall_lantern.output()).is_equal(0.0)
	_steps(look, d.entry_delay_s * 0.5)
	assert_float(look.hall_lantern.output()).override_failure_message("lit before the delay").is_equal(0.0)
	_steps(look, d.entry_delay_s * 0.5 + d.entry_catch_s * 0.5)
	var mid := look.hall_lantern.output()
	assert_float(mid).is_greater(0.0)
	assert_float(mid).is_less(1.0)
	_steps(look, d.entry_catch_s * 0.5 + 0.1)
	assert_float(look.hall_lantern.level).is_equal(1.0)
	# a later visit: lit from the first frame
	look.set_first_visit(false)
	assert_bool(look.first_visit).is_false()
	assert_float(look.hall_lantern.level).is_equal(1.0)
	look.set_first_visit(true)
	assert_float(look.hall_lantern.output()).is_equal(0.0)
	look.free()
	var later := _make(false)
	await get_tree().process_frame
	assert_float(later.hall_lantern.level).is_equal(1.0)
	assert_float(later.mouth_light()).is_equal(0.0)


# --- Q-T193: the Ruins objects as lamp-lit vector art (ART-001 §16.6j) ---------------------------------

func test_objects_show_with_the_placeholders_and_take_the_markers() -> void:
	var look := _make(false)
	await get_tree().process_frame
	var o := look.objects()
	assert_bool(o.visible).is_false()
	look.show_placeholders = true
	assert_bool(o.visible).is_true()
	var rects := o.object_rects()
	var markers := {&"chalk_desk": look.chalk_desk_pos, &"cabinet": look.cabinet_pos,
		&"codex_desk": look.codex_desk_pos, &"hourglass": look.hourglass_pos}
	var frame := Rect2(Vector2.ZERO, Vector2(640, 360))
	for id: StringName in markers.keys():
		var r: Rect2 = rects[id]
		var m: Vector2 = markers[id]
		assert_bool(r.grow(0.5).has_point(m)).override_failure_message("%s not at its marker" % id).is_true()
		assert_bool(frame.encloses(r)).override_failure_message("%s leaves the frame" % id).is_true()
		# clear of the hangar mouth (the gate frames it; nothing stands in it)
		assert_bool(r.intersects(look.hangar_mouth_rect)).override_failure_message("%s in the mouth" % id).is_false()
	var ids: Array = rects.keys()
	for i in ids.size():
		for j in range(i + 1, ids.size()):
			assert_bool((rects[ids[i]] as Rect2).intersects(rects[ids[j]] as Rect2)).override_failure_message(
				"%s overlaps %s" % [ids[i], ids[j]]).is_false()


func test_objects_use_pal_roles_only_and_no_lantern_or_faction_hues() -> void:
	var look := _make(false)
	await get_tree().process_frame
	for c in look.objects().colours_used():
		assert_bool(U.is_black(c)).is_false()
		var name := U.pal_name(c)
		assert_str(name).override_failure_message("%s is not a Pal entry" % c).is_not_empty()
		for bad in ["SIGNAL", "NULL", "GAS-", "CHOIR-"]:
			assert_bool(name.begins_with(bad)).override_failure_message(name).is_false()


func test_set_sand_drives_the_hourglass() -> void:
	var look := _make(false)
	await get_tree().process_frame
	look.set_sand(0.25, true)
	assert_float(look.objects().sand).is_equal(0.25)
	assert_bool(look.objects().sand_falling).is_true()
	look.set_sand(2.0, false)
	assert_float(look.objects().sand).is_equal(1.0)
	assert_bool(look.objects().sand_falling).is_false()


func test_objects_hold_still_under_reduced_motion() -> void:
	var o := RuinsObjects.new()
	o.still = true
	o.set_time(12.0)
	assert_float(o._t).is_equal(0.0)
	o.still = false
	o.set_time(12.0)
	assert_float(o._t).is_equal(12.0)
	o.free()


# --- Q-T248 (Ruins) perf: static vector art is drawn once; only what moves redraws ---------------------

func test_static_art_does_not_redraw_as_time_passes() -> void:
	var look := _make(false)
	look.show_placeholders = true
	await get_tree().process_frame
	await get_tree().process_frame
	var o := look.objects()
	var s := look.get_node("%Set") as RuinsSet
	var counts := {"objects": 0, "set": 0, "live": 0, "planet": 0}
	o.draw.connect(func() -> void: counts["objects"] += 1)
	s.draw.connect(func() -> void: counts["set"] += 1)
	o.get_node("Live").draw.connect(func() -> void: counts["live"] += 1)
	s.get_node("OrreryPlanet").draw.connect(func() -> void: counts["planet"] += 1)
	o.still = false
	look.set_sand(0.5, true)
	for k in 6:
		look.step(DT * 10.0)
		await get_tree().process_frame
	assert_int(int(counts["objects"])).override_failure_message("objects redrew %s" % counts).is_equal(0)
	assert_int(int(counts["set"])).override_failure_message("set redrew %s" % counts).is_equal(0)
	assert_int(int(counts["live"])).is_greater_equal(5)
	assert_int(int(counts["planet"])).is_greater_equal(5)
	# a sand value that does not change does not redraw the Hourglass again
	var before := int(counts["live"])
	o.still = true
	look.set_sand(0.5, true)
	await get_tree().process_frame
	assert_int(int(counts["live"])).is_equal(before)
