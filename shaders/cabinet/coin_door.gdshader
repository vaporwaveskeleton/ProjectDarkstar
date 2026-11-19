shader_type canvas_item;
// An early-1980s US arcade coin door, drawn procedurally (D-13/D-14: no images). Resolution independent:
// every shape is a signed distance field in plate units (the plate is plate_size reference units,
// 56 x 80), edges are antialiased with fwidth, detail fades out below the pixel size and appears
// finer on a bigger display. A height field built from the SDFs gives the normal (finite
// differences), one key light and a fake chrome environment do the shading, seeded procedural noise
// does the wear. Materials and the light come from CabinetSurface (CoinDoorFace pushes them).

uniform vec2 plate_size = vec2(56.0, 80.0);
uniform float glow : hint_range(0.0, 1.0) = 0.0;
uniform float lamp_idle = 0.22;
uniform vec4 paint_color = vec4(0.055, 0.055, 0.063, 1.0);
uniform vec4 chrome_color = vec4(0.79, 0.80, 0.83, 1.0);
uniform vec4 bare_steel_color = vec4(0.43, 0.42, 0.39, 1.0);
uniform vec4 brass_color = vec4(0.71, 0.56, 0.27, 1.0);
uniform vec4 lens_color = vec4(0.88, 0.23, 0.07, 1.0);
uniform vec4 rust_color = vec4(0.54, 0.27, 0.12, 1.0);
uniform float wear : hint_range(0.0, 1.0) = 0.45;
uniform float grime : hint_range(0.0, 1.0) = 0.55;
uniform float smudge : hint_range(0.0, 1.0) = 0.6;
uniform float noise_seed = 7.0;
uniform vec3 light_dir = vec3(-0.55, -0.65, 0.55);
uniform vec2 slot_c = vec2(28.0, 20.0);
uniform vec2 slot_half = vec2(1.6, 9.0);
uniform vec2 button_c = vec2(28.0, 40.0);
uniform vec2 button_half = vec2(7.0, 4.0);
uniform vec2 label_c = vec2(28.0, 52.0);
uniform vec2 label_half = vec2(23.8, 5.5);
uniform vec4 label_color = vec4(0.82, 0.78, 0.64, 1.0);

const vec2 DOOR_C = vec2(28.0, 40.0);
const vec2 DOOR_H = vec2(27.6, 39.6);
const vec2 ENT_C = vec2(28.0, 20.0);
const vec2 ENT_H = vec2(8.7, 12.2);
const vec2 RET_C = vec2(34.5, 67.0);
const vec2 RET_H = vec2(13.0, 5.0);
const vec2 LOCK_C = vec2(11.0, 67.0);
const float RELIEF = 1.7;
const vec3 CHIPS[8] = vec3[8](vec3(12.0, 1.6, 1.4), vec3(24.0, 1.3, 0.9), vec3(38.0, 1.7, 1.6), vec3(47.0, 1.5, 1.0), vec3(1.6, 16.0, 1.3), vec3(1.7, 33.0, 1.7), vec3(1.4, 52.0, 1.0), vec3(1.9, 66.0, 1.2));

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

// Wavelength (in pixels) below which an octave would only alias fades out; a bigger display
// therefore shows finer octaves. `scale` is the base frequency in cycles per plate unit.
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

vec2 screw_c(vec2 p) {
	return vec2(p.x < 28.0 ? 6.0 : 50.0, p.y < 40.0 ? 6.0 : 74.0);
}

float cross_d(vec2 p, vec2 c) {
	float a = c.x * 1.7 + c.y * 0.9;
	vec2 l = p - c;
	l = vec2(l.x * cos(a) - l.y * sin(a), l.x * sin(a) + l.y * cos(a));
	float d1 = rbox(l, vec2(0.0), vec2(1.45, 0.3), 0.1);
	float d2 = rbox(l, vec2(0.0), vec2(0.3, 1.45), 0.1);
	return min(d1, d2);
}

float keyway_d(vec2 p) {
	return min(rbox(p, LOCK_C, vec2(0.5, 2.1), 0.4), length(p - LOCK_C) - 0.95);
}

float door_d(vec2 p) {
	return rbox(p, DOOR_C, DOOR_H, 4.5);
}

