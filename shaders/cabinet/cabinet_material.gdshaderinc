// Shared material library for every physical part of the Cabinet (owner direction 2026-11-18: a real,
// grimy 1983 arcade cabinet). Included by coin_door, bezel_print, bezel_glass, bezel_vent, bezel_sticker
// and contact_shadow. Everything is procedural (D-13/D-14: no images), resolution independent and
// seeded. Units are rig units (640 x 360 at 1x). Values arrive from CabinetSurface via CabinetLighting.
//
// Contents: noise (hash21, vnoise, fbm) / shape SDFs / the one cabinet light (screen glow from the hole
// + a cool room fill + a top-bright gradient) / height-field normals live in the caller / dark-room
// environment / wear helpers (scratches, fingerprints, ridges).

uniform float noise_seed = 7.0;
uniform vec4 cab_hole = vec4(192.0, 28.0, 256.0, 304.0);          // x, y, w, h of the screen hole, rig units
uniform vec3 cab_warm_color = vec3(1.0, 0.78, 0.52);
uniform vec3 cab_fill_color = vec3(0.5, 0.58, 0.78);
uniform float cab_warm_gain = 1.2;
uniform float cab_warm_radius = 170.0;
uniform float cab_fill_gain = 0.6;
uniform float cab_top_gain = 1.0;
uniform float cab_bottom_gain = 0.5;
uniform float cab_view_h = 360.0;
uniform vec3 light_dir = vec3(-0.55, -0.65, 0.55);

// ---------------------------------------------------------------- noise
float hash21(vec2 p) {
	p = fract(p * vec2(123.34, 456.21));
	p += dot(p, p + 45.32);
	return fract(p.x * p.y);
}

float vnoise(vec2 p) {
	vec2 i = floor(p);
	vec2 f = fract(p);
	vec2 u = f * f * (3.0 - 2.0 * f);
	vec2 s = vec2(noise_seed * 1.37, noise_seed * 0.71);
	float a = hash21(i + s);
	float b = hash21(i + vec2(1.0, 0.0) + s);
	float c = hash21(i + vec2(0.0, 1.0) + s);
	float d = hash21(i + vec2(1.0, 1.0) + s);
	return mix(mix(a, b, u.x), mix(c, d, u.x), u.y);
}

// Wavelength (in pixels) below which an octave would only alias fades out; a bigger display therefore
// shows finer octaves. `scale` is the base frequency in cycles per unit, `px` the unit's pixel size.
float fbm(vec2 p, float scale, float px) {
	float v = 0.0;
	float a = 0.5;
	float freq = scale;
	vec2 q = p * scale;
	for (int i = 0; i < 6; i++) {
		float fade = smoothstep(1.5, 3.5, 1.0 / (freq * px));
		v += a * vnoise(q) * fade;
		q = q * 2.03 + vec2(17.1, 9.3);
		freq *= 2.03;
		a *= 0.5;
	}
	return v / 0.96875;
}

// ---------------------------------------------------------------- shapes
float rbox(vec2 p, vec2 c, vec2 h, float r) {
	r = min(r, min(h.x, h.y));
	vec2 q = abs(p - c) - h + r;
	return length(max(q, 0.0)) + min(max(q.x, q.y), 0.0) - r;
}

float cov(float d, float px) {
	return clamp(0.5 - d / px, 0.0, 1.0);
}

float rise(float d, float bev) {
	return 1.0 - smoothstep(-bev, 0.0, d);
}

vec2 rot2(vec2 q, float a) {
	return vec2(q.x * cos(a) - q.y * sin(a), q.x * sin(a) + q.y * cos(a));
}

// ---------------------------------------------------------------- the one cabinet light
// The lit screen is the key: parts nearer the hole are warmer and brighter, the key comes from the hole's
// side and from above, a cool dim room fill is everywhere, and the whole cabinet falls into shadow toward
// its bottom.
float cab_falloff(vec2 rp) {
	vec2 hc = cab_hole.xy + cab_hole.zw * 0.5;
	vec2 q = abs(rp - hc) - cab_hole.zw * 0.5;
	float d = length(max(q, 0.0)) + min(max(q.x, q.y), 0.0);
	return exp(-max(d, 0.0) / cab_warm_radius);
}

vec3 cab_key_dir(vec2 rp) {
	vec2 hc = cab_hole.xy + cab_hole.zw * 0.5;
	vec2 to = normalize(hc - rp + vec2(0.0, -70.0) + vec2(1e-3));
	return normalize(vec3(to * length(light_dir.xy), light_dir.z));
}

