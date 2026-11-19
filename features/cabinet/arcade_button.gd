class_name ArcadeButton
extends BaseButton
## One physical pushbutton on the Cabinet's control panel (Q-T34, owner ruling 2026-11-19; pass 2c wording): the attract menu's
## START (New Vigil) and the small SERVICE button (Settings). A real focusable BaseButton (UI-001; `pressed`, `disabled`, focus, `ui_accept`
## and the mouse are the engine's own), drawn as an object: a translucent plastic cap with a lamp inside it in a chrome ring, by
## shaders/cabinet/arcade_button.gdshader, with its label printed on the panel under it in VectorText
## (BezelText). Mouse click (on release, inside), `ui_accept` and the pad's accept press it.
## Look and feel: START is a big lit pushbutton that blinks once a credit is in (steady with photosensitivity
## or reduced motion on); SERVICE buttons are small and unlit. Pressed, the cap drops and darkens; hover lifts
## the lamp; focus lights a halo round the ring, brightens the lamp and the printed label and lights an
## underline, so keyboard and pad focus reads as a physical selector at any distance.


enum Kind { START, SERVICE }

const SHADER := preload("res://shaders/cabinet/arcade_button.gdshader")
const MARGIN := 5.0                  ## the drawn face extends this far past the control (shadow, grime, halo)
const CAP_CY := 8.6                  ## cap centre y, control-local (the control is the whole panel slot)
const START_HALF := Vector2(11.0, 6.2)
const START_R := 3.5
const SERVICE_HALF := Vector2(5.0, 5.0)
const SERVICE_R := 5.0
const LABEL_TOP := 18.6              ## the printed label's cap-top, control-local
const LABEL_CAP := 3.6               ## ✱ presentation data: the panel's small print
const LABEL_STROKE := 0.8
const LABEL_TRACK := 0.7
const PRESS_SECONDS := 0.06          ## cap travel time
const PRESS_HOLD := 0.14             ## a key or pad press shows at least this long
const FOCUS_SECONDS := 0.12
const BLINK_HZ := 0.8                ## the lamp's flash rate (≤ 3 Hz, GDD §15 photosensitivity)
const DECAL_SHADER := preload("res://shaders/cabinet/panel_decal.gdshader")
const CAPTION_GAP := 3.5             ## between the bezel ring and the caption plate

@export var kind: Kind = Kind.SERVICE
@export var slot := 0                ## which CabinetBezel.panel_slot this sits in (ControlPanel places it)
@export var label_key := ""          ## the tr() key printed under the button
@export var caption_key := ""        ## the tr() key of the plain-language caption shown beside it on focus or hover (none: no caption)
@export var surface: CabinetSurface
@export var variant := 0.0           ## wear seed: no two caps wear alike

## The lamp inside the cap. START turns it on when a credit is in; SERVICE caps stay unlit.
var lamp_on := false:
	set(v):
		lamp_on = v
		queue_redraw()
var blinks := false                  ## the lit lamp flashes (steady when photosensitivity / reduced motion is on)

var _face: ColorRect
var _decal: Control                  ## the printed label: its own item so the decal wear never touches the caption
var _decal_mat: ShaderMaterial
var _cap_k := 0.0                    ## caption fade 0..1 (focus or hover)
var _cap_want := false               ## focus or hover wants the caption shown
var _over := false                   ## the mouse is over the button
var _mat: ShaderMaterial
var _down := false
var _key_hold := 0.0
var _press_k := 0.0
var _focus_k := 0.0
var _hover_k := 0.0
var _t := 0.0
var _cache: Dictionary = {}
var _origin := Vector2(-1.0e9, 0.0)


func _ready() -> void:
	focus_mode = Control.FOCUS_ALL
	mouse_filter = Control.MOUSE_FILTER_STOP
	mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND
	button_down.connect(_on_button_down)
	button_up.connect(_on_button_up)
	pressed.connect(_on_pressed)
	mouse_entered.connect(func() -> void: _over = true)
	mouse_exited.connect(func() -> void: _over = false)
	if surface == null:
		surface = CabinetSurface.default() as CabinetSurface
	accessibility_name = tr(label_key)
	_face = ColorRect.new()
	_face.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_face.show_behind_parent = true
	_face.color = Color.WHITE
	_mat = ShaderMaterial.new()
	_mat.shader = SHADER
	_face.material = _mat
	add_child(_face)
	_decal = Control.new()
	_decal.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_decal.set_anchors_preset(Control.PRESET_FULL_RECT)
	_decal_mat = ShaderMaterial.new()
	_decal_mat.shader = DECAL_SHADER
	_decal.material = _decal_mat
	_decal.draw.connect(_draw_decal)
	add_child(_decal)
	resized.connect(_layout_face)
	_apply_surface()
	_layout_face()


