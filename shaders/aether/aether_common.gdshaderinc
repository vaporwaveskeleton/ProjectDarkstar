// Shared noise, entity-shape and sphere helpers for the Aether shaders (ART-001 §16). Code only, no textures.
// Entity uniforms: xy = screen position in logical px, z = radius px, w = 1 when active.
// The entity SUBTRACTS (pass 2): around its torn edge the world loses its layers in crisp, torn
// stages (near fog, then mid fog, then stars / life / far detail) and its colour goes cold. It is
// never a darkening gradient toward black: the only black is the entity's own shape.

uniform vec2 screen_size = vec2(640.0, 360.0);
uniform vec4 entity_0 = vec4(0.0);
uniform vec4 entity_1 = vec4(0.0);
uniform vec4 entity_2 = vec4(0.0);
uniform vec4 entity_3 = vec4(0.0);
uniform vec4 entity_seeds = vec4(0.7, 3.1, 5.9, 8.4);
uniform float entity_time = 0.0;
// The hero sphere seam on screen: xy centre (logical px), z radius.
uniform vec3 sphere_screen = vec3(320.0, 1000.0, 900.0);

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

float a_luma(vec3 c) {
	return dot(c, vec3(0.299, 0.587, 0.114));
}

// The entity's outline in its own normalised space (p = offset / radius). < 0 inside.
// Domain-warped noise at up to four scales (torn paper, eaten), one perfectly straight ruled cut
// and one impossible square inner corner: geometry that should not exist in fog.
float a_entity_shape(vec2 p, float seed, float t, int oct) {
	vec2 w = p + 0.44 * vec2(a_noise(p * 1.1 + vec2(seed, t * 0.03)) - 0.5,
		a_noise(p * 1.1 + vec2(seed + 4.1, -t * 0.025)) - 0.5);
	float d = length(w * vec2(1.0, 1.12)) - 1.0;
	d += 0.2 * (a_noise(w * 2.6 + vec2(seed * 3.0, t * 0.02)) - 0.5);
	if (oct > 2) {
		d += 0.08 * (a_noise(w * 7.0 + seed) - 0.5);
	}
	if (oct > 3) {
		d += 0.03 * (a_noise(w * 23.0 - seed) - 0.5);
	}
	// the ruled cut: a knife-straight edge across one side
	float ca = seed * 2.4;
	d = max(d, dot(p, vec2(cos(ca), sin(ca))) - 0.74);
	// the impossible inner corner: a right-angled notch bitten into the rim
	float cb = seed * 1.7 + 2.2;
	vec2 c = vec2(cos(cb), sin(cb)) * 0.86;
	vec2 a1 = vec2(cos(cb + 0.785), sin(cb + 0.785));
	vec2 a2 = vec2(cos(cb - 0.785), sin(cb - 0.785));
	d = max(d, min(dot(p - c, a1), dot(p - c, a2)));
	return d;
}

// Layer loss around every entity. x = near fog gone, y = mid fog / leviathan / rays gone,
// z = stars, life and far detail gone (each a crisp, torn boundary), w = proximity 0..1
// (for the inflow and the cold cast). Cheap outline (2 scales).
vec4 a_loss(vec2 px) {
	vec4 L = vec4(0.0);
	vec4 es[4] = vec4[4](entity_0, entity_1, entity_2, entity_3);
	for (int i = 0; i < 4; i++) {
		vec4 e = es[i];
		if (e.w < 0.5 || e.z < 0.5) {
			continue;
		}
		vec2 p = (px - e.xy) / e.z;
		if (dot(p, p) > 6.0) {
			continue;
		}
		float sd = entity_seeds[i];
		float s = a_entity_shape(p, sd, entity_time, 2);
		float aa = 1.2 / e.z;
		float tear = 0.12 * (a_noise(p * 3.3 + sd * 5.0) - 0.5);
		float near_l = 1.0 - smoothstep(0.85 + tear - aa, 0.85 + tear + aa, s);
		float mid_l = 1.0 - smoothstep(0.5 + tear * 1.4 - aa, 0.5 + tear * 1.4 + aa, s);
		float far_l = 1.0 - smoothstep(0.24 + tear * 0.8 - aa, 0.24 + tear * 0.8 + aa, s);
		float prox = clamp(1.0 - s / 1.3, 0.0, 1.0);
		L = max(L, vec4(near_l, mid_l, far_l, prox));
	}
	return L;
}

