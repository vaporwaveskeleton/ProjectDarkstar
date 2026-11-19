shader_type canvas_item;
render_mode unshaded;
// W1-06 Chromatic Edge (WARP-001 §2.2), far-layer part: the frame edge splits into its colour
// channels; the centre is untouched (information is unaffected: the split sits on the frame, never
// on a hitbox or a blip). Static: no animation, no luminance change. Switched off entirely while
// photosensitivity is on (WARP-001 §4.5). Reads the backdrop below it; adds no colour of its own.

uniform sampler2D screen_tex : hint_screen_texture, filter_linear_mipmap;
uniform vec2 screen_size = vec2(640.0, 360.0);
uniform float split_px = 1.5;     // channel offset at the very edge, logical px
uniform float inner = 0.6;        // 0 centre … 1 edge: where the split starts

void fragment() {
	vec2 c = SCREEN_UV - 0.5;
	float e = max(abs(c.x), abs(c.y)) * 2.0;
	float k = smoothstep(inner, 1.0, e);
	vec2 dir = c / max(length(c), 0.0001);
	vec2 off = dir * split_px * k / screen_size;
	float r = textureLod(screen_tex, SCREEN_UV + off, 0.0).r;
	vec3 mid = textureLod(screen_tex, SCREEN_UV, 0.0).rgb;
	float b = textureLod(screen_tex, SCREEN_UV - off, 0.0).b;
	COLOR = vec4(r, mid.g, b, 1.0);
}
