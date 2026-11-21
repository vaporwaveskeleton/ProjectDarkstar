class_name CabinetHauntTuning
extends TunableResource
## W0-12 Hauntings (WARP-001 T0; TECH-001 Q-T250–Q-T259, PM under owner direction 2026-11-19 overnight push):
## small, deniable wrongnesses of the Cabinet's costume from a0_3 on, rare and seeded so the player doubts
## what they saw. Every value is a SYS-001 §9 `ds_cabinet.haunt.*` row, all PROPOSED; ✱ = engineering.

# --- When (moments and odds) ---
@export var min_wear_level: int = 1                  ## a stage haunts only from this wear level (a0_3, W0-11)
@export var attract_min_stage: int = 0               ## the attract haunts once the profile has reached this stage index (0 = a0_3, the first stage since F-14) or finished Act 0
@export var chance_ready: float = 0.35               ## odds a READY card haunts (one kind at most)
@export var chance_hold: float = 0.3                 ## odds a stage-end hold haunts
@export var chance_attract: float = 0.2              ## odds an attract page cycle haunts when it wraps
@export var chance_coin: float = 0.25                ## odds a coin comes back warm
@export var chance_demo: float = 0.3                 ## odds the demo shows the figure once

# --- What ---
@export var figure_frames: int = 1                   ## the figure in the field, and the one on the crag, last this many drawn frames (one field at 60 Hz)
@export var after_image_in_s: float = 0.4            ## the after-image of the never-drawn spine: fade in, hold, fade out (inside the 2.5 s READY card)
@export var after_image_hold_s: float = 0.8
@export var after_image_out_s: float = 1.2
@export var breath_s: float = 4.5                    ## one breath of the hum (in and out)
@export var breath_db: float = 6.0                   ## the hum's swell at the top of the breath
@export var litany_dips: PackedInt32Array = PackedInt32Array([3, 3, 2])   ## the marquee's dips: nine syllables sung in eight (NARR-001 §2.1)
@export var litany_step_s: float = 0.42              ## from one dip to the next (≤ 2.4 per second: under the 3-per-second flash rule)
@export var litany_group_gap_s: float = 0.42         ## extra pause between the groups
@export var litany_depth: float = 0.22               ## share of the marquee's light lost at the bottom of a dip
@export var ghost_press_s: float = 0.9               ## the service button holds itself down this long
@export var warm_coin_s: float = 3.0                 ## the coin return glows like an ember, fading over this
@export var jingle_detune_cents: float = -60.0       ## ✱ informational: the sour jingle is rendered this flat (audio/src/cabinet.cx.js)


## Seconds from the litany's start to the start of each dip, in order.
func litany_times() -> PackedFloat32Array:
	var out := PackedFloat32Array()
	var t := 0.0
	for g in litany_dips.size():
		for d in litany_dips[g]:
			out.append(t)
			t += litany_step_s
		t += litany_group_gap_s
	return out


## The litany's whole length (s).
func litany_s() -> float:
	var ts := litany_times()
	return (ts[ts.size() - 1] + litany_step_s) if not ts.is_empty() else 0.0


## 0..1 light lost at litany time `t`: each dip a smooth sin² of litany_step_s, never a hard edge.
func litany_dim(t: float) -> float:
	if t < 0.0:
		return 0.0
	for s in litany_times():
		var u := (t - s) / litany_step_s
		if u >= 0.0 and u < 1.0:
			var k := sin(PI * u)
			return litany_depth * k * k
	return 0.0


## 0..1 the after-image's strength at `t` from its start.
func after_image_k(t: float) -> float:
	if t < 0.0:
		return 0.0
	if t < after_image_in_s:
		return t / after_image_in_s
	t -= after_image_in_s
	if t < after_image_hold_s:
		return 1.0
	t -= after_image_hold_s
	return clampf(1.0 - t / after_image_out_s, 0.0, 1.0)


func after_image_s() -> float:
	return after_image_in_s + after_image_hold_s + after_image_out_s


## dB added to the hum at `t` from a breath's start (sin² in, sin² out; no onset).
func breath_gain_db(t: float) -> float:
	if t < 0.0 or t >= breath_s:
		return 0.0
	var s := sin(PI * t / breath_s)
	return breath_db * s * s

