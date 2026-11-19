class_name CabinetTrim
extends Control
## The cabinet's edge (PR C pass 2): black T-molding strips along the bezel's outer edges and the zinc
## bezel bolts (slot angles seeded from the bolt's place, so no two line up). Strips follow the window's
## height (ScreenRig.refitted) so they always run to the window's top and bottom. All are lit by the one
## cabinet light. They sit outside the opening, and the molding sits outside the sheet's x range
## (CabinetBezel.sheet_x()), so they can never reach the screen.

const STRIP := preload("res://shaders/cabinet/cabinet_trim.gdshader")
const BOLT := preload("res://shaders/cabinet/bezel_bolt.gdshader")
const BOLT_RECT := 9.0
## Bolt rows (rig y) and their inset from the sheet's edge (column-local x), ✱ art placement.
const BOLT_Y: Array[float] = [16.0, 180.0, 344.0]
const BOLT_INSET := 8.0

@export var rig: ScreenRig
@export var surface: CabinetSurface

var _strips: Array[ColorRect] = []
var _bolts: Array[ColorRect] = []


func _ready() -> void:
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	if surface == null:
		surface = CabinetSurface.default() as CabinetSurface
	for side in [-1, 1]:
		_strips.append(_make_strip(side))
	for side in [-1, 1]:
		for y in BOLT_Y:
			_bolts.append(_make_bolt(side, y))
	if rig != null:
		rig.refitted.connect(set_area)
		set_area(rig.bezel_rect())
	else:
		set_area(Rect2(Vector2.ZERO, Vector2(ScreenFit.REF)))


## The molding strips in rig units for window area `area`: left (outside the sheet's left edge) then right.
static func strip_rects(area: Rect2, width: float) -> Array[Rect2]:
	var sx := CabinetBezel.sheet_x()
	return [Rect2(sx.x - width, area.position.y, width, area.size.y), Rect2(sx.y, area.position.y, width, area.size.y)]


## Bolt head centres in rig units: left side then right, `BOLT_Y` rows.
static func bolt_centres() -> Array[Vector2]:
	var sx := CabinetBezel.sheet_x()
	var out: Array[Vector2] = []
	for y in BOLT_Y:
		out.append(Vector2(sx.x + BOLT_INSET, y))
	for y in BOLT_Y:
		out.append(Vector2(sx.y - BOLT_INSET, y))
	return out


func set_area(area: Rect2) -> void:
	var rs := strip_rects(area, surface.tmold_width)
	for i in _strips.size():
		_strips[i].position = rs[i].position
		_strips[i].size = rs[i].size
		var m := _strips[i].material as ShaderMaterial
		m.set_shader_parameter(&"strip_size", rs[i].size)
		m.set_shader_parameter(&"rig_origin", rs[i].position)


func strips() -> Array[ColorRect]:
	return _strips


func bolts() -> Array[ColorRect]:
	return _bolts


func _make_strip(side: int) -> ColorRect:
	var c := ColorRect.new()
	c.mouse_filter = Control.MOUSE_FILTER_IGNORE
	c.color = Color.WHITE
	var m := ShaderMaterial.new()
	m.shader = STRIP
	CabinetLighting.apply(m, surface)
	m.set_shader_parameter(&"across", 0)
	m.set_shader_parameter(&"outward", float(side))
	m.set_shader_parameter(&"wear", surface.wear)
	c.material = m
	add_child(c)
	return c


func _make_bolt(side: int, y: float) -> ColorRect:
	var sx := CabinetBezel.sheet_x()
	var centre := Vector2(sx.x + BOLT_INSET if side < 0 else sx.y - BOLT_INSET, y)
	var c := ColorRect.new()
	c.mouse_filter = Control.MOUSE_FILTER_IGNORE
	c.color = Color.WHITE
	c.position = centre - Vector2(BOLT_RECT, BOLT_RECT) * 0.5
	c.size = Vector2(BOLT_RECT, BOLT_RECT)
	var m := ShaderMaterial.new()
	m.shader = BOLT
	CabinetLighting.apply(m, surface)
	m.set_shader_parameter(&"head_r", surface.bolt_radius)
	m.set_shader_parameter(&"rig_origin", c.position)
	m.set_shader_parameter(&"rect_size", c.size)
	var h := BezelArt.hash_int(int(centre.x * 7.0) + int(centre.y * 13.0))
	m.set_shader_parameter(&"slot_angle", float(h % 3142) / 1000.0)
	m.set_shader_parameter(&"zinc", Vector3(surface.zinc_color.r, surface.zinc_color.g, surface.zinc_color.b))
	c.material = m
	add_child(c)
	return c
