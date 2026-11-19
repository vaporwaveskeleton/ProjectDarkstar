shader_type canvas_item;
render_mode unshaded;
// The entity's presence (ART-001 §16): the only true black. A WOUND in the picture, not a blob:
// a hard torn edge (domain-warped noise at up to four scales plus fine fray), one knife-straight
// ruled cut, one impossible square inner corner, and thin NULL filaments reaching out along slow
// curving paths, tapering to a hairline and growing with drain. No outline, no rim, no glow and
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
		float rho = length(p);
		float ang = atan(p.y, p.x);
		for (int i = 0; i < 9; i++) {
			if (i >= tendril_count) {
				break;
			}
			float h1 = a_hash(vec2(float(i) + 0.3, seed));
			float h2 = a_hash(vec2(seed, float(i) + 7.7));
			float len = (0.35 + 0.75 * h2) * grow;
			float out_r = rho - 0.82;
			if (out_r < 0.0 || out_r > len) {
				continue;
			}
			float k = out_r / len;
			float th = seed * 1.3 + float(i) * 0.83 + h1 * 0.5;
			th += (0.25 + 0.3 * h1) * sin(out_r * 3.2 + time_s * 0.06 + float(i)) * k;
			th += (h2 - 0.5) * 0.9 * k * k;
			float lateral = abs(mod(ang - th + 3.14159265, 6.2831853) - 3.14159265) * rho * radius;
			float w = mix(1.5, 0.3, k);   // half-width px: tapers to a hairline
			if (lateral < w) {
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
