class_name RaceFramer
extends Node
## Race framing (Reviewer rank 6; TECH-001 §2.5 camera row, Q-T25 stays Z1). The M1 exit test is "a
## tester describes the race unprompted", so the Charge, the Grub and the Sepulchre must share the
## screen at the key moments, or be signposted at its edge (RaceEdgeMarkers, features/hud).
##
## Lean (Q-T354, replaces #79's half-mean): each physics tick it takes the race points near the Vigil
## (from `points`) and aims the lean at the CENTRE OF THE BOX holding the Vigil and every race point
## in reach, so both ends of the race (the Charge and the Sepulchre, the Grub and the Sepulchre) are
## framed, not their average. The lean is clamped per axis to `race_lean_max_frac` of the half view so
## the Vigil never leaves the screen, smoothed with a critically damped spring and handed to
## `SectorCamera.frame_offset`. Numbers: SectorCameraStats (`ds_camera.race_*`, SYS-001 §9).
##
## Pull-out (Q-T211, refined by Q-T355): when the race points in reach still do not fit the zoom-1
## frame after the lean, the camera eases zoom to the FITTED zoom (the largest that holds them with
## `race_fit_margin_px` to spare), never below `race_pull_zoom`. While a Charge is in flight the pull
## lasts the Charge's whole flight (the Charge's own life, SYS-001 §1.4, bounds it) and each new Charge
## re-arms it. A race with no Charge (a Grub theft) pulls for at most `race_pull_max_s`, then holds
## zoom 1 until the race ends (re-arms). Z1 stays the rule elsewhere; telegraphs stay inside 640×360.
##
## Reduced motion (Q-T356): with Settings `reduced_motion` on, the zoom never moves (no pull pulses);
## the lean still pans, and the edge markers carry whatever does not fit.

@export var camera: SectorCamera
## The Vigil (the lean is measured from it).
var anchor: Node2D
## Returns the race points in world px (any image; the torus picks the nearest). Injected by the host.
var points: Callable = func() -> PackedVector2Array: return PackedVector2Array()
## Returns true while at least one Charge is in flight. Injected by the host.
var charge_flying: Callable = func() -> bool: return false

## The current lean (world px) and its spring velocity.
var lean := Vector2.ZERO
var lean_velocity := Vector2.ZERO
## The lean the spring is heading for this tick (tests and the probe read it).
var goal := Vector2.ZERO
## The zoom that fits the race this tick (stats.zoom when it already fits or there is no race).
var fit := 1.0
## Current zoom (scalar), its spring velocity, and the pull-out state.
var zoom_now := 1.0
var zoom_velocity := 0.0
var pulling := false
var pull_s := 0.0
var _pull_spent := false
var _was_charge := false


func _ready() -> void:
	process_physics_priority = -1   # before the camera's own tick


func _physics_process(delta: float) -> void:
	step(delta)


func step(delta: float) -> void:
	if camera == null or camera.stats == null or not is_instance_valid(anchor):
		return
	var s := camera.stats
	var pts: PackedVector2Array = points.call()
	var offsets := PackedVector2Array()
	for p in pts:
		var d := camera.torus.delta(anchor.global_position, p) if camera.torus else p - anchor.global_position
		if d.length() <= s.race_reach_px:
			offsets.append(d)
	var half_z1 := camera.get_viewport_rect().size * 0.5 / maxf(0.001, s.zoom)
	goal = lean_goal(offsets, s.race_reach_px, half_z1 * s.race_lean_max_frac)
	var r := SectorCamera.spring_step(lean, lean_velocity, goal, SectorCamera.omega_for(s.race_lean_time_s), delta)
	lean = r[0]
	lean_velocity = r[1]
	camera.frame_offset = lean
	fit = fit_zoom(offsets, goal, half_z1 * s.zoom, s.race_fit_margin_px, s.race_pull_zoom, s.zoom)
	_step_pull(delta, s, offsets.is_empty())


## True when Settings `reduced_motion` holds the zoom still (data flag, like the shake's D-3 flag).
func pull_suppressed() -> bool:
	var s := camera.stats if camera else null
	return s != null and s.race_pull_off_under_reduced_motion \
		and bool(SettingsService.get_value(&"reduced_motion"))


func _step_pull(delta: float, s: SectorCameraStats, no_race: bool) -> void:
	var charge: bool = bool(charge_flying.call())
	if no_race or (charge and not _was_charge):
		_pull_spent = false   # the race ended, or a new Charge left the rail: re-arm
		pull_s = 0.0
	_was_charge = charge
	var want := false
	if not no_race and not _pull_spent and s.race_pull_zoom > 0.0 and not pull_suppressed():
		want = fit < s.zoom - 0.001
		if want and not charge:
			pull_s += delta
			if pull_s >= s.race_pull_max_s:
				_pull_spent = true
				want = false
	pulling = want
	if pull_suppressed():
		zoom_now = s.zoom
		zoom_velocity = 0.0
	else:
		var z_goal := fit if want else s.zoom
		var r := SectorCamera.spring_step(Vector2(zoom_now, 0.0), Vector2(zoom_velocity, 0.0), Vector2(z_goal, 0.0),
			SectorCamera.omega_for(s.race_lean_time_s), delta)
		zoom_now = r[0].x
		zoom_velocity = r[1].x
	camera.zoom = Vector2.ONE * zoom_now


# --- pure helpers --------------------------------------------------------------------------------

## The lean for race `offsets` (from the Vigil): the centre of the box holding the Vigil (the origin)
## and every offset within `reach`, clamped per axis to `max_lean`. No points in reach = no lean.
## One point gives its midpoint, as #79's lean did.
static func lean_goal(offsets: PackedVector2Array, reach: float, max_lean: Vector2) -> Vector2:
	var lo := Vector2.ZERO
	var hi := Vector2.ZERO
	var n := 0
	for d in offsets:
		if d.length() <= reach:
			lo = lo.min(d)
			hi = hi.max(d)
			n += 1
	if n == 0:
		return Vector2.ZERO
	var g := (lo + hi) * 0.5
	return Vector2(clampf(g.x, -max_lean.x, max_lean.x), clampf(g.y, -max_lean.y, max_lean.y))


## The zoom at which the Vigil (origin) and every offset sit inside the frame centred on `centre`,
## `margin` px (screen) from its edge. `half_screen` is the half viewport in screen px. Clamped to
## [`z_min`, `z_max`]; `z_max` when there is nothing to fit.
static func fit_zoom(offsets: PackedVector2Array, centre: Vector2, half_screen: Vector2, margin: float,
		z_min: float, z_max: float) -> float:
	var z := z_max
	var room := (half_screen - Vector2.ONE * margin).max(Vector2.ONE)
	var all := PackedVector2Array(offsets)
	if all.is_empty():
		return z_max
	all.append(Vector2.ZERO)
	for d in all:
		var e := (d - centre).abs()
		if e.x > 0.0:
			z = minf(z, room.x / e.x)
		if e.y > 0.0:
			z = minf(z, room.y / e.y)
	return clampf(z, minf(z_min, z_max), z_max)


## True when `d` (from the frame centre) lies outside a frame of half size `half` on either axis.
static func offscreen(d: Vector2, half: Vector2) -> bool:
	return absf(d.x) > half.x or absf(d.y) > half.y
