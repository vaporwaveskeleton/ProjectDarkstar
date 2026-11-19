class_name RuinsLamp
extends Node2D
## One flame in the Ruins (the hall lantern or a Tree lamp): its catch, its glass and flame, and the
## PointLight2D that lights the hall. A catch is a slow monotonic bloom (smoothstep over
## `catch_s`), never a flash; once caught the flame breathes gently far under 3 Hz
## (photosensitivity, ART-001 §12). Draws only the flame and its own glass (GAS only here, ART-001
## §4); the housing of a Tree lamp is M1's. Unshaded, so the hall's ambient never dims the flame.

## ✱ radial light texture size in px (generated, no image file).
const LIGHT_TEX := 256

## Hanging hall lantern (draws a brass cage on a chain) or a bare Tree-lamp flame.
@export var hanging: bool = false
## Logical px from the lamp up to the vault (chain length) when hanging.
@export var chain_px: float = 140.0

var colour: Color = Pal.GAS_4
var energy: float = 1.0
var radius: float = 150.0
var core_hdr: float = 1.5
var catch_s: float = 2.0
var breath_hz: float = 0.18
var breath_depth: float = 0.03
## 0 = unlit … 1 = caught. Monotonic during a catch.
var level: float = 0.0
var catching: bool = false
var _catch_t: float = 0.0
var _t: float = 0.0
var _light: PointLight2D
var _flame_mat: CanvasItemMaterial


func _ready() -> void:
	_light = PointLight2D.new()
	_light.name = "Light"
	_light.texture = radial_texture()
	_light.blend_mode = Light2D.BLEND_MODE_ADD
	_light.shadow_enabled = false
	# a Light2D only lights its own CanvasLayer range: follow the layer this lamp is drawn in
	var cl := get_canvas_layer_node()
	var layer := cl.layer if cl != null else 0
	_light.range_layer_min = layer
	_light.range_layer_max = layer
	add_child(_light)
	_apply()


func configure(p_colour: Color, p_energy: float, p_radius: float, p_core_hdr: float, p_catch_s: float,
		p_breath_hz: float, p_breath_depth: float) -> void:
	colour = p_colour
	energy = p_energy
	radius = p_radius
	core_hdr = p_core_hdr
	catch_s = maxf(p_catch_s, 0.01)
	breath_hz = p_breath_hz
	breath_depth = p_breath_depth
	_apply()


## Start the slow catch from where the flame is now (0 if unlit).
func catch_light() -> void:
	catching = true
	_catch_t = catch_s * _inverse_curve(level)


## Lit at once (a lamp already lit on an earlier visit).
func light_now() -> void:
	catching = false
	level = 1.0
	_apply()


func snuff() -> void:
	catching = false
	level = 0.0
	_apply()


## Output as a fraction of full: the catch level times the breath. What the hall and tests read.
func output() -> float:
	return level * breath()


func breath() -> float:
	if level < 1.0:
		return 1.0
	return 1.0 - breath_depth * 0.5 * (1.0 - cos(TAU * breath_hz * _t))


## Light energy currently given to the hall.
func light_energy() -> float:
	return energy * output()


## Luminance of the flame's core as drawn (HDR), at full output.
func core_luminance() -> float:
	return (Pal.GAS_5 * core_hdr).get_luminance()


## The catch curve: smoothstep, monotonic, steepest slope 1.5 / catch_s per second.
static func catch_curve(x: float) -> float:
	var c := clampf(x, 0.0, 1.0)
	return c * c * (3.0 - 2.0 * c)


static func _inverse_curve(y: float) -> float:
	# bisection: smoothstep is monotonic on [0, 1]
	var lo := 0.0
	var hi := 1.0
	for i in 20:
		var mid := (lo + hi) * 0.5
		if catch_curve(mid) < y:
			lo = mid
		else:
			hi = mid
	return (lo + hi) * 0.5


## Advance one step. The owner calls this (so tests can step deterministically).
func step(delta: float) -> void:
	if catching:
		_catch_t += delta
		level = catch_curve(_catch_t / catch_s)
		if _catch_t >= catch_s:
			level = 1.0
			catching = false
			_t = 0.0
	elif level >= 1.0:
		_t += delta
	_apply()


