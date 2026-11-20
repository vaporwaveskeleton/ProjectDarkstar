shader_type canvas_item;
// The room round the cabinet. The printed sheet (and the T-molding on its edges) occupies x0..x1; beyond it
// the frame falls off into darkness: on a wide window (16:9 spare width, 21:9, 16:10) that is dark room with
// a hint of the cabinet's side panel catching the screen's glow, never the print stretched out to the edge.
#include "res://shaders/cabinet/cabinet_material.gdshaderinc"
#include "res://shaders/cabinet/cabinet_detail.gdshaderinc"

uniform vec2 rect_size = vec2(640.0, 360.0);
uniform vec2 rig_origin = vec2(0.0);
uniform vec2 sheet_x = vec2(112.0, 528.0);
uniform float trim = 3.2;
uniform float room_glow = 0.6;

void fragment() {
	vec2 rp = rig_origin + UV * rect_size;
	float px = max(max(fwidth(rp.x), fwidth(rp.y)), 1e-4);
	float ds = max(sheet_x.x - trim - rp.x, rp.x - (sheet_x.y + trim));      // > 0 outside the molding
	if (ds <= 0.0) {
		COLOR = vec4(0.0);
	} else {
		float yk = clamp(rp.y / cab_view_h, 0.0, 1.0);
		// the cabinet's side panel seen almost edge-on: a dark charcoal strip that catches a little light
		float side_w = 15.0;
		float panel = 1.0 - smoothstep(side_w - 1.5, side_w, ds);
		vec3 amb = cab_amb(rp);
		// loom ds_cab_side: black paint chipped back to the plywood, grime in the chips. Seen edge-on, so the
		// texture is squeezed 4x across the strip; its normal catches the key where a chip's edge faces it.
		vec2 sp = vec2(ds * 4.0, rp.y);
		vec3 side_alb = mix(vec3(0.05, 0.05, 0.06), texture(detail_albedo, detail_uv(sp)).rgb, clamp(detail_gain, 0.0, 1.0));
		vec3 sn = normalize(vec3(detail_tilt(sp, 1.0), 1.0));
		float side_ndl = max(dot(sn, cab_key_dir(rp)), 0.0);
		vec3 panel_c = side_alb * (0.35 * amb + cab_key(rp) * (0.22 + 0.5 * side_ndl));
		panel_c += vec3(0.5, 0.52, 0.56) * smoothstep(1.6, 0.0, ds) * 0.03 * (cab_amb(rp) + cab_key(rp));   // the crisp edge
		// the dark room: nearly black, lit by the screen. The cabinet lights its surroundings: a broad
		// screen-coloured pool on the floor and a fainter wash up the walls, breathing with the picture
		// (cab_screen_light is the smoothed, photosensitivity-frozen light, so this never flickers)
		float far = exp(-ds / 90.0);
		float wide = exp(-ds / 260.0);
		float lum = 0.14 + 0.86 * cab_screen_light.a;
		float floor_pool = smoothstep(0.45, 1.0, yk);
		vec3 glow = cab_screen_light.rgb * lum * room_glow;
		vec3 room = vec3(0.006, 0.006, 0.012) + glow * (0.17 * wide * (0.25 + 1.6 * floor_pool * floor_pool) + 0.12 * far * (0.3 + 0.7 * yk));
		room += vec3(0.01, 0.009, 0.014) * far * (1.0 - yk);
		room *= 0.88 + 0.24 * vnoise(rp * 0.03);
		vec3 c = mix(room, panel_c, panel);
		COLOR = vec4(c, 1.0);
	}
}
