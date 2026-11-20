extends GdUnitTestSuite
## The Act 0 arcade screen (TECH-001 §1.3, §2.10): grid from data, CRT as the screen's material on its
## own texture, scanline rows from a uniform, the rig's placement, and mouse / overlay input.

const GAME_SCENE := "res://features/cabinet/cabinet_game.tscn"
const SPEC := "res://data/cabinet/cabinet_screen.tres"
const SHADER_DIR := "res://shaders/"


func _game() -> Node:
	var game := (load(GAME_SCENE) as PackedScene).instantiate()
	add_child(game)
	return game


func test_spec_is_a_ds_tunable_with_the_portrait_grid_and_hud_strip() -> void:
	var spec := load(SPEC) as CabinetScreenSpec
	assert_str(spec.ds_namespace).is_equal("ds_cabinet.screen")
	assert_object(spec.grid).is_equal(Vector2i(256, 304))
	assert_int(spec.hud_strip_height).is_equal(48)
	assert_object(spec.play_rect()).is_equal(Rect2(0, 48, 256, 256))
	assert_vector(spec.play_centre()).is_equal(Vector2(128, 176))
	assert_bool(spec.ds_keys().has("ds_cabinet.screen.grid")).is_true()
	assert_bool(spec.ds_keys().has("ds_cabinet.screen.hud_strip_height")).is_true()


func test_screen_viewport_matches_the_grid_and_carries_the_crt_material() -> void:
	var game := _game()
	var screen := game.get_node("%ArcadeScreen") as ArcadeScreen
	var vp := game.get_node("%ScreenViewport") as SubViewport
	assert_object(vp.size).is_equal(screen.spec.grid)
	assert_vector(screen.size).is_equal(Vector2(screen.spec.grid))
	assert_bool(screen.stretch).is_false()
	var mat := screen.crt_material()
	assert_object(mat).is_not_null()
	assert_str(mat.shader.resource_path).is_equal(SHADER_DIR + "crt.gdshader")
	assert_float(float(mat.get_shader_parameter(&"rows"))).is_equal(float(screen.spec.grid.y))
	game.queue_free()


func test_everything_on_the_tube_is_inside_the_screen_and_the_bezel_is_not() -> void:
	var game := _game()
	var vp := game.get_node("%ScreenViewport") as SubViewport
	for n in ["%World", "%Aether", "%Maw", "%ScreenHud", "%Messages"]:
		assert_bool(vp.is_ancestor_of(game.get_node(n))).override_failure_message("%s should be on the tube" % n).is_true()
	assert_bool(vp.is_ancestor_of(game.get_node("%Hud"))).is_false()
	assert_bool(vp.is_ancestor_of(game.get_node("%Overlays"))).is_false()
	game.queue_free()


func test_no_focusable_control_lives_in_the_screen_viewport() -> void:
	var game := _game()
	var stack: Array[Node] = [game.get_node("%ScreenViewport")]
	while not stack.is_empty():
		var n: Node = stack.pop_back()
		if n is Control:
			assert_int((n as Control).focus_mode).override_failure_message("%s is focusable" % n.name).is_equal(Control.FOCUS_NONE)
		stack.append_array(n.get_children())
	game.queue_free()


func test_screen_crt_reads_its_own_texture_and_no_shader_hard_codes_the_rows() -> void:
	var crt := FileAccess.get_file_as_string(SHADER_DIR + "crt.gdshader")
	assert_bool(crt.contains("hint_screen_texture")).is_false()
	assert_bool(crt.contains("TEXTURE")).is_true()
	for f in ["crt.gdshader"]:
		assert_bool(FileAccess.get_file_as_string(SHADER_DIR + f).contains("360")).override_failure_message("%s hard-codes 360" % f).is_false()
	var common := FileAccess.get_file_as_string(SHADER_DIR + "crt_common.gdshaderinc")
	assert_bool(common.contains("uniform float rows")).is_true()
	assert_bool(common.contains("* 360")).is_false()


func test_rig_places_the_screen_from_screen_fit() -> void:
	var game := _game()
	var rig := game.get_node("%Rig") as ScreenRig
	var t := ScreenFit.rig_transform(rig.get_window().size, rig.spec.grid)
	assert_vector(rig.position).is_equal_approx(t.origin, Vector2(0.001, 0.001))
	assert_vector(rig.scale).is_equal_approx(Vector2(t.x.x, t.y.y), Vector2(0.0001, 0.0001))
	game.queue_free()


## A scaled, offset container forwards mouse motion, so the viewport's own mouse is in grid coordinates.
func test_container_forwards_the_mouse_in_grid_coordinates() -> void:
	var rig := Control.new()
	rig.position = Vector2(30, 20)
	rig.scale = Vector2(2, 2)
	var screen := SubViewportContainer.new()
	screen.size = Vector2(640, 360)
	var vp := SubViewport.new()
	vp.size = Vector2i(640, 360)
	screen.add_child(vp)
	rig.add_child(screen)
	add_child(rig)
	await get_tree().process_frame
	var motion := InputEventMouseMotion.new()
	var logical := Vector2(30, 20) + Vector2(100, 50) * 2.0   # root canvas coordinates of grid point (100, 50)
	motion.position = get_tree().root.get_final_transform() * logical
	motion.global_position = motion.position
	Input.parse_input_event(motion)
	await get_tree().process_frame
	assert_vector(vp.get_mouse_position()).is_equal_approx(Vector2(100, 50), Vector2(0.01, 0.01))
	rig.queue_free()


