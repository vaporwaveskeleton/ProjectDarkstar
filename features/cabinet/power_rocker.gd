class_name PowerRocker
extends BaseButton
## The POWER rocker switch on the Cabinet's right side under the coin door (pass 2c, owner ruling): a real
## focusable BaseButton (UI-001: `pressed`, `disabled`, focus, `ui_accept` and the mouse are the engine's own) drawn as an
## object by shaders/cabinet/power_rocker.gdshader with its decal ("POWER") printed beside it in VectorText.
## It stands where CabinetBezel.power_rocker() puts it (column-local, so it never meets the coin door, the vent or
## the screen hole). Pressing it only emits `pressed`: the attract screen asks for confirmation, and `throw_off`
## flips the paddle once the player has confirmed. While it has focus or the mouse is over it, a plain caption
## ("Quit game", PanelCaption) is drawn on the panel strip beside it, so nobody has to guess what it does.
## `decorative` makes the in-game copy inert: lit, never focusable, mouse ignored.

const SHADER := preload("res://shaders/cabinet/power_rocker.gdshader")
const MARGIN := 4.0                    ## the drawn face extends this far past the control (shadow, grime, halo)
const ROCKER_C := Vector2(33.5, 7.25)  ## the rocker housing's centre, control-local
const ROCKER_HALF := Vector2(9.5, 5.4)
const LABEL_CENTER_X := 12.0           ## the decal's centre, control-local
const LABEL_CAP := 3.2                 ## ✱ presentation data: the panel's small print
const LABEL_STROKE := 0.75
const LABEL_TRACK := 0.55
const PRESS_SECONDS := 0.06
const PRESS_HOLD := 0.14
const FOCUS_SECONDS := 0.12
const FLIP_SECONDS := 0.16             ## the paddle's throw
const CAPTION_GAP := 4.0               ## between the panel's right end and the caption plate

@export var surface: CabinetSurface
@export var label_key := "CAB_PANEL_POWER"
@export var caption_key := "CAB_PANEL_POWER_HINT"
@export var decorative := false

## True once the switch has been thrown OFF (the player confirmed): the paddle tilts and the lamp dies.
var off := false

var _face: ColorRect
var _mat: ShaderMaterial
var _down := false
var _key_hold := 0.0
var _press_k := 0.0
var _focus_k := 0.0
var _hover_k := 0.0
var _flip_k := 0.0
var _cap_k := 0.0
var _cap_want := false
var _over := false
var _cache: Dictionary = {}
var _origin := Vector2(-1.0e9, 0.0)


func _ready() -> void:
	position = CabinetBezel.power_rocker().position
	size = CabinetBezel.power_rocker().size
	if decorative:
		focus_mode = Control.FOCUS_NONE
		mouse_filter = Control.MOUSE_FILTER_IGNORE
		mouse_default_cursor_shape = Control.CURSOR_ARROW
	else:
		focus_mode = Control.FOCUS_ALL
		mouse_filter = Control.MOUSE_FILTER_STOP
		mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND
		button_down.connect(func() -> void: _down = true)
		button_up.connect(func() -> void: _down = false)
		pressed.connect(func() -> void: _key_hold = PRESS_HOLD)
		mouse_entered.connect(func() -> void: _over = true)
		mouse_exited.connect(func() -> void: _over = false)
		accessibility_name = tr(label_key)
	if surface == null:
		surface = CabinetSurface.default() as CabinetSurface
	_face = ColorRect.new()
	_face.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_face.show_behind_parent = true
	_face.color = Color.WHITE
	_mat = ShaderMaterial.new()
	_mat.shader = SHADER
	_face.material = _mat
	add_child(_face)
	resized.connect(_layout_face)
	_apply_surface()
	_layout_face()


## The shader material, for tests and captures.
func face_material() -> ShaderMaterial:
	return _mat


## The paddle's throw 0 (ON) .. 1 (OFF).
func flip_level() -> float:
	return _flip_k


## Throw the switch OFF (the paddle flips at once when photosensitivity or reduced motion is on).
func throw_off() -> void:
	off = true
	if ArcadeButton.is_still():
		_flip_k = 1.0


func is_down() -> bool:
	return _down or _key_hold > 0.0


## The decal's text.
func label_text() -> String:
	return tr(label_key).to_upper()


## The decal's painted rect, control-local.
func label_rect() -> Rect2:
	var sz := BezelText.painted_size(label_text(), LABEL_CAP, LABEL_STROKE, LABEL_TRACK)
	return Rect2(Vector2(LABEL_CENTER_X - sz.x * 0.5, ROCKER_C.y - LABEL_CAP * 0.5 - LABEL_STROKE * 0.5), sz)


## The rocker housing's rect, control-local.
func housing_rect() -> Rect2:
	return Rect2(ROCKER_C - ROCKER_HALF, ROCKER_HALF * 2.0)


func caption_text() -> String:
	return tr(caption_key) if caption_key != "" else ""


