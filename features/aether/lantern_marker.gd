class_name LanternMarker
extends Node2D
## Dev stand-in for the lantern (not the Vigil — M1 owns that): a small top-down skiff silhouette
## in BONE with a GAS lamp, and the PointLight2D that pools warm light into the fog bands.
## GAS appears only here (ART-001 §4). The lamp core is drawn over 1.0 so it is what blooms most.

## ✱ radial light texture size in px (generated, no image file).
const LIGHT_TEX := 256
## ✱ HDR multiplier on the lamp core so it reaches the bloom threshold first.
const CORE_HDR := 1.8
## ✱ bob amplitude in px and period in seconds.
const BOB_PX := 1.5
const BOB_S := 6.0

var energy: float = 1.6
var radius: float = 120.0
var _t := 0.0

@onready var light: PointLight2D = $Light


func _ready() -> void:
	light.texture = _radial_texture()
	light.color = Pal.GAS_4
	light.blend_mode = Light2D.BLEND_MODE_ADD
	light.range_item_cull_mask = 1
	light.shadow_enabled = false
	apply()


func configure(look: AetherLook) -> void:
	energy = look.lantern_energy
	radius = look.lantern_radius
	visible = look.lantern_light
	apply()


func apply() -> void:
	if light == null:
		return
	light.energy = energy
	light.texture_scale = radius * 2.0 / float(LIGHT_TEX)
	light.enabled = visible


static func _radial_texture() -> GradientTexture2D:
	var g := Gradient.new()
	g.offsets = PackedFloat32Array([0.0, 0.15, 0.4, 0.7, 1.0])
	g.colors = PackedColorArray([Color(1, 1, 1, 1), Color(0.62, 0.62, 0.62, 1), Color(0.26, 0.26, 0.26, 1),
		Color(0.07, 0.07, 0.07, 1), Color(0, 0, 0, 1)])
	var t := GradientTexture2D.new()
	t.gradient = g
	t.width = LIGHT_TEX
	t.height = LIGHT_TEX
	t.fill = GradientTexture2D.FILL_RADIAL
	t.fill_from = Vector2(0.5, 0.5)
	t.fill_to = Vector2(1.0, 0.5)
	return t


func _process(delta: float) -> void:
	_t += delta
	queue_redraw()


func _draw() -> void:
	var y := sin(_t * TAU / BOB_S) * BOB_PX
	var o := Vector2(0.0, y)
	# skiff hull, seen from above: a long pointed leaf with a keel line
	var hull := PackedVector2Array([o + Vector2(-14, 0), o + Vector2(-8, -5), o + Vector2(9, -4),
		o + Vector2(15, 0), o + Vector2(9, 4), o + Vector2(-8, 5)])
	draw_colored_polygon(hull, Pal.BONE_1)
	var outline := hull.duplicate()
	outline.append(hull[0])
	draw_polyline(outline, Pal.BONE_3, 1.0, true)
	draw_line(o + Vector2(-11, 0), o + Vector2(12, 0), Pal.BONE_2, 1.0, true)
	# the lamp: GAS glass ring and an over-bright core
	draw_circle(o + Vector2(2, 0), 4.0, Pal.GAS_2)
	draw_circle(o + Vector2(2, 0), 2.6, Pal.GAS_4)
	var core := Pal.GAS_5 * CORE_HDR
	core.a = 1.0
	draw_circle(o + Vector2(2, 0), 1.5, core)