class _Probe extends Node:
	var hits := 0
	func _input(_e: InputEvent) -> void:
		hits += 1


## While a pause overlay is open the tree is paused: the container must not forward input into the tube.
func test_paused_tree_does_not_forward_into_the_screen() -> void:
	var screen := SubViewportContainer.new()
	screen.size = Vector2(640, 360)
	var vp := SubViewport.new()
	vp.size = Vector2i(640, 360)
	screen.add_child(vp)
	var probe := _Probe.new()
	vp.add_child(probe)
	add_child(screen)
	await get_tree().process_frame
	get_tree().paused = true
	var key := InputEventKey.new()
	key.keycode = KEY_ESCAPE
	key.pressed = true
	get_tree().root.push_input(key)
	await get_tree().process_frame
	get_tree().paused = false
	var forwarded := probe.hits
	screen.queue_free()
	assert_int(forwarded).is_equal(0)


func test_world_view_and_centre_come_from_the_spec() -> void:
	var game := _game()
	var world := game.get_node("%World") as ArcadeWorld
	var spec := load(SPEC) as CabinetScreenSpec
	assert_object(world.view_rect).is_equal(spec.play_rect())
	assert_vector(world.view_size).is_equal(spec.play_size())
	assert_vector(world.screen_centre).is_equal(spec.play_centre())
	# the camera is glued to the Vigil, which is drawn at the centre of the play view
	world.start(game.stages[0])
	assert_vector(world.to_screen(world.vigil.pos)).is_equal_approx(spec.play_centre(), Vector2(0.01, 0.01))
	assert_bool(world.on_screen(world.vigil.pos, 0.0)).is_true()
	# the HUD strip is not part of the view
	var above := world.vigil.pos - Vector2(0, spec.play_size().y * 0.5 + 8.0)
	assert_bool(world.on_screen(above, 0.0)).is_false()
	game.queue_free()


## The cursed turn (TECH-001 Q-T262, Reviewer v3 gap 3): the wound opens OFF-centre, inside the play view, at
## the focus the glass bulged at (never a centred iris, ART-001 §16.6f).
func test_ledger_compass_sits_inside_the_strip_and_the_wound_opens_off_centre_in_the_play_view() -> void:
	var spec := load(SPEC) as CabinetScreenSpec
	assert_bool(spec.strip_rect().encloses(CabinetScreenHud.compass_box())).is_true()
	var game := _game()
	var maw := game.get_node("%Maw") as MawView
	assert_bool(spec.play_rect().has_point(maw.centre)).is_true()
	assert_float(maw.centre.distance_to(spec.play_centre())).is_greater(spec.play_size().y * 0.15)
	var decay := load("res://data/cabinet/cabinet_decay.tres") as CabinetDecayTuning
	assert_vector(maw.centre).is_equal_approx(MawView.focus_point(spec, decay), Vector2(0.01, 0.01))
	game.queue_free()


## Owner ruling Q5 (2026-11-18): Acolytes do not fire from off-screen.
func test_acolyte_off_screen_never_fires() -> void:
	var game := _game()
	var world := game.get_node("%World") as ArcadeWorld
	world.start(game.stages[0])
	var vigil := world.vigil
	# one Acolyte inside the range but outside the play view (above it), the Vigil centred
	world.acolytes.items.clear()
	var a := world.acolytes.spawn(world.torus.wrap(vigil.pos + Vector2(0, -(world.view_size.y * 0.5 + 60.0))))
	a.cycle = 0.0
	assert_bool(world.on_screen(a.pos, 0.0)).is_false()
	assert_float(world.torus.distance(a.pos, vigil.pos)).is_less(world.tuning.acolyte_range)
	var shots_before := world.shots.shots.size()
	world.acolytes.tick(0.05)
	assert_float(a.cycle).is_equal(0.0)   # its cycle did not run
	assert_int(world.shots.shots.size()).is_equal(shots_before)
	# bring it into view: it holds fire for the entry hold (SYS-001 §1.7), then the cycle runs and it fires
	a.pos = world.torus.wrap(vigil.pos + Vector2(0, -60.0))
	assert_bool(world.on_screen(a.pos, 0.0)).is_true()
	world.acolytes.tick(0.05)
	assert_float(a.hold).is_greater(0.0)
	assert_int(world.shots.shots.size()).is_equal(shots_before)
	for i in 100:
		if world.shots.shots.size() > shots_before:
			break
		a.pos = world.torus.wrap(vigil.pos + Vector2(0, -60.0))     # it would back off to its hold range, out of view
		world.acolytes.tick(0.05)
	assert_float(a.cycle).is_greater(0.0)
	assert_int(world.shots.shots.size()).is_equal(shots_before + 1)
	game.queue_free()


func test_the_screen_fills_the_hole_in_the_rig() -> void:
	var game := _game()
	var screen := game.get_node("%ArcadeScreen") as ArcadeScreen
	assert_object(Rect2(screen.position, screen.size)).is_equal(ScreenFit.hole_rect(screen.spec.grid))
	assert_object(Rect2(screen.position, screen.size)).is_equal(CabinetBezel.hole())
	game.queue_free()
