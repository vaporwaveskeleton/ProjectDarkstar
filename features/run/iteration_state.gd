class_name IterationState
extends RefCounted
## Iteration-class state (LOOP-001 §2; TECH-001 §4.2, §4.2a): first Ruins visit → ninth sky.
## Saved in the `iteration` slot at `ruins_entry` and at run end (`run_end`, Q-T139).

const KEYS := ["started", "loop_min_left", "skies_dark", "hunger", "corruption"]

## False until the first Ruins visit (SYS-001 §6: Act 0 never ticks the Hourglass).
var started: bool = false
var loop_min_left: float = 0.0
## 0..skies; never goes down inside an Iteration (a win refund adds time, not skies).
var skies_dark: int = 0
var hunger: float = 0.0
## Corruption map: id -> level.
var corruption: Dictionary = {}


func to_payload() -> Dictionary:
	var corr: Dictionary = {}
	for k: Variant in corruption.keys():
		corr[str(k)] = int(corruption[k])
	return {
		"started": started,
		"loop_min_left": loop_min_left,
		"skies_dark": skies_dark,
		"hunger": hunger,
		"corruption": corr,
	}


## Null when `d` holds an unknown key or a value of the wrong type.
static func from_payload(d: Dictionary) -> IterationState:
	if not RunPayload.unknown_keys(d, PackedStringArray(KEYS)).is_empty():
		return null
	var errors: Array[String] = []
	var s := IterationState.new()
	s.started = RunPayload.read_bool(d, "started", false, errors)
	s.loop_min_left = RunPayload.read_float(d, "loop_min_left", 0.0, errors)
	s.skies_dark = RunPayload.read_int(d, "skies_dark", 0, errors)
	s.hunger = RunPayload.read_float(d, "hunger", 0.0, errors)
	s.corruption = RunPayload.read_id_ints(d, "corruption", errors)
	if not errors.is_empty() or s.skies_dark < 0 or s.loop_min_left < 0.0:
		return null
	return s
