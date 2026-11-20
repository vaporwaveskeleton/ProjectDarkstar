extends GdUnitTestSuite
## M2 slice, Aether art PR B: the first Unmaking cinematic (route &"aether", beats 4–6).
## The beat timeline fits the 90 s budget from the tear; route params are forwarded to the Ruins
## unchanged (own keys stripped, first_visit added, nothing invented); go_to(&"ruins") happens exactly
## once, at the end; skip only when can_skip; the only black is the entity's; the timeline's
## luminance changes are slow and monotonic (WARP-001 §4.5); the tilt is look-only, beat 4 only.

const U := preload("res://features/aether/tests/aether_test_util.gd")
const ARRIVAL := "res://features/aether/aether_arrival.tscn"
const ARRIVAL_GD := preload("res://features/aether/aether_arrival.gd")
const SHIPPED := "res://data/routes/route_table.tres"
const TL := preload("res://features/aether/unmaking_timeline.gd")
## ✱ photosensitivity bounds per 60 Hz frame: the lamp's / ember's light (fraction of full), the
## world's cold cast (drain), the front's travel (logical px), and the share of the 640×360 frame the
## front newly covers (no full-field luminance step, WARP-001 §4.5).
const FRAME_S := 1.0 / 60.0
const MAX_LIGHT_STEP := 0.02
const MAX_DRAIN_STEP := 0.002
const MAX_FRONT_PX := 2.5
const MAX_AREA_STEP := 0.005
const FRAME := Vector2(640.0, 360.0)
## ✱ conservative fraction of the front's radius that is solid black in every direction (its warp,
## ridges, bites and notch stay outside it; a_entity_shape_b in aether_common.gdshaderinc), the
## nominal edge, and the outline's vertical squash.
const SOLID := 0.7
const EDGE := 0.95
const SQUASH := 1.12


class StubRouter:
	extends RefCounted
	var calls: Array = []

	func go_to(route_id: StringName, params: Dictionary = {}) -> bool:
		calls.append([route_id, params])
		return true


var _prev_persist: bool
var _prev_reduced: bool
var _prev_photo: bool


func before_test() -> void:
	_prev_persist = SettingsService.persist
	SettingsService.persist = false
	_prev_reduced = bool(SettingsService.get_value(&"reduced_motion"))
	_prev_photo = bool(SettingsService.get_value(&"photosensitivity"))
	SettingsService.set_value(&"reduced_motion", false)
	SettingsService.set_value(&"photosensitivity", false)


func after_test() -> void:
	Input.action_release(&"ui_cancel")
	Input.action_release(&"ui_accept")
	SettingsService.set_value(&"reduced_motion", _prev_reduced)
	SettingsService.set_value(&"photosensitivity", _prev_photo)
	SettingsService.persist = _prev_persist
	if AudioService.has_method("set_subtraction"):
		AudioService.set_subtraction(0.0)
	if AudioService.has_method("set_ambience"):
		AudioService.set_ambience(&"")


func _make() -> Node:
	var a: Node = (load(ARRIVAL) as PackedScene).instantiate()
	add_child(a)
	a.set_process(false)
	return auto_free(a)


func _stub(a: Node) -> StubRouter:
	var r := StubRouter.new()
	a.set("router", r)
	return r


func _run_to(a: Node, t: float, step: float = 0.25) -> void:
	while float(a.get("cine_s")) < t - 0.0001 and not bool(a.get("routed")):
		a.call("advance", minf(step, t - float(a.get("cine_s"))))


# --- the budget ---------------------------------------------------------------------------------------

