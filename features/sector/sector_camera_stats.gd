class_name SectorCameraStats
extends TunableResource
## Sector camera tunables. Values are copied from SYS-001 §9 into data/sector/sector_camera.tres.
## Never edit numbers here; edit the .tres (and SYS-001 first).

## SYS-001 §9 "Camera follow 0.12 s critically damped" (s). Read as the smoothing time T of a
## critically damped spring with omega = 2 / T (SmoothDamp convention). Interpretation: needs a ruling.
@export var follow_time_s: float = 0.0
## SYS-001 §9 "24 px deadzone" (px). Read as a circle radius around the camera focus.
## Interpretation: needs a ruling (radius vs. half-box vs. full box width).
@export var deadzone_px: float = 0.0
## SYS-001 §9 "1.5% aim lookahead" as a fraction (0.015) of the visible viewport size, applied per
## axis along the aim direction (at 640×360: up to 9.6 px horizontally, 5.4 px vertically).
## Interpretation: needs a ruling.
@export var aim_lookahead_frac: float = 0.0
## SYS-001 §9 "Screen shake ≤ 4 px" (px). Hard ceiling; warp shake (≤ 2 px) stacks inside it.
@export var shake_max_px: float = 0.0
## SYS-001 §9 "Screen shake 0.25 s max" (s).
@export var shake_max_s: float = 0.0
## SYS-001 §9 "Zoom 1.0 (T0)". Q-T25 resolved as Z1: zoom 1 is the 640×360 frame and stays fixed.
@export var zoom: float = 0.0
## ✱ D-3 (accepted): no screen shake under Settings `reduced_motion`. One flag so it can flip.
@export var shake_off_under_reduced_motion: bool = true


func tunable_properties() -> PackedStringArray:
	return PackedStringArray(["follow_time_s", "deadzone_px", "aim_lookahead_frac", "shake_max_px",
		"shake_max_s", "zoom", "shake_off_under_reduced_motion"])
