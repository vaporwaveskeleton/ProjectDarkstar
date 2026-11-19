class_name ComposureStats
extends TunableResource
## Composure tunables (SYS-001 §1.5; start value TECH-001 Q-T118). Values live in
## data/composure/composure.tres (`ds_composure.*`). Signs are the Δ Composure of the SYS-001 row:
## negative drains, positive restores.

## SYS-001 §1.5 scale 0–10 (🔒).
@export var min_value: float = 0.0
@export var max_value: float = 0.0
## Q-T118 (PM, 2026-11-19): a run starts Clear, at 10.
@export var start_value: float = 0.0

## Band floors (SYS-001 §1.5 Bands: Clear 10–7, Frayed 6–4, Unmoored 3–1, Hollowed 0). Fractional
## values: Clear >= clear_floor, Frayed >= frayed_floor, Unmoored > min_value, Hollowed == min_value.
@export var clear_floor: float = 0.0
@export var frayed_floor: float = 0.0

## Per-second rows (🔒 unless noted).
@export var gaze_cone_per_s: float = 0.0
## Aim cursor inside the entity's silhouette, T3+ (PM-approved 2026-11-18).
@export var gaze_drain_per_s: float = 0.0
@export var gaze_drain_min_tier: int = 0
@export var chant_radius_per_s: float = 0.0
## Multiplied by the Warp Tier T.
@export var warp_passive_per_s_per_tier: float = 0.0

## One-shot rows.
@export var charge_lost: float = 0.0
## ✱ spend is not punished (0).
@export var charge_spent: float = 0.0
## Applied at run start after a death; restored after `death_recover_s` of play.
@export var death: float = 0.0
@export var death_recover_s: float = 0.0
## ✱ per Surgelight use at Warp Tier >= surgelight_min_tier, at most surgelight_max_per_s per second.
@export var surgelight_use: float = 0.0
@export var surgelight_min_tier: int = 0
@export var surgelight_max_per_s: float = 0.0
@export var shrine_destroyed: float = 0.0
@export var matron_killed: float = 0.0
## ZONES-001 §6.6 (PM-approved 2026-11-18).
@export var procession_let_pass: float = 0.0
## "5 s in darkness, no firing": after darkness_delay_s, +darkness_per_s, at most darkness_cap per spell.
@export var darkness_delay_s: float = 0.0
@export var darkness_per_s: float = 0.0
@export var darkness_cap: float = 0.0
## Clear Eyed (MADNESS-5): −1 (its 20 s T-effect-off is Warp's, not Composure's).
@export var clear_eyed: float = 0.0
## Reading a Codex entry in the Ruins restores to max_value (no field: "full restore").


func tunable_properties() -> PackedStringArray:
	return PackedStringArray([
		"min_value", "max_value", "start_value", "clear_floor", "frayed_floor",
		"gaze_cone_per_s", "gaze_drain_per_s", "gaze_drain_min_tier", "chant_radius_per_s",
		"warp_passive_per_s_per_tier", "charge_lost", "charge_spent", "death", "death_recover_s",
		"surgelight_use", "surgelight_min_tier", "surgelight_max_per_s", "shrine_destroyed",
		"matron_killed", "procession_let_pass", "darkness_delay_s", "darkness_per_s", "darkness_cap",
		"clear_eyed"])
