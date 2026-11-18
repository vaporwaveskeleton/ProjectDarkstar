class_name FakeRouteHost
extends Node
## Test double for Boot's route host. Lets UI tests trigger SceneRouter without replacing the
## GdUnit runner scene. Mounted scenes are recorded and freed immediately.

var mounted_routes: Array[String] = []


func mount(scene: Node) -> void:
	mounted_routes.append(scene.scene_file_path)
	scene.queue_free()


static func install(suite: Node) -> FakeRouteHost:
	var host := FakeRouteHost.new()
	suite.add_child(host)
	SceneRouter.register_host(host)
	return host


static func uninstall(host: FakeRouteHost) -> void:
	SceneRouter.unregister_host(host)
	SceneRouter.is_busy = false
	if is_instance_valid(host):
		host.queue_free()
