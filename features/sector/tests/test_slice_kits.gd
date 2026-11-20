extends GdUnitTestSuite
## SliceKitTable and the two slice kits (PM-01 as built, PM-02 Dark Throat), and the sector building
## each (TECH-001 §2.9 SectorKit). One scene, no branching on kit ids.

const TABLE := preload("res://data/sector/slice_kits.tres")
const PM01 := preload("res://data/sector/kits/pm_01.tres")
const PM02 := preload("res://data/sector/kits/pm_02.tres")
const SCENE := "res://scenes/sector/sector_stub.tscn"
const STATS := preload("res://data/run/run_session.tres")


func test_table_maps_seams_to_kits_and_clamps() -> void:
	assert_object(TABLE.kit_for_seam(1)).is_same(PM01)
	assert_object(TABLE.kit_for_seam(2)).is_same(PM02)
	assert_object(TABLE.kit_for_seam(0)).is_same(PM01)
	assert_object(TABLE.kit_for_seam(5)).is_same(PM02)
	assert_object(TABLE.kit_by_id(&"pm_02")).is_same(PM02)
	assert_object(TABLE.kit_by_id(&"nope")).is_null()
	assert_object(SliceKitTable.new().kit_for_seam(1)).is_null()


func test_kit_switch_is_dev_only_and_ignores_unknown_ids() -> void:
	var args := PackedStringArray(["--kit=pm_02", "--no-save"])
	assert_object(TABLE.kit_for_launch(args, true, 1)).is_same(PM02)
	assert_object(TABLE.kit_for_launch(args, false, 1)).is_same(PM01)
	assert_object(TABLE.kit_for_launch(PackedStringArray(["--kit=zzz"]), true, 1)).is_same(PM01)
	assert_object(TABLE.kit_for_launch(PackedStringArray(), true, 2)).is_same(PM02)


func test_pm_01_reproduces_the_sandbox_layout() -> void:
	assert_str(String(PM01.kit_id)).is_equal("pm_01")
	assert_vector(PM01.vigil_spawn).is_equal(Vector2(320, 180))
	assert_int(PM01.geodes.size()).is_equal(0)                       # the seeded sandbox layout
	assert_str(PM01.procession.resource_path).is_equal("res://data/sepulchre/procession_sandbox.tres")
	assert_int(PM01.sepulchre_start_segments).is_equal(0)
	assert_int(PM01.start_carriers).is_equal(0)
	assert_int(PM01.acolyte_posts.size()).is_equal(0)
	assert_bool(PM01.has_exit_anchor).is_false()
	assert_bool(PM01.dark_default).is_false()
	assert_int(PM01.satellite_grubs).is_equal(0)


func test_pm_02_numbers() -> void:
	assert_str(String(PM02.kit_id)).is_equal("pm_02")
	assert_vector(PM02.vigil_spawn).is_equal(Vector2(320, 330))
	assert_int(PM02.geodes.size()).is_equal(8)
	assert_vector(PM02.geodes[0]).is_equal(Vector2(760, 240))
	assert_vector(PM02.geodes[7]).is_equal(Vector2(1176, 262))
	assert_vector(PM02.procession.sepulchre_pos).is_equal(Vector2(1620, 600))
	assert_int(PM02.procession.grub_count).is_equal(7)
	assert_array(Array(PM02.procession.route)).is_equal([Vector2(980, 300), Vector2(980, 430), Vector2(1160, 672), Vector2(1500, 672)])
	assert_int(PM02.sepulchre_start_segments).is_equal(3)
	assert_int(PM02.start_carriers).is_equal(3)
	assert_array(Array(PM02.acolyte_posts)).is_equal([Vector2(520, 636)])
	assert_bool(PM02.has_exit_anchor).is_true()
	assert_vector(PM02.exit_anchor).is_equal(Vector2(420, 672))
	assert_bool(PM02.dark_default).is_true()
	assert_float(PM02.dark_halo).is_equal(0.25)
	assert_vector(PM02.light_pocket_pos).is_equal(Vector2(980, 330))
	assert_float(PM02.light_pocket_radius_px).is_equal(110.0)
	assert_bool(PM02.unlit_corridor == Rect2(0, 624, 1920, 96)).is_true()
	assert_int(PM02.satellite_grubs).is_equal(2)
	assert_vector(PM02.satellite_spawn).is_equal(Vector2(1700, 160))
	var look: AetherLook = PM02.far_look
	assert_int(look.sister_spheres).is_equal(5)
	assert_int(look.sister_spheres_eaten).is_equal(0)
	assert_float(look.life_density).is_equal(0.8)
	assert_float(look.presence_lit).is_equal(0.0)
	assert_int(look.reveal_life_count).is_equal((PM01.far_look as AetherLook).reveal_life_count)


func test_pm_02_never_goes_black() -> void:
	var c: Color = PM02.dark_ambient
	assert_float(minf(c.r, minf(c.g, c.b))).is_greater(0.3)


