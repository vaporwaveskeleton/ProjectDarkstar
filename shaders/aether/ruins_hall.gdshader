shader_type canvas_item;
// The Ruins hall's surfaces (lit by the hall's PointLight2Ds; ambient from its CanvasModulate):
// the back wall's ashlar with two blind-arcade bays, the floor's flagstones in perspective, the
// hangar mouth (a pointed arch whose deck runs out) and the torn vault. The openings are cut out
// under a veil so the Aether behind reads far and OUTSIDE. Albedos are Pal entries (uniforms);
// nothing here is black (the only true black is the entity, ART-001 §16).

uniform vec2 size_px = vec2(640.0, 360.0);
uniform vec4 mouth = vec4(484.0, 116.0, 132.0, 186.0);   // x, y, w, h (logical px)
uniform float floor_y = 300.0;
uniform vec2 vanish = vec2(320.0, 150.0);
uniform vec2 hole_c = vec2(150.0, 10.0);
uniform vec2 hole_r = vec2(122.0, 70.0);
uniform vec4 bays = vec4(62.0, 208.0, 252.0, 428.0);    // two blind-arcade bays (x0, x1, x0, x1)
uniform float bay_spring = 150.0;
uniform vec4 stone_a : source_color;
uniform vec4 stone_b : source_color;
uniform vec4 mortar : source_color;
uniform vec4 floor_a : source_color;
uniform vec4 floor_b : source_color;
uniform vec4 veil_col : source_color;
uniform float mouth_veil = 0.9;
uniform float hole_veil = 0.55;
uniform float reveal_px = 7.0;   // ✱ wall thickness seen inside the mouth's jambs
uniform float deck_px = 12.0;    // ✱ the deck seen running out through the mouth

float hash(vec2 p) {
	p = fract(p * vec2(123.34, 456.21));
	p += dot(p, p + 45.32);
	return fract(p.x * p.y);
}

float vnoise(vec2 p) {
	vec2 i = floor(p);
	vec2 f = fract(p);
	vec2 u = f * f * (3.0 - 2.0 * f);
	return mix(mix(hash(i), hash(i + vec2(1.0, 0.0)), u.x), mix(hash(i + vec2(0.0, 1.0)), hash(i + vec2(1.0, 1.0)), u.x), u.y);
}

// Signed distance (px, negative inside) to a pointed arch filling rect r, with apex height ah.
float arch_sd(vec2 p, vec4 r, float ah) {
	float w = r.z;
	float spring = r.y + ah;
	float sides = max(r.x - p.x, p.x - (r.x + w));
	float bottom = p.y - (r.y + r.w);
	if (p.y >= spring) {
		return max(sides, bottom);
	}
	float R = (ah * ah + w * w * 0.25) / w;
	float a = length(p - vec2(r.x + R, spring)) - R;
	float b = length(p - vec2(r.x + w - R, spring)) - R;
	return max(max(a, b), sides);
}

// The torn vault: a ragged hole through the roof (no closed organic shapes; jagged, wide).
float hole_sd(vec2 p) {
	vec2 q = (p - hole_c) / hole_r;
	float ang = atan(q.y, q.x);
	float k = floor(ang * 7.0 / 6.2831 * 3.0);
	float jag = (hash(vec2(k, 3.1)) - 0.5) * 0.22 + (vnoise(vec2(ang * 9.0, 1.7)) - 0.5) * 0.16;
	return (length(q) - (1.0 + jag)) * min(hole_r.x, hole_r.y);
}

float aa(float sd) {
	float w = max(fwidth(sd), 0.001);
	return clamp(0.5 - sd / w, 0.0, 1.0);
}

vec3 wall(vec2 p) {
	// ashlar: 14 px courses, 30 px blocks, alternate courses offset
	float course = floor(p.y / 14.0);
	float x = p.x + mod(course, 2.0) * 15.0;
	float block = floor(x / 30.0);
	vec2 f = vec2(fract(x / 30.0) * 30.0, fract(p.y / 14.0) * 14.0);
	float h = hash(vec2(block, course));
	vec3 c = mix(stone_b.rgb, stone_a.rgb, 0.35 + 0.65 * h);
	// grain and grime: soot toward the vault, damp toward the floor
	c *= 0.82 + 0.3 * vnoise(p * 0.21 + h * 7.0);
	c *= mix(0.55, 1.0, smoothstep(10.0, 120.0, p.y));
	c *= mix(1.0, 0.8, smoothstep(floor_y - 40.0, floor_y, p.y));
	float joint = min(min(f.x, 30.0 - f.x), min(f.y, 14.0 - f.y));
	// worn joints: mortar half-blended, a lit upper arris on each block
	c = mix(mix(c, mortar.rgb, 0.5), c, smoothstep(0.3, 1.1, joint));
	c *= 1.0 + 0.12 * (1.0 - smoothstep(0.8, 2.2, f.y)) * step(0.6, joint);
	// spalled stone: a few blocks broken back to rough, darker faces
	c *= mix(1.0, 0.72, step(0.88, h) * smoothstep(0.35, 0.75, vnoise(p * 0.18)));
	// blind-arcade bays: recessed, darker, with a chamfer catching light
	float bay = min(arch_sd(p, vec4(bays.x, 40.0, bays.y - bays.x, floor_y - 40.0), bay_spring - 40.0),
		arch_sd(p, vec4(bays.z, 40.0, bays.w - bays.z, floor_y - 40.0), bay_spring - 40.0));
	c *= mix(1.0, 0.62, aa(bay));
	c = mix(c, stone_a.rgb * 1.15, aa(abs(bay + 1.5) - 1.0) * 0.6);
	return c;
}

