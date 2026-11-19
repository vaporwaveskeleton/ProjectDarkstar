shader_type canvas_item;
#include "res://shaders/crt_common.gdshaderinc"
// Act 0 cabinet costume (WARP-001 W0-01, ART-001 §7) on the arcade screen: it reads the screen's own
// SubViewport texture (TEXTURE), so it can never touch the bezel. `costume` 1 → 0 is W0-08
// "Costume Removal" (curvature drops, scanlines fade). Scanline rows come from the `rows` uniform.

void fragment() {
	vec2 uv = crt_sample_uv(UV);
	COLOR = vec4(crt_finish(crt_quantize(texture(TEXTURE, uv).rgb), UV, uv), 1.0);
}
