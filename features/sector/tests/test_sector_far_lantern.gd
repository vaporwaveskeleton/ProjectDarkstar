extends GdUnitTestSuite
## The sector feeds the Vigil's lantern to the Aether far layer (pass 8, Q-T295; TECH-001 §2.9): the
## warm pool follows the ship, and lantern down (CH-3) drives the far layer's reveal. The far layer
## changes nothing in the play layer.

const SCENE := "res://scenes/sector/sector_stub.tscn"


func test_far_layer_follows_the_vigils_lantern() -> void:
	var runner := scene_runner(SCENE)
	await runner.simulate_frames(3)
	var sector: Node = runner.scene()
	var far := sector.get_node("%AetherFarLayer") as AetherFarLayer
	var vigil: Vigil = sector.vigil
	assert_object(vigil).is_not_null()
	var bd := far.backdrop
	# the pool sits on the Vigil: the far layer's screen position of the lantern matches the ship's
	var cam := sector.get_node("%SectorCamera") as Camera2D
	var expect := (vigil.global_position - cam.global_position) * cam.zoom.x + bd.get_viewport_rect().size * 0.5
	assert_float(bd.lantern_screen.distance_to(expect)).is_less(12.0)
	assert_float(bd.lantern_radius).is_equal_approx(far.look.lantern_radius * cam.zoom.x, 0.001)
	assert_bool(bd.lantern_lit).is_true()
	vigil.lantern.toggle()
	await runner.simulate_frames(2)
	assert_bool(bd.lantern_lit).is_false()
	vigil.lantern.toggle()
	await runner.simulate_frames(2)
	assert_bool(bd.lantern_lit).is_true()
