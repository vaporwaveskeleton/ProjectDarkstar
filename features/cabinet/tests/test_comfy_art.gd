extends GdUnitTestSuite
## ComfyArt (ART-001 §14.9): the generated tape and arcade backdrop are wired behind data switches, default on,
## and the code-drawn versions stay reachable.

func test_tape_strip_uses_the_generated_tape_by_default() -> void:
	var t := auto_free(TapeStrip.new()) as TapeStrip
	add_child(t)
	var m := t.material as ShaderMaterial
	assert_float(float(m.get_shader_parameter(&"use_tex"))).is_equal(1.0)
	assert_object(m.get_shader_parameter(&"tape_tex")).is_not_null()
	t.place(Vector2(0, 30), Vector2(60, 10), 5.5, true, 0.0)   # places without error
	assert_bool(t.visible).is_true()


func test_backdrop_uses_the_photo_and_keeps_the_decay_uniform() -> void:
	var b := auto_free(ArcadeBackdrop.new()) as ArcadeBackdrop
	add_child(b)
	var m := b.material as ShaderMaterial
	assert_float(float(m.get_shader_parameter(&"photo_on"))).is_equal(1.0)
	assert_object(m.get_shader_parameter(&"photo")).is_not_null()
	assert_float(float(m.get_shader_parameter(&"photo_aspect"))).is_between(1.7, 1.8)
	# the cursed turn still reaches it: CabinetDecay sets `dark` on this material
	m.set_shader_parameter(&"dark", 1.0)
	assert_float(float(m.get_shader_parameter(&"dark"))).is_equal(1.0)


func test_the_switches_are_data_and_default_on() -> void:
	var a := ComfyArt.default() as ComfyArt
	assert_str(a.ds_namespace).is_equal("ds_cabinet.comfy_art")
	assert_bool(a.tape_enabled and a.backdrop_enabled).is_true()
	assert_object(ComfyArt.texture("not_there.png")).is_null()   # a missing file falls back to the code art
