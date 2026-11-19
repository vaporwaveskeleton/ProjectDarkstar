class_name TapeStrip
extends ColorRect
## One drawn length of the coin door's hazard tape (pass 2c): shaders/cabinet/hazard_tape.gdshader draws printed vinyl
## with a sheen, a misregistered black plate, lifting edges with a shadow, dirt on the adhesive edge and a crease, or (the
## peeled flap) the adhesive side. CoinSlot owns the tape's behaviour (peel, drag, hold, fall) and only says where this
## length lies each frame: `place(a, b, ...)` takes plate-local end points, exactly as the old vector strip did.

const SHADER := preload("res://shaders/cabinet/hazard_tape.gdshader")
const MARGIN := 9.0                    ## room round the tape for its shadow

@export var surface: CabinetSurface

var _mat: ShaderMaterial
var _seed := 0.0


func _init() -> void:
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	color = Color.WHITE
	visible = false


func _ready() -> void:
	if surface == null:
		surface = CabinetSurface.default() as CabinetSurface
	_mat = ShaderMaterial.new()
	_mat.shader = SHADER
	material = _mat
	CabinetLighting.apply(_mat, surface)
	_mat.set_shader_parameter(&"yellow", surface.tape_yellow)
	_mat.set_shader_parameter(&"black", surface.tape_black)
	_mat.set_shader_parameter(&"sheen", surface.tape_sheen)
	_mat.set_shader_parameter(&"misreg", surface.tape_misregister)
	_mat.set_shader_parameter(&"edge_lift", surface.tape_lift)
	_mat.set_shader_parameter(&"dirt", surface.tape_dirt)
	_mat.set_shader_parameter(&"crease_amt", surface.tape_crease)
	_mat.set_shader_parameter(&"seed", _seed)


## Which strip this is (its own wrinkles and dirt).
func set_seed(v: float) -> void:
	_seed = v
	if _mat != null:
		_mat.set_shader_parameter(&"seed", v)


## Lay this length from `a` to `b` (parent-local). `face` shows the printed side, else the adhesive; `lift` 0 stuck .. 1 in the air;
## `crease` is a parent-local point to put the bend at (or null for none).
func place(a: Vector2, b: Vector2, half_width: float, face: bool, lift: float, crease: Variant = null) -> void:
	var lo := Vector2(minf(a.x, b.x), minf(a.y, b.y)) - Vector2(MARGIN + half_width, MARGIN + half_width)
	var hi := Vector2(maxf(a.x, b.x), maxf(a.y, b.y)) + Vector2(MARGIN + half_width, MARGIN + half_width)
	position = lo
	size = hi - lo
	visible = true
	if _mat == null:
		return
	var parent := get_parent() as Control
	_mat.set_shader_parameter(&"rect_size", size)
	_mat.set_shader_parameter(&"rig_origin", position + (parent.position if parent != null else Vector2.ZERO))
	_mat.set_shader_parameter(&"seg_a", a - lo)
	_mat.set_shader_parameter(&"seg_b", b - lo)
	_mat.set_shader_parameter(&"half_w", half_width)
	_mat.set_shader_parameter(&"face_up", 1.0 if face else 0.0)
	_mat.set_shader_parameter(&"lift_k", lift)
	_mat.set_shader_parameter(&"crease_on", 1.0 if crease != null else 0.0)
	if crease != null:
		_mat.set_shader_parameter(&"crease_c", (crease as Vector2) - lo)
