class_name LanternTreeNode
extends Resource
## One Lantern Tree node as data (LOOP-001 §3.1, §3.3). Content, not tuning: the price is never
## stored here, it comes from the node's tier through LanternTreeData (SYS-001 §7.7).
## The node's in-play effect is wired by other systems keyed on `id` (HandlingTree readings,
## AetherVigilRig modules); `wiring` says honestly how much of the §3.3 effect acts in play today.

enum Wiring {
	NOOP,     ## nothing acts in play yet; `stub_note` names the missing system
	PARTIAL,  ## part of the effect acts (e.g. the hull module or the Aether reading); `stub_note` names the rest
	WIRED,    ## the whole §3.3 / §3.8 effect acts in play
}

## `<BRANCH>-<1..18>` (LOOP-001 §3.1), e.g. "LANTERN-1".
@export var id: StringName = &""
## One of LanternTreeData.BRANCHES.
@export var branch: StringName = &""
## 1..5; nodes 1–4 = T1, 5–8 = T2 (LOOP-001 §3.1).
@export var tier: int = 1
## tr() key of the node's name (GDD §19 / LOOP-001 §3.3 names).
@export var name_key: StringName = &""
## tr() key of the one-line effect (GDD-001 §7.3 legibility: one line).
@export var effect_key: StringName = &""
## Hard named prerequisites from LOOP-001 §3.3 `Requires` (node ids), on top of the tier gate.
@export var requires: PackedStringArray = PackedStringArray()
## Gating Codex entry id (`cx_…`, LOOP-001 §3.7), or &"" for an Ember-priced node.
@export var codex_gate: StringName = &""
## LOOP-001 §3.3 "Rules-bending?" column.
@export var rules_bending: bool = false
## How much of the effect acts in play today (see Wiring).
@export var wiring: Wiring = Wiring.NOOP
## Engineering note for NOOP / PARTIAL nodes: what is not wired and which system it waits on.
## Never shown to the player.
@export_multiline var stub_note: String = ""


func is_codex_gated() -> bool:
	return codex_gate != &""
