class_name HoleFit
extends Control
## Confines a root-level screen (the attract scene, until its menu moves onto the bezel) to the arcade
## screen's footprint: in the default mode it takes the hole's rect in rig units (ScreenFit.hole_rect of
## the spec's grid); in `play_view` mode it takes the play view (the grid below the HUD strip) in its
## parent hole's local coordinates. It clips its children, so nothing a screen draws can leave the tube.

@export var spec: CabinetScreenSpec
@export var play_view := false


func _enter_tree() -> void:
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	clip_contents = true
	set_anchors_preset(Control.PRESET_TOP_LEFT)
	var r := fit_rect()
	position = r.position
	size = r.size


## The rect this node takes, in its parent's coordinates.
func fit_rect() -> Rect2:
	var s := spec if spec != null else (load("res://data/cabinet/cabinet_screen.tres") as CabinetScreenSpec)
	return s.play_rect() if play_view else ScreenFit.hole_rect(s.grid)
