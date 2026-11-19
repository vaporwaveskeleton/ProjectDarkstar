shader_type canvas_item;
// Ink printed in reverse on the back of glass (the 1983 bezel): flat opaque spot inks over a white backer.
// Applied to everything BezelField / BezelPrint / the sticker text draw. Ageing: ink-density mottle, a
// faint halftone where the tone shifts, fading, fine scuffs and flakes that show the white backer; then
// the one cabinet light (cabinet_material.gdshaderinc).
#include "res://shaders/cabinet/cabinet_material.gdshaderinc"

uniform vec2 origin = vec2(0.0);
uniform float fade : hint_range(0.0, 1.0) = 0.28;
uniform float mottle : hint_range(0.0, 1.0) = 0.55;
uniform float halftone : hint_range(0.0, 1.0) = 0.4;
uniform float halftone_cell = 2.6;
uniform float scuff : hint_range(0.0, 1.0) = 0.55;
uniform float flake : hint_range(0.0, 1.0) = 0.45;
uniform vec3 backer_color = vec3(0.89, 0.87, 0.82);

varying vec2 lp;

void vertex() {
	lp = VERTEX;
}

void fragment() {
	vec2 rp = origin + lp;
	float px = max(max(fwidth(rp.x), fwidth(rp.y)), 1e-4);
	vec3 ink = COLOR.rgb;
	float lum = dot(ink, vec3(0.3, 0.59, 0.11));

	// ink density: slow blotches plus a finer cloud (a screen-printed laydown is never even)
	float m = (fbm(rp + 5.0, 0.07, px) - 0.5) * 0.8 + (fbm(rp + 31.0, 0.6, px) - 0.5) * 0.35;
	ink *= 1.0 + mottle * m;

	// halftone where the tone changes: dots at ~45 lpi on a 45 degree screen, only along tone edges
	if (halftone > 0.0) {
		float t = vnoise(rp * 0.045 + 3.0);
		float e = 2.0;
		float gx = vnoise((rp + vec2(e, 0.0)) * 0.045 + 3.0) - vnoise((rp - vec2(e, 0.0)) * 0.045 + 3.0);
		float gy = vnoise((rp + vec2(0.0, e)) * 0.045 + 3.0) - vnoise((rp - vec2(0.0, e)) * 0.045 + 3.0);
		float edge = smoothstep(0.015, 0.12, length(vec2(gx, gy)));
		vec2 g = rot2(rp, 0.7854) / halftone_cell;
		float dd = length(fract(g) - 0.5) * halftone_cell;
		float rad = halftone_cell * 0.5 * sqrt(clamp(t, 0.1, 0.9));
		float dots = cov(dd - rad, px) * smoothstep(1.5, 3.5, halftone_cell / px);
		ink *= 1.0 - halftone * 0.3 * edge * dots + halftone * 0.05 * edge;
	}

	// fading: pale, greyer, patchy
	float fk = fade * (0.45 + 0.9 * fbm(rp + 70.0, 0.025, px));
	ink = mix(ink, vec3(lum) * 1.08 + vec3(0.05, 0.05, 0.045), clamp(fk, 0.0, 0.8));

	// scuffs and flakes through to the white backer
	float fine_a = ridge(vnoise(vec2(rp.x * 0.3 + rp.y * 0.1, rp.y * 3.8 - rp.x * 1.3)), 0.955) * smoothstep(0.35, 0.7, vnoise(rp * 0.12 + 5.0));
	float fine_b = ridge(vnoise(vec2(rp.x * 3.6 + rp.y * 1.4, rp.y * 0.25 - rp.x * 0.2)), 0.96) * smoothstep(0.4, 0.75, vnoise(rp * 0.1 + 21.0));
	float rub = smoothstep(0.62, 0.9, fbm(rp + 120.0, 0.05, px)) * 0.5;
	float cell = hash21(floor(rp * 2.3) + 9.0);
	float fl = step(0.975 - 0.02 * flake, cell) * smoothstep(0.5, 0.75, vnoise(rp * 0.2 + 40.0)) * smoothstep(0.7, 1.4, 1.0 / (2.3 * px));
	float s = clamp(max(fine_a, fine_b) * 0.55 + rub * 0.35, 0.0, 1.0) * scuff + fl * flake;
	ink = mix(ink, backer_color * (0.88 + 0.12 * vnoise(rp * 4.0)), clamp(s, 0.0, 0.85));

	// the one cabinet light
	ink *= cab_amb(rp) + cab_key(rp) * cab_key_dir(rp).z;
	COLOR = vec4(clamp(ink, 0.0, 1.0), COLOR.a);
}
