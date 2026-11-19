class_name UnmakingTimeline
extends RefCounted
## The first Unmaking cinematic's clock, beats 4–6 (route &"aether", AetherArrival). Every duration and
## curve of the cinematic lives here and nowhere else; AetherArrival only reads it. Times are seconds
## of cinematic time `t` from the hand-off (the first frame of route &"aether", t = 0).
##
## Budget (GDD §6.1, PM ruling 2026-11-18, research/act1_vertical_slice.md §2 and §6.1): ≤ 90 s from the
## tear (0:04) to the Ruins (1:34). Beats 2–3 (the tear, the zoom) are Act 0's / PR D's and end at the
## hand-off. Arithmetic, wall clock from THAT WAS A PRETENCE.:
##   hand-off 0:12 (beat sheet: beat 3 the zoom 0:08–0:12)            HANDOFF_AT_S  = 12
##   beat 4 tear silence  0:12–0:32                                     BEAT4_S       = 20 (ruled)
##   beat 5 the arrival   0:32–1:12                                     BEAT5_S       = 40 (ruled, trimmed)
##   beat 6 the last light 1:12–1:34 = front reaches the lamp (10 s ✱) + lamp out (2 s ✱) + black (10 s, ruled)
##   12 + 20 + 40 + 22 = 94 s = tear 4 s + 90 s budget.            END_S (cinematic) = 82
## Everything not marked "ruled" is ✱ (engineering).

## Wall-clock budget (GDD §6.1): the tear at 0:04, ≤ 90 s from the tear to the Ruins.
const TEAR_AT_S := 4.0
const CINEMATIC_S := 90.0
## ✱ wall clock of the hand-off into route &"aether" (beat sheet: the zoom ends at 0:12).
const HANDOFF_AT_S := 12.0
const BEAT4_S := 20.0
const BEAT5_S := 40.0
## ✱ beat 6: the front reaches the lamp, the lamp dims (slow, no flash), then black with one ember.
const LAMP_REACH_S := 10.0
const LAMP_OUT_S := 2.0
const BLACK_S := 10.0
const BEAT6_S := LAMP_REACH_S + LAMP_OUT_S + BLACK_S

## Cinematic-time marks (t from the hand-off).
const BEAT5_AT := BEAT4_S
const BEAT6_AT := BEAT4_S + BEAT5_S
const LAMP_OUT_AT := BEAT6_AT + LAMP_REACH_S
const BLACK_AT := LAMP_OUT_AT + LAMP_OUT_S
const END_S := BLACK_AT + BLACK_S

## ✱ beat 4: the look-only tilt eases back to rest over the last TILT_RETURN_S of the beat.
const TILT_RETURN_S := 2.0
## ✱ beat 5: the Presence turns and leaves at the beat's start; the front starts once it has gone
## (FrostPresence.FLEE_S), so viewers see it leave before the black arrives (checklist #4).
const FLEE_AT := BEAT5_AT
const FRONT_AT := BEAT5_AT + 6.0
## ✱ the front's origin on screen (logical px at the hand-off camera): off-centre, inside the picture,
## up and left where the Presence fled, on the sphere seam (never a centred iris, never an edge: N8).
const FRONT_ORIGIN := Vector2(175.0, 125.0)
## ✱ the entity outline seed for the erasure: turns its ruled cut and sharp notch up and away, out of
## the frame, so the front sweeps the picture evenly toward the lamp.
const FRONT_SEED := 1.64
## ✱ front radius (px): grows as R_REACH·u^FRONT_EASE from FRONT_AT to the lamp (t = LAMP_REACH_AT),
## then on a monotone cubic to R_COVER at BLACK_AT (the frame filled from the inside), then on at
## V_COVER px/s (already off-frame: no visible change).
const LAMP_REACH_AT := BEAT6_AT + 6.0
const R_REACH := 380.0
const R_COVER := 860.0
const V_COVER := 120.0
const FRONT_EASE := 1.5
## ✱ fracture growth of the front's edge at full radius.
const FRONT_GROWTH := 0.6
## ✱ the world's cold cast over the erasure (drain above the look's base), slow.
const DRAIN_MAX := 0.3
## ✱ audio subtraction target, ramped from FRONT_AT to LAMP_REACH_AT (AudioService.set_subtraction).
const SUBTRACTION_MAX := 0.85
## ✱ the lamp's drift (logical px from the hand-off camera centre) by DRIFT_END_AT: the last coloured
## thing sits far from the front's origin, so the front reaches it last.
const LAMP_DRIFT := Vector2(150.0, 90.0)
const DRIFT_END_AT := LAMP_REACH_AT - 2.0
## ✱ the hull hint is eaten as the front arrives at it (seconds before LAMP_REACH_AT, and how long).
const HULL_EATEN_LEAD_S := 3.0
const HULL_EATEN_S := 3.0
## ✱ the ember's alpha when the lamp is out; it fades to 0 across the full BLACK_S (ruled).
const EMBER_PEAK := 0.9


