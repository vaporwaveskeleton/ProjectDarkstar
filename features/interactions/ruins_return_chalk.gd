class_name RuinsReturnChalk
extends RefCounted
## The slate's line for a visit that follows a run (NARR-001 §5.7a; Q-T284). Pure: the Ruins give it
## the outcome id, the run's seed and how many runs have ended, and it names one `tr()` key. The same
## inputs always name the same key; the pick runs through `RunSeed.hash64`, so it needs no RNG state.

const POOL_SIZE := 6
const RARE_POOL_SIZE := 2
## ✱ the rare line (hints at the Cabinet's maker, NARR-001 stage S1) only shows after this many
## ended runs, and then on one pick in `RARE_ONE_IN`.
const RARE_MIN_RUNS := 4
const RARE_ONE_IN := 4
const _STREAM := "ruins_chalk"
const _STREAM_RARE := "ruins_chalk_rare"

const PREFIXES := {
	&"returned": "NARR_SABLE_RET_OK_",
	&"died": "NARR_SABLE_RET_DIED_",
	&"abandoned": "NARR_SABLE_RET_QUIT_",
}
const RARE_PREFIX := "NARR_SABLE_RET_RARE_"


## True for the outcomes that have a pool (`won` and anything unknown keep the plain return line).
static func has_pool(outcome: StringName) -> bool:
	return PREFIXES.has(outcome)


## Every key of an outcome's pool, in order (empty when it has none).
static func pool(outcome: StringName) -> Array[StringName]:
	var out: Array[StringName] = []
	if not PREFIXES.has(outcome):
		return out
	for i in POOL_SIZE:
		out.append(StringName("%s%d" % [PREFIXES[outcome], i + 1]))
	return out


static func rare_pool() -> Array[StringName]:
	var out: Array[StringName] = []
	for i in RARE_POOL_SIZE:
		out.append(StringName("%s%d" % [RARE_PREFIX, i + 1]))
	return out


## The key to write, or &"" when `outcome` has no pool.
static func key_for(outcome: StringName, run_seed: int, runs_ended: int) -> StringName:
	if not PREFIXES.has(outcome):
		return &""
	var s := maxi(run_seed, 0)
	if runs_ended >= RARE_MIN_RUNS and _pick(s, _STREAM_RARE, runs_ended, RARE_ONE_IN) == 0:
		return rare_pool()[_pick(s, _STREAM_RARE, runs_ended + 1, RARE_POOL_SIZE)]
	return pool(outcome)[_pick(s, _STREAM, runs_ended, POOL_SIZE)]


static func _pick(run_seed: int, stream: String, salt: int, n: int) -> int:
	return int(RunSeed.hash64(run_seed, stream, salt) & 0x7FFFFFFF) % n
