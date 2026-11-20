class_name MenuFrame
extends PanelContainer
## The panel of an overlay menu, drawn in its costume (MenuSkin.frame): the cabinet's service-mode
## test card in Act 0, a brass instrument case in the Aether. Replaces the theme's slate panel.
## BRASS adds a fogged-glass face (shaders/menu_glass.gdshader): slow fog drift at low contrast and a
## vignette, still under Reduced Motion or Photosensitivity. The brass, the engraved hairline and the
## rivets are drawn over it (Glass, then this node's own top layer).

## ✱ Content margins (logical px) inside the drawn frame.
const MARGIN := Vector2(18.0, 14.0)
## ✱ Fog amplitude over the glass (Fable review: 5..10 %).
const FOG_CONTRAST := 0.08
const GLASS_SHADER := preload("res://shaders/menu_glass.gdshader")

var kind: MenuSkin.Kind = MenuSkin.Kind.CABINET
var _glass: ColorRect
var _top: Control
var _time := 0.0


func _ready() -> void:
	kind = MenuSkin.for_node(self)
	var box := StyleBoxEmpty.new()
	box.content_margin_left = MARGIN.x
	box.content_margin_right = MARGIN.x
	box.content_margin_top = MARGIN.y
	box.content_margin_bottom = MARGIN.y
	add_theme_stylebox_override(&"panel", box)
	resized.connect(_on_resized)
	sort_children.connect(_on_resized)   # the container fits internal children too: put ours back
	if kind == MenuSkin.Kind.BRASS:
		_glass = ColorRect.new()
		_glass.name = &"Glass"
		_glass.mouse_filter = Control.MOUSE_FILTER_IGNORE
		var m := ShaderMaterial.new()
		m.shader = GLASS_SHADER
		m.set_shader_parameter(&"glass", Pal.VOID_1)
		m.set_shader_parameter(&"fog_a", Pal.CHOIR_1)
		m.set_shader_parameter(&"fog_b", Pal.GAS_1)
		m.set_shader_parameter(&"contrast", FOG_CONTRAST)
		_glass.material = m
		add_child(_glass, false, Node.INTERNAL_MODE_FRONT)
		# the brass case is drawn over the glass, under the menu's own content
		_top = Control.new()
		_top.name = &"Case"
		_top.mouse_filter = Control.MOUSE_FILTER_IGNORE
		_top.draw.connect(_draw_case)
		add_child(_top, false, Node.INTERNAL_MODE_FRONT)
		SettingsService.setting_changed.connect(_on_setting_changed)
		_on_setting_changed(&"reduced_motion", null)
	else:
		set_process(false)
	_on_resized()


func _on_resized() -> void:
	if _glass:
		var face := Rect2(Vector2.ZERO, size).grow(-Brass.RIVET_INSET - 2.0)
		_glass.position = face.position
		_glass.size = face.size
		(_glass.material as ShaderMaterial).set_shader_parameter(&"rect_size", face.size)
		_top.position = Vector2.ZERO
		_top.size = size
		_top.queue_redraw()
	queue_redraw()


func _on_setting_changed(k: StringName, _v: Variant) -> void:
	if k == &"reduced_motion" or k == &"photosensitivity":
		set_process(not MenuSkin.still())


func _process(delta: float) -> void:
	_time += delta
	(_glass.material as ShaderMaterial).set_shader_parameter(&"drift", _time)


## The fog's clock (tests: it does not advance under Reduced Motion).
func fog_time() -> float:
	return _time


func _draw() -> void:
	if kind == MenuSkin.Kind.BRASS:
		MenuSkin.brass_case_back(self, Rect2(Vector2.ZERO, size))
	else:
		MenuSkin.frame(self, Rect2(Vector2.ZERO, size), kind)


func _draw_case() -> void:
	MenuSkin.brass_case_front(_top, Rect2(Vector2.ZERO, size))
