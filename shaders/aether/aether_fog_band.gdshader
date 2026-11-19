shader_type canvas_item;
render_mode unshaded;
// One fog band of the Aether (ART-001 §16): domain-warped fbm advected by a visible flow field,
// coloured from Pal uniforms. Pass 2 value structure: a deep far field (dark), a luminous fog band
// hugging the inside of the sphere shell (mid-high), bright accents left to the seam, the life
// and the lantern. Band 0 (far) is opaque, carries the stars and a faint engraving cross-hatch
// like a 19th-century astronomical plate; nearer bands are translucent, thick at the frame edges
// and capped over the play area (play_fog_ceiling — every quality rung keeps it).
// The lantern pool is analytic (same in place and offscreen): warm light scattered by the fog.
// Around the entity the world loses layers in crisp torn stages and flows in toward it like
// water to a drain; colour goes cold (VOID), never toward black. Drain gives the world a cold
// VOID cast and thins the fog. Colours arrive from GDScript (Pal); defaults are overwritten.
// Colour floor: never below VOID_0 (`floor_col`); the only black is the entity.

#include "res://shaders/aether/aether_common.gdshaderinc"

uniform vec3 col_deep : source_color = vec3(0.07, 0.08, 0.16);
uniform vec3 col_mid : source_color = vec3(0.16, 0.19, 0.34);
uniform vec3 col_high : source_color = vec3(0.34, 0.38, 0.56);
uniform vec3 col_glow : source_color = vec3(0.6, 0.55, 0.8);   // luminous-band highlight
uniform vec3 floor_col : source_color = vec3(0.039, 0.039, 0.07);
uniform vec3 void_lo : source_color = vec3(0.075, 0.078, 0.157);  // cold cast, dark end
uniform vec3 void_hi : source_color = vec3(0.235, 0.27, 0.455);   // cold cast, light end
uniform vec3 star_col : source_color = vec3(0.9, 0.87, 0.82);
uniform vec4 tint : source_color = vec4(0.0);   // far-band incense haze (CHOIR, T4 only)
uniform vec3 lantern_col : source_color = vec3(0.95, 0.78, 0.36);
uniform vec3 lantern_outer : source_color = vec3(0.85, 0.6, 0.18);   // in-scatter at the pool's rim
uniform vec2 lantern_px = vec2(320.0, 202.0);
uniform float lantern_r = 120.0;
uniform float lantern_energy = 1.6;
uniform float scatter = 0.3;           // lantern light scattered by the fog itself
uniform float time_s = 0.0;
uniform float drain : hint_range(0.0, 1.0) = 0.0;
uniform int tier = 1;
uniform int octaves = 5;
uniform int warp_octaves = 3;
uniform int two_sample = 1;
uniform float silver = 1.0;
uniform float is_far = 1.0;            // 1 = opaque far band
uniform float loss_stage = 0.0;        // 0 far, 1 mid, 2 near: which entity loss stage removes it
uniform float fog_scale = 150.0;       // px per noise unit
uniform float drift_speed = 0.02;
uniform vec2 drift_dir = vec2(1.0, 0.25);
uniform float flow_strength = 0.6;
uniform float inflow = 0.9;            // noise units per cycle pulled toward the entity
uniform float alpha_max = 0.55;
uniform float play_fog_ceiling = 0.35;
uniform float hatch_strength = 0.25;
uniform float seed = 0.0;
uniform float lift = 0.0;              // silver lining toward the sphere (0..1)
uniform float stars = 0.0;             // far band star field strength
uniform float deep_k = 0.35;           // brightness of the fog away from the luminous band
uniform float glow_band_px = 70.0;     // half-width of the luminous band inside the shell
uniform float glow_band_inset = 55.0;  // how far inside the shell the band peaks

varying vec2 v_px;

void vertex() {
	v_px = VERTEX;
}

// a slow, structured flow: curl of a large-scale noise, so the currents read as rivers
vec2 flow_at(vec2 p, float t, int oct) {
	float e = 0.15;
	float n0 = a_fbm(p * 0.35 + vec2(seed, t * 0.25), oct);
	float nx = a_fbm(p * 0.35 + vec2(seed + e, t * 0.25), oct);
	float ny = a_fbm(p * 0.35 + vec2(seed, t * 0.25 + e), oct);
	return vec2(ny - n0, -(nx - n0)) / e;
}

vec3 cold(vec3 c) {
	return mix(void_lo, void_hi, clamp(a_luma(c) * 2.4, 0.0, 1.0));
}

