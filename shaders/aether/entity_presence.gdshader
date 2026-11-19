shader_type canvas_item;
render_mode unshaded;
// The entity's presence (ART-001 §16): the only true black. A WOUND in the picture, not a blob:
// a hard torn edge (ridged fray at up to four scales and angular sheared bites; never a face —
// N4), one ruled cut terraced into straight steps, one impossible square inner corner, and thin
// NULL filaments reaching out as straight kinked, branching strokes, tapering to a hairline and
// growing with drain. No outline, no rim, no glow and
// no halo of its own: inside is exactly vec4(0,0,0,1), outside is discarded. The world losing its
// layers around it is done by the layers that read the entity mask (a_loss), not here.

#include "res://shaders/aether/aether_common.gdshaderinc"

uniform float radius = 40.0;           // px
uniform vec2 half_size = vec2(200.0);  // half of the quad, px
uniform float time_s = 0.0;
uniform float seed = 0.0;
uniform int edge_octaves = 4;
uniform float grow = 0.0;              // 0..1 tendril growth (drain)
uniform int tendril_count = 7;

void fragment() {
	if (radius < 0.5) {
		discard;
	}
	vec2 rel = (UV - 0.5) * half_size * 2.0;
	vec2 p = rel / radius;
	float s = a_entity_shape(p, seed, time_s, edge_octaves);
	bool inside = s < 0.0;
	if (!inside && grow > 0.0) {
		// filaments: STRAIGHT segments with one kink and an occasional one-sided branch (pass 3:
		// curving pairs near the edge read as whiskers / brows). Half-width tapers to a hairline.
		float px_w = 1.0 / radius;
		for (int i = 0; i < 9; i++) {
			if (i >= tendril_count) {
				break;
			}
			float h1 = a_hash(vec2(float(i) + 0.3, seed));
			float h2 = a_hash(vec2(seed, float(i) + 7.7));
			float h3 = a_hash(vec2(float(i) * 2.3, seed + 1.9));
			float len = (0.35 + 0.75 * h2) * grow;
			float th = seed * 1.3 + float(i) * 0.83 + h1 * 0.5 + 0.015 * sin(time_s * 0.05 + float(i));
			vec2 dir = vec2(cos(th), sin(th));
			vec2 base = dir * 0.8;
			if (length(p - base) > len * 1.05 + 0.05) {
				continue;
			}
			float kk = 0.35 + 0.35 * h1;
			vec2 kink = base + dir * len * kk;
			float th2 = th + (h2 - 0.5) * 0.6;
			vec2 tip = kink + vec2(cos(th2), sin(th2)) * len * (1.0 - kk);
			float dseg = min(a_seg(p, base, kink), a_seg(p, kink, tip));
			if (h3 > 0.45) {
				float th3 = th + (h3 > 0.72 ? 0.55 : -0.48) * (0.6 + 0.6 * h1);
				dseg = min(dseg, a_seg(p, kink, kink + vec2(cos(th3), sin(th3)) * len * 0.4 * h3));
			}
			float k = clamp(length(p - base) / max(len, 0.001), 0.0, 1.0);
			if (dseg < mix(1.5, 0.3, k) * px_w) {
				inside = true;
				break;
			}
		}
	}
	if (!inside) {
		discard;
	}
	COLOR = vec4(0.0, 0.0, 0.0, 1.0);
}
