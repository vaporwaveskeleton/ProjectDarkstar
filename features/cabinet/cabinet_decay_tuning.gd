class_name CabinetDecayTuning
extends TunableResource
## The Decay (GDD-001 §6.1 A0-5; WARP-001 W0-07 / W0-11; ART-001 §12.7b; AUDIO-001 §12.18): the wordless
## wearing-out of the Cabinet's costume that replaces the old title card. Every value is a SYS-001 §9
## `ds_cabinet.decay.*` / `ds_cabinet.wear.*` row (PM under owner autonomy grant 2026-11-19, TECH-001 Q-T184).
## Fields marked ✱ are engineering presentation params (TECH-001 §3.4), not SYS-001 rows.

# --- Beats (s) ---
@export var attract_s: float = 2.0                    ## D1 back to attract
@export var phosphor_s: float = 4.0                   ## D2 tired phosphor
@export var skin_s: float = 5.0                       ## D3 the skin fails
@export var collapse_s: float = 2.0                   ## D4 collapse to a dot (line, dot, hold)
@export var collapse_squeeze_s: float = 0.8           ## ✱ of collapse_s spent squeezing to the line and the dot
@export var collapse_silence_s: float = 1.2           ## total silence while the dot holds

# --- Screen (layer one) ---
@export var persistence_max: float = 0.6              ## ghost alpha at the end of D2
@export var bloom_bleed_px_max: float = 2.0           ## grid px at the end of D3
@export var raster_shrink_max: float = 0.15           ## share of picture height lost by the end of D3
@export var register_drift_steps: int = 1             ## RGB332 steps per drifting register
@export var register_drift_interval_s: float = 0.8    ## one write per interval across D2–D3
@export var drift_registers: PackedInt32Array = PackedInt32Array([1, 2, 3, 4, 5, 6])   ## VOID and BONE only (ART-001 §15.2a)
@export var blink_period_start_s: float = 1.0         ## INSERT CREDIT, ART-001 §12.7
@export var blink_period_end_s: float = 2.4
@export var glyph_drop_per_blink: int = 1
@export var glyph_drop_still_interval_s: float = 1.0  ## ✱ photosensitivity: one glyph per this, no blink

# --- Bezel ---
@export var bulb_die_interval_s: float = 0.06               ## retuned from the first capture (was 0.5: 10 of ~88 bulbs died)
@export var bulb_dim_s: float = 0.2                   ## ✱ each bulb dims out over this, never a flicker
@export var print_bleach_max: float = 0.7
@export var worn_through_light_max: float = 0.9     ## retuned from the first capture (was 0.35: read as grey smudges, not light)

# --- Sound ---
@export var shell_detune_cents_end: float = -40.0
@export var hum_hz_start: float = 50.0                ## AUDIO-001 §2.1 ✱
@export var hum_hz_end: float = 47.0
@export var hum_db: float = -26.0                     ## AUDIO-001 §2.1 "extra" row level ✱
@export var shell_db: float = -14.0                   ## AUDIO-001 §2.1 layer A level ✱

# --- The cursed turn (PROPOSED, PM under owner direction 2026-11-19 overnight push, TECH-001 Q-T260–Q-T263) ---
@export var focus_play: Vector2 = Vector2(0.7, 0.38)  ## where the Cabinet looks back from: fraction of the play view (x, y), off-centre
@export var bulge_max: float = 0.9                    ## the glass's swell at the end of D3 (0..1)
@export var bulge_radius: float = 0.3                 ## ✱ the swell's radius, share of the screen height
@export var breath_hz: float = 0.22                   ## the hum breathes this slowly across D2–D3 (one breath ≈ 4.5 s)
@export var breath_db: float = 7.0                    ## how far the hum swells on each in-breath

# --- Ending 5 ---
@export var ending5_line_hold_s: float = 4.0

# --- Wear (W0-11) ---
@export var wear_level_by_stage: PackedInt32Array = PackedInt32Array([1, 2, 3])
@export var wear_detune_cents_per_level: float = -2.0
@export var wear_dead_bulbs_per_level: int = 1
@export var wear_bleach_per_level: float = 0.06       ## ✱ edge bleach per wear level (≪ print_bleach_max)


## Seconds from d = 0 to the tear (D1–D4).
func total_s() -> float:
	return attract_s + phosphor_s + skin_s + collapse_s


## Start of each beat: [D1, D2, D3, D4, tear].
func marks() -> PackedFloat32Array:
	var a := attract_s
	var b := a + phosphor_s
	var c := b + skin_s
	return PackedFloat32Array([0.0, a, b, c, c + collapse_s])


## Beat number 1..4 at decay time `t`, 5 once the tear is due.
func beat_at(t: float) -> int:
	var m := marks()
	for i in range(4, 0, -1):
		if t >= m[i]:
			return i + 1
	return 1


## 0..1 progress through D2 (phosphor) at `t`.
func phosphor_k(t: float) -> float:
	var m := marks()
	return clampf((t - m[1]) / phosphor_s, 0.0, 1.0)


## 0..1 progress through D3 (skin) at `t`.
func skin_k(t: float) -> float:
	var m := marks()
	return clampf((t - m[2]) / skin_s, 0.0, 1.0)


## 0..1 progress of the CRT collapse uniform during D4 (the squeeze, then held at the dot).
func collapse_k(t: float) -> float:
	var m := marks()
	return clampf((t - m[3]) / maxf(collapse_squeeze_s, 0.001), 0.0, 1.0)


## 0..1 the glass's swell at `t`: from D2's start to D3's end, easing in (the lean grows), held through D4.
func bulge_k(t: float) -> float:
	var m := marks()
	var k := clampf((t - m[1]) / (m[3] - m[1]), 0.0, 1.0)
	return k * k * (3.0 - 2.0 * k)


## The focus in whole-screen UV, given the UV y of the HUD strip's bottom (`play_top`).
func focus_uv(play_top: float) -> Vector2:
	return Vector2(focus_play.x, play_top + (1.0 - play_top) * focus_play.y)


## Wear level for stage index `i` (0 outside the table).
func wear_level(i: int) -> int:
	return wear_level_by_stage[i] if i >= 0 and i < wear_level_by_stage.size() else 0


## The INSERT CREDIT blink period at `t` (slows across D2).
func blink_period(t: float) -> float:
	return lerpf(blink_period_start_s, blink_period_end_s, phosphor_k(t))


## Pitch scale for a detune in cents.
static func cents_to_pitch(cents: float) -> float:
	return pow(2.0, cents / 1200.0)