func _apply() -> void:
	if _light == null:
		return
	_light.color = colour
	_light.energy = light_energy()
	_light.texture_scale = radius * 2.0 / float(LIGHT_TEX)
	_light.enabled = level > 0.0
	if _flame_mat == null:
		_flame_mat = CanvasItemMaterial.new()
		_flame_mat.light_mode = CanvasItemMaterial.LIGHT_MODE_UNSHADED
		material = _flame_mat
	queue_redraw()


## A soft interior falloff (roughly inverse-square with a smooth edge), generated.
static func radial_texture() -> GradientTexture2D:
	var g := Gradient.new()
	g.offsets = PackedFloat32Array([0.0, 0.1, 0.3, 0.55, 0.8, 1.0])
	g.colors = PackedColorArray([Color(1, 1, 1, 1), Color(0.86, 0.86, 0.86, 1), Color(0.56, 0.56, 0.56, 1),
		Color(0.26, 0.26, 0.26, 1), Color(0.08, 0.08, 0.08, 1), Color(0, 0, 0, 1)])
	var t := GradientTexture2D.new()
	t.gradient = g
	t.width = LIGHT_TEX
	t.height = LIGHT_TEX
	t.fill = GradientTexture2D.FILL_RADIAL
	t.fill_from = Vector2(0.5, 0.5)
	t.fill_to = Vector2(1.0, 0.5)
	return t


func _draw() -> void:
	var o := output()
	if hanging:
		_draw_cage(o)
	_draw_flame(o)


func _draw_flame(o: float) -> void:
	if o <= 0.0:
		# an unlit wick: dark glass, no light
		draw_circle(Vector2.ZERO, 2.0, Pal.VOID_3)
		return
	# a soft halo in the glass (stepped rings, faint), then the flame; everything scales with the
	# output, so the first frame of a catch adds almost nothing (no pop)
	for k in 3:
		var halo := colour
		halo.a = (0.05 + 0.04 * k) * o
		draw_circle(Vector2.ZERO, (7.0 - 2.0 * k) * (0.5 + 0.5 * o), halo)
	var glass := Pal.GAS_3
	glass.a = 0.45 * o
	draw_circle(Vector2.ZERO, 2.0 + 1.2 * o, glass)
	var core := Pal.GAS_5 * lerpf(1.0, core_hdr, o)
	core.a = o
	# the flame: a small teardrop, taller as it catches
	var h := 1.5 + 3.0 * o
	var pts := PackedVector2Array([Vector2(0, -h), Vector2(1.3 * o + 0.4, -h * 0.25), Vector2(0.9, 0.9),
		Vector2(-0.9, 0.9), Vector2(-1.3 * o - 0.4, -h * 0.25)])
	draw_colored_polygon(pts, Color(Pal.GAS_4, o))
	draw_circle(Vector2(0, -0.2), 0.6 + 0.9 * o, core)


func _draw_cage(o: float) -> void:
	# chain up to the vault, a brass cap, four glass panes in a brass frame
	# unshaded, so the cage carries its own lighting: VOID in the dark, brass by its own flame
	var lit_brass := Pal.VOID_4.lerp(Pal.BONE_3.lerp(Pal.GAS_3, 0.4), o)
	var dark_brass := Pal.VOID_2.lerp(Pal.BONE_1.lerp(Pal.GAS_1, 0.5), o)
	var link := 0.0
	while link < chain_px:
		var y := -9.0 - link
		draw_line(Vector2(0, y), Vector2(0, y - 3.0), dark_brass, 1.0)
		link += 4.0
	var cap := PackedVector2Array([Vector2(-5, -7), Vector2(0, -10), Vector2(5, -7)])
	draw_colored_polygon(cap, lit_brass)
	var pane := Pal.VOID_3.lerp(Pal.GAS_2, o)
	pane.a = 0.4 + 0.2 * o
	draw_rect(Rect2(-4, -7, 8, 12), pane)
	for x in [-4.5, -1.5, 1.5, 4.5]:
		draw_line(Vector2(x, -7), Vector2(x, 5), dark_brass if absf(x) < 2.0 else lit_brass, 0.7)
	draw_line(Vector2(-5, -7), Vector2(5, -7), lit_brass, 1.0)
	draw_line(Vector2(-5, 5), Vector2(5, 5), lit_brass, 1.0)
	draw_colored_polygon(PackedVector2Array([Vector2(-4, 5), Vector2(4, 5), Vector2(1.5, 8), Vector2(-1.5, 8)]), dark_brass)
