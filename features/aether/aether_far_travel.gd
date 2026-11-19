class_name AetherFarTravel
extends RefCounted
## The far layer's long-flight state (Q-T127 option B). Holds the camera travel since the sector
## origin and, per landmark channel, its leashed parallax displacement. Pure math: no nodes; the
## backdrop applies the results (Parallax2D scroll_offset, band uniforms, life velocity).
## Landmark step, per frame: a critically damped pull toward the authored framing (exact solution,
## stable at any delta), then the parallax slide against the camera, then the state is held within
## saturation × cap; the shown displacement is the soft cap of that state (cap · tanh(|u| / cap)),
## moved toward it by at most max_step_px per frame.

var tuning: AetherFarLeash
## Camera travel since the sector origin (backdrop px). Float32 is sub-pixel up to ~1.3e5.
var travel := Vector2.ZERO
## Travel over the last step (backdrop px).
var step_travel := Vector2.ZERO
var _prev := Vector2.ZERO
var _u: Dictionary = {}
var _v: Dictionary = {}
var _shown: Dictionary = {}


func _init(t: AetherFarLeash = null) -> void:
	tuning = t if t != null else AetherFarLeash.new()


## New sector: travel back to zero and every landmark back on its authored framing (no slide).
func reset() -> void:
	travel = Vector2.ZERO
	_prev = Vector2.ZERO
	step_travel = Vector2.ZERO
	_u.clear()
	_v.clear()
	_shown.clear()


func set_travel(d: Vector2) -> void:
	travel = d


## Advance every landmark channel by `delta` seconds. `factors`: channel → parallax scroll factor.
func step(delta: float, factors: Dictionary) -> void:
	step_travel = travel - _prev
	_prev = travel
	var dt := maxf(delta, 0.0)
	var w := 1.0 / maxf(tuning.time_constant_s, 0.001)
	var e := exp(-w * dt)
	var u_max := tuning.cap_px * tuning.saturation
	for ch: StringName in factors:
		var s := float(factors[ch])
		var u: Vector2 = _u.get(ch, Vector2.ZERO)
		var v: Vector2 = _v.get(ch, Vector2.ZERO)
		var k := (v + u * w) * dt
		u = (u + k) * e
		v = (v - k * w) * e
		u -= step_travel * s
		if u.length() > u_max:
			u = u.limit_length(u_max)
			v = Vector2.ZERO
		_u[ch] = u
		_v[ch] = v
		var shown: Vector2 = _shown.get(ch, Vector2.ZERO)
		_shown[ch] = shown.move_toward(soft_cap(u, tuning.cap_px), tuning.max_step_px)


## The landmark channel's displacement from its authored framing (logical px).
func displacement(ch: StringName) -> Vector2:
	return _shown.get(ch, Vector2.ZERO)


## |u| → cap · tanh(|u| / cap): linear for small flights, never past the cap.
static func soft_cap(u: Vector2, cap: float) -> Vector2:
	var m := u.length()
	if m < 0.0001 or cap <= 0.0:
		return Vector2.ZERO if cap <= 0.0 else u
	return u * (cap * tanh(m / cap) / m)


## A band's parallax offset (travel × factor) wrapped into [-period / 2, period / 2) per axis, phase
## 0 at the sector origin. `phase` shifts the wrap (the crossfade's second sample uses period / 2).
## Computed in float64 from the float32 travel.
static func band_offset(d: Vector2, factor: float, period: float, phase: float = 0.0) -> Vector2:
	return Vector2(_wrap(float(d.x) * factor + phase, period), _wrap(float(d.y) * factor + phase, period))


## 0 away from a wrap … 1 at it (on either axis): how far the band hides its wrap.
static func wrap_mix(offset: Vector2, period: float, window: float) -> float:
	var dist := period * 0.5 - maxf(absf(offset.x), absf(offset.y))
	return 1.0 - smoothstep(0.0, maxf(window, 0.001), dist)


static func _wrap(x: float, period: float) -> float:
	return fposmod(x + period * 0.5, period) - period * 0.5
