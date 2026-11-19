extends RefCounted
## Screenshot helpers. Headless has no renderer, so a capture there is recorded as skipped.
## No class_name: release builds may exclude core/automation.


## Returns {"ok": bool, "record": Dictionary, "detail": String}. Caller awaits frame_post_draw first.
static func take(tree: SceneTree, route_root: Node, name: String, target: String, out_dir: String) -> Dictionary:
	var rec := {"name": name, "target": target}
	if DisplayServer.get_name() == "headless":
		rec["skipped"] = "headless"
		return {"ok": true, "record": rec, "detail": ""}
	var vp: Viewport = tree.root
	if target == "arcade":
		var found: Node = route_root.get_node_or_null("%ScreenViewport") if route_root != null else null
		if not (found is Viewport):
			return {"ok": false, "record": rec, "detail": "no %ScreenViewport on the current route"}
		vp = found as Viewport
	var img: Image = vp.get_texture().get_image() if vp.get_texture() != null else null
	if img == null or img.is_empty():
		return {"ok": false, "record": rec, "detail": "capture returned an empty image"}
	DirAccess.make_dir_recursive_absolute(out_dir)
	var path := out_dir.path_join(name + ".png")
	var err := img.save_png(path)
	if err != OK:
		return {"ok": false, "record": rec, "detail": "could not write %s (error %d)" % [path, err]}
	rec["path"] = path
	rec["width"] = img.get_width()
	rec["height"] = img.get_height()
	return {"ok": true, "record": rec, "detail": ""}
