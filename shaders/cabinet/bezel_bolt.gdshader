shader_type canvas_item;
// A zinc bezel bolt head: a round dull-metal head in a dark recess, a slot at a seeded angle, a crescent of
// the key light on its upper edge, dirt packed round it. A ColorRect a little bigger than the head.
#include "res://shaders/cabinet/cabinet_material.gdshaderinc"

uniform float head_r = 2.3;
uniform float slot_angle = 0.4;
uniform vec2 rig_origin = vec2(0.0);
uniform vec2 rect_size = vec2(9.0, 9.0);
uniform vec3 zinc = vec3(0.54, 0.55, 0.56);

void fragment() {
	vec2 p = UV * rect_size - rect_size * 0.5;
	vec2 rp = rig_origin + UV * rect_size;
	float px = max(max(fwidth(p.x), fwidth(p.y)), 1e-4);
	float r = length(p);
	float head = cov(r - head_r, px);
	float pit = cov(r - (head_r + 0.9), px);
	vec3 n = normalize(vec3(p / head_r * 0.7, 0.8));
	vec3 L = cab_key_dir(rp);
	vec3 col = zinc * (0.85 + 0.25 * vnoise(p * 2.0 + rp)) * (cab_amb(rp) + cab_key(rp) * max(dot(n, L), 0.0));
	// slot
	vec2 sl = rot2(p, slot_angle);
	float slot = cov(rbox(sl, vec2(0.0), vec2(head_r * 0.85, 0.32), 0.1), px);
	col = mix(col, vec3(0.02), slot * 0.85);
	// crescent of light on the upper-left rim
	vec2 lxy = normalize(-L.xy + vec2(1e-3));
	float cres = smoothstep(0.35, 1.0, dot(normalize(p + vec2(1e-4)), lxy)) * smoothstep(head_r - 0.7, head_r - 0.1, r) * head;
	col += cab_key(rp) * cres * 0.35;
	// dirt packed round the head
	float dirt = smoothstep(head_r + 0.9, head_r - 0.1, r) * 0.7;
	vec3 pitc = vec3(0.012, 0.011, 0.01) + vec3(0.03) * vnoise(p * 3.0 + 4.0);
	vec3 out_c = mix(pitc, col, head);
	COLOR = vec4(out_c, pit * (0.35 + 0.65 * max(head, dirt)));
}