func test_the_throwaway_sector_builds_pm_01() -> void:
	var runner := scene_runner(SCENE)
	var sector: Node = runner.scene()
	assert_str(sector.kit_id).is_equal("pm_01")
	assert_int(sector.segments).is_equal(0)
	assert_int(sector.grubs_alive).is_equal(4)
	assert_int(sector.acolyte_alive).is_equal(0)
	assert_int(sector.geodes_alive).is_equal(10)
	assert_vector((sector.seam_exit as SeamExit).throat_home).is_equal((sector.exit_stats as SeamExitStats).throat_pos)
	assert_bool(sector.darkness.active).is_false()


func _seam_2_core() -> RunSessionCore:
	var core := RunSessionCore.new(STATS, null)
	core.arrive_at_ruins({})
	core.start_run(5)
	core.enter_seam()
	var r := SeamReport.new()
	r.composure = 8.0
	assert_bool(core.end_seam(r)).is_true()
	return core


func test_the_sector_applies_pm_02_at_seam_2() -> void:
	var core := _seam_2_core()
	var runner := scene_runner(SCENE)
	var sector: Node = runner.scene()
	sector.on_route_entered(core.enter_seam())
	assert_int(sector.seam_index).is_equal(2)
	assert_str(sector.kit_id).is_equal("pm_02")
	assert_int(sector.segments).is_equal(3)                         # Active from the start
	assert_vector((sector.seam_exit as SeamExit).throat_home).is_equal(Vector2(420, 672))
	assert_vector((sector.seam_exit as SeamExit).throat.position).is_equal(Vector2(420, 672))
	assert_int(sector.grubs_alive).is_equal(9)                      # 7 route Grubs + the satellite pair
	assert_int(sector.grubs_carrying).is_equal(3)                   # start_carriers: deposits at once
	assert_int(sector.acolyte_alive).is_equal(1)
	assert_int(sector.geodes_alive).is_equal(8)
	assert_bool(sector.darkness.active).is_true()
	assert_str(sector.far_look).is_equal("ds_aether.pm02_pale_marches_t1")
	assert_object(sector.get_node("%ChargeLauncher").target).is_same(sector._procession.sepulchre.hurtbox)
	await runner.simulate_frames(3)
	assert_int(sector.darkness.discs.size()).is_greater(0)


func test_pm_02_clears_with_charges_and_opens_the_throat_at_the_anchor() -> void:
	var core := _seam_2_core()
	var runner := scene_runner(SCENE)
	var sector: Node = runner.scene()
	sector.on_route_entered(core.enter_seam())
	var sep: Sepulchre = sector._procession.sepulchre
	for _i in 3:
		sep.take_charge_hit()
	await runner.simulate_frames(3)
	assert_bool(sector.seam_cleared).is_true()
	assert_bool((sector.seam_exit as SeamExit).throat.visible).is_true()


func test_seam_1_keeps_pm_01_when_a_session_is_handed_in() -> void:
	var core := RunSessionCore.new(STATS, null)
	core.arrive_at_ruins({})
	core.start_run(5)
	var runner := scene_runner(SCENE)
	var sector: Node = runner.scene()
	sector.on_route_entered(core.enter_seam())
	assert_str(sector.kit_id).is_equal("pm_01")
	assert_int(sector.segments).is_equal(0)
	assert_int(sector.acolyte_alive).is_equal(0)


func test_acolyte_off_is_a_dev_only_switch() -> void:
	var args := PackedStringArray(["--acolyte-off"])
	assert_bool(SliceKitTable.acolytes_off(args, true)).is_true()
	assert_bool(SliceKitTable.acolytes_off(args, false)).is_false()
	assert_bool(SliceKitTable.acolytes_off(PackedStringArray(), true)).is_false()


func test_fixed_layout_uses_the_authored_positions() -> void:
	var torus := Torus.new(Vector2(1920, 720))
	var out := GeodeSandbox.fixed_layout(RunSeed.new(146), 3, torus, PM02.geodes)
	assert_int(out.size()).is_equal(8)
	assert_vector(out[0].pos as Vector2).is_equal(Vector2(760, 240))
	assert_int(int(out[0].size_class)).is_between(0, 2)


func test_grub_halo_dims_outside_the_light_pocket_only() -> void:
	var gp := auto_free(GrubProcession.new()) as GrubProcession
	gp.torus = Torus.new(Vector2(1920, 720))
	assert_float(gp.halo_scale_at(Vector2(0, 0))).is_equal(1.0)     # no dark kit: unchanged
	gp.dark_halo = 0.25
	gp.pocket_pos = Vector2(980, 330)
	gp.pocket_radius_px = 110.0
	assert_float(gp.halo_scale_at(Vector2(1000, 340))).is_equal(1.0)
	assert_float(gp.halo_scale_at(Vector2(1500, 340))).is_equal(0.25)
