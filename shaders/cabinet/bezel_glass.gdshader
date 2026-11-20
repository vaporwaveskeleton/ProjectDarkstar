shader_type canvas_item;
// The glass over the whole printed bezel, its own front layer (never over the screen hole: BezelGlass only
// draws the rectangles that tile the bezel around it). Four things you can see: one broad soft diagonal
// specular band from the cabinet light; the screen's glow reflected in it (the live screen colour,
// crawling across the glass); dust lying ON TOP of the ink, brighter where the light catches it; and a
// thumb-smear where a hand leaned in (beside the screen edge, in the glow path). A faint green-blue tint
// hugs the glass edge and a few fine scratches remain. The printed art stays readable.
#include "res://shaders/cabinet/cabinet_material.gdshaderinc"

uniform vec4 area = vec4(0.0, 0.0, 640.0, 360.0);        // the bezel window, rig units
uniform vec4 door_rect = vec4(460.0, 252.0, 56.0, 80.0); // the coin door: glass does not cover it
uniform vec4 edge_color = vec4(0.235, 0.69, 0.6, 1.0);
uniform float reflection : hint_range(0.0, 1.0) = 0.55;
uniform float band_gain : hint_range(0.0, 1.0) = 0.6;
uniform float screen_reflection : hint_range(0.0, 1.0) = 0.5;
uniform float edge_tint : hint_range(0.0, 1.0) = 0.6;
uniform float dust : hint_range(0.0, 1.0) = 0.5;
uniform float smudges : hint_range(0.0, 1.0) = 0.5;
uniform float scratch : hint_range(0.0, 1.0) = 0.5;
uniform float band_lift = 0.42;          // peak alpha of the specular band: a pale veil that lowers contrast and saturation
uniform float smear_haze = 1.0;          // peak alpha of the thumb-smear when the screen is bright
uniform float smear_idle = 0.0;          // its share of that when the screen is dark
uniform sampler2D smudge_mask : repeat_enable, filter_linear_mipmap;   // loom ds_cab_glass_smudge (ART-001 §14.8a)
uniform float smudge_tile = 90.0;
uniform float prints : hint_range(0.0, 1.0) = 0.8;

varying vec2 lp;

void vertex() {
	lp = VERTEX;
}

