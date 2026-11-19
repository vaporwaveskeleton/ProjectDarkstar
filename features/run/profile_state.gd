class_name ProfileState
extends RefCounted
## Anchored state (LOOP-001 §2; TECH-001 §4.2, §4.2a, §7.2), the `profile` slot.
## From the Ruins on RunSession is the one profile writer (Q-T142). The Cabinet and attract mode
## still write their own keys with their own reasons (`cabinet_score`, `cabinet_tape`), so this
## object carries their keys too and keeps any other plain key it does not know in `extra`:
## a RunSession write must never erase another writer's key.

## Keys RunSession owns: its in-memory value wins over what is on disk (`merge_foreign`).
const OWNED_KEYS := ["ember_banked", "act0_banked", "tree_nodes"]
## Keys other writers own (TECH-001 §7.2 Act 0 keys; `act0_pending_vi` is Q-T141).
const FOREIGN_KEYS := ["cabinet_hi_score", "act0_complete", "pretence_seen", "cabinet_tape_peeled", "act0_pending_vi"]

var ember_banked: int = 0
## Lantern Tree node ids bought (Q-T191), in purchase order; ids only (TECH-001 §7).
var tree_nodes: Array[StringName] = []
## Q-T101: the Act 0 bank has been paid (once per profile, ever).
var act0_banked: bool = false
var cabinet_hi_score: int = 0
var act0_complete: bool = false
var pretence_seen: bool = false
var cabinet_tape_peeled: bool = false
## Q-T141: the Act 0 Vigil Index the Cabinet stored with its `cabinet_score` write at Act 0
## completion, so a crash before `ruins_entry` does not lose the bank. −1 = none pending.
var act0_pending_vi: int = -1
## Plain keys owned by nobody above (future Codex, Tree, endings…), carried through unchanged.
var extra: Dictionary = {}


func to_payload() -> Dictionary:
	var d: Dictionary = extra.duplicate(true)
	d["ember_banked"] = ember_banked
	d["act0_banked"] = act0_banked
	d["cabinet_hi_score"] = cabinet_hi_score
	d["act0_complete"] = act0_complete
	d["pretence_seen"] = pretence_seen
	d["cabinet_tape_peeled"] = cabinet_tape_peeled
	if not tree_nodes.is_empty():
		d["tree_nodes"] = RunPayload.ids_out(tree_nodes)
	if act0_pending_vi >= 0:
		d["act0_pending_vi"] = act0_pending_vi
	return d


## Null when a known key has the wrong type or an unknown key holds a non-plain value.
static func from_payload(d: Dictionary) -> ProfileState:
	var errors: Array[String] = []
	var p := ProfileState.new()
	p.ember_banked = RunPayload.read_int(d, "ember_banked", 0, errors)
	p.act0_banked = RunPayload.read_bool(d, "act0_banked", false, errors)
	p.cabinet_hi_score = RunPayload.read_int(d, "cabinet_hi_score", 0, errors)
	p.act0_complete = RunPayload.read_bool(d, "act0_complete", false, errors)
	p.pretence_seen = RunPayload.read_bool(d, "pretence_seen", false, errors)
	p.cabinet_tape_peeled = RunPayload.read_bool(d, "cabinet_tape_peeled", false, errors)
	p.tree_nodes = RunPayload.read_ids(d, "tree_nodes", errors)
	p.act0_pending_vi = RunPayload.read_int(d, "act0_pending_vi", -1, errors)
	var known := PackedStringArray(OWNED_KEYS + FOREIGN_KEYS)
	for k in RunPayload.unknown_keys(d, known):
		var v: Variant = d[k]
		if not RunPayload.is_plain(v):
			errors.append("%s is not plain" % k)
			continue
		p.extra[k] = v
	if not errors.is_empty():
		return null
	return p


## Takes every key another writer owns from `disk` (the Cabinet may have written since boot) and
## keeps this object's own keys (`OWNED_KEYS`): in-memory Ember banked at a run end is not lost.
func merge_foreign(disk: ProfileState) -> void:
	cabinet_hi_score = disk.cabinet_hi_score
	act0_complete = act0_complete or disk.act0_complete
	pretence_seen = pretence_seen or disk.pretence_seen
	cabinet_tape_peeled = disk.cabinet_tape_peeled
	act0_pending_vi = disk.act0_pending_vi
	extra = disk.extra.duplicate(true)
