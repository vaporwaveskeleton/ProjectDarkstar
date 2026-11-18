class_name SaveBackend
extends RefCounted
## Storage interface used by SaveService. Swap implementations for tests or Steam Cloud.
## Every method works on a logical key (e.g. "profile"), never a player-visible name.

func write_text(_key: String, _text: String) -> Error:
	return ERR_UNAVAILABLE


## Returns "" when the key is missing.
func read_text(_key: String) -> String:
	return ""


## Returns the previous good copy, "" if none.
func read_backup(_key: String) -> String:
	return ""


func exists(_key: String) -> bool:
	return false


func remove(_key: String) -> Error:
	return ERR_UNAVAILABLE
