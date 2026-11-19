shader_type canvas_item;
render_mode unshaded, blend_add;
// God-rays through the sphere seam (ART-001 §16): soft additive radial streaks broken up by fbm,
// fanning down from a source point above the frame. `intensity` stays well below the lantern.
// Colours arrive from GDScript (Pal); defaults are overwritten at runtime.

#include "res://shaders/aether/aether_common.gdshaderinc"

uniform vec3 ray_col : source_color = vec3(0.89, 0.87, 0.82);
uniform vec2 source_px = vec2(420.0, -140.0);   // screen px
uniform float intensity = 0.12;
uniform float time_s = 0.0;
uniform float spread = 0.9;                      // half-angle of the fan, radians
uniform float drain = 0.0;

void fragment() {
	vec2 spx = SCREEN_UV * screen_size;
	vec2 rel = spx - source_px;
	float dist = length(rel);
	float ang = atan(rel.x, rel.y);              // 0 = straight down
	float fan = smoothstep(spread, spread * 0.4, abs(ang));
	float streak = a_fbm(vec2(ang * 9.0, time_s * 0.03), 4);
	streak = smoothstep(0.42, 0.85, streak);
	float fine = a_noise(vec2(ang * 40.0, time_s * 0.05 + 3.0));
	float breakup = a_fbm(spx / 90.0 + vec2(0.0, time_s * 0.02), 3);
	float fall = exp(-dist / 380.0) * smoothstep(40.0, 200.0, dist);
	float v = fan * streak * (0.7 + 0.3 * fine) * fall * (0.5 + breakup);
	v *= 1.0 - a_drunk(spx);
	v *= 1.0 - drain;
	COLOR = vec4(ray_col * v * intensity, 1.0);
}
