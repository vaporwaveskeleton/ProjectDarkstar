shader_type canvas_item;
// The arcade behind the cabinet (surround pass, owner direction 2026-11-19): a late-70s / early-80s arcade floor
// seen past the cabinet with the lens focused on the cabinet, so everything here is soft. Rows of fictional
// cabinets as blurred silhouettes, their marquees and screens as soft neon bokeh, warm tungsten ceiling lights,
// a stray neon tube, a hint of maroon patterned carpet, smoke haze and a gentle 35 mm grain. It only fills the
// window beyond the printed sheet (wide and ultrawide windows), it is dim, desaturated and darkest next to the
// cabinet, so it never pulls the eye from the screen. Everything is a function of the rig position: no
// textures, no per-frame state (only the grain moves, and it freezes with photosensitivity on).
#include "res://shaders/cabinet/cabinet_material.gdshaderinc"

uniform vec2 rect_size = vec2(640.0, 360.0);
uniform vec2 rig_origin = vec2(0.0);
uniform vec2 sheet_x = vec2(40.0, 600.0);
uniform float trim = 3.2;
uniform float room_glow = 0.6;
uniform float exposure = 0.5;
uniform float blur = 1.0;
uniform float grain = 0.05;
uniform float grain_fps = 12.0;
uniform float desaturate = 0.3;
uniform float cabinet_shadow = 0.6;
uniform float haze = 0.5;
uniform vec3 wall_color = vec3(0.10, 0.06, 0.13);
uniform vec3 carpet_color = vec3(0.29, 0.055, 0.11);
uniform vec3 tungsten_color = vec3(1.0, 0.75, 0.47);
uniform vec3 neon[6];          // set by ArcadeBackdrop from CabinetSurface.backdrop_neon
// The cursed turn (TECH-001 Q-T294, cursed-cabinet; additive, 0 = as built): during the Decay the other machines
// in the arcade go dark one by one, in a fixed per-cabinet order; the ceiling lights and the room stay.
uniform float dark : hint_range(0.0, 1.0) = 0.0;

const float HORIZON = 238.0;    // where the far row stands (rig y)

float sd_box(vec2 p, vec2 b) {
	vec2 d = abs(p) - b;
	return length(max(d, 0.0)) + min(max(d.x, d.y), 0.0);
}

// coverage of a soft (defocused) shape from its signed distance
float soft(float d, float b) {
	return 1.0 - smoothstep(-b, b, d);
}

vec3 neon_of(float h) {
	return neon[int(floor(clamp(h, 0.0, 0.999) * 6.0))];
}

// One row of cabinets: dark silhouettes with a lit marquee and a glowing screen, painted over `col`; their light
// goes into `glow`. `s` scales the details with the row's distance.
void cabinet_row(vec2 rp, float pitch, float phase, float base, float h, float w, float b, float seed, float body_k,
		inout vec3 col, inout vec3 glow) {
	float ci = floor((rp.x - phase) / pitch);
	for (int k = -1; k <= 1; k++) {
		float i = ci + float(k);
		float h1 = hash21(vec2(i * 1.31, seed));
		float h2 = hash21(vec2(seed * 2.7, i * 0.77));
		float h3 = hash21(vec2(i * 0.53 + seed, 9.1));
		if (h2 < 0.1) {
			continue;   // a gap in the row
		}
		float cx = phase + (i + 0.5) * pitch + (h1 - 0.5) * pitch * 0.22;
		float hh = h * (0.9 + 0.18 * h2);
		float ww = w * (0.9 + 0.2 * h3);
		vec3 nc = neon_of(h1);
		vec3 sc = mix(vec3(0.25, 0.42, 0.9), neon_of(h3), 0.45);
		float lit = 1.0 - smoothstep(h3 * 0.82, h3 * 0.82 + 0.16, dark);   // this machine's turn to go dark
		// body
		vec2 c = vec2(cx, base - hh * 0.5);
		float d = sd_box(rp - c, vec2(ww * 0.5, hh * 0.5));
		float cov = soft(d, b);
		vec3 body = wall_color * body_k + nc * 0.035;
		body += tungsten_color * 0.05 * smoothstep(c.y + hh * 0.1, c.y - hh * 0.5, rp.y);   // top of the cabinet catching the ceiling light
		col = mix(col, body, cov);
		// marquee box at the top
		float mh = hh * 0.065;
		vec2 mc = vec2(cx, base - hh + mh + 1.0);
		float md = sd_box(rp - mc, vec2(ww * 0.44, mh));
		float mk = 0.55 + 0.45 * exp(-pow((rp.x - cx) / (ww * 0.28), 2.0));                 // brightest behind the blurred lettering
		col = mix(col, mix(body, nc * mk, lit), soft(md, b));
		glow += nc * exp(-max(md, 0.0) / (b * 3.0 + 6.0)) * 0.34 * lit;
		// the screen, set back in the cabinet
		vec2 sp = vec2(cx, base - hh * 0.6);
		float sd = sd_box(rp - sp, vec2(ww * 0.31, hh * 0.13));
		col = mix(col, mix(wall_color * 0.35, sc * 0.42, lit), soft(sd, b));
		glow += sc * exp(-max(sd, 0.0) / (b * 2.2 + 3.0)) * 0.1 * lit;
		// the control panel jutting out below the screen, lit by it
		vec2 pc = vec2(cx, base - hh * 0.37);
		float pd = sd_box(rp - pc, vec2(ww * 0.56, hh * 0.028));
		col = mix(col, wall_color * 0.9 + sc * 0.14 * lit + tungsten_color * 0.03, soft(pd, b));
		// the screen's light on the carpet in front of it
		vec2 fp = (rp - vec2(cx, base + 5.0)) / vec2(ww * 0.8, 6.0 + b);
		glow += sc * 0.14 * exp(-dot(fp, fp)) * lit;
	}
}

