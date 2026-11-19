shader_type canvas_item;
// Black T-molding along the bezel's outer edges: a rounded black vinyl strip with a narrow highlight where
// the key light catches its crown, chalky scuffs where it is kicked and rubbed (wear_k: the lower end most).
// `across` is the strip's width axis (0 = x, 1 = y).
#include "res://shaders/cabinet/cabinet_material.gdshaderinc"

uniform vec2 strip_size = vec2(3.2, 360.0);
uniform vec2 rig_origin = vec2(0.0);
uniform int across = 0;
uniform float outward = 1.0;                 // +1 the lit side faces +x/+y, -1 the other
uniform float wear : hint_range(0.0, 1.0) = 0.8;

void fragment() {
	vec2 p = UV * strip_size;
	vec2 rp = rig_origin + p;
	float px = max(max(fwidth(p.x), fwidth(p.y)), 1e-4);
	float u = (across == 0 ? UV.x : UV.y) * 2.0 - 1.0;          // -1 .. 1 across the strip
	vec3 n = normalize(vec3(u * outward * 0.9, 0.0, 0.5));
	if (across == 1) {
		n = normalize(vec3(0.0, u * outward * 0.9, 0.5));
	}
	vec3 L = cab_key_dir(rp);
	float ndl = max(dot(n, L), 0.0);
	vec3 base = vec3(0.016, 0.016, 0.019);
	vec3 col = base * (cab_amb(rp) + cab_key(rp) * ndl);
	float spec = pow(max(dot(n, normalize(L + vec3(0.0, 0.0, 1.0))), 0.0), 14.0);
	col += cab_key(rp) * spec * 0.16;
	// chalky scuffs
	float w = wear_k(rp) * wear;
	float scuff = smoothstep(0.55, 0.85, fbm(vec2(rp.x * 0.4, rp.y * 0.25) + 5.0, 0.3, px)) * (0.15 + 0.85 * w);
	col = mix(col, vec3(0.16, 0.16, 0.17) * (cab_amb(rp) + cab_key(rp) * 0.5), scuff * 0.7);
	COLOR = vec4(col, 1.0);
}
