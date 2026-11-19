class_name AetherFarLeash
extends TunableResource
## Long-flight tuning for the Aether far layer (Q-T127 option B: SectorHost passes a continuous camera
## centre that can run 1e5 px from the sector origin; set_field resets the origin per sector).
## Engineering ✱, not game numbers. AetherFarTravel reads it. File: data/aether/leash/far_leash.tres.
## Landmarks (the Presence, the leviathan, the far set pieces, the sky sphere with the still smudge,
## the entity layer): their parallax displacement from the authored framing is pulled back toward the
## view by a critically damped spring, soft-capped, and rate-limited per frame, so they drift off at
## most `cap_px` and come back without anyone seeing them move.
## Fog bands: their parallax offset reaches the shader wrapped into ±band_period_px / 2 per axis, and
## each wrap is hidden by a crossfade `wrap_window_px` wide on either side.

## ✱ time constant (s) of the critically damped pull back toward the authored framing.
@export var time_constant_s: float = 20.0
## ✱ the most a landmark is ever displaced from its authored framing (logical px, before zoom).
@export var cap_px: float = 180.0
## ✱ the leash's internal state is held within saturation × cap_px (the soft cap is ≥ 96 % there),
## so a long flight never winds it up and the return starts as soon as the flight stops.
@export var saturation: float = 2.0
## ✱ the most a landmark's displacement may change in one frame (logical px): no pop, ever.
@export var max_step_px: float = 3.0
## ✱ fog-band wrap period (band px). Offsets reach the shader in ±period / 2: float32 ulp there is
## under 0.002 px. Much larger than any visible extent (the cover rect is 1120 px wide).
@export var band_period_px: float = 32768.0
## ✱ band px on either side of a wrap over which the wrap is hidden (crossfade / fade).
@export var wrap_window_px: float = 1024.0


func tunable_properties() -> PackedStringArray:
	return PackedStringArray(["time_constant_s", "cap_px", "saturation", "max_step_px", "band_period_px", "wrap_window_px"])
