class_name WarpSet
extends TunableResource
## One tier's effect set and its presentation tunables (WARP-001 §2.2 for T1). data/warp/t1_frayed.tres
## (`ds_warp.t1.*`). Game numbers are SYS-001 §9 "Warp T1 presentation" rows (proposed 2026-11-19);
## `✱` engineering params are TECH-001 §5.1a.

@export var tier: int = 1
## Every row of the slice's T1 set (Q-T100): standing W1-01/02/03/05/08, transient W1-07/09/10, and
## W1-06 on dropping to Frayed.
@export var effects: Array[WarpEffect] = []

## SYS-001 §9 `Warp entry quiet` (WARP-001 §1.4: no effect within the first 2 s of a Seam).
@export var entry_quiet_s: float = 0.0
## GDD §16 R-02: at most this many novel transient effects per sector.
@export var novel_per_sector: int = 0
## SYS-001 §9 `Warp frame budget` (1.2 ms on min spec).
@export var budget_ms: float = 0.0
## Standing-effect strength by Seam (index 0 = Seam 1): how the T1 costume deepens through a run
## inside the Act 1 window (SYS-001 §9 `Warp T1 seam depth`).
@export var seam_depth: PackedFloat32Array = PackedFloat32Array()

## W1-02 Breathing (WARP-001 §2.2: ±1 px).
@export var breath_px: float = 0.0
@export var breath_period_s: float = 0.0
## How fast the breath travels outward from the Vigil (px/s): the field breathes as one wave.
@export var breath_wave_px_s: float = 0.0

## W1-05 Teeth in the Rock: teeth per geode face ring and their length (px).
@export var teeth_count: int = 0
@export var teeth_len_px: float = 0.0

## W1-06 Chromatic Edge: SYS-001 §1.5 Frayed row (≤ 2 px).
@export var chromatic_edge_px: float = 0.0

## W1-07 False Chant: SYS-001 §1.5 Frayed row (1 false cue per 40 s) and the cue's length.
@export var false_chant_period_s: float = 0.0
@export var false_chant_s: float = 0.0
## Distance of the false source from the Vigil (px), off-screen at 640×360.
@export var false_chant_distance_px: float = 0.0

## W1-09 Smudged Blip / W1-10 Ledger Smudge: one each per sector, starting inside this window.
@export var transient_earliest_s: float = 0.0
@export var transient_latest_s: float = 0.0
@export var blip_lag_s: float = 0.0
@export var blip_smear_s: float = 0.0
@export var glyph_s: float = 0.0


func tunable_properties() -> PackedStringArray:
	return PackedStringArray(["entry_quiet_s", "novel_per_sector", "budget_ms", "seam_depth",
		"breath_px", "breath_period_s", "breath_wave_px_s", "teeth_count", "teeth_len_px",
		"chromatic_edge_px", "false_chant_period_s", "false_chant_s", "false_chant_distance_px",
		"transient_earliest_s", "transient_latest_s", "blip_lag_s", "blip_smear_s", "glyph_s"])


func effect(effect_id: StringName) -> WarpEffect:
	for e in effects:
		if e.id == effect_id:
			return e
	return null


func ids() -> Array[StringName]:
	var out: Array[StringName] = []
	for e in effects:
		out.append(e.id)
	return out


## Strength of the standing set in Seam `seam_index` (1-based), 1.0 when unset.
func depth_for_seam(seam_index: int) -> float:
	if seam_depth.is_empty():
		return 1.0
	return seam_depth[clampi(seam_index - 1, 0, seam_depth.size() - 1)]


## WARP-001 §5.2 L-05: standing sum + the two largest transient peaks.
func worst_case_ms() -> float:
	var standing := 0.0
	var peaks: Array[float] = []
	for e in effects:
		if e.is_standing():
			standing += e.ms_standing
		else:
			peaks.append(e.ms_transient)
	peaks.sort()
	peaks.reverse()
	var transient := 0.0
	for i in mini(2, peaks.size()):
		transient += peaks[i]
	return standing + transient
