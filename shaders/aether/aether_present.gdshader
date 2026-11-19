shader_type canvas_item;
render_mode unshaded;
// Presents the Aether world's HDR SubViewport in the sRGB root: an HDR 2D viewport renders in
// linear space and is only converted to sRGB when it blits to the screen itself, so a texture of
// it must be converted here. No colours of its own.

uniform bool to_srgb = true;

vec3 linear_to_srgb(vec3 c) {
	c = clamp(c, vec3(0.0), vec3(1.0));
	return mix(c * 12.92, 1.055 * pow(c, vec3(1.0 / 2.4)) - 0.055, step(vec3(0.0031308), c));
}

void fragment() {
	vec3 c = texture(TEXTURE, UV).rgb;
	COLOR = vec4(to_srgb ? linear_to_srgb(c) : c, 1.0);
}
