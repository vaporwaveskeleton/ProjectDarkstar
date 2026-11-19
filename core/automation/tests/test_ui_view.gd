extends GdUnitTestSuite
## UiView: automation ids resolve against the current route root; only allow-listed props read.

const UiView := preload("res://core/automation/ui_view.gd")


class _Game extends Node:
	enum State { INTRO, PLAY, GAME_OVER }
	var state: int = State.PLAY
	var stage_index := 2
	var demo := false
	var secret := 7


var host: Node
var root: Control
var view: RefCounted
var _prev_route: StringName


func before_test() -> void:
	_prev_route = SceneRouter.current_route
	SceneRouter.current_route = &"fake"
	host = Node.new()
	add_child(host)
	root = Control.new()
	host.add_child(root)
	_unique(root, Button.new(), "Go")
	var off := _unique(root, Button.new(), "Off") as Button
	off.disabled = true
	var plain := _unique(root, Label.new(), "Caption")
	plain.visible = false
	var stack := _unique(root, ScreenStack.new(), "Overlays") as ScreenStack
	var screen := Screen.new()
	stack.push(screen)
	_unique(screen, Button.new(), "Deep")
	view = UiView.new(host)


func after_test() -> void:
	SceneRouter.current_route = _prev_route
	host.free()


func _unique(parent: Node, child: Node, uname: String) -> Node:
	child.name = uname
	parent.add_child(child)
	child.unique_name_in_owner = true
	child.owner = parent.owner if parent.owner != null else parent
	return child


func test_resolves_unique_named_controls() -> void:
	assert_bool(view.read("fake/ui/Go", "visible").value).is_true()
	assert_bool(view.read("fake/ui/Go", "enabled").value).is_true()
	assert_bool(view.read("fake/ui/Go", "focusable").value).is_true()
	assert_bool(view.read("fake/ui/Go", "focused").value).is_false()
	assert_bool(view.read("fake/ui/Off", "enabled").value).is_false()
	assert_bool(view.read("fake/ui/Caption", "visible").value).is_false()
	assert_bool(view.read("fake/ui/Caption", "enabled").value).is_true()


func test_falls_back_to_the_top_overlay_screen() -> void:
	var r: Dictionary = view.read("fake/ui/Deep", "visible")
	assert_bool(r.ok).override_failure_message(str(r.error)).is_true()


func test_unknown_ids_fail_plainly() -> void:
	assert_str(view.read("fake/ui/Nope", "visible").error).contains("no control")
	assert_str(view.read("other/ui/Go", "visible").error).contains("not on the current route")
	assert_str(view.read("garbage", "visible").error).contains("unknown id")
	assert_str(view.read("cabinet/game", "state").error).contains("needs route")


func test_allow_list_rejects_other_props() -> void:
	var r: Dictionary = view.read("fake/ui/Go", "text")
	assert_bool(r.ok).is_false()
	assert_str(r.error).contains("not readable")
	assert_bool(view.read("fake/ui/Go", "name").ok).is_false()


func test_state_ids_read_through_the_enum_map() -> void:
	SceneRouter.current_route = &"cabinet"
	for c in host.get_children():
		host.remove_child(c)
		c.free()
	var game := _Game.new()
	host.add_child(game)
	assert_str(view.read("cabinet/game", "state").value).is_equal("play")
	assert_int(view.read("cabinet/game", "stage_index").value).is_equal(2)
	assert_bool(view.read("cabinet/game", "demo").value).is_false()
	assert_bool(view.read("cabinet/game", "secret").ok).is_false()
