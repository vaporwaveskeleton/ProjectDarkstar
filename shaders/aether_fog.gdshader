shader_type canvas_item;
// The Aether (ART-001 §16): space as the Victorians imagined it — a luminous medium of coloured fog,
// currents and drifting motes, with the curve of a crystal sphere catching the light.
// `amount` 0 → 1 lets the aether rise into the field; `drain` 0 → 1 is the entity drinking it:
// colour and density fall away to black (the only true black is the entity, §16.1).
// Generated entirely in code (D-13); no textures. Sampled on the 640×360 grid.

uniform float amount : hint_range(0.0, 1.0) = 0.0;
uniform float drain : hint_range(0.0, 1.0) = 0.0;
uniform float time_s = 0.0;
uniform vec2 drift = vec2(0.012, 0.004);
uniform float sphere_radius = 1.35;           // the crystal sphere's curve, in screen heights
uniform vec2 sphere_centre = vec2(0.5, 1.9);
// aether colours: nocturne violet, rose, sea-glass, tarnished gold (derived per ART-001 §15–§16)
uniform vec3 col_deep : source_color = vec3(0.10, 0.07, 0.22);
uniform vec3 col_violet : source_color = vec3(0.36, 0.22, 0.52);
uniform vec3 col_rose : source_color = vec3(0.70, 0.38, 0.50);
uniform vec3 col_sea : source_color = vec3(0.20, 0.55, 0.55);
uniform vec3 col_gold : source_color = vec3(0.85, 0.66, 0.34);

float hash(vec2 p) {
	p = fract(p * vec2(123.34, 456.21));
	p += dot(p, p + 45.32);
	return fract(p.x * p.y);
}

float vnoise(vec2 p) {
	vec2 i = floor(p);
	vec2 f = fract(p);
	vec2 u = f * f * (3.0 - 2.0 * f);
	return mix(mix(hash(i), hash(i + vec2(1.0, 0.0)), u.x),
		mix(hash(i + vec2(0.0, 1.0)), hash(i + vec2(1.0, 1.0)), u.x), u.y);
}

float fbm(vec2 p) {
	float v = 0.0;
	float a = 0.5;
	for (int i = 0; i < 5; i++) {
		v += a * vnoise(p);
		p = p * 2.03 + vec2(1.7, 9.2);
		a *= 0.5;
	}
	return v;
}

void fragment() {
	// snap to the 640×360 logical pixel grid so the aether stays pixel art
	vec2 px = floor(UV * vec2(640.0, 360.0)) / vec2(640.0, 360.0);
	vec2 p = px * vec2(1.7778, 1.0) * 3.0;
	float t = time_s;
	// two fog layers drifting at different speeds: currents in the medium
	vec2 q = vec2(fbm(p + drift * t * 40.0), fbm(p + vec2(5.2, 1.3) - drift * t * 25.0));
	float f = fbm(p + 1.8 * q + vec2(0.0, t * 0.03));
	float g = fbm(p * 0.5 + q.yx * 1.2 - t * 0.02);
	vec3 col = mix(col_deep, col_violet, smoothstep(0.25, 0.75, f));
	col = mix(col, col_rose, smoothstep(0.55, 0.9, g) * 0.6);
	col = mix(col, col_sea, smoothstep(0.6, 0.95, q.x) * 0.55);
	// the crystal sphere: a thin bright seam of glass curving across the far field
	float d = abs(length((px - sphere_centre) * vec2(1.7778, 1.0)) - sphere_radius);
	float seam = smoothstep(0.012, 0.0, d) * 0.6 + smoothstep(0.08, 0.0, d) * 0.12;
	col += col_gold * seam;
	// motes: drifting aether-life, a sparse twinkle
	vec2 cell = floor(px * vec2(160.0, 90.0) + vec2(t * 2.0, t * 0.7));
	float m = step(0.996, hash(cell)) * (0.5 + 0.5 * sin(t * 3.0 + hash(cell + 3.1) * 20.0));
	col += mix(col_sea, col_gold, hash(cell + 7.7)) * m;
	// density: thick at the edges, thinner where play happens (ART-001 §16.3)
	vec2 e = px - 0.5;
	float edge = clamp(dot(e, e) * 2.4 + 0.35, 0.0, 1.0);
	float density = amount * (0.55 + 0.45 * f) * edge;
	// the entity drinks it: colour drains toward black, density thins
	vec3 drained = mix(col, vec3(dot(col, vec3(0.3, 0.55, 0.15))) * 0.25, drain);
	COLOR = vec4(drained, density * (1.0 - drain * 0.85));
}
