shader_type canvas_item;
// One fog band of the Aether (ART-001 §16): domain-warped fbm advected by a visible flow field,
// coloured from three Pal uniforms. Band 0 (far) is opaque and carries a faint engraving
// cross-hatch like a 19th-century astronomical plate; nearer bands are translucent, thick at the
// frame edges and thin over the play area (play_fog_ceiling). Lit by the lantern (light_mask).
// Colours arrive from GDScript (Pal); the defaults below are overwritten at runtime.
// Colour floor: never below VOID_0 (`floor_col`); the only black is the entity.

#include "res://shaders/aether/aether_common.gdshaderinc"

uniform vec3 col_deep : source_color = vec3(0.07, 0.08, 0.16);
uniform vec3 col_mid : source_color = vec3(0.16, 0.19, 0.34);
uniform vec3 col_high : source_color = vec3(0.34, 0.38, 0.56);
uniform vec3 floor_col : source_color = vec3(0.039, 0.039, 0.07);
uniform vec4 tint : source_color = vec4(0.0);   // far-band incense haze (CHOIR, T4 only)
uniform float time_s = 0.0;
uniform float drain : hint_range(0.0, 1.0) = 0.0;
uniform int tier = 1;
uniform int octaves = 5;
uniform float is_far = 1.0;            // 1 = opaque far band
uniform float fog_scale = 150.0;       // px per noise unit
uniform float drift_speed = 0.02;
uniform vec2 drift_dir = vec2(1.0, 0.25);
uniform float flow_strength = 0.6;
uniform float alpha_max = 0.55;
uniform float play_fog_ceiling = 0.35;
uniform float hatch_strength = 0.25;
uniform float seed = 0.0;
uniform float lift = 0.0;              // brightness of the silver lining toward the sphere (0..1)
uniform float scatter = 0.22;          // lantern light scattered by the fog itself, not only reflected

varying vec2 v_px;

void vertex() {
	v_px = VERTEX;
}

// The lantern pools warm light into cool fog: reflected (fog colour x light) plus in-scattered
// light proportional to the fog present, so the pool reads warm even in blue fog.
void light() {
	vec3 lc = LIGHT_COLOR.rgb * LIGHT_COLOR.a * LIGHT_ENERGY;
	LIGHT = vec4(lc * (COLOR.rgb * 0.7 + vec3(scatter) * COLOR.a), 1.0);
}

// a slow, structured flow: curl of a large-scale noise, so the currents read as rivers
vec2 flow_at(vec2 p, float t) {
	float e = 0.15;
	float n0 = a_fbm(p * 0.35 + vec2(seed, t * 0.25), 3);
	float nx = a_fbm(p * 0.35 + vec2(seed + e, t * 0.25), 3);
	float ny = a_fbm(p * 0.35 + vec2(seed, t * 0.25 + e), 3);
	return vec2(ny - n0, -(nx - n0)) / e;
}

void fragment() {
	float t = time_s * drift_speed;
	vec2 p = v_px / fog_scale + vec2(seed * 7.13, seed * 3.71);
	if (tier == 4) {
		t = -t;   // the Litany: the medium runs backwards
	}
	vec2 adv = drift_dir * t;
	vec2 f = flow_at(p, t);
	// advect along the flow: two samples blended across a cycle hide the reset (no pop)
	float cyc = fract(t * 0.5);
	vec2 q1 = p + adv + f * flow_strength * cyc;
	vec2 q2 = p + adv + f * flow_strength * fract(cyc + 0.5);
	float w = abs(cyc * 2.0 - 1.0);
	vec2 warp1 = vec2(a_fbm(q1 + vec2(1.7, 9.2), 3), a_fbm(q1 + vec2(8.3, 2.8), 3));
	vec2 warp2 = vec2(a_fbm(q2 + vec2(1.7, 9.2), 3), a_fbm(q2 + vec2(8.3, 2.8), 3));
	float n1 = a_fbm(q1 + 1.6 * warp1, octaves);
	float n2 = a_fbm(q2 + 1.6 * warp2, octaves);
	float n = mix(n1, n2, w);
	float m = mix(warp1.x, warp2.x, w);
	if (tier == 3) {
		n += 0.08 * sin(time_s * 0.12 + p.y * 0.8);   // tidal swell
	}
	if (tier == 5) {
		// fog peeling into chalk-stroke bands
		float stroke = abs(fract(n * 5.0 + p.y * 0.15) - 0.5) * 2.0;
		n = mix(n, n * smoothstep(0.35, 0.8, stroke), 0.75);
	}
	float dens = smoothstep(0.32, 0.78, n);
	vec3 col = mix(col_deep, col_mid, smoothstep(0.25, 0.65, n));
	col = mix(col, col_high, smoothstep(0.55, 0.85, n) * (0.55 + 0.45 * m));
	// silver lining: the side of each billow facing the sphere above catches light
	float up = a_fbm(q1 + 1.6 * warp1 + vec2(0.0, -0.12), octaves);
	col += col_high * clamp((n - up) * 3.0, 0.0, 1.0) * lift;
	vec2 spx = SCREEN_UV * screen_size;
	// engraving: a fine cross-hatch that thickens in the shadows (far band only)
	if (is_far > 0.5 && hatch_strength > 0.0) {
		float shade = 1.0 - smoothstep(0.2, 0.7, n);
		float h1 = step(0.82 - shade * 0.25, fract((spx.x + spx.y) * 0.34));
		float h2 = step(0.9 - shade * 0.3, fract((spx.x - spx.y) * 0.34)) * step(0.45, shade);
		col *= 1.0 - hatch_strength * 0.22 * max(h1, h2);
	}
	col = mix(col, tint.rgb, tint.a * (0.4 + 0.6 * dens));
	// the entity drinks colour and density around itself
	float drunk = a_drunk(spx);
	float drink = clamp(drain * 0.85 + drunk, 0.0, 1.0);
	col = mix(col, vec3(a_luma(col)), drink);
	col = mix(col, floor_col, drink * 0.7);
	col = max(col, floor_col);
	if (is_far > 0.5) {
		COLOR = vec4(col, 1.0);
	} else {
		float r = length((SCREEN_UV - 0.5) * vec2(screen_size.x / screen_size.y, 1.0));
		float edge = mix(play_fog_ceiling, 1.0, smoothstep(0.18, 0.85, r));
		float a = dens * alpha_max * edge * (1.0 - 0.75 * drink);
		COLOR = vec4(col, a);
	}
}