static func beat_at(t: float) -> int:
	if t < BEAT5_AT:
		return 4
	if t < BEAT6_AT:
		return 5
	return 6


## Total seconds of route &"aether" (beats 4–6).
static func total_s() -> float:
	return BEAT4_S + BEAT5_S + BEAT6_S


## Wall clock (from THAT WAS A PRETENCE.) at which the cinematic ends on the Ruins.
static func ends_at_wall_s() -> float:
	return HANDOFF_AT_S + total_s()


## 1 during beat 4, easing to 0 over its last TILT_RETURN_S; 0 after.
static func tilt_weight(t: float) -> float:
	return 1.0 - smoothstep(BEAT5_AT - TILT_RETURN_S, BEAT5_AT, t)


## Front radius (logical px) at t; 0 before FRONT_AT. Monotone, C1 at the joins.
static func front_radius(t: float) -> float:
	if t <= FRONT_AT:
		return 0.0
	if t <= LAMP_REACH_AT:
		var u := (t - FRONT_AT) / (LAMP_REACH_AT - FRONT_AT)
		return R_REACH * pow(u, FRONT_EASE)
	if t <= BLACK_AT:
		var h := BLACK_AT - LAMP_REACH_AT
		var s := (t - LAMP_REACH_AT) / h
		var m0 := FRONT_EASE * R_REACH / (LAMP_REACH_AT - FRONT_AT) * h
		var m1 := V_COVER * h
		var s2 := s * s
		var s3 := s2 * s
		return (2.0 * s3 - 3.0 * s2 + 1.0) * R_REACH + (s3 - 2.0 * s2 + s) * m0 \
			+ (-2.0 * s3 + 3.0 * s2) * R_COVER + (s3 - s2) * m1
	return R_COVER + V_COVER * (t - BLACK_AT)


## The largest radius the front reaches (sizes the entity quad once).
static func front_reach() -> float:
	return front_radius(END_S) + 1.0


static func front_growth(t: float) -> float:
	return FRONT_GROWTH * smoothstep(FRONT_AT, LAMP_REACH_AT, t)


## Drain above the look's base: 0 until the front starts, then a slow cold cast.
static func drain(t: float) -> float:
	return DRAIN_MAX * smoothstep(FRONT_AT, LAMP_REACH_AT, t)


## The lamp's light 0..1: full until LAMP_OUT_AT, then a slow dim over LAMP_OUT_S (no flash).
static func lamp_light(t: float) -> float:
	return 1.0 - smoothstep(LAMP_OUT_AT, BLACK_AT, t)


## The phosphor ember 0..1: rises as the lamp dims (no pop), then fades across the full BLACK_S.
static func ember(t: float) -> float:
	if t < LAMP_OUT_AT:
		return 0.0
	if t < BLACK_AT:
		return EMBER_PEAK * smoothstep(LAMP_OUT_AT, BLACK_AT, t)
	return EMBER_PEAK * clampf(1.0 - (t - BLACK_AT) / BLACK_S, 0.0, 1.0)


## The unlit hull hint's alpha: eaten as the front arrives.
static func hull_alpha(t: float) -> float:
	var at := LAMP_REACH_AT - HULL_EATEN_LEAD_S
	return 1.0 - smoothstep(at, at + HULL_EATEN_S, t)


## The lamp's offset from the hand-off camera centre (logical px).
static func lamp_drift(t: float) -> Vector2:
	return LAMP_DRIFT * smoothstep(0.0, DRIFT_END_AT, t)
