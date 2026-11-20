class_name RunSessionCore
extends RefCounted
## RunSession rules (TECH-001 §4.2a): the run, the Iteration (Hourglass Clock) and the profile's
## Ember. No node, no autoload reads, no files: stats and a saver are injected. The autoload
## `autoload/run_session.gd` owns one core and ticks it; tests build their own.
##
## Saver: any Object with `save_slot(slot, payload, reason) -> Error` and
## `load_slot(slot) -> {ok, payload, reason}` (SaveService, or a test spy). Null = never saves
## (the throwaway core a sector builds when no session is handed in).
##
## Saves happen only here, only at these call sites (§4.2a, §7.2, Q-T139):
##   arrive_at_ruins → profile + iteration, `ruins_entry`
##   end_seam (not the last) → run, `seam_boundary`
##   die / win / abandon / return_from_frontier → run + iteration, `run_end`
## Never from tick, enter_seam, a sky or any mid-Seam moment.

signal iteration_started()
signal run_started(run_seed: int)
signal seam_entered(seam_index: int)
signal seam_cleared(seam_index: int)
signal run_ended(outcome: StringName)
signal sky_darkened(skies_dark: int)
signal iteration_ended()

const SLOT_PROFILE := &"profile"
const SLOT_ITERATION := &"iteration"
const SLOT_RUN := &"run"
const REASON_RUINS_ENTRY := &"ruins_entry"
const REASON_SEAM_BOUNDARY := &"seam_boundary"
const REASON_RUN_END := &"run_end"
const REASON_TREE_PURCHASE := &"tree_purchase"

const OUTCOME_DIED := &"died"
const OUTCOME_WON := &"won"
const OUTCOME_ABANDONED := &"abandoned"
const OUTCOME_NINTH_SKY := &"ninth_sky"
## Q-T276 (PM 2026-11-19 overnight): the run ends at the slice frontier through the cleared Seam's
## exit throat (`return_from_frontier`). Banks like a win; costs and refunds no clock.
const OUTCOME_RETURNED := &"returned"

## Clock pause reasons (Q-T138). Others may be added by callers; any active reason stops the clock.
const PAUSE_MENU := &"pause"
const PAUSE_CODEX := &"codex"
const PAUSE_CINEMATIC := &"cinematic"
const PAUSE_ATTRACT := &"attract"
const PAUSE_CURTAIN := &"curtain"
const PAUSE_RUINS_MENU := &"ruins_menu"
## Q-T162 (settled 2026-11-19): the Ruins holds this on the first visit until the launch, so the
## Hourglass starts when you leave (beat 11; GDD §6.2 exception).
const PAUSE_FIRST_GLASS := &"first_glass"

## Route param keys (TECH-001 §4.2a).
const PARAM_ACT0_VI := "act0_vigil_index"

const _SKY_EPS := 1e-6
## The act the M2 slice's runs play (WARP-001 §1.3 act window: Act 1 = T1). TECH-001 Q-T200.
const WARP_ACT_SLICE := 1

## Transient warp effects witnessed this Iteration (WARP-001 §1.1 "novel"; Q-T201): id -> true.
## In memory only; cleared when a new Iteration begins. The WarpComposer reads and adds to it.
var warp_witnessed: Dictionary = {}
## Highest effective warp tier seen this Iteration (SYS-001 §8 telemetry key `warp_max`; Q-T203).
## In memory until the telemetry pass saves it in the iteration slot.
var warp_max: int = 0

var stats: RunSessionStats

var _saver: Object
var _run := RunState.new()
var _iteration := IterationState.new()
var _profile := ProfileState.new()
## Reason -> count (reason-counted set).
var _pauses: Dictionary = {}
## True between enter_seam and end_seam / die (abandon is refused here, Q-T144).
var _in_seam := false
## The Vigil Index the last arrival banked (−1 = none): the Ruins chalks it as a tally (LOOP-001 §10.5).
var act0_vi_banked := -1
## The seed of the run that ended last (−1 = none this boot): the Ruins pick the return chalk from it
## (NARR-001 §5.7a; Q-T284). In memory only.
var last_run_seed := -1
## False when the profile on disk could not be read: never overwrite it (no data loss).
var _profile_writable := true


