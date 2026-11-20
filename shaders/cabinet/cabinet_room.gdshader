shader_type canvas_item;
// The cabinet's side seen past the printed sheet. The sheet (and the T-molding on its edges) occupies x0..x1;
// just beyond it is the cabinet's side panel seen almost edge-on, catching a little of the screen's glow.
// Beyond the panel this paints nothing: the room itself is ArcadeBackdrop (arcade_backdrop.gdshader), drawn
// behind, which also carries the screen's light on the floor and walls (surround pass, 2026-11-19).
#include "res://shaders/cabinet/cabinet_material.gdshaderinc"
#include "res://shaders/cabinet/cabinet_detail.gdshaderinc"

uniform vec2 rect_size = vec2(640.0, 360.0);
uniform vec2 rig_origin = vec2(0.0);
uniform vec2 sheet_x = vec2(40.0, 600.0);
uniform float trim = 3.2;
uniform float room_glow = 0.6;
uniform float side_w = 15.0;     // the side panel's visible width, rig units

void fragment() {
	vec2 rp = rig_origin + UV * rect_size;
	float ds = max(sheet_x.x - trim - rp.x, rp.x - (sheet_x.y + trim));      // > 0 outside the molding
	if (ds <= 0.0 || ds > side_w + 1.0) {
		COLOR = vec4(0.0);
	} else {
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
		float lum = 0.14 + 0.86 * cab_screen_light.a;
		panel_c += cab_screen_light.rgb * lum * room_glow * 0.02;               // the screen's glow on the laminate
		COLOR = vec4(panel_c, panel);
	}
}
