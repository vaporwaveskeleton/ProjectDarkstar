shader_type canvas_item;
render_mode unshaded;
// The entity's presence (ART-001 §16): the only true black. A WOUND in the picture, not a blob:
// a hard torn edge (ridged fray at up to four scales and angular sheared bites; never a face —
// N4), one ruled cut terraced into slanted steps, one impossible sharp inner corner, and (pass 4,
// N7: never a limb) EDGE FRACTURES instead of filaments: thin black cracks crazing the world's
// surface along the loss edge like crazed glaze, growing with drain: a connected polygon network
// (cell borders), thinning outward, that starts on the mass and stays inside
// 0 < s < A_ENT_CRACK_BAND * grow — inside the mid loss step — and stops on that contour as a
// hairline. No line ever leaves the mass as a free-ending appendage. No outline, no rim, no glow and no halo of its own: inside is
// exactly vec4(0,0,0,1), outside is discarded. The world losing its layers around it is done by
// the layers that read the entity mask (a_loss), not here.

#include "res://shaders/aether/aether_common.gdshaderinc"

uniform float radius = 40.0;           // px
uniform vec2 half_size = vec2(200.0);  // half of the quad, px
uniform float time_s = 0.0;
uniform float seed = 0.0;
uniform int edge_octaves = 4;
uniform float grow = 0.0;              // 0..1 edge-fracture growth (drain)
uniform float crack_cells = 22.0;      // ✱ crazing density: cell side = (2π / crack_cells) / 4 radii

vec2 cell_pt(vec2 id) {
	return vec2(a_hash(id + seed * 3.7), a_hash(id.yx + seed * 1.3 + 7.1));
}

// Distance (normalised units) to the nearest DRAWN border of the crazing (cells of side `cell`).
// Borders thin out with s (crazing propagates from the mass, fewer cracks further out).
float crack_dist(vec2 p, float cell, float s_frac) {
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
	for (int j = -1; j <= 1; j++) {
		for (int i = -1; i <= 1; i++) {
			vec2 o = mg + vec2(float(i), float(j));
			vec2 idb = g + o;
			vec2 r = (o + cell_pt(idb) - f) * cell;
			vec2 dr = r - mr;
			if (dot(dr, dr) < 1e-7) {
				continue;
			}
			// symmetric per-border hash: some borders never crack, more of them further out
			float hb = a_hash(ida + idb + abs(ida - idb) * 7.3 + seed);
			if (hb < 0.06 + 0.3 * s_frac) {
				continue;
			}
			best = min(best, dot(0.5 * (mr + r), normalize(dr)));
		}
	}
	return best;
}

void fragment() {
	if (radius < 0.5) {
		discard;
	}
	vec2 rel = (UV - 0.5) * half_size * 2.0;
	vec2 p = rel / radius;
	float s = a_entity_shape(p, seed, time_s, edge_octaves);
	bool inside = s < 0.0;
	float band = A_ENT_CRACK_BAND * grow;
	if (!inside && band > 0.0 && s < band) {
		float s_frac = s / band;
		float dn = crack_dist(p, 6.2831853 / crack_cells * 0.25, s_frac);
		// half-width in px: 0.9 at the mass, a hairline at the band edge, where the crazing stops
		// along the loss contour (a hairline end on a contour, never a tapering thorn)
		float hw = mix(0.9, 0.35, s_frac) / radius;
		inside = dn < hw;
	}
	if (!inside) {
		discard;
	}
	COLOR = vec4(0.0, 0.0, 0.0, 1.0);
}
