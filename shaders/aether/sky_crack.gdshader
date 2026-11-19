shader_type canvas_item;
render_mode unshaded;
// Sky cracks (T4, ART-001 §16): glass, not lightning. Pass 4: irregular fracture CELLS (Voronoi
// polygons, no common centre — radial wedges read as glass shards / lens flare), foreshortened
// along the crystal sphere's curve. Each impact crazes a ragged patch of cells: most stay closed
// hairlines (PHOS_5 at low alpha, <= 0.5) whose pane bends the fog behind it by its own small
// offset; a few have fallen OPEN and show the Aether BEHIND the Aether — another place, not a
// lighter purple: a sea-green / sea-glass hue family (behind_a, behind_b), horizontal strata of
// its own fog drifting the opposite way to ours, its own sparse large warm stars, and a vast dim
// body (the reversed sphere) with a limb. Still below the lantern; no GAS, no CHOIR. The cracks
// catch the lantern: brighter nearest it. Colours arrive from GDScript (Pal); defaults are
// overwritten at runtime.

#include "res://shaders/aether/aether_common.gdshaderinc"

uniform sampler2D screen_tex : hint_screen_texture, filter_linear_mipmap;
uniform vec3 edge_col : source_color = vec3(0.66, 0.94, 0.82);
uniform vec3 behind_a : source_color = vec3(0.12, 0.49, 0.44);
uniform vec3 behind_b : source_color = vec3(0.5, 0.77, 0.82);
uniform vec3 behind_star : source_color = vec3(0.89, 0.87, 0.82);
uniform vec3 seam_col : source_color = vec3(0.66, 0.94, 0.82);
uniform vec3 floor_col : source_color = vec3(0.039, 0.039, 0.07);
uniform float amount : hint_range(0.0, 1.0) = 0.5;
uniform float time_s = 0.0;
uniform float drain = 0.0;
uniform vec2 sphere_c = vec2(620.0, 1200.0);   // local px (same space as the impacts)
uniform float sphere_r = 900.0;
uniform vec2 camera_offset = vec2(0.0);
uniform vec2 lantern_px = vec2(320.0, 202.0);
uniform vec4 impact_a = vec4(640.0, 300.0, 210.0, 1.3);   // local px xy, reach, seed
uniform vec4 impact_b = vec4(1010.0, 330.0, 160.0, 4.7);
uniform vec4 impact_c = vec4(330.0, 350.0, 120.0, 8.2);
uniform float line_alpha = 0.45;

// ✱ cell size as a fraction of an impact's reach; squash across the seam (foreshortening)
const float CELL_FRAC = 0.36;
const float FORE = 0.45;
// ✱ px the open part of a fallen cell sits inside its hairline rim
const float OPEN_INSET = 1.6;
// ✱ pass 5: share of closed patch cells drawn as dim panes; share of inner / fringe borders cracked
const float A_DIM_PANES = 0.16;
const float A_KEEP_INNER = 0.3;
const float A_KEEP_FRINGE = 0.18;
// ✱ how much of the other world a dim pane shows (alpha) and how dark it is
const float A_DIM_ALPHA = 0.5;
const float A_DIM_VALUE = 0.55;

varying vec2 v_px;

void vertex() {
	v_px = VERTEX;
}

vec2 tang_at(vec2 hit) {
	vec2 n = normalize(hit - sphere_c);
	return vec2(-n.y, n.x);
}

vec2 cell_jit(vec2 id, float sd) {
	return vec2(a_hash(id + sd * 1.9), a_hash(id.yx - sd * 2.7 + 3.3));
}

// Is cell `id` (centre `cc` in reach units) part of this impact's crazed patch? A ragged polygon:
// the patch boundary follows cell borders, never a circle (and no stray island cells far out).
float in_patch(vec2 id, vec2 cc, float sd) {
	return step(length(cc), 0.55 + 0.3 * a_hash(id * 1.7 + sd));
}

