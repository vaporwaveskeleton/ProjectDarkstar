class_name TunableRegistry
extends RefCounted
## Load-time table that resolves every `ds_` key to (resource, property) (TECH-001 §3.2).
## Not an autoload: build one where needed, or call `scan()` from tests and lints.

const DATA_ROOT := "res://data"
const KEY_PATTERN := "^ds_[a-z0-9_]+(\\.[a-z0-9_]+)+$"

var _entries: Dictionary = {}   # key -> {"resource": TunableResource, "property": String, "path": String}
var errors: PackedStringArray = PackedStringArray()


## Scan `root` recursively for TunableResource .tres files and index their keys.
func scan(root: String = DATA_ROOT) -> TunableRegistry:
	_entries.clear()
	errors.clear()
	var regex := RegEx.create_from_string(KEY_PATTERN)
	for path in _list_tres(root):
		var res := ResourceLoader.load(path)
		if not (res is TunableResource):
			continue
		var t := res as TunableResource
		if not t.ds_namespace.begins_with("ds_"):
			errors.append("%s: ds_namespace must start with 'ds_'" % path)
			continue
		var keys := t.ds_keys()
		for key in keys:
			if regex.search(key) == null:
				errors.append("%s: malformed key '%s'" % [path, key])
			elif _entries.has(key):
				errors.append("%s: duplicate key '%s' (also in %s)" % [path, key, _entries[key].path])
			else:
				_entries[key] = {"resource": t, "property": keys[key], "path": path}
	return self


func has_key(key: String) -> bool:
	return _entries.has(key)


func get_value(key: String) -> Variant:
	if not _entries.has(key):
		push_error("TunableRegistry: unknown key %s" % key)
		return null
	var e: Dictionary = _entries[key]
	return (e.resource as Resource).get(e.property)


func keys() -> PackedStringArray:
	return PackedStringArray(_entries.keys())


static func _list_tres(root: String) -> PackedStringArray:
	var out := PackedStringArray()
	var dir := DirAccess.open(root)
	if dir == null:
		return out
	dir.list_dir_begin()
	var name := dir.get_next()
	while name != "":
		if not name.begins_with("."):
			var full := root.path_join(name)
			if dir.current_is_dir():
				out.append_array(_list_tres(full))
			elif name.ends_with(".tres"):
				out.append(full)
			elif name.ends_with(".tres.remap"):   # exported builds
				out.append(full.trim_suffix(".remap"))
		name = dir.get_next()
	dir.list_dir_end()
	return out
