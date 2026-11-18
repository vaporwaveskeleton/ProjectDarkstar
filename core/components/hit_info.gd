class_name HitInfo
extends RefCounted
## One damage event. `source_id` + `window_id` identify an attack window so a target
## takes at most one hit per window (TECH-001 §2.6, one-hit-per-window rule).

var amount: int = 1
var source_id: int = 0   ## instance id of the attacker (or hitbox) — internal only
var window_id: int = 0   ## increments each time the attacker opens a new active window
var kind: StringName = &"generic"


static func make(p_amount: int, p_source_id: int, p_window_id: int, p_kind: StringName = &"generic") -> HitInfo:
	var h := HitInfo.new()
	h.amount = p_amount
	h.source_id = p_source_id
	h.window_id = p_window_id
	h.kind = p_kind
	return h


func window_key() -> String:
	return "%d:%d" % [source_id, window_id]