void fragment() {
	vec2 spx = SCREEN_UV * screen_size;
	vec4 loss = a_loss(spx);
	vec3 toward = a_toward_entity(spx);
	float t = time_s * drift_speed;
	vec2 p = v_px / fog_scale + vec2(seed * 7.13, seed * 3.71);
	if (tier == 4) {
		t = -t;   // the Litany: the medium runs backwards
	}
	// toward the entity the fog is stretched into radial streaks (water to a drain); `p` stays the
	// plain drifting domain for the strip coordinates (pass 4 guard: taken before the drain stretch)
	vec2 pd = p;
	if (toward.z > 0.0) {
		pd -= toward.xy * dot(pd, toward.xy) * 0.55 * toward.z;
	}
	// play core weight (every band; the law-4 cap) and the translucent bands' strip-field weight.
	// Pass 5 (Q-T94): the strip weight reaches 1 at pw = A_STRIP_FULL, and where it is 1 the free fog
	// (and its silver-lining sample once the lining has faded) is never computed.
	float r_scr = length((SCREEN_UV - 0.5) * vec2(screen_size.x / screen_size.y, 1.0));
	float pw = 1.0 - smoothstep(A_PLAY_CORE, A_PLAY_RING, r_scr);
	float play = min(pw * (1.0 - is_far) / A_STRIP_FULL, 1.0);
	float lining = silver * (1.0 - smoothstep(0.3, 0.5, play));
	vec2 adv = drift_dir * t;
	vec2 pull = toward.xy * toward.z * inflow;
	float n = 0.5;
	float m = 0.5;
	float n_up = 0.5;
	if (play > 0.999) {
		// the core is the strip field outright; the free fog is never seen there
	} else if (two_sample == 1) {
		vec2 f = flow_at(pd, t, max(warp_octaves - 1, 2));   // pass 5 (Q-T94): the curl is large-scale
		// advect along the flow: two samples blended across a cycle hide the reset (no pop)
		float cyc = fract(t * 0.5);
		float cyc2 = fract(cyc + 0.5);
		vec2 q1 = pd + adv + f * flow_strength * cyc - pull * cyc;
		vec2 q2 = pd + adv + f * flow_strength * cyc2 - pull * cyc2;
		float w = abs(cyc * 2.0 - 1.0);
		vec2 warp1 = vec2(a_fbm(q1 + vec2(1.7, 9.2), warp_octaves), a_fbm(q1 + vec2(8.3, 2.8), warp_octaves));
		vec2 warp2 = vec2(a_fbm(q2 + vec2(1.7, 9.2), warp_octaves), a_fbm(q2 + vec2(8.3, 2.8), warp_octaves));
		n = mix(a_fbm(q1 + 1.6 * warp1, octaves), a_fbm(q2 + 1.6 * warp2, octaves), w);
		m = mix(warp1.x, warp2.x, w);
		n_up = lining > 0.0 ? a_fbm(q1 + 1.6 * warp1 + vec2(0.0, -0.12), octaves) : n;
	} else {
		vec2 f = flow_at(pd, t, max(warp_octaves - 1, 2));   // pass 5 (Q-T94): the curl is large-scale
		vec2 q = pd + adv + f * flow_strength * 0.5 - pull * 0.5;
		vec2 warp = vec2(a_fbm(q + vec2(1.7, 9.2), warp_octaves), a_fbm(q + vec2(8.3, 2.8), warp_octaves));
		n = a_fbm(q + 1.6 * warp, octaves);
		m = warp.x;
		n_up = n;
	}
	if (tier == 3) {
		n += 0.08 * sin(time_s * 0.12 + pd.y * 0.8);   // tidal swell
	}
	// pass 4 pareidolia guard (every tier): over the play core the translucent bands ARE a strip
	// field (a_fog_streak: open strands drifting along their own length — the domain only
	// translates, so the strips stay strips), blended back to the free fog across the play ring.
	// The opaque far band keeps its own soft field (low contrast, under the lantern pool).
	// the value the colour is shaded from (pass 5: never the across-strand field over the core)
	float n_shade = n;
	if (play > 0.01 || tier == 5) {
		// strip coordinates only where they are used (pass 5, Q-T94)
		vec2 sw = a_strip_coords(p + drift_dir * t, drift_dir, seed);
		if (play > 0.01) {
			n = mix(n, a_fog_streak(sw, seed, max(octaves - 2, 2)), play);
			n_up = mix(n_up, n, play);   // no silver-lining offset sample over the core
			// pass 5: short ragged streaks (a min with a phase-of-(w.y + h(w.x)) field: still strips)
			float ph = a_dash_phase(sw, seed);
			n = min(n, mix(1.0, a_fog_dash(ph, seed), play));
			// flat shade, varied along the strand only: no cross-strand gradient (that was the satin)
			n_shade = mix(n, a_streak_shade(ph, seed), play);
			m = mix(m, 0.5, play);
		}
		if (tier == 5) {
			// fog peeling into chalk strands: a min with an across-flow stroke keeps the strip property
			// (pass 5: the chalk cuts the density only; the colour never shades across a chalk strand)
			n = min(n, mix(1.0, a_chalk_strand(sw.x, seed), 0.7));
		}
	}
	float dens = smoothstep(0.34, 0.78, n);
	// value structure: luminous just inside the shell, deep beyond it and deep below
	float sd = a_sphere_d(spx);
	float lumb = exp(-pow((sd + glow_band_inset) / glow_band_px, 2.0));
	float beyond = smoothstep(-6.0, 24.0, sd);
	vec3 col = mix(col_deep, col_mid, smoothstep(0.25, 0.65, n_shade));
	col = mix(col, col_high, smoothstep(0.5, 0.85, n_shade) * (0.55 + 0.45 * m));
	col = mix(col, col_glow, smoothstep(0.45, 0.8, n_shade) * lumb * 0.85);
	col += col_high * clamp((n - n_up) * 3.0, 0.0, 1.0) * lift * lining * (0.4 + 0.6 * lumb);
	float bright = mix(deep_k, 1.0, lumb) * mix(1.0, 0.55, beyond);
	col = mix(col_deep, col, bright);
	// engraving: a fine cross-hatch that thickens in the shadows (far band only)
	if (is_far > 0.5 && hatch_strength > 0.0) {
		float shade = 1.0 - smoothstep(0.2, 0.7, n);
		float h1 = step(0.78 - shade * 0.25, fract((spx.x + spx.y) * 0.34));
		float h2 = step(0.86 - shade * 0.3, fract((spx.x - spx.y) * 0.34)) * step(0.4, shade);
		col *= 1.0 - hatch_strength * 0.28 * max(h1, h2) * (1.0 - loss.z);
	}
	col = mix(col, tint.rgb, tint.a * (0.4 + 0.6 * dens));
	// stars: the far field, hidden by fog, gone near the entity and as the world is drunk
	if (stars > 0.0) {
		vec2 g = v_px / 7.0;
		vec2 id = floor(g);
		float h = a_hash(id + seed * 13.0);
		if (h > 0.955) {
			vec2 sp = id + 0.5 + (vec2(a_hash(id * 1.31), a_hash(id * 2.17)) - 0.5) * 0.7;
			float dd = length(g - sp) * 7.0;
			float tw = 0.75 + 0.25 * sin(time_s * 0.5 + h * 60.0);   // 0.08 Hz
			float s = exp(-dd * dd * 1.4) * (0.35 + 0.65 * a_hash(id * 0.77)) * tw;
			s *= (1.0 - dens * 0.75) * (1.0 - loss.z) * (1.0 - drain);
			col += star_col * s * stars;
		}
	}
	// pass 5, law 4: over the play core the fog's own light stays under A_PLAY_FOG_LUMA, so only the
	// lantern's in-scatter (below) can make anything there bright
	col = a_cap_luma(col, A_PLAY_FOG_LUMA, pw);
	// the lantern: warm light pooled into the fog (the last warm thing)
	float ld = length(spx - lantern_px) / max(lantern_r, 1.0);
	float lp = exp(-ld * ld * 4.0);
	// pass 3: in-scatter tinted gold-amber (lantern_outer at the rim of the pool, the lantern's own
	// colour at its heart) and multiplied by the fog's VALUE more than its hue, so the pool reads
	// warm in every tier instead of a yellow-green smear over teal fog
	vec3 lc = mix(lantern_outer, lantern_col, smoothstep(0.15, 0.8, lp)) * lantern_energy;
	vec3 fog_term = mix(col, vec3(a_luma(col)), 0.7) * 0.8;
	col += lc * lp * (fog_term + vec3(scatter) * (0.35 + 0.65 * max(dens, is_far)));
	// the entity: the medium near it goes cold and loses its layers (never darker than VOID)
	col = mix(col, cold(col), loss.w * 0.75);
	if (is_far > 0.5) {
		// the middle step of the subtraction: a FLAT cold VOID (no fog texture, no stars, no glow)
		col = mix(col, mix(void_lo, void_hi, 0.22), loss.z);
	}
	// drain: a cold VOID cast everywhere but the lantern pool
	col = mix(col, cold(col), drain * 0.92 * (1.0 - lp * 0.85));
	col = max(col, floor_col);
	if (is_far > 0.5) {
		COLOR = vec4(col, 1.0);
	} else {
		float edge = mix(play_fog_ceiling, 1.25, smoothstep(0.2, 0.9, r_scr));
		float stage = loss_stage > 1.5 ? loss.x : loss.y;
		float a = dens * alpha_max * edge * min(0.6 + 0.4 * lumb + 0.25 * lp, 1.0);
		a *= (1.0 - stage) * (1.0 - 0.45 * loss.w) * (1.0 - 0.8 * drain);
		COLOR = vec4(col, clamp(a, 0.0, 1.0));
	}
}