func _init(p_stats: RunSessionStats, p_saver: Object = null) -> void:
	stats = p_stats
	_saver = p_saver


# --- loading ---------------------------------------------------------------------------------------

## Loads all three slots from the saver (boot). Missing slots keep defaults.
func load_from_saver() -> void:
	for slot: StringName in [SLOT_PROFILE, SLOT_ITERATION, SLOT_RUN]:
		var r := _load(slot)
		if r.is_empty():
			continue
		if not restore(slot, r):
			push_warning("RunSession: %s payload rejected" % slot)
			if slot == SLOT_PROFILE:
				_profile_writable = false


## Payload of `slot` from the saver; {} when missing or unreadable (an unreadable profile is
## marked unwritable).
func _load(slot: StringName) -> Dictionary:
	if _saver == null or not _saver.has_method(&"load_slot"):
		return {}
	var r: Dictionary = _saver.call(&"load_slot", slot)
	if bool(r.get("ok", false)):
		var p: Variant = r.get("payload", {})
		return p if typeof(p) == TYPE_DICTIONARY else {}
	var why := StringName(str(r.get("reason", &"missing")))
	if slot == SLOT_PROFILE and why != &"missing":
		_profile_writable = false
	return {}


# --- the Ruins and the Act 0 bank ------------------------------------------------------------------

## The player arrives in the Ruins (TECH-001 §4.2a): Act 0 bank, begin the Iteration if needed,
## then one profile and one iteration write (`ruins_entry`). Returns the Ember banked from Act 0.
func arrive_at_ruins(params: Dictionary = {}) -> int:
	_refresh_profile()
	var paid := _bank_act0(params)
	# Reaching the Ruins means Act 0 is done (the Ruins stub set these before Q-T142).
	_profile.act0_complete = true
	_profile.pretence_seen = true
	begin_iteration_if_needed()
	_save(SLOT_PROFILE, REASON_RUINS_ENTRY)
	_save(SLOT_ITERATION, REASON_RUINS_ENTRY)
	return paid


# --- the Lantern Tree station (Q-T191) -------------------------------------------------------------

## Buys the next unbought node of `stock` at its tier-1 price from the banked Ember (LOOP-001 §3.8).
## Only in the Ruins (never mid-run). Returns the node id, or &"" when nothing was bought (all
## owned, not enough Ember, a run is live, or the profile on disk is unreadable). One profile
## write, reason `tree_purchase`: the spend and the node commit together.
func buy_tree_node(stock: LanternTreeStock) -> StringName:
	if stock == null or _run.is_active() or not _profile_writable:
		return &""
	var id := stock.next_unbought(_profile.tree_nodes)
	if id == &"" or _profile.ember_banked < stock.price_tier1:
		return &""
	_profile.ember_banked -= stock.price_tier1
	_profile.tree_nodes.append(id)
	_save(SLOT_PROFILE, REASON_TREE_PURCHASE)
	return id


## The Cabinet or attract mode may have written the profile since boot: take their keys, keep ours.
func _refresh_profile() -> void:
	var d := _load(SLOT_PROFILE)
	if d.is_empty():
		return
	var disk := ProfileState.from_payload(d)
	if disk == null:
		_profile_writable = false
		return
	_profile.merge_foreign(disk)


## SYS-001 §7.1 Act 0 bank: `max(floor(VI / score_per_ember), floor)`, once per profile (Q-T101).
## The index comes from the route param, else from the Cabinet's pending index (Q-T141).
func _bank_act0(params: Dictionary) -> int:
	var vi := _param_vi(params)
	if vi < 0:
		vi = _profile.act0_pending_vi
	_profile.act0_pending_vi = -1
	if vi < 0 or _profile.act0_banked:
		return 0
	var pay := maxi(floori(float(vi) / float(maxi(1, stats.score_per_ember))), stats.act0_bank_floor_ember)
	_profile.ember_banked += pay
	_profile.act0_banked = true
	act0_vi_banked = vi
	return pay


