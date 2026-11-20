shader_type canvas_item;
render_mode unshaded, blend_premul_alpha;
// The vast life the lantern hides (CH-3 lantern-down reveal, pass 8; ART-001 §16.6k, Q-T301..303).
// Up to three bodies far bigger than the frame drift close around the Vigil in the fog. With the
// lantern up they are there but unseen (the light washes them out); lantern down (`reveal` 1) shows
// them as dark silhouettes cut out against distant light behind them, rim-lit on the side facing
// that light, with slow rows of PHOS photophores and one head light that is brighter the more the
// head is turned toward the Vigil (it watches). Far layer only: never a hitbox, no light in the play
// layer, never black (body VOID tones above floor_col). No pulse above 0.2 Hz; `steady` holds the
// lights level (reduced motion / photosensitivity). The rect sits at the screen origin (screen px).
// Colours arrive from GDScript (Pal); defaults are overwritten. Every number here is ✱.

#include "res://shaders/aether/aether_common.gdshaderinc"

uniform vec3 body_col : source_color = vec3(0.075, 0.078, 0.157);    // VOID-1
uniform vec3 body_hi : source_color = vec3(0.114, 0.125, 0.251);     // far_silhouette
uniform vec3 glow_col : source_color = vec3(0.435, 0.357, 0.722);    // AETHER-2: the distant light
uniform vec3 rim_col : source_color = vec3(0.588, 0.557, 0.824);     // AETHER-3
uniform vec3 photo_col : source_color = vec3(0.384, 0.812, 0.659);   // PHOS-4
uniform vec3 head_col : source_color = vec3(0.659, 0.941, 0.816);    // PHOS-5
uniform vec3 floor_col : source_color = vec3(0.039, 0.039, 0.07);
uniform float time_s = 0.0;
uniform float reveal : hint_range(0.0, 1.0) = 0.0;
uniform float steady = 0.0;
uniform int count = 0;
// per body: xy = head (screen px), z = heading (rad), w = length (px)
uniform vec4 body_a[3];
// per body: x = max half-width (px), y = seed, z = facing the Vigil 0..1, w = presence 0..1
uniform vec4 body_b[3];
uniform vec2 light_dir = vec2(0.45, -0.89);   // toward the distant light (screen)

const float PHOTO_SPACING = 22.0;
const float BODY_ALPHA = 0.82;
const float GLOW_ALPHA = 0.5;

varying vec2 v_px;

void vertex() {
	v_px = VERTEX;
}

// Half-width of the body at u (0 = head … 1 = tail).
// A rounded bell of a head, a waist, then a long tapering trunk: an animal, not a slab.
float width_at(float u, float w, float sd) {
	float head = sqrt(clamp(u / 0.1, 0.0, 1.0));
	float bell = 1.0 - 0.32 * smoothstep(0.16, 0.3, u) * (1.0 - smoothstep(0.3, 0.5, u));
	return w * head * bell * pow(max(1.0 - u, 0.0), 0.85) * (0.9 + 0.1 * sin(u * 17.0 + sd));
}

// The spine's sideways offset at u: a slow undulation that grows toward the tail.
float spine_at(float u, float len, float sd, float t) {
	return len * 0.05 * sin(u * 8.2 - t * 0.35 + sd) * smoothstep(0.0, 0.35, u);
}

