shader_type canvas_item;
// The arcade behind the cabinet (surround pass, owner direction 2026-11-19; warmed after the Fable review
// 2026-11-20): a late-70s / early-80s arcade floor seen past the cabinet with the lens focused on the cabinet, so
// everything here is soft. An amber drop ceiling across the top, an oxblood carpet band across the bottom, a dim
// far row of machines, two recognisable upright cabinets per side (lit warm marquee, screen, control panel, two
// coin lamps) keyed to the sheet's edges, one player standing at a cabinet, warm smoke haze and a gentle 35 mm
// grain. Warm tungsten, not cool neon: the other machines' hues are pulled toward tungsten (warmth). It only
// fills the window beyond the printed sheet, kept two to three stops under the bezel and darkest next to the
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
uniform vec3 ceiling_color = vec3(0.16, 0.11, 0.07);
uniform float warmth = 0.7;      // how far the other machines' hues are pulled toward tungsten
uniform vec3 neon[6];          // set by ArcadeBackdrop from CabinetSurface.backdrop_neon

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
		vec3 nc = mix(neon_of(h1), tungsten_color, warmth);
		vec3 sc = mix(mix(vec3(0.25, 0.42, 0.9), neon_of(h3), 0.45), tungsten_color, warmth * 0.6);
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
		col = mix(col, nc * mk, soft(md, b));
		glow += nc * exp(-max(md, 0.0) / (b * 3.0 + 6.0)) * 0.34;
		// the screen, set back in the cabinet
		vec2 sp = vec2(cx, base - hh * 0.6);
		float sd = sd_box(rp - sp, vec2(ww * 0.31, hh * 0.13));
		col = mix(col, sc * 0.42, soft(sd, b));
		glow += sc * exp(-max(sd, 0.0) / (b * 2.2 + 3.0)) * 0.1;
		// the control panel jutting out below the screen, lit by it
		vec2 pc = vec2(cx, base - hh * 0.37);
		float pd = sd_box(rp - pc, vec2(ww * 0.56, hh * 0.028));
		col = mix(col, wall_color * 0.9 + sc * 0.14 + tungsten_color * 0.03, soft(pd, b));
		// the screen's light on the carpet in front of it
		vec2 fp = (rp - vec2(cx, base + 5.0)) / vec2(ww * 0.8, 6.0 + b);
		glow += sc * 0.14 * exp(-dot(fp, fp));
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

// The ceiling: a drop ceiling of acoustic tiles in perspective, about one in three an amber light panel (the
// reference photos' warm ceiling), soft with the defocus.
vec3 ceiling(vec2 rp, float b) {
	float yv = 66.0;                                   // the ceiling's vanishing line
	float dy = max(yv - rp.y, 1.0);
	float u = 120.0 / dy;                              // tile rows: closer rows are taller, near the top
	float xw = (rp.x - 320.0) / dy * 1.5;
	vec2 id = floor(vec2(xw, u));
	vec2 f = fract(vec2(xw, u));
	float soft_k = clamp(b / dy * 0.6, 0.02, 0.3);
	float inset = smoothstep(0.1, 0.1 + soft_k, min(f.x, 1.0 - f.x)) * smoothstep(0.12, 0.12 + soft_k, min(f.y, 1.0 - f.y));
	float lit = step(hash21(id + 5.3), 0.34);
	vec3 tile = ceiling_color * (0.8 + 0.3 * hash21(id + 9.1));
	vec3 c = mix(ceiling_color * 0.45, tile, inset);   // dark grid between the tiles
	c = mix(c, tungsten_color * 1.15, lit * inset);
	return c;
}

// One recognisable upright cabinet seen from the front: a lit marquee with blurred dark lettering, the screen in
// its recess, the control panel ledge, and the coin door with its two lit coin lamps. `mk` is the marquee hue.
void cabinet_front(vec2 rp, float cx, float base, float h, float w, float b, vec3 mk, vec3 sc, inout vec3 col, inout vec3 glow) {
	float top = base - h;
	float d = sd_box(rp - vec2(cx, base - h * 0.5), vec2(w * 0.5, h * 0.5));
	vec3 body = wall_color * 0.7 + tungsten_color * 0.05 * smoothstep(top + h * 0.3, top, rp.y);
	col = mix(col, body, soft(d, b));
	// marquee (slightly wider than the body), warm and lit, the title a dark blurred band with gaps
	float mh = h * 0.06;
	vec2 mc = vec2(cx, top + mh);
	float md = sd_box(rp - mc, vec2(w * 0.53, mh));
	float letters = smoothstep(mh * 0.55, mh * 0.2, abs(rp.y - mc.y)) * step(0.3, hash21(vec2(floor((rp.x - cx) / 5.0), cx))) * step(abs(rp.x - cx), w * 0.36);
	col = mix(col, mk * (1.0 - 0.6 * letters), soft(md, b));
	glow += mk * exp(-max(md, 0.0) / (b * 2.5 + 5.0)) * 0.3;
	// the screen in its dark recess
	float rd = sd_box(rp - vec2(cx, top + h * 0.32), vec2(w * 0.4, h * 0.17));
	col = mix(col, wall_color * 0.3, soft(rd, b));
	float sd = sd_box(rp - vec2(cx, top + h * 0.32), vec2(w * 0.3, h * 0.13));
	col = mix(col, sc * 0.45, soft(sd, b));
	glow += sc * exp(-max(sd, 0.0) / (b * 2.0 + 3.0)) * 0.08;
	// control panel ledge, lit by the screen and the ceiling
	float pd = sd_box(rp - vec2(cx, top + h * 0.53), vec2(w * 0.57, h * 0.035));
	col = mix(col, wall_color * 0.9 + sc * 0.1 + tungsten_color * 0.1, soft(pd, b));
	// coin door with two lit coin lamps (red-orange)
	float cd = sd_box(rp - vec2(cx, top + h * 0.78), vec2(w * 0.17, h * 0.09));
	col = mix(col, wall_color * 0.4, soft(cd, b));
	vec3 lamp = vec3(1.0, 0.36, 0.12);
	for (int k = 0; k < 2; k++) {
		float lx = cx + (k == 0 ? -1.0 : 1.0) * w * 0.08;
		float ld = sd_box(rp - vec2(lx, top + h * 0.74), vec2(w * 0.035, h * 0.018));
		col = mix(col, lamp * 0.9, soft(ld, b * 0.7));
		glow += lamp * exp(-max(ld, 0.0) / (b + 3.0)) * 0.12;
	}
	// its screen's light on the carpet in front
	vec2 fp = (rp - vec2(cx, base + 6.0)) / vec2(w * 0.8, 7.0 + b);
	glow += sc * 0.1 * exp(-dot(fp, fp));
}

