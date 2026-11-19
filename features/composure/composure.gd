class_name Composure
extends Node
## Composure (GDD §8.6, SYS-001 §1.5): 0–10, starts at 10 (Clear, Q-T118). No passive regen: it
## moves only through the event rows below, clamped to [min_value, max_value].
## Sector-scoped for M1 (one per SectorStub); it moves to RunSession when that is built (TECH-001 §2.8).
##
## Wired in the M1 sandbox: `charge_lost` (ChargeLauncher, a Charge destroyed by an interceptor) and
## `charge_spent` (Δ 0). Every other row is API only and inert until its source exists.
## Band effects (false cues, phantom Grubs, axis inversion, +1 tier) are not built: display only.
##
## Readers poll `value` / `band` (CockpitFlame, ComposureWick, probes). No signals. On entering a
## worse band it requests E01/E02/E03, on recovering to a better band E04 (AUDIO-001 §6.2, §6.5).

enum Band { CLEAR, FRAYED, UNMOORED, HOLLOWED }

## AUDIO-001 §6.2 E01–E04. Not in data/audio/cue_ids.tres yet: AudioService.play is a silent no-op.
const CUE_FRAYED := &"wick_frayed"
const CUE_UNMOORED := &"wick_unmoored"
const CUE_HOLLOWED := &"wick_hollowed"
const CUE_RECOVERY := &"wick_recovery"
const BAND_NAMES: Array[String] = ["clear", "frayed", "unmoored", "hollowed"]

@export var stats: ComposureStats

var value: float = 0.0
var band: Band = Band.CLEAR
## Play time this component has counted (drives death recovery and the Surgelight cap).
var clock_s: float = 0.0
## Cue sink (id, volume_db). Tests replace it.
var sfx: Callable = AudioService.play

## Death penalty still owed back (restored once `_death_left_s` runs out).
var _death_owed: float = 0.0
var _death_left_s: float = 0.0
## Surgelight drains in the last second: [time_s, magnitude] pairs.
var _surge_log: Array[Vector2] = []
## Darkness spell: seconds in darkness without firing, and Composure already given this spell.
var _dark_s: float = 0.0
var _dark_given: float = 0.0


func _ready() -> void:
	reset()


## Back to the start value (Clear). No cue: nothing was entered.
func reset() -> void:
	value = stats.start_value if stats else 0.0
	band = band_for(value, stats)
	clock_s = 0.0
	_death_owed = 0.0
	_death_left_s = 0.0
	_surge_log.clear()
	_dark_s = 0.0
	_dark_given = 0.0


func _physics_process(delta: float) -> void:
	tick(delta)


## Advances play time: restores a recovered death penalty. Nothing else moves by itself.
func tick(delta: float) -> void:
	clock_s += delta
	if _death_owed > 0.0:
		_death_left_s -= delta
		if _death_left_s <= 0.0:
			var owed := _death_owed
			_death_owed = 0.0
			change(owed)


## Adds `delta` (clamped) and updates the band. Returns the change actually applied.
func change(delta: float) -> float:
	if stats == null:
		return 0.0
	var before := value
	value = clampf(value + delta, stats.min_value, stats.max_value)
	_update_band()
	return value - before


func band_name() -> String:
	return BAND_NAMES[band]


# --- per-second rows (callers pass their frame delta) ---------------------------------------------

func gaze_cone(delta: float) -> float:
	return change(stats.gaze_cone_per_s * delta)


## Aim cursor resting inside the entity's silhouette; only from Warp Tier gaze_drain_min_tier.
func gaze_drain(delta: float, tier: int) -> float:
	return change(stats.gaze_drain_per_s * delta) if tier >= stats.gaze_drain_min_tier else 0.0


func chant_radius(delta: float) -> float:
	return change(stats.chant_radius_per_s * delta)


func warp_passive(delta: float, tier: int) -> float:
	return change(stats.warp_passive_per_s_per_tier * float(maxi(0, tier)) * delta)


## "5 s in darkness, no firing": call every frame. Firing or light ends the spell.
func darkness(delta: float, in_darkness: bool, fired: bool) -> float:
	if not in_darkness or fired:
		_dark_s = 0.0
		_dark_given = 0.0
		return 0.0
	var before_s := _dark_s
	_dark_s += delta
	var earning_s := _dark_s - maxf(before_s, stats.darkness_delay_s)
	if earning_s <= 0.0:
		return 0.0
	var gain := minf(stats.darkness_per_s * earning_s, stats.darkness_cap - _dark_given)
	if gain <= 0.0:
		return 0.0
	_dark_given += gain
	return change(gain)


# --- one-shot rows --------------------------------------------------------------------------------

func charge_lost() -> float:
	return change(stats.charge_lost)


func charge_spent() -> float:
	return change(stats.charge_spent)


## A death costs `death` at the next run start and is given back after death_recover_s of play.
func death_at_run_start() -> float:
	var applied := change(stats.death)
	_death_owed += -applied
	_death_left_s = stats.death_recover_s
	return applied


## One Surgelight use; costs only at Warp Tier >= surgelight_min_tier, never more than
## surgelight_max_per_s in any one second.
func surgelight_used(tier: int) -> float:
	if tier < stats.surgelight_min_tier:
		return 0.0
	var spent := 0.0
	var keep: Array[Vector2] = []
	for e: Vector2 in _surge_log:
		if clock_s - e.x < 1.0 - 1e-6:
			keep.append(e)
			spent += e.y
	_surge_log = keep
	var cost := minf(absf(stats.surgelight_use), maxf(0.0, stats.surgelight_max_per_s - spent))
	if cost <= 0.0:
		return 0.0
	_surge_log.append(Vector2(clock_s, cost))
	return change(-cost)


func shrine_destroyed() -> float:
	return change(stats.shrine_destroyed)


func matron_killed() -> float:
	return change(stats.matron_killed)


func procession_let_pass() -> float:
	return change(stats.procession_let_pass)


## Reading a Codex entry in the Ruins: full restore.
func codex_read() -> float:
	return change(stats.max_value - value)


func clear_eyed() -> float:
	return change(stats.clear_eyed)


# --- bands ----------------------------------------------------------------------------------------

## SYS-001 §1.5 bands; fractional values: Clear >= 7, Frayed >= 4, Unmoored > 0, Hollowed == 0.
static func band_for(v: float, s: ComposureStats) -> Band:
	if s == null:
		return Band.CLEAR
	if v >= s.clear_floor - 1e-6:
		return Band.CLEAR
	if v >= s.frayed_floor - 1e-6:
		return Band.FRAYED
	if v > s.min_value + 1e-6:
		return Band.UNMOORED
	return Band.HOLLOWED


## The cue for moving from band `from` to band `to` (&"" when the band did not change).
static func cue_for(from: Band, to: Band) -> StringName:
	if to == from:
		return &""
	if to < from:
		return CUE_RECOVERY
	match to:
		Band.FRAYED:
			return CUE_FRAYED
		Band.UNMOORED:
			return CUE_UNMOORED
		Band.HOLLOWED:
			return CUE_HOLLOWED
	return &""


func _update_band() -> void:
	var nb := band_for(value, stats)
	var cue := cue_for(band, nb)
	band = nb
	if cue != &"" and sfx.is_valid():
		sfx.call(cue, 0.0)
