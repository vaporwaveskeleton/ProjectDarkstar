shader_type canvas_item;
#include "res://shaders/crt_common.gdshaderinc"
// The same costume for the attract scene, which still shades the root screen texture until its menu
// moves onto the bezel. A ColorRect over the whole scene; the frame and coin door draw after it.

uniform sampler2D screen_tex : hint_screen_texture, filter_nearest;

void fragment() {
	vec2 uv = crt_sample_uv(SCREEN_UV);
	COLOR = vec4(crt_finish(texture(screen_tex, uv).rgb, SCREEN_UV, uv), 1.0);
}
