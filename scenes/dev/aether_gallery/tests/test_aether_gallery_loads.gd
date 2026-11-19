extends GdUnitTestSuite
## The dev Aether gallery instantiates headless, runs, cycles every exhibit (including the
## entity's drain), and frees cleanly.

const GALLERY := "res://scenes/dev/aether_gallery/aether_gallery.tscn"


func test_gallery_cycles_all_exhibits() -> void:
	var g: Node = (load(GALLERY) as PackedScene).instantiate()
	add_child(g)
	for i in 6:
		g.call("show_exhibit", i)
		for f in 4:
			await get_tree().process_frame
		assert_int(int(g.get("exhibit"))).is_equal(i)
	g.set("exhibit_time", 20.0)
	await get_tree().process_frame
	assert_float(float(g.get("drain"))).is_equal(1.0)
	g.call("show_exhibit", 6)
	assert_int(int(g.get("exhibit"))).is_equal(0)
	g.free()


func test_ui_right_and_left_cycle() -> void:
	var g: Node = (load(GALLERY) as PackedScene).instantiate()
	add_child(g)
	await get_tree().process_frame
	var ev := InputEventAction.new()
	ev.action = &"ui_right"
	ev.pressed = true
	g.call("_unhandled_input", ev)
	assert_int(int(g.get("exhibit"))).is_equal(1)
	ev.action = &"ui_left"
	g.call("_unhandled_input", ev)
	g.call("_unhandled_input", ev)
	assert_int(int(g.get("exhibit"))).is_equal(5)
	g.free()
