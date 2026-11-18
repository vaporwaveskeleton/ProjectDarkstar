class_name HullMode
extends RefCounted
## D-08 hull A/B switch resolution (SYS-001 §1.2). The data value (`ds_vigil.hull.max_hp`, carried by
## the Vigil's HealthStats) is the default; a tester may override it with `-- --hull=1|2`.
## Only 1 (one-hit) and 2 (plated) are valid; anything else falls back to the data value.

const ARG_PREFIX := "--hull="
const VALID: Array[int] = [1, 2]


## True when `value` is a legal hull setting.
static func is_valid(value: int) -> bool:
	return VALID.has(value)


## Override from the CLI user args (after `--`): 1 or 2, or -1 when absent or invalid.
static func parse_args(args: PackedStringArray) -> int:
	for a in args:
		if a.begins_with(ARG_PREFIX):
			var text := a.trim_prefix(ARG_PREFIX)
			if text.is_valid_int() and is_valid(int(text)):
				return int(text)
			return -1
	return -1


## The hull max HP to use: a valid override wins, otherwise the data value.
static func resolve(override: int, data_value: int) -> int:
	return override if is_valid(override) else data_value
