shader_type canvas_item;
render_mode unshaded;
// Final grade of the Aether world (ART-001 §16). Only drawn when something needs it (drain, an
// entity, or T5 subtraction). At T5, chromatic subtraction: channels drained one by one (red, then
// green, then blue) toward a chalk grey. Drain gives everything a cold VOID cast — the world reads
// MISSING, not desaturated — and around the entity colour goes cold in a ring (saturation loss,
// never a darkening toward black). The lantern pool is spared — the last warm thing.
// Never turns a non-entity pixel to pure black: floor VOID_0. Entity pixels (exact black) stay black.
// Colours arrive from GDScript (Pal); defaults are overwritten at runtime.

#include "res://shaders/aether/aether_common.gdshaderinc"

uniform sampler2D screen_tex : hint_screen_texture, filter_nearest;
uniform vec3 floor_col : source_color = vec3(0.039, 0.039, 0.07);
uniform vec3 chalk_col : source_color = vec3(0.54, 0.55, 0.58);
uniform vec3 void_lo : source_color = vec3(0.075, 0.078, 0.157);
uniform vec3 void_hi : source_color = vec3(0.235, 0.27, 0.455);
uniform float subtraction : hint_range(0.0, 1.0) = 0.0;
uniform float drain : hint_range(0.0, 1.0) = 0.0;
uniform vec2 lantern_px = vec2(320.0, 200.0);
uniform float lantern_r = 120.0;

vec3 cold(vec3 c) {
	return mix(void_lo, void_hi, clamp(a_luma(c) * 2.4, 0.0, 1.0));
}

void fragment() {
	vec3 c = texture(screen_tex, SCREEN_UV).rgb;
	vec2 spx = SCREEN_UV * screen_size;
	if (max(c.r, max(c.g, c.b)) <= 0.0) {
		COLOR = vec4(0.0, 0.0, 0.0, 1.0);   // the entity: untouched
	} else {
		float spare = pow(1.0 - smoothstep(0.0, lantern_r * 2.4, length(spx - lantern_px)), 1.5);
		float l = a_luma(c);
		// chromatic subtraction, one channel after another
		float s = subtraction * (1.0 - spare * 0.8);
		vec3 sub = c;
		sub.r = mix(c.r, l, smoothstep(0.0, 0.34, s));
		sub.g = mix(c.g, l, smoothstep(0.33, 0.67, s));
		sub.b = mix(c.b, l, smoothstep(0.66, 1.0, s));
		sub = mix(sub, chalk_col * l * 1.6, smoothstep(0.7, 1.0, s) * 0.5);
		// drain: a cold VOID cast everywhere except the lantern pool
		float d = drain * (1.0 - spare * 0.9);
		sub = mix(sub, cold(sub), d * 0.85);
		// the ring around the entity: colour goes cold (layers are removed by the layers themselves)
		vec4 loss = a_loss(spx);
		sub = mix(sub, cold(sub), loss.w * 0.6);
		COLOR = vec4(max(sub, floor_col), 1.0);
	}
}
