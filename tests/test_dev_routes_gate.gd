extends GdUnitTestSuite
## Dev-only routes (architect ruling, TECH-001 doc pass pending): the shipped route table never
## carries dev routes; SceneRouter.merge_routes adds but never overwrites; Boot merges only in
## editor / automation builds.

const BootScript := preload("res://scenes/boot/boot.gd")
const DEV_TABLE := "res://data/routes/dev_route_table.tres"

var _saved: RouteTable


func before_test() -> void:
	_saved = SceneRouter.table


func after_test() -> void:
	SceneRouter.table = _saved


func test_shipped_table_has_no_dev_route() -> void:
	var text := FileAccess.get_file_as_string(SceneRouter.TABLE_PATH)
	assert_bool(text.contains("aether_gallery")).is_false()
	var fresh := ResourceLoader.load(SceneRouter.TABLE_PATH, "", ResourceLoader.CACHE_MODE_IGNORE) as RouteTable
	assert_bool(fresh.has_route(&"aether_gallery")).is_false()


func test_dev_table_points_at_a_loadable_gallery() -> void:
	var dev := load(DEV_TABLE) as RouteTable
	assert_bool(dev.has_route(&"aether_gallery")).is_true()
	assert_object(load(dev.path_for(&"aether_gallery")) as PackedScene).is_not_null()


func test_merge_adds_new_ids_and_never_overwrites() -> void:
	var base := RouteTable.new()
	base.routes = {&"attract": "res://scenes/attract/attract_mode.tscn"}
	SceneRouter.table = base
	var extra := RouteTable.new()
	extra.routes = {&"attract": "res://elsewhere.tscn", &"aether_gallery": "res://scenes/dev/aether_gallery/aether_gallery.tscn"}
	assert_int(SceneRouter.merge_routes(extra)).is_equal(1)
	assert_str(SceneRouter.table.path_for(&"attract")).is_equal("res://scenes/attract/attract_mode.tscn")
	assert_bool(SceneRouter.table.has_route(&"aether_gallery")).is_true()
	# the original table object is not mutated (a copy was taken)
	assert_bool(base.has_route(&"aether_gallery")).is_false()
	# merging the same routes again adds nothing
	assert_int(SceneRouter.merge_routes(extra)).is_equal(0)


func test_dev_build_gate_reads_feature_tags() -> void:
	assert_bool(BootScript._is_dev_build(func(_t: String) -> bool: return false)).is_false()
	assert_bool(BootScript._is_dev_build(func(t: String) -> bool: return t == "editor")).is_true()
	assert_bool(BootScript._is_dev_build(func(t: String) -> bool: return t == "automation_qa")).is_true()
	assert_bool(BootScript._is_dev_build(func(t: String) -> bool: return t == "release")).is_false()
