class_name CabinetLighting
extends RefCounted
## Pushes the one cabinet light and the shared seeds from CabinetSurface into a part's ShaderMaterial
## (the uniforms of shaders/cabinet/cabinet_material.gdshaderinc). Every physical part of the Cabinet
## (coin door, printed field and columns, glass, vents, sticker, trim, marquee, contact shadows) calls
## `apply`, so they all share one screen glow and one room fill. The live part of that glow, the screen's
## own average colour, is the global shader parameter `cab_screen_light` that ScreenLight writes.
## Presentation only (✱).

const GLOBAL := &"cab_screen_light"


## Set the light uniforms of `mat` from `s` and the screen hole from CabinetBezel.hole().
static func apply(mat: ShaderMaterial, s: CabinetSurface) -> void:
	var h := CabinetBezel.hole()
	mat.set_shader_parameter(&"cab_hole", Vector4(h.position.x, h.position.y, h.size.x, h.size.y))
	mat.set_shader_parameter(&"cab_warm_color", Vector3(s.warm_color.r, s.warm_color.g, s.warm_color.b))
	mat.set_shader_parameter(&"cab_fill_color", Vector3(s.fill_color.r, s.fill_color.g, s.fill_color.b))
	mat.set_shader_parameter(&"cab_warm_gain", s.warm_gain)
	mat.set_shader_parameter(&"cab_warm_radius", s.warm_radius)
	mat.set_shader_parameter(&"cab_fill_gain", s.fill_gain)
	mat.set_shader_parameter(&"cab_top_gain", s.top_gain)
	mat.set_shader_parameter(&"cab_bottom_gain", s.bottom_gain)
	mat.set_shader_parameter(&"cab_view_h", float(ScreenFit.REF.y))
	mat.set_shader_parameter(&"cab_spill_gain", s.spill_gain)
	mat.set_shader_parameter(&"cab_spill_radius", s.spill_radius)
	mat.set_shader_parameter(&"noise_seed", s.noise_seed)
	mat.set_shader_parameter(&"light_dir", s.light_direction)


## The live screen light (rgb colour, a intensity) every cabinet shader reads.
static func set_screen_light(c: Color) -> void:
	RenderingServer.global_shader_parameter_set(GLOBAL, c)


## A material for ink drawn with canvas draw calls (columns, field, sticker text): screened tones, fade,
## mottle, causal wear and flakes, lit by the cabinet. `origin` is the item's top-left in rig units.
static func print_material(s: CabinetSurface, origin: Vector2, mottled: bool) -> ShaderMaterial:
	var m := ShaderMaterial.new()
	m.shader = load("res://shaders/cabinet/bezel_print.gdshader")
	apply(m, s)
	m.set_shader_parameter(&"origin", origin)
	m.set_shader_parameter(&"fade", s.print_fade)
	m.set_shader_parameter(&"mottle", s.print_mottle * (1.0 if mottled else 0.35))
	m.set_shader_parameter(&"halftone", s.print_halftone)
	m.set_shader_parameter(&"halftone_cell", s.print_halftone_cell)
	m.set_shader_parameter(&"dot_gain", s.print_dot_gain)
	m.set_shader_parameter(&"scuff", s.print_scuff)
	m.set_shader_parameter(&"flake", s.print_flake)
	m.set_shader_parameter(&"backer_color", Vector3(s.backer_color.r, s.backer_color.g, s.backer_color.b))
	return m