// One impact's fracture cells at local px `px`. x = border distance px (1e4 = none), y = open
// coverage (0..1), zw = this cell's refraction offset px (0 outside the patch); `dim` = dim-pane
// coverage (0..1).
vec4 fracture(vec2 px, vec4 im, out float dim) {
	dim = 0.0;
	float reach = im.z * amount;
	vec2 rel = px - im.xy;
	if (reach < 1.0 || length(rel) > reach * 1.15) {
		return vec4(1e4, 0.0, 0.0, 0.0);
	}
	vec2 tang = tang_at(im.xy);
	vec2 nrm = vec2(-tang.y, tang.x);
	float cs = reach * CELL_FRAC;
	vec2 lq = vec2(dot(rel, tang), dot(rel, nrm) / FORE) / cs;   // cell units
	// a slight warp: borders kink and cells vary in size (glass, not a honeycomb)
	lq += 0.3 * (vec2(a_noise(lq * 0.9 + im.w), a_noise(lq * 0.9 - im.w + 4.0)) - 0.5);
	vec2 uv = lq + im.w * 3.1;
	vec2 g = floor(uv);
	vec2 f = fract(uv);
	vec2 mr = vec2(0.0);
	vec2 mg = vec2(0.0);
	float md = 1e9;
	for (int j = -1; j <= 1; j++) {
		for (int i = -1; i <= 1; i++) {
			vec2 o = vec2(float(i), float(j));
			vec2 r = o + cell_jit(g + o, im.w) - f;
			float d = dot(r, r);
			if (d < md) {
				md = d;
				mr = r;
				mg = o;
			}
		}
	}
	vec2 ida = g + mg;
	// cell centre in reach units (undo the squash so the patch is round-ish on the sphere)
	vec2 cca = (lq + mr) * cs / reach;
	float pa = in_patch(ida, cca, im.w);
	// a few cells have fallen open: more of them near the impact, none at the patch rim
	float ho = a_hash(ida * 0.73 + im.w * 5.1);
	float opened = pa * step(0.66 + 0.4 * length(cca), ho);
	// pass 5: a few closed panes are DIM-filled — a deeper, darker look into the other world
	float dimmed = pa * (1.0 - opened) * step(1.0 - A_DIM_PANES, a_hash(ida * 2.31 + im.w * 1.7));
	float border = 1e9;
	float drawn = 1e9;
	for (int j = -1; j <= 1; j++) {
		for (int i = -1; i <= 1; i++) {
			vec2 o = mg + vec2(float(i), float(j));
			vec2 idb = g + o;
			vec2 r = o + cell_jit(idb, im.w) - f;
			vec2 dr = r - mr;
			if (dot(dr, dr) < 1e-6) {
				continue;
			}
			float e = dot(0.5 * (mr + r), normalize(dr));
			border = min(border, e);
			// which borders actually cracked (pass 5: sparse, so no cell is a closed polygon outline —
			// the pass 4 outline cells read as a honeycomb / wireframe UI): every rim of an OPEN cell;
			// A_KEEP_INNER of the closed-closed borders inside the patch; A_KEEP_FRINGE of the patch's
			// own boundary. Each kept border has its own weight (hairlines of varied width).
			float pb = in_patch(idb, (lq + r) * cs / reach, im.w);
			float ob = pb * step(0.66 + 0.4 * length((lq + r) * cs / reach), a_hash(idb * 0.73 + im.w * 5.1));
			float hb = a_hash(ida + idb + abs(ida - idb) * 5.7 + im.w);
			float keep = max(opened, ob) > 0.5 ? 1.0 : (pa + pb > 1.5 ? step(1.0 - A_KEEP_INNER, hb) : step(1.0 - A_KEEP_FRINGE, hb) * step(0.5, pa + pb));
			if (keep > 0.5) {
				float wgt = max(opened, ob) > 0.5 ? 1.0 : 0.45 + 1.2 * a_hash(ida * 3.3 + idb * 3.3 + im.w);
				drawn = min(drawn, e / wgt);
			}
		}
	}
	// border distances in px: the squash makes them anisotropic; average the two axes
	float px_k = cs * mix(FORE, 1.0, 0.55);
	float bpx = border * px_k;
	float line = drawn * px_k;
	// hairlines fade toward the patch fringe (the fracture dies out in the glass)
	line += 2.5 * smoothstep(0.55, 1.0, length(cca));
	float cover = opened * smoothstep(OPEN_INSET, OPEN_INSET + 1.0, bpx);
	dim = dimmed * smoothstep(OPEN_INSET, OPEN_INSET + 1.0, bpx);
	vec2 off = (vec2(a_hash(ida + 11.0), a_hash(ida.yx + 23.0)) - 0.5) * 7.0 * pa;
	return vec4(line, cover, off);
}

