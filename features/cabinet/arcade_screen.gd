class_name ArcadeScreen
extends SubViewportContainer
## The Act 0 tube (TECH-001 §1.3, §2.10): a SubViewport of `spec.grid` texels, nearest filtered with its
## own 2D snapping, drawn by this container at whole-number display px per texel. The CRT costume is
## this node's material and reads the screen's own texture, so it can never touch the bezel.
## A SubViewportContainer (not a TextureRect) because it forwards mouse motion into the viewport through
## its global transform, scale included: `mouse()` is then in grid coordinates with no extra maths.
## No focusable Control may live in the screen's viewport (its focus is separate from the root's).

@export var spec: CabinetScreenSpec

@onready var viewport: SubViewport = %ScreenViewport


func _ready() -> void:
	stretch = false
	texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	viewport.size = spec.grid
	size = Vector2(spec.grid)
	var mat := crt_material()
	if mat != null:
		mat.set_shader_parameter(&"rows", float(spec.grid.y))


func crt_material() -> ShaderMaterial:
	return material as ShaderMaterial


## The mouse in screen-grid coordinates (the viewport's own mouse position).
func mouse() -> Vector2:
	return viewport.get_mouse_position()