void fragment() {
	vec2 rp = lp;
	float px = max(max(fwidth(rp.x), fwidth(rp.y)), 1e-4);
	vec2 hc = cab_hole.xy + cab_hole.zw * 0.5;
	vec3 key = cab_key(rp);
	float key_l = dot(key, vec3(0.33));
	vec3 acc = vec3(0.0);
	float asum = 0.0;

	// ONE broad soft diagonal band from the cabinet light: wide, gentle, a little brighter toward the top
	vec2 dir = normalize(vec2(0.62, -1.0));
	float u = dot(rp - hc, dir);
	float band = exp(-pow((u + 12.0) / 74.0, 2.0));
	float core = exp(-pow((u + 12.0) / 20.0, 2.0)) * 0.35;
	float top = 0.75 + 0.5 * (1.0 - clamp(rp.y / cab_view_h, 0.0, 1.0));
	float a_band = (band * band_lift + core * band_lift * 0.45) * top * band_gain * reflection * (0.9 + 0.2 * fbm(rp + 4.0, 0.015, px));
	acc += vec3(0.86, 0.92, 1.0) * a_band;
	asum += a_band;

	// the screen's glow reflected in the glass: the live screen colour, hugging the opening and crawling out
	float dh = max(cab_hole_dist(rp), 0.0);
	float halo = exp(-dh / 22.0) + 0.45 * exp(-dh / 70.0);
	float crawl = 0.75 + 0.5 * vnoise(vec2(dh * 0.11 - (rp.x + rp.y) * 0.02, 3.0));
	float a_scr = clamp(halo * crawl * (0.05 + 0.26 * cab_screen_light.a), 0.0, 0.4) * screen_reflection;
	acc += mix(vec3(0.55, 0.65, 0.9), cab_screen_light.rgb, 0.8) * a_scr;
	asum += a_scr;

	// the glass edge seen end-on: a green-blue tint hugging the window edge
	float e = min(min(rp.x - area.x, area.x + area.z - rp.x), min(rp.y - area.y, area.y + area.w - rp.y));
	float a_edge = smoothstep(16.0, 0.0, e) * 0.12 * edge_tint * (0.7 + 0.5 * vnoise(rp * 0.15));
	acc += edge_color.rgb * a_edge;
	asum += a_edge;

	// dust lying on top of the ink: sparse specks and a faint film, bright where the key light catches it
	float sp = smoothstep(0.9, 0.97, vnoise(rp * 1.9 + 7.0)) * smoothstep(0.45, 0.8, vnoise(rp * 0.12 + 2.0));
	float film = smoothstep(0.45, 0.8, fbm(rp + 33.0, 0.08, px)) * 0.035;
	float a_dust = (sp * 0.15 + film) * dust * (0.55 + 1.6 * key_l);
	acc += mix(vec3(0.78, 0.76, 0.7), key / max(max(key.r, max(key.g, key.b)), 0.05), 0.5) * a_dust;
	asum += a_dust;

	// the thumb-smear (pass 2c): on the glass beside the screen's left edge, in the glow's path, where a hand leaned in
	// to steady itself: a tall greasy wipe hugging the edge with streaks along the lean, and two thumb ovals with ridges.
	// It is the screen's own light scattering in the grease: invisible while the picture is dark, a clear haze when it is bright.
	vec2 sc = vec2(cab_hole.x - 17.0, cab_hole.y + cab_hole.w * 0.62);
	vec2 sq = rot2(rp - sc, 0.16) / vec2(15.0, 74.0);
	float streak = 0.55 + 0.6 * vnoise(rp * vec2(2.4, 0.2) + 11.0);
	float wipe = smoothstep(1.0, 0.1, length(sq)) * streak;
	float thumb = max(print_blob(rp, sc + vec2(4.0, -26.0), 1.2, vec2(9.5, 6.5), px), print_blob(rp, sc + vec2(-4.0, 16.0), 1.45, vec2(9.0, 6.0), px));
	float glow_path = exp(-max(dh, 0.0) / 40.0);
	float lit_k = smear_idle + (1.0 - smear_idle) * smoothstep(0.5, 0.95, cab_screen_light.a);
	float a_sm = clamp(wipe * 0.6 + thumb * 0.9, 0.0, 1.0) * smear_haze * smudges * lit_k * glow_path * (0.8 + 0.6 * key_l);
	acc += mix(vec3(0.9, 0.92, 0.94), cab_screen_light.rgb * 1.1 + 0.15, 0.55) * a_sm;
	asum += a_sm;

	// greasy fingerprints and palm smears (loom ds_cab_glass_smudge): wherever hands go (wear_k: the lower edge,
	// round the coin door) and in a band beside the screen; always faintly there, a lit sheen in the key light and
	// the specular band, so the glass reads as a touched surface even when the picture is dark
	float grease = dot(texture(smudge_mask, rp / max(smudge_tile, 1.0)).rgb, vec3(0.333));
	float hands = clamp(wear_k(rp) * 1.3 + exp(-max(dh, 0.0) / 30.0) * 0.35, 0.0, 1.0);
	float a_fp = grease * hands * prints * (0.05 + 0.25 * band + 0.18 * key_l + 0.1 * cab_screen_light.a);
	acc += mix(vec3(0.82, 0.85, 0.9), key / max(max(key.r, max(key.g, key.b)), 0.05), 0.35) * a_fp;
	asum += a_fp;

	// a few fine scratches
	float fa = ridge(vnoise(vec2(rp.x * 0.09 + rp.y * 0.04, rp.y * 1.3 - rp.x * 0.5)), 0.975) * smoothstep(0.4, 0.7, vnoise(rp * 0.05 + 8.0));
	float fb = ridge(vnoise(vec2(rp.x * 1.2 + rp.y * 0.6, rp.y * 0.08 - rp.x * 0.12)), 0.978) * smoothstep(0.45, 0.75, vnoise(rp * 0.04 + 2.0));
	float a_sc = clamp(max(fa, fb) * 0.12, 0.0, 0.14) * scratch * wear_k(rp);
	acc += vec3(0.92, 0.94, 0.96) * a_sc;
	asum += a_sc;

	// the glass is the cabinet's front only: it fades out into the room beyond the sheet
	float x0 = cab_hole.x - cab_side;
	float x1 = cab_hole.x + cab_hole.z + cab_side;
	float in_sheet = smoothstep(x0 - 5.0, x0 + 1.0, rp.x) * (1.0 - smoothstep(x1 - 1.0, x1 + 5.0, rp.x));

	// the coin door sits in front of the glass
	vec2 dq = abs(rp - (door_rect.xy + door_rect.zw * 0.5)) - door_rect.zw * 0.5;
	float dd = max(dq.x, dq.y);
	float hide = smoothstep(0.0, 1.5, dd + 1.0);
	float a = clamp(asum, 0.0, 0.7) * hide * in_sheet;
	vec3 c = asum > 1e-5 ? acc / asum : vec3(1.0);
	COLOR = vec4(c, a);
}
