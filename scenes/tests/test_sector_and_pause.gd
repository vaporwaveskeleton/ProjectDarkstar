extends GdUnitTestSuite
## Sector stub + pause flow: Vigil spawned from the reusable scene, HUD text, pause always
## available (Steady Ledger W4-07), modal stacking, safe default focus on destructive confirm.

const SCENE := "res://scenes/sector/sector_stub.tscn"

var host: FakeRouteHost


func before_test() -> void:
	host = FakeRouteHost.install(self)
	SettingsService.persist = false


func after_test() -> void:
	get_tree().paused = false
	FakeRouteHost.uninstall(host)
	SettingsService.persist = true


func _focus() -> Control:
	return get_viewport().gui_get_focus_owner()


func test_vigil_spawns_at_anchor_with_hud() -> void:
	var runner := scene_runner(SCENE)
	await runner.simulate_frames(2)
	var vigil: Vigil = runner.get_property("vigil")
	assert_object(vigil).is_not_null()
	assert_vector(vigil.global_position).is_equal(Vector2(320, 180))
	var hud: Label = runner.find_child("HullLabel")
	assert_str(hud.text).is_equal("Hull 1")


func test_camera_and_compass_are_wired_to_the_vigil() -> void:
	var runner := scene_runner(SCENE)
	await runner.simulate_frames(2)
	var vigil: Vigil = runner.get_property("vigil")
	var cam: SectorCamera = runner.find_child("SectorCamera")
	var compass: LedgerCompass = runner.find_child("LedgerCompass")
	assert_object(cam.target).is_same(vigil)
	assert_bool(cam.is_current()).is_true()
	assert_vector(cam.zoom).is_equal(Vector2.ONE)
	compass.refresh()
	# the Vigil first, then the Sepulchre and its 4 Grubs (lower compass rank), then the sandbox
	# geodes, capped at max_markers (8 ✱)
	assert_int(compass.marker_points.size()).is_equal(compass.stats.max_markers)
	assert_str(str(compass.marker_kinds[0])).is_equal("vigil")
	assert_str(str(compass.marker_kinds[1])).is_equal("sepulchre")
	for i in range(2, 6):
		assert_str(str(compass.marker_kinds[i])).is_equal("grub")
	assert_str(str(compass.marker_kinds[6])).is_equal("geode")
	assert_object(compass.torus).is_same(runner.get_property("torus"))
	# Q-T120: one 64 × 64 module (ART-001 §12.5), top-centre of the sector HUD
	assert_vector(compass.size).is_equal(Vector2(64, 64))
	assert_float(compass.position.x + compass.size.x * 0.5).is_equal_approx(
		compass.get_parent_area_size().x * 0.5, 0.5)
	assert_object(vigil.emitter.projectile_parent).is_same(runner.find_child("Actors"))


func test_sepulchre_grubs_and_charges_are_wired() -> void:
	var runner := scene_runner(SCENE)
	await runner.simulate_frames(2)
	var vigil: Vigil = runner.get_property("vigil")
	var actors: Node2D = runner.find_child("Actors")
	var procession: ProcessionSandbox = runner.find_child("ProcessionSandbox")
	var launcher: ChargeLauncher = runner.find_child("ChargeLauncher")
	var sep := procession.sepulchre
	assert_object(sep).is_not_null()
	assert_object(sep.get_parent()).is_same(actors)
	assert_vector(sep.home).is_equal(Vector2(1100, 560))
	assert_bool(sep.hurtbox.bites).is_false()
	assert_int(runner.get_property("grubs_alive")).is_equal(4)
	assert_int(runner.get_property("grubs_carrying")).is_equal(0)
	assert_int(runner.get_property("segments")).is_equal(0)
	assert_int(runner.get_property("deposited_shards")).is_equal(0)
	assert_bool(runner.get_property("sepulchre_complete")).is_false()
	assert_int(runner.get_property("charges_in_flight")).is_equal(0)
	assert_int(runner.get_property("charges_lost")).is_equal(0)
	assert_object(launcher.vigil).is_same(vigil)
	assert_object(launcher.target).is_same(sep.hurtbox)
	assert_object(launcher.projectile_parent).is_same(actors)
	assert_object(launcher.magazine).is_same(runner.find_child("ChargeMagazine"))
	# Phase 0: the Sepulchre is off the spawn view (ZONES-001 §6.1)
	var t: Torus = runner.get_property("torus")
	var d := t.delta(vigil.global_position, sep.home)
	assert_bool(absf(d.x) > 320.0 or absf(d.y) > 180.0).is_true()


