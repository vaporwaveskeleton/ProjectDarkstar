class_name RunSessionStats
extends TunableResource
## RunSession tunables (TECH-001 §4.2a). Values live in data/run/run_session.tres (`ds_run.session.*`),
## copied from SYS-001 §6 (Hourglass Clock) and §7.1 / §7.2 (Ember). ✱ = engineering or playtest value.

## SYS-001 §6: 120 loop-minutes per Iteration at Entropy 0 🔒. Above Entropy 0 is deferred (Q-T137):
## the slice is Entropy 0 only, so there is no Entropy scaling here yet.
@export var iteration_budget_loop_min: float = 0.0
## SYS-001 §6: a sky darkens each time one ninth of the budget is spent; the ninth ends the run.
@export var skies: int = 0
## SYS-001 §6 (Q-T136, PM 2026-11-19): 1 loop-minute = 1 real minute.
@export var loop_min_per_real_min: float = 0.0
## SYS-001 §6 death clock cost `base + per_seam × (Seam − 1)` loop-minutes ✱. Abandon costs the same (Q-T144).
@export var death_cost_base_loop_min: float = 0.0
@export var death_cost_per_seam_loop_min: float = 0.0
## SYS-001 §6 run-won refund ✱, clamped to the budget.
@export var win_refund_loop_min: float = 0.0
## SYS-001 §6 in-run Hourglass show threshold (≤ this many loop-minutes left).
@export var show_threshold_loop_min: float = 0.0
## Seams per run (LOOP-001 §2).
@export var seams_per_run: int = 0
## SYS-001 §7.2: Ember per Seam cleared, Seam 5 included (Q-T145).
@export var seam_clear_ember: int = 0
## SYS-001 §7.1: Ember = floor(score / score_per_ember). Also the Act 0 bank divisor.
@export var score_per_ember: int = 0
## SYS-001 §7.1 Act 0 bank floor (PM 2026-11-19, Q-T146): the tier-1 node price.
@export var act0_bank_floor_ember: int = 0
## Q-T140 (PM 2026-11-19): Composure and Charges carry between Seams unchanged. Off = each Seam
## starts from the sector defaults.
@export var carry_between_seams: bool = true
## ✱ engineering: seed of the throwaway run a sector builds when no session is handed in (dev route,
## M1 sandboxes, tests). Never saved.
@export var dev_seed: int = 0
## ✱ engineering (Q-T138): routes on which the clock never runs (attract mode; Act 0 never ticks).
@export var clock_free_routes: Array[StringName] = []


func tunable_properties() -> PackedStringArray:
	return PackedStringArray([
		"iteration_budget_loop_min", "skies", "loop_min_per_real_min", "death_cost_base_loop_min",
		"death_cost_per_seam_loop_min", "win_refund_loop_min", "show_threshold_loop_min",
		"seams_per_run", "seam_clear_ember", "score_per_ember", "act0_bank_floor_ember",
		"carry_between_seams", "dev_seed",
	])


## Loop-minutes per sky (derived: 13⅓ at the Entropy 0 budget).
func sky_size_loop_min() -> float:
	return iteration_budget_loop_min / float(maxi(1, skies))


## Death (and abandon) clock cost at `seam_index` (1-based).
func death_cost_loop_min(seam_index: int) -> float:
	return death_cost_base_loop_min + death_cost_per_seam_loop_min * float(maxi(0, seam_index - 1))
