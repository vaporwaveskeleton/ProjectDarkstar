shader_type canvas_item;
render_mode unshaded;
// The crystal sphere (ART-001 §16) as an orrery: the vast curve of a glass sky across the frame.
// A thin bright seam (the hero), an engraved brass meridian band riding just inside it with
// graduation ticks, faint meridians fading into the fog below, and up to two nested shells at
// other depths (their own parallax, thinner, fogged). A broad soft refraction band bends the fog
// behind it (screen texture, quality-switchable), a slow glint travels along the seam, and a faint
// second seam should not be there (strength by tier). Where the entity is, the line BREAKS: a crisp
// gap with its ends displaced. T5: straight glass fractures struck into the seam.
// Colours arrive from GDScript (Pal); defaults are overwritten at runtime.

#include "res://shaders/aether/aether_common.gdshaderinc"

uniform sampler2D screen_tex : hint_screen_texture, filter_linear_mipmap;
uniform vec3 glass_col : source_color = vec3(0.38, 0.81, 0.66);
uniform vec3 seam_col : source_color = vec3(0.66, 0.94, 0.82);
uniform vec3 crack_col : source_color = vec3(0.89, 0.87, 0.82);
uniform vec3 brass_col : source_color = vec3(0.54, 0.55, 0.58);
uniform vec3 brass_hi : source_color = vec3(0.89, 0.87, 0.82);
uniform vec3 brass_shadow : source_color = vec3(0.16, 0.19, 0.34);
uniform vec3 floor_col : source_color = vec3(0.039, 0.039, 0.07);
uniform vec2 centre = vec2(400.0, 1500.0);    // local px
uniform float radius = 1380.0;
uniform float band_px = 46.0;
uniform float refraction_px = 0.0;
uniform int shells = 2;
uniform float brass_strength = 0.55;
uniform float wrong_strength = 0.0;
uniform vec2 wrong_offset = vec2(-26.0, 14.0);
uniform float glint_angle = 0.0;              // radians from straight up, clockwise
uniform float glint_strength = 0.75;
uniform float crack_amount = 0.0;
uniform vec2 camera_offset = vec2(0.0);       // camera drift, px
uniform float time_s = 0.0;
uniform float drain = 0.0;
uniform float sky_tint = 0.07;
uniform float missing = 0.0;                  // pass 6: the look's monotonic "missing" cue
uniform int numerals = 1;                     // 1 = engraved I..XII on the meridian band, 0 = none

// ✱ numeral cap height and its row centre (|d| px inside the seam): the outer half of the band
const float NUM_H = 5.0;
const float NUM_ROW = 10.4;
const float NUM_CLEAR = 9.0;                  // ✱ half-width of the numeral's tick-free cartouche

varying vec2 v_px;

void vertex() {
	v_px = VERTEX;
}

float thin_line(float x, float w, float fw) {
	return 1.0 - smoothstep(w, w + fw * 1.5, abs(x));
}

// One engraved Roman numeral I..XII (pass 4, Q-T92: decorative engraving, not UI text — pending PM
// approval, switchable by `numerals`). `g` = glyph-space px (x along the band, y toward the seam),
// centred on the numeral; `h` = cap height px. Returns the distance (px) to the nearest stroke.
// Strokes: I = a stem with foot and head serifs; V = two arms meeting at the foot; X = two
// diagonals. Codes are read most-significant digit first: 1 = I, 2 = V, 3 = X.
float roman_numeral(vec2 g, int n, float h) {
	int codes[12] = int[12](1, 11, 111, 12, 2, 21, 211, 2111, 13, 3, 31, 311);
	int code = codes[clamp(n, 1, 12) - 1];
	float adv_i = 0.46 * h;
	float adv_w = 0.9 * h;
	float gap = 0.3 * h;
	// total width (chars + gaps), then walk the digits from the last char leftward
	float width = -gap;
	int c = code;
	for (int k = 0; k < 4; k++) {
		if (c == 0) {
			break;
		}
		width += (c % 10 == 1 ? adv_i : adv_w) + gap;
		c /= 10;
	}
	float x = width * 0.5;
	float best = 1e4;
	float top = 0.5 * h;
	float bot = -0.5 * h;
	c = code;
	for (int k = 0; k < 4; k++) {
		if (c == 0) {
			break;
		}
		int ch = c % 10;
		float w = ch == 1 ? adv_i : adv_w;
		float cx = x - w * 0.5;
		if (ch == 1) {
			best = min(best, a_seg(g, vec2(cx, bot), vec2(cx, top)));
			best = min(best, a_seg(g, vec2(cx - 0.18 * h, top), vec2(cx + 0.18 * h, top)));
			best = min(best, a_seg(g, vec2(cx - 0.18 * h, bot), vec2(cx + 0.18 * h, bot)));
		} else if (ch == 2) {
			best = min(best, a_seg(g, vec2(cx - 0.45 * h, top), vec2(cx, bot)));
			best = min(best, a_seg(g, vec2(cx, bot), vec2(cx + 0.45 * h, top)));
		} else {
			best = min(best, a_seg(g, vec2(cx - 0.42 * h, top), vec2(cx + 0.42 * h, bot)));
			best = min(best, a_seg(g, vec2(cx - 0.42 * h, bot), vec2(cx + 0.42 * h, top)));
		}
		x -= w + gap;
		c /= 10;
	}
	return best;
}