func test_glass_economy_is_wired_on_the_sector_torus() -> void:
	var runner := scene_runner(SCENE)
	await runner.simulate_frames(2)
	var vigil: Vigil = runner.get_property("vigil")
	var shards: ShardField = runner.find_child("ShardField")
	var sandbox: GeodeSandbox = runner.find_child("GeodeSandbox")
	assert_int(runner.get_property("geodes_alive")).is_equal(10)
	assert_int(runner.get_property("shards_free")).is_equal(0)
	assert_int(runner.get_property("charges")).is_equal(0)
	assert_int(runner.get_property("score")).is_equal(0)
	assert_object(shards.collector).is_same(vigil)
	assert_object(shards.torus).is_same(sandbox.torus)
	assert_object(shards.magazine).is_same(runner.find_child("ChargeMagazine"))
	assert_int(shards.pool_size()).is_equal(144)


func test_pause_action_opens_pause_and_pauses_tree() -> void:
	var runner := scene_runner(SCENE)
	await runner.simulate_frames(2)
	runner.simulate_action_pressed("pause")
	await runner.simulate_frames(2)
	var stack: ScreenStack = runner.find_child("Overlays")
	assert_int(stack.depth()).is_equal(1)
	assert_bool(get_tree().paused).is_true()
	assert_str(_focus().name).is_equal("Resume")


func test_ui_cancel_and_pause_both_resume() -> void:
	var runner := scene_runner(SCENE)
	await runner.simulate_frames(2)
	var stack: ScreenStack = runner.find_child("Overlays")
	runner.invoke("open_pause")
	await runner.simulate_frames(2)
	runner.simulate_action_pressed("ui_cancel")
	await runner.simulate_frames(2)
	assert_int(stack.depth()).is_equal(0)
	assert_bool(get_tree().paused).is_false()
	runner.invoke("open_pause")
	await runner.simulate_frames(2)
	runner.simulate_action_pressed("pause")
	await runner.simulate_frames(2)
	assert_int(stack.depth()).is_equal(0)
	assert_bool(get_tree().paused).is_false()


func test_abandon_confirm_defaults_to_safe_choice_and_cancel_restores_focus() -> void:
	var runner := scene_runner(SCENE)
	await runner.simulate_frames(2)
	var stack: ScreenStack = runner.find_child("Overlays")
	runner.invoke("open_pause")
	await runner.simulate_frames(2)
	(runner.find_child("Abandon") as Button).grab_focus()
	runner.simulate_action_pressed("ui_accept")
	await runner.simulate_frames(2)
	assert_int(stack.depth()).is_equal(2)
	assert_str(_focus().name).is_equal("Cancel")
	runner.simulate_action_pressed("ui_cancel")
	await runner.simulate_frames(2)
	assert_int(stack.depth()).is_equal(1)
	assert_str(_focus().name).is_equal("Abandon")
	assert_bool(get_tree().paused).is_true()


func test_confirmed_abandon_routes_to_attract_and_unpauses() -> void:
	var runner := scene_runner(SCENE)
	await runner.simulate_frames(2)
	runner.invoke("open_pause")
	await runner.simulate_frames(2)
	(runner.find_child("Abandon") as Button).pressed.emit()
	await runner.simulate_frames(2)
	(runner.find_child("Confirm") as Button).pressed.emit()
	await runner.simulate_frames(4)
	assert_bool(get_tree().paused).is_false()
	assert_array(host.mounted_routes).is_equal(["res://scenes/attract/attract_mode.tscn"])


func test_settings_from_pause_stacks_three_deep_and_unwinds() -> void:
	var runner := scene_runner(SCENE)
	await runner.simulate_frames(2)
	var stack: ScreenStack = runner.find_child("Overlays")
	runner.invoke("open_pause")
	await runner.simulate_frames(2)
	(runner.find_child("Settings") as Button).pressed.emit()
	await runner.simulate_frames(2)
	assert_int(stack.depth()).is_equal(2)
	for i in 2:
		runner.simulate_action_pressed("ui_cancel")
		await runner.simulate_frames(2)
	assert_int(stack.depth()).is_equal(0)
	assert_bool(get_tree().paused).is_false()
