class_name WarpSchedule
extends RefCounted
## Transient timing for one sector (TECH-001 §5.1 Determinism, Novelty cap). Pure: start times come
## from the run's `warp` stream (RunSeed, TECH-001 §4.9) for this Seam, so a seed replays the same warp.
## Scheduled rows (Trigger.SCHEDULED, e.g. W1-09, W1-10) get one start each inside the set's window;
## band-driven rows (W1-07) ask `admit()` when their cue comes due.

## id -> {start_s, end_s}
var planned: Dictionary = {}
## Novel effects admitted this sector (GDD §16 R-02).
var novel_used: int = 0
## Witnessed ids: the run's Iteration memory when bound (RunSessionCore.warp_witnessed, Q-T201),
## else a sector-local set. Shared by reference, so admits write through to the Iteration.
var _witnessed: Dictionary = {}
var _cap: int = 0


static func plan(warp_set: WarpSet, run_seed: int, seam_index: int,
		witnessed: Variant = null) -> WarpSchedule:
	var s := WarpSchedule.new()
	if witnessed is Dictionary:
		s._witnessed = witnessed
	if warp_set == null:
		return s
	s._cap = warp_set.novel_per_sector
	var rng := RunSeed.new(run_seed).stream(RunSeed.STREAM_WARP, seam_index)
	var earliest := maxf(warp_set.transient_earliest_s, warp_set.entry_quiet_s)
	var latest := maxf(earliest, warp_set.transient_latest_s)
	for e in warp_set.effects:
		if e.kind != WarpEffect.Kind.TRANSIENT or e.trigger != WarpEffect.Trigger.SCHEDULED:
			continue
		var start := rng.randf_range(earliest, latest)
		s.planned[e.id] = {"start_s": start, "end_s": start + duration_of(warp_set, e.id)}
	return s


## Live length of a scheduled or cue-driven transient (s).
static func duration_of(warp_set: WarpSet, effect_id: StringName) -> float:
	match effect_id:
		&"W1-09": return warp_set.blip_smear_s
		&"W1-10": return warp_set.glyph_s
		&"W1-07": return warp_set.false_chant_s
	return 0.0


## Spends a novelty slot the first time `effect_id` fires this sector; repeats are free.
## Returns false when the cap is spent (the effect is refused, not deferred).
func admit(effect_id: StringName) -> bool:
	if _witnessed.has(effect_id):
		return true   # not novel this Iteration: free (WARP-001 §1.1)
	if novel_used >= _cap:
		return false
	_witnessed[effect_id] = true
	novel_used += 1
	return true


func start_of(effect_id: StringName) -> float:
	return float((planned.get(effect_id, {}) as Dictionary).get("start_s", INF))


func end_of(effect_id: StringName) -> float:
	return float((planned.get(effect_id, {}) as Dictionary).get("end_s", INF))
