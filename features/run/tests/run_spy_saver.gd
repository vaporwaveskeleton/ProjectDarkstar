extends RefCounted
## Test saver for RunSessionCore: records every save call and forwards it to a private SaveService
## instance on a MemorySaveBackend (so the real allowed-reasons table is enforced). Never writes
## a file and never touches the SaveService autoload.

const SaveServiceScript := preload("res://autoload/save_service.gd")

## [{slot, reason, payload, result}] in call order.
var calls: Array[Dictionary] = []
var mem := MemorySaveBackend.new()
var svc: Node


func _init() -> void:
	svc = SaveServiceScript.new()
	svc.set_backend(mem)


func free_service() -> void:
	if is_instance_valid(svc):
		svc.free()


func save_slot(slot: StringName, payload: Dictionary, reason: StringName) -> Error:
	var err: Error = svc.save_slot(slot, payload, reason)
	calls.append({"slot": slot, "reason": reason, "payload": payload.duplicate(true), "result": err})
	return err


func load_slot(slot: StringName) -> Dictionary:
	return svc.load_slot(slot)


func slots_and_reasons() -> Array[String]:
	var out: Array[String] = []
	for c in calls:
		out.append("%s:%s" % [c.slot, c.reason])
	return out


func clear() -> void:
	calls.clear()
