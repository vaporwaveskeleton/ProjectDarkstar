class_name ScreenRig
extends Control
## The cabinet's rig: a reference-unit space (640×360 at 1×; the bezel is drawn in it) that sits so the
## arcade screen's hole lands exactly on the integer-scaled screen (ScreenFit, TECH-001 §1.3). Re-fits
## whenever the window changes size. The rig is the only node that knows the window; the sim never does.
## The bezel fills the WHOLE window at any aspect (no bars): `bezel_rect()` is the window in rig units,
## the hole centred in it. Lay the bezel out against that rect.

signal refitted(area: Rect2)

@export var spec: CabinetScreenSpec

var _area := Rect2(Vector2.ZERO, Vector2(ScreenFit.REF))


func _ready() -> void:
	pivot_offset = Vector2.ZERO
	get_window().size_changed.connect(refit)
	refit()


func refit() -> void:
	var win := get_window().size
	if win.x < 1 or win.y < 1 or spec == null:
		return
	var t := ScreenFit.rig_transform(win, spec.grid)
	position = t.origin
	scale = Vector2(t.x.x, t.y.y)
	_area = ScreenFit.bezel_rect(win, spec.grid)
	refitted.emit(_area)


## The whole window in rig units.
func bezel_rect() -> Rect2:
	return _area
