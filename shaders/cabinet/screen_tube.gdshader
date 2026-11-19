shader_type canvas_item;
// The tube: a ColorRect exactly over the screen's opening, drawn AFTER the arcade screen's own shaders (the
// CRT and the register quantize never see it, and no pixel of the Act 0 grid is ever written: this is a
// separate overlay). Two things:
//  1. the TUBE MASK: the opening has rounded corners, so the four corner wedges are key black (the only
//     screen pixels it covers: a few corner texels, counted by ScreenTube.mask_pixels());
//  2. a VERY low-opacity glass layer: faint convex reflection, light dust, phosphor bloom bleed at the
//     edges, and a soft inner shadow where the tube sits recessed. Its alpha is clamped to `max_alpha`
//     (the sum of its amounts, never above the readability bound), so no screen channel can move by more than
//     that; `glass` 0 turns the whole layer off (photosensitivity).
#include "res://shaders/cabinet/cabinet_material.gdshaderinc"

uniform float corner_r = 5.0;
uniform vec2 rect_size = vec2(256.0, 304.0);
uniform vec2 rig_origin = vec2(0.0);
uniform float glass : hint_range(0.0, 1.0) = 1.0;
uniform float a_reflect = 0.035;
uniform float a_dust = 0.02;
uniform float a_bloom = 0.04;
uniform float a_shadow = 0.07;
uniform float max_alpha = 0.12;
uniform vec3 key_black = vec3(0.078, 0.063, 0.094);

void fragment() {
	vec2 p = UV * rect_size;
	vec2 rp = rig_origin + p;
	float px = max(max(fwidth(p.x), fwidth(p.y)), 1e-4);
	vec2 hs = rect_size * 0.5;
	float d = rbox(p, hs, hs, corner_r);                  // > 0 in the corner wedges

	// the glass layer (inside the rounded opening)
	vec2 uv = UV;
	float inner = -d;                                      // distance in from the edge
	// faint convex reflection: a soft window-shaped highlight upper left and a pale streak across it
	vec2 rq = (uv - vec2(0.3, 0.2)) / vec2(0.34, 0.2);
	float refl = exp(-dot(rq, rq)) + 0.35 * exp(-pow((uv.x * 0.6 + uv.y - 0.55) / 0.07, 2.0)) * smoothstep(0.0, 0.5, uv.y);
	float l_refl = refl * a_reflect;
	// light dust: sparse pale specks and a faint film
	float sp = smoothstep(0.9, 0.97, vnoise(p * 1.3 + 3.0)) * smoothstep(0.35, 0.7, vnoise(p * 0.2 + 9.0));
	float l_dust = (sp * 0.8 + 0.2 * smoothstep(0.5, 0.85, fbm(p + 19.0, 0.07, px))) * a_dust;
	// phosphor bloom bleeding in at the edges, in the screen's own colour
	float l_bloom = smoothstep(14.0, 0.0, inner) * a_bloom;
	vec3 bloom_c = mix(vec3(0.7, 0.8, 1.0), cab_screen_light.rgb, 0.85);
	float l_total = (l_refl + l_dust + l_bloom) * glass;
	vec3 light_c = (vec3(0.85, 0.9, 1.0) * (l_refl + l_dust) + bloom_c * l_bloom) / max(l_refl + l_dust + l_bloom, 1e-5);
	// soft inner shadow where the tube sits recessed
	float l_shadow = smoothstep(7.0, 0.0, inner) * a_shadow * glass;
	float ga = clamp(l_total + l_shadow, 0.0, max_alpha);
	vec3 gc = ga > 1e-5 ? (light_c * l_total) / max(l_total + l_shadow, 1e-5) : vec3(0.0);

	// the tube mask: opaque key black in the corner wedges, antialiased on the rounded edge
	float m = cov(d, px);                              // 1 inside the rounded opening
	float wedge = 1.0 - m;
	float a = wedge + ga * m;
	vec3 c = wedge > 0.0 ? mix(gc, key_black, wedge / max(a, 1e-5)) : gc;
	COLOR = vec4(c, clamp(a, 0.0, 1.0));
}
