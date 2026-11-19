class_name ControlPanel
extends Control
## The Cabinet's control panel (Q-T34): the strip of the bezel under the screen where the attract menu's
## pushbuttons (ArcadeButton: START and SERVICE) live. It places its children (each ArcadeButton goes to its `slot` in
## CabinetBezel.panel_slot, so the buttons sit on the panel under the tube and never over it) and draws the panel itself:
## an angled laminate slab with a bright top lip, a shadowed front edge, contact shadows under each button and
## palm-polish beside START (shaders/cabinet/control_panel.gdshader, pass 2c). It draws after the glass (like the coin
## door), so the buttons stand proud of the sheet.

const SURFACE_SHADER := preload("res://shaders/cabinet/control_panel.gdshader")

@export var surface: CabinetSurface

var _slab: ColorRect
var _slab_mat: ShaderMaterial


func _ready() -> void:
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	if surface == null:
		surface = CabinetSurface.default() as CabinetSurface
	var panel := CabinetBezel.control_panel()
	position = panel.position
	size = panel.size
	for b in buttons():
		var r := CabinetBezel.panel_slot(b.slot)
		b.position = r.position - panel.position
		b.size = r.size
	_build_slab(panel)


## The drawn slab (a child behind the buttons), for tests and captures.
func slab_material() -> ShaderMaterial:
	return _slab_mat


func _build_slab(panel: Rect2) -> void:
	_slab = ColorRect.new()
	_slab.name = "Slab"
	_slab.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_slab.color = Color.WHITE
	_slab.position = Vector2.ZERO
	_slab.size = panel.size
	_slab_mat = ShaderMaterial.new()
	_slab_mat.shader = SURFACE_SHADER
	_slab.material = _slab_mat
	add_child(_slab)
	move_child(_slab, 0)
	CabinetLighting.apply(_slab_mat, surface)
	_slab_mat.set_shader_parameter(&"panel_size", panel.size)
	_slab_mat.set_shader_parameter(&"rig_origin", panel.position)
	_slab_mat.set_shader_parameter(&"panel_color", surface.panel_color)
	_slab_mat.set_shader_parameter(&"lip", surface.panel_lip)
	_slab_mat.set_shader_parameter(&"lip_width", surface.panel_lip_width)
	_slab_mat.set_shader_parameter(&"front_shadow", surface.panel_front_shadow)
	_slab_mat.set_shader_parameter(&"front_width", surface.panel_front_width)
	_slab_mat.set_shader_parameter(&"contact", surface.panel_contact)
	_slab_mat.set_shader_parameter(&"palm", surface.panel_palm_polish)
	_slab_mat.set_shader_parameter(&"grain", surface.panel_grain)
	var start := CabinetBezel.panel_slot(0)
	_slab_mat.set_shader_parameter(&"palm_c", Vector2(start.get_center().x - panel.position.x + 46.0, 14.0))
	var centres := PackedVector4Array()
	var radii := PackedFloat32Array()
	for b in buttons():
		var h := ArcadeButton.cap_half(b.kind)
		var c := b.position + Vector2(b.size.x * 0.5, ArcadeButton.CAP_CY)
		centres.append(Vector4(c.x, c.y, h.x, h.y))
		radii.append(ArcadeButton.cap_radius(b.kind))
	var n := centres.size()
	while centres.size() < 4:
		centres.append(Vector4())
		radii.append(0.0)
	_slab_mat.set_shader_parameter(&"btn_n", n)
	_slab_mat.set_shader_parameter(&"btn", centres)
	_slab_mat.set_shader_parameter(&"btn_r", radii)


## The panel's buttons, in slot order.
func buttons() -> Array[ArcadeButton]:
	var out: Array[ArcadeButton] = []
	for c in get_children():
		if c is ArcadeButton:
			out.append(c)
	out.sort_custom(func(a: ArcadeButton, b: ArcadeButton) -> bool: return a.slot < b.slot)
	return out


## The in-game bezel's panel: START and SERVICE in their slots and the POWER rocker in its place, as decoration only
## (the arcade game is played with the game's own controls). Lamps dark, not focusable, mouse and input ignored.
## The rocker is returned through `rocker_out` (a one-element array) so the caller can slide it with the right column.
static func add_decorative(host: Control, rocker_out: Array = []) -> ControlPanel:
	var panel := ControlPanel.new()
	panel.name = "ControlPanel"
	var specs := [
		[ArcadeButton.Kind.START, 0, "MENU_NEW_VIGIL", 0.0],
		[ArcadeButton.Kind.SERVICE, 1, "CAB_PANEL_SERVICE", 1.0],
	]
	for s: Array in specs:
		var b := ArcadeButton.new()
		b.kind = s[0]
		b.slot = s[1]
		b.label_key = s[2]
		b.variant = s[3]
		panel.add_child(b)
	host.add_child(panel)
	for b in panel.buttons():
		b.focus_mode = Control.FOCUS_NONE
		b.mouse_filter = Control.MOUSE_FILTER_IGNORE
		b.mouse_default_cursor_shape = Control.CURSOR_ARROW
	var rocker := PowerRocker.new()
	rocker.name = "PowerRocker"
	rocker.decorative = true
	host.add_child(rocker)
	rocker_out.append(rocker)
	return panel
