extends GdUnitTestSuite
## Williams video limits on the Act 0 screen: 16 RGB332 registers, Pal -> register map, the CPU mirror
## of the shader's register search, register writes, colour cycling on video frames, and the Look.t fade.

const PATH := "res://data/cabinet/screen_registers.tres"


func _spec() -> ScreenRegisters:
	return load(PATH) as ScreenRegisters


func _registers() -> VideoRegisters:
	var vr := VideoRegisters.new()
	vr.spec = _spec()
	add_child(vr)
	return vr


func test_sixteen_registers_all_rgb332_exact() -> void:
	var s := _spec()
	assert_str(s.ds_namespace).is_equal("ds_cabinet.registers")
	assert_int(s.defaults.size()).is_equal(16)
	for c in s.defaults:
		assert_bool(ScreenRegisters.to_rgb332(c).is_equal_approx(c)).override_failure_message("not RGB332: %s" % c).is_true()
	assert_float(s.video_frame_s).is_equal(0.01664)


func test_to_rgb332_snaps() -> void:
	assert_bool(ScreenRegisters.to_rgb332(Color8(0xFF, 0x1F, 0x3D)).is_equal_approx(Color8(0xFF, 0x24, 0x55))).is_true()
	assert_bool(ScreenRegisters.to_rgb332(Color8(0x26, 0x33, 0xD9)).is_equal_approx(Color8(0x24, 0x24, 0xFF))).is_true()
	assert_bool(ScreenRegisters.to_rgb332(Color8(0x5B, 0x6C, 0xFF)).is_equal_approx(Color8(0x49, 0x6D, 0xFF))).is_true()


func test_every_pal_name_has_a_register() -> void:
	var s := _spec()
	for name: String in Look.NEON:
		assert_bool(s.pal_map.has(name)).override_failure_message("no register for %s" % name).is_true()
		var r: int = s.pal_map[name]
		assert_bool(r >= 0 and r < 16).is_true()
	assert_int(s.pal_map.size()).is_equal(Look.NEON.size())


func test_every_neon_colour_resolves_to_its_register() -> void:
	var s := _spec()
	var m := VideoRegisters.match_set(s)
	assert_int((m["rgb"] as PackedVector3Array).size()).is_equal(VideoRegisters.MATCH_MAX)
	for name: String in Look.NEON:
		var got := VideoRegisters.nearest_register(Look.NEON[name], m["rgb"], m["reg"])
		assert_int(got).override_failure_message("%s -> %d" % [name, got]).is_equal(int(s.pal_map[name]))
	for i in 16:
		assert_int(VideoRegisters.nearest_register(s.defaults[i], m["rgb"], m["reg"])).is_equal(i)


func test_write_snaps_and_reads_back() -> void:
	var vr := _registers()
	vr.write(13, Color8(0xFF, 0x0F, 0x1D))
	assert_bool(vr.read(13).is_equal_approx(Color8(0xFF, 0x00, 0x00))).is_true()
	vr.reset()
	assert_bool(vr.read(13).is_equal_approx(Color8(0xFF, 0x92, 0x00))).is_true()
	vr.free()


func test_cycle_steps_once_per_frames_per_step() -> void:
	var vr := _registers()
	var cols := PackedColorArray([Color8(0xFF, 0x00, 0x00), Color8(0xFF, 0xFF, 0x00), Color8(0xFF, 0xFF, 0xFF)])
	var fs := _spec().video_frame_s
	vr.cycle(15, cols, 3)
	assert_bool(vr.read(15).is_equal_approx(cols[0])).is_true()
	vr.advance(fs)
	vr.advance(fs)
	assert_bool(vr.read(15).is_equal_approx(cols[0])).is_true()
	vr.advance(fs)
	assert_int(vr.frame).is_equal(3)
	assert_bool(vr.read(15).is_equal_approx(cols[1])).is_true()
	for i in 6:
		vr.advance(fs)
	assert_bool(vr.read(15).is_equal_approx(cols[0])).is_true()   # wrapped after 3 steps
	vr.stop_cycle(15)
	assert_bool(vr.is_cycling(15)).is_false()
	assert_bool(vr.read(15).is_equal_approx(Color8(0xFF, 0x00, 0x00))).is_true()
	vr.free()


func test_limits_fade_out_with_look_t() -> void:
	var old := Look.t
	var vr := _registers()
	Look.t = 0.0
	vr.advance(0.0)
	assert_float(vr.limits).is_equal(1.0)
	Look.t = 1.0
	vr.advance(0.0)
	assert_float(vr.limits).is_equal(0.0)
	Look.t = old
	vr.free()
