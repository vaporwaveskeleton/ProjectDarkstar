extends GdUnitTestSuite
## Q-T108: the register-count helper. Synthetic images prove the mapping; captured frames under
## res://reports/automation (local only, never in CI) are checked when present.

const RegisterCount := preload("res://features/cabinet/tests/register_count.gd")
const REPORTS := "res://reports/automation"
const MAX_REPORT_FILES := 40


func _image_of(colours: Array[Color]) -> Image:
	var img := Image.create(colours.size(), 1, false, Image.FORMAT_RGBAF)   # float: no 8-bit rounding in synthetic pixels
	for i in colours.size():
		img.set_pixel(i, 0, colours[i])
	return img


func _neon() -> Array[Color]:
	var out: Array[Color] = []
	for name: String in Look.NEON:
		var c: Color = Look.NEON[name]
		out.append(c)
	return out


func test_one_colour_is_one_register() -> void:
	var c: Color = Look.NEON.values()[0]
	assert_int(RegisterCount.distinct_registers(_image_of([c, c, c]))).is_equal(1)


func test_neon_only_image_uses_the_registers_its_palette_maps_to() -> void:
	var regs := load(RegisterCount.REGISTERS) as ScreenRegisters
	var expected := {}
	for name: String in Look.NEON:
		expected[int(regs.pal_map[name])] = true
	var img := _image_of(_neon())
	var n := RegisterCount.distinct_registers(img)
	assert_int(n).is_equal(expected.size())
	assert_int(n).is_less_equal(ScreenRegisters.REGISTER_COUNT)
	assert_float(RegisterCount.worst_snap(img)).is_equal_approx(0.0, 0.000001)


func test_antialiased_edges_still_map_to_registers() -> void:
	var neon := _neon()
	var mixed: Array[Color] = []
	for i in neon.size():
		var a := neon[i]
		var b := neon[(i + 5) % neon.size()]
		mixed.append(a.lerp(b, 0.5))
		mixed.append(a.lerp(Color.BLACK, 0.3))
	var img := _image_of(mixed)
	var used := RegisterCount.registers_used(img)
	assert_int(used.size()).is_greater(0)
	assert_int(used.size()).is_less_equal(ScreenRegisters.REGISTER_COUNT)
	var total := 0
	for r: int in used.keys():
		assert_int(r).is_between(0, ScreenRegisters.REGISTER_COUNT - 1)
		total += int(used[r])
	assert_int(total).is_equal(mixed.size())
	assert_float(RegisterCount.worst_snap(img)).is_greater(0.0)


## Local capture check: any arcade.png or t*.png under res://reports/automation. None in CI (passes).
func test_captured_arcade_frames_stay_within_sixteen_registers() -> void:
	var files := _report_pngs(REPORTS)
	if files.is_empty():
		print("register count: no captures under %s, nothing to check" % REPORTS)
		return
	var checked := 0
	for path in files:
		if checked >= MAX_REPORT_FILES:
			break
		var img := Image.new()
		if img.load_png_from_buffer(FileAccess.get_file_as_bytes(path)) != OK:
			continue
		var n := RegisterCount.distinct_registers(img)
		print("register count: %s uses %d registers (worst snap %.4f)" % [path, n, RegisterCount.worst_snap(img)])
		assert_int(n).override_failure_message("%s uses %d registers" % [path, n]).is_less_equal(ScreenRegisters.REGISTER_COUNT)
		checked += 1


static func _report_pngs(root: String) -> PackedStringArray:
	var out := PackedStringArray()
	var dir := DirAccess.open(root)
	if dir == null:
		return out
	dir.list_dir_begin()
	var n := dir.get_next()
	while n != "":
		var full := root.path_join(n)
		if dir.current_is_dir():
			if not n.begins_with("."):
				out.append_array(_report_pngs(full))
		elif n.ends_with(".png") and (n == "arcade.png" or n.begins_with("t")):
			out.append(full)
		n = dir.get_next()
	return out
