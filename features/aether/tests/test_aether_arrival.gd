extends GdUnitTestSuite
## AetherArrival (route &"aether"): route params land on the backdrop, camera and lantern in the
## entering call (no frame late), missing or wrongly typed params use the defaults, and the
## route is shipped while the gallery stays dev-only.

const ARRIVAL := "res://features/aether/aether_arrival.tscn"
const SHIPPED := "res://data/routes/route_table.tres"
const DEV := "res://data/routes/dev_route_table.tres"

var _prev_persist: bool
var _prev_reduced: bool


func before_test() -> void:
	_prev_persist = SettingsService.persist
	SettingsService.persist = false
	_prev_reduced = bool(SettingsService.get_value(&"reduced_motion"))
	SettingsService.set_value(&"reduced_motion", false)


func after_test() -> void:
	SettingsService.set_value(&"reduced_motion", _prev_reduced)
	SettingsService.persist = _prev_persist


func _make() -> Node:
	var a: Node = (load(ARRIVAL) as PackedScene).instantiate()
	add_child(a)
	return auto_free(a)


func test_params_are_applied_in_the_entering_call() -> void:
	var a := _make()
	a.call("on_route_entered", {"skip_curtain": true, "aether_time_s": 3.0, "tier": 2,
		"camera_centre": Vector2(300, 170), "camera_zoom": 1.25})
	var b := a.get_node("%Backdrop") as AetherBackdrop
	var cam := a.get_node("%Camera") as Camera2D
	var lantern := a.get_node("%Lantern") as Node2D
	assert_float(b.time_s).is_equal(3.0)
	assert_int(b.tier).is_equal(2)
	assert_vector(b.camera_centre).is_equal(Vector2(300, 170))
	assert_float(b.camera_zoom).is_equal(1.25)
	assert_vector(cam.position).is_equal(Vector2(300, 170))
	assert_vector(cam.zoom).is_equal(Vector2(1.25, 1.25))
	assert_vector(lantern.position).is_equal(Vector2(300, 170))
	# refresh() pushed the uniforms already: the first drawn frame is not a frame late
	var far := b.find_child("FarFog", true, false) as AetherShaderRect
	assert_float(float(far.get_param(&"time_s"))).is_equal(3.0)
	assert_int(int(far.get_param(&"tier"))).is_equal(2)
	var screen := b.get_viewport_rect().size
	assert_vector(far.get_param(&"screen_size") as Vector2).is_equal(screen)
	var sphere := b.find_child("Sphere", true, false) as AetherShaderRect
	assert_vector(sphere.get_param(&"camera_offset") as Vector2).is_equal(Vector2(300, 170) - screen * 0.5)


func test_string_name_keys_are_read_too() -> void:
	var a := _make()
	a.call("on_route_entered", {&"aether_time_s": 5.0, &"tier": 3})
	var b := a.get_node("%Backdrop") as AetherBackdrop
	assert_float(b.time_s).is_equal(5.0)
	assert_int(b.tier).is_equal(3)


func test_defaults_when_params_are_absent_or_mistyped() -> void:
	var a := _make()
	a.call("on_route_entered", {"aether_time_s": 9.0, "tier": 4, "camera_centre": Vector2(10, 10), "camera_zoom": 2.0})
	a.call("on_route_entered", {"tier": "3", "camera_centre": "here", "camera_zoom": -1.0})
	var b := a.get_node("%Backdrop") as AetherBackdrop
	var cam := a.get_node("%Camera") as Camera2D
	assert_float(b.time_s).is_equal(0.0)
	assert_int(b.tier).is_equal(1)
	assert_vector(b.camera_centre).is_equal(Vector2(320, 180))
	assert_float(b.camera_zoom).is_equal(1.0)
	assert_vector(cam.position).is_equal(Vector2(320, 180))
	assert_vector(cam.zoom).is_equal(Vector2.ONE)


func test_world_runs_and_frees() -> void:
	var a := _make()
	a.call("on_route_entered", {"aether_time_s": 3.0})
	for f in 4:
		await get_tree().process_frame
	var b := a.get_node("%Backdrop") as AetherBackdrop
	assert_float(b.time_s).is_greater(3.0)
	var view := a.get_node("%View") as AetherView
	assert_bool(view.world.use_hdr_2d).is_true()
	var look := a.get("look") as AetherLook
	assert_float(view.environment().glow_hdr_threshold).is_equal_approx(look.glow_threshold, 0.0001)


func test_aether_route_ships_and_the_gallery_stays_dev_only() -> void:
	var shipped := ResourceLoader.load(SHIPPED, "", ResourceLoader.CACHE_MODE_IGNORE) as RouteTable
	assert_bool(shipped.has_route(&"aether")).is_true()
	assert_str(shipped.path_for(&"aether")).is_equal(ARRIVAL)
	assert_bool(shipped.has_route(&"aether_gallery")).is_false()
	var dev := ResourceLoader.load(DEV, "", ResourceLoader.CACHE_MODE_IGNORE) as RouteTable
	assert_bool(dev.has_route(&"aether_gallery")).is_true()
