shader_type canvas_item;
// One length of hazard tape on the coin door (PR C pass 2c): printed vinyl, not a vector stripe. The yellow vinyl has a
// slight sheen; the black stripes (diagonal, as printed) are a flat second ink laid a little out of register with
// a few pinholes; the long edges lift off the bezel in places (a bright raised rim and a shadow under it) and
// the adhesive edge has caught dirt; a stress crease crosses it where it bends over the slit's ridge. The flap that
// is peeled back shows its adhesive side: a dull sticky film with lint and grime. Procedural (D-13/D-14), lit by the one cabinet
// light, resolution independent, in rig units. CoinSlot places the rect and the segment; its peel and fall are untouched.
#include "res://shaders/cabinet/cabinet_material.gdshaderinc"

uniform vec2 rect_size = vec2(80.0, 60.0);
uniform vec2 rig_origin = vec2(0.0);
uniform vec2 seg_a = vec2(10.0, 30.0);
uniform vec2 seg_b = vec2(70.0, 30.0);
uniform float half_w = 5.5;
uniform float period = 6.0;                   // stripe period along the tape
uniform float face_up : hint_range(0.0, 1.0) = 1.0;     // 1 printed face, 0 adhesive side
uniform float lift_k : hint_range(0.0, 1.0) = 0.0;      // 1 free in the air (falling, hanging): big soft shadow
uniform float seed = 0.0;
uniform float crease_on : hint_range(0.0, 1.0) = 0.0;
uniform vec2 crease_c = vec2(40.0, 30.0);
uniform vec4 yellow : source_color = vec4(0.93, 0.745, 0.11, 1.0);
uniform vec4 black : source_color = vec4(0.086, 0.078, 0.078, 1.0);
uniform float sheen = 0.7;
uniform float misreg = 0.4;
uniform float edge_lift = 0.8;
uniform float dirt = 0.8;
uniform float crease_amt = 0.8;

float body_sd(vec2 p, vec2 a, vec2 t, float len, float tear) {
	vec2 nrm = vec2(-t.y, t.x);
	vec2 d = p - a;
	float u = dot(d, t);
	float v = dot(d, nrm);
	vec2 q = vec2(abs(u - len * 0.5 + tear * 0.5) - len * 0.5, abs(v) - half_w);
	return length(max(q, vec2(0.0))) + min(max(q.x, q.y), 0.0);
}

void over(inout vec3 col, inout float al, vec3 c, float k) {
	float oa = k + al * (1.0 - k);
	col = (c * k + col * al * (1.0 - k)) / max(oa, 1e-4);
	al = oa;
}

