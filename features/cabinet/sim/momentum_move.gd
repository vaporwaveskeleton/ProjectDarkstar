class_name MomentumMove
extends RefCounted
## Act 0 "momentum" ship handling (owner F-9, Q-T445), after the arcade original's player ship
## (research/sinistar_player_movement.md): a one-stick tank. The stick sets a wanted heading; the
## hull turns toward it; thrust acts only while the stick is within the thrust arc of the hull's
## heading, and always along that heading; velocity eases toward heading * max speed at a rate
## scaled by deflection; no drag, no brake, so the ship coasts. Aim and fire stay twin-stick (GDD §4.1).
## Pure statics (frame-rate independent: exact exponentials) so tests can drive them directly.

## Hull heading after one tick: eases toward the stick direction, faster with more deflection.
static func step_heading(heading: float, stick: Vector2, dt: float, t: CabinetTuning) -> float:
	if stick == Vector2.ZERO:
		return heading
	var defl := minf(stick.length(), 1.0)
	var f := 1.0 - exp(-t.momentum_turn_rate * defl * dt)
	return heading + wrapf(stick.angle() - heading, -PI, PI) * f


## True when the stick is within the thrust arc of the heading (thrust only then).
static func thrusts(heading: float, stick: Vector2, t: CabinetTuning) -> bool:
	if stick == Vector2.ZERO:
		return false
	return absf(wrapf(stick.angle() - heading, -PI, PI)) <= deg_to_rad(t.momentum_thrust_arc_deg)


## Velocity after one tick, `heading` being this tick's (already stepped) hull heading.
static func step_velocity(v: Vector2, heading: float, stick: Vector2, dt: float, t: CabinetTuning) -> Vector2:
	if thrusts(heading, stick, t):
		var f := 1.0 - exp(-t.momentum_ease_rate * minf(stick.length(), 1.0) * dt)
		return v + (Vector2.from_angle(heading) * t.momentum_max_speed - v) * f
	var spd := v.length()
	if spd > t.momentum_max_speed:
		# only a Surgelight burst takes the ship over the cap: the excess eases away (no new number)
		var f2 := 1.0 - exp(-t.momentum_ease_rate * dt)
		return v.normalized() * lerpf(spd, t.momentum_max_speed, f2)
	return v        # no drag, no brake: the ship coasts
