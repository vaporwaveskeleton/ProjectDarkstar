shader_type canvas_item;
// An early-1980s US arcade coin door, drawn procedurally (D-13/D-14: no images). Resolution independent:
// every shape is a signed distance field in plate units (the plate is plate_size reference units,
// 56 x 80), edges are antialiased with fwidth, detail fades out below the pixel size and appears finer on
// a bigger display. A height field built from the SDFs gives the normal, the one cabinet light (screen
// glow from the hole + cool room fill, cabinet_material.gdshaderinc) does the shading, seeded procedural
// noise does the wear. The door is stamped sheet steel: satin black paint, dull zinc plating, and ONE
// bright place, the coin slot's lip. The lit plate is the reject / price plate. Wear is causal: where
// coins, keys, hands, thumbs and feet go.
#include "res://shaders/cabinet/cabinet_material.gdshaderinc"
// The painted steel's orange-peel, dents, rubbed-through scuffs and grime are a loom texture (ds_cab_steel).
#include "res://shaders/cabinet/cabinet_detail.gdshaderinc"

uniform vec2 plate_size = vec2(56.0, 80.0);
uniform vec2 rig_origin = vec2(0.0);
uniform float glow : hint_range(0.0, 1.0) = 0.0;
uniform float lamp_idle = 0.22;
uniform vec4 paint_color = vec4(0.055, 0.055, 0.063, 1.0);
uniform vec4 zinc_color = vec4(0.54, 0.55, 0.56, 1.0);
uniform vec4 lip_color = vec4(0.9, 0.91, 0.93, 1.0);
uniform vec4 bare_steel_color = vec4(0.43, 0.42, 0.39, 1.0);
uniform vec4 brass_color = vec4(0.71, 0.56, 0.27, 1.0);
uniform vec4 lens_color = vec4(0.88, 0.23, 0.07, 1.0);
uniform vec4 sticker_color = vec4(0.82, 0.78, 0.64, 1.0);
uniform float wear : hint_range(0.0, 1.0) = 0.8;
uniform float grime : hint_range(0.0, 1.0) = 0.95;
uniform float smudge : hint_range(0.0, 1.0) = 0.8;
uniform float dust : hint_range(0.0, 1.0) = 0.7;
uniform float finger_halo : hint_range(0.0, 1.0) = 0.85;
uniform float thumb_wear : hint_range(0.0, 1.0) = 0.85;
uniform float micro_texture : hint_range(0.0, 1.0) = 0.55;
uniform float door_edge_grime : hint_range(0.0, 1.0) = 0.85;
uniform float slot_polish : hint_range(0.0, 1.0) = 0.8;     // the entry plate rubbed bright round the slot by fingers feeding coins
uniform float lock_scratches : hint_range(0.0, 1.0) = 0.8;  // bright key scratches in a ring round the lock
uniform float low_grime : hint_range(0.0, 1.0) = 0.7;       // grime thickening toward the bottom of the door (feet, mop water)
uniform float lamp_spill = 0.6;
uniform float lamp_spill_radius = 13.0;
uniform vec2 slot_c = vec2(28.0, 20.0);
uniform vec2 slot_half = vec2(1.6, 9.0);
uniform vec2 plate_c = vec2(28.0, 46.0);       // the lit reject / price plate
uniform vec2 plate_half = vec2(23.5, 5.5);

const vec2 DOOR_C = vec2(28.0, 40.0);
const vec2 DOOR_H = vec2(27.6, 39.6);
const vec2 ENT_C = vec2(28.0, 20.0);
const vec2 ENT_H = vec2(8.7, 12.2);
const vec2 RET_C = vec2(31.0, 67.0);            // coin-return pocket
const vec2 RET_H = vec2(13.0, 5.0);
const vec2 FLAP_C = vec2(31.0, 65.8);           // its hinged flap
const vec2 FLAP_H = vec2(11.6, 2.7);
const vec2 LOCK_C = vec2(45.0, 15.0);           // offset toward a corner
const vec2 STK_C = vec2(11.5, 64.0);            // sticker remnant
const vec2 STK_H = vec2(4.6, 6.2);
const float RELIEF = 1.7;
// deliberate chips (x, y, size): few, unevenly spaced, none repeating: clusters at the LOWER corners (kicks), one
// on the top-left, a couple of strays; irregular so no row of them reads as stitching
const vec3 CHIPS[6] = vec3[6](vec3(2.3, 77.4, 2.4), vec3(7.4, 78.8, 0.95), vec3(52.6, 77.8, 2.7), vec3(55.0, 70.2, 1.2),
		vec3(3.1, 2.4, 1.5), vec3(29.7, 78.8, 0.7));

