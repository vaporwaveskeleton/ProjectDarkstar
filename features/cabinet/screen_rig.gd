class_name ScreenRig
extends Control
## The cabinet's rig: a 640×360 reference-unit space (the bezel is drawn in it) that sits so the
## arcade screen's hole lands exactly on the integer-scaled screen (ScreenFit, TECH-001 §1.3). Re-fits
## whenever the window changes size. The rig is the only node that knows the window; the sim never does.

@export var spec: CabinetScreenSpec


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
