shader_type canvas_item;
// One arcade pushbutton on the Cabinet's control panel (PR C pass 2, Q-T34), drawn procedurally (D-13/D-14:
// no images). Resolution independent: signed distance fields in face units (rig units, the ColorRect is
// `face_size` big), edges antialiased with fwidth, a height field gives the normal, the one cabinet light
// (cabinet_material.gdshaderinc) does the shading. From the outside in: a soft shadow on the panel, the grime
// packed against the base, the focus halo (a physical selector: the ring lights), a chrome/zinc bezel ring, the dark
// well the cap travels in, and the translucent plastic cap with a lamp inside it. The cap is polished smooth
// where thumbs land, scuffed round that. Pressed: the cap drops and is darker. Hover: the lamp lifts.
#include "res://shaders/cabinet/cabinet_material.gdshaderinc"

uniform vec2 face_size = vec2(40.0, 24.0);
uniform vec2 rig_origin = vec2(0.0);
uniform vec2 cap_c = vec2(20.0, 9.5);
uniform vec2 cap_half = vec2(12.0, 7.0);
uniform float cap_r = 3.5;
uniform float press : hint_range(0.0, 1.0) = 0.0;
uniform float hover_k : hint_range(0.0, 1.0) = 0.0;
uniform float focus_k : hint_range(0.0, 1.0) = 0.0;
uniform float lamp : hint_range(0.0, 1.0) = 0.0;
uniform float dim : hint_range(0.0, 1.0) = 0.0;
uniform vec4 plastic_color : source_color = vec4(0.75, 0.16, 0.06, 1.0);
uniform vec4 lamp_color : source_color = vec4(1.0, 0.42, 0.14, 1.0);
uniform vec4 ring_color : source_color = vec4(0.54, 0.55, 0.56, 1.0);
uniform vec4 focus_color : source_color = vec4(1.0, 0.85, 0.2, 1.0);
uniform float wear : hint_range(0.0, 1.0) = 0.8;
uniform float grime : hint_range(0.0, 1.0) = 0.95;
uniform float thumb_wear : hint_range(0.0, 1.0) = 0.85;
uniform float micro_texture : hint_range(0.0, 1.0) = 0.55;
uniform float variant = 0.0;                    // per-button seed offset: no two caps wear alike

const float GAP = 0.45;                         // the dark well between cap and ring
const float RING_W = 1.5;                       // the bezel ring's width
const float RELIEF = 1.6;

float d_cap(vec2 p, float k) {
	float s = 1.0 - 0.05 * k;
	return rbox(p, cap_c + vec2(0.0, 0.7 * k), cap_half * s, cap_r * s);
}

float d_well(vec2 p) {
	return rbox(p, cap_c, cap_half + GAP, cap_r + GAP);
}

float d_ring(vec2 p) {
	return rbox(p, cap_c, cap_half + GAP + RING_W, cap_r + GAP + RING_W);
}

float height(vec2 p) {
	float dc = d_cap(p, press);
	float dw = d_well(p);
	float dr = d_ring(p);
	float u = clamp(dw / RING_W, 0.0, 1.0);
	float h = 1.1 * sin(u * 3.14159) * step(dr, 0.0) * step(0.0, dw);   // the ring: a rounded bead
	h -= 0.7 * step(dw, 0.0);                                            // the well
	float depth = clamp(-dc / 5.5, 0.0, 1.0);
	float dome = 1.7 * (1.0 - (1.0 - depth) * (1.0 - depth));
	h += step(dc, 0.0) * (0.4 + dome - 0.55 * press);
	return h;
}

// Composite colour `c` with coverage `k` over (col, a), straight alpha.
void over(inout vec3 col, inout float a, vec3 c, float k) {
	float oa = k + a * (1.0 - k);
	col = (c * k + col * a * (1.0 - k)) / max(oa, 1e-4);
	a = oa;
}