vec2 screw_c(vec2 p) {
	return vec2(p.x < 28.0 ? 6.0 : 50.0, p.y < 40.0 ? 6.0 : 74.0);
}

float cross_d(vec2 p, vec2 c) {
	float a = hash21(c + noise_seed) * 3.14159;     // seeded: no two slots line up
	vec2 l = rot2(p - c, a);
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
	// coin entry: a raised plated plate, the funnel and the slot with its lip
	h += 0.7 * rise(rbox(p, ENT_C, ENT_H, 3.4), 1.1);
	float dsl = rbox(p, slot_c, slot_half, 1.5);
	h -= 0.55 * (1.0 - smoothstep(0.0, 2.4, dsl));
	h -= 1.8 * rise(dsl, 0.35);
	h += 0.25 * rise(dsl - 0.5, 0.25) * (1.0 - rise(dsl, 0.3));
	// the lit plate: a dark housing ring and a slightly domed translucent plate
	float dpl = rbox(p, plate_c, plate_half, 1.6);
	h -= 0.5 * rise(dpl - 0.6, 0.3);
	h += 0.7 * rise(dpl, 1.6);
	// coin return: a recessed pocket under a hinged flap
	h -= 1.1 * rise(rbox(p, RET_C, RET_H, 1.8), 0.45);
	h += 0.75 * rise(rbox(p, FLAP_C, FLAP_H, 1.0), 0.5);
	// cylinder lock
	float dl = length(p - LOCK_C);
	h += 0.6 * rise(dl - 5.8, 0.9);
	h -= 0.2 * rise(dl - 4.0, 0.3);
	h -= 0.9 * rise(keyway_d(p), 0.3);
	// screws
	vec2 sc = screw_c(p);
	float ds = length(p - sc) - 2.2;
	h += 0.55 * rise(ds, 0.9);
	h -= 0.5 * rise(cross_d(p, sc), 0.2) * (1.0 - step(0.0, ds));
	return h;
}

