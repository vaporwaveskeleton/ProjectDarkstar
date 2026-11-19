extends RefCounted
## Flash-rule watch over captured frames (dev/QA automation only; TECH-001 §9.1).
## The rule: WARP-001 §5 L-11 "no flash, flicker above 3 cycles/s ✱" and the full-field luminance
## step ban (WARP-001 §1.4), ART-001 §7 "no UI element may flash more than 3 times in any one second".
## Method (engineering ✱, WCAG 2.x general-flash style): each frame is averaged down to a GRID of
## cells; a cell "transitions" when its relative luminance moves FLASH_DELTA or more from the last
## extreme and the darker side is below DARK_MAX; two opposite transitions are one flash cycle. A cell
## with more than MAX_CYCLES_PER_S cycles inside any WINDOW_FRAMES window is flagged, as is any frame
## whose whole-field mean moves FULL_STEP or more from the previous frame. Pixels, not the timeline:
## this closes the gap Q-T64/Q-T155 leave (those checks are analytic).
## No class_name: release builds exclude core/automation.

const GRID := Vector2i(8, 6)          ## ✱ cells across and down
const CELL_PX := Vector2i(8, 6)       ## ✱ downsample pixels per cell (image is GRID * CELL_PX)
const FLASH_DELTA := 0.10             ## ✱ relative-luminance swing that counts as a transition (WCAG 2.x)
const DARK_MAX := 0.80                ## ✱ the darker side must be below this (WCAG 2.x)
const MAX_CYCLES_PER_S := 3           ## WARP-001 L-11 / ART-001 §7 (✱ in WARP-001)
const WINDOW_FRAMES := 60             ## one second at the scenario's fixed 60 fps
const FULL_STEP := 0.10               ## ✱ whole-field mean change in one frame that counts as a step
const SOFT_STEP := 0.02               ## ✱ ART-001 §16 per-frame light bound under photosensitivity (reported, not flagged)
const MAX_VIOLATIONS := 50            ## ✱ violation records kept (the count is always exact)

var frames := 0
var max_full_step := 0.0
var max_full_step_frame := -1
var soft_steps := 0
var violation_count := 0
var violations: Array = []
var max_cycles_per_s := 0.0

var _prev_full := -1.0
var _ref := PackedFloat64Array()      ## per cell: luminance at the last extreme
var _dir := PackedInt32Array()        ## per cell: -1, 0, +1 direction of the last transition
var _times: Array = []                ## per cell: frames of recent transitions
var _flagged := PackedInt32Array()    ## per cell: last frame a flicker violation was recorded


## Feeds one captured frame. `img` is any size; it is reduced to GRID * CELL_PX first.
func add_image(frame: int, img: Image) -> void:
	var small := img.duplicate() as Image
	if small.is_compressed():
		small.decompress()
	small.convert(Image.FORMAT_RGB8)
	small.resize(GRID.x * CELL_PX.x, GRID.y * CELL_PX.y, Image.INTERPOLATE_TRILINEAR)
	var cells := PackedFloat64Array()
	cells.resize(GRID.x * GRID.y)
	var total := 0.0
	for cy in GRID.y:
		for cx in GRID.x:
			var acc := 0.0
			for py in CELL_PX.y:
				for px in CELL_PX.x:
					acc += relative_luminance(small.get_pixel(cx * CELL_PX.x + px, cy * CELL_PX.y + py))
			var mean := acc / float(CELL_PX.x * CELL_PX.y)
			cells[cy * GRID.x + cx] = mean
			total += mean
	add_cells(frame, cells, total / float(cells.size()))


## Feeds per-cell luminances (0..1) and the whole-field mean. Separate from add_image for tests.
func add_cells(frame: int, cells: PackedFloat64Array, full: float) -> void:
	if _ref.is_empty():
		_ref = cells.duplicate()
		_dir.resize(cells.size())
		_flagged.resize(cells.size())
		_flagged.fill(-WINDOW_FRAMES)
		for _i in cells.size():
			_times.append([])
	frames += 1
	if _prev_full >= 0.0:
		var step := absf(full - _prev_full)
		if step > max_full_step:
			max_full_step = step
			max_full_step_frame = frame
		if step >= SOFT_STEP:
			soft_steps += 1
		if step >= FULL_STEP:
			_violate({"frame": frame, "kind": "full_field_step", "value": snappedf(step, 0.001)})
	_prev_full = full
	for i in cells.size():
		_cell(i, frame, cells[i])


func _cell(i: int, frame: int, l: float) -> void:
	var ref := _ref[i]
	var d := _dir[i]
	if (d == 1 and l > ref) or (d == -1 and l < ref):
		_ref[i] = l   # still moving the same way: extend the extreme
		return
	var swing := l - ref
	if absf(swing) < FLASH_DELTA or minf(l, ref) >= DARK_MAX:
		return
	var new_dir := 1 if swing > 0.0 else -1
	_ref[i] = l
	if new_dir == d:
		return
	_dir[i] = new_dir
	if d == 0:
		return   # the first swing from rest is a change, not half a flash
	var times: Array = _times[i]
	times.append(frame)
	while not times.is_empty() and int(times[0]) <= frame - WINDOW_FRAMES:
		times.pop_front()
	var cycles := times.size() / 2.0
	max_cycles_per_s = maxf(max_cycles_per_s, cycles)
	if cycles > MAX_CYCLES_PER_S and frame - _flagged[i] >= WINDOW_FRAMES:
		_flagged[i] = frame
		_violate({"frame": frame, "kind": "flicker", "cell": i, "value": cycles})


func _violate(v: Dictionary) -> void:
	violation_count += 1
	if violations.size() < MAX_VIOLATIONS:
		violations.append(v)


func report() -> Dictionary:
	return {
		"frames": frames,
		"ok": violation_count == 0,
		"violation_count": violation_count,
		"violations": violations,
		"max_full_step": snappedf(max_full_step, 0.0001),
		"max_full_step_frame": max_full_step_frame,
		"soft_steps": soft_steps,
		"max_cycles_per_s": max_cycles_per_s,
	}


## sRGB colour -> relative luminance (Rec. 709 weights on linear values).
static func relative_luminance(c: Color) -> float:
	var lin := c.srgb_to_linear()
	return 0.2126 * lin.r + 0.7152 * lin.g + 0.0722 * lin.b
