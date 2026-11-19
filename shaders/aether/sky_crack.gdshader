shader_type canvas_item;
render_mode unshaded;
// Sky cracks (T4, ART-001 §16): glass, not lightning. Fine straight-segment fractures struck into
// the crystal sphere, foreshortened along its curve, hairline PHOS_5 at low alpha (<= 0.5). Each
// shard bends the fog behind it by its own small offset, like a broken pane. Through the wide
// slivers shows the Aether BEHIND the Aether: lavender / pearl, offset in hue and parallax, its own
// tiny stars and a second sphere seam curving the opposite way. The cracks catch the lantern:
// brighter nearest it. Colours arrive from GDScript (Pal); defaults are overwritten at runtime.

#include "res://shaders/aether/aether_common.gdshaderinc"

uniform sampler2D screen_tex : hint_screen_texture, filter_linear_mipmap;
uniform vec3 edge_col : source_color = vec3(0.66, 0.94, 0.82);
uniform vec3 behind_a : source_color = vec3(0.44, 0.36, 0.72);
uniform vec3 behind_b : source_color = vec3(0.91, 0.86, 0.85);
uniform vec3 seam_col : source_color = vec3(0.66, 0.94, 0.82);
uniform vec3 floor_col : source_color = vec3(0.039, 0.039, 0.07);
uniform float amount : hint_range(0.0, 1.0) = 0.5;
uniform float time_s = 0.0;
uniform float drain = 0.0;
uniform vec2 sphere_c = vec2(620.0, 1200.0);   // local px (same space as the impacts)
uniform float sphere_r = 900.0;
uniform vec2 camera_offset = vec2(0.0);
uniform vec2 lantern_px = vec2(320.0, 202.0);
uniform vec4 impact_a = vec4(640.0, 300.0, 210.0, 1.3);   // local px xy, reach, seed
uniform vec4 impact_b = vec4(1010.0, 330.0, 160.0, 4.7);
uniform vec4 impact_c = vec4(330.0, 350.0, 120.0, 8.2);
uniform float line_alpha = 0.45;

varying vec2 v_px;

void vertex() {
	v_px = VERTEX;
}

vec2 tang_at(vec2 hit) {
	vec2 n = normalize(hit - sphere_c);
	return vec2(-n.y, n.x);
}

void fragment() {
	vec2 spx = SCREEN_UV * screen_size;
	float fw = max(fwidth(v_px.x), 0.2);
	vec4 imps[3] = vec4[3](impact_a, impact_b, impact_c);
	// pass 3: two impacts open WIDE gaps so the content behind reads clearly; one stays a hairline
	float gap_ws[3] = float[3](10.0, 8.0, 3.4);
	float line = 1e4;
	float gap = 0.0;
	vec2 shard = vec2(0.0);
	float pane = 0.0;
	for (int i = 0; i < 3; i++) {
		vec4 im = imps[i];
		float reach = im.z * amount;
		vec2 g = a_glass(v_px, im.xy, reach, im.w, tang_at(im.xy), 0.45, gap_ws[i]);
		line = min(line, g.x);
		gap = max(gap, g.y);
		vec2 dd = v_px - im.xy;
		float rr = length(dd);
		if (rr < reach * 0.85) {
			// each shard refracts by its own small offset
			float sector = floor((atan(dd.y, dd.x) - im.w) / 1.0471976);
			vec2 o = (vec2(a_hash(vec2(sector, im.w)), a_hash(vec2(im.w, sector))) - 0.5) * 7.0;
			float w = 1.0 - smoothstep(reach * 0.55, reach * 0.85, rr);
			shard += o * w;
			pane = max(pane, w);
		}
	}
	float hair = 1.0 - smoothstep(0.5 * fw, 1.6 * fw, line);
	// the Aether behind the Aether: other hue, other parallax, its own stars, a reversed seam
	// its parallax runs AGAINST ours (camera_offset * -0.9) and it drifts on its own, the other way
	vec2 bp = v_px * 0.82 - camera_offset * 0.9 + vec2(time_s * 2.4, -time_s * 0.9);
	vec2 q = bp / 46.0 + vec2(-time_s * 0.05, time_s * 0.02);
	float c = a_fbm(q + 1.8 * vec2(a_fbm(q + time_s * 0.03, 3), a_fbm(q - 5.0, 3)), 4);
	vec3 inner = mix(behind_a, behind_b, smoothstep(0.3, 0.75, c));
	// its own stars, denser and faster than ours (a nearer sky behind the sky)
	vec2 sg = (bp + vec2(time_s * 4.0, 0.0)) / 4.0;
	vec2 sid = floor(sg);
	float sh = a_hash(sid + 4.2);
	inner += behind_b * step(0.86, sh) * exp(-pow(length(sg - sid - 0.5) * 4.0, 2.0) * 1.5) * 1.1;
	vec2 rev_c = sphere_c - vec2(0.0, 2.0 * sphere_r) + vec2(90.0, 70.0) - camera_offset * 0.9;
	float d2 = length(bp - rev_c) - sphere_r;
	inner += seam_col * exp(-abs(d2) / 1.2) * 0.8;
	// the broken pane: fog behind each shard, displaced by that shard's offset
	vec3 bent = textureLod(screen_tex, SCREEN_UV + shard / screen_size, 0.0).rgb;
	float lamp = exp(-length(spx - lantern_px) / 260.0);
	vec3 col = bent;
	float a = pane * step(0.01, length(shard));
	col = mix(col, inner, gap);
	a = max(a, gap);
	float la = hair * line_alpha * (0.55 + 0.45 * lamp);
	col = mix(col, edge_col * (1.0 + 0.6 * lamp), la);
	a = max(a, la);
	col = mix(col, vec3(a_luma(col)), drain);
	a *= 1.0 - a_loss(spx).z;
	col = max(col, floor_col);
	COLOR = vec4(col, clamp(a, 0.0, 1.0));
}
