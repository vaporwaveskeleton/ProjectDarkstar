extends GdUnitTestSuite
## The ComfyUI-generated bezel candidates (BezelArtMode, ART-001 §14.9) fit CabinetBezel's 640×360 rig space:
## 2× size, exactly transparent over the screen hole, opaque face on the sheet, transparent outside the sheet.

static func _image(name: String) -> Image:
	var bytes := FileAccess.get_file_as_bytes(BezelArtMode.FOLDER + name)
	var img := Image.new()
	img.load_png_from_buffer(bytes)
	return img


func test_every_bezel_candidate_fits_the_rig_and_the_hole() -> void:
	var h := CabinetBezel.hole()
	var sx := CabinetBezel.sheet_x()
	for name in ["bezel_navy.png", "bezel_oxblood.png", "bezel_black.png"]:
		var img := _image(name)
		assert_vector(Vector2(img.get_size())).is_equal(Vector2(ScreenFit.REF) * 2.0)
		# hole: every corner and the centre fully transparent, one texel outside each corner opaque
		for p in [h.position, h.end - Vector2.ONE, h.get_center(), Vector2(h.position.x, h.end.y - 1.0), Vector2(h.end.x - 1.0, h.position.y)]:
			assert_float(img.get_pixel(int(p.x * 2.0), int(p.y * 2.0)).a).override_failure_message("%s hole at %s" % [name, p]).is_equal(0.0)
		assert_float(img.get_pixel(int(h.position.x * 2.0) - 1, int(h.get_center().y * 2.0)).a).is_equal(1.0)
		assert_float(img.get_pixel(int(h.end.x * 2.0) + 1, int(h.get_center().y * 2.0)).a).is_equal(1.0)
		# sheet face opaque, beyond the sheet transparent (the backdrop shows)
		assert_float(img.get_pixel(int(sx.x * 2.0) + 4, 360).a).is_equal(1.0)
		assert_float(img.get_pixel(int(sx.x * 2.0) - 4, 360).a).is_equal(0.0)


func test_the_texture_node_builds_over_the_rig_when_switched_on() -> void:
	var t := auto_free(BezelTexture.new()) as BezelTexture
	add_child(t)
	assert_object(t.texture).is_not_null()
	assert_vector(t.size).is_equal(Vector2(ScreenFit.REF))
	assert_int(t.mouse_filter).is_equal(Control.MOUSE_FILTER_IGNORE)