void fragment() {
	vec2 spx = SCREEN_UV * screen_size;
	float fw = max(fwidth(v_px.x), 0.2);
	vec4 imps[3] = vec4[3](impact_a, impact_b, impact_c);
	float line = 1e4;
	float gap = 0.0;
	float dim = 0.0;
	vec2 shard = vec2(0.0);
	for (int i = 0; i < 3; i++) {
		float dm;
		vec4 fr = fracture(v_px, imps[i], dm);
		line = min(line, fr.x);
		gap = max(gap, fr.y);
		dim = max(dim, dm);
		shard += fr.zw;
	}
	float hair = 1.0 - smoothstep(0.5 * fw, 1.6 * fw, line);
	vec3 inner = vec3(0.0);
	if (gap > 0.0 || dim > 0.0) {
		// the Aether behind the Aether: another place. Its parallax runs AGAINST ours and its medium
		// drifts the other way, in long horizontal strata (ours is curled and rising)
		vec2 bp = v_px * 0.7 - camera_offset * 0.9 + vec2(-time_s * 3.2, 0.0);
		vec2 q = vec2(bp.x / 120.0, bp.y / 16.0);
		float c = a_fbm(q + vec2(0.9 * a_fbm(q * 0.5 + vec2(time_s * -0.02, 3.0), 2), 0.0), 4);
		// deep sea-green below, sea-glass strata catching a light from above (that world's own sky)
		float lift = smoothstep(0.42, 0.72, c);
		inner = mix(behind_a * 0.22, behind_a * 0.7, smoothstep(0.2, 0.6, c));
		inner = mix(inner, behind_b * 0.78, lift * lift);
		// a vast dim body: the reversed sphere, filled and darker, with a sea-glass limb
		vec2 rev_c = sphere_c - vec2(0.0, 2.0 * sphere_r) + vec2(90.0, 70.0) - camera_offset * 0.9;
		float d2 = length(bp - rev_c) - sphere_r;
		inner = mix(inner, behind_a * 0.35, (1.0 - smoothstep(-2.0, 2.0, d2)) * 0.7);
		inner += seam_col * exp(-abs(d2) / 1.6) * 0.45;
		// its own stars: sparse, large, soft and warm (ours are small, cold and dense-ish)
		vec2 sg = bp / 18.0;
		vec2 sid = floor(sg);
		float sh = a_hash(sid + 4.2);
		float sr = length(sg - sid - 0.5) * 18.0;
		inner += behind_star * step(0.93, sh) * exp(-sr * sr * 0.18) * 0.55;
	}
	// the broken pane: fog behind each closed cell, displaced by that cell's offset
	vec3 bent = textureLod(screen_tex, SCREEN_UV + shard / screen_size, 0.0).rgb;
	float lamp = exp(-length(spx - lantern_px) / 260.0);
	vec3 col = bent;
	float a = step(0.01, length(shard));
	col = mix(col, inner, gap);
	a = max(a, gap);
	// a dim pane: the same other world, darker and only half seen through the cracked glass
	col = mix(col, inner * A_DIM_VALUE, dim * A_DIM_ALPHA * (1.0 - gap));
	a = max(a, dim * A_DIM_ALPHA);
	float la = hair * line_alpha * (0.55 + 0.45 * lamp);
	col = mix(col, edge_col * (1.0 + 0.6 * lamp), la);
	a = max(a, la);
	col = mix(col, vec3(a_luma(col)), drain);
	a *= 1.0 - a_loss(spx).z;
	col = max(col, floor_col);
	COLOR = vec4(col, clamp(a, 0.0, 1.0));
}
