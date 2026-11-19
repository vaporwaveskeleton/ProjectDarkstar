class_name LedgerCompassStatic
extends Control
## The Ledger Compass's static layer (TECH-001 §5.4): brass bezel, VOID-1 face, chalk tick marks
## (ART-001 §12.5), the sector cell with its grid, the one-cell sector list stub and the empty entity
## marker frame. Draws only when its owner calls `queue_redraw()`; between those calls the canvas
## keeps the recorded commands (the cache), so this costs nothing per frame. Pal colours only.

## Set by the owning LedgerCompass before each redraw.
var layout: LedgerCompassLayout
## Grid lines across the map, in world px per cell (one per `grid_world_px`).
var world_rect: Rect2 = Rect2(0, 0, 640, 360)
var grid_world_px: Vector2 = Vector2(640, 360)
var sector_list_cells: int = 1
## Number of `_draw` passes so far (tests and the bench read it).
var draw_count: int = 0
## Duration of the last `_draw` pass in microseconds (the compass bench reads it).
var last_draw_usec: int = 0


func _ready() -> void:
	mouse_filter = Control.MOUSE_FILTER_IGNORE


func _draw() -> void:
	var t0 := Time.get_ticks_usec()
	draw_count += 1
	if layout == null:
		return
	_draw_layer()
	last_draw_usec = Time.get_ticks_usec() - t0


func _draw_layer() -> void:
	var full := Rect2(Vector2.ZERO, layout.size)
	# Brass bezel (GAS ramp), then the VOID-1 face.
	draw_rect(full, Pal.GAS_2, true)
	draw_rect(full.grow(-0.5), Pal.GAS_1, false, 1.0)
	draw_rect(layout.face, Pal.VOID_1, true)
	draw_rect(layout.face.grow(0.5), Pal.GAS_1, false, 1.0)
	_draw_ticks(full)
	# The sector cell: the whole wrapping map, with a grid of one cell per `grid_world_px`.
	var m := layout.map
	draw_rect(m, Pal.VOID_0, true)
	for x in LedgerCompassLayout.grid_lines(world_rect.size.x, grid_world_px.x):
		var gx := m.position.x + x * m.size.x
		draw_line(Vector2(gx, m.position.y), Vector2(gx, m.end.y), Pal.VOID_3, 1.0)
	for y in LedgerCompassLayout.grid_lines(world_rect.size.y, grid_world_px.y):
		var gy := m.position.y + y * m.size.y
		draw_line(Vector2(m.position.x, gy), Vector2(m.end.x, gy), Pal.VOID_3, 1.0)
	draw_rect(m.grow(0.5), Pal.BONE_2, false, 1.0)
	# Sector list: one-cell STUB (no doc specifies its fields). The current sector, phosphor = truth.
	for i in sector_list_cells:
		var c := layout.list_cell(i)
		draw_rect(c, Pal.PHOS_1, true)
		draw_rect(c.grow(0.5), Pal.BONE_3, false, 1.0)
	# Entity marker frame: drawn, chalk, EMPTY (no entity in M1; WARP-001 §4.7, §3.2 H16).
	draw_rect(layout.entity_frame.grow(0.5), Pal.BONE_5, false, 1.0)


## Chalk ticks on the bezel at the quarter points of each side; the midpoints are longer.
func _draw_ticks(full: Rect2) -> void:
	var b := layout.face.position.x
	for f: float in [0.25, 0.5, 0.75]:
		var tick_len := b if is_equal_approx(f, 0.5) else b * 0.5
		var x := roundf(full.size.x * f) - 0.5
		var y := roundf(full.size.y * f) - 0.5
		draw_line(Vector2(x, 0), Vector2(x, tick_len), Pal.BONE_5, 1.0)
		draw_line(Vector2(x, full.size.y), Vector2(x, full.size.y - tick_len), Pal.BONE_5, 1.0)
		draw_line(Vector2(0, y), Vector2(tick_len, y), Pal.BONE_5, 1.0)
		draw_line(Vector2(full.size.x, y), Vector2(full.size.x - tick_len, y), Pal.BONE_5, 1.0)
