class_name SectorFloor
extends Node2D
## The sandbox floor (Q-T58): a repeating runtime-vector grid in Pal colours drawn over whatever the
## camera sees, so no clear colour ever shows. The grid is anchored to world (0, 0) and its period
## divides the torus size, so it looks the same on both sides of the seam and through a camera rebase.

@export var style: SectorFloorStyle
## Fill the cells with `style.base_colour`. Off when the Aether far layer shows behind the play layer
## (golden path, TECH-001 §2.9): only the grid lines are drawn, so the Aether is never covered.
@export var draw_base := true


func _ready() -> void:
	z_index = -100


func _process(_delta: float) -> void:
	queue_redraw()


## The world rect the active camera shows (viewport rect through the inverse canvas transform).
func visible_world_rect() -> Rect2:
	var vp := get_viewport()
	if vp == null:
		return Rect2()
	return vp.get_canvas_transform().affine_inverse() * vp.get_visible_rect()


## `visible` grown out to whole cells plus one cell of margin (covers shake and sub-pixel motion).
static func covered_rect(visible: Rect2, cell: float) -> Rect2:
	if cell <= 0.0:
		return visible
	var x0 := (floorf(visible.position.x / cell) - 1.0) * cell
	var y0 := (floorf(visible.position.y / cell) - 1.0) * cell
	var x1 := (ceilf(visible.end.x / cell) + 1.0) * cell
	var y1 := (ceilf(visible.end.y / cell) + 1.0) * cell
	return Rect2(x0, y0, x1 - x0, y1 - y0)


func _draw() -> void:
	if style == null or style.cell_px <= 0.0:
		return
	var cell := style.cell_px
	var r := covered_rect(visible_world_rect(), cell)
	# The node may be moved; draw in its local space.
	r = Rect2(r.position - global_position, r.size)
	if draw_base:
		draw_rect(r, style.base_colour, true)
	var major := maxi(1, style.major_every)
	var i0 := roundi((r.position.x + global_position.x) / cell)
	var n := roundi(r.size.x / cell)
	for k in n + 1:
		var x := r.position.x + k * cell
		var c := style.major_colour if posmod(i0 + k, major) == 0 else style.minor_colour
		draw_line(Vector2(x, r.position.y), Vector2(x, r.end.y), c, style.line_px)
	var j0 := roundi((r.position.y + global_position.y) / cell)
	var m := roundi(r.size.y / cell)
	for k in m + 1:
		var y := r.position.y + k * cell
		var c := style.major_colour if posmod(j0 + k, major) == 0 else style.minor_colour
		draw_line(Vector2(r.position.x, y), Vector2(r.end.x, y), c, style.line_px)
