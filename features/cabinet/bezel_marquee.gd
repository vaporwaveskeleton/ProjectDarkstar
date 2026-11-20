class_name BezelMarquee
extends ColorRect
## The marquee (Q-T32 (a)): a thin backlit translucent sign in the top 28 rig units above the screen
## (CabinetBezel.marquee()). The sign is shaders/cabinet/bezel_marquee.gdshader (uneven backlight, a dead tube
## band, dust on its top edge); its lettering is the game title via tr("GAME_TITLE") in VectorText, printed
## ink on the lens through the print material (BezelText on a child CanvasItem).

const SHADER := preload("res://shaders/cabinet/bezel_marquee.gdshader")
const KEY := "GAME_TITLE"
const SHADOW_FROM := 0.56    ## the shadow across the backlight, as fractions of the sign width
const SHADOW_TO := 0.71
const SHADOW_SOFT := 0.03

@export var surface: CabinetSurface

## Runtime lettering for the haunt (cursed turn): when not empty it is printed instead of tr("GAME_TITLE"),
## e.g. the title's letters rearranged. Setting it redraws the ink once.
var lettering_override := "":
	set(v):
		lettering_override = v
		if _ink != null:
			_ink.queue_redraw()
## Additive draw hook: when valid it is called after the lettering as hook.call(ink_canvas, lettering_rect_local),
## drawing on the ink layer (through the lens print material). Call refresh_ink() after changing what it draws.
var ink_hook: Callable = Callable()

var _mat: ShaderMaterial
var _ink: Control
var _cache: Dictionary = {}


func _ready() -> void:
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	color = Color.WHITE
	if surface == null:
		surface = CabinetSurface.default() as CabinetSurface
	var r := CabinetBezel.marquee()
	position = r.position
	size = r.size
	_mat = ShaderMaterial.new()
	_mat.shader = SHADER
	material = _mat
	CabinetLighting.apply(_mat, surface)
	_mat.set_shader_parameter(&"sign_size", r.size)
	_mat.set_shader_parameter(&"rig_origin", r.position)
	_mat.set_shader_parameter(&"unevenness", surface.marquee_unevenness)
	_mat.set_shader_parameter(&"dust", surface.dust)
	_mat.set_shader_parameter(&"hot", surface.marquee_hot)
	_mat.set_shader_parameter(&"shadow_depth", surface.marquee_shadow_depth)
	_mat.set_shader_parameter(&"dead_from", SHADOW_FROM)
	_mat.set_shader_parameter(&"dead_to", SHADOW_TO)
	_mat.set_shader_parameter(&"dead_soft", SHADOW_SOFT)
	_ink = Control.new()
	_ink.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_ink.size = r.size
	var ink_mat := CabinetLighting.print_material(surface, r.position, false, true)
	ink_mat.set_shader_parameter(&"backlit_shadow", shadow_params(r))
	_ink.material = ink_mat
	_ink.draw.connect(_draw_ink)
	add_child(_ink)


## The shadow across the backlight in rig x (x0, x1, depth, softness): the same band the lens shader darkens.
func shadow_params(r: Rect2) -> Vector4:
	return Vector4(r.position.x + r.size.x * SHADOW_FROM, r.position.x + r.size.x * SHADOW_TO, surface.marquee_shadow_depth, r.size.x * SHADOW_SOFT)

## Redraw the lettering (for a driven lettering_override or ink_hook).
func refresh_ink() -> void:
	if _ink != null:
		_ink.queue_redraw()


## The printed title's painted rect in rig units (static: the haunt anchors need it without a node).
static func lettering_rect() -> Rect2:
	var s := CabinetSurface.default() as CabinetSurface
	var m := CabinetBezel.marquee()
	var sz := BezelText.ink_size(TranslationServer.translate(KEY), s.marquee_lettering, s.marquee_stroke + 1.6, s.marquee_tracking)
	var top := m.position.y + (m.size.y - s.marquee_lettering) * 0.5
	return Rect2(m.position.x + (m.size.x - sz.x) * 0.5, top - (s.marquee_stroke + 1.6) * 0.5, sz.x, sz.y)


## Where the lettering's cap-top sits (sign-local) and its centre x.
func lettering_anchor() -> Vector2:
	return Vector2(size.x * 0.5, (size.y - surface.marquee_lettering) * 0.5)


## The painted size of the lettering (for tests).
func lettering_size() -> Vector2:
	return BezelText.ink_size(tr(KEY), surface.marquee_lettering, surface.marquee_stroke + 1.6, surface.marquee_tracking)


func _draw_ink() -> void:
	var inks := BezelInks.default() as BezelInks
	var s := lettering_override if lettering_override != "" else tr(KEY)
	var at := lettering_anchor()
	var cap := surface.marquee_lettering
	var st := surface.marquee_stroke
	var tr_ := surface.marquee_tracking
	BezelText.draw(_ink, _cache, s, at + Vector2(1.0, 1.2), true, cap, st + 1.6, tr_, inks.key_black)
	BezelText.draw(_ink, _cache, s, at, true, cap, st, tr_, inks.warm_red)
	if ink_hook.is_valid():
		ink_hook.call(_ink, Rect2(lettering_rect().position - position, lettering_rect().size))
