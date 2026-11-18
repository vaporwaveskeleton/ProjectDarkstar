class_name SaveEnvelope
extends RefCounted
## Versioned wrapper around one persisted block (TECH-001 §7.1).
## Payload holds invariant IDs and numbers only — never localized text.

const FORMAT := "darkstar_save"
## Bump when the payload layout changes, and add a migration in MIGRATIONS.
const SCHEMA_VERSION := 1

enum Status { OK, MISSING, CORRUPT, CHECKSUM_MISMATCH, NEWER_VERSION, WRONG_SLOT }

var slot: String = ""
var schema_version: int = SCHEMA_VERSION
var game_version: String = ""
var written_unix: int = 0
var payload: Dictionary = {}


static func create(p_slot: String, p_payload: Dictionary) -> SaveEnvelope:
	var e := SaveEnvelope.new()
	e.slot = p_slot
	e.payload = p_payload.duplicate(true)
	e.game_version = str(ProjectSettings.get_setting("application/config/version", "0.0.0"))
	e.written_unix = int(Time.get_unix_time_from_system())
	return e


## Checksum over the canonical form: payload is round-tripped through JSON first so ints that
## come back as floats on load hash the same way.
static func checksum(p: Dictionary) -> String:
	var canonical: Variant = JSON.parse_string(JSON.stringify(p, "", true, true))
	return JSON.stringify(canonical, "", true, true).sha256_text()


func to_json() -> String:
	return JSON.stringify({
		"format": FORMAT,
		"schema_version": schema_version,
		"slot": slot,
		"game_version": game_version,
		"written_unix": written_unix,
		"checksum": checksum(payload),
		"payload": payload,
	}, "\t", true, true)


## Parse and validate. Returns [Status, SaveEnvelope or null].
static func from_json(text: String, expected_slot: String) -> Array:
	if text.is_empty():
		return [Status.MISSING, null]
	var parsed: Variant = JSON.parse_string(text)
	if typeof(parsed) != TYPE_DICTIONARY:
		return [Status.CORRUPT, null]
	var d: Dictionary = parsed
	if d.get("format") != FORMAT or not d.has("payload") or typeof(d.payload) != TYPE_DICTIONARY:
		return [Status.CORRUPT, null]
	if str(d.get("slot", "")) != expected_slot:
		return [Status.WRONG_SLOT, null]
	var version := int(d.get("schema_version", 0))
	if version > SCHEMA_VERSION:
		return [Status.NEWER_VERSION, null]
	if checksum(d.payload) != str(d.get("checksum", "")):
		return [Status.CHECKSUM_MISMATCH, null]
	var e := SaveEnvelope.new()
	e.slot = expected_slot
	e.game_version = str(d.get("game_version", ""))
	e.written_unix = int(d.get("written_unix", 0))
	e.payload = migrate(d.payload, version)
	e.schema_version = SCHEMA_VERSION
	return [Status.OK, e]


## Upgrade a payload from `from_version` to SCHEMA_VERSION, one step at a time.
## Add `_migrate_1_to_2(p)` etc. here when SCHEMA_VERSION moves. Never edit a shipped step.
static func migrate(p: Dictionary, from_version: int) -> Dictionary:
	var out := p.duplicate(true)
	var v := maxi(from_version, 1)
	while v < SCHEMA_VERSION:
		match v:
			_:
				push_error("SaveEnvelope: no migration from schema %d" % v)
				return out
	return out
