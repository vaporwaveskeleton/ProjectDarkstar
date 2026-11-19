shader_type canvas_item;
render_mode unshaded;
// Final grade of the Aether world (ART-001 §16). Drinks colour around each entity (the world stops
// at its edge) and, at T5, performs chromatic subtraction: channels drained one by one (red, then
// green, then blue) toward a chalk grey. The lantern pool is spared — the last warm thing.
// Never turns a non-entity pixel to pure black: floor VOID_0. Entity pixels (exact black) stay black.
// Colours arrive from GDScript (Pal); defaults are overwritten at runtime.

#include "res://shaders/aether/aether_common.gdshaderinc"

uniform sampler2D screen_tex : hint_screen_texture, filter_nearest;
uniform vec3 floor_col : source_color = vec3(0.039, 0.039, 0.07);
uniform vec3 chalk_col : source_color = vec3(0.54, 0.55, 0.58);
uniform float subtraction : hint_range(0.0, 1.0) = 0.0;
uniform float drain : hint_range(0.0, 1.0) = 0.0;
uniform vec2 lantern_px = vec2(320.0, 200.0);
uniform float lantern_r = 120.0;

void fragment() {
	vec3 c = texture(screen_tex, SCREEN_UV).rgb;
	vec2 spx = SCREEN_UV * screen_size;
	if (max(c.r, max(c.g, c.b)) <= 0.0) {
		COLOR = vec4(0.0, 0.0, 0.0, 1.0);   // the entity: untouched
	} else {
		float spare = pow(1.0 - smoothstep(0.0, lantern_r * 1.6, length(spx - lantern_px)), 1.5);
		float l = a_luma(c);
		// chromatic subtraction, one channel after another
		float s = subtraction * (1.0 - spare * 0.8);
		vec3 sub = c;
		sub.r = mix(c.r, l, smoothstep(0.0, 0.34, s));
		sub.g = mix(c.g, l, smoothstep(0.33, 0.67, s));
		sub.b = mix(c.b, l, smoothstep(0.66, 1.0, s));
		sub = mix(sub, chalk_col * l * 1.6, smoothstep(0.7, 1.0, s) * 0.5);
		// drain: colour goes out everywhere except the lantern pool
		float d = drain * (1.0 - spare);
		sub = mix(sub, vec3(a_luma(sub)), d * 0.9);
		sub = mix(sub, floor_col, d * 0.45);
		// the annulus around the entity: the world stops at its edge
		float drunk = a_drunk(spx);
		sub = mix(sub, vec3(a_luma(sub)), drunk);
		sub = mix(sub, floor_col, drunk * 0.55);
		COLOR = vec4(max(sub, floor_col), 1.0);
	}
}
