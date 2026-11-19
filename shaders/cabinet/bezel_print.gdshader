shader_type canvas_item;
// Ink printed in reverse on the back of glass (the 1983 bezel), plate by plate. Everything BezelField /
// BezelPrint / the sticker lettering draw arrives as flat spot colour. A draw with alpha below 1 is a
// SCREENED TONE: the alpha is the tone (0 none .. 1 solid) and becomes round dots on that ink's own
// rotated grid (black 45, blue-ish 15, red-ish 75, the rest 0 degrees) with dot gain, never a soft blend;
// where the dots would be finer than about two pixels they fade to their average tone, so the print is
// resolution independent (finer dots on a bigger display). Ageing is CAUSAL: ink fades and is lost as
// sharp-edged flakes showing the black backing only where the cabinet is touched and kicked (wear_k:
// lower edge, corners, round the coin door), plus one or two clear flakes; the upper art stays clean and
// the navy has no even speckle. Then the one cabinet light (cabinet_material.gdshaderinc).
#include "res://shaders/cabinet/cabinet_material.gdshaderinc"

uniform vec2 origin = vec2(0.0);
uniform float fade : hint_range(0.0, 1.0) = 0.28;
uniform float mottle : hint_range(0.0, 1.0) = 0.4;
uniform float halftone : hint_range(0.0, 1.0) = 1.0;
uniform float halftone_cell = 1.25;
uniform float dot_gain = 0.22;
uniform float scuff : hint_range(0.0, 1.0) = 0.3;
uniform float flake : hint_range(0.0, 1.0) = 0.7;
uniform vec3 backer_color = vec3(0.89, 0.87, 0.82);
uniform vec3 flake_color = vec3(0.02, 0.018, 0.024);       // the black backing behind the print

varying vec2 lp;

void vertex() {
	lp = VERTEX;
}

float plate_angle(vec3 c) {
	float mx = max(c.r, max(c.g, c.b));
	if (mx < 0.2) {
		return 0.7854;
	}
	if (c.b >= c.r && c.b >= c.g) {
		return 0.2618;
	}
	return c.r > c.g * 1.15 ? 1.309 : 0.0;
}

// One screened tone: coverage 0..1 at rig position rp.
float plate_tone(vec2 rp, vec3 ink, float tone, float px) {
	float pitch = halftone_cell;
	vec2 f = fract(rot2(rp, plate_angle(ink)) / pitch) - 0.5;
	float t = clamp(tone + dot_gain * 4.0 * tone * (1.0 - tone), 0.0, 1.0);
	float cvg;
	if (t < 0.5) {
		cvg = cov(length(f) * pitch - pitch * sqrt(t / 3.14159), px);
	} else {
		float hole = length(vec2(0.5) - abs(f)) * pitch - pitch * sqrt((1.0 - t) / 3.14159);
		cvg = 1.0 - cov(hole, px);
	}
	return mix(t, cvg, smoothstep(1.2, 2.6, pitch / px));
}

// A sharp-edged flake of lost ink, irregular, centred c, radius r.
float flake_shape(vec2 p, vec2 c, float r, float seed, float px) {
	vec2 q = rot2(p - c, seed * 2.3);
	float ang = atan(q.y, q.x);
	float rr = r * (0.62 + 0.55 * vnoise(vec2(ang * 1.7 + seed, seed * 3.1)) + 0.25 * vnoise(q * 1.3 + seed));
	return cov(length(q * vec2(1.0, 1.45)) - rr, px);
}

// Many small flakes where the cabinet is worn, none where it is not.
float flakes(vec2 rp, float px, float w) {
	vec2 g = rp / 5.0;
	vec2 cell = floor(g);
	float h = hash21(cell + 13.0);
	float rate = 0.05 * w * w * w;
	if (h < 1.0 - rate) {
		return 0.0;
	}
	vec2 c = (cell + vec2(0.25 + 0.5 * hash21(cell + 3.0), 0.25 + 0.5 * hash21(cell + 7.0))) * 5.0;
	float r = 0.6 + 1.0 * hash21(cell + 21.0);
	return flake_shape(rp, c, r, h * 9.0, px);
}

void fragment() {
	vec2 rp = origin + lp;
	float px = max(max(fwidth(rp.x), fwidth(rp.y)), 1e-4);
	vec3 ink = COLOR.rgb;
	float a = 1.0;
	float tone = COLOR.a;
	if (tone < 0.999) {
		a = halftone > 0.0 ? mix(tone, plate_tone(rp, ink, tone, px), halftone) : tone;
	}
	float lum = dot(ink, vec3(0.3, 0.59, 0.11));
	float w = wear_k(rp);

	// ink density: slow blotches only (a screen-printed laydown is never perfectly even, but not speckled)
	float m = (fbm(rp + 5.0, 0.05, px) - 0.5) * 0.7;
	ink *= 1.0 + mottle * m;

	// fading: pale and grey, patchy, strongest where the cabinet is worn
	float fk = fade * (0.3 + 0.7 * fbm(rp + 70.0, 0.025, px)) + scuff * 0.45 * w * smoothstep(0.35, 0.8, fbm(rp + 120.0, 0.06, px));
	ink = mix(ink, vec3(lum) * 1.08 + vec3(0.05, 0.05, 0.045), clamp(fk, 0.0, 0.8));

	// flakes through to the black backing: sharp edges, causal, plus two clear ones
	float fl = flakes(rp, px, w);
	fl = max(fl, flake_shape(rp, vec2(cab_hole.x - 61.0, cab_hole.y + cab_hole.w - 19.0), 3.3, 1.7, px));
	fl = max(fl, flake_shape(rp, vec2(cab_hole.x + cab_hole.z + 66.0, cab_hole.y + 213.0), 2.5, 4.1, px));
	fl *= flake;
	ink = mix(ink, flake_color, fl);
	a = mix(a, 1.0, fl);

	// the one cabinet light
	ink *= cab_amb(rp) + cab_key(rp) * cab_key_dir(rp).z;
	COLOR = vec4(clamp(ink, 0.0, 1.0), a);
}
