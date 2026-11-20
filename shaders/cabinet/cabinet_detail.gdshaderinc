// loom detail textures for a Cabinet part (ART-001 §14.8a): an albedo and an OpenGL normal map rendered from
// art/src/cabinet_textures.tx.js, tiled in rig units. Bound by CabinetTextures.bind(). Bezel hardware only.
uniform sampler2D detail_albedo : source_color, repeat_enable, filter_linear_mipmap;
uniform sampler2D detail_normal : repeat_enable, filter_linear_mipmap;     // data, not colour: no source_color
uniform float detail_tile = 48.0;      // rig units per repeat
uniform float detail_mean = 0.8;       // the albedo's mean luma: detail_tone() is 1.0 on average
uniform float detail_gain = 1.0;       // 0 = the untextured look

vec2 detail_uv(vec2 rp) {
	return rp / max(detail_tile, 1e-3);
}

// Luminance of the detail albedo around its mean (about 0.5 .. 1.2), blended toward 1.0 by (1 - k * gain).
float detail_tone(vec2 rp, float k) {
	float l = dot(texture(detail_albedo, detail_uv(rp)).rgb, vec3(0.2126, 0.7152, 0.0722)) / max(detail_mean, 1e-3);
	return mix(1.0, l, clamp(k * detail_gain, 0.0, 1.0));
}

// The detail normal's tilt in rig space (rig y points down, the map's green points up), scaled by k * gain.
vec2 detail_tilt(vec2 rp, float k) {
	vec2 t = texture(detail_normal, detail_uv(rp)).rg * 2.0 - 1.0;
	return vec2(t.x, -t.y) * k * detail_gain;
}
