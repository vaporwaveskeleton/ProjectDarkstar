class_name FileSaveBackend
extends SaveBackend
## Writes JSON files under user://saves/. Atomic: write .tmp, keep the old file as .bak, rename.

var root: String = "user://saves"


func _init(p_root: String = "user://saves") -> void:
	root = p_root


func _path(key: String) -> String:
	return root.path_join("%s.json" % key)


func write_text(key: String, text: String) -> Error:
	var err := DirAccess.make_dir_recursive_absolute(root)
	if err != OK:
		return err
	var path := _path(key)
	var tmp := path + ".tmp"
	var f := FileAccess.open(tmp, FileAccess.WRITE)
	if f == null:
		return FileAccess.get_open_error()
	f.store_string(text)
	f.flush()
	f.close()
	if FileAccess.file_exists(path):
		var bak := path + ".bak"
		if FileAccess.file_exists(bak):
			DirAccess.remove_absolute(bak)
		err = DirAccess.rename_absolute(path, bak)
		if err != OK:
			return err
	return DirAccess.rename_absolute(tmp, path)


func read_text(key: String) -> String:
	return _read(_path(key))


func read_backup(key: String) -> String:
	return _read(_path(key) + ".bak")


func exists(key: String) -> bool:
	return FileAccess.file_exists(_path(key))


func remove(key: String) -> Error:
	var path := _path(key)
	for p in [path, path + ".bak", path + ".tmp"]:
		if FileAccess.file_exists(p):
			DirAccess.remove_absolute(p)
	return OK


static func _read(path: String) -> String:
	if not FileAccess.file_exists(path):
		return ""
	return FileAccess.get_file_as_string(path)