vec3 floor_col(vec2 p) {
	float dy = max(p.y - vanish.y, 1.0);
	float u = (p.x - vanish.x) / dy;           // lateral (perspective)
	float v = 900.0 / dy;                      // depth
	vec2 g = vec2(u * 2.4, v * 0.55);
	vec2 cell = floor(g);
	vec2 f = fract(g);
	float h = hash(cell + 11.0);
	vec3 c = mix(floor_b.rgb, floor_a.rgb, 0.45 + 0.55 * h);
	c *= 0.85 + 0.25 * vnoise(p * vec2(0.12, 0.3) + h * 5.0);
	vec2 jw = fwidth(g) * 1.2;
	float joint = min(smoothstep(0.0, jw.x, f.x) * smoothstep(0.0, jw.x, 1.0 - f.x),
		smoothstep(0.0, jw.y, f.y) * smoothstep(0.0, jw.y, 1.0 - f.y));
	c = mix(mortar.rgb, c, joint);
	// a stone plinth where wall meets floor
	c = mix(c, stone_a.rgb * 0.9, 1.0 - smoothstep(0.0, 3.0, p.y - floor_y));
	return c;
}

void fragment() {
	vec2 p = UV * size_px;
	vec3 c = p.y >= floor_y ? floor_col(p) : wall(p);
	float alpha = 1.0;
	// the hangar mouth: a pointed arch; its deck runs out under the opening
	float ah = min(mouth.z * 0.62, mouth.w * 0.5);
	float msd = arch_sd(p, mouth, ah);
	float open_m = aa(msd + reveal_px) * aa(p.y - (floor_y - deck_px));
	float reveal = aa(msd) * (1.0 - open_m);
	// moulding round the arch, then the jamb reveal (the wall's thickness, darker)
	c = mix(c, stone_a.rgb * 1.25, aa(abs(msd - 3.0) - 2.0) * (1.0 - aa(msd)) * step(p.y, floor_y));
	c = mix(c, stone_b.rgb * 0.7, reveal * step(p.y, floor_y - deck_px));
	// the deck out through the mouth: two brass launch rails converge toward the outside
	if (p.y < floor_y && p.y >= floor_y - deck_px && msd < 0.0) {
		c = floor_a.rgb * 0.85;
		float mid = mouth.x + mouth.z * 0.5;
		float k = (floor_y - p.y) / deck_px;
		float half_gap = mix(22.0, 9.0, k);
		float rail = min(abs(p.x - (mid - half_gap)), abs(p.x - (mid + half_gap)));
		c = mix(c, stone_a.rgb * 1.6, 1.0 - smoothstep(0.4, 1.2, rail));
	}
	// rails continue across the hall floor to the mouth
	if (p.y >= floor_y && p.x > mouth.x - 20.0) {
		float mid = mouth.x + mouth.z * 0.5;
		float dy = p.y - floor_y;
		float half_gap = 22.0 + dy * 0.9;
		float rail = min(abs(p.x - (mid - half_gap)), abs(p.x - (mid + half_gap)));
		c = mix(c, stone_a.rgb * 1.5, (1.0 - smoothstep(0.4, 1.3, rail)) * (1.0 - smoothstep(30.0, 60.0, dy)));
	}
	vec3 veil = veil_col.rgb;
	if (open_m > 0.0) {
		c = mix(c, veil, open_m);
		alpha = mix(1.0, mouth_veil, open_m);
	}
	// the torn vault
	float hs = hole_sd(p);
	float open_h = aa(hs) * step(p.y, floor_y - 20.0);
	// broken stone rim round the tear: lighter, ragged
	c = mix(c, stone_a.rgb * 1.2, aa(abs(hs - 2.0) - 1.6) * (1.0 - open_h));
	if (open_h > 0.0) {
		c = mix(c, veil, open_h);
		alpha = min(alpha, mix(1.0, hole_veil, open_h));
	}
	COLOR = vec4(c, alpha);
}
