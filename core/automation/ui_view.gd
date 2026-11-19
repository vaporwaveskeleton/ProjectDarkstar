extends RefCounted
## Resolves UI automation ids to nodes and reads allow-listed properties only.
##   UI controls:   <route>/ui/<UniqueName>   props: visible, enabled, focused, focusable
## Game-state ids of routes that have a probe (cabinet/...) belong to that probe (see scenario_runner.gd).
##   state ids:     the rows of STATE_IDS below (routes without a probe yet, e.g. sector)
## Values returned are scalars or strings, never nodes or paths.
## No class_name: release builds may exclude core/automation.

const UI_PROPS: Array[String] = ["visible", "enabled", "focused", "focusable"]

## id -> {route, member, props}. `member` is "" for the route root, else a property of it that holds
## the object to read; `props` are the only readable names.
const STATE_IDS := {
	"sector/vigil": {"route": "sector", "member": "", "props": ["vigil_x", "vigil_y", "vigil_speed", "hull_max_hp", "camera_x", "compass_markers", "camera_gap", "facing_deg", "aim_x", "aim_y", "composure", "composure_band"]},
	"sector/field": {"route": "sector", "member": "", "props": ["geodes_alive", "geodes_detonated", "shards_free", "shards_live", "charges", "score", "charges_in_flight", "charges_lost", "charges_hit", "charges_guttered", "dry_fires"]},
	"sector/choir": {"route": "sector", "member": "", "props": ["grubs_alive", "grubs_carrying", "segments", "deposited_shards", "sepulchre_complete"]},
	# Route-independent: read from the RunSession autoload (TECH-001 §4.2a), on any route.
	"run/session": {"route": "*", "autoload": "RunSession", "props": ["ember", "act0_banked", "hourglass_left", "skies_dark", "seam_index", "clock_paused"]},
}

var _route_host: Node


func _init(route_host: Node) -> void:
	_route_host = route_host


## The current routed scene root, or null.
func route_root() -> Node:
	if _route_host == null or _route_host.get_child_count() == 0:
		return null
	return _route_host.get_child(0)


## Returns {"ok": bool, "node": Node, "error": String}.
func resolve(id: String) -> Dictionary:
	if STATE_IDS.has(id) and (STATE_IDS[id] as Dictionary).has("autoload"):
		var tree := Engine.get_main_loop() as SceneTree
		var auto: Node = tree.root.get_node_or_null(str(STATE_IDS[id].autoload)) if tree else null
		if auto == null:
			return _err("'%s' is not available (no %s)" % [id, STATE_IDS[id].autoload])
		return {"ok": true, "node": auto, "error": ""}
	var root := route_root()
	if root == null:
		return _err("no route is mounted")
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
	var parts := id.split("/")
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


## Visible, focusable Controls with a scene-unique name under the route root (overlay screens
## included): [{id, enabled, focused}], in tree order, without duplicates.
func list_focusable() -> Array:
	var out: Array = []
	var root := route_root()
	if root == null:
		return out
	var route := str(SceneRouter.current_route)
	var seen := {}
	var stack: Array[Node] = [root]
	while not stack.is_empty():
		var n: Node = stack.pop_back()
		var kids := n.get_children()
		kids.reverse()
		for k in kids:
			stack.append(k)
		if n is Control and n.unique_name_in_owner:
			var c := n as Control
			var id := "%s/ui/%s" % [route, c.name]
			if not seen.has(id) and c.is_visible_in_tree() and c.focus_mode != Control.FOCUS_NONE:
				seen[id] = true
				out.append({"id": id, "enabled": (not (c as BaseButton).disabled) if c is BaseButton else true, "focused": c.has_focus()})
	return out


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