// Out-of-focus point lights: one disc per cell in `occupancy` of the cells, with the slightly brighter rim of
// real bokeh.
vec3 bokeh_field(vec2 rp, vec2 cell, float y0, float y1, float occupancy, float r0, float r1, float seed, float b, bool warm) {
	vec3 acc = vec3(0.0);
	if (rp.y < y0 - r1 - b || rp.y > y1 + r1 + b) {
		return acc;
	}
	float ci = floor(rp.x / cell.x);
	for (int k = -1; k <= 1; k++) {
		float i = ci + float(k);
		float h1 = hash21(vec2(i, seed));
		if (h1 > occupancy) {
			continue;
		}
		float h2 = hash21(vec2(seed, i * 1.9));
		float h3 = hash21(vec2(i * 0.37, seed * 3.1));
		vec2 c = vec2((i + 0.2 + 0.6 * h2) * cell.x, mix(y0, y1, h3));
		float r = mix(r0, r1, h2);
		float dist = length(rp - c);
		float disc = soft(dist - r, b);
		float rim = smoothstep(r - 2.5 * b, r - 0.5 * b, dist) * disc * 0.35;
		vec3 lc = warm ? tungsten_color : neon_of(h3);
		acc += lc * (disc * 0.5 + rim);
	}
	return acc;
}

