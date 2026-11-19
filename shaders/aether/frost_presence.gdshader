shader_type canvas_item;
render_mode unshaded;
// The Pale Marches Presence (ZONES-001 §2.3, T1): "a frost-drifting thing like a migrating ice
// shelf, with a slow heartbeat of light". Far layer only; never a hitbox; never black.
// Slice B art pass: a vast translucent ICE SHELF lit from within. Anatomy, front to back:
//   frost haze  — a soft drifting veil calving off the front (beyond it, never a hard edge);
//   thin edge   — where the shelf thins it is translucent (the fog and stars show through it), with a
//                 broken frost catch-light along it (never one continuous ruled line);
//   facets      — the body is built of flat tilted ice PLANES (an anisotropic jittered cell field,
//                 plates lying along the front), each with its own value and its own slope of light,
//                 so it reads as cut glass, not as strata;
//   ridges      — pressure ridges are BROKEN seams on some plate boundaries only (per-seam hash and
//                 a length mask): irregular, angular, never parallel, never closed rings;
//   crevasses   — a second, coarser cell field stretched back from the front: dark cracks whose
//                 cores carry the heartbeat;
//   pockets     — some plates hold a glassy light pocket, lit along the plate's own slope (light
//                 caught inside a pane: one side lit, never a round dot in a cell — no eyes);
//   heartbeat   — a lub-dub of PHOS glass light leaving a heart deep in the body, travelling through
//                 the crevasses and pockets (one beat per beat_period, two soft bumps: well under the
//                 3 Hz flicker cap of WARP-001 §4.5, no flash). `steady` holds it level.
// Lantern up: a vague mass in the fog, only the light near the heart. Lantern down (`reveal` 1): its
// full lit pattern. Veiled near the lantern's pool (no light in the play layer); the entity
// subtracts it like every far layer. Colours arrive from GDScript (Pal); defaults are overwritten.
// Every number here is ✱.

#include "res://shaders/aether/aether_common.gdshaderinc"

uniform vec3 body_col : source_color = vec3(0.11, 0.13, 0.25);    // far_silhouette (VOID)
uniform vec3 pearl_col : source_color = vec3(0.91, 0.86, 0.85);   // AETHER-4 pearl
uniform vec3 frost_col : source_color = vec3(0.73, 0.72, 0.68);   // BONE-3 frost rim
uniform vec3 light_col : source_color = vec3(0.38, 0.81, 0.66);   // PHOS-4 glass light
uniform vec3 floor_col : source_color = vec3(0.039, 0.039, 0.07);
uniform vec2 quad_size = vec2(1700.0, 1000.0);
uniform float front_y = 640.0;          // local y of the calving front's mean line
uniform vec2 heart = vec2(470.0, 360.0); // local px: where the heartbeat starts
uniform float time_s = 0.0;
uniform float beat_period = 4.0;        // s per beat (lub-dub)
uniform float wave_speed = 150.0;       // px/s the beat travels along the veins
uniform float presence : hint_range(0.0, 1.0) = 1.0;
uniform float reveal : hint_range(0.0, 1.0) = 0.0;
uniform float drain = 0.0;
uniform float steady = 0.0;             // 1 = no pulse (reduced motion / photosensitivity)
uniform float max_alpha = 0.66;
uniform int edge_octaves = 3;
uniform vec2 lantern_px = vec2(320.0, 202.0);
uniform float lantern_r = 120.0;

// ✱ ice plate cell size (local px, along / across the front) and the crevasse field's.
const vec2 PLATE = vec2(96.0, 34.0);
const vec2 CREVASSE = vec2(150.0, 330.0);
// ✱ how far the plate field is warped (cell units): kinks the plate edges so no two plates match and
// the field never reads as tiles or a honeycomb.
const float PLATE_WARP = 0.55;

varying vec2 v_px;

void vertex() {
	v_px = VERTEX;
}

// The calving front's y at local x: straight facets (ice), on a slow swell (alive). A line, never a
// closed shape (pareidolia rule, ART-001 §16.6c).
float front(float x, float t) {
	float c = floor(x / 96.0);
	float f = fract(x / 96.0);
	float facet = mix(a_hash(vec2(c, 4.2)), a_hash(vec2(c + 1.0, 4.2)), f) * 34.0;
	float swell = 30.0 * sin(x / 310.0 + t * 0.05) + 12.0 * sin(x / 137.0 - t * 0.031);
	return front_y + swell - facet;
}

// One heartbeat over phase 0..1: two soft bumps (lub, dub), then rest.
float beat(float ph) {
	return exp(-pow((ph - 0.08) / 0.05, 2.0)) + 0.55 * exp(-pow((ph - 0.27) / 0.06, 2.0));
}

