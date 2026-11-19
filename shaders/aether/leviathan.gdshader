shader_type canvas_item;
render_mode unshaded;
// The Presence (ART-001 §16; scale by occlusion): something the size of the sky sliding across it.
// It passes IN FRONT of the sphere line (the brass meridian simply ends at its edge) and blots out
// the stars, at a depth behind the jellies, cropped by the frame. Pass 3 anatomy — alive means
// asymmetric and curved: a long tapering head whose DORSAL CURVE climbs off the top of the frame,
// a long belly curve that passes ABOVE the lantern (never enclosing it), and one swept pectoral vane
// with a crisp, notched trailing edge running off-frame. Smooth back line with a few broken plates.
// Rim: BACKSCATTER from the fog behind it, a thin fog-coloured edge (rim_col, below the lantern).
// Flank lights follow the belly curve, staggered in size, spacing and phase (sequential drift,
// under 1 Hz, below the lantern). VOID / AETHER tones — never black. Never a collider.
// Colours arrive from GDScript (Pal); defaults are overwritten at runtime.

#include "res://shaders/aether/aether_common.gdshaderinc"

uniform vec3 body_col : source_color = vec3(0.11, 0.13, 0.25);
uniform vec3 plate_col : source_color = vec3(0.16, 0.19, 0.34);
uniform vec3 rim_col : source_color = vec3(0.59, 0.56, 0.82);
uniform vec3 light_col : source_color = vec3(0.38, 0.81, 0.66);
uniform vec3 floor_col : source_color = vec3(0.039, 0.039, 0.07);
uniform vec2 quad_size = vec2(2600.0, 900.0);
uniform float thickness = 300.0;
uniform float time_s = 0.0;
uniform float presence : hint_range(0.0, 1.0) = 1.0;
uniform float drain = 0.0;
uniform float max_alpha = 0.95;
uniform float rim_strength = 1.0;
uniform int edge_octaves = 3;

varying vec2 v_px;

void vertex() {
	v_px = VERTEX;
}

