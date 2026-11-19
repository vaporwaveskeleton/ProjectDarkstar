class_name AetherShaderRect
extends ColorRect
## One full-coverage Aether shader layer. Owns its ShaderMaterial (one per instance, so two
## backdrops never share uniforms) and nothing else. The backdrop feeds it uniforms.
## Quality ladder: a layer can render offscreen into its own SubViewport at a fraction of the
## window's pixel size and be shown by a screen-sized TextureRect in the same draw slot (same
## material, same local coordinates, so the picture is identical, only softer).

## The layer's shader (a shaders/aether/*.gdshader).
@export var shader: Shader
## True when the layer reads the lantern's PointLight2D. Aether layers light themselves
## analytically (the same in place and offscreen), so this stays false for them.
@export var lit: bool = false
## True when the layer adds light (blend_add shaders): its offscreen view is added, not mixed.
@export var additive: bool = false

var mat: ShaderMaterial
## Whether the backdrop wants this layer drawn at all (layer switch, look, band count).
var wanted: bool = true
## ✱ offscreen resolution as a fraction of the window's pixel size; 1 = drawn in place.
var offscreen_scale: float = 1.0
var _vp: SubViewport
var _proxy: ColorRect
var _view: TextureRect


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


## Draw this layer or not (independent of where it renders).
func set_drawn(on: bool) -> void:
	wanted = on
	_refresh_draw()


func is_drawn() -> bool:
	return wanted


## Render offscreen at `s` of the window's pixel size (s < 1), or in place (s >= 1).
func set_offscreen_scale(s: float) -> void:
	offscreen_scale = clampf(s, 0.1, 1.0)
	if is_offscreen() and _vp == null and is_inside_tree():
		_build_offscreen()
	_refresh_draw()


func is_offscreen() -> bool:
	return offscreen_scale < 0.999


## The offscreen viewport's RID while it renders (for cost measurement), else an empty RID.
func offscreen_rid() -> RID:
	if _vp != null and wanted and is_offscreen():
		return _vp.get_viewport_rid()
	return RID()


func _build_offscreen() -> void:
	var layer := get_parent()
	_vp = SubViewport.new()
	_vp.name = name + "Offscreen"
	_vp.transparent_bg = true
	_vp.use_hdr_2d = true          # the world viewport is HDR (linear); keep the same space
	_vp.disable_3d = true
	# its own (empty) World3D: otherwise it inherits the world viewport's WorldEnvironment and pays
	# a full glow pass of its own every frame
	_vp.own_world_3d = true
	_vp.handle_input_locally = false
	_vp.gui_disable_input = true
	_vp.size_2d_override_stretch = true
	_vp.canvas_item_default_texture_filter = Viewport.DEFAULT_CANVAS_ITEM_TEXTURE_FILTER_LINEAR
	_proxy = ColorRect.new()
	_proxy.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_proxy.color = Color(1, 1, 1, 1)
	_proxy.material = mat
	_proxy.light_mask = 0
	_vp.add_child(_proxy)
	layer.add_child(_vp)
	RenderingServer.viewport_set_measure_render_time(_vp.get_viewport_rid(), true)
	_view = TextureRect.new()
	_view.name = name + "View"
	_view.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_view.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	_view.stretch_mode = TextureRect.STRETCH_SCALE
	_view.texture_filter = CanvasItem.TEXTURE_FILTER_LINEAR
	_view.light_mask = 0
	_view.texture = _vp.get_texture()
	var cim := CanvasItemMaterial.new()
	cim.blend_mode = CanvasItemMaterial.BLEND_MODE_ADD if additive else CanvasItemMaterial.BLEND_MODE_PREMULT_ALPHA
	_view.material = cim
	layer.add_child(_view)
	layer.move_child(_view, get_index() + 1)


func _refresh_draw() -> void:
	var off := is_offscreen() and _vp != null
	visible = wanted and not off
	if _vp != null:
		_view.visible = wanted and off
		_vp.render_target_update_mode = SubViewport.UPDATE_ALWAYS if (wanted and off) else SubViewport.UPDATE_DISABLED


## Keep the offscreen copy aligned with where this rect would draw. Call once per frame.
## `px_size` = the world viewport's pixel size, `logical` = its logical (2D override) size.
func sync_offscreen(px_size: Vector2i, logical: Vector2) -> void:
	if _vp == null or not _view.visible:
		return
	var want := Vector2i(maxi(int(float(px_size.x) * offscreen_scale), 1), maxi(int(float(px_size.y) * offscreen_scale), 1))
	if _vp.size != want:
		_vp.size = want
	var lsize := Vector2i(maxi(int(logical.x), 1), maxi(int(logical.y), 1))
	if _vp.size_2d_override != lsize:
		_vp.size_2d_override = lsize
	_proxy.position = get_global_transform_with_canvas().origin
	_proxy.size = size
	var inv := (get_parent() as CanvasItem).get_global_transform_with_canvas().affine_inverse()
	_view.position = inv * Vector2.ZERO
	_view.size = logical