void fragment() {
	vec2 p = UV * rect_size;
	vec2 rp = rig_origin + p;
	float px = max(max(fwidth(p.x), fwidth(p.y)), 1e-4);
	vec2 ab = seg_b - seg_a;
	float len = max(length(ab), 0.001);
	vec2 t = ab / len;
	vec2 nrm = vec2(-t.y, t.x);
	vec2 d = p - seg_a;
	float u = dot(d, t);
	float v = dot(d, nrm);
	float tear = (vnoise(vec2(v * 0.9, seed * 3.1)) - 0.5) * 1.6;
	float sd = body_sd(p, seg_a, t, len, tear);
	float m_body = cov(sd, px);
	vec3 col = vec3(0.0);
	float al = 0.0;

	// shadow under the tape: tight along a stuck length, wide and offset when it is free
	vec2 off = vec2(0.5, 1.0) * (0.7 + 2.2 * lift_k);
	float ssd = body_sd(p - off, seg_a, t, len, tear);
	float blur = 0.7 + 2.6 * lift_k;
	over(col, al, vec3(0.0), exp(-max(ssd, 0.0) / blur) * (0.35 + 0.3 * lift_k) * (1.0 - m_body));
	// edges that stand off the bezel: a dark gap just outside, strongest in lifted stretches
	float lifted = smoothstep(0.35, 0.7, vnoise(vec2(u * 0.11 + sign(v) * 5.0, seed * 2.0 + 1.0))) * edge_lift;
	float gap = cov(abs(sd - 0.45) - 0.4, px) * step(0.0, sd) * lifted;
	over(col, al, vec3(0.0), gap * 0.55);

	// ---- the tape's surface normal: vinyl never lies perfectly flat
	float w1 = vnoise(p * 0.35 + seed) - 0.5;
	float w2 = vnoise(p * 0.9 + seed * 2.0) - 0.5;
	vec3 n = normalize(vec3(w1 * 0.3 + t.x * 0.0, w2 * 0.3, 1.0));
	vec3 L = cab_key_dir(rp);
	vec3 V = vec3(0.0, 0.0, 1.0);
	vec3 Hh = normalize(L + V);
	vec3 keyc = cab_key(rp);
	vec3 amb = cab_amb(rp);

	vec3 base;
	float gloss = sheen;
	if (face_up > 0.5) {
		// the yellow vinyl, then the black plate printed over it out of register
		vec3 y = yellow.rgb * (0.86 + 0.14 * fbm(p + seed, 0.5, px));
		vec2 pb = p - vec2(0.55, -0.35) * misreg * 2.0;
		vec2 db = pb - seg_a;
		float ub = dot(db, t);
		float vb = dot(db, nrm);
		float s = (ub + vb) / (period * 1.35);
		float fw = max(fwidth(s), 1e-4);
		float band = smoothstep(0.5 - fw, 0.5 + fw, fract(s)) * (1.0 - smoothstep(1.0 - fw, 1.0 + fw * 0.001, fract(s)));
		float edge_margin = 1.0 - smoothstep(half_w - 0.35, half_w - 0.1, abs(vb));   // ink stops just short of the edge
		float pin = smoothstep(0.9, 0.96, vnoise(p * 4.5 + seed * 5.0));              // pinholes in the black
		float ink = band * edge_margin * (1.0 - pin * 0.8);
		vec3 bk = black.rgb * (0.7 + 0.3 * vnoise(p * 1.3 + seed * 3.0));
		base = mix(y, bk, ink);
		gloss = sheen * mix(1.0, 1.3, ink);
	} else {
		// the adhesive side: dull sticky film, lint and grime
		float lint = smoothstep(0.62, 0.8, vnoise(p * 2.6 + seed * 4.0));
		float film = fbm(p * 1.0 + seed, 0.9, px);
		base = vec3(0.66, 0.6, 0.46) * (0.8 + 0.35 * film);
		base = mix(base, vec3(0.2, 0.17, 0.13), lint * 0.65);
		base = mix(base, vec3(0.1, 0.08, 0.06), smoothstep(0.7, 0.9, film) * 0.35);
		gloss = sheen * 0.7;
	}

	// ---- stress crease where it bends: a dark line, a pale stress line beside it, and the ink cracking
	if (crease_on > 0.5 && face_up > 0.5) {
		vec2 ct = rot2(t, 0.12);
		float cdist = dot(p - crease_c, ct) + (vnoise(vec2(v * 0.8, 4.0)) - 0.5) * 0.7;
		float dark = exp(-pow(cdist / 0.42, 2.0));
		float pale = exp(-pow((cdist - 0.95) / 0.5, 2.0));
		float crack = exp(-pow((cdist + 0.5) / 0.3, 2.0)) * smoothstep(0.5, 0.75, vnoise(vec2(v * 2.2, 8.0)));
		base = mix(base, base * 0.35, dark * 0.9 * crease_amt);
		base = mix(base, base * 1.35 + vec3(0.12, 0.11, 0.08), pale * 0.7 * crease_amt);
		base = mix(base, vec3(0.7, 0.62, 0.3), crack * 0.5 * crease_amt);
		n = normalize(n + vec3(0.0, 0.0, 0.0) + vec3(ct.x, ct.y, 0.0) * (pale - dark) * 0.35 * crease_amt);
	}

	// ---- lighting, with the vinyl's sheen: a broad soft highlight that wanders with the wrinkles
	float spec = pow(max(dot(n, Hh), 0.0), 18.0) * gloss * (0.5 + 0.9 * (vnoise(p * 0.22 + seed * 7.0)));
	vec3 lit = base * (amb + keyc * max(dot(n, L), 0.0) * 1.2) + keyc * spec * 0.32;
	// raised, lifted edge: a bright rim on the sides facing the light, a darker one on the sides facing away
	float eband = smoothstep(0.7, 0.0, -sd) * step(sd, 0.0);
	vec2 en = sign(v) * nrm;
	float facing = dot(en, normalize(L.xy + vec2(1e-4)));
	lit *= 1.0 + eband * lifted * (facing > 0.0 ? 0.55 * facing : 0.35 * facing);
	// dirt caught on the adhesive edge: a grimy band along both long edges, patchy; some specks just outside it
	float band_d = smoothstep(1.4, 0.0, -sd) * step(sd, 0.0);
	float patch_d = 0.35 + 0.9 * fbm(vec2(u * 1.0, v * 1.6) + seed * 9.0, 0.7, px);
	float grime = clamp(band_d * patch_d * dirt, 0.0, 0.85);
	lit = mix(lit, vec3(0.13, 0.1, 0.07), grime);
	float specks = smoothstep(0.72, 0.85, vnoise(vec2(u * 1.7, sd * 2.0) + seed * 5.0)) * smoothstep(1.3, 0.0, sd) * step(0.0, sd) * dirt;
	over(col, al, vec3(0.1, 0.085, 0.07), specks * 0.8);
	over(col, al, clamp(lit, 0.0, 1.0), m_body);

	COLOR = vec4(col, al);
}
