class_name RunPayload
extends RefCounted
## Typed reads for the RunSession save payloads (TECH-001 §4.2a, §7.2): ids and numbers only.
## A JSON round trip turns ints into floats and StringNames into Strings, so reads accept both.
## Every read returns `ok == false` through the `errors` array instead of guessing a value.

## True for a value a payload may hold: a number, a bool, an id (String / StringName), or an
## Array / Dictionary made only of those (keys: ids).
static func is_plain(v: Variant) -> bool:
	match typeof(v):
		TYPE_INT, TYPE_FLOAT, TYPE_BOOL, TYPE_STRING, TYPE_STRING_NAME:
			return true
		TYPE_ARRAY:
			for e: Variant in (v as Array):
				if not is_plain(e):
					return false
			return true
		TYPE_DICTIONARY:
			var d: Dictionary = v
			for k: Variant in d.keys():
				if typeof(k) != TYPE_STRING and typeof(k) != TYPE_STRING_NAME:
					return false
				if not is_plain(d[k]):
					return false
			return true
	return false


## Keys of `d` that are not in `known` (as Strings).
static func unknown_keys(d: Dictionary, known: PackedStringArray) -> PackedStringArray:
	var out := PackedStringArray()
	for k: Variant in d.keys():
		if not known.has(str(k)):
			out.append(str(k))
	return out


static func read_int(d: Dictionary, key: String, fallback: int, errors: Array[String]) -> int:
	if not d.has(key):
		return fallback
	var v: Variant = d[key]
	if typeof(v) == TYPE_INT:
		return int(v)
	if typeof(v) == TYPE_FLOAT and is_equal_approx(float(v), roundf(float(v))):
		return int(roundf(float(v)))
	errors.append("%s is not an int" % key)
	return fallback


static func read_float(d: Dictionary, key: String, fallback: float, errors: Array[String]) -> float:
	if not d.has(key):
		return fallback
	var v: Variant = d[key]
	if typeof(v) == TYPE_INT or typeof(v) == TYPE_FLOAT:
		return float(v)
	errors.append("%s is not a number" % key)
	return fallback


static func read_bool(d: Dictionary, key: String, fallback: bool, errors: Array[String]) -> bool:
	if not d.has(key):
		return fallback
	var v: Variant = d[key]
	if typeof(v) == TYPE_BOOL:
		return bool(v)
	errors.append("%s is not a bool" % key)
	return fallback


static func read_id(d: Dictionary, key: String, fallback: StringName, errors: Array[String]) -> StringName:
	if not d.has(key):
		return fallback
	var v: Variant = d[key]
	if typeof(v) == TYPE_STRING or typeof(v) == TYPE_STRING_NAME:
		return StringName(str(v))
	errors.append("%s is not an id" % key)
	return fallback


static func read_ids(d: Dictionary, key: String, errors: Array[String]) -> Array[StringName]:
	var out: Array[StringName] = []
	if not d.has(key):
		return out
	var v: Variant = d[key]
	if typeof(v) != TYPE_ARRAY:
		errors.append("%s is not an id list" % key)
		return out
	for e: Variant in (v as Array):
		if typeof(e) != TYPE_STRING and typeof(e) != TYPE_STRING_NAME:
			errors.append("%s holds a non-id" % key)
			return []
		out.append(StringName(str(e)))
	return out


## Dictionary[id -> int] (the corruption map).
static func read_id_ints(d: Dictionary, key: String, errors: Array[String]) -> Dictionary:
	var out: Dictionary = {}
	if not d.has(key):
		return out
	var v: Variant = d[key]
	if typeof(v) != TYPE_DICTIONARY:
		errors.append("%s is not an id map" % key)
		return out
	var src: Dictionary = v
	for k: Variant in src.keys():
		if typeof(k) != TYPE_STRING and typeof(k) != TYPE_STRING_NAME:
			errors.append("%s has a non-id key" % key)
			return {}
		out[StringName(str(k))] = read_int({"v": src[k]}, "v", 0, errors)
	return out


## Array[StringName] -> Array[String] for a payload.
static func ids_out(ids: Array[StringName]) -> Array:
	var out: Array = []
	for i in ids:
		out.append(String(i))
	return out
