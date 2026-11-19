extends Node
## SceneRouter (autoload) — why global: exactly one top-level scene is active at a time and every
## screen must be able to request a change without knowing who owns the tree. TECH-001 §2.8.
##
## Top-level scenes are mounted under a *host* (Boot's %RouteHost). Boot stays alive for the whole
## session, so the transition curtain and the error fallback always exist. Without a host (e.g. a
## scene run directly from the editor) the router falls back to SceneTree.change_scene_to_packed.
## Overlays (pause, settings, confirm) are NOT routes: they are pushed on a ScreenStack.

signal route_changed(route_id: StringName)
signal route_failed(route_id: StringName, reason: StringName)

const TABLE_PATH := "res://data/routes/route_table.tres"

var table: RouteTable
var current_route: StringName = &""
var is_busy: bool = false
var _host: Node


func _ready() -> void:
	table = load(TABLE_PATH) as RouteTable
	if table == null:
		push_error("SceneRouter: route table missing at %s" % TABLE_PATH)


## Add the routes of `extra` that are not in the table yet; returns how many were added.
## Never overwrites: an id that already points at a different scene is refused (warning, skipped);
## an id already present with the same path is skipped silently (a second Boot merging again).
## The loaded route_table.tres is copied before the first change, so the shipped resource in the
## cache is never mutated. Knows nothing about dev builds; Boot decides whether to call it.
func merge_routes(extra: RouteTable) -> int:
	if extra == null or table == null:
		return 0
	var added: Dictionary = {}
	for id: Variant in extra.routes.keys():
		var key := StringName(str(id))
		var path := extra.path_for(key)
		if table.has_route(key):
			if table.path_for(key) != path:
				push_warning("SceneRouter: merge refused to overwrite route %s" % key)
			continue
		added[key] = path
	if added.is_empty():
		return 0
	table = table.duplicate(true) as RouteTable
	for key: Variant in added.keys():
		table.routes[key] = added[key]
	return added.size()


func register_host(host: Node) -> void:
	_host = host


func unregister_host(host: Node) -> void:
	if _host == host:
		_host = null


func has_host() -> bool:
	return is_instance_valid(_host)


## Request a route change. Repeated requests while a change is in flight are ignored (returns false).
## The change happens on a later frame so the calling button/scene is never freed mid-callback.
## `params` go to the new scene's `on_route_entered(params)`. One key belongs to the router:
## `"skip_curtain": true` skips the host's transition_out and transition_in, so the old scene's
## last frame is followed directly by the new scene's first (remove, mount and enter happen in
## one deferred call, one frame). For hand-offs that are their own transition, e.g. Act 0 into
## the Aether (TECH-001 §2.1, Q-T60). Anything but a bool `true` keeps the curtain.
func go_to(route_id: StringName, params: Dictionary = {}) -> bool:
	if is_busy:
		return false
	if table == null or not table.has_route(route_id):
		push_error("SceneRouter: unknown route %s" % route_id)
		route_failed.emit(route_id, &"unknown_route")
		return false
	is_busy = true
	_perform.call_deferred(route_id, params)
	return true


## True only when `params` holds "skip_curtain" (String or StringName key) set to the bool `true`.
static func skips_curtain(params: Dictionary) -> bool:
	for key: Variant in ["skip_curtain", &"skip_curtain"]:
		if params.has(key):
			var v: Variant = params[key]
			if typeof(v) == TYPE_BOOL and bool(v):
				return true
	return false


func _perform(route_id: StringName, params: Dictionary) -> void:
	var packed := load(table.path_for(route_id)) as PackedScene
	if packed == null:
		push_error("SceneRouter: could not load scene for route %s" % route_id)
		is_busy = false
		route_failed.emit(route_id, &"load_failed")
		return
	if has_host():
		var curtain := not skips_curtain(params)
		if curtain and _host.has_method("transition_out"):
			await _host.transition_out()
		var scene := packed.instantiate()
		_host.mount(scene)
		if scene.has_method("on_route_entered"):
			scene.on_route_entered(params)
		current_route = route_id
		if curtain and _host.has_method("transition_in"):
			await _host.transition_in()
	else:
		var err := get_tree().change_scene_to_packed(packed)
		if err != OK:
			is_busy = false
			route_failed.emit(route_id, &"load_failed")
			return
		current_route = route_id
	is_busy = false
	route_changed.emit(route_id)
