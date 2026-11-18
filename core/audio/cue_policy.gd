class_name CuePolicy
extends TunableResource
## Per-cue voice policy table (AUDIO-001 §12.6), loaded from `data/audio/cue_policy.tres`.
## All values are engineering ✱ numbers. The `entries` table is not addressed by `ds_` keys;
## the policy is looked up by cue id.

const DEFAULT_BUS := &"BUS-FLY"          ## ✱ default for a cue with no entry
const DEFAULT_PRIORITY := 3              ## ✱ mid priority
const DEFAULT_MAX_CONCURRENT := 4        ## ✱

@export var entries: Array[CuePolicyEntry] = []

var _default: CuePolicyEntry


## The entry for `id`, or a safe default (BUS-FLY, mid priority, 4 voices, no gate, no jitter).
func entry_for(id: StringName) -> CuePolicyEntry:
	for e in entries:
		if e.id == id:
			return e
	if _default == null:
		_default = CuePolicyEntry.new()
		_default.bus = DEFAULT_BUS
		_default.priority = DEFAULT_PRIORITY
		_default.max_concurrent = DEFAULT_MAX_CONCURRENT
	return _default


func has_entry(id: StringName) -> bool:
	for e in entries:
		if e.id == id:
			return true
	return false