void fragment() {
	vec2 p = v_px;
	float t = time_s;
	vec4 acc = vec4(0.0);   // premultiplied
	for (int i = 0; i < 3; i++) {
		if (i >= count) {
			break;
		}
		vec4 A = body_a[i];
		vec4 B = body_b[i];
		float len = A.w;
		float w = B.x;
		float sd = B.y;
		float k = B.w * reveal;
		vec2 q = p - A.xy;
		if (k <= 0.001 || dot(q, q) > pow(len * 1.25 + w * 3.0, 2.0)) {
			continue;
		}
		float c = cos(A.z);
		float s = sin(A.z);
		// body frame: x along the heading (head at 0, body toward -x), y across
		vec2 b = vec2(q.x * c + q.y * s, -q.x * s + q.y * c);
		vec2 lb = vec2(light_dir.x * c + light_dir.y * s, -light_dir.x * s + light_dir.y * c);
		float u = -b.x / len;
		float ys = spine_at(clamp(u, 0.0, 1.0), len, sd, t);
		float v = b.y - ys;
		float wu = width_at(u, w, sd);
		wu += (a_noise(vec2(u * len / 18.0, sd + t * 0.05)) - 0.5) * 5.0 * step(0.0, u);
		// frilled mantle: a scalloped edge on both flanks whose ripples travel head to tail
		float frill = abs(sin(u * len / 26.0 - t * 0.5 + sd + step(0.0, v) * 1.3));
		wu += w * 0.16 * frill * smoothstep(0.04, 0.14, u) * (1.0 - smoothstep(0.75, 1.0, u));
		float inside_u = step(0.0, u) * step(u, 1.0);
		float d = abs(v) - wu;                           // < 0 inside the body
		float body = (1.0 - smoothstep(-1.2, 1.2, d)) * inside_u;
		// the distant light behind it: a long soft glow offset toward the light, so the body is cut out
		float gx = (b.x + 0.45 * len) / (0.75 * len);
		float side = sign(lb.y + 0.0001);
		float gy = (b.y - side * w * 0.9) / (w * 2.6);
		float glow = exp(-gx * gx - gy * gy);
		// rim on the flank facing the light
		float facing_l = clamp(sign(v) * lb.y, 0.0, 1.0);
		float rim = exp(-abs(d) / 2.4) * facing_l * inside_u * smoothstep(0.02, 0.12, u);
		// photophores: two loose rows on the flanks, a slow wave travelling head to tail (≤ 0.2 Hz)
		float idx = floor(u * len / PHOTO_SPACING + 0.5);
		float pu = clamp(idx * PHOTO_SPACING / len, 0.0, 1.0);
		float pw = width_at(pu, w, sd);
		float py = spine_at(pu, len, sd, t);
		float row = sign(v);
		vec2 pp = vec2(-pu * len, py + row * pw * (0.48 + 0.1 * a_hash(vec2(idx, sd + row))));
		float pd = length(b - pp);
		float pulse = mix(0.45 + 0.55 * sin(t * 1.2566 - idx * 0.7 + sd), 0.7, steady);
		float on = step(0.45, a_hash(vec2(idx * 1.7, sd * 3.1 + row))) * step(0.06, pu) * step(pu, 0.88);
		float photo = on * pulse * (exp(-pd * pd / 2.2) + 0.3 * exp(-pd / 4.0));
		// the head light: one, not a pair; brighter the more the head is turned toward the Vigil
		vec2 hp = vec2(-0.06 * len, spine_at(0.06, len, sd, t));
		float hd = length(b - hp);
		float head_l = (0.35 + 0.65 * B.z) * (1.4 * exp(-hd * hd / 8.0) + 0.45 * exp(-hd / 11.0));

		// composite this body over what is accumulated (premultiplied, back bodies first)
		vec4 layer = vec4(glow_col * glow * GLOW_ALPHA, glow * GLOW_ALPHA);
		vec3 sil = mix(body_col, body_hi, 0.35 + 0.3 * smoothstep(-wu, 0.0, -abs(v)));
		// translucent rib bands across the trunk (anatomy: the distant light shows through between them)
		float rib = smoothstep(0.7, 1.0, sin(u * len / 13.0 + sd)) * smoothstep(0.12, 0.25, u) * (1.0 - abs(v) / max(wu, 1.0));
		sil = mix(sil, glow_col, clamp(rib, 0.0, 1.0) * 0.35);
		float ba = body * BODY_ALPHA;
		layer = vec4(layer.rgb * (1.0 - ba) + sil * ba, layer.a * (1.0 - ba) + ba);
		vec3 add = rim_col * rim * 1.2 + (photo_col * photo * 0.9 + head_col * head_l) * body;
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
