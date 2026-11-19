class_name CabinetStageRoster
extends Resource
## The Act 0 shift: every CabinetStage in play order (a0_1 … a0_5; SYS-001 §1.6, PM 2026-11-19).
## Content, not tuning. CabinetGame plays them in order; the Pretence follows the last one.

@export var stages: Array[CabinetStage] = []


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
