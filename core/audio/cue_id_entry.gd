class_name CueIdEntry
extends Resource
## One row of the cue id table (AUDIO-001 §12.7 C6): a built cue, its §6.2 id, and whether a
## runtime SfxSynth fallback exists for it.

## Cue id the game plays (`AudioService.play(id)`), also the render file name.
@export var id: StringName = &""
## AUDIO-001 §6.2 id (e.g. "A01"), or "" when the cue is Act 0 only.
@export var doc_id: String = ""
## True when the cue has no §6.2 id and exists only for the Act 0 Cabinet.
@export var act0_only := false
## True when `SfxSynth` can build this cue at runtime if its render is missing.
@export var has_synth_fallback := false
## True for a looping bed (the chant) rather than a one-shot cue.
@export var is_loop := false
## Free text: an approximate id mapping, or why the row exists. Never shown to the player.
@export var note: String = ""