func test_beats_fit_the_90_s_budget_from_the_tear() -> void:
	assert_float(TL.BEAT4_S).is_equal(20.0)
	assert_float(TL.BEAT5_S).is_equal(40.0)
	assert_float(TL.BLACK_S).is_equal(10.0)
	assert_float(TL.HANDOFF_AT_S + TL.BEAT4_S + TL.BEAT5_S + TL.BEAT6_S).is_equal_approx(TL.TEAR_AT_S + TL.CINEMATIC_S, 0.001)
	assert_float(TL.ends_at_wall_s()).is_equal_approx(94.0, 0.001)
	assert_float(TL.END_S).is_equal_approx(TL.total_s(), 0.001)
	# the marks are ordered: flee, front, lamp reached, lamp out, black, end
	var marks: Array[float] = [0.0, TL.FLEE_AT, TL.FRONT_AT, TL.BEAT6_AT, TL.LAMP_REACH_AT, TL.LAMP_OUT_AT, TL.BLACK_AT, TL.END_S]
	for i in range(1, marks.size()):
		assert_float(marks[i]).is_greater_equal(marks[i - 1])
	assert_float(TL.BLACK_AT - TL.LAMP_OUT_AT).is_equal(TL.LAMP_OUT_S)
	assert_float(TL.END_S - TL.BLACK_AT).is_equal(TL.BLACK_S)
	assert_int(TL.beat_at(0.0)).is_equal(4)
	assert_int(TL.beat_at(TL.BEAT5_AT + 0.1)).is_equal(5)
	assert_int(TL.beat_at(TL.BEAT6_AT + 0.1)).is_equal(6)
	# the front only starts once the Presence has had FLEE_S to leave
	assert_float(TL.FRONT_AT - TL.FLEE_AT).is_greater_equal(FrostPresence.FLEE_S)


# --- params forwarding --------------------------------------------------------------------------------

func test_params_are_forwarded_unchanged_with_first_visit() -> void:
	var out: Dictionary = ARRIVAL_GD.ruins_params({"shift_total": 48210, "act0_vigil_index": 2, "mystery": "kept",
		&"other_key": Vector2(1, 2), "skip_curtain": true, "aether_time_s": 3.0, "tier": 2,
		"camera_centre": Vector2(300, 170), "camera_zoom": 1.25, "can_skip": true})
	assert_int(typeof(out["shift_total"])).is_equal(TYPE_INT)
	assert_int(int(out["shift_total"])).is_equal(48210)
	assert_int(typeof(out["act0_vigil_index"])).is_equal(TYPE_INT)
	assert_int(int(out["act0_vigil_index"])).is_equal(2)
	assert_str(str(out["mystery"])).is_equal("kept")
	assert_bool(out.has(&"other_key")).is_true()
	assert_vector(out[&"other_key"] as Vector2).is_equal(Vector2(1, 2))
	for k in ARRIVAL_GD.OWN_KEYS:
		assert_bool(out.has(k)).override_failure_message("own key %s forwarded" % k).is_false()
		assert_bool(out.has(StringName(k))).override_failure_message("own key &%s forwarded" % k).is_false()
	assert_bool(out["first_visit"]).is_true()
	assert_int(out.size()).is_equal(5)


func test_nothing_is_invented_when_absent() -> void:
	var out: Dictionary = ARRIVAL_GD.ruins_params({})
	assert_dict(out).is_equal({"first_visit": true})
	out = ARRIVAL_GD.ruins_params({&"skip_curtain": true, &"aether_time_s": 1.0, &"can_skip": true, "first_visit": false})
	assert_dict(out).is_equal({"first_visit": true})
	# own keys given as StringName are stripped too
	var d := {}
	d[&"tier"] = 4
	d[&"camera_zoom"] = 2.0
	d[&"act0_vigil_index"] = 1
	out = ARRIVAL_GD.ruins_params(d)
	assert_int(out.size()).is_equal(2)
	assert_int(int(out[&"act0_vigil_index"])).is_equal(1)
	assert_bool(out["first_visit"]).is_true()


# --- the route out ------------------------------------------------------------------------------------

