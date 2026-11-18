shader_type canvas_item;
// Act 0 cabinet costume (WARP-001 W0-01, ART-001 §7): scanlines, a soft vignette and a hint of
// curvature. `costume` 1 → 0 is W0-08 "Costume Removal" (curvature drops, scanlines fade).
// Photosensitivity: no flicker term exists here at all.

uniform sampler2D screen_tex : hint_screen_texture, filter_nearest;
uniform float costume : hint_range(0.0, 1.0) = 1.0;
uniform float scanline_strength : hint_range(0.0, 1.0) = 0.22;
uniform float curvature : hint_range(0.0, 0.2) = 0.06;
uniform float vignette : hint_range(0.0, 1.0) = 0.35;
uniform float desaturate : hint_range(0.0, 1.0) = 0.0;
uniform float tear : hint_range(0.0, 1.0) = 0.0;     // W0-07 Pretence Tear: horizontal slice offsets
uniform float time_s = 0.0;

vec2 warp(vec2 uv) {
	vec2 c = uv * 2.0 - 1.0;
	c *= 1.0 + curvature * costume * dot(c.yx, c.yx);
	return c * 0.5 + 0.5;
}

void fragment() {
	vec2 uv = warp(SCREEN_UV);
	if (tear > 0.0) {
		float band = floor(uv.y * 24.0);
		float h = fract(sin(band * 91.7 + floor(time_s * 6.0) * 13.1) * 43758.5);
		uv.x += (h - 0.5) * 0.08 * tear * step(0.6, h);
	}
	vec3 col = texture(screen_tex, uv).rgb;
	if (uv.x < 0.0 || uv.x > 1.0 || uv.y < 0.0 || uv.y > 1.0) {
		col = vec3(0.0);
	}
	// scanlines on every other logical row (360 rows)
	float row = floor(SCREEN_UV.y * 360.0);
	col *= 1.0 - scanline_strength * costume * mod(row, 2.0);
	// vignette
	vec2 d = SCREEN_UV - 0.5;
	col *= 1.0 - vignette * costume * dot(d, d) * 2.0;
	// T0→T1 desaturation
	float g = dot(col, vec3(0.299, 0.587, 0.114));
	col = mix(col, vec3(g), desaturate);
	COLOR = vec4(col, 1.0);
}
