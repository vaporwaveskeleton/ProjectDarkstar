extends RefCounted
## Helpers shared by the Aether tests: the look files, Pal lookups, and a tree walk.

const LOOK_DIR := "res://data/aether/"
const BACKDROP := "res://features/aether/aether_backdrop.tscn"
const QUALITY_DIR := "res://data/aether/quality/"


static func look_paths() -> PackedStringArray:
	var out := PackedStringArray()
	for f in DirAccess.get_files_at(LOOK_DIR):
		if f.ends_with(".tres"):
			out.append(LOOK_DIR + f)
	return out


static func is_black(c: Color) -> bool:
	return c.a > 0.0 and c.r <= 0.0 and c.g <= 0.0 and c.b <= 0.0


static func same_rgb(a: Color, b: Color) -> bool:
	return absf(a.r - b.r) < 0.003 and absf(a.g - b.g) < 0.003 and absf(a.b - b.b) < 0.003


## Pal entry name for `c` (rgb), or "" when it is not a palette colour.
static func pal_name(c: Color) -> String:
	for k: Variant in Pal.ALL.keys():
		if same_rgb(Pal.ALL[k] as Color, c):
			return str(k)
	# the AETHER ramp is post-Pretence only and lives outside Pal.ALL (ART-001 §4, palette v2 pending)
	for k: Variant in Pal.AETHER.keys():
		if same_rgb(Pal.AETHER[k] as Color, c):
			return str(k)
	return ""


static func is_ramp(c: Color, ramp: String) -> bool:
	return pal_name(c).begins_with(ramp + "-")


static func walk(n: Node, out: Array[Node]) -> void:
	out.append(n)
	for c in n.get_children():
		walk(c, out)


static func in_entity_group(n: Node) -> bool:
	var p: Node = n
	while p != null:
		if p.is_in_group(EntityPresence.GROUP):
			return true
		p = p.get_parent()
	return false


## Colour-typed uniform values currently held by a ShaderMaterial.
static func colour_uniforms(m: ShaderMaterial) -> Dictionary:
	var out := {}
	if m == null or m.shader == null:
		return out
	for u: Dictionary in m.shader.get_shader_uniform_list():
		var v: Variant = m.get_shader_parameter(StringName(str(u.get("name", ""))))
		if v is Color:
			out[str(u.name)] = v
	return out