static func _param_vi(params: Dictionary) -> int:
	for key: Variant in [PARAM_ACT0_VI, StringName(PARAM_ACT0_VI)]:
		if params.has(key):
			var v: Variant = params[key]
			if typeof(v) == TYPE_INT or typeof(v) == TYPE_FLOAT:
				return maxi(0, int(v))
	return -1


## Starts a fresh Iteration when none is running (first Ruins visit, or after the ninth sky).
## Entropy above 0 is deferred (Q-T137): the budget is the Entropy 0 row.
func begin_iteration_if_needed() -> bool:
	if _iteration.started and _iteration.skies_dark < stats.skies:
		return false
	_iteration = IterationState.new()
	_iteration.started = true
	_iteration.loop_min_left = stats.iteration_budget_loop_min
	warp_witnessed.clear()
	warp_max = 0
	iteration_started.emit()
	return true


# --- the run ---------------------------------------------------------------------------------------

## New run at Seam 1. `run_seed` −1 = a fresh seed; else the typed SeedCode's value (§4.9).
func start_run(run_seed: int = -1) -> RunState:
	if _run.is_active():
		push_warning("RunSession: start_run refused, a run is live")
		return _run
	_run = RunState.new()
	_run.seam_index = 1
	_run.seed_value = (run_seed if run_seed >= 0 else _fresh_seed()) & RunSeed.SEED_MASK
	_in_seam = false
	run_started.emit(_run.seed_value)
	return _run


static func _fresh_seed() -> int:
	var rng := RandomNumberGenerator.new()
	rng.randomize()
	return ((rng.randi() << 24) ^ rng.randi()) & RunSeed.SEED_MASK


## Enters the current Seam. Returns the route params for `SceneRouter.go_to(&"sector", …)`;
## {} when no run is live.
func enter_seam() -> Dictionary:
	if not _run.is_active():
		push_warning("RunSession: enter_seam without a run")
		return {}
	_in_seam = true
	seam_entered.emit(_run.seam_index)
	var seam_seed := RunSeed.hash64(_run.seed_value, String(RunSeed.STREAM_MAP), _run.seam_index) & RunSeed.SEED_MASK
	return {"session": self, "seam_index": _run.seam_index, "seam_seed": seam_seed}


## Seam clear: the one write-back from a sector. Composure and Charges carry unchanged (Q-T140),
## Ember +report +Seam clear (SYS-001 §7.2). The last Seam's clear wins the run.
func end_seam(report: SeamReport) -> bool:
	if not _write_back(report):
		return false
	var cleared := _run.seam_index
	seam_cleared.emit(cleared)
	if cleared >= stats.seams_per_run:
		return win()
	_run.seam_index += 1
	_save(SLOT_RUN, REASON_SEAM_BOUNDARY)
	return true


## True when the live run's current Seam is the slice frontier (Q-T276): its exit throat leads back
## to the Ruins instead of into the next Seam. `slice_last_seam` 0 = no frontier (all five Seams).
func at_frontier() -> bool:
	return _run.is_active() and stats.slice_last_seam > 0 \
		and _run.seam_index >= stats.slice_last_seam and _run.seam_index < stats.seams_per_run


## The cleared Seam's exit throat at the slice frontier (Q-T276): write back and pay the Seam clear
## exactly as `end_seam` (Q-T145), then end the run as `returned`. In-run Ember banks in full; no
## death lump and no win refund. One write set, `run_end` (no `seam_boundary` write first).
## Outside the frontier this is `end_seam`.
func return_from_frontier(report: SeamReport) -> bool:
	if not at_frontier():
		return end_seam(report)
	if not _write_back(report):
		return false
	seam_cleared.emit(_run.seam_index)
	_end_run(OUTCOME_RETURNED)
	_save_run_end()
	return true