func test_go_to_ruins_exactly_once_at_the_end() -> void:
	var shipped := ResourceLoader.load(SHIPPED, "", ResourceLoader.CACHE_MODE_IGNORE) as RouteTable
	assert_bool(shipped.has_route(&"ruins")).is_true()
	var a := _make()
	var r := _stub(a)
	a.call("on_route_entered", {"skip_curtain": true, "act0_vigil_index": 3, "shift_total": 777, "aether_time_s": 2.0})
	_run_to(a, TL.END_S - 0.5)
	assert_int(r.calls.size()).is_equal(0)
	var b := a.get_node("%Backdrop") as AetherBackdrop
	assert_bool(b.presence_flee_progress() > 0.0 or (b.find_child("FrostPresence", true, false) as FrostPresence).fleeing).is_true()
	assert_bool(b.is_erasing()).is_true()
	_run_to(a, TL.END_S + 3.0)
	assert_bool(bool(a.get("routed"))).is_true()
	assert_int(r.calls.size()).is_equal(1)
	assert_str(String(r.calls[0][0])).is_equal("ruins")
	assert_dict(r.calls[0][1] as Dictionary).is_equal({"act0_vigil_index": 3, "shift_total": 777, "first_visit": true})
	# nothing more once routed
	a.call("advance", 5.0)
	assert_int(r.calls.size()).is_equal(1)


func test_skip_only_when_can_skip() -> void:
	var a := _make()
	var r := _stub(a)
	a.call("on_route_entered", {})
	assert_bool(bool(a.get("can_skip"))).is_false()
	Input.action_press(&"ui_cancel")
	for i in 8:
		a.call("advance", 0.25)
	assert_int(r.calls.size()).is_equal(0)
	Input.action_release(&"ui_cancel")
	a.call("on_route_entered", {"can_skip": true, "act0_vigil_index": 1})
	a.call("advance", 0.25)
	assert_int(r.calls.size()).is_equal(0)
	Input.action_press(&"ui_accept")
	a.call("advance", ARRIVAL_GD.SKIP_HOLD_S * 0.5)
	assert_int(r.calls.size()).is_equal(0)
	a.call("advance", ARRIVAL_GD.SKIP_HOLD_S * 0.6)
	assert_int(r.calls.size()).is_equal(1)
	assert_dict(r.calls[0][1] as Dictionary).is_equal({"act0_vigil_index": 1, "first_visit": true})
	a.call("advance", 1.0)
	assert_int(r.calls.size()).is_equal(1)
	# a mistyped can_skip counts as false
	a.call("on_route_entered", {"can_skip": "yes"})
	assert_bool(bool(a.get("can_skip"))).is_false()


# --- black roles --------------------------------------------------------------------------------------

func test_only_black_is_the_entity_during_the_erasure() -> void:
	var a := _make()
	_stub(a)
	a.call("on_route_entered", {})
	for t: float in [TL.FRONT_AT + 12.0, TL.LAMP_REACH_AT, TL.BLACK_AT + 4.0]:
		_run_to(a, t)
		await get_tree().process_frame
		var nodes: Array[Node] = []
		U.walk(a, nodes)
		var bad: Array[String] = []
		for n in nodes:
			if not (n is CanvasItem):
				continue
			var ci := n as CanvasItem
			if (U.is_black(ci.modulate) or U.is_black(ci.self_modulate)) and not U.in_entity_group(n):
				bad.append("%s modulate" % n.name)
			if n is ColorRect and U.is_black((n as ColorRect).color) and not U.in_entity_group(n):
				bad.append("%s color" % n.name)
			if ci.material is ShaderMaterial:
				var cols := U.colour_uniforms(ci.material as ShaderMaterial)
				for k: Variant in cols.keys():
					if U.is_black(cols[k] as Color) and not U.in_entity_group(n):
						bad.append("%s.%s" % [n.name, k])
		assert_array(bad).override_failure_message("t=%.1f black outside entity_presence: %s" % [t, bad]).is_empty()
		var b := a.get_node("%Backdrop") as AetherBackdrop
		assert_bool(b.active_layers().has("entity")).is_true()
		assert_float(b.entity_mask().z).is_equal_approx(TL.front_radius(float(a.get("cine_s"))), 0.01)
	# the lamp draws nothing black: its colours are its brass, GAS glass, VOID hull hint and PHOS ember
	var lamp := a.get_node("%Lantern") as LastLamp
	for c: Color in [lamp.brass, Pal.GAS_2, Pal.GAS_4, Pal.GAS_5, Pal.VOID_4, Pal.VOID_5, Pal.PHOS_2, Pal.PHOS_4]:
		assert_bool(U.is_black(c)).is_false()


# --- photosensitivity ---------------------------------------------------------------------------------

