extends GdUnitTestSuite
## DustMotes: cosmetic, deterministic, inside its area, and still under reduced motion.


func _dust(still := false) -> DustMotes:
	var d := DustMotes.new()
	d.still = still
	add_child(d)
	auto_free(d)
	return d


func test_motes_stay_inside_the_area() -> void:
	var d := _dust()
	for t: float in [0.0, 13.7, 600.0]:
		for i in DustMotes.COUNT:
			assert_bool(DustMotes.AREA.grow(DustMotes.SWAY_PX).has_point(d.mote_at(i, t))).is_true()


func test_same_seed_same_air() -> void:
	var a := _dust()
	var b := _dust()
	assert_vector(a.mote_at(5, 3.0)).is_equal(b.mote_at(5, 3.0))


func test_reduced_motion_holds_the_motes_still() -> void:
	var d := _dust(true)
	assert_vector(d.mote_at(9, 0.0)).is_equal(d.mote_at(9, 42.0))


func test_motes_draw_batched_quads_from_a_generated_dot() -> void:
	# Q-T248 (Ruins) perf: one textured quad per mote from a shared runtime GradientTexture2D
	# (no image files, D-13), never a tessellated circle per mote per frame.
	DustMotes._ensure_dot()
	assert_object(DustMotes._dot_tex).is_not_null()
	assert_int(DustMotes._dot_tex.fill).is_equal(GradientTexture2D.FILL_RADIAL)
	var src := FileAccess.get_file_as_string("res://features/interactions/dust_motes.gd")
	assert_bool(src.contains("draw_circle(")).is_false()