func _write_back(report: SeamReport) -> bool:
	if not _run.is_active() or not _in_seam or report == null:
		push_warning("RunSession: Seam write-back outside a Seam")
		return false
	_in_seam = false
	if stats.carry_between_seams:
		_run.composure = report.composure
		_run.charges = maxi(0, report.charges)
	else:
		_run.composure = -1.0
		_run.charges = 0
	_run.ember_in_run += maxi(0, report.ember_earned) + stats.seam_clear_ember
	return true


## Death: in-run Ember banks in full (Q-T145; LOOP-001 §9.2 has no halving rule), the death lump is
## spent, the run ends and both run and iteration are written (`run_end`, Q-T139).
func die() -> bool:
	if not _run.is_active():
		return false
	var cost := stats.death_cost_loop_min(_run.seam_index)
	_end_run(OUTCOME_DIED)
	consume_clock(cost, &"death")
	_save_run_end()
	return true


## Win: Ember banks, +refund clamped to the budget (skies never re-light), run ends, `run_end`.
func win() -> bool:
	if not _run.is_active():
		return false
	_end_run(OUTCOME_WON)
	if _iteration.started:
		_iteration.loop_min_left = minf(stats.iteration_budget_loop_min,
			_iteration.loop_min_left + stats.win_refund_loop_min)
	_save_run_end()
	return true


## Abandon (Q-T144): only in the Ruins or at a Seam boundary (refused inside a Seam); costs the
## death price. Ember banks as on a death (no rule says otherwise; reported to the PM).
func abandon() -> bool:
	if not _run.is_active() or _in_seam:
		return false
	var cost := stats.death_cost_loop_min(_run.seam_index)
	_end_run(OUTCOME_ABANDONED)
	consume_clock(cost, &"abandon")
	_save_run_end()
	return true


## Abandon Run from the sector's pause menu, mid-Seam (Q-T277, amends Q-T144 "refused mid-Seam"):
## the Seam ends unwon and the run is abandoned at the death price; in-run Ember banks (Q-T152 (a)).
## The Seam's own score is not reported, so it pays nothing. Saves `run_end`, as any abandon.
func abandon_from_seam() -> bool:
	if not _run.is_active():
		return false
	_in_seam = false
	return abandon()


func _end_run(outcome: StringName) -> void:
	if outcome != OUTCOME_NINTH_SKY:
		_profile.ember_banked += _run.ember_in_run
		last_run_seed = _run.seed_value
		_profile.extra["runs_ended"] = runs_ended() + 1
	# TODO(Q-T143): the ninth-sky bank is deferred (outside the slice); a ninth-sky end banks nothing.
	_run = RunState.new()
	_in_seam = false
	run_ended.emit(outcome)


func _save_run_end() -> void:
	_save(SLOT_RUN, REASON_RUN_END)
	_save(SLOT_ITERATION, REASON_RUN_END)


# --- the Hourglass Clock ---------------------------------------------------------------------------

## Spends real time (stage −20, §4.1). No-op before the first Ruins visit, while any pause reason
## is held, or after the ninth sky. Never saves.
func tick(delta_s: float) -> void:
	if not _iteration.started or is_clock_paused() or _iteration.skies_dark >= stats.skies:
		return
	consume_clock(delta_s / 60.0 * stats.loop_min_per_real_min, &"time")


func pause_clock(reason: StringName) -> void:
	_pauses[reason] = int(_pauses.get(reason, 0)) + 1


func resume_clock(reason: StringName) -> void:
	var n := int(_pauses.get(reason, 0)) - 1
	if n > 0:
		_pauses[reason] = n
	else:
		_pauses.erase(reason)


func is_clock_paused() -> bool:
	return not _pauses.is_empty()


func pause_reasons() -> Array[StringName]:
	var out: Array[StringName] = []
	for k: Variant in _pauses.keys():
		out.append(StringName(str(k)))
	return out


