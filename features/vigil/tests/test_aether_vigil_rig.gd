extends GdUnitTestSuite
## AetherVigilRig: modules, braking shutters, Lantern Down, gimbal inertia, palette laws, breach.

const LOOK_PATH := "res://data/vigil/aether_vigil_look.tres"


func _rig() -> AetherVigilRig:
	var r := auto_free(AetherVigilRig.new()) as AetherVigilRig
	add_child(r)
	return r


func _run(r: AetherVigilRig, seconds: float) -> void:
	for i in int(seconds * 60.0):
		r.step(1.0 / 60.0)


func _pose(r: AetherVigilRig, accel: Vector2 = Vector2.ZERO, braking: bool = false, up: bool = true) -> void:
	r.set_pose(0.0, 0.0, Vector2.ZERO, accel, 0.0, braking, up, false)


func test_modules_enable_parts() -> void:
	var r := _rig()
	assert_bool(r.has_part(&"keelSpine")).is_true()
	assert_bool(r.has_part(&"vaneA")).is_false()
	r.set_modules(PackedStringArray(["HULL-1", "LANTERN-10", "ORDNANCE-1", "BOGUS-9"]))
	assert_bool(r.has_part(&"vaneA")).is_true()
	assert_bool(r.has_part(&"keelLamp")).is_true()
	assert_bool(r.has_part(&"hookReel")).is_true()
	assert_bool(r.has_part(&"vaneB")).is_false()
	r.set_modules(PackedStringArray())
	assert_bool(r.has_part(&"vaneA")).is_false()
	assert_bool(r.has_part(&"lampGimbal")).is_true()


func test_braking_opens_shutters() -> void:
	var r := _rig()
	r.set_modules(PackedStringArray(["HULL-3"]))
	_pose(r)
	_run(r, 0.5)
	assert_float(r.shutter_openness()).is_equal(0.0)
	_pose(r, Vector2.ZERO, true)
	_run(r, 0.5)
	assert_float(r.shutter_openness()).is_equal(1.0)
	_pose(r)
	_run(r, 0.5)
	assert_float(r.shutter_openness()).is_equal(0.0)


func test_lantern_down_dims_globe() -> void:
	var r := _rig()
	_pose(r)
	_run(r, 1.0)
	var lit: float = r.lamp_intensity()
	_pose(r, Vector2.ZERO, false, false)
	_run(r, 1.0)
	assert_float(r.lamp_intensity()).is_less(lit * 0.5)
	assert_float(r.lamp_intensity()).is_greater(0.0)


func test_gimbal_swings_against_accel_and_settles() -> void:
	var r := _rig()
	_pose(r, Vector2(400.0, 0.0))
	_run(r, 0.3)
	assert_float(r.gimbal_offset().x).is_less(-0.5)
	_pose(r)
	_run(r, 3.0)
	assert_float(r.gimbal_offset().length()).is_less(0.05)


func test_no_choir_or_signal_colours() -> void:
	var look := load(LOOK_PATH) as AetherVigilLook
	assert_object(look).is_not_null()
	var banned: Array[Color] = [Pal.SIGNAL]
	for k in ["CHOIR-0", "CHOIR-1", "CHOIR-2", "CHOIR-3", "CHOIR-4", "CHOIR-5"]:
		banned.append(Pal.ALL[k] as Color)
	var cols := look.all_colors()
	assert_int(cols.size()).is_greater(15)
	for c in cols:
		for b in banned:
			assert_bool(c.is_equal_approx(b)).is_false()
	assert_int(_rig().palette_colors().size()).is_equal(cols.size())


func test_look_keys_resolve() -> void:
	var look := load(LOOK_PATH) as AetherVigilLook
	assert_str(look.ds_namespace).is_equal("ds_vigil.aether_look")
	assert_bool(look.ds_keys().has("ds_vigil.aether_look.gimbal_stiffness")).is_true()


func test_breach_ends_dark_and_shears_plate() -> void:
	var r := _rig()
	r.set_modules(PackedStringArray(["HULL-4"]))
	_pose(r)
	_run(r, 0.2)
	assert_bool(r.plate_sheared()).is_false()
	r.play_breach()
	assert_bool(r.plate_sheared()).is_true()
	_run(r, 0.3)
	assert_bool(r.is_dark()).is_false()
	_run(r, 2.0)
	assert_float(r.lamp_intensity()).is_equal(0.0)
	assert_bool(r.is_dark()).is_true()


func test_draws_without_error() -> void:
	var r := _rig()
	r.set_modules(PackedStringArray(["HULL-1", "HULL-7", "HULL-4", "HULL-3", "HULL-5", "HULL-15", "HULL-9",
			"ORDNANCE-1", "LANTERN-1", "LANTERN-6", "LANTERN-9", "LANTERN-10", "LANTERN-13", "LANTERN-16",
			"LANTERN-3", "LANTERN-5"]))
	r.set_pose(0.7, 1.2, Vector2(200, 50), Vector2(100, 30), 0.8, true, true, true)
	_run(r, 0.5)
	await get_tree().process_frame
	await get_tree().process_frame
	r.play_breach()
	await get_tree().process_frame
	assert_bool(is_instance_valid(r)).is_true()


## Owner direction 2026-11-19 (ART-001 §14.8a, §15.1a): the hull plates wear loom hammered brass (CanvasTexture with
## a normal map) on their own layer with vigil_plating.gdshader, lit by the lamp (which goes out with the lantern)
## and a sky key rotated into the hull frame, so the highlights move as the skiff turns. No extra Light2D.
func test_brass_plating_is_textured_lamp_lit_and_turns_with_the_hull() -> void:
	var r := _rig()
	var tex := r.brass_texture()
	assert_object(tex.diffuse_texture).is_not_null()
	assert_object(tex.normal_texture).is_not_null()
	assert_int(tex.texture_repeat).is_equal(CanvasItem.TEXTURE_REPEAT_ENABLED)
	var plating := r.get_node("Plating") as CanvasItem
	assert_object(plating.material).is_same(r.plating_material())
	for n in ["Under", "Plating", "HullDetail"]:
		assert_bool((r.get_node(n) as CanvasItem).show_behind_parent).is_true()
	assert_int(r.find_children("*", "Light2D", true, false).size()).is_equal(0)
	var mat := r.plating_material()
	_pose(r)
	_run(r, 1.0)
	var lit: float = mat.get_shader_parameter(&"lamp_energy")
	assert_float(lit).is_greater(0.5)
	var sky0: Vector2 = mat.get_shader_parameter(&"sky_hull")
	r.set_pose(PI * 0.5, 0.0, Vector2.ZERO, Vector2.ZERO, 0.0, false, true, false)
	r.step(1.0 / 60.0)
	var sky1: Vector2 = mat.get_shader_parameter(&"sky_hull")
	assert_float(sky0.angle_to(sky1)).is_equal_approx(-PI * 0.5, 0.01)
	_pose(r, Vector2.ZERO, false, false)
	_run(r, 2.0)
	assert_float(mat.get_shader_parameter(&"lamp_energy") as float).is_less(lit * 0.5)
