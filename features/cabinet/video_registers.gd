class_name VideoRegisters
extends Node
## The Act 0 screen's 16 colour registers (Williams video limits; ScreenRegisters holds the defaults).
## The CPU may write a register at any time: `write()` snaps to RGB332 and the shader recolours every
## pixel assigned to that register on the next draw, with no redraw of the screen. Colour cycling
## (`cycle()`) steps on video frames (16.64 ms each, counted from accumulated delta), not on physics ticks.
## Child of the node whose material is the CRT shader (ArcadeScreen): `target` defaults to the
## parent. Pushes `registers`, the pixel-match set and `limits` (1 - Look.t, so THE PRETENCE fades the
## limits out) to that material. Only what that material shades is limited; the bezel never is.

const MATCH_MAX := 48   ## size of the shader's match arrays: 32 NEON colours + 16 register defaults

@export var spec: ScreenRegisters
## The CanvasItem whose ShaderMaterial gets the uniforms. Empty = the parent.
@export var target: CanvasItem

var frame: int = 0   ## video frames counted since the node entered the tree
var limits: float = 1.0

var _regs := PackedColorArray()
var _acc: float = 0.0
var _cycles: Dictionary = {}   # reg -> {colors: PackedColorArray, every: int, step: int, since: int}
var _dirty := true
var _last_limits: float = -1.0


func _ready() -> void:
	if spec == null:
		spec = load("res://data/cabinet/screen_registers.tres") as ScreenRegisters
	if target == null:
		target = get_parent() as CanvasItem
	reset()
	_push_match_set()


func _process(delta: float) -> void:
	advance(delta)


## Feed elapsed real time; counts whole video frames and steps any cycles. Public so tests can drive it.
func advance(delta: float) -> void:
	_acc += delta
	var vf := spec.video_frame_s
	while _acc >= vf - 0.000001:
		_acc -= vf
		frame += 1
		_step_cycles()
	limits = 1.0 - clampf(Look.t, 0.0, 1.0)
	if _dirty or not is_equal_approx(limits, _last_limits):
		_push()


## Registers back to power-on values; cycles stop.
func reset() -> void:
	_cycles.clear()
	_regs = PackedColorArray()
	for i in ScreenRegisters.REGISTER_COUNT:
		_regs.append(ScreenRegisters.to_rgb332(spec.defaults[i]))
	_dirty = true
	_push()


func read(i: int) -> Color:
	return _regs[i]


## Write register `i` now; the colour is snapped to RGB332.
func write(i: int, c: Color) -> void:
	if i < 0 or i >= ScreenRegisters.REGISTER_COUNT:
		return
	_regs[i] = ScreenRegisters.to_rgb332(Color(c.r, c.g, c.b, 1.0))
	_dirty = true
	_push()


## Step register `reg` through `colors`, one entry every `frames_per_step` video frames (looping).
## The first colour is written immediately.
func cycle(reg: int, colors: PackedColorArray, frames_per_step: int) -> void:
	if colors.is_empty() or frames_per_step < 1:
		return
	_cycles[reg] = {"colors": colors, "every": frames_per_step, "step": 0, "since": 0}
	write(reg, colors[0])


## Stop cycling `reg` and put its power-on colour back.
func stop_cycle(reg: int) -> void:
	if _cycles.erase(reg):
		write(reg, spec.defaults[reg])


func is_cycling(reg: int) -> bool:
	return _cycles.has(reg)


func _step_cycles() -> void:
	for reg: int in _cycles.keys():
		var c: Dictionary = _cycles[reg]
		var since: int = int(c["since"]) + 1
		if since >= int(c["every"]):
			since = 0
			var colors: PackedColorArray = c["colors"]
			var step: int = (int(c["step"]) + 1) % colors.size()
			c["step"] = step
			_regs[reg] = ScreenRegisters.to_rgb332(Color(colors[step].r, colors[step].g, colors[step].b, 1.0))
			_dirty = true
		c["since"] = since


func _material() -> ShaderMaterial:
	if target == null:
		return null
	return target.material as ShaderMaterial


func _push() -> void:
	_dirty = false
	_last_limits = limits
	var m := _material()
	if m == null:
		return
	var v := PackedVector3Array()
	for c in _regs:
		v.append(Vector3(c.r, c.g, c.b))
	m.set_shader_parameter(&"registers", v)
	m.set_shader_parameter(&"limits", limits)


func _push_match_set() -> void:
	var m := _material()
	if m == null:
		return
	var set := match_set(spec)
	m.set_shader_parameter(&"match_rgb", set["rgb"])
	m.set_shader_parameter(&"match_reg", set["reg"])


## The shader's match set: every Look.NEON colour tagged with its register (from `pal_map`), then the
## 16 register defaults tagged with themselves, padded to MATCH_MAX with the first entry.
## Returns {"rgb": PackedVector3Array, "reg": PackedInt32Array}.
static func match_set(regs: ScreenRegisters) -> Dictionary:
	var rgb := PackedVector3Array()
	var reg := PackedInt32Array()
	for name: String in Look.NEON:
		var c: Color = Look.NEON[name]
		rgb.append(Vector3(c.r, c.g, c.b))
		reg.append(int(regs.pal_map[name]))
	for i in ScreenRegisters.REGISTER_COUNT:
		var d: Color = regs.defaults[i]
		rgb.append(Vector3(d.r, d.g, d.b))
		reg.append(i)
	while rgb.size() < MATCH_MAX:
		rgb.append(rgb[0])
		reg.append(reg[0])
	return {"rgb": rgb, "reg": reg}


## CPU mirror of the shader's register search (shaders/crt_common.gdshaderinc, `crt_quantize`):
## the register of the match-set entry nearest to `c` by squared RGB distance; the first entry wins ties.
static func nearest_register(c: Color, match_rgb: PackedVector3Array, match_reg: PackedInt32Array) -> int:
	var p := Vector3(c.r, c.g, c.b)
	var best := 1.0e20
	var out := 0
	for i in match_rgb.size():
		var d := p.distance_squared_to(match_rgb[i])
		if d < best:
			best = d
			out = match_reg[i]
	return out
