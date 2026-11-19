class_name FrostPresence
extends AetherShaderRect
## The Pale Marches Presence (ZONES-001 §2.3, T1): a frost-drifting thing like a migrating ice shelf,
## with a slow heartbeat of light (frost_presence.gdshader). Bigger than the playfield, only ever
## seen cropped: its calving front crosses the top of the frame and the rest of it lies off-frame.
## Far layer only (the backdrop's PresenceLayer), never a hitbox (no physics body anywhere under
## it), no light in the play layer, never black. Indifferent: it migrates slowly along its front and
## does not react to the player. It flees the entity: presence_flee() turns it and sends it away,
## accelerating and dimming over FLEE_S ✱; flee_progress reads 0 (here) … 1 (gone).
## Lantern down (CH-3): set_reveal(1) shows its full lit pattern. Every number here is ✱.

## ✱ quad size in logical px: several times the frame, so it is only ever seen cropped.
const QUAD := Vector2(1700.0, 1000.0)
## ✱ layer position and rotation at rest (the rect turns about HEART): the front runs from the left
## edge (~y 240) up to the top edge (~x 540), well above the lantern; the heart sits just inside the
## frame's top-left, ~130 px deep in the body.
const HOME := Vector2(-524.0, -479.0)
const HOME_ROT := -0.42
## ✱ local y of the front's mean line, and the heart (local px) the heartbeat leaves from.
const FRONT_Y := 640.0
const HEART := Vector2(673.0, 508.0)
## ✱ migration: px/s along its own front, the cycle (it fades out, and back in, at the ends), the
## fade at each end, and the phase at t = 0 (mid-cycle: fully present from the first frame).
const MIGRATE_PX_S := 0.9
const MIGRATE_PERIOD_S := 600.0
const MIGRATE_FADE_S := 45.0
const MIGRATE_PHASE := 0.5
## ✱ flee: seconds to gone, acceleration (px/s²), direction (away from the entity, top right, and
## off the top-left of the frame) and how far it turns.
const FLEE_S := 6.0
const FLEE_ACCEL := 46.0
const FLEE_DIR := Vector2(-0.62, -0.78)
const FLEE_TURN := 0.24
## ✱ heartbeat: seconds per beat (two soft bumps: 0.5 luminance cycles/s, under the 1 Hz brief and
## the WARP-001 §4.5 flicker cap) and the speed the beat travels along the veins.
const BEAT_PERIOD_S := 4.0
const WAVE_PX_S := 150.0

## 0 = here … 1 = gone. Rises only after presence_flee() (or a look's presence_fled).
var flee_progress: float = 0.0
var fleeing: bool = false
## 0 = lantern up (vague mass) … 1 = lantern down (full lit pattern).
var reveal: float = 0.0
var _flee_s := 0.0


func _ready() -> void:
	super._ready()
	size = QUAD
	pivot_offset = HEART
	set_param(&"quad_size", QUAD)
	set_param(&"front_y", FRONT_Y)
	set_param(&"heart", HEART)
	set_param(&"beat_period", BEAT_PERIOD_S)
	set_param(&"wave_speed", WAVE_PX_S)
	place(0.0, 0.0, false)


func configure(look: AetherLook) -> void:
	set_param(&"body_col", look.far_silhouette)
	set_param(&"pearl_col", look.presence_pearl)
	set_param(&"frost_col", look.presence_frost)
	set_param(&"light_col", look.presence_light)
	set_param(&"floor_col", Pal.VOID_0)
	set_flee_progress(look.presence_fled)


## It turns and leaves: accelerating away and dimming over FLEE_S. Calling it again changes nothing.
func presence_flee() -> void:
	fleeing = true


## Hold the flee at `p` (0 here … 1 gone), e.g. a ladder look's damage state. Held: it does not
## move on until presence_flee() is called.
func set_flee_progress(p: float) -> void:
	flee_progress = clampf(p, 0.0, 1.0)
	_flee_s = flee_progress * FLEE_S
	fleeing = false


func is_gone() -> bool:
	return flee_progress >= 1.0


## Advance the flee by `delta` seconds of real time (runs under reduced motion too: it dims in place).
func step(delta: float) -> void:
	if not fleeing or is_gone():
		return
	_flee_s = minf(_flee_s + maxf(delta, 0.0), FLEE_S)
	flee_progress = _flee_s / FLEE_S


func set_reveal(r: float) -> void:
	reveal = clampf(r, 0.0, 1.0)
	set_param(&"reveal", reveal)


## Pulse held steady (reduced motion or photosensitivity): the light stays, only its beat stops.
func set_steady(on: bool) -> void:
	set_param(&"steady", 1.0 if on else 0.0)


## Place it for world time `t` (s) and drain; `still` (reduced motion) freezes migration and the
## flee's travel, so it only dims.
func place(t: float, drain: float, still: bool) -> void:
	var cyc := fposmod(t / MIGRATE_PERIOD_S + MIGRATE_PHASE, 1.0)
	var along := Vector2(cos(HOME_ROT), sin(HOME_ROT))
	var mig := 0.0 if still else (cyc - MIGRATE_PHASE) * MIGRATE_PERIOD_S * MIGRATE_PX_S
	var edge := MIGRATE_FADE_S / MIGRATE_PERIOD_S
	var fade := smoothstep(0.0, edge, cyc) * (1.0 - smoothstep(1.0 - edge, 1.0, cyc))
	var off := Vector2.ZERO if still else FLEE_DIR * 0.5 * FLEE_ACCEL * _flee_s * _flee_s
	position = HOME - along * mig + off
	rotation = HOME_ROT + FLEE_TURN * smoothstep(0.0, 0.6, flee_progress)
	var p := fade * (1.0 - smoothstep(0.1, 1.0, flee_progress)) * (1.0 - 0.6 * drain)
	set_param(&"presence", p)
	set_param(&"drain", drain)


## Current presence 0..1 (0 when gone).
func presence() -> float:
	var v: Variant = get_param(&"presence")
	return float(v) if v != null else 0.0
