class_name CuePolicyEntry
extends Resource
## Voice policy of one cue (AUDIO-001 §12.6). Every number is an engineering ✱ value, tuned in the
## slice; none is a gameplay number.

@export var id: StringName = &""
## Audio bus the cue plays on (names from data/audio/default_bus_layout.tres).
@export var bus: StringName = &"BUS-FLY"
## AUDIO-001 §7.2 level, 0..5; lower is more important. P0 and P1 are never stolen.
@export_range(0, 5) var priority := 3
## Voices of this cue that may sound at once; 0 means unlimited.
@export var max_concurrent := 4
## Minimum time between two starts of this cue, ms; 0 means no gate.
@export var min_retrigger_ms := 0
## Random pitch offset, +- cents, per play; 0 means none.
@export var pitch_jitter_cents := 0.0


## P0 and P1 cues are never stolen by another cue.
func is_stealable() -> bool:
	return priority >= 2
