class_name RaceFramer
extends Node
## Race framing (Reviewer rank 6; TECH-001 §2.5 camera row, Q-T25 stays Z1). The M1 exit test is "a
## tester describes the race unprompted", so the Charge, the Grub and the Sepulchre must share the
## screen at the key moments. Zoom is fixed, so the camera LEANS instead: each physics tick it takes
## the race points near the Vigil (from `points`), aims the lean at half their mean offset (the
## midpoint between the Vigil and the race), clamps it per axis to `race_lean_max_frac` of the half
## view so the Vigil never leaves the screen, smooths it with a critically damped spring and hands it
## to `SectorCamera.frame_offset`. Numbers: SectorCameraStats (`ds_camera.race_*`, SYS-001 §9).

@export var camera: SectorCamera
## The Vigil (the lean is measured from it).
var anchor: Node2D
## Returns the race points in world px (any image; the torus picks the nearest). Injected by the host.
var points: Callable = func() -> PackedVector2Array: return PackedVector2Array()

## The current lean (world px) and its spring velocity.
var lean := Vector2.ZERO
var lean_velocity := Vector2.ZERO
## The lean the spring is heading for this tick (tests and the probe read it).
var goal := Vector2.ZERO


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