vec2 cell_point(vec2 c, float sd) {
	return c + 0.04 + 0.92 * vec2(a_hash(c + vec2(sd, 1.3)), a_hash(c + vec2(7.1, sd)));
}

// Jittered cell field: x = distance to the nearest point, y = second nearest minus nearest (seam
// distance), zw = the nearest cell's id; `rel` = offset to the nearest point, `id2` = the second
// nearest cell (the seam between them is identified by both). Plates are flat polygons.
vec4 cells(vec2 q, float sd, out vec2 rel, out vec2 id2) {
	vec2 i = floor(q);
	float d1 = 1e4;
	float d2 = 1e4;
	vec2 id = i;
	id2 = i;
	rel = vec2(0.0);
	for (int y = -1; y <= 1; y++) {
		for (int x = -1; x <= 1; x++) {
			vec2 c = i + vec2(float(x), float(y));
			vec2 r = cell_point(c, sd) - q;
			float d = dot(r, r);
			if (d < d1) {
				d2 = d1;
				id2 = id;
				d1 = d;
				id = c;
				rel = r;
			} else if (d < d2) {
				d2 = d;
				id2 = c;
			}
		}
	}
	d1 = sqrt(d1);
	d2 = sqrt(d2);
	return vec4(d1, d2 - d1, id);
}

