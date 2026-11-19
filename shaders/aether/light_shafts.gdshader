shader_type canvas_item;
render_mode unshaded, blend_add;
// God-rays through the sphere seam (ART-001 §16): soft additive radial streaks broken up by fbm,
// fanning down from a source point above the frame. `intensity` stays well below the lantern.
// The Presence shadows them where it passes (rays stop at its back); near the entity they bend
// into it and then stop at its mid loss boundary. Static on the low quality rung (time frozen,
// fewer octaves, rendered offscreen at a fraction of the resolution).
// Colours arrive from GDScript (Pal); defaults are overwritten at runtime.

#include "res://shaders/aether/aether_common.gdshaderinc"

uniform vec3 ray_col : source_color = vec3(0.89, 0.87, 0.82);
uniform vec2 source_px = vec2(420.0, -140.0);   // screen px
uniform float intensity = 0.12;
uniform float time_s = 0.0;
uniform float spread = 0.9;                      // half-angle of the fan, radians
uniform float drain = 0.0;
uniform int octaves = 4;
// the Presence's body line: quad origin on screen, quad size, thickness, presence 0..1
uniform vec2 lev_origin = vec2(0.0);
uniform vec2 lev_quad = vec2(2600.0, 900.0);
uniform float lev_thick = 230.0;
uniform float lev_time = 0.0;
uniform float lev_presence = 0.0;

void fragment() {
	vec2 spx = SCREEN_UV * screen_size;
	vec4 loss = a_loss(spx);
	vec3 tw = a_toward_entity(spx);
	// rays bend into the entity
	vec2 bent = spx - tw.xy * tw.z * tw.z * 60.0;
	vec2 rel = bent - source_px;
	float dist = length(rel);
	float ang = atan(rel.x, rel.y);              // 0 = straight down
	float fan = smoothstep(spread, spread * 0.4, abs(ang));
	float streak = a_fbm(vec2(ang * 9.0, time_s * 0.03), octaves);
	streak = smoothstep(0.42, 0.85, streak);
	float fine = a_noise(vec2(ang * 40.0, time_s * 0.05 + 3.0));
	float breakup = a_fbm(spx / 90.0 + vec2(0.0, time_s * 0.02), max(octaves - 1, 1));
	float fall = exp(-dist / 380.0) * smoothstep(40.0, 200.0, dist);
	float v = fan * streak * (0.7 + 0.3 * fine) * fall * (0.5 + breakup);
	if (lev_presence > 0.0) {
		vec2 lq = spx - lev_origin;
		vec2 prof = a_lev_profile(lq.x, lev_time, lev_quad, lev_thick);
		if (prof.y > 0.5) {
			float top = prof.x - prof.y * 0.5 - 8.0;
			float bottom = prof.x + prof.y * 0.5;
			float shade = smoothstep(top - 4.0, top + 14.0, lq.y) * (1.0 - 0.55 * smoothstep(bottom, bottom + 170.0, lq.y));
			v *= 1.0 - shade * lev_presence * 0.92;
		}
	}
	v *= 1.0 - loss.y;
	v *= 1.0 - drain;
	COLOR = vec4(ray_col * v * intensity, 1.0);
}
