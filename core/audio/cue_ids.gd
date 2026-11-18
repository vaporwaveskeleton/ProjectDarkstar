class_name CueIds
extends Resource
## Table of every built cue (AUDIO-001 §12.7 C6), loaded from `data/audio/cue_ids.tres`.
## Render-only cues (no `SfxSynth` fallback) are silent when their render is missing.

@export var entries: Array[CueIdEntry] = []


## Every cue id in the table.
func ids() -> Array[StringName]:
	var out: Array[StringName] = []
	for e in entries:
		out.append(e.id)
	return out


func entry(id: StringName) -> CueIdEntry:
	for e in entries:
		if e.id == id:
			return e
	return null


func has_id(id: StringName) -> bool:
	return entry(id) != null


## One-shot cue ids that SfxSynth.build_cabinet_set() is expected to supply.
func fallback_ids() -> Array[StringName]:
	var out: Array[StringName] = []
	for e in entries:
		if e.has_synth_fallback and not e.is_loop:
			out.append(e.id)
	return out
