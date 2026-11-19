shader_type canvas_item;
// The soft contact shadow and occlusion where a raised part (the coin door) sits on the bezel. A
// ColorRect larger than the part by `margin` draws behind it; the part's own shape is drawn over the
// middle. The shadow falls away from the screen glow (the cabinet's one key light), with a tighter
// ambient-occlusion ring all round.
#include "res://shaders/cabinet/cabinet_material.gdshaderinc"

uniform vec2 part_size = vec2(56.0, 80.0);
uniform float margin = 8.0;
uniform float radius = 4.5;
uniform vec2 rig_origin = vec2(0.0);       // rig position of the part's top-left
uniform float strength : hint_range(0.0, 1.0) = 0.7;
uniform float blur = 5.0;

void fragment() {
	vec2 size = part_size + vec2(2.0 * margin);
	vec2 q = UV * size - vec2(margin);
	vec2 c = part_size * 0.5;
	vec2 away = -cab_key_dir(rig_origin + c).xy;
	vec2 off = normalize(away + vec2(1e-4)) * blur * 0.35;
	float d_cast = rbox(q, c + off, part_size * 0.5, radius);
	float d_ao = rbox(q, c, part_size * 0.5, radius);
	float cast = 1.0 - smoothstep(-blur * 0.3, blur, d_cast);
	float ao = 1.0 - smoothstep(0.0, blur * 0.45, d_ao);
	float a = clamp(cast * 0.75 + ao * 0.55, 0.0, 1.0) * strength;
	COLOR = vec4(0.0, 0.0, 0.0, a);
}
