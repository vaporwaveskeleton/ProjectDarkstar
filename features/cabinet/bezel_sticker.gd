class_name BezelSticker
extends ColorRect
## The "NEW!" sticker as a real die-cut vinyl sticker stuck on the glass (replaces the flat starburst):
## shaders/cabinet/bezel_sticker.gdshader draws flat inks, fading, edge wear, rim dirt and a lifted
## curling corner with a shadow; the slogan is VectorText over it, through the same print material so it
## fades and scuffs with the rest of the print. Child of the right BezelPrint column; `rect` is
## column-local (CabinetBezel.RIGHT_STICKER).

const SHADER := preload("res://shaders/cabinet/bezel_sticker.gdshader")
const MARGIN := 3.0

@export var surface: CabinetSurface

var _mat: ShaderMaterial
var _text: Control
var _sticker := Rect2()
var _text_cache: Dictionary = {}


## A sticker over `rect` (column-local).
static func make(rect: Rect2) -> BezelSticker:
	var s := BezelSticker.new()
	s._sticker = rect
	s.position = rect.position - Vector2(MARGIN, MARGIN)
	s.size = rect.size + Vector2(MARGIN, MARGIN) * 2.0
	return s


## The sticker body in column-local units (without the shadow margin).
func sticker_rect() -> Rect2:
	return _sticker


func _ready() -> void:
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	color = Color.WHITE
	if surface == null:
		surface = CabinetSurface.default() as CabinetSurface
	var inks := BezelInks.default() as BezelInks
	_mat = ShaderMaterial.new()
	_mat.shader = SHADER
	material = _mat
	var parent := get_parent() as Control
	var origin := _sticker.position + (parent.position if parent != null else Vector2.ZERO)
	CabinetLighting.apply(_mat, surface)
	_mat.set_shader_parameter(&"sticker_size", _sticker.size)
	_mat.set_shader_parameter(&"margin", MARGIN)
	_mat.set_shader_parameter(&"rig_origin", origin)
	_mat.set_shader_parameter(&"orange", inks.orange)
	_mat.set_shader_parameter(&"yellow", inks.yellow)
	_mat.set_shader_parameter(&"key_black", inks.key_black)
	_mat.set_shader_parameter(&"backing", surface.backer_color)
	_mat.set_shader_parameter(&"fade", surface.sticker_fade)
	_mat.set_shader_parameter(&"curl", surface.sticker_curl)
	_mat.set_shader_parameter(&"shadow_strength", surface.contact_shadow)
	_text = Control.new()
	_text.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_text.position = Vector2.ZERO
	_text.size = size
	_text.material = CabinetLighting.print_material(surface, origin - Vector2(MARGIN, MARGIN), false)
	_text.draw.connect(_draw_text)
	add_child(_text)


func _draw_text() -> void:
	var inks := BezelInks.default() as BezelInks
	var s := tr("CAB_BEZEL_SLOGAN")
	var cap := _sticker.size.y * 0.42
	var stroke := cap * 0.2
	var c := Vector2(MARGIN + _sticker.size.x * 0.5, MARGIN + _sticker.size.y * 0.5)
	var top := c.y - BezelText.ink_size(s, cap, stroke, 0.8).y * 0.5 + stroke * 0.5
	BezelText.draw(_text, _text_cache, s, Vector2(c.x, top), true, cap, stroke, 0.8, inks.key_black)
