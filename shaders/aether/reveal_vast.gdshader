shader_type canvas_item;
render_mode unshaded, blend_premul_alpha;
// The vast life the lantern hides (CH-3 lantern-down reveal; ART-001 §16.6k, Q-T301..303, pass 2
// Q-T311..313). Lantern down, the presenter crushes the fog to near-VOID (`night`, Q-T310); what is
// left is a dim distant AETHER glow on the horizon and, in front of it, up to three bodies far
// bigger than the Vigil: a small skull on a long ribbed neck, a deep body with two pairs of trailing
// fins, a tapering tail with trailing tendrils, dorsal spines. Each is near-VOID with a directional
// rim on the edges facing the distant glow (pass 8 c), rows of PHOS portholes (paired along the body,
// single on the lit flank of the neck; on the near one a light is a sizeable fraction of the Vigil: the
// scale cue) and no head light (pass 8 c: nothing where an eye would be). The neck bends so the head
// turns toward the Vigil (`bend`), and the front portholes brighten the more it faces it. One body
// crosses in front of the horizon glow so its whole outline shows.
// Far layer only: never a hitbox, no light in the play layer, never black (floor_col), gone inside
// the entity's loss. Photophores pulse in a 0.2 Hz wave; `steady` holds them (reduced motion /
// photosensitivity). The rect sits at the screen origin (screen px). Colours arrive from GDScript
// (Pal); defaults are overwritten. Every number here is ✱.

#include "res://shaders/aether/aether_common.gdshaderinc"

uniform vec3 body_col : source_color = vec3(0.039, 0.039, 0.07);     // VOID-0..1 silhouette
uniform vec3 body_hi : source_color = vec3(0.075, 0.078, 0.157);     // VOID-1
uniform vec3 glow_col : source_color = vec3(0.588, 0.557, 0.824);    // AETHER-3: the distant light
uniform vec3 rim_col : source_color = vec3(0.502, 0.769, 0.816);     // AETHER-5: hard rim
uniform vec3 photo_col : source_color = vec3(0.384, 0.812, 0.659);   // PHOS-4 portholes
uniform vec3 floor_col : source_color = vec3(0.039, 0.039, 0.07);
uniform float time_s = 0.0;
uniform float reveal : hint_range(0.0, 1.0) = 0.0;
uniform float steady = 0.0;
uniform int count = 0;
uniform vec2 horizon_px = vec2(420.0, 78.0);
uniform vec2 horizon_r = vec2(300.0, 130.0);
// per body: xy = head (screen px), z = body heading (rad), w = length (px)
uniform vec4 body_a[3];
// per body: x = max half-width (px), y = seed, z = neck bend -1..1 (head turned toward the Vigil), w = light scale
uniform vec4 body_b[3];
// per body: x = facing the Vigil 0..1, y = presence 0..1
uniform vec4 body_c[3];

const float GLOW_HDR = 2.4;
const float RIM_HDR = 1.7;
const float PHOTO_HDR = 2.2;
const float PORT_SPACING = 0.035;   // portholes per unit u

varying vec2 v_px;

void vertex() {
	v_px = VERTEX;
}

// Half-width profile (units of w) at u (0 = head … 1 = tail tip): skull, ribbed neck, deep body, tail.
float profile(float u, float len) {
	float skull = 0.34 * sqrt(clamp(u / 0.06, 0.0, 1.0));
	float neck = 0.17 + 0.035 * abs(sin(u * len / 8.0));
	float f = mix(skull, neck, smoothstep(0.05, 0.1, u));
	f = mix(f, 1.0, smoothstep(0.26, 0.42, u));
	f *= 1.0 - 0.96 * smoothstep(0.62, 1.0, u);
	return f * step(0.0, u) * step(u, 1.0);
}

// The spine's sideways offset: the neck bends toward the Vigil, the rest sways slowly.
float spine(float u, float len, float bend, float sd, float t) {
	float neck = bend * len * 0.16 * pow(max(1.0 - u / 0.32, 0.0), 2.0);
	float sway = len * 0.025 * sin(u * 6.0 - t * 0.3 + sd) * smoothstep(0.3, 0.8, u);
	return neck + sway;
}

