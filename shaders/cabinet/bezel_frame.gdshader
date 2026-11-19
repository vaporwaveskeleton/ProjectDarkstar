shader_type canvas_item;
// The printed border round the rounded-corner screen opening, and the recess the tube sits in. A ColorRect
// over the opening grown by `reach`; it paints NOTHING inside the opening's rectangle (the screen's own
// pixels are the tube's business: ScreenTube). Outward from the opening's edge: a key-black tube-mask
// band, a cream printed line (a touch out of register), a key-black keyline, then the recess wall's
// shadow fading onto the print, darkest where the screen glow does not reach. Lit like the rest of the
// print by the one cabinet light.
#include "res://shaders/cabinet/cabinet_material.gdshaderinc"

uniform float corner_r = 5.0;
uniform vec2 rect_size = vec2(276.0, 324.0);
uniform vec2 rig_origin = vec2(0.0);
uniform float recess_shadow = 0.7;
uniform float recess_width = 7.0;
uniform vec3 key_black = vec3(0.078, 0.063, 0.094);
uniform vec3 cream = vec3(0.945, 0.9, 0.78);

void fragment() {
	vec2 rp = rig_origin + UV * rect_size;
	float px = max(max(fwidth(rp.x), fwidth(rp.y)), 1e-4);
	vec2 hc = cab_hole.xy + cab_hole.zw * 0.5;
	vec2 hh = cab_hole.zw * 0.5;
	float d = rbox(rp, hc, hh, corner_r);                 // < 0 inside the rounded opening
	vec2 q = abs(rp - hc) - hh;
	float in_rect = 1.0 - cov(max(q.x, q.y), px);         // 1 inside the opening's rectangle: not ours
	// black tube-mask band, cream line (out of register by a quarter unit), black keyline
	float band = (1.0 - cov(d, px)) * cov(d - 1.6, px);
	float cr = cov(abs(d - 2.45) - 0.55, px);
	float kl = cov(abs(d - 3.2) - 0.45, px);
	vec3 ink = key_black;
	float a_ink = clamp(band + kl, 0.0, 1.0);
	ink = mix(ink, cream, cr);
	a_ink = max(a_ink, cr);
	ink *= cab_amb(rp) * 1.6 + cab_key(rp) * 0.9;
	// the recess wall's shadow beyond the printed rings
	float dw = d - 3.7;
	float sh = (1.0 - smoothstep(0.0, recess_width, dw)) * step(0.0, dw) * recess_shadow;
	sh *= 1.0 - 0.6 * clamp(dot(cab_spill(rp), vec3(0.33)) * 1.5, 0.0, 1.0);
	float total = a_ink + sh * (1.0 - a_ink);
	vec3 c = total > 1e-4 ? ink * a_ink / total : vec3(0.0);
	COLOR = vec4(c, clamp(total, 0.0, 1.0) * (1.0 - in_rect));
}
