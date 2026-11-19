// Shared noise and entity-mask helpers for the Aether shaders (ART-001 §16). Code only, no textures.
// Entity uniforms: xy = screen position in logical px, z = radius px, w = 1 when active.
// The world goes out around each entity: colour and density are drunk inside `drink_reach` radii.

uniform vec2 screen_size = vec2(640.0, 360.0);
uniform vec4 entity_0 = vec4(0.0);
uniform vec4 entity_1 = vec4(0.0);
uniform vec4 entity_2 = vec4(0.0);
uniform vec4 entity_3 = vec4(0.0);
uniform float drink_reach = 1.9;

float a_hash(vec2 p) {
	vec3 p3 = fract(vec3(p.xyx) * 0.1031);
	p3 += dot(p3, p3.yzx + 33.33);
	return fract((p3.x + p3.y) * p3.z);
}

float a_noise(vec2 p) {
	vec2 i = floor(p);
	vec2 f = fract(p);
	vec2 u = f * f * (3.0 - 2.0 * f);
	return mix(mix(a_hash(i), a_hash(i + vec2(1.0, 0.0)), u.x),
		mix(a_hash(i + vec2(0.0, 1.0)), a_hash(i + vec2(1.0, 1.0)), u.x), u.y);
}

float a_fbm(vec2 p, int octaves) {
	float v = 0.0;
	float a = 0.5;
	mat2 rot = mat2(vec2(0.8, 0.6), vec2(-0.6, 0.8));
	for (int i = 0; i < 7; i++) {
		if (i >= octaves) {
			break;
		}
		v += a * a_noise(p);
		p = rot * p * 2.03 + vec2(1.7, 9.2);
		a *= 0.5;
	}
	return v;
}

// 0 outside every entity's reach, 1 at an entity's edge.
float a_drunk(vec2 px) {
	float d = 0.0;
	vec4 es[4] = vec4[4](entity_0, entity_1, entity_2, entity_3);
	for (int i = 0; i < 4; i++) {
		if (es[i].w > 0.5 && es[i].z > 0.5) {
			float dist = length(px - es[i].xy);
			d = max(d, smoothstep(es[i].z * drink_reach, es[i].z, dist));
		}
	}
	return d;
}

float a_luma(vec3 c) {
	return dot(c, vec3(0.299, 0.587, 0.114));
}

// Glass fracture around an impact point `c` (px) of reach `reach` (px): jagged hairline rays and
// a few broken concentric arcs, as a pane cracks. Two or three main rays open wider near the
// impact. Returns x = line coverage (0..1), y = gap coverage (where what lies behind shows through).
vec2 a_fracture(vec2 px, vec2 c, float reach, float seed) {
	vec2 d = px - c;
	float r = length(d);
	if (r > reach * 1.05 || reach < 1.0) {
		return vec2(0.0);
	}
	float a = atan(d.y, d.x);
	float jag = (a_noise(vec2(r / 7.0, seed)) - 0.5) * 0.07 + (a_noise(vec2(r / 31.0, seed + 5.0)) - 0.5) * 0.3;
	float n_rays = 7.0;
	float sector = (a + jag) * n_rays / 6.2831853 + seed;
	float cell = floor(sector);
	float h = a_hash(vec2(cell, seed));
	float ray_mid = cell + 0.5 + (h - 0.5) * 0.7;
	float dist = abs(sector - ray_mid) * 6.2831853 / n_rays * r;
	float len = reach * (0.3 + 0.7 * a_hash(vec2(cell + 3.0, seed)));
	float t = clamp(r / len, 0.0, 1.0);
	float main_ray = step(0.62, a_hash(vec2(cell + 11.0, seed)));
	float w = mix(0.9 + 2.6 * main_ray, 0.35, t);
	float live = step(r, len) * step(0.2, h);
	float line = smoothstep(w, w * 0.25, dist) * live;
	float gap = smoothstep(w * 0.6, w * 0.15, dist) * live * main_ray * (1.0 - t);
	// one broken, wandering ring: short arcs between some rays only
	float rr = reach * (0.3 + 0.18 * a_noise(vec2(a * 2.3, seed + 9.0))) + (a_noise(vec2(a * 17.0, seed)) - 0.5) * 6.0;
	float seg_on = step(0.7, a_hash(vec2(cell + 7.0, seed + 1.0)));
	line = max(line, smoothstep(0.7, 0.15, abs(r - rr)) * seg_on);
	float core = smoothstep(3.0, 0.0, r);
	return vec2(max(line, core), max(gap, core));
}