void fragment() {
	vec2 p = v_px;
	float t = time_s;
	vec4 acc = vec4(0.0);   // premultiplied
	// the distant light on the horizon: dim, wide, behind everything
	vec2 hq = (p - horizon_px) / horizon_r;
	float hz = exp(-dot(hq, hq) * 1.6);
	acc = vec4(glow_col * GLOW_HDR * hz * 0.85, hz * 0.85) * reveal;
	for (int i = 0; i < 3; i++) {
		if (i >= count) {
			break;
		}
		vec4 A = body_a[i];
		vec4 B = body_b[i];
		vec4 C = body_c[i];
		float len = A.w;
		float w = B.x;
		float sd = B.y;
		float ls = B.w;
		float k = C.y * reveal;
		vec2 q = p - A.xy;
		if (k <= 0.001 || dot(q, q) > pow(len * 1.5 + w * 2.0, 2.0)) {
			continue;
		}
		float c = cos(A.z);
		float s = sin(A.z);
		vec2 b = vec2(q.x * c + q.y * s, -q.x * s + q.y * c);   // x along the heading, head at 0
		float u = -b.x / len;
		float uc = clamp(u, 0.0, 1.0);
		float v = b.y - spine(uc, len, B.z, sd, t);
		float wu = w * profile(u, len);
		// two pairs of fins sweeping back from the body, swaying slowly
		for (int f = 0; f < 2; f++) {
			float u0 = f == 0 ? 0.42 : 0.58;
			float fu = (u - u0) / 0.17;
			float fin = clamp((u - u0) / 0.025, 0.0, 1.0) * (1.0 - clamp(fu, 0.0, 1.0)) * step(0.0, fu);
			wu += w * (f == 0 ? 0.8 : 0.55) * fin * fin * (0.85 + 0.15 * sin(t * 0.5 + float(f) * 2.0 + sd));
		}
		// dorsal spines on the neck and back, on the side facing the light
		vec2 to_l = normalize(horizon_px - A.xy + vec2(0.001));
		float lit_side = sign(-to_l.x * s + to_l.y * c + 0.0001);   // + = the light is on the +y flank
		float spines = min(w * 0.05, 5.0) * pow(max(sin(u * len / 4.0), 0.0), 10.0) * step(0.08, u) * step(u, 0.62);
		wu += spines * step(0.0, v * lit_side);
		float d = abs(v) - wu;                                      // < 0 inside
		float body = (1.0 - smoothstep(-0.8, 0.8, d)) * step(0.0, u) * step(u, 1.0);
		// trailing tendrils past the tail
		float tend = 0.0;
		for (int j = 0; j < 3; j++) {
			float off = (float(j) - 1.0) * w * 0.12;
			float ut = (u - 0.9) / 0.6;
			float wave = w * 0.18 * sin(u * len / 40.0 - t * 0.7 + float(j) * 1.7 + sd) * ut;
			float tw = mix(1.6, 0.5, clamp(ut, 0.0, 1.0));
			tend = max(tend, (1.0 - smoothstep(tw * 0.5, tw, abs(v - off - wave))) * step(0.0, ut) * (1.0 - smoothstep(0.6, 1.0, ut)));
		}
		body = max(body, tend * 0.9);
		// pass 8 c (Q-T402): a directional rim. Only edges that face the glow catch it, per pixel; the rim
		// is widest near the head and thins toward the tail; far from the glow the fog swallows it.
		vec2 lp = normalize(horizon_px - p + vec2(0.001));
		float lby = -lp.x * s + lp.y * c;
		float facing_l = smoothstep(0.05, 0.6, sign(v) * lby);
		float rim_w = mix(2.8, 0.5, uc) * facing_l;
		float rim = (1.0 - smoothstep(0.0, max(rim_w, 0.01), abs(d + 0.4))) * facing_l * step(0.0, u) * step(u, 1.0);
		rim += tend * 0.25 * facing_l;
		rim *= clamp(hz * 2.6 + 0.12, 0.0, 1.0);
		// the far ends sink into the fog
		body *= 1.0 - 0.7 * smoothstep(0.6, 1.0, u);
		// paired portholes along both flanks of the body (a slow 0.2 Hz wave runs head to tail)
		float sp = max(PORT_SPACING, 13.0 * ls / len);   // big lights sit further apart
		float idx = floor(u / sp + 0.5);
		float pu = idx * sp;
		float pw = w * profile(pu, len);
		float pv = spine(clamp(pu, 0.0, 1.0), len, B.z, sd, t) + sign(v) * pw * 0.42;
		vec2 pp = vec2(-pu * len, pv);
		float lsz = ls * mix(0.55, 1.0, smoothstep(0.2, 0.32, pu));   // smaller on the neck
		float pd = length(b - pp) / lsz;
		float pulse = mix(0.75 + 0.25 * sin(t * 1.2566 - idx * 0.5 + sd), 0.9, steady);
		// pass 8 c (Q-T401): no head light (it sat where an eye would be). The rows run up the neck on the
		// lit flank only (single, never a pair near the head), paired along the body; the front lights
		// brighten the more the head faces the Vigil (it is watching).
		float neck_row = step(0.18, pu) * step(pu, 0.3) * step(0.0, v * lit_side);
		float row = max(step(0.3, pu) * step(pu, 0.72), neck_row);
		float watch = mix(0.5 + 1.0 * C.x, 1.0, smoothstep(0.3, 0.45, pu));
		float photo = row * pulse * watch * (exp(-pd * pd / 1.6) + 0.35 * exp(-pd / 3.0));

		vec3 sil = mix(body_col, body_hi, 0.25 * smoothstep(-wu, 0.0, -abs(v)));
		vec4 layer = vec4(sil * body, body);
		vec3 add = rim_col * RIM_HDR * rim + photo_col * PHOTO_HDR * photo * max(body, 0.4);
		layer.rgb += add;
		layer.a = max(layer.a, clamp(a_luma(add), 0.0, 1.0));
		layer *= k;
		acc = vec4(acc.rgb * (1.0 - layer.a) + layer.rgb, acc.a * (1.0 - layer.a) + layer.a);
	}
	if (acc.a <= 0.0005) {
		discard;
	}
	// life flees the entity: gone inside its loss steps like every far layer
	acc *= 1.0 - a_loss(p).y;
	// never below the floor (the only true black is the entity): un-premultiply, clamp, re-premultiply
	vec3 col = max(acc.rgb / max(acc.a, 0.0001), floor_col);
	COLOR = vec4(col * acc.a, acc.a);
}