void fragment() {
	vec2 p = UV * face_size;
	vec2 rp = rig_origin + p;
	float px = max(max(fwidth(p.x), fwidth(p.y)), 1e-4);
	float dc = d_cap(p, press);
	float dw = d_well(p);
	float dr = d_ring(p);
	float m_cap = cov(dc, px);
	float m_well = cov(dw, px);
	float m_ring = cov(dr, px);
	vec3 col = vec3(0.0);
	float a = 0.0;
	vec2 sp = p + vec2(variant * 7.3, variant * 3.1);

	// ---- normal from the height field
	float e = max(px * 0.8, 0.07);
	float hx = height(p + vec2(e, 0.0)) - height(p - vec2(e, 0.0));
	float hy = height(p + vec2(0.0, e)) - height(p - vec2(0.0, e));
	vec3 n = normalize(vec3(-hx / (2.0 * e) * RELIEF, -hy / (2.0 * e) * RELIEF, 1.0));
	vec3 L = cab_key_dir(rp);
	vec3 V = vec3(0.0, 0.0, 1.0);
	vec3 Hh = normalize(L + V);
	vec3 keyc = cab_key(rp);
	float ndl = max(dot(n, L), 0.0);
	float nz1 = fbm(sp, 1.8, px);
	float nz2 = fbm(sp + 31.0, 4.2, px);

	// ---- the soft shadow the whole button throws on the panel (the key is the tube, above it: it falls down)
	float dsh = rbox(p - vec2(0.0, 1.3), cap_c, cap_half + GAP + RING_W, cap_r + GAP + RING_W);
	over(col, a, vec3(0.0), exp(-max(dsh, 0.0) / 1.7) * 0.6 * (1.0 - m_ring));

	// ---- grime packed against the base: an oily dark halo that the cleaning never reaches
	float halo = smoothstep(2.8, 0.0, dr) * (1.0 - m_ring) * grime * (0.45 + 0.9 * nz1);
	over(col, a, vec3(0.035, 0.03, 0.026), clamp(halo * 0.8, 0.0, 0.85));
	float crumbs = smoothstep(0.62, 0.8, vnoise(sp * 3.4 + 4.0)) * smoothstep(2.2, 0.3, dr) * (1.0 - m_ring) * grime;
	over(col, a, vec3(0.2, 0.18, 0.15), crumbs * 0.5);

	// ---- the focus halo: the selector lights the ring (a bright band just outside it, and a glow)
	float band = cov(abs(dr - 1.0) - 0.45, px) * (1.0 - m_ring);
	float glow = exp(-max(dr - 1.4, 0.0) / 2.4) * 0.4 * (1.0 - m_ring);
	over(col, a, focus_color.rgb, clamp((band + glow) * focus_k, 0.0, 1.0));

	// ---- the bezel ring: dull zinc-plated steel, scuffed, with a bright polished edge where it is caught
	float u = clamp(dw / RING_W, 0.0, 1.0);
	float rough = 0.5;
	vec3 zinc = ring_color.rgb * (0.78 + 0.38 * nz2);
	float streak = vnoise(sp * vec2(2.2, 21.0)) - 0.5;
	zinc *= 1.0 + 0.22 * streak * micro_texture;
	float edge_polish = smoothstep(0.55, 0.0, abs(u - 0.5)) * wear * smoothstep(0.35, 0.8, nz1);
	zinc = mix(zinc, ring_color.rgb * 1.5, edge_polish * 0.5);
	vec3 refl = reflect(-V, n);
	float t_env = refl.y * 0.5 + 0.47;
	vec3 env = environment(t_env, refl.x + (p.x / face_size.x - 0.5) * 0.5, 0.05 + 0.45 * rough);
	float spec_r = pow(max(dot(n, Hh), 0.0), mix(14.0, 40.0, edge_polish));
	vec3 keyn = mix(vec3(dot(keyc, vec3(0.333))), keyc, 0.3);   // plated steel reads grey, not gold, under the warm key
	vec3 ring_lit = zinc * env * (cab_amb(rp) + keyn * 0.8) * 1.25 + zinc * (cab_amb(rp) + keyn * ndl) * 0.5 + keyn * spec_r * 0.7 * zinc;
	float ring_ao = smoothstep(0.35, 0.0, u) + smoothstep(0.65, 1.0, u) * 0.55;   // dirt packed along both seams
	ring_lit *= 1.0 - 0.55 * grime * ring_ao * (0.5 + 0.8 * nz1);
	over(col, a, ring_lit, m_ring);

	// ---- the well: black, with the cap's own shadow in it (it deepens as the cap goes down)
	over(col, a, vec3(0.006, 0.005, 0.006), m_well);

	// ---- the cap: translucent plastic with a lamp inside it
	vec2 cc = cap_c + vec2(0.0, 0.7 * press);
	vec2 cq = (p - cc) / (cap_half * (1.0 - 0.05 * press));
	float core = smoothstep(1.25, 0.0, length(cq));
	float rim = smoothstep(-3.0, -0.1, dc);
	float lamp_k = clamp(lamp + 0.1 * hover_k + 0.35 * focus_k, 0.0, 1.0);
	vec3 plastic = plastic_color.rgb * (0.9 + 0.2 * nz1);
	vec3 diffuse = plastic * (cab_amb(rp) * 0.9 + keyc * ndl * 0.5);
	vec3 emit = lamp_color.rgb * lamp_k * (0.4 + 0.9 * core + 0.35 * rim) * mix(vec3(1.0), plastic * 1.6 + 0.15, 0.4);
	emit = mix(emit, vec3(1.0, 0.93, 0.78), core * core * lamp_k * 0.5);
	// worn thumb-polish: smooth, clear and glossy where thumbs land; scuffed and frosted round it
	vec2 tq = (p - (cap_c + cap_half * vec2(0.1, 0.25))) / (cap_half * vec2(0.62, 0.52));
	float tn = length(tq) + (fbm(sp + 9.0, 3.2, px) - 0.5) * 0.5;
	float polish = smoothstep(1.0, 0.3, tn) * thumb_wear;
	float scuff_zone = smoothstep(1.9, 0.9, tn) * (1.0 - polish) * wear;
	float scuffs = ridge(vnoise(vec2(sp.x * 3.1 + sp.y * 1.2, sp.y * 7.0 - sp.x * 2.0)), 0.9) * scuff_zone;
	float frost = scuff_zone * (0.3 + 0.7 * smoothstep(0.3, 0.8, nz2));
	diffuse = mix(diffuse, diffuse * 1.25 + 0.03, frost * 0.5);
	diffuse += vec3(0.35, 0.33, 0.3) * scuffs * (0.3 + 0.6 * lamp_k);
	emit *= 1.0 + 0.18 * polish;
	emit *= 1.0 - 0.2 * frost;
	float shine_pow = mix(26.0, 70.0, polish);
	float spec_c = pow(max(dot(n, Hh), 0.0), shine_pow) * mix(0.35, 0.9, polish);
	spec_c += 0.1 * pow(max(dot(n, Hh), 0.0), 8.0) * (1.0 - frost * 0.7);
	vec3 cap_lit = diffuse + emit + keyc * spec_c;
	// pressed: the cap is further down in the well, darker
	cap_lit *= 1.0 - 0.28 * press;
	cap_lit *= 1.0 - 0.3 * dim;
	// edge dirt where the cap meets the well
	cap_lit *= 1.0 - 0.45 * grime * smoothstep(-1.2, 0.0, dc) * (0.5 + 0.8 * nz1);
	over(col, a, clamp(cap_lit, 0.0, 1.0), m_cap);

	COLOR = vec4(clamp(col, 0.0, 1.0), clamp(a, 0.0, 1.0));
}
