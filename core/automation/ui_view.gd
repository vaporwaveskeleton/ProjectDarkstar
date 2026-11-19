extends RefCounted
## Resolves automation ids to nodes and reads allow-listed properties only.
##   UI controls:   <route>/ui/<UniqueName>   props: visible, enabled, focused, focusable
##   state ids:     the rows of STATE_IDS below
## Values returned are scalars or strings, never nodes or paths.
## No class_name: release builds may exclude core/automation.

const UI_PROPS: Array[String] = ["visible", "enabled", "focused", "focusable"]

## id -> {route, member, props}. `member` is "" for the route root, else a property of it that holds
## the object to read; `props` are the only readable names.
const STATE_IDS := {
	"cabinet/game": {"route": "cabinet", "member": "", "props": ["state", "stage_index", "demo"]},
	"cabinet/score": {"route": "cabinet", "member": "score", "props": ["score", "lives"]},
	"cabinet/record": {"route": "cabinet", "member": "record", "props": ["grubs_destroyed", "glass_mined", "charges_thrown", "glass_carried"]},
	"sector/vigil": {"route": "sector", "member": "", "props": ["vigil_x", "vigil_y", "vigil_speed", "hull_max_hp", "camera_x", "compass_markers", "camera_gap"]},
	"sector/field": {"route": "sector", "member": "", "props": ["geodes_alive", "geodes_detonated", "shards_free", "charges", "score"]},
}

var _route_host: Node


func _init(route_host: Node) -> void:
	_route_host = route_host


## The current routed scene root, or null.
func route_root() -> Node:
	if _route_host == null or _route_host.get_child_count() == 0:
		return null
	return _route_host.get_child(0)


## Returns {"ok": bool, "node": Node, "error": String}. For state ids `node` is the object to read.
func resolve(id: String) -> Dictionary:
	var root := route_root()
	if root == null:
		return _err("no route is mounted")
	var parts := id.split("/")
	if STATE_IDS.has(id):
		var row: Dictionary = STATE_IDS[id]
		if str(SceneRouter.current_route) != str(row.route):
			return _err("id '%s' needs route '%s' (current: '%s')" % [id, row.route, SceneRouter.current_route])
		if str(row.member) == "":
			return {"ok": true, "node": root, "error": ""}
		var obj: Variant = root.get(str(row.member))
		if obj is Object:
			return {"ok": true, "node": obj as Object, "error": ""}
		return _err("'%s' is not available on this route" % id)
	if parts.size() != 3 or parts[1] != "ui":
		return _err("unknown id '%s'" % id)
	if parts[0] != str(SceneRouter.current_route):
		return _err("id '%s' is not on the current route '%s'" % [id, SceneRouter.current_route])
	var found: Node = root.get_node_or_null("%" + parts[2])
	if found == null:
		var stack := root.get_node_or_null("%Overlays")
		if stack != null and stack.has_method("top"):
			var top: Variant = stack.call("top")
			if top is Node:
				found = (top as Node).get_node_or_null("%" + parts[2])
	if found == null:
		return _err("no control '%s' under route '%s'" % [parts[2], parts[0]])
	return {"ok": true, "node": found, "error": ""}


## Returns {"ok": bool, "value": Variant, "error": String}.
func read(id: String, prop: String) -> Dictionary:
	var r := resolve(id)
	if not r.ok:
		return {"ok": false, "value": null, "error": r.error}
	var node: Object = r.node
	if STATE_IDS.has(id):
		if not (STATE_IDS[id].props as Array).has(prop):
			return _err("property '%s' is not readable on '%s'" % [prop, id])
		if id == "cabinet/game" and prop == "state":
			return {"ok": true, "value": enum_name_of(node, "State", int(node.get("state"))), "error": ""}
		return {"ok": true, "value": node.get(prop), "error": ""}
	if not UI_PROPS.has(prop):
		return _err("property '%s' is not readable on UI ids (allowed: %s)" % [prop, ", ".join(UI_PROPS)])
	if not (node is Control):
		return _err("'%s' is not a Control" % id)
	var c := node as Control
	match prop:
		"visible":
			return {"ok": true, "value": c.is_visible_in_tree(), "error": ""}
		"enabled":
			return {"ok": true, "value": (not (c as BaseButton).disabled) if c is BaseButton else true, "error": ""}
		"focused":
			return {"ok": true, "value": c.has_focus(), "error": ""}
	return {"ok": true, "value": c.focus_mode != Control.FOCUS_NONE, "error": ""}


## Lower-case name of an enum member, found through the node's script constants.
static func enum_name_of(node: Object, enum_name: String, value: int) -> String:
	var script := node.get_script() as Script
	if script != null:
		var consts := script.get_script_constant_map()
		if consts.has(enum_name):
			var e: Dictionary = consts[enum_name]
			for k: Variant in e.keys():
				if int(e[k]) == value:
					return str(k).to_lower()
	return str(value)


func _err(msg: String) -> Dictionary:
	return {"ok": false, "node": null, "value": null, "error": msg}
