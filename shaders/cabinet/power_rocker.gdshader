shader_type canvas_item;
// The POWER rocker switch on the cabinet's right side under the coin door (PR C pass 2c), drawn procedurally
// (D-13/D-14: no images). Resolution independent signed distance fields in face units (rig units; the ColorRect is
// `face_size`), antialiased with fwidth, lit by the one cabinet light (cabinet_material.gdshaderinc). From the outside
// in: a soft contact shadow on the sheet, grime packed round the base, the focus halo (the selector lights the
// frame), a snap-in zinc frame, the black well, and the rocker paddle: a single sloped piece of black plastic, one
// half pressed down, with a printed O and I legend. ON: the I half is down and glows (a lamp inside it). `flip` 1
// is the switch thrown OFF: the paddle tilts the other way and the lamp dies. Pressed: the paddle sinks a little.
#include "res://shaders/cabinet/cabinet_material.gdshaderinc"

uniform vec2 face_size = vec2(52.0, 22.5);
uniform vec2 rig_origin = vec2(0.0);
uniform vec2 rk_c = vec2(37.0, 11.25);
uniform vec2 rk_half = vec2(9.5, 5.4);
uniform float press : hint_range(0.0, 1.0) = 0.0;
uniform float hover_k : hint_range(0.0, 1.0) = 0.0;
uniform float focus_k : hint_range(0.0, 1.0) = 0.0;
uniform float flip : hint_range(0.0, 1.0) = 0.0;
uniform float lamp : hint_range(0.0, 1.0) = 1.0;
uniform float dim : hint_range(0.0, 1.0) = 0.0;
uniform vec4 plastic_color : source_color = vec4(0.045, 0.045, 0.05, 1.0);
uniform vec4 ring_color : source_color = vec4(0.54, 0.55, 0.56, 1.0);
uniform vec4 lamp_color : source_color = vec4(1.0, 0.29, 0.11, 1.0);
uniform vec4 focus_color : source_color = vec4(1.0, 0.85, 0.2, 1.0);
uniform vec4 ink_color : source_color = vec4(0.94, 0.9, 0.78, 1.0);
uniform float wear : hint_range(0.0, 1.0) = 0.8;
uniform float grime : hint_range(0.0, 1.0) = 0.95;
uniform float micro_texture : hint_range(0.0, 1.0) = 0.55;

const float FRAME_W = 1.0;                      // the zinc frame's width
const float GAP = 0.4;                          // dark gap between frame and paddle
const float R = 1.5;

void over(inout vec3 col, inout float a, vec3 c, float k) {
	float oa = k + a * (1.0 - k);
	col = (c * k + col * a * (1.0 - k)) / max(oa, 1e-4);
	a = oa;
}

float d_outer(vec2 p) { return rbox(p, rk_c, rk_half, R); }
float d_open(vec2 p) { return rbox(p, rk_c, rk_half - FRAME_W, R - 0.5); }
float d_pad(vec2 p) { return rbox(p, rk_c, rk_half - FRAME_W - GAP, R - 0.7); }