func test_timeline_luminance_changes_are_slow_and_monotonic() -> void:
	var prev_light := TL.lamp_light(0.0)
	var prev_ember := TL.ember(0.0)
	var prev_drain := TL.drain(0.0)
	var prev_r := TL.front_radius(0.0)
	var ember_peaked := false
	var t := FRAME_S
	while t <= TL.END_S + FRAME_S:
		var light := TL.lamp_light(t)
		var ember := TL.ember(t)
		var dr := TL.drain(t)
		var r := TL.front_radius(t)
		assert_float(absf(light - prev_light)).override_failure_message("lamp step at %.2f" % t).is_less_equal(MAX_LIGHT_STEP)
		assert_float(absf(ember - prev_ember)).override_failure_message("ember step at %.2f" % t).is_less_equal(MAX_LIGHT_STEP)
		assert_float(absf(dr - prev_drain)).override_failure_message("drain step at %.2f" % t).is_less_equal(MAX_DRAIN_STEP)
		assert_float(r - prev_r).override_failure_message("front jump at %.2f" % t).is_less_equal(MAX_FRONT_PX)
		# monotonic: no flicker cycle anywhere (the ember rises once, then only fades)
		assert_float(light).is_less_equal(prev_light + 1e-6)
		assert_float(dr).is_greater_equal(prev_drain - 1e-6)
		assert_float(r).is_greater_equal(prev_r - 1e-6)
		if ember < prev_ember - 1e-6:
			ember_peaked = true
		elif ember_peaked:
			assert_float(ember).override_failure_message("ember rises again at %.2f" % t).is_less_equal(prev_ember + 1e-6)
		prev_light = light
		prev_ember = ember
		prev_drain = dr
		prev_r = r
		t += FRAME_S
	assert_float(TL.ember(TL.END_S)).is_equal_approx(0.0, 0.0001)
	assert_float(TL.lamp_light(TL.BLACK_AT)).is_equal_approx(0.0, 0.0001)


func test_no_full_field_step_the_front_covers_the_frame_gradually() -> void:
	# the share of the frame inside the front's nominal edge, sampled every 0.25 s on a 64×36 grid
	var prev := 0.0
	var t := 0.0
	var dt := 0.25
	while t <= TL.END_S:
		var cover := _covered(TL.front_radius(t) * EDGE)
		var per_frame := (cover - prev) / (dt / FRAME_S)
		assert_float(per_frame).override_failure_message("t=%.2f covers %.4f of the frame per frame" % [t, per_frame]).is_less_equal(MAX_AREA_STEP)
		assert_float(cover).is_greater_equal(prev - 1e-6)
		prev = cover
		t += dt
	# the whole frame is solid black by the time the lamp is out (filled from the inside)
	assert_float(_covered(TL.front_radius(TL.BLACK_AT) * SOLID)).is_equal(1.0)
	# and the front starts inside the picture, off-centre, never at an edge (N8)
	var o := TL.FRONT_ORIGIN
	assert_bool(Rect2(Vector2.ZERO, FRAME).grow(-40.0).has_point(o)).is_true()
	assert_float(o.distance_to(FRAME * 0.5)).is_greater(80.0)


func test_the_lamp_is_the_last_light() -> void:
	var lamp := FRAME * 0.5 + TL.lamp_drift(TL.LAMP_REACH_AT)
	var d := _norm(lamp - TL.FRONT_ORIGIN)
	# reached at LAMP_REACH_AT, not much before
	assert_float(d).is_less(TL.front_radius(TL.LAMP_REACH_AT) * EDGE)
	assert_float(d).is_greater(TL.front_radius(TL.LAMP_REACH_AT - 4.0) * EDGE)
	# by then most of the frame is gone; the lamp is still lit until LAMP_OUT_AT
	assert_float(_covered(TL.front_radius(TL.LAMP_REACH_AT) * EDGE)).is_greater(0.6)
	assert_float(TL.lamp_light(TL.LAMP_REACH_AT)).is_equal(1.0)
	assert_float(TL.hull_alpha(TL.LAMP_REACH_AT)).is_equal(0.0)


