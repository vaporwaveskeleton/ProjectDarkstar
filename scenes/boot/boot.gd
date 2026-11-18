extends Node
## Boot — the main scene and the permanent route host (TECH-001 §2.1).
## Owns: the RouteHost the router mounts top-level scenes into, and the transition curtain.
## Does not own any game state.
##
## `-- --smoke` on the command line runs the boot smoke path: attract -> sector -> quit(0).

const TRANSITION_S := 0.2   ## ✱ inside the 150–300 ms UI transition rule (UI-001 §4)
const SMOKE_FRAMES := 30    ## ✱ frames to run the sector before declaring the smoke test passed

@onready var _route_host: Node = %RouteHost
@onready var _curtain: ColorRect = %Curtain

var _smoke := false


func _ready() -> void:
	_smoke = OS.get_cmdline_user_args().has("--smoke")
	_curtain.color.a = 1.0
	SceneRouter.register_host(self)
	SceneRouter.route_changed.connect(_on_route_changed)
	SceneRouter.go_to(SceneRouter.table.initial_route)


func _exit_tree() -> void:
	SceneRouter.unregister_host(self)


## Replace the current top-level scene.
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


func _on_route_changed(route_id: StringName) -> void:
	if not _smoke:
		return
	match route_id:
		&"attract":
			SceneRouter.go_to(&"sector")
		&"sector":
			for i in SMOKE_FRAMES:
				await get_tree().physics_frame
			print("BOOT_SMOKE: reached route 'sector'")
			get_tree().quit(0)