## The cap's half size and corner radius for a kind.
static func cap_half(k: Kind) -> Vector2:
	return START_HALF if k == Kind.START else SERVICE_HALF


static func cap_radius(k: Kind) -> float:
	return START_R if k == Kind.START else SERVICE_R


## The cap's rectangle, control-local (unpressed): what a click on "the button" means.
func cap_rect() -> Rect2:
	var h := cap_half(kind)
	return Rect2(Vector2(size.x * 0.5, CAP_CY) - h, h * 2.0)


## The text printed under the button.
func label_text() -> String:
	return tr(label_key).to_upper()


## The label's painted rect, control-local.
func label_rect() -> Rect2:
	var sz := BezelText.painted_size(label_text(), LABEL_CAP, LABEL_STROKE, LABEL_TRACK)
	return Rect2(Vector2((size.x - sz.x) * 0.5, LABEL_TOP - LABEL_STROKE * 0.5), sz)


## True while the cap is down (mouse held, or a key / pad press still showing).
func is_down() -> bool:
	return _down or _key_hold > 0.0


## The lamp's current strength 0..1 (before the focus and hover lift): off, steady, or flashing.
func lamp_level() -> float:
	if not lamp_on or disabled:
		return 0.0
	if blinks and not is_still():
		return 1.0 if int(_t * BLINK_HZ * 2.0) % 2 == 0 else 0.3
	return 1.0


## Photosensitivity or reduced motion on: lamps hold steady.
static func is_still() -> bool:
	return bool(SettingsService.get_value(&"photosensitivity")) or bool(SettingsService.get_value(&"reduced_motion"))


## The shader material, for tests and captures.
func face_material() -> ShaderMaterial:
	return _mat


func _apply_surface() -> void:
	if _mat == null or surface == null:
		return
	CabinetLighting.apply(_mat, surface)
	CabinetLighting.apply(_decal_mat, surface)
	_decal_mat.set_shader_parameter(&"rub", surface.start_decal_rub if kind == Kind.START else surface.decal_rub)
	_decal_mat.set_shader_parameter(&"bias", 1.0 if kind == Kind.START else 0.4)
	var inks := BezelInks.default() as BezelInks
	var h := cap_half(kind)
	_mat.set_shader_parameter(&"cap_half", h)
	_mat.set_shader_parameter(&"cap_r", cap_radius(kind))
	_mat.set_shader_parameter(&"ring_color", surface.zinc_color)
	_mat.set_shader_parameter(&"wear", surface.wear)
	_mat.set_shader_parameter(&"grime", surface.grime)
	_mat.set_shader_parameter(&"thumb_wear", surface.thumb_wear)
	_mat.set_shader_parameter(&"micro_texture", surface.micro_texture)
	_mat.set_shader_parameter(&"variant", variant)
	_mat.set_shader_parameter(&"focus_color", inks.yellow.lightened(0.25))
	if kind == Kind.START:
		_mat.set_shader_parameter(&"plastic_color", surface.lens_color.darkened(0.12))
		_mat.set_shader_parameter(&"lamp_color", surface.lens_color.lightened(0.35))
	else:
		_mat.set_shader_parameter(&"plastic_color", Color(0.1, 0.1, 0.115))        # smoked service caps
		_mat.set_shader_parameter(&"lamp_color", inks.yellow)                      # only the selector lights them


func _layout_face() -> void:
	if _face == null:
		return
	_face.position = Vector2(-MARGIN, -MARGIN)
	_face.size = size + Vector2(MARGIN, MARGIN) * 2.0
	_mat.set_shader_parameter(&"face_size", _face.size)
	_mat.set_shader_parameter(&"cap_c", Vector2(size.x * 0.5, CAP_CY) + Vector2(MARGIN, MARGIN))
	_decal_mat.set_shader_parameter(&"label_w", label_rect().size.x)
	_update_origin()


## The face's top-left in rig units: the control's own position plus its parent's (the ControlPanel sits in the Rig).
func _update_origin() -> void:
	var parent := get_parent() as Control
	var o := position + (parent.position if parent != null else Vector2.ZERO) - Vector2(MARGIN, MARGIN)
	if o != _origin:
		_origin = o
		_mat.set_shader_parameter(&"rig_origin", o)
		var ro := o + Vector2(MARGIN, MARGIN)
		_decal_mat.set_shader_parameter(&"rig_origin", ro)
		_decal_mat.set_shader_parameter(&"label_x", ro.x + label_rect().position.x)


