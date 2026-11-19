class_name AetherShaderRect
extends ColorRect
## One full-coverage Aether shader layer. Owns its ShaderMaterial (one per instance, so two
## backdrops never share uniforms) and nothing else. The backdrop feeds it uniforms.

## The layer's shader (a shaders/aether/*.gdshader).
@export var shader: Shader
## True when the layer reads the lantern's PointLight2D (fog bands). Others are unshaded.
@export var lit: bool = false

var mat: ShaderMaterial


func _init() -> void:
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	color = Color(1, 1, 1, 1)


func _ready() -> void:
	ensure_material()
	light_mask = 1 if lit else 0


func ensure_material() -> ShaderMaterial:
	if mat == null:
		mat = ShaderMaterial.new()
		mat.shader = shader
		material = mat
	elif mat.shader == null and shader != null:
		mat.shader = shader
	return mat


func set_param(param: StringName, value: Variant) -> void:
	ensure_material().set_shader_parameter(param, value)


func get_param(param: StringName) -> Variant:
	return ensure_material().get_shader_parameter(param)
