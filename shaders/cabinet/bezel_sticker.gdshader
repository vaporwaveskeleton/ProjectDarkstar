shader_type canvas_item;
// A printed vinyl sticker stuck on the glass: flat inks (orange body, yellow band, black keyline),
// slightly faded, edge wear that shows the pale backing, dirt caught on its rim, and a lifted
// bottom-right corner that curls over (shows its pale back) and casts a soft shadow. The slogan text is
// drawn over it by BezelSticker with the print material. The ColorRect is `margin` larger than the
// sticker so the shadow can fall on the glass.
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

void fragment() {
	vec2 size = sticker_size + vec2(2.0 * margin);
	vec2 q = UV * size - vec2(margin);
	vec2 rp = rig_origin + q;
	float px = max(max(fwidth(q.x), fwidth(q.y)), 1e-4);
	vec2 hs = sticker_size * 0.5;
	vec2 c = hs;
	float nz = fbm(q + 2.0, 0.5, px);
	float ds = rbox(q, c, hs, 3.0);

	// the lifted corner: fold along a diagonal near the bottom-right
	vec2 corner = sticker_size;
	vec2 nrm = vec2(0.7071, 0.7071);
	float fold = -curl * 0.7071;
	float d = dot(q - corner, nrm);
	vec2 qm = q - 2.0 * (d - fold) * nrm;              // mirror across the fold
	float beyond = step(fold, d);                      // the part past the fold lifts away
	float face = cov(ds, px) * (1.0 - beyond);
	float flap = (1.0 - beyond) * cov(rbox(qm, c, hs, 3.0), px) * step(fold, dot(qm - corner, nrm));

	// flat printed inks: black keyline, orange body, yellow band
	float inner = rbox(q, c, hs - vec2(1.6), 2.0);
	float band = rbox(q, c, vec2(hs.x - 3.8, hs.y - 5.2), 2.0);
	vec3 col = mix(key_black.rgb, orange.rgb, cov(inner, px));
	col = mix(col, key_black.rgb, cov(abs(band) - 0.55, px) * cov(inner, px));
	col = mix(col, yellow.rgb, cov(band + 0.4, px));
	// faded vinyl inks, patchy
	float lum = dot(col, vec3(0.3, 0.59, 0.11));
	col = mix(col, vec3(lum) * 1.1 + vec3(0.06), clamp(fade * (0.5 + 0.9 * nz), 0.0, 0.7));
	// edge wear: nicks showing the pale backing; dirt caught on the rim
	float nick = smoothstep(0.5, 0.78, fbm(q + 31.0, 2.2, px)) * smoothstep(2.4, 0.0, -ds);
	col = mix(col, backing.rgb * 0.92, nick * 0.8);
	float dirt = smoothstep(2.6, 0.0, -ds) * (0.35 + 0.8 * fbm(q + 5.0, 1.1, px));
	col = mix(col, vec3(0.1, 0.085, 0.06), clamp(dirt * 0.6, 0.0, 0.75));
	// scuffs
	float fine_a = ridge(vnoise(vec2(q.x * 0.5 + q.y * 0.2, q.y * 4.2 - q.x * 1.5)), 0.95) * smoothstep(0.35, 0.7, vnoise(q * 0.3 + 5.0));
	col = mix(col, backing.rgb, fine_a * 0.5);
	// the face darkens where the flap rises off it
	col *= 1.0 - 0.45 * smoothstep(5.0, 0.0, abs(d - fold)) * step(d, fold);

	// the flap shows the sticker's pale back, bright at the fold, darker toward the tip, a trace of print through the vinyl
	float t = clamp((fold - dot(qm - corner, nrm)) / curl, 0.0, 1.0);
	vec3 back = backing.rgb * (0.7 + 0.28 * (1.0 - t)) * (0.94 + 0.1 * nz);
	back = mix(back, orange.rgb * 0.85, 0.16 * cov(rbox(qm, c, hs - vec2(2.0), 2.0), px));

	// the shadow the flap throws on the glass beside it
	float cast_d = (d - fold) - curl * 0.2;
	float cast = (1.0 - smoothstep(0.0, 6.0, cast_d)) * step(-curl * 0.5, d - fold) * cov(rbox(q - nrm * 1.6, c, hs, 3.0), px * 3.0);
	cast *= shadow_strength;

	vec3 lit_face = col * (cab_amb(rp) + cab_key(rp) * cab_key_dir(rp).z);
	vec3 lit_back = back * (cab_amb(rp) + cab_key(rp) * (0.5 + 0.35 * t));
	float a_face = face * (1.0 - flap);
	float a_shadow = cast * (1.0 - face) * (1.0 - flap);
	float a = a_face + flap + a_shadow;
	vec3 out_c = lit_face * a_face + lit_back * flap;
	COLOR = vec4(a > 1e-4 ? out_c / a : vec3(0.0), clamp(a, 0.0, 1.0));
}