// The engraved brass meridian band (pass 3: brass is BRASS) riding inside a seam at signed distance
// d, arc length `arc`. Returns x = metal body, y = highlight edge (toward the seam), z = engraving
// shadow (inner edge, graduations, numerals). Two-tone metal: brass_col body, brass_hi edge,
// brass_shadow engraving. Minor graduations every 9 px over the inner half of the band, majors
// every 45 px across it, each with its own weight. Pass 4: halfway between majors, a crisp engraved
// Roman numeral I..XII (a VOID_3 cut in a tick-free cartouche), upright toward the seam and read
// along the curve; `numerals` = 0 leaves graduations only (the cartouche gets its ticks back).
vec3 brass_band(float d, float arc, float fw) {
	float aa = fw * 1.2;
	float body = smoothstep(-15.0 - aa, -15.0 + aa, d) * (1.0 - smoothstep(-6.0 - aa, -6.0 + aa, d));
	float hi = thin_line(d + 6.7, 0.45, fw);
	float lo = thin_line(d + 14.3, 0.4, fw);
	float mi = floor(arc / 9.0 + 0.5);
	float tx = arc - mi * 9.0;
	float mj = floor(arc / 45.0 + 0.5);
	float mx = arc - mj * 45.0;
	float is_major = step(abs(mx), 4.5);
	float w_minor = 0.22 + 0.3 * a_hash(vec2(mi, 1.3));
	float w_major = 0.55 + 0.45 * a_hash(vec2(mj, 7.1));
	float tw = mix(w_minor, w_major, is_major);
	float tick = thin_line(tx, tw, fw) * step(-14.5, d) * step(d, mix(-10.5, -7.0, is_major));
	// engraved numerals between the majors (the hour ring): a clear cartouche (no minor ticks) with
	// the numeral cut across the band
	float marks = 0.0;
	float nj = floor(arc / 45.0);
	vec2 g = vec2(arc - (nj + 0.5) * 45.0, d + NUM_ROW);
	if (numerals == 1) {
		tick *= step(NUM_CLEAR, abs(g.x));
		if (abs(g.y) < NUM_H && abs(g.x) < NUM_CLEAR) {
			marks = thin_line(roman_numeral(g, int(mod(nj, 12.0)) + 1, NUM_H), 0.3, fw);
		}
	}
	return vec3(body, hi * body, max(lo * body, max(tick, marks * body)));
}

