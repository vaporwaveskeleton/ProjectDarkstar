extends GdUnitTestSuite
## The dev Ruins look gallery instantiates headless, cycles its four states (entry, before any lamp,
## one lamp, three lamps), lights the right number of lamps, and frees cleanly.

const GALLERY := "res://scenes/dev/aether_gallery/ruins_gallery.tscn"


func test_gallery_cycles_its_states() -> void:
	var g: Node = (load(GALLERY) as PackedScene).instantiate()
	add_child(g)
	var expected: Array[int] = [0, 0, 1, 3]
	for i in 4:
		g.call("show_stage", i)
		await get_tree().process_frame
		var look := g.get("look") as RuinsLook
		assert_bool(look.show_placeholders).is_true()
		assert_bool(look.first_visit).is_equal(i == 0)
		g.set("stage_time", 3.0)
		await get_tree().process_frame
		assert_int(look.lamp_count()).is_equal(expected[i])
	g.free()
