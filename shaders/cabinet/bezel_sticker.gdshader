shader_type canvas_item;
// A die-cut vinyl sticker stuck on the glass (the NEW! burst): a white vinyl backing cut to a scalloped
// burst, the orange ink printed on it a little out of register so it bleeds past the cut on one side and
// leaves a sliver of white on the other, a yellow screened glow in the middle. NO keyline, NO inner frame, NO
// bevel: it is flat printed vinyl. Faded inks, edge nicks, dirt on the rim, and a lifted bottom-right
// corner that curls over (shows its pale back) and casts a soft shadow. The slogan is VectorText over it,
// drawn by BezelSticker with the print material. The ColorRect is `margin` larger than the sticker so the
// shadow can fall on the glass.
#include "res://shaders/cabinet/cabinet_material.gdshaderinc"

uniform vec2 sticker_size = vec2(74.0, 26.0);
uniform float margin = 3.0;
uniform vec2 rig_origin = vec2(0.0);                  // rig position of the sticker's top-left
uniform vec4 orange = vec4(0.91, 0.475, 0.17, 1.0);
uniform vec4 yellow = vec4(0.95, 0.76, 0.19, 1.0);
uniform vec4 key_black = vec4(0.08, 0.063, 0.094, 1.0);
uniform vec4 backing = vec4(0.88, 0.87, 0.82, 1.0);
uniform float fade : hint_range(0.0, 1.0) = 0.3;
uniform float curl = 9.0;
uniform float shadow_strength = 0.7;

// The die-cut outline: an ellipse with twelve soft petals.
float sd_cut(vec2 q, vec2 hs, float inset) {
	vec2 qn = (q - hs) / (hs - vec2(inset));
	float ang = atan(qn.y, qn.x);
	float k = 0.925 + 0.075 * cos(ang * 12.0);
	return (length(qn) - k) * min(hs.x, hs.y);
}

void fragment() {
	vec2 size = sticker_size + vec2(2.0 * margin);
	vec2 q = UV * size - vec2(margin);
	vec2 rp = rig_origin + q;
	float px = max(max(fwidth(q.x), fwidth(q.y)), 1e-4);
	vec2 hs = sticker_size * 0.5;
	float nz = fbm(q + 2.0, 0.5, px);
	float ds = sd_cut(q, hs, 0.0);

	// the lifted corner: fold along a diagonal near the bottom-right
	vec2 corner = sticker_size;
	vec2 nrm = vec2(0.7071, 0.7071);
	float fold = -curl * 0.7071;
	float d = dot(q - corner, nrm);
	vec2 qm = q - 2.0 * (d - fold) * nrm;              // mirror across the fold
	float beyond = step(fold, d);                      // the part past the fold lifts away
	float face = cov(ds, px) * (1.0 - beyond);
	float flap = (1.0 - beyond) * cov(sd_cut(qm, hs, 0.0), px) * step(fold, dot(qm - corner, nrm));

	// white vinyl, then the ink plate printed out of register: bleeds past the cut at the upper left, leaves a
	// white sliver at the lower right. Ragged ink edge.
	vec2 reg = vec2(-0.55, -0.45);
	float ink_d = sd_cut(q - reg, hs, 0.35) + (fbm(q + 9.0, 1.7, px) - 0.5) * 0.55;
	float ink_cov = cov(ink_d, px);
	vec3 col = backing.rgb * 0.96;
	col = mix(col, orange.rgb, ink_cov);
	// a yellow screened glow in the middle: round dots, bigger toward the centre (no soft blend)
	vec2 g = rot2(q, 0.7854) / 1.1;
	float dd = length(fract(g) - 0.5) * 1.1;
	float tone = smoothstep(26.0, 2.0, length((q - hs) / vec2(1.0, 1.7)));
	float dots = cov(dd - 0.55 * sqrt(clamp(tone * 0.95, 0.0, 1.0)), px) * smoothstep(1.2, 2.6, 1.1 / px);
	float solid = smoothstep(0.6, 1.0, tone);
	col = mix(col, yellow.rgb, ink_cov * clamp(max(dots * tone * 1.4, solid * 0.9), 0.0, 1.0));
	// faded vinyl inks, patchy
	float lum = dot(col, vec3(0.3, 0.59, 0.11));
	col = mix(col, vec3(lum) * 1.1 + vec3(0.06), clamp(fade * (0.5 + 0.9 * nz), 0.0, 0.7));
	// edge wear: nicks showing bare backing; dirt caught on the cut edge
	float nick = smoothstep(0.55, 0.8, fbm(q + 31.0, 2.2, px)) * smoothstep(2.4, 0.0, -ds);
	col = mix(col, backing.rgb * 0.92, nick * 0.6);
	float dirt = smoothstep(1.8, 0.0, -ds) * (0.3 + 0.7 * fbm(q + 5.0, 1.1, px)) * smoothstep(0.25, 0.7, fbm(q + 17.0, 0.35, px));
	col = mix(col, vec3(0.1, 0.085, 0.06), clamp(dirt * 0.55, 0.0, 0.7));
	// the face darkens where the flap rises off it
	col *= 1.0 - 0.4 * smoothstep(5.0, 0.0, abs(d - fold)) * step(d, fold);

	// the flap shows the sticker's pale back, bright at the fold, darker toward the tip
	float t = clamp((fold - dot(qm - corner, nrm)) / curl, 0.0, 1.0);
	vec3 back = backing.rgb * (0.7 + 0.28 * (1.0 - t)) * (0.94 + 0.1 * nz);
	back = mix(back, orange.rgb * 0.85, 0.12 * ink_cov);

	// the shadow the flap throws on the glass beside it
	float cast_d = (d - fold) - curl * 0.2;
	float cast = (1.0 - smoothstep(0.0, 6.0, cast_d)) * step(-curl * 0.5, d - fold) * cov(sd_cut(q - nrm * 1.6, hs, 0.0), px * 3.0);
	cast *= shadow_strength;

	vec3 lit_face = col * (cab_amb(rp) + cab_key(rp) * cab_key_dir(rp).z);
	vec3 lit_back = back * (cab_amb(rp) + cab_key(rp) * (0.5 + 0.35 * t));
	float a_face = face * (1.0 - flap);
	float a_shadow = cast * (1.0 - face) * (1.0 - flap);
	float a = a_face + flap + a_shadow;
	vec3 out_c = lit_face * a_face + lit_back * flap;
	COLOR = vec4(a > 1e-4 ? out_c / a : vec3(0.0), clamp(a, 0.0, 1.0));
}