## The caption's plate, control-local: right-aligned against the panel strip's right end (left of the rocker, over
## the panel, never over the screen), nudged down if a large text size would push it up into the tube-mask edge.
func caption_rect() -> Rect2:
	var at_rig := CabinetBezel.power_rocker().position
	var panel := CabinetBezel.control_panel()
	var anchor := Vector2(panel.end.x - CAPTION_GAP - at_rig.x, size.y * 0.5)
	var r := PanelCaption.rect(caption_text(), anchor, true)
	var top_limit := panel.position.y + 1.0 - at_rig.y
	if r.position.y < top_limit:
		r.position.y = top_limit
	return r


func caption_visible() -> bool:
	return _cap_want


func _apply_surface() -> void:
	if _mat == null or surface == null:
		return
	var inks := BezelInks.default() as BezelInks
	CabinetLighting.apply(_mat, surface)
	_mat.set_shader_parameter(&"rk_half", ROCKER_HALF)
	_mat.set_shader_parameter(&"ring_color", surface.zinc_color)
	_mat.set_shader_parameter(&"lamp_color", surface.rocker_lamp_color)
	_mat.set_shader_parameter(&"ink_color", inks.cream)
	_mat.set_shader_parameter(&"focus_color", inks.yellow.lightened(0.25))
	_mat.set_shader_parameter(&"wear", surface.wear)
	_mat.set_shader_parameter(&"grime", surface.grime)
	_mat.set_shader_parameter(&"micro_texture", surface.micro_texture)


func _layout_face() -> void:
	if _face == null:
		return
	_face.position = Vector2(-MARGIN, -MARGIN)
	_face.size = size + Vector2(MARGIN, MARGIN) * 2.0
	_mat.set_shader_parameter(&"face_size", _face.size)
	_mat.set_shader_parameter(&"rk_c", ROCKER_C + Vector2(MARGIN, MARGIN))
	_update_origin()


func _update_origin() -> void:
	var o := position - Vector2(MARGIN, MARGIN)
	var parent := get_parent() as Control
	if parent != null:
		o += parent.position
	if o != _origin:
		_origin = o
		_mat.set_shader_parameter(&"rig_origin", o)


func _process(delta: float) -> void:
	_update_origin()
	_key_hold = maxf(_key_hold - delta, 0.0)
	_press_k = move_toward(_press_k, 1.0 if is_down() and not disabled else 0.0, delta / PRESS_SECONDS)
	_focus_k = move_toward(_focus_k, 1.0 if has_focus() else 0.0, delta / FOCUS_SECONDS)
	_hover_k = move_toward(_hover_k, 1.0 if _over and not disabled else 0.0, delta / FOCUS_SECONDS)
	_flip_k = move_toward(_flip_k, 1.0 if off else 0.0, delta / FLIP_SECONDS)
	var want_caption := 1.0 if (not decorative and not disabled and (has_focus() or _over)) else 0.0
	_cap_want = want_caption > 0.0
	_cap_k = move_toward(_cap_k, want_caption, delta / PanelCaption.FADE_SECONDS)
	_mat.set_shader_parameter(&"press", _press_k)
	_mat.set_shader_parameter(&"focus_k", _focus_k)
	_mat.set_shader_parameter(&"hover_k", _hover_k)
	_mat.set_shader_parameter(&"flip", _flip_k)
	_mat.set_shader_parameter(&"dim", 1.0 if disabled else 0.0)
	queue_redraw()


## The pad's accept button when the InputMap carries no pad binding for `ui_accept` (BaseButton handles the rest).
func _gui_input(event: InputEvent) -> void:
	if decorative or disabled or not (event is InputEventJoypadButton) or not InputLabels.is_accept(event) or event.is_action(&"ui_accept"):
		return
	if event.is_pressed() and not event.is_echo():
		pressed.emit()
	accept_event()


func _notification(what: int) -> void:
	match what:
		NOTIFICATION_FOCUS_EXIT:
			_key_hold = 0.0
		NOTIFICATION_VISIBILITY_CHANGED:
			_down = false


## The decal, cream ink (lit yellow with an underline when focused, dull when disabled), then the caption.
func _draw() -> void:
	var inks := BezelInks.default() as BezelInks
	var col := inks.cream.darkened(0.12)
	if disabled:
		col = inks.cream.darkened(0.62)
	elif has_focus():
		col = inks.yellow.lightened(0.25)
	var text := label_text()
	var top := ROCKER_C.y - LABEL_CAP * 0.5
	BezelText.draw(self, _cache, text, Vector2(LABEL_CENTER_X, top), true, LABEL_CAP, LABEL_STROKE, LABEL_TRACK, col)
	if has_focus() and not disabled:
		var sz := BezelText.ink_size(text, LABEL_CAP, LABEL_STROKE, LABEL_TRACK)
		draw_rect(Rect2(LABEL_CENTER_X - sz.x * 0.5, top + sz.y + LABEL_STROKE + 0.9, sz.x, 0.8), col)
	if _cap_k > 0.0:
		var r := caption_rect()
		PanelCaption.draw(self, _cache, caption_text(), Vector2(r.end.x, r.get_center().y), true, _cap_k)