func _process(delta: float) -> void:
	_t += delta
	_update_origin()
	_key_hold = maxf(_key_hold - delta, 0.0)
	_press_k = move_toward(_press_k, 1.0 if is_down() and not disabled else 0.0, delta / PRESS_SECONDS)
	_focus_k = move_toward(_focus_k, 1.0 if has_focus() else 0.0, delta / FOCUS_SECONDS)
	_hover_k = move_toward(_hover_k, 1.0 if is_hovered() and not disabled else 0.0, delta / FOCUS_SECONDS)
	if _mat != null:
		_mat.set_shader_parameter(&"press", _press_k)
		_mat.set_shader_parameter(&"focus_k", _focus_k)
		_mat.set_shader_parameter(&"hover_k", _hover_k)
		_mat.set_shader_parameter(&"lamp", lamp_level())
		_mat.set_shader_parameter(&"dim", 1.0 if disabled else 0.0)
		_decal_mat.set_shader_parameter(&"focus_k", _focus_k)
	var want_caption := 1.0 if (caption_key != "" and not disabled and (has_focus() or _over)) else 0.0
	_cap_want = want_caption > 0.0
	_cap_k = move_toward(_cap_k, want_caption, delta / PanelCaption.FADE_SECONDS)
	_decal.queue_redraw()
	queue_redraw()


## The pad's accept button when the InputMap carries no pad binding for `ui_accept` (BaseButton handles the rest:
## the mouse on release inside, `ui_accept`, focus and the disabled state).
func _gui_input(event: InputEvent) -> void:
	if disabled or not (event is InputEventJoypadButton) or not InputLabels.is_accept(event) or event.is_action(&"ui_accept"):
		return
	if event.is_pressed() and not event.is_echo():
		pressed.emit()
	accept_event()


func _on_button_down() -> void:
	_down = true


func _on_button_up() -> void:
	_down = false


func _on_pressed() -> void:
	_key_hold = PRESS_HOLD          # a quick tap still shows the cap going down


func _notification(what: int) -> void:
	match what:
		NOTIFICATION_FOCUS_EXIT:
			_key_hold = 0.0
		NOTIFICATION_VISIBILITY_CHANGED:
			_down = false


## The label, printed on the panel as a decal (worn by panel_decal.gdshader): cream ink; lit yellow with an
## underline when focused. Printed ink does not change when the button is disabled (only the lamp goes dark),
## so the label stays legible before a credit.
func _draw_decal() -> void:
	var inks := BezelInks.default() as BezelInks
	var col := inks.cream.darkened(0.12)
	if has_focus() and not disabled:
		col = inks.yellow.lightened(0.25)
	var text := label_text()
	var sz := BezelText.ink_size(text, LABEL_CAP, LABEL_STROKE, LABEL_TRACK)
	BezelText.draw(_decal, _cache, text, Vector2(size.x * 0.5, LABEL_TOP), true, LABEL_CAP, LABEL_STROKE, LABEL_TRACK, col)
	if has_focus() and not disabled:
		var y := LABEL_TOP + sz.y + LABEL_STROKE + 1.1
		_decal.draw_rect(Rect2(size.x * 0.5 - sz.x * 0.5, y, sz.x, 0.9), col)


## Where the caption's left-centre sits: right of the bezel ring, on the cap's centre line.
func caption_anchor() -> Vector2:
	var h := PanelCaption.plate_size(caption_text()).y * 0.5 + 0.5
	return Vector2(size.x * 0.5 + cap_half(kind).x + GAP_RING + CAPTION_GAP, maxf(CAP_CY, h))


const GAP_RING := 0.45 + 1.5          ## the shader's well gap plus ring width


## The caption's text.
func caption_text() -> String:
	return tr(caption_key) if caption_key != "" else ""


## The caption's plate rect, control-local (where it is drawn once shown).
func caption_rect() -> Rect2:
	return PanelCaption.rect(caption_text(), caption_anchor(), false)


## True while the caption is on its way in or fully shown.
func caption_visible() -> bool:
	return _cap_want


## The caption, drawn on the bezel beside the button while it has focus or the mouse is over it.
func _draw() -> void:
	if _cap_k > 0.0:
		PanelCaption.draw(self, _cache, caption_text(), caption_anchor(), false, _cap_k)
