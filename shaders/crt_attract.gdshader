shader_type canvas_item;
#include "res://shaders/crt_common.gdshaderinc"
// The same costume for the attract scene, which still shades the root screen texture until its menu
// moves onto the bezel. A ColorRect over the arcade hole only: `hole_uv` is the hole's footprint in
// window UV (x, y, w, h), set by AttractCrt, so curvature and scanlines are the hole's, not the window's.

uniform sampler2D screen_tex : hint_screen_texture, filter_nearest;
uniform vec4 hole_uv = vec4(0.0, 0.0, 1.0, 1.0);

void fragment() {
	vec2 local = (SCREEN_UV - hole_uv.xy) / hole_uv.zw;
	vec2 uv = crt_sample_uv(local);
	vec2 src = hole_uv.xy + uv * hole_uv.zw;
	COLOR = vec4(crt_finish(crt_quantize(texture(screen_tex, src).rgb), local, uv), 1.0);
}
