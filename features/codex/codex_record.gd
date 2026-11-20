class_name CodexRecord
extends RefCounted
## The Codex knowledge record, minimal (LOOP-001 §8; TECH-001 Q-T350, closes Q-T327). Pure rules over
## two id lists the profile keeps (ProfileState `codex_known`, `codex_read`; anchored state, LOOP-001 §2):
## which entries are stamped (known) and which of those the player has opened. No nodes, no saves:
## RunSessionCore stamps and reads through these helpers and the profile goes to disk only at its
## allowed reasons (`ruins_entry`, `tree_purchase`; TECH-001 §7.2). A stamp is never undone (§8.1).
##
## Built: the record, the Ruins page read (beat 10, `cx_place_act0_3`), and the tier-1 backstop
## (LOOP-001 §3.7 backstop (a): tier-1 gating entries stamped after the Chronicle's third run, SYS-001
## §7.6). Not built (Q-T351): discovery sources, the per-death backstop (b), the tier-t floor, the run
## summary that shows new stamps, and the Codex screen itself.

## Entry ids are `cx_<class>_<slug>` (LOOP-001 §8.2).
const ENTRY_PREFIX := "cx_"
## The page the Ruins Codex desk shows on the first visit (LOOP-001 §10.5.2 beat 10; NARR-001 §8.4).
## Reaching the Ruins means Act 0's third stage is cleared, so arrival stamps it (Q-T352).
const ACT0_PAGE := &"cx_place_act0_3"


static func is_entry_id(id: StringName) -> bool:
	var s := String(id)
	return s.begins_with(ENTRY_PREFIX) and s.length() > ENTRY_PREFIX.length()


## Stamps `id` into `known` (in stamp order). True only when it was not known before.
static func stamp(known: Array[StringName], id: StringName) -> bool:
	if not is_entry_id(id) or known.has(id):
		return false
	known.append(id)
	return true


## Marks a stamped entry as opened. Unknown entries cannot be read (the Codex shows stamped pages
## only, §8.6). True only when it was unread before.
static func mark_read(known: Array[StringName], read: Array[StringName], id: StringName) -> bool:
	if not known.has(id) or read.has(id):
		return false
	read.append(id)
	return true


## Stamped entries not yet opened (each carries a chalk tick on its spine, §8.6), in stamp order.
static func unread(known: Array[StringName], read: Array[StringName]) -> Array[StringName]:
	var out: Array[StringName] = []
	for id in known:
		if not read.has(id):
			out.append(id)
	return out


## The gating entries of `tree`'s nodes at `tier`, in the tree's data order, without repeats.
## The tree data is the one source of the gating map in code (LOOP-001 §3.7 → `codex_gate`).
static func gating_ids(tree: LanternTreeData, tier: int) -> Array[StringName]:
	var out: Array[StringName] = []
	if tree == null:
		return out
	for n in tree.nodes:
		if n != null and n.tier == tier and n.is_codex_gated() and not out.has(n.codex_gate):
			out.append(n.codex_gate)
	return out


## Backstop (a) for tier 1: due once `runs_ended` reaches `after_runs` (0 or less = off).
static func tier1_backstop_due(runs_ended: int, after_runs: int) -> bool:
	return after_runs > 0 and runs_ended >= after_runs