vec3 cab_amb(vec2 rp) {
	float k = clamp(rp.y / cab_view_h, 0.0, 1.0);
	return cab_fill_color * cab_fill_gain * mix(cab_top_gain, cab_bottom_gain, k);
}

vec3 cab_key(vec2 rp) {
	return cab_warm_color * cab_warm_gain * cab_falloff(rp);
}

// Diffuse light on a surface of normal n at rig position rp (white-light units, multiply the albedo).
vec3 cab_lightc(vec3 n, vec2 rp) {
	return cab_amb(rp) + cab_key(rp) * max(dot(n, cab_key_dir(rp)), 0.0);
}

// ---------------------------------------------------------------- wear helpers
float ridge(float n, float thr) {
	float r = 1.0 - abs(2.0 * n - 1.0);
	float w = fwidth(r) + 1e-4;
	return clamp((r - thr) / w + 0.5, 0.0, 1.0);
}

// One short, slightly curved scratch: anchor q, tangent angle th, half length hl, curvature k.
float arc_one(vec2 p, vec2 q, float th, float hl, float k, float px) {
	vec2 t = vec2(cos(th), sin(th));
	vec2 d = p - q;
	float u = dot(d, t);
	float v = dot(d, vec2(-t.y, t.x)) - 0.5 * k * u * u;
	float w = max(0.065, px * 0.6);
	float vis = min(1.0, 0.065 / w + 0.4);
	return (1.0 - smoothstep(w * 0.4, w, abs(v))) * smoothstep(hl, hl * 0.55, abs(u)) * vis;
}

// Coin and key scratches round an opening: short arcs at mixed angles, anchored within `spread` units of
// the opening and thinning with distance. `lxy` is the light's direction: a groove across it catches it.
float scratches(vec2 p, vec2 c, vec2 open_half, float count, float spread, float px, vec2 lxy) {
	float acc = 0.0;
	for (int i = 0; i < 30; i++) {
		if (float(i) >= count) {
			break;
		}
		float fi = float(i);
		float h1 = hash21(vec2(fi, 1.3) + noise_seed);
		float h2 = hash21(vec2(fi, 2.9) + noise_seed);
		float h3 = hash21(vec2(fi, 4.1) + noise_seed);
		float h4 = hash21(vec2(fi, 6.7) + noise_seed);
		float h5 = hash21(vec2(fi, 8.3) + noise_seed);
		float a = h1 * 6.2831853;
		vec2 q = c + vec2(cos(a), sin(a)) * (open_half + 0.3 + spread * h2 * h2);
		float th = h3 * 3.14159;
		vec2 t = vec2(cos(th), sin(th));
		float lum = 0.2 + 0.8 * pow(abs(t.x * lxy.y - t.y * lxy.x), 2.0);
		acc = max(acc, arc_one(p, q, th, 0.5 + 1.5 * h4 * (1.0 - 0.5 * h2), (h5 - 0.5) * 0.9, px) * lum);
	}
	return acc;
}

// A smeared fingerprint: oval body with ridge rings that fade out when too fine for the display.
float print_blob(vec2 p, vec2 c, float rot, vec2 rad, float px) {
	vec2 q = rot2(p - c, rot) / rad;
	float r = length(q);
	float body = smoothstep(1.0, 0.45, r);
	float rings = 0.5 + 0.5 * sin(length(q * rad) * 17.0 + 2.5 * vnoise(q * 3.0));
	float fade = smoothstep(1.5, 3.5, 1.0 / (2.7 * px));
	return body * mix(0.7, mix(0.45, 1.0, rings), fade);
}

// A dark room: dim ceiling, a dark horizon band, one sharp bright streak, then a dark floor.
vec3 environment(float t, float x, float blur) {
	float horizon = exp(-pow((t - 0.41) / (0.055 + blur * 0.4), 2.0));
	float streak = exp(-pow((t - 0.51) / (0.014 + blur * 0.3), 2.0));
	float floor_k = smoothstep(0.55 - blur * 0.4, 0.6 + blur * 0.4, t);
	vec3 sky = mix(vec3(0.55, 0.58, 0.64), vec3(0.28, 0.29, 0.32), smoothstep(0.0, 0.38, t));
	vec3 ground = mix(vec3(0.06, 0.055, 0.05), vec3(0.2, 0.19, 0.18), smoothstep(0.65, 1.0, t));
	vec3 e = mix(sky, vec3(0.03), horizon * 0.9);
	e += streak * vec3(1.0, 1.0, 0.97);
	e = mix(e, ground, floor_k);
	e += 0.12 * smoothstep(0.3, 0.0, abs(x + 0.4)) * (1.0 - floor_k);
	return e;
}
