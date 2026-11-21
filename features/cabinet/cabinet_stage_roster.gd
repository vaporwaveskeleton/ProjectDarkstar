class_name CabinetStageRoster
extends Resource
## The Act 0 shift: every CabinetStage in play order (three stages since F-14: a0_3, a0_4, a0_5; the five-stage shift is stage_roster_five.tres; SYS-001 §1.6).
## Content, not tuning. CabinetGame plays them in order; the Pretence follows the last one.

const DEFAULT_PATH := "res://data/cabinet/stage_roster.tres"   ## the shift the cabinet scene plays

@export var stages: Array[CabinetStage] = []


## The shared shift (DEFAULT_PATH), or null when it cannot load.
static func default_roster() -> CabinetStageRoster:
	return load(DEFAULT_PATH) as CabinetStageRoster


## Stage count of the default shift, 0 when it is missing (attract asks before the cabinet exists).
static func default_size() -> int:
	var r := default_roster()
	return r.size() if r != null else 0


func size() -> int:
	return stages.size()


## Stage `i`, or null when `i` is outside the roster.
func get_stage(i: int) -> CabinetStage:
	if i < 0 or i >= stages.size():
		return null
	return stages[i]


## Index of the stage with `stage_id`, or -1.
func index_of(stage_id: StringName) -> int:
	for i in stages.size():
		if stages[i] != null and stages[i].id == stage_id:
			return i
	return -1


## How many Unmakings the shift needs: the stages whose goal is to unmake the entity (SYS-001 §1.7, 3).
func unmakings_required() -> int:
	return unmakings_before(stages.size())


## Unmaking stages (UNMAKE_ENTITY) strictly before stage index `i`: the Unmakings already done when stage
## `i` starts (the run-scoped count CabinetGame derives on CONTINUE).
func unmakings_before(i: int) -> int:
	var n := 0
	for k in mini(i, stages.size()):
		if stages[k] != null and stages[k].goal == CabinetStage.Goal.UNMAKE_ENTITY:
			n += 1
	return n
