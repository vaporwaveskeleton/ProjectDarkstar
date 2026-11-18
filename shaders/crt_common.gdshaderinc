// Shared by crt.gdshader (the arcade screen's own texture) and crt_attract.gdshader (the attract scene,
// which still shades the root screen texture). One costume, one set of uniforms (WARP-001 W0-01).
uniform float costume : hint_range(0.0, 1.0) = 1.0;
uniform float scanline_strength : hint_range(0.0, 1.0) = 0.22;
uniform float curvature : hint_range(0.0, 0.2) = 0.06;
uniform float vignette : hint_range(0.0, 1.0) = 0.35;
uniform float desaturate : hint_range(0.0, 1.0) = 0.0;
uniform float tear : hint_range(0.0, 1.0) = 0.0;     // W0-07 Pretence Tear: horizontal slice offsets
uniform float time_s = 0.0;
uniform float rows = 360.0;                           // ✱ scanline row count = the grid height (ds_cabinet.screen)

vec2 crt_warp(vec2 uv) {
	vec2 c = uv * 2.0 - 1.0;
	c *= 1.0 + curvature * costume * dot(c.yx, c.yx);
	return c * 0.5 + 0.5;
}

// Where to sample the picture for the pixel at `suv` (0..1 across the screen).
vec2 crt_sample_uv(vec2 suv) {
	vec2 uv = crt_warp(suv);
	if (tear > 0.0) {
		float band = floor(uv.y * 24.0);
		float h = fract(sin(band * 91.7 + floor(time_s * 6.0) * 13.1) * 43758.5);
		uv.x += (h - 0.5) * 0.08 * tear * step(0.6, h);
	}
	return uv;
}

// Scanlines on every other grid row, vignette, desaturation. Photosensitivity: no flicker term exists.
vec3 crt_finish(vec3 col, vec2 suv, vec2 uv) {
	if (uv.x < 0.0 || uv.x > 1.0 || uv.y < 0.0 || uv.y > 1.0) {
		col = vec3(0.0);
	}
	float row = floor(suv.y * rows);
	col *= 1.0 - scanline_strength * costume * mod(row, 2.0);
	vec2 d = suv - 0.5;
	col *= 1.0 - vignette * costume * dot(d, d) * 2.0;
	float g = dot(col, vec3(0.299, 0.587, 0.114));
	return mix(col, vec3(g), desaturate);
}
