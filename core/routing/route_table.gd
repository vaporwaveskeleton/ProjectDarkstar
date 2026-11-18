class_name RouteTable
extends Resource
## Route id -> scene path. Scenes are addressed by stable ids, never by path, outside this file.

@export var routes: Dictionary = {}   # StringName -> String (res:// path to a .tscn)
@export var initial_route: StringName = &"attract"


func has_route(id: StringName) -> bool:
	return routes.has(id)


func path_for(id: StringName) -> String:
	return str(routes.get(id, ""))