void fragment() {
	vec2 spx = SCREEN_UV * screen_size;
	vec4 loss = a_loss(spx);
	vec2 rel = v_px - centre;
	float r = length(rel);
	float d = r - radius;                      // < 0 inside the sphere (where we are)
	// near the entity the seam's ends are displaced before the line stops
	d += 10.0 * loss.w * loss.w;
	float keep = (1.0 - loss.y) * (1.0 - a_missing(spx, missing));   // crisp gap: the line just... stops
	vec2 nrm = rel / max(r, 1.0);
	float fw = max(fwidth(v_px.x), 0.2);
	float band = exp(-abs(d) / band_px);
	float core = exp(-abs(d) / 1.1);
	float halo = exp(-abs(d) / 5.0);
	float ang = atan(rel.x, -rel.y);
	float arc = ang * radius;
	vec2 off = vec2(0.0);
	float crack = 0.0;
	if (crack_amount > 0.0) {
		// the sphere itself breaking: straight glass fractures struck into the seam
		for (int i = 0; i < 3; i++) {
			float th = -0.42 + 0.4 * float(i) + 0.05 * sin(float(i) * 7.0);
			vec2 hit = centre + radius * vec2(sin(th), -cos(th));
			vec2 tang = vec2(cos(th), sin(th));
			vec2 g = a_glass(v_px, hit, 190.0 * crack_amount * (1.0 - 0.25 * float(i == 1)), 2.3 + float(i) * 3.1, tang, 0.5, 3.4);
			crack = max(crack, (1.0 - smoothstep(0.5 * fw, 1.6 * fw, g.x)) * 0.45);
			off += normalize(v_px - hit + vec2(0.01)) * g.y * 6.0;
		}
	}
	vec3 col = vec3(0.0);
	float a = 0.0;
	vec3 glass_add = seam_col * core * 0.55 + glass_col * halo * 0.12;
	if (refraction_px > 0.0) {
		// refraction: a lens across the seam, plus a drift that runs against the camera
		off += nrm * refraction_px * band * clamp(d / band_px, -1.0, 1.0);
		off += -camera_offset * 0.35 * band;
		vec3 behind = textureLod(screen_tex, SCREEN_UV + off / screen_size, 0.0).rgb;
		col = mix(behind, behind * 0.85 + glass_col * 0.15, band * 0.6 * keep);
		col = mix(col, col * 0.9 + glass_col * 0.1, sky_tint * step(0.0, d) * 6.0 * keep);
		a = clamp(band * 1.4 + sky_tint * 4.0 * step(0.0, d), 0.0, 1.0);
	} else {
		col = glass_col * 0.5;
		a = (band * 0.18 + sky_tint * step(0.0, d)) * keep;
	}
	// brass meridian band and graduation (engraved, fogged: below the seam's brightness)
	vec3 bb = brass_band(d, arc, fw) * brass_strength;
	float br = 0.0;
	// faint meridians fading down into the fog, and one dashed parallel
	float mer_x = abs(fract(ang / 0.09) - 0.5) * 0.09 * radius;
	float mer = (1.0 - smoothstep(0.3, 0.3 + fw * 1.5, mer_x)) * smoothstep(-130.0, -16.0, d) * step(d, -14.0) * 0.35;
	float par = (1.0 - smoothstep(0.3, 0.3 + fw * 1.5, abs(d + 44.0))) * step(0.45, fract(arc / 14.0)) * 0.4;
	br = max(br, max(mer, par) * brass_strength);
	// nested shells: other depths, other parallax, thinner and fogged
	for (int k = 1; k <= 2; k++) {
		if (k > shells) {
			break;
		}
		float fk = float(k);
		vec2 c2 = centre + camera_offset * (0.1 * fk) + vec2(50.0 * fk, -14.0 * fk);
		float d2 = length(v_px - c2) - radius * (1.0 + 0.05 * fk);
		float s2 = exp(-abs(d2) / 0.8) * (0.28 / fk) + exp(-abs(d2) / 6.0) * 0.04;
		glass_add += glass_col * s2;
		br = max(br, (1.0 - smoothstep(0.3, 0.3 + fw * 1.5, abs(d2 + 6.0))) * brass_strength * 0.45 / fk);
		a = max(a, s2 * 0.8);
	}
	col = mix(col, brass_col, max(br, bb.x * 0.85) * keep);
	col = mix(col, brass_shadow, bb.z * keep);
	col = mix(col, brass_hi, bb.y * keep);
	a = max(a, max(br, max(bb.x * 0.85, max(bb.y, bb.z))) * keep);
	col += glass_add * keep;
	a = max(a, clamp(core + halo * 0.6, 0.0, 1.0) * keep);
	// the glint, travelling along the seam
	float glint = exp(-pow((ang - glint_angle) * radius / 70.0, 2.0)) * exp(-abs(d) / 3.0) * glint_strength * keep;
	col += seam_col * glint;
	a = max(a, glint);
	// the second seam, offset and breathing; it should not exist
	if (wrong_strength > 0.0) {
		float r2 = length(v_px - centre - wrong_offset * (1.0 + 0.2 * sin(time_s * 0.09)));
		float dw = r2 - radius * 1.004;
		float w = exp(-abs(dw) / 1.3) * wrong_strength * 0.35 * keep;
		col += glass_col * w;
		a = max(a, w);
	}
	col = mix(col, crack_col, crack);
	a = max(a, crack);
	col = mix(col, vec3(a_luma(col)), max(drain * 0.6, missing * A_MISS_DESAT));
	col = max(col, floor_col);
	COLOR = vec4(col, clamp(a, 0.0, 1.0));
}
