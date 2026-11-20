shader_type canvas_item;
// The Cabinet's control panel surface (PR C pass 2c): an ANGLED laminate slab under the screen, its own material
// (a fine grain and faint brushing, not the print's speckle), lit by the one cabinet light. Read from top to
// bottom: a bright bevelled lip where the slab meets the bezel under the tube (with a dark seam under it), the
// tilted face that catches the screen's glow, and the rounded front edge with a shadow falling off under it.
// Each button throws a tight contact shadow. Wear is causal: a palm-polished patch where hands rest beside START
// (smoother, glossier, the grain worn away). Procedural (D-13/D-14), resolution independent, in rig units.
#include "res://shaders/cabinet/cabinet_material.gdshaderinc"
// The laminate's grain, scratches and packed grime are a loom texture (ART-001 §14.8a, CabinetTextures).
#include "res://shaders/cabinet/cabinet_detail.gdshaderinc"

uniform vec2 panel_size = vec2(256.0, 26.0);
uniform vec2 rig_origin = vec2(0.0);
uniform vec4 panel_color : source_color = vec4(0.165, 0.176, 0.227, 1.0);
uniform float lip : hint_range(0.0, 1.0) = 0.85;
uniform float lip_width = 1.6;
uniform float front_shadow : hint_range(0.0, 1.0) = 0.7;
uniform float front_width = 5.5;
uniform float contact : hint_range(0.0, 1.0) = 0.8;
uniform float palm : hint_range(0.0, 1.0) = 0.8;
uniform float grain : hint_range(0.0, 1.0) = 0.5;
uniform float worn_through : hint_range(0.0, 1.0) = 0.8;   // laminate rubbed through to the core where hands rest
uniform vec4 core_color : source_color = vec4(0.54, 0.45, 0.33, 1.0);
uniform vec4 rust_color : source_color = vec4(0.42, 0.2, 0.09, 1.0);   // rust bleeding from the corner screws
uniform float screw_inset = 7.0;              // panel-local: the two lower corner screws sit this far in from the side, 9 up from the bottom
uniform float rust_radius = 6.5;
uniform vec2 palm_c = vec2(86.0, 15.0);       // panel-local: the polished patch beside START
uniform vec2 palm_r = vec2(20.0, 8.0);
uniform int btn_n = 0;
uniform vec4 btn[4];                           // cap centre (xy) and half size (zw), panel-local
uniform float btn_r[4];                        // cap corner radius