void fragment() {
	vec2 rp = rig_origin + UV * rect_size;
	float ds = max(sheet_x.x - trim - rp.x, rp.x - (sheet_x.y + trim));      // > 0 beyond the cabinet
	if (ds <= 0.0) {
		COLOR = vec4(0.0);
	} else {
		float b = 6.0 * blur;
		float yk = clamp(rp.y / cab_view_h, 0.0, 1.0);
		// wall: dark plum, a little warmer toward the ceiling lights
		vec3 col = wall_color * (1.2 + 1.3 * smoothstep(240.0, 20.0, rp.y));          // the back wall, lit by the ceiling cans
		col *= 0.85 + 0.3 * vnoise(vec2(rp.x * 0.02, 3.0));                    // wall panels catching light unevenly
		// carpet below the horizon: maroon, a defocused pattern of coloured flecks
		float fl = smoothstep(HORIZON - 4.0, HORIZON + 4.0, rp.y);
		if (fl > 0.0) {
			float depth = clamp((rp.y - HORIZON) / 140.0, 0.0, 1.0);
			vec3 carpet = carpet_color * (0.55 + 0.6 * depth);
			float s = mix(5.0, 16.0, depth);
			vec2 q = vec2(rp.x / s, (rp.y - HORIZON) / (s * 0.5));
			vec2 id = floor(q);
			vec2 f = fract(q) - 0.5;
			float hc = hash21(id + 3.0);
			float dot_k = (1.0 - smoothstep(0.12, 0.48, length(f))) * step(0.5, hc);
			carpet = mix(carpet, neon_of(hash21(id + 11.0)) * 0.45 * (0.5 + 0.5 * depth), dot_k * 0.35);
			carpet *= 0.85 + 0.3 * vnoise(rp * 0.05);
			col = mix(col, carpet, fl);
		}
		vec3 glow = vec3(0.0);
		// the far row, then the nearer row (bigger, darker bodies, standing lower)
		cabinet_row(rp, 66.0, 11.0, HORIZON + 2.0, 128.0, 44.0, b * 1.3, 1.7, 0.55, col, glow);
		cabinet_row(rp, 158.0, 61.0, 318.0, 236.0, 88.0, b, 5.3, 0.25, col, glow);
		// ceiling: tungsten cans as big soft discs, and stray neon bokeh up in the dark
		glow += bokeh_field(rp, vec2(74.0, 1.0), 10.0, 22.0, 0.8, 5.0, 8.0, 2.2, b, true) * 0.55;
		glow += bokeh_field(rp, vec2(46.0, 1.0), 40.0, 96.0, 0.6, 2.5, 6.0, 8.4, b * 0.8, false) * 0.5;
		glow += bokeh_field(rp, vec2(58.0, 1.0), 100.0, 200.0, 0.35, 3.0, 7.0, 12.7, b, false) * 0.28;   // more neon bokeh between the rows
		// a neon tube on the far wall, one segment per stretch of wall
		float seg = floor(rp.x / 230.0);
		float hs = hash21(vec2(seg, 4.4));
		if (hs > 0.35) {
			float x0 = (seg + 0.15 + 0.2 * hs) * 230.0;
			float x1 = x0 + 60.0 + 70.0 * hash21(vec2(seg, 7.7));
			float ty = 60.0 + 14.0 * hs;
			vec2 pa = rp - vec2(x0, ty);
			vec2 ba = vec2(x1 - x0, 0.0);
			float t = clamp(dot(pa, ba) / dot(ba, ba), 0.0, 1.0);
			float dl = length(pa - ba * t);
			vec3 tc = neon_of(hash21(vec2(seg, 1.3)));
			glow += tc * (soft(dl - 1.2, b * 0.8) * 0.6 + exp(-dl / 14.0) * 0.18);
		}
		// smoke haze: a slow warm veil at head height
		float hz = vnoise(vec2(rp.x * 0.012, rp.y * 0.02)) * smoothstep(20.0, 140.0, rp.y) * smoothstep(300.0, 160.0, rp.y);
		glow += tungsten_color * hz * haze * 0.08;
		glow += mix(neon[0], neon[2], 0.5) * haze * 0.025 * smoothstep(300.0, 120.0, rp.y);   // a faint warm neon cast in the smoke
		// our cabinet's own screen light on the floor and walls round it (as the room had it)
		float far = exp(-ds / 90.0);
		float lum = 0.14 + 0.86 * cab_screen_light.a;
		float floor_pool = smoothstep(0.45, 1.0, yk);
		glow += cab_screen_light.rgb * lum * room_glow * (0.12 * far * (0.3 + 1.4 * floor_pool * floor_pool));
		vec3 c = (col + glow) * exposure;
		// keep it out of the way: desaturate, darken next to the cabinet (its body and shadow) and toward the
		// window's top and bottom
		float l = dot(c, vec3(0.299, 0.587, 0.114));
		c = mix(c, vec3(l), desaturate);
		c *= 1.0 - cabinet_shadow * exp(-ds / 34.0);
		float vy = (rig_origin.y + rect_size.y * 0.5 - rp.y) / (rect_size.y * 0.5);
		c *= 1.0 - 0.35 * vy * vy;
		// 35 mm grain: per display pixel, refreshed at grain_fps (0 = frozen)
		float gt = grain_fps > 0.0 ? floor(TIME * grain_fps) : 0.0;
		uint h = uint(FRAGCOORD.x) * 1973u + uint(FRAGCOORD.y) * 9277u + uint(gt) * 26699u;
		h = (h ^ (h >> 13u)) * 1274126177u;
		h ^= h >> 16u;
		float g = float(h & 65535u) / 65535.0 - 0.5;
		c += g * grain * (0.35 + l);
		COLOR = vec4(max(c, vec3(0.0)), 1.0);
	}
}
