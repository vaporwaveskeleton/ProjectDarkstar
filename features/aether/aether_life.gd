class_name AetherLife
extends GPUParticles2D
## One kind of Aether life (ART-001 §16) as GPU particles. Motion is the aether_life particle
## shader (shared current, school formation, flee); drawing is aether_life_draw from a generated
## white GradientTexture2D (no image files, D-13). Colours are Pal entries from the look.

enum Kind { MOTE, JELLY, SPORE, SCHOOL, VAST_JELLY }

@export var kind: Kind = Kind.MOTE
## ✱ half-size of the field the particles wrap within, logical px.
@export var extents: Vector2 = Vector2(420.0, 260.0)

const MOTION := preload("res://shaders/aether/aether_life.gdshader")
const DRAW := preload("res://shaders/aether/aether_life_draw.gdshader")
const TEX_PX := 32   ## ✱ quad texture size; particle scale is px / TEX_PX

var motion_mat: ShaderMaterial
var draw_mat: ShaderMaterial
var colour: Color = Pal.PHOS_3


func _ready() -> void:
	_ensure()


func _ensure() -> void:
	if motion_mat != null:
		return
	motion_mat = ShaderMaterial.new()
	motion_mat.shader = MOTION
	process_material = motion_mat
	draw_mat = ShaderMaterial.new()
	draw_mat.shader = DRAW
	material = draw_mat
	texture = _white_texture()
	local_coords = true
	lifetime = 3600.0
	explosiveness = 1.0
	one_shot = false
	fixed_fps = 0
	interpolate = false
	visibility_rect = Rect2(-extents * 1.5, extents * 3.0)
	light_mask = 0


static func _white_texture() -> GradientTexture2D:
	var g := Gradient.new()
	g.set_color(0, Color(1, 1, 1, 1))
	g.set_color(1, Color(1, 1, 1, 1))
	var t := GradientTexture2D.new()
	t.gradient = g
	t.width = TEX_PX
	t.height = TEX_PX
	return t


## Set up this kind from a look. `count` 0 hides the node.
func configure(look: AetherLook, count: int, quality_scale: float = 1.0) -> void:
	_ensure()
	var n := maxi(int(round(float(count) * look.life_density * quality_scale)), 0)
	if count > 0 and n == 0:
		n = 1
	visible = n > 0 and look.life
	emitting = visible
	if not visible:
		return
	amount = n
	var shape := 0
	var size_px := Vector2(1.5, 3.0)
	var glow := 1.0
	var alpha := 0.7
	colour = look.life_secondary
	motion_mat.set_shader_parameter(&"mode", 0)
	motion_mat.set_shader_parameter(&"align", 1.0)
	motion_mat.set_shader_parameter(&"drift", Vector2(4.0, -1.5))
	motion_mat.set_shader_parameter(&"swirl", 6.0)
	motion_mat.set_shader_parameter(&"current_strength", 10.0)
	match kind:
		Kind.JELLY:
			shape = 1
			size_px = Vector2(14.0, 64.0)
			colour = look.life_glow
			glow = 1.35 if look.emitters_bloom else 1.0
			alpha = 0.9
			motion_mat.set_shader_parameter(&"align", 0.0)
			motion_mat.set_shader_parameter(&"drift", Vector2(2.0, -3.0))
			motion_mat.set_shader_parameter(&"swirl", 3.0)
		Kind.SPORE:
			shape = 2
			size_px = Vector2(3.0, 7.0)
			colour = look.life_glow.lerp(look.fog_high, 0.35)
			alpha = 0.55
			motion_mat.set_shader_parameter(&"drift", Vector2(1.0, -5.0))
			motion_mat.set_shader_parameter(&"swirl", 9.0)
		Kind.VAST_JELLY:
			# vast, far and cropped: very dim, slow, swallowed by the fog
			shape = 1
			size_px = Vector2(240.0, 340.0)
			colour = look.life_glow
			glow = 0.8
			alpha = 0.35
			motion_mat.set_shader_parameter(&"align", 0.0)
			motion_mat.set_shader_parameter(&"drift", Vector2(0.6, -0.8))
			motion_mat.set_shader_parameter(&"swirl", 0.6)
			motion_mat.set_shader_parameter(&"current_strength", 1.0)
		Kind.SCHOOL:
			shape = 3
			size_px = Vector2(5.0, 7.0)
			colour = look.life_glow.lerp(look.life_secondary, 0.4)
			alpha = 0.8
			motion_mat.set_shader_parameter(&"mode", 1)
		_:
			glow = 1.1 if look.emitters_bloom else 1.0
	motion_mat.set_shader_parameter(&"extents", extents)
	motion_mat.set_shader_parameter(&"size_range", size_px / float(TEX_PX))
	motion_mat.set_shader_parameter(&"tint", colour)
	motion_mat.set_shader_parameter(&"alpha_max", alpha)
	motion_mat.set_shader_parameter(&"speed_scale", look.life_speed)
	draw_mat.set_shader_parameter(&"shape", shape)
	draw_mat.set_shader_parameter(&"glow", glow)
	# depth: a particle at the middle of the size range is "mid"; the vast ones count as far
	var mid := (size_px.x + size_px.y) * 0.5 / float(TEX_PX)
	draw_mat.set_shader_parameter(&"size_mid", mid * (4.0 if kind == Kind.VAST_JELLY else 1.0))
	draw_mat.set_shader_parameter(&"fog_col", look.fog_mid)
	restart()


## Shared current heading (the whole field turns as one), flee target in emitter-local px.
func update_motion(t: float, life_fade: float, current_heading: float, flee_local: Vector2, flee_radius: float) -> void:
	if motion_mat == null:
		return
	motion_mat.set_shader_parameter(&"current_heading", current_heading)
	motion_mat.set_shader_parameter(&"life_fade", life_fade)
	motion_mat.set_shader_parameter(&"flee_pos", flee_local)
	motion_mat.set_shader_parameter(&"flee_radius", flee_radius)
	draw_mat.set_shader_parameter(&"time_s", t)


func update_school(centre: Vector2, heading: float, scatter: float, scatter_pos: Vector2) -> void:
	if motion_mat == null:
		return
	motion_mat.set_shader_parameter(&"school_centre", centre)
	motion_mat.set_shader_parameter(&"school_heading", heading)
	motion_mat.set_shader_parameter(&"scatter", scatter)
	motion_mat.set_shader_parameter(&"scatter_pos", scatter_pos)
