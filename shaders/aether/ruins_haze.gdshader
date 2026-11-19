shader_type canvas_item;
render_mode unshaded, blend_add;
// Light in the Ruins' dusty air (additive, unshaded): warm in-scatter round the hall lantern and
// each lit Tree lamp, the lamps' light reaching the hangar mouth, a few motes turning in the
// lantern's light, and the Aether's cool spill through the torn vault. Everything is capped well
// under the hall lantern's core (law 4). Adds light only: it can never write black.

const int MAX_LAMPS = 8;

uniform vec2 size_px = vec2(640.0, 360.0);
uniform vec4 hall = vec4(262.0, 138.0, 1.0, 300.0);   // x, y, output 0–1, radius
uniform vec4 lamps[8];                                // x, y, output 0–1, radius
uniform int lamp_count = 0;
uniform vec4 mouth = vec4(484.0, 116.0, 132.0, 186.0);
uniform float mouth_light = 0.0;
uniform float floor_y = 300.0;
uniform vec2 hole_c = vec2(150.0, 10.0);
uniform vec2 hole_r = vec2(122.0, 70.0);
uniform vec4 warm : source_color;      // in-scatter (GAS)
uniform vec4 warm_hi : source_color;   // in-scatter heart (GAS)
uniform vec4 spill : source_color;     // the Aether's cool spill
uniform vec4 mote : source_color;      // dust (BONE)
uniform float haze = 0.16;
uniform float spill_strength = 0.05;
uniform float time_s = 0.0;

float hash(vec2 p) {
	p = fract(p * vec2(123.34, 456.21));
	p += dot(p, p + 45.32);
	return fract(p.x * p.y);
}

float vnoise(vec2 p) {
	vec2 i = floor(p);
	vec2 f = fract(p);
	vec2 u = f * f * (3.0 - 2.0 * f);
	return mix(mix(hash(i), hash(i + vec2(1.0, 0.0)), u.x), mix(hash(i + vec2(0.0, 1.0)), hash(i + vec2(1.0, 1.0)), u.x), u.y);
}

// soft in-scatter: bright heart, long tail, zero at the radius
float scatter(vec2 p, vec2 c, float r) {
	float d = length(p - c) / max(r, 1.0);
	return pow(max(1.0 - d, 0.0), 2.2) * (0.35 + 0.65 * exp(-d * 9.0));
}

void fragment() {
	vec2 p = UV * size_px;
	float drift = vnoise(p * 0.035 + vec2(time_s * 0.05, -time_s * 0.02));
	float dust = 0.7 + 0.6 * drift;
	vec3 col = vec3(0.0);
	float s = scatter(p, hall.xy, hall.w * 0.75) * hall.z;
	col += mix(warm.rgb, warm_hi.rgb, exp(-length(p - hall.xy) / 18.0)) * s * haze * dust;
	float motes_light = s;
	for (int i = 0; i < MAX_LAMPS; i++) {
		if (i >= lamp_count) {
			break;
		}
		vec4 l = lamps[i];
		float ls = scatter(p, l.xy, l.w * 0.8) * l.z;
		col += mix(warm.rgb, warm_hi.rgb, exp(-length(p - l.xy) / 10.0)) * ls * haze * 0.8 * dust;
		motes_light += ls * 0.6;
	}
	// the way out: the lamps' light gathers in the mouth, low and along the deck
	vec2 mc = vec2(mouth.x + mouth.z * 0.5, floor_y - 10.0);
	float in_mouth = smoothstep(mouth.x - 30.0, mouth.x + 10.0, p.x) * (1.0 - smoothstep(mouth.x + mouth.z - 10.0, mouth.x + mouth.z + 30.0, p.x));
	float low = smoothstep(floor_y - mouth.w * 0.9, floor_y - 6.0, p.y);
	float m = scatter(p, mc, mouth.z * 1.1) * in_mouth * max(low, 0.35);
	col += warm.rgb * m * mouth_light * haze * 1.4 * dust;
	// dust motes: one per 22 px cell, slowly turning, seen only where light is
	vec2 g = (p + vec2(time_s * 1.3, time_s * 2.1)) / 22.0;
	vec2 cell = floor(g);
	vec2 at = vec2(hash(cell), hash(cell + 7.7)) * 0.8 + 0.1;
	at += 0.08 * vec2(sin(time_s * 0.4 + hash(cell + 3.0) * 6.28), cos(time_s * 0.3 + hash(cell + 5.0) * 6.28));
	float md = length((fract(g) - at) * 22.0);
	float mote_a = (1.0 - smoothstep(0.25, 0.9, md)) * step(0.8, hash(cell + 1.3));
	col += mote.rgb * mote_a * min(motes_light * motes_light * 2.5, 0.35);
	// the Aether's cool spill through the torn vault: a broad slanting shaft fading to the floor
	vec2 dir = normalize(vec2(0.28, 1.0));
	vec2 rel = p - hole_c;
	float along = dot(rel, dir);
	float across = abs(rel.x * dir.y - rel.y * dir.x);
	float shaft = smoothstep(hole_r.x * 0.95, hole_r.x * 0.35, across) * smoothstep(0.0, 40.0, along)
		* (1.0 - smoothstep(60.0, floor_y + 20.0 - hole_c.y, along));
	col += spill.rgb * shaft * spill_strength * (0.6 + 0.8 * vnoise(vec2(across * 0.06, along * 0.01 - time_s * 0.03)));
	COLOR = vec4(col, 1.0);
}
