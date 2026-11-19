extends Node
## SaveService (autoload) — why global: save slots outlive every scene, and the cadence rule
## (SYS-001 §8: never mid-run) must be enforced in one place. TECH-001 §2.8, §7.
##
## Three slots, one per persistence class (LOOP-001 §2):
##   profile   — Anchored state (Lantern Tree, banked currency, Codex, endings, bests)
##   iteration — Iteration state (Hourglass Clock, Hunger, corruption map, telemetry counters)
##   run       — Run state (Seam index, seed, Sigils, Relics, Pact, Charges, Composure)
## Callers pass *why* they save; reasons not allowed for a slot are refused.
## Payloads are dictionaries of invariant IDs and numbers. Never store tr() output.

signal save_completed(slot: StringName)
signal save_failed(slot: StringName, reason: StringName)
signal load_failed(slot: StringName, reason: StringName)

const SLOT_PROFILE := &"profile"
const SLOT_ITERATION := &"iteration"
const SLOT_RUN := &"run"

## Allowed save reasons per slot (SYS-001 §8 save cadence; LOOP-001 §2 "run slot, written between Seams only").
## `run_end` (Q-T139, PM 2026-11-19): written by RunSession at death / win / abandon, so a quit after
## a death can never resume the dead run. It is a run boundary, not mid-run.
const ALLOWED_REASONS := {
	&"profile": [&"ruins_entry", &"tree_purchase", &"iteration_end", &"cabinet_score", &"cabinet_tape"],
	&"iteration": [&"ruins_entry", &"iteration_end", &"new_iteration", &"run_end"],
	&"run": [&"seam_boundary", &"run_end"],
}

## Player-safe meaning of each failure reason; the UI turns these into tr() text.
const REASON_NOT_ALLOWED := &"not_allowed_now"
const REASON_UNKNOWN_SLOT := &"unknown_slot"
const REASON_WRITE_FAILED := &"write_failed"
const REASON_CORRUPT := &"corrupt"
const REASON_NEWER := &"newer_version"
const REASON_MISSING := &"missing"

var backend: SaveBackend = FileSaveBackend.new()


## `-- --no-save` (captures, demos, CI): keep every slot in memory, never touch the player's saves.
func _ready() -> void:
	if OS.get_cmdline_user_args().has("--no-save"):
		backend = MemorySaveBackend.new()


func set_backend(p_backend: SaveBackend) -> void:
	backend = p_backend


func is_known_slot(slot: StringName) -> bool:
	return ALLOWED_REASONS.has(slot)


func save_slot(slot: StringName, payload: Dictionary, reason: StringName) -> Error:
	if not is_known_slot(slot):
		_fail(slot, REASON_UNKNOWN_SLOT, "unknown slot")
		return ERR_INVALID_PARAMETER
	if not (ALLOWED_REASONS[slot] as Array).has(reason):
		_fail(slot, REASON_NOT_ALLOWED, "reason '%s' not allowed for slot" % reason)
		return ERR_UNAUTHORIZED
	var env := SaveEnvelope.create(String(slot), payload)
	var err := backend.write_text(String(slot), env.to_json())
	if err != OK:
		_fail(slot, REASON_WRITE_FAILED, "backend error %d" % err)
		return err
	save_completed.emit(slot)
	return OK


## Returns {"ok": bool, "payload": Dictionary, "reason": StringName, "recovered": bool}.
## A corrupt main file falls back to the last good backup.
func load_slot(slot: StringName) -> Dictionary:
	var result := {"ok": false, "payload": {}, "reason": REASON_MISSING, "recovered": false}
	if not is_known_slot(slot):
		result.reason = REASON_UNKNOWN_SLOT
		load_failed.emit(slot, result.reason)
		return result
	var parsed := SaveEnvelope.from_json(backend.read_text(String(slot)), String(slot))
	if parsed[0] == SaveEnvelope.Status.MISSING:
		return result   # not an error: first launch
	if parsed[0] != SaveEnvelope.Status.OK and parsed[0] != SaveEnvelope.Status.NEWER_VERSION:
		var bak := SaveEnvelope.from_json(backend.read_backup(String(slot)), String(slot))
		if bak[0] == SaveEnvelope.Status.OK:
			push_warning("SaveService: %s main copy unreadable (%s); using backup" % [slot, parsed[0]])
			parsed = bak
			result.recovered = true
	match parsed[0]:
		SaveEnvelope.Status.OK:
			result.ok = true
			result.payload = (parsed[1] as SaveEnvelope).payload
			result.reason = &""
		SaveEnvelope.Status.NEWER_VERSION:
			result.reason = REASON_NEWER
		_:
			result.reason = REASON_CORRUPT
	if not result.ok:
		push_warning("SaveService: load %s failed: %s" % [slot, result.reason])
		load_failed.emit(slot, result.reason)
	return result


func has_slot(slot: StringName) -> bool:
	return backend.exists(String(slot))


## Used by "New Iteration" / "abandon run". Never called mid-run by gameplay.
func clear_slot(slot: StringName) -> void:
	backend.remove(String(slot))


func _fail(slot: StringName, reason: StringName, detail: String) -> void:
	push_warning("SaveService: save %s refused/failed: %s" % [slot, detail])
	save_failed.emit(slot, reason)