void fragment() {
	vec2 p = UV * plate_size;
	vec2 rp = rig_origin + p;
	float px = max(max(fwidth(p.x), fwidth(p.y)), 1e-4);
	float dd = door_d(p);
	float cover = cov(dd, px);
	if (cover <= 0.0) {
		COLOR = vec4(0.0);
	} else {
		// ---- geometry masks
		float de = rbox(p, ENT_C, ENT_H, 3.4);
		float dsl = rbox(p, slot_c, slot_half, 1.5);
		float dpl = rbox(p, plate_c, plate_half, 1.6);
		float dret = rbox(p, RET_C, RET_H, 1.8);
		float dfl = rbox(p, FLAP_C, FLAP_H, 1.0);
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
		float m_lip = cov(dsl - 0.55, px) * (1.0 - m_slot);
		float m_lens = cov(dpl, px);
		float m_ring = cov(dpl - 0.7, px) * (1.0 - m_lens);

		// ---- normal from the height field
		float e = max(px * 0.8, 0.07);
		float hx = height(p + vec2(e, 0.0)) - height(p - vec2(e, 0.0));
		float hy = height(p + vec2(0.0, e)) - height(p - vec2(0.0, e));
		float h0 = height(p);
		float cr = 1.5;
		float avg = 0.25 * (height(p + vec2(cr, 0.0)) + height(p - vec2(cr, 0.0)) + height(p + vec2(0.0, cr)) + height(p - vec2(0.0, cr)));
		float cav = clamp((avg - h0) * 1.4, 0.0, 1.0);
		vec3 n = normalize(vec3(-hx / (2.0 * e) * RELIEF, -hy / (2.0 * e) * RELIEF, 1.0));

		// ---- base material: satin black paint on stamped sheet steel
		float nz1 = fbm(p, 1.3, px);
		float nz2 = fbm(p + 40.0, 3.1, px);
		vec3 col = paint_color.rgb * (0.9 + 0.35 * nz1);         // the satin is slightly uneven
		float metal = 0.0;
		float rough = 0.55;
		float spec_gain = 0.16;
		// painted-steel micro-texture: orange-peel grain in the normal and a fine 2D speckle
		float grain_fade = smoothstep(1.5, 3.5, 1.0 / (3.0 * px));
		vec2 gr = vec2(vnoise(p * 3.0 + 3.1), vnoise(p * 3.0 + 11.7)) - 0.5;
		n.xy += gr * 0.14 * grain_fade;
		// the steel itself (loom ds_cab_steel, mipmapped so it never aliases): dents, scuffs, grime in the low spots
		n.xy += detail_tilt(rp, 1.6 * micro_texture);
		col *= detail_tone(rp, 3.0 * micro_texture);

		// dull zinc-plated steel: the entry plate (brushed), lock collar, screws, flap
		float brush_fade = smoothstep(1.5, 3.5, 1.0 / (16.0 * px));
		float brush = vnoise(vec2(p.x * 0.5, p.y * 16.0)) - 0.5;
		brush += 0.5 * (vnoise(vec2(p.x * 1.4 + 9.0, p.y * 38.0)) - 0.5) * smoothstep(1.5, 3.5, 1.0 / (38.0 * px));
		vec3 zinc = zinc_color.rgb * (0.82 + 0.3 * nz2);
		float m_zinc = max(max(m_ent, m_lockc), max(m_screw * 0.9, m_flap));
		col = mix(col, zinc * (1.0 + brush * 0.4 * brush_fade * m_ent) * mix(1.0, trim_tone(rp, 1.8), m_ent), m_zinc);
		n.y += brush * 0.12 * brush_fade * m_ent;
		metal = max(metal, m_zinc * 0.75);
		rough = mix(rough, 0.58, m_zinc);
		col = mix(col, brass_color.rgb * 0.8, m_lockf);
		metal = max(metal, m_lockf * 0.75);
		rough = mix(rough, 0.5, m_lockf);
		col = mix(col, zinc * 0.55, m_cross);
		// the coin return: a dark pocket, the flap on top of it
		col = mix(col, vec3(0.012), m_ret * (1.0 - m_flap));
		metal = mix(metal, 0.0, m_ret * (1.0 - m_flap));
		rough = mix(rough, 0.9, m_ret * (1.0 - m_flap));
		col = mix(col, zinc * 0.72, m_flap);
		// black housing ring round the lit plate, deep gaps, the slot and keyway
		col = mix(col, vec3(0.02), m_ring);
		metal = mix(metal, 0.0, m_ring);
		float dark = max(m_slot, m_key);
		col = mix(col, vec3(0.008), dark);
		metal = mix(metal, 0.0, dark);
		rough = mix(rough, 0.9, dark);
		// the one bright place: the coin slot's lip, polished by decades of coins
		col = mix(col, lip_color.rgb, m_lip);
		metal = max(metal, m_lip);
		rough = mix(rough, 0.1, m_lip);

		// ---- causal wear: finger grease and bare-steel halo round the slot mouth, polished at the lip
		float jit = (nz1 - 0.5) * 1.6;
		float bare_halo = smoothstep(2.3, 0.7, dsl + jit) * (1.0 - m_lip) * (1.0 - dark) * finger_halo * m_ent;
		vec3 steel = min(bare_steel_color.rgb * (1.7 + 0.5 * nz2), vec3(1.0));
		col = mix(col, steel * (1.0 + brush * 0.3 * brush_fade), bare_halo * 0.85);
		rough = mix(rough, 0.45, bare_halo);
		float grease = smoothstep(6.5, 1.8, dsl + jit * 1.6) * (1.0 - m_lip) * (1.0 - dark) * finger_halo * (0.5 + 0.7 * nz2);
		col *= 1.0 - 0.5 * grease * m_ent * (1.0 - bare_halo * 0.5);
		rough = mix(rough, 0.34, grease * 0.7);

		// ---- label remnant: the bottom of a paper label torn off the door. A long ragged tear along the top, a
		// fibrous pale tear edge, a gummy dirty edge, the printing's last stripe, and a strip of yellowed
		// tape still holding the left corner down (translucent amber, its ends cut ragged).
		vec2 sl = rot2(p - STK_C, 0.14);
		float tear_line = sl.y + 2.6 - 2.6 * sl.x / STK_H.x * 0.5 + (fbm(p + 3.0, 3.6, px) - 0.5) * 3.4 + 1.2 * sin(sl.x * 1.9) * (vnoise(p * 1.5) - 0.3);
		float ds_ = max(rbox(sl, vec2(0.0), STK_H, 0.4), -tear_line);       // keep the part below the tear
		ds_ = max(ds_, dot(sl - STK_H, vec2(0.7071, 0.7071)) + 2.6 + (fbm(p + 9.0, 6.0, px) - 0.5) * 0.9);   // the torn lower-right corner
		ds_ += (fbm(p + 14.0, 5.0, px) - 0.5) * 0.35;
		float m_stk = cov(ds_, px) * (1.0 - 0.35 * smoothstep(0.6, 0.85, fbm(p + 22.0, 2.7, px)));
		float fibre = smoothstep(0.9, 0.0, abs(tear_line)) * m_stk;
		float glue = cov(ds_ - 1.4 - (nz2 - 0.5) * 1.2, px) * (1.0 - m_stk);
		glue *= 1.0 - dark;
		col = mix(col, vec3(0.045, 0.043, 0.04), glue * 0.55);
		rough = mix(rough, 0.35, glue * 0.5);
		// flat, faded off-white paper: no layers, no stripe; ghosted print lines, a dark gummy rim
		vec3 paper = sticker_color.rgb * (0.66 + 0.08 * nz1);
		paper = mix(paper, vec3(0.2, 0.17, 0.11), smoothstep(1.0, 0.0, -ds_) * 0.35);
		paper = mix(paper, vec3(0.78, 0.76, 0.7), fibre * 0.7);
		float ghost = max(cov(abs(sl.y - 3.2) - 0.35, px) * step(abs(sl.x + 0.3), 3.1), cov(abs(sl.y - 1.5) - 0.3, px) * step(abs(sl.x - 0.6), 2.3));
		ghost = max(ghost, cov(abs(sl.y - 4.9) - 0.3, px) * step(abs(sl.x + 0.8), 2.0));
		paper = mix(paper, paper * vec3(0.5, 0.48, 0.46), ghost * 0.85 * (0.7 + 0.3 * nz2));
		// the yellowed tape strip across the left corner
		vec2 tp = rot2(p - (STK_C + vec2(-1.8, -3.0)), -0.55);
		float tape_end = (vnoise(vec2(tp.y * 2.2, 5.0)) - 0.5) * 1.1;
		float tape_d = max(abs(tp.y) - 1.9, abs(tp.x + tape_end) - 5.2);
		float m_tape = cov(tape_d, px) * (1.0 - dark);
		vec3 tape_c = vec3(0.62, 0.45, 0.14);
		paper = mix(paper, paper * tape_c * 1.5 + vec3(0.03, 0.02, 0.0), m_tape * 0.8);
		float tape_over = max(m_tape - m_stk, 0.0);
		col = mix(col, vec3(0.1, 0.075, 0.03), tape_over * 0.55);   // the tape's tail on bare paint: dark, sticky
		col = mix(col, paper, m_stk * (1.0 - dark));
		col = mix(col, tape_c * 0.55, m_tape * 0.35 * m_stk);
		metal = mix(metal, 0.0, max(m_stk, m_tape) + glue);
		rough = mix(rough, 0.82, m_stk);

		// ---- chips: sharp-edged bare steel on the rim's top and left, the lower edge and the corners
		float chip = 0.0;
		float chip_edge = 0.0;
		float wsize = 0.8 + 1.3 * wear;
		for (int i = 0; i < 6; i++) {
			vec3 cd = CHIPS[i];
			float cn = vnoise(p * 3.1 + float(i) * 5.0) - 0.5;
			float asp = 0.6 + 1.3 * hash21(vec2(float(i), 3.7));
			vec2 cq = rot2(p - cd.xy, hash21(vec2(float(i), 9.1)) * 3.14159) * vec2(1.0, asp);
			float cdist = length(cq) + cn * 1.9 * cd.z - cd.z * wsize * 0.8;
			chip = max(chip, cov(cdist, px));
			chip_edge = max(chip_edge, cov(cdist - 0.22, px));
		}
		float paint_only = (1.0 - metal) * (1.0 - dark) * (1.0 - m_lens) * (1.0 - m_stk);
		chip *= paint_only;
		chip_edge = clamp(chip_edge - chip, 0.0, 1.0) * paint_only;
		vec3 bare = min(bare_steel_color.rgb * (1.5 + 0.5 * nz2), vec3(1.0));
		col *= 1.0 - 0.45 * chip_edge;
		col = mix(col, bare, chip);
		metal = mix(metal, 0.7, chip);
		rough = mix(rough, 0.4, chip);

		// scratches: arcs round the coin slot and the keyway (coins, keys), fine ones elsewhere
		vec2 lxy = normalize(cab_key_dir(rp).xy);
		float scr = max(scratches(p, slot_c, slot_half, 26.0, 4.5, px, lxy), scratches(p, LOCK_C, vec2(1.2), 16.0, 2.6, px, lxy));
		float fine_a = ridge(vnoise(vec2(p.x * 0.35 + p.y * 0.12, p.y * 5.5 - p.x * 1.8)), 0.965) * smoothstep(0.35, 0.7, vnoise(p * 0.5 + 5.0)) * 0.3;
		float fine_b = ridge(vnoise(vec2(p.x * 4.8 + p.y * 1.4, p.y * 0.3 - p.x * 0.2)), 0.97) * smoothstep(0.4, 0.75, vnoise(p * 0.45 + 21.0)) * 0.3;
		scr = max(scr, max(fine_a, fine_b)) * (0.4 + 0.6 * wear) * (1.0 - dark) * (1.0 - m_lens) * (1.0 - m_stk);
		col = mix(col, vec3(0.6, 0.6, 0.58), scr * 0.3 * (1.0 - metal));
		rough = mix(rough, rough + 0.12, scr);

		// ---- grime packed into recesses (ambient occlusion): door corners, screw heads, the slot's inner edge
		float corner_d = min(min(length(p - vec2(0.0, 0.0)), length(p - vec2(56.0, 0.0))), min(length(p - vec2(0.0, 80.0)), length(p - vec2(56.0, 80.0))));
		float corner_ao = smoothstep(11.0, 0.5, corner_d) * smoothstep(-0.5, -3.0, dd + 1.0);
		float screw_ao = smoothstep(2.4, 0.9, dsc) * (1.0 - smoothstep(0.0, 0.5, -dsc)) + smoothstep(1.2, 0.0, dsc) * 0.5;
		float slot_ao = smoothstep(1.6, 0.0, dsl) * (1.0 - m_slot);
		float corner = smoothstep(0.0, 1.0, cav);
		float g = clamp(grime * (corner * 1.7 + 0.45 * smoothstep(0.5, 0.15, abs(dd + 4.2)) + corner_ao * 0.9 + screw_ao * 0.9 + slot_ao * 0.9) * (0.55 + 0.9 * nz1), 0.0, 1.0);
		col = mix(col, vec3(0.03, 0.03, 0.032), g * (1.0 - m_lens * 0.7));
		rough = mix(rough, 0.85, g);
		float seam = (1.0 - smoothstep(0.0, 0.8, abs(dd + 2.6))) * grime * (0.6 + 0.6 * nz1) * (0.7 + 0.5 * p.y / plate_size.y);
		seam = clamp(seam * 1.3, 0.0, 0.95) * paint_only;
		col = mix(col, vec3(0.012, 0.01, 0.008), seam);
		rough = mix(rough, 0.95, seam);
		float film = grime * 0.2 * smoothstep(0.3, 0.8, nz1);
		col = mix(col, col * 0.8 + vec3(0.006), film * (1.0 - m_lens));

		// ---- hands: greasy fingerprints, smudged, round the slot and the lit plate, palm smears where hands rub
		vec2 pc = plate_c;
		float prints = max(max(print_blob(p, vec2(31.5, 26.0), 0.5, vec2(3.3, 4.2), px), print_blob(p, vec2(24.0, 13.5), -0.3, vec2(3.0, 3.8), px)),
				max(max(print_blob(p, vec2(33.0, 8.5), 0.9, vec2(2.8, 3.6), px), print_blob(p, vec2(22.5, 28.5), -0.7, vec2(3.0, 3.6), px)),
				max(max(print_blob(p, pc + vec2(8.0, -7.0), 0.4, vec2(3.0, 3.6), px), print_blob(p, pc + vec2(-9.0, 7.5), -0.5, vec2(3.2, 3.8), px)),
				max(print_blob(p, pc + vec2(2.0, 8.0), -0.4, vec2(3.2, 3.8), px), print_blob(p, vec2(37.0, 57.5), 0.9, vec2(3.0, 3.6), px)))));
		float palm = smoothstep(1.0, 0.2, length((p - vec2(25.0, 44.0)) / vec2(17.0, 11.0))) * (0.5 + 0.7 * nz1);
		palm = max(palm, smoothstep(1.0, 0.25, length((p - vec2(33.0, 67.0)) / vec2(14.0, 8.0))) * (0.5 + 0.7 * nz2));
		float smear = 0.7 + 0.6 * vnoise(p * vec2(5.0, 2.0) + 31.0);
		float smu = clamp(smudge * max(prints * 1.25, palm * 0.75) * smear, 0.0, 1.0) * (1.0 - dark);
		rough = mix(rough, mix(rough * 0.55, max(rough, 0.62), metal), smu);
		col *= 1.0 - 0.18 * smu * metal - 0.14 * smu * (1.0 - metal);
		// greyed satin where hands rub: round the slot, the lit plate and the return
		float rub = max(smoothstep(8.0, 1.5, dsl + jit), max(smoothstep(6.0, 0.5, dpl + jit), smoothstep(6.0, 0.5, dret + jit)));
		float grey = rub * (0.35 + 0.65 * nz2) * (1.0 - metal) * (1.0 - dark) * (1.0 - m_lens) * (1.0 - m_stk) * smudge;
		col = mix(col, vec3(0.2, 0.2, 0.205), grey * 0.55);
		rough = mix(rough, 0.35, grey * 0.6);

		// ---- dust settled on the TOP edges of the coin entry and the coin-return recess
		float top_e = smoothstep(0.35, 0.95, (ENT_C.y - p.y) / ENT_H.y);
		float band_e = smoothstep(-2.2, -0.2, de) * (1.0 - smoothstep(-0.1, 0.5, de)) * top_e * m_ent;
		float top_r = smoothstep(0.1, 0.9, (RET_C.y - p.y) / RET_H.y);
		float band_r = smoothstep(-1.6, -0.1, dret) * (1.0 - smoothstep(-0.1, 0.4, dret)) * (1.0 - m_flap) * top_r;
		float band_f = (1.0 - smoothstep(0.0, 0.9, abs(dfl + 0.4))) * smoothstep(0.2, 0.8, (FLAP_C.y - p.y) / FLAP_H.y) * m_flap;
		float dust_k = dust * max(max(band_e, band_r), band_f * 0.8) * (0.55 + 0.7 * fbm(p + 77.0, 2.6, px));
		col = mix(col, vec3(0.5, 0.48, 0.43), clamp(dust_k, 0.0, 0.85));
		rough = mix(rough, 0.9, dust_k);
		float dust_g = 0.07 * fbm(p + 77.0, 2.6, px) * smoothstep(0.1, 0.5, 0.35 - n.y) * (1.0 - dark);
		col = mix(col, vec3(0.5, 0.48, 0.43), dust_g);

		// ---- hinge side: a thin door-gap shadow where the door meets its frame
		float hinge_gap = (1.0 - smoothstep(0.0, 0.55, abs(dd + 0.95))) * smoothstep(14.0, 2.0, p.x) * smoothstep(0.0, 1.0, p.y) * (1.0 - smoothstep(78.0, 79.5, p.y));
		col = mix(col, vec3(0.0), hinge_gap * 0.85);

		// ---- lighting: one key (the screen glow from the hole side and above) + the cool room fill
		vec3 L = cab_key_dir(rp);
		vec3 V = vec3(0.0, 0.0, 1.0);
		vec3 Hh = normalize(L + V);
		float ndl = max(dot(n, L), 0.0);
		vec3 keyc = cab_key(rp);
		vec3 keyd = mix(vec3(dot(keyc, vec3(0.333))), keyc, 0.18);   // the satin paint stays black: warmth lives in the highlights
		vec3 lightc = cab_amb(rp) + keyd * ndl;
		float shin = max(2.0 / (rough * rough + 0.001) - 2.0, 1.0);
		float spec = pow(max(dot(n, Hh), 0.0), shin) * (1.0 - 0.55 * rough);
		vec3 diffuse = col * lightc;
		vec3 refl = reflect(-V, n);
		float t = refl.y * 0.5 + 0.47 + clamp((p.y - slot_c.y) / slot_half.y, -1.2, 1.2) * 0.18;
		float xr = refl.x + (p.x / plate_size.x - 0.5) * 0.5;
		vec3 env = environment(t, xr, 0.04 + 0.5 * rough);
		vec3 metal_col = col * env * (cab_amb(rp) + keyc * 0.8) * mix(1.1, 0.8, rough) + keyc * spec * spec_gain * col;
		vec3 lit = mix(diffuse + keyc * spec * spec_gain * 0.4, metal_col, metal);
		// the polished lip is the bright place: it catches the key hard
		lit += m_lip * keyc * (0.5 + 1.2 * pow(max(dot(n, Hh), 0.0), 18.0)) * lip_color.rgb;
		// finger-polished: a bright band on the entry plate round the slot, widest below it where thumbs push coins in
		float fpol = smoothstep(3.8, 0.9, dsl + jit * 0.6 - max(p.y - slot_c.y, 0.0) * 0.15) * (1.0 - m_lip) * (1.0 - dark) * m_ent * slot_polish;
		lit += lip_color.rgb * keyc * fpol * (0.35 + 0.9 * pow(max(dot(n, Hh), 0.0), 8.0));
		// the satin paint's faint clear sheen
		lit += (1.0 - metal) * keyc * pow(max(dot(n, Hh), 0.0), 7.0) * 0.03 * (1.0 - rough * 0.5) * (1.0 - dark);
		lit *= 1.0 - 0.6 * cav * (1.0 - m_lens);
		float spec_wide = pow(max(dot(n, Hh), 0.0), 10.0);
		lit += keyc * 0.5 * scr * (0.12 + 0.88 * spec_wide) * (0.3 + 0.7 * metal) * (1.0 - 0.6 * smu);

		// ---- the lit reject / price plate: a lamp behind a translucent lens, dulled where thumbs press
		vec2 thumb_c = plate_c + vec2(plate_half.x * 0.18, 0.4);
		vec2 tq = (p - thumb_c) / vec2(plate_half.x * 0.62, plate_half.y * 1.4);
		float thumb = smoothstep(1.0, 0.25, length(tq) + (nz2 - 0.5) * 0.5) * thumb_wear;
		float lamp = lamp_idle + (1.0 - lamp_idle) * glow;
		float core = smoothstep(1.15, 0.0, length((p - plate_c) / plate_half));
		vec3 lens = lens_color.rgb * (0.2 + 1.0 * lamp * (0.5 + 0.7 * core));
		lens += lens_color.rgb * 0.12 * lamp * smoothstep(0.6, 1.1, length((p - plate_c) / plate_half));
		lens = mix(lens, vec3(1.0, 0.9, 0.7), clamp(core * core * glow * 0.5, 0.0, 1.0));
		float lsm = clamp(smu + thumb, 0.0, 1.0);
		lens += (vec3(spec) * 0.35 + vec3(1.0, 0.95, 0.9) * pow(max(dot(n, Hh), 0.0), 40.0) * 0.12) * keyc * (1.0 - 0.9 * lsm);
		lens = mix(lens, vec3(dot(lens, vec3(0.33))) * vec3(0.78, 0.7, 0.66) + vec3(0.05, 0.03, 0.025), thumb * 0.8);
		lens = mix(lens, lens * 0.72 + vec3(0.04, 0.02, 0.015), smu * 0.85);
		lens *= 1.0 - 0.25 * cav;
		lit = mix(lit, lens, m_lens);

		// lamp spill: the red-orange glow lights the entry above, the door face round it and the nearest screw heads
		float spill = exp(-max(dpl, 0.0) / lamp_spill_radius) * lamp_spill * glow * (1.0 - m_lens);
		lit += lens_color.rgb * spill * (0.25 + 0.55 * metal + 0.4 * (1.0 - metal)) * (0.35 + 0.65 * ndl) * (1.0 - 0.8 * dark);
		vec2 to_plate = normalize(plate_c - sc);
		float sc_spill = exp(-max(length(plate_c - sc) - plate_half.x, 0.0) / (lamp_spill_radius * 1.8)) * glow * lamp_spill;
		float catch_light = smoothstep(1.0, 0.0, length(p - (sc + to_plate * 0.9))) * m_screw;
		lit += lens_color.rgb * catch_light * sc_spill * 2.2;

		// key scratches: a ring of bright arcs round the lock where the key missed, on the collar and the paint
		float dlk = length(p - LOCK_C);
		float kring = smoothstep(1.6, 2.6, dlk) * (1.0 - smoothstep(6.5, 9.5, dlk));
		float ks = scratches(p, LOCK_C, vec2(1.0), 30.0, 7.0, px, lxy) * kring * (1.0 - dark);
		lit = mix(lit, max(lit, lip_color.rgb * (keyc * 1.2 + 0.25)), clamp(ks * 3.0, 0.0, 1.0) * lock_scratches);
		// grime thickening toward the bottom: a gradient of dirt from the door's middle to its foot
		float lowg = smoothstep(plate_size.y * 0.45, plate_size.y, p.y) * (0.7 + 0.6 * nz1);
		lit = mix(lit, lit * vec3(0.38, 0.34, 0.3), clamp(lowg, 0.0, 1.0) * low_grime * (1.0 - 0.6 * m_lens));
		// dirt packed along the door's edge and into its corners (thickest at the bottom, where feet scuff),
		// ragged by the steel texture's own low spots
		float edge_in = 1.0 - smoothstep(0.0, 5.5, -dd);
		vec2 cq = abs(p - plate_size * 0.5) - plate_size * 0.5 + 7.0;
		float door_corner = smoothstep(0.0, 6.0, min(cq.x, cq.y) + 4.0);
		float low = 1.0 - smoothstep(0.6, 1.05, detail_luma(rp) / max(detail_mean, 1e-3));
		float packed = clamp((edge_in * (0.55 + 0.45 * p.y / plate_size.y) + door_corner * 0.8) * (0.45 + 0.9 * low), 0.0, 1.0);
		lit = mix(lit, lit * vec3(0.32, 0.29, 0.26), packed * door_edge_grime * detail_gain);

		COLOR = vec4(clamp(lit, 0.0, 1.0), cover);
	}
}
