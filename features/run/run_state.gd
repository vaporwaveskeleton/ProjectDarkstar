class_name RunState
extends RefCounted
## Run-class state (LOOP-001 §2; TECH-001 §4.2, §4.2a): New Vigil → death / win / abandon / ninth sky.
## Saved in the `run` slot at Seam boundaries only (`seam_boundary`), and at run end (`run_end`, Q-T139).
## Never changes mid-Seam: the sector nodes are the live authority until `end_seam` writes back.

const KEYS := ["seam_index", "seed", "sigils", "relics", "pact", "charges", "composure", "ember_in_run"]

## 0 = no run; 1..seams_per_run while a run is live.
var seam_index: int = 0
## The run's RunSeed value (payload key `seed`; the field avoids shadowing the built-in `seed()`).
var seed_value: int = 0
var sigils: Array[StringName] = []
var relics: Array[StringName] = []
var pact: StringName = &""
var charges: int = 0
## < 0 = not set yet: the sector's Composure keeps its own start value (SYS-001 §1.5, Q-T118).
var composure: float = -1.0
var ember_in_run: int = 0


func is_active() -> bool:
	return seam_index > 0


func to_payload() -> Dictionary:
	return {
		"seam_index": seam_index,
		"seed": seed_value,
		"sigils": RunPayload.ids_out(sigils),
		"relics": RunPayload.ids_out(relics),
		"pact": String(pact),
		"charges": charges,
		"composure": composure,
		"ember_in_run": ember_in_run,
	}


## Null when `d` holds an unknown key or a value of the wrong type.
static func from_payload(d: Dictionary) -> RunState:
	if not RunPayload.unknown_keys(d, PackedStringArray(KEYS)).is_empty():
		return null
	var errors: Array[String] = []
	var r := RunState.new()
	r.seam_index = RunPayload.read_int(d, "seam_index", 0, errors)
	r.seed_value = RunPayload.read_int(d, "seed", 0, errors)
	r.sigils = RunPayload.read_ids(d, "sigils", errors)
	r.relics = RunPayload.read_ids(d, "relics", errors)
	r.pact = RunPayload.read_id(d, "pact", &"", errors)
	r.charges = RunPayload.read_int(d, "charges", 0, errors)
	r.composure = RunPayload.read_float(d, "composure", -1.0, errors)
	r.ember_in_run = RunPayload.read_int(d, "ember_in_run", 0, errors)
	if not errors.is_empty() or r.seam_index < 0:
		return null
	return r