void fragment() {
	vec2 spx = SCREEN_UV * screen_size;
	float len = quad_size.x * 0.92;
	float x0 = quad_size.x * 0.04;
	float u = (v_px.x - x0) / len;     // 0 snout … 1 tail
	float uc = clamp(u, 0.0, 1.0);
	vec2 prof = a_lev_profile(v_px.x, time_s, quad_size, thickness);
	float cy = prof.x;
	float th = prof.y;
	float dy = v_px.y - cy;
	float n = a_fbm(v_px / 90.0 + vec2(time_s * 0.03, 0.0), edge_octaves);
	// asymmetric section: a deep back (climbing off the frame), a shallower belly
	float half_top = th * A_LEV_BACK;
	float half_bot = th * A_LEV_BELLY;
	// a few broken plates along the back: crisp raised steps, not scallops
	float cell = floor(uc * 16.0);
	float ph = a_hash(vec2(cell, 3.7));
	float in_cell = fract(uc * 16.0);
	float plate = step(0.55, ph) * step(0.12, in_cell) * step(in_cell, 0.12 + 0.6 * ph) * (2.5 + 3.0 * ph);
	half_top += plate * step(0.04, u);
	float sd = dy < 0.0 ? -dy - half_top : dy - half_bot;   // < 0 inside the body (px)
	sd += (n - 0.5) * 7.0;                                   // edge breathes into the fog, no lumps
	float body = (1.0 - smoothstep(-5.0, 3.0, sd)) * step(0.0, u) * step(u, 1.0);
	// the pectoral vane: rooted on the belly, swept down and back, crisp notched trailing edge
	float root_x = x0 + len * 0.12;
	vec2 rp = a_lev_profile(root_x, time_s, quad_size, thickness);
	vec2 root = vec2(root_x, rp.x + rp.y * A_LEV_BELLY - 6.0);
	vec2 fd = normalize(vec2(1.0, 0.62));
	vec2 fnrm = vec2(fd.y, -fd.x);                 // toward the tail / up
	vec2 fq = v_px - root;
	float fa = dot(fq, fd) / (thickness * 1.05);
	// the vane curves (swept further back toward its tip), its chord tapers, and its trailing edge
	// carries a few sharp V notches (worn, uneven), not a sawtooth
	float fo = dot(fq, fnrm) + fa * fa * thickness * 0.22;
	float chord = mix(thickness * 0.24, thickness * 0.02, pow(clamp(fa, 0.0, 1.0), 0.8));
	float vn = 1.0 - min(abs(fract(fa * 3.3 + 0.35) - 0.5) * 9.0, 1.0);
	chord -= thickness * 0.05 * vn * step(0.12, fa) * (0.6 + 0.4 * a_hash(vec2(floor(fa * 3.3 + 0.35), 2.0)));
	float vane = step(0.0, fa) * step(fa, 1.0) * step(-2.0, fo) * (1.0 - smoothstep(chord - 1.5, chord + 1.0, fo));
	vane *= 1.0 - body;
	float vane_rib = step(0.45, abs(fract(fa * 6.0) - 0.5)) * vane;
	float a = max(body * max_alpha, vane * 0.6);
	// colour: a smooth back, plate seams catching a little light
	vec3 col = body_col;
	float seam = (1.0 - smoothstep(0.4, 1.4, abs(sd + 9.0))) * step(dy, 0.0) * step(0.55, ph) * body;
	col = mix(col, plate_col, seam * 0.6);
	col = mix(col, plate_col, vane * 0.45 + vane_rib * 0.25);
	// rim: backscatter of the fog behind it, strongest along the belly (lit from below by the
	// lantern-warmed fog), broken by slow streaks; a thin edge just inside the silhouette
	float streak = 0.55 + 0.45 * smoothstep(0.3, 0.75, a_noise(vec2(spx.x * 0.03, time_s * 0.03)));
	float edge_d = min(abs(sd + 1.5), mix(1e4, abs(fo - chord + 1.5), vane));
	float rim = exp(-edge_d / 1.6) * mix(0.45, 1.0, step(0.0, dy)) * streak * rim_strength;
	col = mix(col, rim_col, clamp(rim, 0.0, 1.0) * 0.75);
	a = max(a, clamp(rim, 0.0, 1.0) * 0.8 * step(-1.0, -sd) * step(0.0, u));
	// flank lights: following the belly curve, staggered size / spacing / phase, drifting in
	// sequence (2.2 rad/s ≈ 0.35 Hz), under the lantern
	float cells = 46.0;
	float idx = floor(uc * cells);
	float lh = a_hash(vec2(idx, 9.1));
	float lh2 = a_hash(vec2(17.3, idx));
	float lcx = (idx + 0.5 + (lh2 - 0.5) * 0.5) / cells;
	vec2 lp_prof = a_lev_profile(x0 + lcx * len, time_s, quad_size, thickness);
	float inset = 14.0 + 16.0 * lh;                              // two loose rows
	float ly = lp_prof.x + lp_prof.y * A_LEV_BELLY - inset;
	float lx = (uc - lcx) * len;
	float ldist = length(vec2(lx, v_px.y - ly));
	float lsize = 1.0 + 1.6 * lh2;
	float pulse = 0.3 + 0.7 * pow(0.5 + 0.5 * sin(time_s * 2.2 - idx * 0.55 + lh * 0.9), 2.0);
	float on = step(0.32, lh) * step(0.05, u) * step(u, 0.8) * step(0.5, lp_prof.y);
	float cell_w = len / cells;
	float win = 1.0 - smoothstep(0.2, 0.42, max(abs(lx), abs(v_px.y - ly)) / cell_w);   // no cell seams
	float lamp = (exp(-ldist / lsize) + 0.22 * exp(-ldist / (lsize * 3.0))) * pulse * on * win;
	col = mix(col, light_col * 1.2, clamp(lamp, 0.0, 1.0));
	a = max(a, clamp(lamp, 0.0, 1.0) * 0.9);
	vec4 loss = a_loss(spx);
	a *= presence * (1.0 - loss.y);
	col = mix(col, vec3(a_luma(col)), drain * 0.5);
	col = max(col, floor_col);
	COLOR = vec4(col, clamp(a, 0.0, 1.0));
}