void fragment() {
	vec2 p = v_px;
	vec2 spx = SCREEN_UV * screen_size;
	float t = time_s;
	float n = a_fbm(p / 130.0 + vec2(t * 0.004, 0.0), edge_octaves);
	float s = front(p.x, t) - p.y + (n - 0.5) * 9.0;     // depth into the shelf (px); < 0 outside
	float body = smoothstep(-2.5, 3.5, s);
	// the quad's own edges dissolve into the fog (the frame crops it; drift never shows an edge)
	float fade_q = smoothstep(0.0, 260.0, p.x) * smoothstep(0.0, 200.0, quad_size.x - p.x) * smoothstep(0.0, 200.0, p.y);
	// deep in the body it sinks back into the far fog (vast and far, not a wall)
	float sink = 1.0 - 0.55 * smoothstep(60.0, 300.0, s);
	float near_front = 1.0 - smoothstep(20.0, 260.0, s);

	// --- facets: tilted plates of ice, each its own value and slope -------------------------------
	vec2 rel;
	vec2 id2;
	vec2 warp = PLATE_WARP * (vec2(a_noise(p / 160.0 + 3.0), a_noise(p / 160.0 + 11.0)) - 0.5)
		+ 0.18 * (vec2(a_noise(p / 47.0 + 5.0), a_noise(p / 47.0 + 17.0)) - 0.5);
	// plates break smaller toward the calving front (fragmenting as it calves)
	float frag = mix(0.8, 1.0, smoothstep(0.0, 300.0, s));
	vec4 pc = cells(p / (PLATE * frag) + warp, 2.7, rel, id2);
	vec2 pid = pc.zw;
	float h_val = a_hash(pid + vec2(0.31, 5.7));
	float h_dir = a_hash(pid + vec2(9.2, 0.77)) * 6.2831853;
	// the plane's own slope: light runs across the plate (a tilted pane), clamped to the plate
	float slope = clamp(0.5 + 1.1 * dot(-rel, vec2(cos(h_dir), sin(h_dir))), 0.0, 1.0);
	// frosted grain: the surface is rough rime, not polished CG panels
	float grain = a_noise(p / 5.0 + pid * 3.1) * 0.6 + a_noise(p / 13.0) * 0.4;
	float val = 0.05 + 0.42 * h_val + 0.34 * (slope - 0.5) + 0.2 * near_front + 0.08 * (grain - 0.5);
	vec3 ice = mix(body_col, pearl_col, clamp(val, 0.03, 0.75));
	// thick ice holds a cold glacier cast (teal-blue light inside), thin bright plates stay pearl
	vec3 glacier = mix(body_col, light_col, 0.32);
	vec3 col = mix(ice, mix(glacier, pearl_col, 0.25), 0.4 * (1.0 - slope) * (1.0 - h_val * 0.6));

	// --- pressure ridges: SOME plate boundaries only (a per-seam hash), broken along their length --
	float seam_h = a_hash(floor(pid + id2) * 0.5 + vec2(13.1, 2.9) + abs(pid - id2) * 7.0);
	float seam_on = step(0.62, seam_h) * smoothstep(0.42, 0.58, a_noise(p / 31.0 + seam_h * 9.0));
	float seam_w = 0.05 + 0.04 * a_noise(p / 23.0);
	float seam = 1.0 - smoothstep(seam_w * 0.3, seam_w, pc.y);
	float flank = 1.0 - smoothstep(seam_w, seam_w * 3.0, pc.y);
	float seam_k = seam_on * smoothstep(2.0, 18.0, s);
	// the crest of compressed bright ice, its shadowed flank on the plate turned away
	col = mix(col, frost_col, seam * seam_k * 0.6);
	col = mix(col, body_col, (flank - seam) * seam_k * 0.3 * (1.0 - slope));
	// every other boundary is only a value change between planes (cut glass), plus a faint hairline
	col = mix(col, pearl_col, (1.0 - seam_on) * (1.0 - smoothstep(0.0, 0.025, pc.y)) * 0.08);

	// --- crevasses: coarse cracks running back from the front ------------------------------------
	vec2 crel;
	vec2 cid2;
	vec4 cc = cells(p / CREVASSE + 0.4 * warp, 6.1, crel, cid2);
	float crack_w = 0.03 + 0.02 * a_noise(p / 51.0 + 4.0);
	float crack_k = step(0.3, a_hash(cc.zw + vec2(2.2, 8.8))) * smoothstep(8.0, 50.0, s);
	float ridge = 1.0 - smoothstep(0.0, crack_w, cc.y);        // 1 on the crack's centre
	col = mix(col, body_col, ridge * crack_k * 0.65);

	// --- thin edge: translucent where the shelf thins, a broken frost catch-light along it ---------
	float thin = smoothstep(0.0, 70.0, s);
	float rim = exp(-abs(s - 2.0) / 3.6) * step(-3.0, s);
	float rim_break = smoothstep(0.3, 0.62, a_noise(vec2(p.x / 23.0, 3.0)) * 0.7 + a_noise(vec2(p.x / 7.0, 9.0)) * 0.3);
	rim *= mix(0.25, 1.0, rim_break);
	col = mix(col, frost_col, clamp(rim, 0.0, 1.0) * 0.75);
	// translucent: thin ice and clear panes let the fog and stars through; each plate its own clarity
	float a = body * max_alpha * sink * mix(0.3, 1.0, thin) * (0.62 + 0.38 * h_val);
	a = max(a, clamp(rim, 0.0, 1.0) * 0.5);

	// --- frost haze calving off the front: a soft drifting veil beyond the edge -------------------
	vec2 hz = vec2(p.x / 60.0 - t * 0.06, s / 26.0 + t * 0.02);
	float haze = exp(s / 70.0) * step(s, 0.0) * (0.4 + 0.6 * a_fbm(hz, 2));
	col = mix(col, mix(frost_col, pearl_col, 0.5), haze * (1.0 - body) * 0.8);
	a = max(a, haze * 0.3);

	// --- the heartbeat: glass light from the heart, through crevasses and pockets -----------------
	float d = length(p - heart);
	float ph = fract((t - d / wave_speed) / beat_period);
	float b = mix(0.3 + 0.7 * beat(ph), 0.42, steady);
	float reach = mix(240.0, 1500.0, reveal);                 // lantern down: the full pattern
	float lit = 1.0 - smoothstep(reach * 0.5, reach, d);
	// veins: the light runs in the crevasse cores (lantern down: more of them carry it)
	float core = 1.0 - smoothstep(0.0, crack_w * 0.45, cc.y);
	float vein_k = mix(step(0.62, a_hash(cc.zw + vec2(5.5, 1.1))), 1.0, reveal);
	float vein = core * crack_k * vein_k * smoothstep(12.0, 60.0, s);
	// pockets: light caught inside some plates, along the plate's slope (one side of the pane lit)
	float pocket_k = step(mix(0.8, 0.62, reveal), a_hash(pid + vec2(3.3, 3.9)));
	float pocket = pocket_k * smoothstep(0.35, 0.95, slope) * smoothstep(0.0, 0.08, pc.y) * smoothstep(20.0, 90.0, s);
	// a deep diffuse glow in the ice around the heart (lit from within)
	float glow = exp(-pow(d / mix(190.0, 440.0, reveal), 2.0)) * smoothstep(20.0, 160.0, s);
	// pockets keep a faint steady glow everywhere (lit from within); the beat brightens them near the heart
	float light = ((vein * mix(0.75, 1.0, reveal) + pocket * 0.55 + glow * mix(0.3, 0.42, reveal)) * b * lit
		+ pocket * 0.16 * mix(1.0, 1.6, reveal)) * body;
	col = mix(col, light_col, clamp(light, 0.0, 1.0));
	a = max(a, clamp(light, 0.0, 1.0) * 0.85);

	// no light in the play layer: veiled to a vague mass near the lantern's pool
	float dl = length(spx - lantern_px);
	a *= mix(0.12, 1.0, smoothstep(lantern_r * 1.1, lantern_r * 2.4, dl));
	vec4 loss = a_loss(spx);
	a *= fade_q * presence * (1.0 - loss.y);
	col = mix(col, vec3(a_luma(col)), drain * 0.5);
	col = max(col, floor_col);
	COLOR = vec4(col, clamp(a, 0.0, 1.0));
}
