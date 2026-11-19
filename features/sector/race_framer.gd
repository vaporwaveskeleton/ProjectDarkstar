class_name RaceFramer
extends Node
## Race framing (Reviewer rank 6; TECH-001 §2.5 camera row, Q-T25 stays Z1). The M1 exit test is "a
## tester describes the race unprompted", so the Charge, the Grub and the Sepulchre must share the
## screen at the key moments. Zoom is fixed, so the camera LEANS instead: each physics tick it takes
## the race points near the Vigil (from `points`), aims the lean at half their mean offset (the
## midpoint between the Vigil and the race), clamps it per axis to `race_lean_max_frac` of the half
## view so the Vigil never leaves the screen, smooths it with a critically damped spring and hands it
## to `SectorCamera.frame_offset`. Numbers: SectorCameraStats (`ds_camera.race_*`, SYS-001 §9).
## Q-T211 (PM under owner autonomy grant, 2026-11-19): when the Sepulchre is a race target and still
## off the zoom-1 frame after the lean, the camera briefly pulls out to `race_pull_zoom` (Z2 for that
## moment only; Z1 stays the rule), for at most `race_pull_max_s`, then holds zoom 1 until the
## Sepulchre is no longer a race target (re-arms). Telegraphs stay inside the 640×360 frame either way.

@export var camera: SectorCamera
## The Vigil (the lean is measured from it).
var anchor: Node2D
## Returns the race points in world px (any image; the torus picks the nearest). Injected by the host.
var points: Callable = func() -> PackedVector2Array: return PackedVector2Array()
## Returns the Sepulchre (0 or 1 point) while it is a race target. Injected by the host.
var pull_target: Callable = func() -> PackedVector2Array: return PackedVector2Array()

## The current lean (world px) and its spring velocity.
var lean := Vector2.ZERO
var lean_velocity := Vector2.ZERO
## The lean the spring is heading for this tick (tests and the probe read it).
var goal := Vector2.ZERO
## Current zoom (scalar), its spring velocity, and the pull-out state (Q-T211).
var zoom_now := 1.0
var zoom_velocity := 0.0
var pulling := false
var pull_s := 0.0
var _pull_spent := false


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
		offsets.append(d)
	goal = lean_goal(offsets, s.race_reach_px, camera.visible_size() * 0.5 * s.race_lean_max_frac)
	var r := SectorCamera.spring_step(lean, lean_velocity, goal, SectorCamera.omega_for(s.race_lean_time_s), delta)
	lean = r[0]
	lean_velocity = r[1]
	camera.frame_offset = lean
	_step_pull(delta, s)


## Q-T211: pull out while the Sepulchre is a race target off the zoom-1 frame, at most race_pull_max_s.
func _step_pull(delta: float, s: SectorCameraStats) -> void:
	var tgt: PackedVector2Array = pull_target.call()
	var want := false
	if tgt.is_empty():
		_pull_spent = false
		pull_s = 0.0
	elif not _pull_spent and s.race_pull_zoom > 0.0:
		var d := camera.torus.delta(anchor.global_position, tgt[0]) if camera.torus else tgt[0] - anchor.global_position
		var half := camera.get_viewport_rect().size * 0.5 / maxf(0.001, s.zoom)
		want = offscreen(d - goal, half)
		if want:
			pull_s += delta
			if pull_s >= s.race_pull_max_s:
				_pull_spent = true
				want = false
	pulling = want
	var z_goal := s.race_pull_zoom if want else s.zoom
	var r := SectorCamera.spring_step(Vector2(zoom_now, 0.0), Vector2(zoom_velocity, 0.0), Vector2(z_goal, 0.0),
		SectorCamera.omega_for(s.race_lean_time_s), delta)
	zoom_now = r[0].x
	zoom_velocity = r[1].x
	camera.zoom = Vector2.ONE * zoom_now


# --- pure helpers --------------------------------------------------------------------------------

## The lean for race `offsets` (from the Vigil): half their mean (the midpoint), ignoring any farther
## than `reach`, clamped per axis to `max_lean`. No points in reach = no lean.
static func lean_goal(offsets: PackedVector2Array, reach: float, max_lean: Vector2) -> Vector2:
	var sum := Vector2.ZERO
	var n := 0
	for d in offsets:
		if d.length() <= reach:
			sum += d
			n += 1
	if n == 0:
		return Vector2.ZERO
	var g := sum / float(n) * 0.5
	return Vector2(clampf(g.x, -max_lean.x, max_lean.x), clampf(g.y, -max_lean.y, max_lean.y))


## True when `d` (from the frame centre) lies outside a frame of half size `half` on either axis.
static func offscreen(d: Vector2, half: Vector2) -> bool:
	return absf(d.x) > half.x or absf(d.y) > half.y
