class_name HandlingTree
extends RefCounted
## Applies owned Lantern Tree nodes to the Aether handling stats (LOOP-001 §3.8). Pure: returns a
## modified duplicate and never touches the base resource. All numbers come from the effects data.

const EFFECTS := preload("res://data/lantern_tree/handling_node_effects.tres")
const ARG_PREFIX := "--tree="


## Tester override from the CLI user args (after `--`): `--tree=HULL-1,LANTERN-10`. Unknown ids are
## kept (they may have a visible module); `apply` ignores them.
static func parse_args(args: PackedStringArray) -> PackedStringArray:
	var out := PackedStringArray()
	for a in args:
		if a.begins_with(ARG_PREFIX):
			for part in a.trim_prefix(ARG_PREFIX).split(",", false):
				var id := part.strip_edges().to_upper()
				if id != "" and not out.has(id):
					out.append(id)
	return out


static func apply(base: VigilAetherStats, node_ids: PackedStringArray,
		fx: HandlingNodeEffects = EFFECTS) -> VigilAetherStats:
	var out := base.duplicate() as VigilAetherStats
	var speed_frac := 0.0
	var base_fracs := {}   # field -> summed fraction of the base value
	var seen := {}
	for id in node_ids:
		if seen.has(id) or not fx.effects.has(id):
			continue
		seen[id] = true
		var list: Array = fx.effects[id]
		for e: Dictionary in list:
			var field: String = e["field"]
			var op: String = e["op"]
			var value: float = float(e["value"])
			match op:
				"speed_frac":
					speed_frac += value
				"add_base_frac":
					base_fracs[field] = float(base_fracs.get(field, 0.0)) + value
				"mul":
					_set_num(out, field, _num(out, field) * value)
				"max_to":
					_set_num(out, field, maxf(_num(out, field), value))
	for f: String in base_fracs:
		_set_num(out, f, _num(out, f) + _num(base, f) * float(base_fracs[f]))
	var total := minf(speed_frac, fx.speed_bonus_cap)
	out.max_speed *= 1.0 + total
	out.accel *= 1.0 + total
	out.brake *= 1.0 + total
	out.surge_cooldown = maxf(out.surge_cooldown, out.surge_cooldown_floor)
	return out


static func _num(s: VigilAetherStats, field: String) -> float:
	var v: Variant = s.get(field)
	return float(v)


static func _set_num(s: VigilAetherStats, field: String, value: float) -> void:
	var cur: Variant = s.get(field)
	if typeof(cur) == TYPE_INT:
		s.set(field, roundi(value))
	else:
		s.set(field, value)