# --- look-only tilt -----------------------------------------------------------------------------------

func test_tilt_is_look_only_and_beat_4_only() -> void:
	var a := _make()
	_stub(a)
	a.call("on_route_entered", {})
	var cam := a.get_node("%Camera") as Camera2D
	var b := a.get_node("%Backdrop") as AetherBackdrop
	var ev := InputEventMouseMotion.new()
	ev.position = a.get_viewport().get_visible_rect().size
	a.call("_unhandled_input", ev)
	_run_to(a, 4.0, FRAME_S * 4.0)
	var tilt := a.get("tilt") as Vector2
	assert_float(tilt.length()).is_greater(1.0)
	assert_float(tilt.length()).is_less_equal(ARRIVAL_GD.TILT_PX * 1.5)
	assert_vector(cam.position).is_equal_approx(Vector2(320, 180) + tilt, Vector2(0.01, 0.01))
	assert_vector(b.camera_centre).is_equal_approx(cam.position, Vector2(0.01, 0.01))
	# gone by beat 5: nothing it moved stays moved
	_run_to(a, TL.BEAT5_AT + 1.0, FRAME_S * 4.0)
	assert_vector(a.get("tilt") as Vector2).is_equal(Vector2.ZERO)
	assert_vector(cam.position).is_equal(Vector2(320, 180))
	# reduced motion: no tilt at all
	SettingsService.set_value(&"reduced_motion", true)
	var c := _make()
	_stub(c)
	c.call("on_route_entered", {})
	c.call("_unhandled_input", ev)
	_run_to(c, 4.0, FRAME_S * 4.0)
	assert_vector(c.get("tilt") as Vector2).is_equal(Vector2.ZERO)


func test_first_frame_is_pushed_in_the_entering_call() -> void:
	var a := _make()
	_stub(a)
	a.call("on_route_entered", {"aether_time_s": 3.0, "camera_centre": Vector2(300, 170)})
	var b := a.get_node("%Backdrop") as AetherBackdrop
	var lamp := a.get_node("%Lantern") as LastLamp
	assert_vector(lamp.position).is_equal(Vector2(300, 170))
	assert_float(lamp.light_amount).is_equal(1.0)
	assert_float(lamp.ember_alpha).is_equal(0.0)
	assert_bool(b.is_erasing()).is_false()
	assert_vector(b.lantern_screen).is_equal_approx(b.get_viewport_rect().size * 0.5, Vector2(0.01, 0.01))
	assert_float(float(a.get("cine_s"))).is_equal(0.0)


static func _norm(rel: Vector2) -> float:
	return Vector2(rel.x, rel.y * SQUASH).length()


static func _covered(r: float) -> float:
	if r <= 0.0:
		return 0.0
	var inside := 0
	var n := 0
	for gy in 36:
		for gx in 64:
			var p := Vector2((gx + 0.5) * FRAME.x / 64.0, (gy + 0.5) * FRAME.y / 36.0)
			n += 1
			if _norm(p - TL.FRONT_ORIGIN) < r:
				inside += 1
	return float(inside) / float(n)


## The hand-off veil (cursed-cabinet, TECH-001 Q-T267): the scene opens behind a VOID-dark veil that clears
## over ENTRY_VEIL_S, smoothly, so the cut from the reveal is never one whole-field luma step ≥ 0.10.
func test_the_entry_veil_clears_smoothly_over_the_first_frames() -> void:
	var scene := (load("res://features/aether/aether_arrival.tscn") as PackedScene).instantiate()
	add_child(scene)
	scene.set_process(false)
	assert_float(scene.entry_veil()).is_equal(1.0)
	var prev: float = scene.entry_veil()
	var steps := 0
	while scene.entry_veil() > 0.0 and steps < 120:
		scene.advance(1.0 / 60.0)
		var a: float = scene.entry_veil()
		assert_float(prev - a).is_less(0.1)          # never a big step, even at the smoothstep's steepest
		assert_float(a).is_less_equal(prev)          # one way only
		prev = a
		steps += 1
	assert_int(steps).is_between(15, 20)             # ≈ 0.3 s at 60 Hz
	scene.free()
