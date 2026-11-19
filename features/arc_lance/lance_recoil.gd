class_name LanceRecoil
extends Node
## Visual-only Lance recoil: on each shot, nudges the Vigil's visual node opposite the aim for a
## few drawn frames. Never touches the body's position, velocity or the Facing node, so
## SYS-001 §1.3 "no recoil" holds for gameplay. Off under Reduced Motion (read at fire time).
## Values: ArcLanceFxStats (ds_arc_lance.fx, SYS-001 §9).

@export var emitter: ArcLanceEmitter
@export var stats: ArcLanceFxStats
## The drawn ship (a child of Facing). Only its local position is offset.
@export var visual: Node2D

var frames_left: int = 0
var _dir: Vector2 = Vector2.ZERO
var _rest: Vector2 = Vector2.ZERO


func _ready() -> void:
	if visual:
		_rest = visual.position
	if emitter:
		emitter.lance_fired.connect(kick)


func _process(_delta: float) -> void:
	apply()
	advance_draw_frame()


## Start a recoil along `direction` (world space), unless Reduced Motion is on.
func kick(direction: Vector2) -> void:
	if bool(SettingsService.get_value(&"reduced_motion")):
		return
	frames_left = stats.recoil_frames
	_dir = direction.normalized()


## World-space draw nudge right now: opposite the aim, or zero.
func offset() -> Vector2:
	if frames_left <= 0:
		return Vector2.ZERO
	return -_dir * float(stats.recoil_px)


## Put the visual at rest + the nudge (converted into its parent's local space).
func apply() -> void:
	if visual == null:
		return
	var parent := visual.get_parent() as Node2D
	var local := offset()
	if parent:
		local = parent.global_transform.basis_xform_inv(local)
	visual.position = _rest + local


## One drawn frame has passed (tests call it directly).
func advance_draw_frame() -> void:
	frames_left = maxi(0, frames_left - 1)