// One player standing at a cabinet, back to us: a dark silhouette with the cabinet's light round the head and
// shoulders.
void person(vec2 rp, float px, float base, float hgt, float b, vec3 rim, inout vec3 col, inout vec3 glow) {
	float head = length(rp - vec2(px, base - hgt * 0.92)) - hgt * 0.068;
	float torso = sd_box(rp - vec2(px, base - hgt * 0.66), vec2(hgt * 0.13, hgt * 0.17)) - hgt * 0.03;
	float legs = min(sd_box(rp - vec2(px - hgt * 0.06, base - hgt * 0.25), vec2(hgt * 0.045, hgt * 0.25)),
			sd_box(rp - vec2(px + hgt * 0.06, base - hgt * 0.25), vec2(hgt * 0.045, hgt * 0.25)));
	float d = min(min(head, torso), legs);
	col = mix(col, wall_color * 0.25, soft(d, b));
	glow += rim * exp(-abs(d) / 2.5) * 0.18 * smoothstep(base - hgt * 0.45, base - hgt, rp.y);
}

void fragment() {
	vec2 rp = rig_origin + UV * rect_size;
	float ds = max(sheet_x.x - trim - rp.x, rp.x - (sheet_x.y + trim));      // > 0 beyond the cabinet
	if (ds <= 0.0) {
		COLOR = vec4(0.0);
	} else {
		float b = 6.0 * blur;
		float yk = clamp(rp.y / cab_view_h, 0.0, 1.0);
		vec3 warm_mk = tungsten_color * 1.1;
		// wall: dark plum, warmer under the ceiling
		vec3 col = wall_color * (1.1 + 1.0 * smoothstep(200.0, 60.0, rp.y));
		col *= 0.85 + 0.3 * vnoise(vec2(rp.x * 0.02, 3.0));
		// the amber drop ceiling across the top
		col = mix(col, ceiling(rp, b), smoothstep(70.0, 58.0, rp.y));
		// oxblood carpet band across the bottom: a low, dim woven pattern, no neon
		float fl = smoothstep(HORIZON - 4.0, HORIZON + 4.0, rp.y);
		if (fl > 0.0) {
			float depth = clamp((rp.y - HORIZON) / 120.0, 0.0, 1.0);
			vec3 carpet = carpet_color * (0.6 + 0.6 * depth);
			float s = mix(5.0, 14.0, depth);
			vec2 q = vec2(rp.x / s, (rp.y - HORIZON) / (s * 0.5));
			float weave = step(0.5, hash21(floor(q) + 3.0)) * (1.0 - smoothstep(0.15, 0.48, length(fract(q) - 0.5)));
			carpet = mix(carpet, carpet * 1.6 + tungsten_color * 0.04, weave * 0.4);
			col = mix(col, carpet, fl);
		}
		vec3 glow = vec3(0.0);
		// a far row of machines (dim, small), then two near cabinets per side, keyed to the sheet's edges
		cabinet_row(rp, 66.0, 11.0, HORIZON + 2.0, 118.0, 42.0, b * 1.3, 1.7, 0.55, col, glow);
		vec3 sc0 = mix(neon[1], tungsten_color, warmth);
		vec3 sc1 = mix(neon[3], tungsten_color, warmth);
		cabinet_front(rp, sheet_x.x - 132.0, 304.0, 150.0, 54.0, b * 1.15, mix(neon[2], warm_mk, warmth), sc1, col, glow);
		cabinet_front(rp, sheet_x.x - 52.0, 338.0, 205.0, 72.0, b, mix(neon[4], warm_mk, warmth), sc0, col, glow);
		cabinet_front(rp, sheet_x.y + 140.0, 304.0, 150.0, 54.0, b * 1.15, mix(neon[0], warm_mk, warmth), sc0, col, glow);
		cabinet_front(rp, sheet_x.y + 62.0, 338.0, 205.0, 72.0, b, warm_mk, sc1, col, glow);
		person(rp, sheet_x.y + 70.0, 356.0, 150.0, b * 0.9, sc1 + tungsten_color * 0.3, col, glow);
		// a few warm out-of-focus lights between the rows
		glow += bokeh_field(rp, vec2(58.0, 1.0), 96.0, 190.0, 0.3, 3.0, 7.0, 12.7, b, true) * 0.18;
		// smoke haze: a slow warm veil at head height
		float hz = vnoise(vec2(rp.x * 0.012, rp.y * 0.02)) * smoothstep(50.0, 140.0, rp.y) * smoothstep(300.0, 160.0, rp.y);
		glow += tungsten_color * hz * haze * 0.08;
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
		c *= 1.0 - 0.25 * vy * vy;
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
