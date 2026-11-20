shader_type canvas_item;
render_mode unshaded;
// W1-06 Chromatic Edge over the play layer (WARP-001 §2.2; owner of TECH-001 Q-T128's full-frame
// split). The frame edge splits by at most `split_px` (SYS-001 §1.5 Frayed: ≤ 2 px); the centre of the
// field, where hitboxes and blips live, is untouched (`edge_band` mask). Static: no flicker, no motion.
// Never drawn under photosensitivity (the composer hides the node; the wick and flame carry the band).

uniform sampler2D screen_tex : hint_screen_texture, filter_linear_mipmap;
uniform vec2 view_size = vec2(640.0, 360.0);
uniform float split_px = 2.0;
uniform float edge_band : hint_range(0.0, 0.5) = 0.18;   // fraction of the half-extent that splits
uniform float strength : hint_range(0.0, 1.0) = 1.0;

void fragment() {
	vec2 uv = SCREEN_UV;
	vec2 q = (uv - 0.5) * 2.0;                       // -1..1
	float edge = max(abs(q.x), abs(q.y));
	float mask = smoothstep(1.0 - edge_band * 2.0, 1.0, edge) * strength;
	vec2 dir = normalize(q + vec2(1e-5));
	vec2 off = dir * split_px * mask / view_size;
	vec4 base = texture(screen_tex, uv);
	float r = texture(screen_tex, uv + off).r;
	float b = texture(screen_tex, uv - off).b;
	COLOR = vec4(r, base.g, b, 1.0);
}