## Lump spend; clamps at 0. Emits `sky_darkened` once per sky crossed (a lump can cross two).
## The ninth sky ends the run (if one is live) and the Iteration. Returns the skies crossed.
## Never saves (die / abandon save after it).
func consume_clock(loop_min: float, _cause: StringName) -> int:
	if not _iteration.started or _iteration.skies_dark >= stats.skies or loop_min <= 0.0:
		return 0
	_iteration.loop_min_left = maxf(0.0, _iteration.loop_min_left - loop_min)
	var spent := stats.iteration_budget_loop_min - _iteration.loop_min_left
	var dark := mini(stats.skies, floori(spent / stats.sky_size_loop_min() + _SKY_EPS))
	if _iteration.loop_min_left <= 0.0:
		dark = stats.skies
	var before := _iteration.skies_dark
	for s in range(before + 1, dark + 1):
		_iteration.skies_dark = s
		sky_darkened.emit(s)
	if _iteration.skies_dark >= stats.skies and before < stats.skies:
		_on_ninth_sky()
	return maxi(0, _iteration.skies_dark - before)


func _on_ninth_sky() -> void:
	if _run.is_active():
		_end_run(OUTCOME_NINTH_SKY)
	iteration_ended.emit()


# --- reads (callers never mutate the returned objects) ---------------------------------------------

## How many runs have ended on this profile (a plain `extra` key `runs_ended`, saved with the profile).
func runs_ended() -> int:
	var v: Variant = _profile.extra.get("runs_ended", 0)
	return int(v) if typeof(v) == TYPE_INT or typeof(v) == TYPE_FLOAT else 0


func run() -> RunState:
	return _run


func iteration() -> IterationState:
	return _iteration


func profile() -> ProfileState:
	return _profile


func loop_min_left() -> float:
	return _iteration.loop_min_left


func skies_dark() -> int:
	return _iteration.skies_dark


func in_seam() -> bool:
	return _in_seam


## SYS-001 §6: in a run the Hourglass shows at ≤ the threshold.
func hourglass_visible() -> bool:
	return _run.is_active() and _iteration.started \
		and _iteration.loop_min_left <= stats.show_threshold_loop_min + _SKY_EPS


## The four warp drives at Seam entry (WARP-001 §1.2, §1.3), read by the sector's WarpComposer, which
## computes the tier. The tier itself is never saved (WARP-001 §1.5). Slice values: the run plays Act 1
## (WARP_ACT_SLICE until LOOP-001 act progression is built, TECH-001 Q-T200); no Entropy selector and
## no Hollow sector exist yet, so those terms are 0.
func warp_inputs() -> Dictionary:
	return {
		"act": WARP_ACT_SLICE,
		"entropy": 0,
		"hollow": false,
		"composure_zero": _run.composure == 0.0,
		"seam_index": maxi(1, _run.seam_index),
		"seed": _run.seed_value,
	}


## The WarpComposer reports each effective tier it enters (warp_tier_set).
func note_warp_tier(tier: int) -> void:
	warp_max = maxi(warp_max, tier)


# --- snapshot / restore ----------------------------------------------------------------------------

func snapshot(slot: StringName) -> Dictionary:
	match slot:
		SLOT_PROFILE:
			return _profile.to_payload()
		SLOT_ITERATION:
			return _iteration.to_payload()
		SLOT_RUN:
			return _run.to_payload()
	return {}


## Loads one slot. Rejects unknown keys (run, iteration) and non-number/id values; on false the
## held state is unchanged.
func restore(slot: StringName, payload: Dictionary) -> bool:
	match slot:
		SLOT_PROFILE:
			var p := ProfileState.from_payload(payload)
			if p == null:
				return false
			_profile = p
			return true
		SLOT_ITERATION:
			var i := IterationState.from_payload(payload)
			if i == null:
				return false
			_iteration = i
			return true
		SLOT_RUN:
			var r := RunState.from_payload(payload)
			if r == null:
				return false
			_run = r
			_in_seam = false
			return true
	return false


func _save(slot: StringName, reason: StringName) -> void:
	if _saver == null:
		return
	if slot == SLOT_PROFILE and not _profile_writable:
		push_warning("RunSession: profile on disk is unreadable; not overwriting it")
		return
	_saver.call(&"save_slot", slot, snapshot(slot), reason)
