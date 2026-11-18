class_name MemorySaveBackend
extends SaveBackend
## In-memory backend for tests. Mirrors FileSaveBackend's .bak behaviour.

var files: Dictionary = {}
var backups: Dictionary = {}
var fail_writes: bool = false


func write_text(key: String, text: String) -> Error:
	if fail_writes:
		return ERR_FILE_CANT_WRITE
	if files.has(key):
		backups[key] = files[key]
	files[key] = text
	return OK


func read_text(key: String) -> String:
	return files.get(key, "")


func read_backup(key: String) -> String:
	return backups.get(key, "")


func exists(key: String) -> bool:
	return files.has(key)


func remove(key: String) -> Error:
	files.erase(key)
	backups.erase(key)
	return OK
