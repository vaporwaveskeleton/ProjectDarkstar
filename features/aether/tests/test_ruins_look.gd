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


func _make(first_visit: bool) -> RuinsLook:
	_look = (load(SCENE) as PackedScene).instantiate() as RuinsLook
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
	for o: Object in [look.get_node("%Set"), look.get_node("%Foreground"), look.get_node("%Placeholders")]:
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