void fragment() {
	vec2 p = UV * face_size;
	vec2 rp = rig_origin + p;
	float px = max(max(fwidth(p.x), fwidth(p.y)), 1e-4);
	float dO = d_outer(p);
	float dI = d_open(p);
	float dP = d_pad(p);
	float m_out = cov(dO, px);
	float m_open = cov(dI, px);
	float m_pad = cov(dP, px);
	vec3 col = vec3(0.0);
	float a = 0.0;
	vec2 sp = p + vec2(3.7, 1.9);
	float nz1 = fbm(sp, 1.8, px);
	float nz2 = fbm(sp + 31.0, 4.2, px);
	vec3 L = cab_key_dir(rp);
	vec3 V = vec3(0.0, 0.0, 1.0);
	vec3 Hh = normalize(L + V);
	vec3 keyc = cab_key(rp);
	vec3 amb = cab_amb(rp);

	// ---- contact shadow the module throws on the sheet (key above: it falls down)
	float dsh = rbox(p - vec2(0.0, 1.2), rk_c, rk_half, R);
	over(col, a, vec3(0.0), exp(-max(dsh, 0.0) / 1.5) * 0.7 * (1.0 - m_out));

	// ---- grime packed against the frame
	float halo = smoothstep(2.6, 0.0, dO) * (1.0 - m_out) * grime * (0.45 + 0.9 * nz1);
	over(col, a, vec3(0.035, 0.03, 0.026), clamp(halo * 0.8, 0.0, 0.85));

	// ---- focus halo
	float band = cov(abs(dO - 1.0) - 0.45, px) * (1.0 - m_out);
	float glow = exp(-max(dO - 1.4, 0.0) / 2.4) * 0.4 * (1.0 - m_out);
	over(col, a, focus_color.rgb, clamp((band + glow) * focus_k, 0.0, 1.0));

	// ---- the zinc frame: a bead with a bevel facing out on the outer half and in on the inner half
	float e = max(px * 0.8, 0.07);
	vec2 g = vec2(d_outer(p + vec2(e, 0.0)) - d_outer(p - vec2(e, 0.0)), d_outer(p + vec2(0.0, e)) - d_outer(p - vec2(0.0, e))) / (2.0 * e);
	float u = clamp(-dO / FRAME_W, 0.0, 1.0);               // 0 at the outer edge, 1 at the opening
	float bev = sin(u * 3.14159) * (u < 0.5 ? 1.0 : -0.5);
	vec3 nf = normalize(vec3(g * bev * 1.3, 1.0));
	vec3 zinc = ring_color.rgb * (0.78 + 0.38 * nz2);
	zinc *= 1.0 + 0.22 * (vnoise(sp * vec2(2.2, 21.0)) - 0.5) * micro_texture;
	vec3 keyn = mix(vec3(dot(keyc, vec3(0.333))), keyc, 0.3);
	vec3 refl = reflect(-V, nf);
	vec3 env = environment(refl.y * 0.5 + 0.47, refl.x + (p.x / face_size.x - 0.5) * 0.5, 0.3);
	float spec_f = pow(max(dot(nf, Hh), 0.0), 22.0);
	vec3 frame = zinc * env * (amb + keyn * 0.8) * 1.2 + zinc * (amb + keyn * max(dot(nf, L), 0.0)) * 0.5 + keyn * spec_f * 0.5 * zinc;
	frame *= 1.0 - 0.5 * grime * (smoothstep(0.35, 0.0, u) + smoothstep(0.65, 1.0, u) * 0.6) * (0.5 + 0.8 * nz1);
	over(col, a, frame, m_out);

	// ---- the well
	over(col, a, vec3(0.006, 0.005, 0.006), m_open);

	// ---- the paddle: one sloped piece of black plastic; state s +1 = ON (I half, on the right, is down)
	vec2 q = (p - rk_c) / (rk_half - FRAME_W - GAP);
	float s = mix(1.0, -1.0, flip);
	float slope = 0.5 * s * (1.0 - 0.55 * press);
	float depth = clamp(-dP / 1.6, 0.0, 1.0);
	vec2 gp = vec2(d_pad(p + vec2(e, 0.0)) - d_pad(p - vec2(e, 0.0)), d_pad(p + vec2(0.0, e)) - d_pad(p - vec2(0.0, e))) / (2.0 * e);
	vec3 np = normalize(vec3(slope - gp.x * (1.0 - depth) * 0.9, -gp.y * (1.0 - depth) * 0.9, 1.0));

	float ndl = max(dot(np, L), 0.0);
	vec3 pl = plastic_color.rgb * (0.9 + 0.2 * nz1);
	vec3 diffuse = pl * (amb * 0.9 + keyc * ndl * 0.7);
	float spec = pow(max(dot(np, Hh), 0.0), 34.0) * 0.55 + 0.08 * pow(max(dot(np, Hh), 0.0), 7.0);
	// worn smooth where thumbs land (the I half's upper right), scuffed round it
	float scuffs = ridge(vnoise(vec2(sp.x * 2.7 + sp.y * 1.1, sp.y * 6.0 - sp.x * 2.0)), 0.9) * wear * smoothstep(0.35, 0.7, nz2);
	diffuse += vec3(0.3, 0.29, 0.27) * scuffs * 0.5;
	vec3 pad_col = diffuse + keyc * spec;
	// the lit half: lamp behind translucent plastic on the down side
	float lit_side = smoothstep(-0.05, 0.25, q.x * s);
	float core = smoothstep(1.3, 0.0, length((q - vec2(0.5 * s, 0.0)) * vec2(0.9, 1.4)));
	float lamp_k = clamp(lamp * (1.0 - flip) + 0.12 * hover_k + 0.1 * focus_k, 0.0, 1.0);
	vec3 emit = lamp_color.rgb * lamp_k * lit_side * (0.22 + 0.7 * core);
	pad_col += emit;
	// the ridge at the pivot
	float pivot = exp(-pow(q.x / 0.05, 2.0)) * smoothstep(1.0, 0.6, abs(q.y));
	pad_col += keyc * pivot * 0.18;
	// printed legend: O (left) and I (right), cream ink; the lit I glows through
	vec2 pO = (p - rk_c) - vec2(-rk_half.x * 0.5, 0.0);
	vec2 pI = (p - rk_c) - vec2(rk_half.x * 0.5, 0.0);
	float d_o = abs(length(pO) - 1.45) - 0.23;
	float d_i = rbox(pI, vec2(0.0), vec2(0.28, 1.5), 0.25);
	float leg = max(cov(d_o, px), cov(d_i, px));
	float rubbed = smoothstep(0.25, 0.75, vnoise(sp * 3.1 + 2.0)) * wear * 0.3;
	vec3 ink = ink_color.rgb * (0.55 + 0.45 * clamp(dot(amb + keyc * 0.6, vec3(0.5)), 0.0, 1.2));
	vec3 ink_i = mix(ink, vec3(1.0, 0.8, 0.6), lamp_k * (1.0 - flip) * 0.7);
	float is_i = step(0.0, p.x - rk_c.x);
	pad_col = mix(pad_col, mix(ink, ink_i, is_i), leg * (1.0 - rubbed));
	pad_col *= 1.0 - 0.25 * press;
	pad_col *= 1.0 - 0.3 * dim;
	// dirt where the paddle meets the well
	pad_col *= 1.0 - 0.5 * grime * smoothstep(-0.9, 0.0, dP) * (0.5 + 0.8 * nz1);
	over(col, a, clamp(pad_col, 0.0, 1.0), m_pad);

	COLOR = vec4(clamp(col, 0.0, 1.0), clamp(a, 0.0, 1.0));
}
