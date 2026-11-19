shader_type canvas_item;
// The glass over the whole printed bezel (never over the screen hole: BezelGlass only draws the
// rectangles that tile the bezel around it). Restrained: a broad soft reflection, a faint green-blue
// edge tint, light dust, a few fingerprints and wipes, fine scratches. The printed art stays readable.
#include "res://shaders/cabinet/cabinet_material.gdshaderinc"

uniform vec4 area = vec4(0.0, 0.0, 640.0, 360.0);        // the bezel window, rig units
uniform vec4 door_rect = vec4(460.0, 252.0, 56.0, 80.0); // the coin door: glass does not cover it
uniform vec4 edge_color = vec4(0.235, 0.69, 0.6, 1.0);
uniform float reflection : hint_range(0.0, 1.0) = 0.55;
uniform float edge_tint : hint_range(0.0, 1.0) = 0.6;
uniform float dust : hint_range(0.0, 1.0) = 0.5;
uniform float smudges : hint_range(0.0, 1.0) = 0.5;
uniform float scratch : hint_range(0.0, 1.0) = 0.5;

varying vec2 lp;

void vertex() {
	lp = VERTEX;
}

void fragment() {
	vec2 rp = lp;
	float px = max(max(fwidth(rp.x), fwidth(rp.y)), 1e-4);
	vec2 hc = cab_hole.xy + cab_hole.zw * 0.5;
	vec3 acc = vec3(0.0);
	float asum = 0.0;

	// broad soft reflection of the room: a wide diagonal band and a fainter second one, brighter near the top
	vec2 dir = normalize(vec2(0.62, -1.0));
	float u = dot(rp - hc, dir);
	float band = exp(-pow((u - 20.0) / 120.0, 2.0)) * 0.085 + exp(-pow((u + 150.0) / 38.0, 2.0)) * 0.04;
	float top = (1.0 - clamp(rp.y / cab_view_h, 0.0, 1.0)) * 0.03;
	float a_ref = (band + top) * reflection * (0.8 + 0.4 * fbm(rp + 4.0, 0.02, px));
	acc += vec3(0.82, 0.9, 1.0) * a_ref;
	asum += a_ref;

	// the glass edge seen end-on: a green-blue tint hugging the window edge
	float e = min(min(rp.x - area.x, area.x + area.z - rp.x), min(rp.y - area.y, area.y + area.w - rp.y));
	float a_edge = smoothstep(16.0, 0.0, e) * 0.16 * edge_tint * (0.7 + 0.5 * vnoise(rp * 0.15));
	acc += edge_color.rgb * a_edge;
	asum += a_edge;

	// light dust: fine specks and a faint film
	float sp = smoothstep(0.84, 0.95, vnoise(rp * 1.9 + 7.0)) * smoothstep(0.3, 0.7, vnoise(rp * 0.17 + 2.0));
	float film = smoothstep(0.45, 0.8, fbm(rp + 33.0, 0.08, px)) * 0.035;
	float a_dust = (sp * 0.13 + film) * dust;
	acc += vec3(0.78, 0.76, 0.7) * a_dust;
	asum += a_dust;

	// fingerprints and wipe marks (where hands steady themselves)
	float pr = max(max(print_blob(rp, vec2(150.0, 196.0), 0.5, vec2(5.5, 7.0), px), print_blob(rp, vec2(546.0, 120.0), -0.4, vec2(5.0, 6.5), px)),
			max(print_blob(rp, vec2(168.0, 304.0), 0.9, vec2(5.0, 6.0), px), print_blob(rp, vec2(520.0, 206.0), -0.8, vec2(5.5, 6.5), px)));
	vec2 wq = rot2(rp - vec2(250.0, 18.0), 0.1) / vec2(46.0, 5.5);
	float wipe = smoothstep(1.0, 0.2, length(wq)) * (0.5 + 0.6 * vnoise(rp * vec2(0.4, 1.6) + 11.0));
	vec2 wq2 = rot2(rp - vec2(390.0, 344.0), -0.15) / vec2(60.0, 6.0);
	wipe = max(wipe, smoothstep(1.0, 0.2, length(wq2)) * (0.5 + 0.6 * vnoise(rp * vec2(0.4, 1.6) + 51.0)));
	float a_sm = clamp(pr * 0.11 + wipe * 0.06, 0.0, 0.2) * smudges;
	acc += vec3(0.88, 0.9, 0.92) * a_sm;
	asum += a_sm;

	// fine scratches
	float fa = ridge(vnoise(vec2(rp.x * 0.09 + rp.y * 0.04, rp.y * 1.3 - rp.x * 0.5)), 0.972) * smoothstep(0.4, 0.7, vnoise(rp * 0.05 + 8.0));
	float fb = ridge(vnoise(vec2(rp.x * 1.2 + rp.y * 0.6, rp.y * 0.08 - rp.x * 0.12)), 0.975) * smoothstep(0.45, 0.75, vnoise(rp * 0.04 + 2.0));
	float arcs = scratches(rp, vec2(470.0, 300.0), vec2(30.0, 40.0), 14.0, 20.0, px, vec2(-0.6, -0.8));
	float a_sc = clamp(max(fa, fb) * 0.2 + arcs * 0.17, 0.0, 0.3) * scratch;
	acc += vec3(0.92, 0.94, 0.96) * a_sc;
	asum += a_sc;

	// the coin door sits in front of the glass
	vec2 dq = abs(rp - (door_rect.xy + door_rect.zw * 0.5)) - door_rect.zw * 0.5;
	float dd = max(dq.x, dq.y);
	float hide = smoothstep(0.0, 1.5, dd + 1.0);
	float a = clamp(asum, 0.0, 0.6) * hide;
	vec3 c = asum > 1e-5 ? acc / asum : vec3(1.0);
	COLOR = vec4(c, a);
}
