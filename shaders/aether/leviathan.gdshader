shader_type canvas_item;
render_mode unshaded;
// A far leviathan (ART-001 §16): an SDF of a long segmented body with ribbed fin-vanes and a row of
// faint phosphor lights along its flank, edges dissolving into the fog. VOID tones mixed into the
// fog — never black. Far larger than the frame; it is only ever seen cropped. Never a collider.
// Colours arrive from GDScript (Pal); defaults are overwritten at runtime.

#include "res://shaders/aether/aether_common.gdshaderinc"

uniform vec3 body_col : source_color = vec3(0.11, 0.13, 0.25);
uniform vec3 rim_col : source_color = vec3(0.16, 0.19, 0.34);
uniform vec3 light_col : source_color = vec3(0.2, 0.66, 0.56);
uniform vec3 floor_col : source_color = vec3(0.039, 0.039, 0.07);
uniform vec2 quad_size = vec2(2600.0, 900.0);
uniform float thickness = 280.0;
uniform float time_s = 0.0;
uniform float presence : hint_range(0.0, 1.0) = 1.0;
uniform float drain = 0.0;
uniform float max_alpha = 0.72;

varying vec2 v_px;

void vertex() {
	v_px = VERTEX;
}

void fragment() {
	float len = quad_size.x * 0.92;
	float x0 = quad_size.x * 0.04;
	float u = (v_px.x - x0) / len;            // 0 head … 1 tail
	float uc = clamp(u, 0.0, 1.0);
	float wave = sin(uc * 9.0 - time_s * 0.35) * 26.0 * uc;
	float cy = quad_size.y * 0.5 + wave;
	// thickness: a rounded nose (parabolic), a long taper to the tail, slight segment pinches
	float th = thickness * sqrt(clamp(u / 0.1, 0.0, 1.0)) * pow(max(1.0 - uc, 0.0), 0.7);
	float seg = fract(uc * 22.0);
	float plate = 1.0 - smoothstep(0.0, 0.12, seg) * smoothstep(1.0, 0.88, seg);   // 1 at the joints
	th *= 1.0 - 0.06 * plate;
	float dy = v_px.y - cy;
	float n = a_fbm(v_px / 60.0 + vec2(time_s * 0.05, 0.0), 4);
	float edge_noise = (n - 0.5) * 34.0;
	float sd = abs(dy) - th * 0.5 + edge_noise;              // < 0 inside the body
	if (u < 0.0) {
		sd = length(vec2(u * len, dy)) + edge_noise;          // in front of the nose
	}
	float body = smoothstep(18.0, -22.0, sd) * step(u, 1.0);
	// fin-vanes: long ribbed sheets raking back from the spine, top and bottom
	float vane = 0.0;
	float k = fract(uc * 7.0 + 0.3);
	float out_d = abs(dy) - th * 0.5;
	if (out_d > 0.0 && u > 0.08 && u < 0.85) {
		float rake = k - out_d * 0.0016;
		float sheet = smoothstep(0.0, 0.02, rake) * smoothstep(0.16, 0.04, rake);
		float reach = smoothstep(th * 1.3, 0.0, out_d);
		float ribs = 0.55 + 0.45 * sin(out_d * 0.22);
		vane = sheet * reach * ribs;
	}
	float dissolve = smoothstep(0.25, 0.6, n + 0.25 * (1.0 - body));
	float a = max(body, vane * dissolve) * max_alpha * presence;
	// lit from the sphere above: a cold rim along the upper edge of the body and the vanes
	float top = smoothstep(24.0, -24.0, dy);
	float rim = smoothstep(-14.0, 0.0, sd) * top * body;
	vec3 col = mix(body_col, rim_col, clamp(rim * 1.2 + vane * 0.7, 0.0, 1.0));
	// segment shading: darker bands where the plates overlap
	col *= 1.0 - 0.28 * plate * body;
	// a row of faint lights along the flank, breathing slowly (well under 3 Hz)
	float ly = cy - th * 0.08;
	float lx = fract(uc * 46.0);
	float ldist = length(vec2((lx - 0.5) * len / 46.0, v_px.y - ly));
	float pulse = 0.55 + 0.45 * sin(time_s * 0.9 + floor(uc * 46.0) * 0.7);
	float lamp = exp(-ldist / 2.4) * pulse * step(0.1, u) * step(u, 0.8) * presence;
	col = mix(col, light_col, clamp(lamp, 0.0, 1.0) * 0.8);
	a = max(a, clamp(lamp, 0.0, 1.0) * 0.7);
	float drunk = a_drunk(SCREEN_UV * screen_size);
	col = mix(col, floor_col, clamp(drain + drunk, 0.0, 1.0) * 0.6);
	col = max(col, floor_col);
	COLOR = vec4(col, a * (1.0 - drunk));
}
