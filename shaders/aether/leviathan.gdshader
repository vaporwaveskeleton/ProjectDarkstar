shader_type canvas_item;
render_mode unshaded;
// The Presence (ART-001 §16; scale by occlusion): something the size of the sky sliding across it.
// It passes IN FRONT of the sphere line and blots out the stars, at a depth behind the jellies,
// cropped by both frame edges. A long body with segmented spine plates along its back, three long
// ribbed vane-fins and a tapering tail; its edge dissolves into the fog. A thin rim along its upper
// edge where the god-rays catch it; a row of flank lights pulsing in slow sequence (under 1 Hz,
// below the lantern). VOID / AETHER tones — never black. Never a collider.
// Colours arrive from GDScript (Pal); defaults are overwritten at runtime.

#include "res://shaders/aether/aether_common.gdshaderinc"

uniform vec3 body_col : source_color = vec3(0.11, 0.13, 0.25);
uniform vec3 plate_col : source_color = vec3(0.16, 0.19, 0.34);
uniform vec3 rim_col : source_color = vec3(0.34, 0.38, 0.56);
uniform vec3 light_col : source_color = vec3(0.38, 0.81, 0.66);
uniform vec3 floor_col : source_color = vec3(0.039, 0.039, 0.07);
uniform vec2 quad_size = vec2(2600.0, 900.0);
uniform float thickness = 230.0;
uniform float time_s = 0.0;
uniform float presence : hint_range(0.0, 1.0) = 1.0;
uniform float drain = 0.0;
uniform float max_alpha = 0.95;
uniform float rim_strength = 1.0;
uniform int edge_octaves = 3;

varying vec2 v_px;

void vertex() {
	v_px = VERTEX;
}

// one ribbed vane-fin rooted at local x `root` on the edge `edge_y`, raking back toward the tail
float fin(vec2 q, float root, float edge_y, float dir, float len, float h) {
	float along = (q.x - root) / len;
	float out_d = (q.y - edge_y) * dir;          // > 0 away from the body
	along -= out_d * 0.004;                        // rake
	if (along < 0.0 || along > 1.0 || out_d < -6.0) {
		return 0.0;
	}
	float reach = h * pow(sin(3.14159 * along), 1.4) * (1.0 - 0.35 * along);
	float sheet = 1.0 - smoothstep(reach - 10.0, reach + 2.0, out_d);
	float ribs = 0.65 + 0.35 * smoothstep(0.2, 0.0, abs(fract(along * 9.0 + out_d * 0.01) - 0.5));
	return sheet * ribs;
}

void fragment() {
	vec2 spx = SCREEN_UV * screen_size;
	float len = quad_size.x * 0.92;
	float u = (v_px.x - quad_size.x * 0.04) / len;     // 0 head … 1 tail
	float uc = clamp(u, 0.0, 1.0);
	vec2 prof = a_lev_profile(v_px.x, time_s, quad_size, thickness);
	float cy = prof.x;
	float th = prof.y;
	float dy = v_px.y - cy;
	float n = a_fbm(v_px / 70.0 + vec2(time_s * 0.04, 0.0), edge_octaves);
	// spine plates: overlapping scales along the back
	float seg = fract(uc * 95.0);
	float plates = 4.0 * sqrt(abs(sin(3.14159 * seg))) * smoothstep(0.02, 0.1, u) * (1.0 - smoothstep(0.75, 0.9, u));
	float half_top = th * 0.5 + plates;
	float half_bot = th * 0.5;
	float sd = dy < 0.0 ? -dy - half_top : dy - half_bot;   // < 0 inside the body
	sd += (n - 0.5) * 30.0;
	if (u < 0.0) {
		sd = length(vec2(u * len, dy)) + (n - 0.5) * 30.0;
	}
	float body = (1.0 - smoothstep(-24.0, 14.0, sd)) * step(u, 1.0);
	// three long vane-fins, two over the back, one under the belly
	float top_y = cy - half_top + 4.0;
	float bot_y = cy + half_bot - 4.0;
	float vane = max(fin(v_px, quad_size.x * 0.04 + len * 0.06, top_y, -1.0, len * 0.16, thickness * 0.55),
		fin(v_px, quad_size.x * 0.04 + len * 0.15, top_y, -1.0, len * 0.13, thickness * 0.42));
	vane = max(vane, fin(v_px, quad_size.x * 0.04 + len * 0.09, bot_y, 1.0, len * 0.14, thickness * 0.38));
	vane *= smoothstep(0.2, 0.55, n + 0.2) * (1.0 - body);
	float a = max(body * max_alpha, vane * 0.42);
	// colour: segment shading over the body, plates catching a little light
	vec3 col = body_col;
	col = mix(col, plate_col, (0.5 + 0.5 * cos(6.28318 * seg)) * 0.3 * smoothstep(-half_top + 34.0, -half_top + 4.0, dy) * body);
	col = mix(col, plate_col, vane * 0.6);
	// rim: the god-rays catch its upper edge (broken by the same streaks)
	float streak = smoothstep(0.35, 0.8, a_noise(vec2(spx.x * 0.035, time_s * 0.03)));
	float rim = exp(-abs(sd + 4.0) / 5.0) * step(dy, 0.0) * (0.4 + 0.6 * streak) * rim_strength;
	col = mix(col, rim_col, clamp(rim, 0.0, 1.0));
	// the flank lights: a row pulsing in slow sequence (0.4 Hz wave, under the lantern)
	float ly = cy + th * 0.12;
	float idx = floor(uc * 40.0);
	float lx = (fract(uc * 40.0) - 0.5) * len / 40.0;
	float ldist = length(vec2(lx, v_px.y - ly));
	float pulse = 0.35 + 0.65 * pow(0.5 + 0.5 * sin(time_s * 2.513 - idx * 0.55), 2.0);
	float on = step(0.08, u) * step(u, 0.78) * step(0.5, th);
	float lamp = (exp(-ldist / 1.6) + 0.25 * exp(-ldist / 6.0)) * pulse * on;
	col = mix(col, light_col * 1.25, clamp(lamp, 0.0, 1.0));
	a = max(a, clamp(lamp, 0.0, 1.0) * 0.9);
	vec4 loss = a_loss(spx);
	a *= presence * (1.0 - loss.y);
	col = mix(col, vec3(a_luma(col)), drain * 0.5);
	col = max(col, floor_col);
	COLOR = vec4(col, clamp(a, 0.0, 1.0));
}
