shader_type canvas_item;
render_mode unshaded;
// The entity's presence (ART-001 §16): the only true black. A WOUND in the picture, not a blob:
// a hard torn edge (ridged fray at up to four scales and angular sheared bites; never a face —
// N4), one ruled cut terraced into slanted steps, one impossible sharp inner corner.
// Pass 5 rule: NO BLACK STROKES OUTSIDE THE TRUE-BLACK MASS (black linework reaching out read as
// brambles / growth / limbs). The only black written here is the mass itself (s < 0). The edge
// fractures are on the WORLD's side of the edge instead: hairline gaps in the world's glaze (a deep
// cold VOID, never black) whose edges catch the fog's own light (a thin lighter rim, VOID_5, far
// below the lantern), and a few small FRAGMENTS lifted out showing the flat cold VOID middle band
// behind. The crazing is a connected polygon network (cell borders), thinning outward, that stays
// inside 0 < s < A_ENT_CRACK_BAND * grow (inside the mid loss step) and stops on that contour as a
// hairline: no line ever leaves the mass as a free-ending appendage (N7). No outline, no glow and
// no halo on the mass: inside is exactly vec4(0,0,0,1). The world losing its layers around it is
// done by the layers that read the entity mask (a_loss), not here.

#include "res://shaders/aether/aether_common.gdshaderinc"

uniform float radius = 40.0;           // px
uniform vec2 half_size = vec2(200.0);  // half of the quad, px
uniform float time_s = 0.0;
uniform float seed = 0.0;
uniform int edge_octaves = 4;
uniform float grow = 0.0;              // 0..1 edge-fracture growth (drain)
uniform float crack_cells = 22.0;      // ✱ crazing density: cell side = (2π / crack_cells) / 4 radii
uniform vec3 gap_col : source_color = vec3(0.075, 0.078, 0.157);    // VOID_1: the cold behind a crack
uniform vec3 rim_col : source_color = vec3(0.337, 0.376, 0.561);    // VOID_5: glaze lit from inside
uniform vec3 void_hi : source_color = vec3(0.235, 0.27, 0.455);     // VOID_4: with gap_col, the flat
// cold VOID middle band the fog's far step shows (mix(VOID_1, VOID_4, 0.22), as in aether_fog_band)
// ✱ share of crazing cells lifted out as fragments, and the band fraction they start at
const float A_ENT_FRAGMENTS = 0.22;
const float A_ENT_FRAGMENT_FROM = 0.45;
// ✱ pass 6 (B2): how much of a cell the cracks have eaten at the mass (fraction of the cell side);
// it falls to 0 at the band's outer edge (pow curve A_ENT_ERODE_K), so the tiles shrink inward
const float A_ENT_ERODE = 0.42;
const float A_ENT_ERODE_K = 1.3;

vec2 cell_pt(vec2 id) {
	return vec2(a_hash(id + seed * 3.7), a_hash(id.yx + seed * 1.3 + 7.1));
}

// x = distance (normalised units) to the nearest DRAWN border of the crazing (cells of side
// `cell`; borders thin out with s: crazing propagates from the mass, fewer cracks further out),
// y = distance to the nearest border of any kind, z = hash of the cell the point is in.
vec3 crack_dist(vec2 p, float cell, float s_frac) {
	vec2 uv = p / cell;
	vec2 g = floor(uv);
	vec2 f = fract(uv);
	vec2 mr = vec2(0.0);
	vec2 mg = vec2(0.0);
	float md = 1e9;
	for (int j = -1; j <= 1; j++) {
		for (int i = -1; i <= 1; i++) {
			vec2 o = vec2(float(i), float(j));
			vec2 r = (o + cell_pt(g + o) - f) * cell;
			float d = dot(r, r);
			if (d < md) {
				md = d;
				mr = r;
				mg = o;
			}
		}
	}
	vec2 ida = g + mg;
	float best = 1e9;
	float any_b = 1e9;
	for (int j = -1; j <= 1; j++) {
		for (int i = -1; i <= 1; i++) {
			vec2 o = mg + vec2(float(i), float(j));
			vec2 idb = g + o;
			vec2 r = (o + cell_pt(idb) - f) * cell;
			vec2 dr = r - mr;
			if (dot(dr, dr) < 1e-7) {
				continue;
			}
			float bd = dot(0.5 * (mr + r), normalize(dr));
			any_b = min(any_b, bd);
			// symmetric per-border hash: some borders never crack, more of them further out
			float hb = a_hash(ida + idb + abs(ida - idb) * 7.3 + seed);
			if (hb < 0.06 + 0.3 * s_frac) {
				continue;
			}
			best = min(best, bd);
		}
	}
	return vec3(best, any_b, a_hash(ida * 1.37 + seed * 5.1));
}

void fragment() {
	if (radius < 0.5) {
		discard;
	}
	vec2 rel = (UV - 0.5) * half_size * 2.0;
	vec2 p = rel / radius;
	float s = a_entity_shape(p, seed, time_s, edge_octaves);
	bool inside = s < 0.0;
	if (inside) {
		// the mass: the only black in the game
		COLOR = vec4(0.0, 0.0, 0.0, 1.0);
	} else {
		float band = A_ENT_CRACK_BAND * grow;
		bool drawn = false;
		vec4 c = vec4(0.0);
		if (!inside && band > 0.0 && s < band) {
			float s_frac = s / band;
			float cell = 6.2831853 / crack_cells * 0.25;
			vec3 cd = crack_dist(p, cell, s_frac);
			float dn = cd.x;
			// pass 6 (B2): a GRADIENT OF DISINTEGRATION, not a uniform pale mosaic. s_frac = 1 at the
			// band's outer edge (the world: large intact tiles, sparse hairline cracks), 0 at the mass.
			// Inward every border erodes (er: the cracks widen into deep cold VOID gaps), so the tiles
			// shrink, their lit rims dim, and the last of them are specks on the VOID.
			float er = A_ENT_ERODE * cell * pow(1.0 - s_frac, A_ENT_ERODE_K);
			// half-width in px: 0.9 at the mass, a hairline at the band edge, where the crazing stops
			// along the loss contour (a hairline end on a contour, never a tapering thorn)
			float hw = mix(0.9, 0.35, s_frac) / radius;
			float rim_w = 0.7 / radius;
			// the glaze's own light: dims inward toward the mass, and fades just before the outer edge so
			// the band never ends on a lit contour
			float lit = mix(0.15, 1.0, smoothstep(0.0, 0.75, s_frac)) * (1.0 - 0.7 * smoothstep(0.88, 1.0, s_frac));
			if (cd.z < A_ENT_FRAGMENTS && s_frac > A_ENT_FRAGMENT_FROM) {
				// a fragment lifted out: the flat cold VOID behind it, its broken edge catching light
				float e = cd.y;
				c = e < rim_w ? vec4(rim_col, 0.85 * lit + 0.15) : vec4(mix(gap_col, void_hi, 0.22), 1.0);
				drawn = true;
			} else if (dn < hw || cd.y < er) {
				c = vec4(gap_col, 1.0);   // the gap itself: deep cold, never black
				drawn = true;
			} else if (dn < hw + rim_w || cd.y < er + rim_w) {
				c = vec4(rim_col, 0.5 * lit);   // the gap's edge lit from inside the glaze
				drawn = c.a > 0.02;
			}
		}
		if (!drawn) {
			discard;
		}
		COLOR = c;
	}
}