// Direction (screen px, normalised) toward the nearest active entity, and its proximity in w.
vec3 a_toward_entity(vec2 px) {
	vec3 best = vec3(0.0);
	float best_d = 1e9;
	vec4 es[4] = vec4[4](entity_0, entity_1, entity_2, entity_3);
	for (int i = 0; i < 4; i++) {
		vec4 e = es[i];
		if (e.w < 0.5 || e.z < 0.5) {
			continue;
		}
		vec2 rel = e.xy - px;
		float d = length(rel) / e.z;
		if (d < best_d) {
			best_d = d;
			best = vec3(rel / max(length(rel), 0.001), clamp(1.0 - (d - 1.0) / 1.6, 0.0, 1.0));
		}
	}
	return best;
}

// Legacy round reach (kept for cheap callers): 0 far away, 1 at an entity's edge.
float a_drunk(vec2 px) {
	return a_loss(px).z;
}

// Signed distance (logical px) from the hero sphere seam; < 0 inside (where we are).
float a_sphere_d(vec2 spx) {
	return length(spx - sphere_screen.xy) - sphere_screen.z;
}

float a_seg(vec2 p, vec2 a, vec2 b) {
	vec2 pa = p - a;
	vec2 ba = b - a;
	float h = clamp(dot(pa, ba) / max(dot(ba, ba), 0.0001), 0.0, 1.0);
	return length(pa - ba * h);
}

// Glass fracture, not lightning: straight segments from an impact `c`, each ray kinked once,
// a few straight chords between neighbouring rays (shards), foreshortened along the sphere
// (`tang` = seam tangent; the normal component is squashed by `fore`). Returns x = distance to
// the nearest fracture line (logical px), y = gap coverage (a sliver opening along two main rays).
vec2 a_glass(vec2 px, vec2 c, float reach, float seed, vec2 tang, float fore) {
	if (reach < 1.0 || length(px - c) > reach * 1.3) {
		return vec2(1e4, 0.0);
	}
	vec2 nrm = vec2(-tang.y, tang.x);
	float line = 1e4;
	float gap = 0.0;
	vec2 prev_a = c;
	vec2 prev_b = c;
	for (int i = 0; i < 6; i++) {
		float h1 = a_hash(vec2(float(i) + 0.5, seed));
		float h2 = a_hash(vec2(seed, float(i) + 3.1));
		float ang = (float(i) + 0.7 * h1) * 1.0471976 + seed;
		vec2 dir = normalize(tang * cos(ang) + nrm * sin(ang) * fore);
		float l1 = reach * (0.3 + 0.45 * h2);
		vec2 k = c + dir * l1;
		float ang2 = ang + (h1 - 0.5) * 0.8;
		vec2 dir2 = normalize(tang * cos(ang2) + nrm * sin(ang2) * fore);
		vec2 e = k + dir2 * reach * (0.2 + 0.45 * h1) * step(0.25, h2);
		float s1 = a_seg(px, c, k);
		line = min(line, min(s1, a_seg(px, k, e)));
		if (h2 > 0.5) {
			float tpos = clamp(dot(px - c, dir) / l1, 0.0, 1.0);
			float w = 3.4 * (1.0 - tpos) * (1.0 - tpos * 0.3);
			gap = max(gap, (1.0 - smoothstep(w * 0.5, w + 0.01, s1)) * step(0.02, w));
		}
		vec2 ca = c + dir * l1 * 0.45;
		vec2 cb = c + dir * l1 * 0.8;
		if (i > 0 && h1 > 0.45) {
			line = min(line, a_seg(px, prev_a, ca));
		}
		if (i > 0 && h2 < 0.3) {
			line = min(line, a_seg(px, prev_b, cb));
		}
		prev_a = ca;
		prev_b = cb;
	}
	return vec2(line, gap);
}

// The Presence (leviathan) body line in its own quad: x local px -> (centre y, thickness).
// Shared by the leviathan and the god-rays it shadows.
vec2 a_lev_profile(float x, float t, vec2 quad, float thick) {
	float len = quad.x * 0.92;
	float u = (x - quad.x * 0.04) / len;
	float uc = clamp(u, 0.0, 1.0);
	float wave = sin(uc * 3.4 - t * 0.12 + 0.6) * 75.0 * (0.3 + uc);
	float th = thick * sqrt(clamp(u / 0.08, 0.0, 1.0)) * pow(max(1.0 - uc, 0.0), 0.9);
	return vec2(quad.y * 0.5 + wave, th * step(0.0, u) * step(u, 1.0));
}