float height(vec2 p) {
	float dd = door_d(p);
	float base = 0.45 + 0.55 * smoothstep(-3.2, -2.0, dd);
	float h = base * rise(dd, 1.4);
	// coin entry: raised chrome bezel, funnel and slot
	h += 0.9 * rise(rbox(p, ENT_C, ENT_H, 3.4), 1.1);
	float dsl = rbox(p, slot_c, slot_half, 1.5);
	h -= 0.55 * (1.0 - smoothstep(0.0, 2.4, dsl));
	h -= 1.8 * rise(dsl, 0.35);
	// lit price button: dark housing ring, domed lens
	float dbn = rbox(p, button_c, button_half, 2.2);
	h -= 0.5 * rise(dbn - 0.6, 0.3);
	h += 1.0 * rise(dbn, 2.0);
	// printed price label: a thin paper strip on the panel
	h += 0.3 * rise(rbox(p, label_c, label_half, 0.8), 0.3);
	// coin return: chrome surround, recessed flap
	h += 0.55 * rise(rbox(p, RET_C, RET_H, 2.5), 0.9);
	h -= 0.4 * rise(rbox(p, RET_C + vec2(0.0, 0.4), vec2(11.0, 2.8), 1.6), 0.35);
	// cylinder lock
	float dl = length(p - LOCK_C);
	h += 0.7 * rise(dl - 5.8, 0.9);
	h -= 0.2 * rise(dl - 4.0, 0.3);
	h -= 0.9 * rise(keyway_d(p), 0.3);
	// screws
	vec2 sc = screw_c(p);
	float ds = length(p - sc) - 2.2;
	h += 0.55 * rise(ds, 0.9);
	h -= 0.5 * rise(cross_d(p, sc), 0.2) * (1.0 - step(0.0, ds));
	return h;
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
// the opening and thinning with distance. A groove catches the key light when it runs across the light
// (`lxy`, the light's direction on the plate), so each arc gets its own brightness.
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

float print_blob(vec2 p, vec2 c, float rot, vec2 rad, float px) {
	vec2 q = p - c;
	q = vec2(q.x * cos(rot) - q.y * sin(rot), q.x * sin(rot) + q.y * cos(rot)) / rad;
	float r = length(q);
	float body = smoothstep(1.0, 0.45, r);
	float rings = 0.5 + 0.5 * sin(length(q * rad) * 17.0 + 2.5 * vnoise(q * 3.0));
	float fade = smoothstep(1.5, 3.5, 1.0 / (2.7 * px));
	return body * mix(0.7, mix(0.45, 1.0, rings), fade);
}

vec3 environment(float t, float x, float blur) {
	// a dark room: dim ceiling, a dark horizon band, one sharp bright streak, then a dark floor
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

void fragment() {
	vec2 p = UV * plate_size;
	float px = max(max(fwidth(p.x), fwidth(p.y)), 1e-4);
	float dd = door_d(p);
	float cover = cov(dd, px);
	if (cover <= 0.0) {
		COLOR = vec4(0.0);
	} else {
		// ---- geometry masks
		float de = rbox(p, ENT_C, ENT_H, 3.4);
		float dsl = rbox(p, slot_c, slot_half, 1.5);
		float dbn = rbox(p, button_c, button_half, 2.2);
		float dret = rbox(p, RET_C, RET_H, 2.5);
		float dfl = rbox(p, RET_C + vec2(0.0, 0.4), vec2(11.0, 2.8), 1.6);
		float dl = length(p - LOCK_C);
		vec2 sc = screw_c(p);
		float dsc = length(p - sc) - 2.2;
		float dcr = cross_d(p, sc);
		float dky = keyway_d(p);

		float m_ent = cov(de, px);
		float m_ret = cov(dret, px);
		float m_flap = cov(dfl, px);
		float m_lockc = cov(dl - 5.8, px);
		float m_lockf = cov(dl - 4.0, px);
		float m_key = cov(dky, px);
		float m_screw = cov(dsc, px);
		float m_cross = cov(dcr, px) * m_screw;
		float m_slot = cov(dsl, px);
		float dlab = rbox(p, label_c, label_half, 0.8);
		float m_lab = cov(dlab, px);
		float m_lens = cov(dbn, px);
		float m_ring = cov(dbn - 0.6, px) * (1.0 - m_lens);
		float m_gap = cov(abs(dfl) - 0.22, px);

		// ---- normal from the height field
		float e = max(px * 0.8, 0.07);
		float hx = height(p + vec2(e, 0.0)) - height(p - vec2(e, 0.0));
		float hy = height(p + vec2(0.0, e)) - height(p - vec2(0.0, e));
		float h0 = height(p);
		float cr = 1.5;
		float avg = 0.25 * (height(p + vec2(cr, 0.0)) + height(p - vec2(cr, 0.0)) + height(p + vec2(0.0, cr)) + height(p - vec2(0.0, cr)));
		float cav = clamp((avg - h0) * 1.4, 0.0, 1.0);
		vec3 n = normalize(vec3(-hx / (2.0 * e) * RELIEF, -hy / (2.0 * e) * RELIEF, 1.0));

		// ---- base material: painted steel
		float nz1 = fbm(p, 1.3, px);
		float nz2 = fbm(p + 40.0, 3.1, px);
		vec3 col = paint_color.rgb;
		float metal = 0.0;
		float rough = 0.46;
		float spec_gain = 0.55;
		// paint orange-peel grain in the normal
		float grain_fade = smoothstep(1.5, 3.5, 1.0 / (3.0 * px));
		vec2 gr = vec2(vnoise(p * 3.0 + 3.1), vnoise(p * 3.0 + 11.7)) - 0.5;
		n.xy += gr * 0.14 * grain_fade;

		// chrome / metal parts
		float m_chrome = max(max(m_ent, m_ret), max(m_lockc, m_screw * 0.8));
		col = mix(col, chrome_color.rgb, m_chrome);
		metal = max(metal, m_chrome);
		rough = mix(rough, 0.2, m_chrome);
		col = mix(col, chrome_color.rgb * 0.82, m_flap);
		metal = max(metal, m_flap);
		rough = mix(rough, 0.3, m_flap);
		col = mix(col, brass_color.rgb, m_lockf);
		metal = max(metal, m_lockf);
		rough = mix(rough, 0.3, m_lockf);
		col = mix(col, chrome_color.rgb * 0.55, m_cross);
		// black housing ring round the lens, deep gaps, the slot and keyway
		col = mix(col, vec3(0.025), m_ring);
		metal = mix(metal, 0.0, m_ring);
		rough = mix(rough, 0.5, m_ring);
		float dark = max(max(m_slot, m_key), m_gap * m_ret);
		col = mix(col, vec3(0.012), dark);
		metal = mix(metal, 0.0, dark);
		rough = mix(rough, 0.9, dark);

		// ---- the printed price label: aged paper, yellowed, scuffed at one corner, riveted
		vec3 paper = label_color.rgb * (0.84 + 0.28 * nz1);
		paper *= mix(0.72, 1.0, smoothstep(0.0, 1.8, -dlab));
		paper = mix(paper, paper * vec3(0.86, 0.72, 0.46), 0.4 * smoothstep(0.4, 0.8, nz2));
		float scuff_d = length((p - (label_c + label_half)) * vec2(0.85, 1.0)) + (fbm(p, 2.0, px) - 0.5) * 3.2;
		float scuff = smoothstep(5.5, 2.6, scuff_d);
		paper = mix(paper, vec3(0.36, 0.33, 0.27) * (0.8 + 0.4 * nz2), scuff * 0.85);
		float lab = m_lab * (1.0 - dark);
		col = mix(col, paper, lab);
		metal = mix(metal, 0.0, lab);
		rough = mix(rough, 0.8, lab);
		for (int i = 0; i < 2; i++) {
			vec2 rv = label_c + vec2(i == 0 ? -label_half.x + 1.4 : label_half.x - 1.4, -label_half.y + 1.0);
			float m_rv = cov(length(p - rv) - 0.7, px);
			col = mix(col, chrome_color.rgb * 0.7, m_rv);
			metal = max(metal, m_rv);
			rough = mix(rough, 0.35, m_rv);
		}

		// ---- wear
		// deliberate chips: sharp-edged bare steel on the rim's high top and left edges
		float chip = 0.0;
		float chip_edge = 0.0;
		float wsize = 0.8 + 1.3 * wear;
		for (int i = 0; i < 8; i++) {
			vec3 cd = CHIPS[i];
			float cn = vnoise(p * 3.1 + float(i) * 5.0) - 0.5;
			float cdist = (length((p - cd.xy) * vec2(1.0, 1.35)) + cn * 0.9 * cd.z - cd.z * wsize);
			chip = max(chip, cov(cdist, px));
			chip_edge = max(chip_edge, cov(cdist - 0.22, px));
		}
		float paint_only = (1.0 - metal) * (1.0 - dark) * (1.0 - m_lens);
		chip *= paint_only;
		chip_edge = clamp(chip_edge - chip, 0.0, 1.0) * paint_only;
		vec3 bare = min(bare_steel_color.rgb * (1.5 + 0.5 * nz2), vec3(1.0));
		col *= 1.0 - 0.45 * chip_edge;
		col = mix(col, bare, chip);
		metal = mix(metal, 0.9, chip);
		rough = mix(rough, 0.32, chip);

		// scratches: short curved arcs round the coin slot and the keyway, thinning with distance; fine ones elsewhere
		vec2 lxy = normalize(light_dir.xy);
		float scr = max(scratches(p, slot_c, slot_half, 26.0, 4.5, px, lxy), scratches(p, LOCK_C, vec2(1.2), 10.0, 2.2, px, lxy));
		float fine_a = ridge(vnoise(vec2(p.x * 0.35 + p.y * 0.12, p.y * 5.5 - p.x * 1.8)), 0.965) * smoothstep(0.35, 0.7, vnoise(p * 0.5 + 5.0)) * 0.3;
		float fine_b = ridge(vnoise(vec2(p.x * 4.8 + p.y * 1.4, p.y * 0.3 - p.x * 0.2)), 0.97) * smoothstep(0.4, 0.75, vnoise(p * 0.45 + 21.0)) * 0.3;
		scr = max(scr, max(fine_a, fine_b)) * (0.4 + 0.6 * wear) * (1.0 - dark) * (1.0 - m_lens) * (1.0 - lab);
		col = mix(col, vec3(0.6, 0.6, 0.58), scr * 0.3 * (1.0 - metal));
		rough = mix(rough, rough + 0.12, scr);

		// rust: a soft irregular stain hugging the top-right screw on its lower-left side, with a thin fading drip
		vec2 rp = p - vec2(50.0, 6.0);
		float rn = fbm(p + 9.0, 1.8, px);
		float stain = smoothstep(3.7, 1.6, length((rp - vec2(-0.7, 0.9)) * vec2(1.0, 0.85)) + (rn - 0.5) * 3.0);
		stain *= smoothstep(-1.6, 2.2, dot(rp, normalize(vec2(-0.5, 1.0))) + (rn - 0.5) * 2.0);
		float ty = clamp((rp.y - 2.0) / (6.5 + 3.0 * vnoise(p + 13.0)), 0.0, 1.0);
		float dax = abs(rp.x + 0.8 + (vnoise(vec2(p.y * 0.9, 4.3)) - 0.5) * 1.3);
		float dw = 0.45 * (1.0 - ty) + 0.12;
		float drip = smoothstep(dw, dw * 0.3, dax) * smoothstep(1.5, 3.0, rp.y) * (1.0 - ty) * (0.6 + 0.4 * vnoise(vec2(p.y * 3.0, 1.7)));
		float rust = clamp(stain * 0.85 + drip * 0.8, 0.0, 1.0) * smoothstep(0.1, 0.4, wear) * (1.0 - dark) * (1.0 - m_lens) * (1.0 - lab) * (1.0 - 0.5 * m_screw);
		col = mix(col, rust_color.rgb * (0.65 + 0.6 * nz2), rust * 0.8);
		metal = mix(metal, 0.0, rust * 0.8);
		rough = mix(rough, 0.85, rust);

		// grime: packed into recesses and corners, a dark line in the rim's inner corner, a nicotine film
		float corner = smoothstep(0.0, 1.0, cav);
		float g = clamp(grime * (corner * 1.7 + 0.45 * smoothstep(0.5, 0.15, abs(dd + 4.2))) * (0.55 + 0.9 * nz1), 0.0, 1.0);
		col = mix(col, vec3(0.05, 0.04, 0.025), g * (1.0 - m_lens * 0.7));
		rough = mix(rough, 0.85, g);
		float seam = (1.0 - smoothstep(0.0, 0.8, abs(dd + 2.6))) * grime * (0.6 + 0.6 * nz1) * (0.7 + 0.5 * p.y / plate_size.y);
		seam = clamp(seam * 1.3, 0.0, 0.95) * paint_only;
		col = mix(col, vec3(0.012, 0.01, 0.008), seam);
		rough = mix(rough, 0.95, seam);
		float film = grime * 0.2 * smoothstep(0.3, 0.8, nz1);
		col = mix(col, col * vec3(0.78, 0.66, 0.42) + vec3(0.025, 0.018, 0.005), film * (1.0 - m_lens));

		// hands: greasy fingerprints and a palm smudge, dull smeared patches that break the specular
		float prints = max(max(print_blob(p, vec2(31.5, 26.0), 0.5, vec2(3.3, 4.2), px), print_blob(p, vec2(24.0, 13.5), -0.3, vec2(3.0, 3.8), px)),
				max(max(print_blob(p, vec2(30.5, 40.5), 0.4, vec2(3.0, 3.6), px), print_blob(p, vec2(13.0, 52.5), -0.5, vec2(3.2, 3.8), px)),
				max(print_blob(p, vec2(38.0, 53.0), -0.4, vec2(3.2, 3.8), px), print_blob(p, vec2(42.0, 58.8), 0.9, vec2(3.0, 3.6), px))));
		float palm = smoothstep(1.0, 0.2, length((p - vec2(25.0, 40.0)) / vec2(15.0, 10.0))) * (0.5 + 0.7 * nz1);
		palm = max(palm, smoothstep(1.0, 0.25, length((p - vec2(37.0, 67.0)) / vec2(14.0, 8.0))) * (0.5 + 0.7 * nz2));
		float smear = 0.7 + 0.6 * vnoise(p * vec2(5.0, 2.0) + 31.0);
		float smu = clamp(smudge * max(prints * 1.25, palm * 0.75) * smear, 0.0, 1.0) * (1.0 - dark);
		rough = mix(rough, mix(rough * 0.55, max(rough, 0.62), metal), smu);
		col *= 1.0 - 0.18 * smu * metal - 0.14 * smu * (1.0 - metal);

		// light dust
		float dust = 0.1 * fbm(p + 77.0, 2.6, px) * smoothstep(0.1, 0.5, 0.35 - n.y) * (1.0 - dark);
		col = mix(col, vec3(0.5, 0.48, 0.43), dust);
		rough = mix(rough, 0.8, dust);

		// ---- lighting
		vec3 L = normalize(light_dir);
		vec3 V = vec3(0.0, 0.0, 1.0);
		vec3 Hh = normalize(L + V);
		float ndl = max(dot(n, L), 0.0);
		float shin = max(2.0 / (rough * rough + 0.001) - 2.0, 1.0);
		float spec = pow(max(dot(n, Hh), 0.0), shin) * (1.0 - 0.55 * rough);
		vec3 diffuse = col * (0.2 + 0.8 * ndl);
		vec3 refl = reflect(-V, n);
		// each chrome part reflects the room from its own pivot, so every part shows the bands
		vec2 piv = de < 0.6 ? vec2(ENT_C.y, ENT_H.y) : (dl < 7.0 ? vec2(LOCK_C.y, 5.8) : (dret < 0.6 ? vec2(RET_C.y, RET_H.y) : vec2(sc.y, 2.2)));
		float t = refl.y * 0.5 + 0.47 + clamp((p.y - piv.x) / piv.y, -1.2, 1.2) * 0.2;
		float xr = refl.x + (p.x / plate_size.x - 0.5) * 0.5;
		vec3 env = environment(t, xr, 0.04 + 0.45 * rough);
		vec3 metal_col = col * env * mix(1.0, 0.8, rough) + vec3(spec) * spec_gain * 1.4 * col;
		vec3 lit = mix(diffuse + vec3(spec) * spec_gain * 0.45, metal_col, metal);
		// the clear paint sheen on the satin black
		lit += (1.0 - metal) * vec3(0.7, 0.72, 0.78) * pow(max(dot(n, Hh), 0.0), 7.0) * 0.07 * (1.0 - rough * 0.5) * (1.0 - dark);
		lit *= 1.0 - 0.6 * cav * (1.0 - m_lens);
		float spec_wide = pow(max(dot(n, Hh), 0.0), 10.0);
		lit += vec3(0.6) * scr * (0.12 + 0.88 * spec_wide) * (0.3 + 0.7 * metal) * (1.0 - 0.6 * smu);

		// ---- the lit price button: a lamp behind a translucent lens
		float lamp = lamp_idle + (1.0 - lamp_idle) * glow;
		float core = smoothstep(1.15, 0.0, length((p - button_c) / button_half));
		vec3 lens = lens_color.rgb * (0.2 + 1.0 * lamp * (0.5 + 0.7 * core));
		lens += lens_color.rgb * 0.12 * lamp * smoothstep(0.6, 1.1, length((p - button_c) / button_half));
		lens = mix(lens, vec3(1.0, 0.9, 0.7), clamp(core * core * glow * 0.5, 0.0, 1.0));
		lens += (vec3(spec) * 0.9 + vec3(1.0, 0.95, 0.9) * pow(max(dot(n, Hh), 0.0), 40.0) * 0.5) * (1.0 - 0.85 * smu);
		lens = mix(lens, lens * 0.72 + vec3(0.04, 0.02, 0.015), smu * 0.85);
		lens *= 1.0 - 0.25 * cav;
		lit = mix(lit, lens, m_lens);
		// lamp spill on the metal round the lens
		float spill = pow(smoothstep(8.0, 0.0, max(dbn, 0.0)), 2.0) * 0.28 * glow * (1.0 - m_lens);
		lit += lens_color.rgb * spill * (0.5 + 0.5 * metal);

		COLOR = vec4(clamp(lit, 0.0, 1.0), cover);
	}
}
