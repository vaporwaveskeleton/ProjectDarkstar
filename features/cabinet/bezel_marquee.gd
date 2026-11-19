class_name BezelMarquee
extends ColorRect
## The marquee (Q-T32 (a)): a thin backlit translucent sign in the top 28 rig units above the screen
## (CabinetBezel.marquee()). The sign is shaders/cabinet/bezel_marquee.gdshader (uneven backlight, a dead tube
## band, dust on its top edge); its lettering is the game title via tr("GAME_TITLE") in VectorText, printed
## ink on the lens through the print material (BezelText on a child CanvasItem).

const SHADER := preload("res://shaders/cabinet/bezel_marquee.gdshader")
const KEY := "GAME_TITLE"

@export var surface: CabinetSurface

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
	_ink = Control.new()
	_ink.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_ink.size = r.size
	_ink.material = CabinetLighting.print_material(surface, r.position, false)
	_ink.draw.connect(_draw_ink)
	add_child(_ink)


## Where the lettering's cap-top sits (sign-local) and its centre x.
func lettering_anchor() -> Vector2:
	return Vector2(size.x * 0.5, (size.y - surface.marquee_lettering) * 0.5)


## The painted size of the lettering (for tests).
func lettering_size() -> Vector2:
	return BezelText.ink_size(tr(KEY), surface.marquee_lettering, surface.marquee_stroke + 1.6, surface.marquee_tracking)


func _draw_ink() -> void:
	var inks := BezelInks.default() as BezelInks
	var s := tr(KEY)
	var at := lettering_anchor()
	var cap := surface.marquee_lettering
	var st := surface.marquee_stroke
	var tr_ := surface.marquee_tracking
	BezelText.draw(_ink, _cache, s, at + Vector2(1.0, 1.2), true, cap, st + 1.6, tr_, inks.key_black)
	BezelText.draw(_ink, _cache, s, at, true, cap, st, tr_, inks.warm_red)
