extends Node
## Boot — the main scene and the permanent route host (TECH-001 §2.1).
## Owns: the RouteHost the router mounts top-level scenes into, and the transition curtain.
## Does not own any game state.
##
## `-- --smoke` on the command line runs the boot smoke path: attract -> cabinet (Act 0) -> quit(0).

const TRANSITION_S := 0.2   ## ✱ inside the 150–300 ms UI transition rule (UI-001 §4)
const SMOKE_FRAMES := 30    ## ✱ frames to run the cabinet before declaring the smoke test passed

@onready var _route_host: Node = %RouteHost
@onready var _curtain: ColorRect = %Curtain

const AUTOMATION_GATE := "res://core/automation/automation_gate.gd"
## Dev-only routes (e.g. the Aether gallery). Release builds exclude this file and scenes/dev/.
const DEV_ROUTE_TABLE := "res://data/routes/dev_route_table.tres"
const DEV_FEATURES: Array[String] = ["editor", "automation_dev", "automation_qa"]

## GdUnit injects a prepared scenario runner before add_child (dev/QA only).
var automation_runner: Node = null
var _smoke := false


func _ready() -> void:
	_smoke = OS.get_cmdline_user_args().has("--smoke")
	_curtain.color.a = 1.0
	SceneRouter.register_host(self)
	SceneRouter.route_changed.connect(_on_route_changed)
	_merge_dev_routes()
	var runner: Node = automation_runner if automation_runner != null else _make_automation_runner()
	if runner != null:
		add_child(runner)
	# The first route of a launch is the Cabinet switching on (attract plays its power-on test).
	# Dev builds may start elsewhere with `-- --route=<id>` (LaunchRoute); `--smoke` keeps its path.
	var first: StringName = SceneRouter.table.initial_route
	if not _smoke:
		first = LaunchRoute.resolve(OS.get_cmdline_user_args(), SceneRouter.table, LaunchRoute.is_dev_build())
	var params := {"power_on": not _smoke and runner == null} if first == SceneRouter.table.initial_route else {}
	SceneRouter.go_to(first, params)


func _has_scenario_arg() -> bool:
	for a in OS.get_cmdline_user_args():
		if a.begins_with("--scenario=") or a.begins_with("--record=") or a == "--automation-caps":
			return true
	return false


## `-- --scenario=<id>` (or `--record=<id>`): dev/QA builds only (D-09: in-process, no sockets). Null otherwise.
func _make_automation_runner() -> Node:
	if not _has_scenario_arg():
		return null
	if not _is_dev_build():
		print("automation: not available in this build")
		return null
	if not ResourceLoader.exists(AUTOMATION_GATE):
		return null
	return (load(AUTOMATION_GATE) as GDScript).call("create_node", OS.get_cmdline_user_args()) as Node


## Editor, dev or QA build. `has_feature` is injectable so tests can fake a release build.
static func _is_dev_build(has_feature: Callable = OS.has_feature) -> bool:
	for tag in DEV_FEATURES:
		if bool(has_feature.call(tag)):
			return true
	return false


## Dev builds only: add the dev routes before the first go_to. The build check comes first, then
## the existence check, so a release build (which excludes the file) never tries to load it.
func _merge_dev_routes() -> void:
	if not _is_dev_build():
		return
	if not ResourceLoader.exists(DEV_ROUTE_TABLE):
		return
	var extra := load(DEV_ROUTE_TABLE) as RouteTable
	if extra != null:
		SceneRouter.merge_routes(extra)


func _exit_tree() -> void:
	SceneRouter.unregister_host(self)


## Replace the current top-level scene. Removes the old scene and adds the new one in one call, so
## a `skip_curtain` route change (SceneRouter.go_to) swaps them within a single frame.
func mount(scene: Node) -> void:
	for child in _route_host.get_children():
		_route_host.remove_child(child)
		child.queue_free()
	_route_host.add_child(scene)


func transition_out() -> void:
	await _fade_to(1.0)


func transition_in() -> void:
	await _fade_to(0.0)


func _fade_to(alpha: float) -> void:
	if SettingsService.get_value(&"reduced_motion") or is_equal_approx(_curtain.color.a, alpha):
		_curtain.color.a = alpha
		return
	var tw := create_tween()
	tw.tween_property(_curtain, "color:a", alpha, TRANSITION_S)
	await tw.finished


## `-- --smoke-frames=N` lets a capture run longer than the smoke default.
func _smoke_frames() -> int:
	for a in OS.get_cmdline_user_args():
		if a.begins_with("--smoke-frames="):
			return int(a.trim_prefix("--smoke-frames="))
	return SMOKE_FRAMES


func _on_route_changed(route_id: StringName) -> void:
	if not _smoke:
		return
	match route_id:
		&"attract":
			SceneRouter.go_to(&"cabinet")
		&"cabinet":
			for i in _smoke_frames():
				await get_tree().physics_frame
			print("BOOT_SMOKE: reached route 'cabinet'")
			get_tree().quit(0)
