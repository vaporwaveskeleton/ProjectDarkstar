extends GdUnitTestSuite
## TECH-001 §1.2: the root renders at native resolution over a 640x360 logical reference; only the
## Act 0 arcade screen (its own SubViewport) is pixel-snapped and nearest filtered.

const GAME_SCENE := "res://features/cabinet/cabinet_game.tscn"


func _setting(key: String) -> Variant:
	return ProjectSettings.get_setting(key)


func test_logical_reference_and_window_override() -> void:
	assert_int(int(_setting("display/window/size/viewport_width"))).is_equal(640)
	assert_int(int(_setting("display/window/size/viewport_height"))).is_equal(360)
	assert_int(int(_setting("display/window/size/window_width_override"))).is_equal(1280)
	assert_int(int(_setting("display/window/size/window_height_override"))).is_equal(720)


func test_root_stretches_canvas_items_expand_fractional() -> void:
	assert_str(str(_setting("display/window/stretch/mode"))).is_equal("canvas_items")
	assert_str(str(_setting("display/window/stretch/aspect"))).is_equal("expand")
	assert_str(str(_setting("display/window/stretch/scale_mode"))).is_equal("fractional")
	assert_bool(bool(_setting("display/window/hidpi/nearest_filtering"))).is_false()


func test_root_is_unsnapped_linear_and_msaa_4x() -> void:
	assert_bool(bool(_setting("rendering/2d/snap/snap_2d_transforms_to_pixel"))).is_false()
	assert_bool(bool(_setting("rendering/2d/snap/snap_2d_vertices_to_pixel"))).is_false()
	assert_int(int(_setting("rendering/textures/canvas_textures/default_texture_filter"))).is_equal(Viewport.DEFAULT_CANVAS_ITEM_TEXTURE_FILTER_LINEAR)
	assert_int(int(_setting("rendering/anti_aliasing/quality/msaa_2d"))).is_equal(Viewport.MSAA_4X)


func test_arcade_screen_viewport_snaps_and_is_nearest() -> void:
	var game := (load(GAME_SCENE) as PackedScene).instantiate()
	var vp := game.get_node("%ScreenViewport") as SubViewport
	var screen := game.get_node("%ArcadeScreen") as ArcadeScreen
	assert_bool(vp.snap_2d_transforms_to_pixel).is_true()
	assert_bool(vp.snap_2d_vertices_to_pixel).is_true()
	assert_int(vp.canvas_item_default_texture_filter).is_equal(Viewport.DEFAULT_CANVAS_ITEM_TEXTURE_FILTER_NEAREST)
	assert_int(screen.texture_filter).is_equal(CanvasItem.TEXTURE_FILTER_NEAREST)
	assert_int(vp.msaa_2d).is_equal(Viewport.MSAA_DISABLED)
	game.free()
