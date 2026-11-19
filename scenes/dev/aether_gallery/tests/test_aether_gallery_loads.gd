extends GdUnitTestSuite
## The dev Aether gallery instantiates headless, runs, cycles every exhibit (including the
## entity's drain, the PM-01 slice exhibit and the Pale Marches ladder), toggles the stand-in
## lantern, and frees cleanly.

const GALLERY := "res://scenes/dev/aether_gallery/aether_gallery.tscn"


func _count(g: Node) -> int:
	var looks: Array = (g.get_script() as Script).get_script_constant_map()["LOOKS"]
	return looks.size()


func test_gallery_cycles_all_exhibits() -> void:
	var g: Node = (load(GALLERY) as PackedScene).instantiate()
	add_child(g)
	var n := _count(g)
	assert_int(n).is_equal(12)
	for i in n:
		g.call("show_exhibit", i)
		for f in 4:
			await get_tree().process_frame
		assert_int(int(g.get("exhibit"))).is_equal(i)
	g.call("show_exhibit", 5)
	g.set("exhibit_time", 20.0)
	await get_tree().process_frame
	assert_float(float(g.get("drain"))).is_equal(1.0)
	g.call("show_exhibit", n)
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
	assert_int(int(g.get("exhibit"))).is_equal(_count(g) - 1)
	g.free()


func test_focus_prev_toggles_the_stand_in_lantern() -> void:
	var g: Node = (load(GALLERY) as PackedScene).instantiate()
	add_child(g)
	await get_tree().process_frame
	g.call("show_exhibit", 6)
	var b := g.get_node("%Backdrop") as AetherBackdrop
	var lamp := g.get_node("%Lantern") as LanternMarker
	assert_bool(bool(g.get("lantern_lit"))).is_true()
	var ev := InputEventAction.new()
	ev.action = &"ui_focus_prev"
	ev.pressed = true
	g.call("_unhandled_input", ev)
	assert_bool(bool(g.get("lantern_lit"))).is_false()
	assert_bool(b.lantern_lit).is_false()
	assert_bool(lamp.light.enabled).is_false()
	g.call("_unhandled_input", ev)
	assert_bool(b.lantern_lit).is_true()
	assert_bool(lamp.light.enabled).is_true()
	g.free()
