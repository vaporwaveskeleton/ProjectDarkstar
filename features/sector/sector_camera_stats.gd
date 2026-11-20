class_name SectorCameraStats
extends TunableResource
## Sector camera tunables. Values are copied from SYS-001 §9 into data/sector/sector_camera.tres.
## Never edit numbers here; edit the .tres (and SYS-001 first).

## SYS-001 §9 "Camera follow 0.12 s critically damped" (s). Read as the smoothing time T of a
## critically damped spring with omega = 2 / T (SmoothDamp convention). Accepted reading (Q-T56).
@export var follow_time_s: float = 0.0
## SYS-001 §9 "24 px deadzone" (px). A circle radius around the camera focus (accepted reading Q-T57).
@export var deadzone_px: float = 0.0
## SYS-001 §9 "1.5% aim lookahead" as a fraction (0.015) of the visible viewport size, applied per
## axis along the aim direction (at 640×360: up to 9.6 px horizontally, 5.4 px vertically).
## Accepted reading (Q-T55).
@export var aim_lookahead_frac: float = 0.0
## SYS-001 §9 "Screen shake ≤ 4 px" (px). Hard ceiling; warp shake (≤ 2 px) stacks inside it.
@export var shake_max_px: float = 0.0
## SYS-001 §9 "Screen shake 0.25 s max" (s).
@export var shake_max_s: float = 0.0
## SYS-001 §9 "Zoom 1.0 (T0)". Q-T25 resolved as Z1: zoom 1 is the 640×360 frame and stays fixed.
@export var zoom: float = 0.0
## ✱ D-3 (accepted): no screen shake under Settings `reduced_motion`. One flag so it can flip.
@export var shake_off_under_reduced_motion: bool = true

## SYS-001 §9 "Race framing reach" (px, proposed 2026-11-19): race points farther than this from
## the Vigil (torus distance) are ignored by the RaceFramer.
@export var race_reach_px: float = 0.0
## SYS-001 §9 "Race framing lean max" (fraction of the half view per axis, proposed 2026-11-19):
## the camera never leans further, so the Vigil always stays on screen.
@export var race_lean_max_frac: float = 0.0
## SYS-001 §9 "Race framing lean time" (s, proposed 2026-11-19): smoothing time of the lean spring.
@export var race_lean_time_s: float = 0.0
## SYS-001 §9 "Race pull-out zoom" (proposed 2026-11-19, Q-T211): the floor of the fitted pull-out
## (Q-T355): the camera eases to the zoom that fits the race, never below this. 0 = off.
@export var race_pull_zoom: float = 0.0
## SYS-001 §9 "Race pull-out max" (s, proposed 2026-11-19, Q-T211): the longest one pull-out lasts when
## no Charge is in flight (a Grub theft). A Charge's flight holds the pull for its whole life (Q-T355).
@export var race_pull_max_s: float = 0.0
## SYS-001 §9 "Race fit margin" (px, proposed 2026-11-19 overnight, Q-T355): the screen margin the
## fitted pull-out keeps between the outermost race point and the frame edge.
@export var race_fit_margin_px: float = 0.0
## ✱ (Q-T356, D-3 reading): no race pull-out under Settings `reduced_motion` (the zoom never moves; the
## edge markers carry the race). One flag so it can flip.
@export var race_pull_off_under_reduced_motion: bool = true


func tunable_properties() -> PackedStringArray:
	return PackedStringArray(["follow_time_s", "deadzone_px", "aim_lookahead_frac", "shake_max_px",
		"shake_max_s", "zoom", "shake_off_under_reduced_motion", "race_reach_px", "race_lean_max_frac",
		"race_lean_time_s", "race_pull_zoom", "race_pull_max_s", "race_fit_margin_px",
		"race_pull_off_under_reduced_motion"])
