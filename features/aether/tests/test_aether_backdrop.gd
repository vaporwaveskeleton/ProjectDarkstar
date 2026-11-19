extends GdUnitTestSuite
## AetherBackdrop API: drain grows the entity and drains life, reduced motion halves parallax,
## layers switch off for cost measurement, and the leviathan announces its pass.

const U := preload("res://features/aether/tests/aether_test_util.gd")


func _make(path: String) -> AetherBackdrop:
	var b := (load(U.BACKDROP) as PackedScene).instantiate() as AetherBackdrop
	b.look = load(path) as AetherLook
	add_child(b)
	return auto_free(b)


func test_drain_grows_the_entity_from_nothing() -> void:
	var b := _make("res://data/aether/drowned_observatory_t3.tres")
	await get_tree().process_frame
	var e := b.find_child("Entity", true, false) as EntityPresence
	b.set_drain(0.0)
	assert_float(e.radius).is_equal(0.0)
	assert_bool(e.visible).is_false()
	b.set_drain(1.0)
	assert_float(e.radius).is_greater(50.0)
	assert_bool(e.visible).is_true()


func test_t5_has_holes_of_black_without_drain() -> void:
	var b := _make("res://data/aether/the_black_t5.tres")
	await get_tree().process_frame
	var shown := get_tree().get_nodes_in_group(EntityPresence.GROUP).filter(func(n: Node) -> bool: return (n as CanvasItem).visible)
	assert_int(shown.size()).is_greater_equal(3)


func test_reduced_motion_halves_parallax() -> void:
	var b := _make("res://data/aether/pale_marches_t1.tres")
	await get_tree().process_frame
	var far := b.find_child("FarLayer", true, false) as Parallax2D
	var s := far.scroll_scale.x
	b.reduced_motion = true
	b.apply_look(b.look)
	assert_float(1.0 - far.scroll_scale.x).is_equal_approx((1.0 - s) * 0.5, 0.0001)


func test_layers_can_be_switched_off() -> void:
	var b := _make("res://data/aether/drowned_observatory_t3.tres")
	await get_tree().process_frame
	assert_bool(b.active_layers().has("leviathan")).is_true()
	b.set_layer_enabled(&"leviathan", false)
	assert_bool(b.active_layers().has("leviathan")).is_false()
	b.set_layer_enabled(&"grade", false)
	assert_bool(b.active_layers().has("grade")).is_false()


func test_leviathan_enters_and_reaches_closest() -> void:
	var b := _make("res://data/aether/drowned_observatory_t3.tres")
	await get_tree().process_frame
	var lev := b.find_child("Leviathan", true, false) as AetherLeviathan
	assert_str(lev.get_parent().get_class()).is_equal("Parallax2D")
	var got: Array[String] = []
	b.leviathan_entered.connect(func() -> void: got.append("entered"))
	b.leviathan_closest.connect(func() -> void: got.append("closest"))
	b.set_process(false)
	lev.configure(b.look)
	var t := 0.0
	while t < b.look.leviathan_period_s:
		lev.advance(t, 0.0)
		t += 0.25
	assert_array(got).contains(["entered", "closest"])
	var bodies := lev.find_children("*", "CollisionObject2D", true, false)
	assert_int(bodies.size()).is_equal(0)


func test_sphere_glint_passes_the_centre() -> void:
	var b := _make("res://data/aether/pale_marches_t1.tres")
	await get_tree().process_frame
	var sphere := b.find_child("Sphere", true, false) as CrystalSphere
	var n := [0]
	sphere.sphere_glinted.connect(func() -> void: n[0] += 1)
	var t := 0.0
	while t < sphere.glint_period_s:
		sphere.update_glint(t, Vector2(320, 180))
		t += 0.1
	assert_int(n[0]).is_equal(1)