void fragment() {
	vec2 p = UV * panel_size;
	vec2 rp = rig_origin + p;
	float px = max(max(fwidth(p.x), fwidth(p.y)), 1e-4);

	// polished patch: 0 outside, 1 in the middle, ragged edge
	vec2 pq = (p - palm_c) / palm_r;
	float polish = smoothstep(1.0, 0.25, length(pq) + (fbm(p + 5.0, 0.35, px) - 0.5) * 0.55) * palm;

	// the face: tilted toward the player; laminate grain + faint brushing; both worn away in the polish
	float g1 = fbm(p * 1.0 + 3.0, 2.4, px);
	float g2 = vnoise(p * vec2(0.9, 14.0) + 11.0);                 // brushing along x
	float wearing = 1.0 - 0.85 * polish;
	vec3 base = panel_color.rgb * (0.86 + 0.28 * g1 * grain * wearing + 0.06 * (g2 - 0.5) * wearing);
	// the worn laminate (loom ds_cab_laminate): its tone and relief, both rubbed smooth in the polish
	base *= detail_tone(rp, 1.8 * wearing);
	vec3 n = normalize(vec3(0.0, -0.34, 1.0));
	n = normalize(n + vec3(detail_tilt(rp, 1.6 * wearing), 0.0));

	// wear gathered into three patches, not a line of flecks (art review 2026-11-20): worn THROUGH to the core in
	// the palm patch, and rust bleeding from the two lower corner screws, run down toward the corner, with a
	// stained halo round it; all ragged by the laminate texture
	float rn = (detail_luma(rp) - detail_mean) * 2.2 + (fbm(p * 0.6 + 17.0, 0.5, px) - 0.5) * 0.5;
	float rub = polish * 0.85 + rn;
	float thru = smoothstep(0.62, 0.72, rub) * step(0.2, polish) * worn_through * detail_gain;
	float rim = smoothstep(0.55, 0.62, rub) * step(0.2, polish) * (1.0 - thru) * worn_through * detail_gain;
	base = mix(base, core_color.rgb * (0.75 + 0.5 * fbm(p * 2.0 + 9.0, 1.2, px)), thru);
	base = mix(base, base * 1.9 + 0.03, rim * 0.6);
	vec2 s0 = vec2(screw_inset, panel_size.y - 9.0);
	vec2 s1 = vec2(panel_size.x - screw_inset, panel_size.y - 9.0);
	vec2 sc = length(p - s0) < length(p - s1) ? s0 : s1;
	float run = vnoise(vec2(p.x * 0.9, 3.0)) - 0.5;                                  // streaks running down from the screw
	float rpatch = 1.0 - length((p - sc - vec2(run * 2.0, 3.5)) / vec2(rust_radius * 0.75, rust_radius * 1.5)) + rn * 0.9;
	float rust = smoothstep(0.35, 0.6, rpatch) * worn_through * detail_gain;
	float stain = smoothstep(-0.7, 0.4, rpatch) * (1.0 - rust) * worn_through * detail_gain;
	base = mix(base, base * vec3(0.6, 0.46, 0.33), stain * 0.85);
	base = mix(base, rust_color.rgb * (0.55 + 0.8 * fbm(p * 2.3 + 4.0, 1.4, px)), rust * 0.85);
	// the screw heads themselves: dull zinc domes, rusted at the slot
	float sd = length(p - sc);
	float m_scr = 1.0 - smoothstep(1.2, 1.6, sd);
	vec2 sl = rot2(p - sc, 0.6 + 2.1 * step(sc.x, panel_size.x * 0.5));
	float slot = (1.0 - smoothstep(0.2, 0.45, abs(sl.y))) * step(abs(sl.x), 1.1);
	base = mix(base, mix(vec3(0.42, 0.41, 0.39), rust_color.rgb, 0.35) * (1.0 - 0.75 * slot), m_scr);
	n = normalize(n + vec3((p - sc) / 1.6 * 0.8 * m_scr, 0.0));

	// the lip: a bright bevel on the top edge, a dark seam just beneath it where the slab meets the bezel
	float yt = p.y - 0.0;
	float in_lip = 1.0 - smoothstep(lip_width - 0.35, lip_width + 0.2, yt) ;
	base = mix(base, base * trim_tone(rp, 1.6), in_lip);                     // brushed, scratched metal lip
	float seam = smoothstep(lip_width + 0.0, lip_width + 0.5, yt) * (1.0 - smoothstep(lip_width + 0.7, lip_width + 1.4, yt));
	n = normalize(mix(n, vec3(0.0, -0.8, 0.6), in_lip));

	// the rounded front edge: a thin highlight on the radius, then the front face dropping away in shadow
	float yb = panel_size.y - p.y;
	float edge_hi = smoothstep(1.7, 1.0, yb) * smoothstep(0.35, 0.8, yb);
	float edge_face = 1.0 - smoothstep(0.35, 0.8, yb);
	float fshadow = (1.0 - smoothstep(0.0, front_width, yb)) * front_shadow;

	vec3 L = cab_key_dir(rp);
	vec3 V = vec3(0.0, 0.0, 1.0);
	vec3 Hh = normalize(L + V);
	vec3 keyc = cab_key(rp);
	vec3 amb = cab_amb(rp);
	float ndl = max(dot(n, L), 0.0);
	vec3 col = base * (amb + keyc * ndl * 1.1);
	// specular: low gloss across the face, a hard glossy sheet in the polish, a bright line on the lip
	float sp = pow(max(dot(n, Hh), 0.0), mix(18.0, 40.0, polish));
	col += keyc * sp * mix(0.05, 0.16, polish);
	col += mix(vec3(0.0), vec3(1.0, 0.96, 0.88), in_lip) * lip * (0.3 + 0.5 * clamp(dot(keyc, vec3(0.33)) * 1.3, 0.0, 1.0)) * 0.5;
	col *= 1.0 - 0.7 * seam;
	col += vec3(0.8, 0.85, 0.95) * edge_hi * 0.22 * (0.4 + dot(keyc, vec3(0.33)));
	col *= 1.0 - fshadow;
	col = mix(col, vec3(0.012), edge_face * 0.9);

	// contact shadow under each button's bezel (the key is above, so it falls down and out)
	float cs = 0.0;
	for (int i = 0; i < 4; i++) {
		if (i >= btn_n) {
			break;
		}
		float d = rbox(p - vec2(0.0, 1.0), btn[i].xy, btn[i].zw + 2.0, btn_r[i] + 2.0);
		cs = max(cs, exp(-max(d, 0.0) / 0.9) * 0.9 + exp(-max(d, 0.0) / 3.2) * 0.35);
	}
	col *= 1.0 - clamp(cs * contact, 0.0, 0.92);

	COLOR = vec4(clamp(col, 0.0, 1.0), 1.0);
}
