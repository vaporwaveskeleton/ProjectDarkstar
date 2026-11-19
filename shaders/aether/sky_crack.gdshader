shader_type canvas_item;
render_mode unshaded;
// Sky cracks (T4, ART-001 §16): jagged lit fractures in the crystal sphere, radiating from impact
// points like a struck pane. Through the wide part of each crack shows the Aether behind the
// Aether — brighter, wrong-coloured, churning against the current. Fracture edges are thin
// PHOS_5 / BONE_5. Colours arrive from GDScript (Pal); defaults are overwritten at runtime.

#include "res://shaders/aether/aether_common.gdshaderinc"

uniform vec3 edge_col : source_color = vec3(0.66, 0.94, 0.82);
uniform vec3 behind_a : source_color = vec3(0.38, 0.81, 0.66);
uniform vec3 behind_b : source_color = vec3(0.97, 0.96, 0.91);
uniform vec3 floor_col : source_color = vec3(0.039, 0.039, 0.07);
uniform float amount : hint_range(0.0, 1.0) = 0.5;
uniform float time_s = 0.0;
uniform float drain = 0.0;
uniform vec4 impact_a = vec4(660.0, 250.0, 200.0, 1.3);   // local px xy, reach, seed
uniform vec4 impact_b = vec4(1010.0, 300.0, 150.0, 4.7);
uniform vec4 impact_c = vec4(330.0, 330.0, 110.0, 8.2);
uniform float brightness = 0.85;

varying vec2 v_px;

void vertex() {
	v_px = VERTEX;
}

void fragment() {
	vec2 fa = a_fracture(v_px, impact_a.xy, impact_a.z * amount, impact_a.w);
	vec2 fb = a_fracture(v_px, impact_b.xy, impact_b.z * amount, impact_b.w);
	vec2 fc = a_fracture(v_px, impact_c.xy, impact_c.z * amount, impact_c.w);
	float line = max(fa.x, max(fb.x, fc.x));
	float gap = max(fa.y, max(fb.y, fc.y));
	// the Aether behind: same medium, wrong colours, churning the other way
	vec2 q = v_px / 40.0 + vec2(-time_s * 0.06, time_s * 0.025);
	float c = a_fbm(q + 2.0 * vec2(a_fbm(q + time_s * 0.03, 3), a_fbm(q - 5.0, 3)), 4);
	vec3 inner = mix(behind_a, behind_b, smoothstep(0.35, 0.75, c)) * brightness;
	vec3 col = mix(edge_col * brightness, inner, gap);
	float a = max(line * 0.85, gap);
	col = mix(col, vec3(a_luma(col)), drain);
	a *= 1.0 - a_drunk(SCREEN_UV * screen_size);
	col = max(col, floor_col);
	COLOR = vec4(col, a);
}
