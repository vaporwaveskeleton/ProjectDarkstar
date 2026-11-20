shader_type canvas_item;
render_mode blend_add, unshaded;
// Warp T1 mote field (WARP-001 W1-01 Wrong Three accents, W1-03 Parallax Arrives near layers; TECH-001
// §5.1a). One full-field pass, procedural: no textures, no per-mote nodes. Three parallax sheets of
// aether motes drift in a slow current around the camera; a few in each sheet wear the Wrong Three
// hues. Colours arrive as uniforms from Pal (ART-001 §14); additive light is the T1 lighting
// derivation ART-001 §15 allows. Readability: behind the play layer, value-capped by `intensity`.
// Photosensitivity: `twinkle` = 0 (no brightness change over time). Reduced motion: `drift` = 0.

uniform vec2 view_size = vec2(640.0, 360.0);
uniform vec2 cam = vec2(0.0);            // world-space camera centre (continuous through torus rebases)
uniform float t = 0.0;                    // composer clock (s), never wall time
uniform float intensity : hint_range(0.0, 1.0) = 1.0;   // seam depth × fade-in
uniform float density : hint_range(0.0, 1.0) = 0.7;    // fraction of cells holding a mote
uniform float drift : hint_range(0.0, 1.0) = 1.0;
uniform float twinkle : hint_range(0.0, 1.0) = 1.0;
uniform float breath : hint_range(-1.0, 1.0) = 0.0;      // W1-02 phase, shared with the units
uniform bool foreground = false;          // the sparse near sheet in front of the play layer
uniform vec4 base_a : source_color;
uniform vec4 base_b : source_color;
uniform vec4 wrong_a : source_color;
uniform vec4 wrong_b : source_color;
uniform vec4 wrong_c : source_color;
uniform float wrong_share : hint_range(0.0, 1.0) = 0.12;

float h21(vec2 p) {
	p = fract(p * vec2(123.34, 456.21));
	p += dot(p, p + 45.32);
	return fract(p.x * p.y);
}

vec2 h22(vec2 p) {
	float n = h21(p);
	return vec2(n, h21(p + n + 17.17));
}

vec4 pick(float r) {
	if (r < wrong_share * 0.34) return wrong_a;
	if (r < wrong_share * 0.67) return wrong_b;
	if (r < wrong_share) return wrong_c;
	return r < 0.6 ? base_a : base_b;
}

// One sheet: parallax factor p, cell size c (px), mote radius r (px), brightness k.
vec3 sheet(vec2 px, float p, float c, float r, float k, float seed) {
	vec2 flow = vec2(7.0, -3.0) * t * drift * p;
	vec2 pos = px + cam * p + flow + vec2(seed * 311.0, seed * 173.0);
	pos.x += sin(pos.y * 0.013 + t * 0.21 * drift + seed) * 9.0 * drift;
	pos.y += sin(pos.x * 0.009 + t * 0.17 * drift) * 6.0 * drift;
	vec2 cell = floor(pos / c);
	vec3 acc = vec3(0.0);
	for (int j = -1; j <= 1; j++) {
		for (int i = -1; i <= 1; i++) {
			vec2 cc = cell + vec2(float(i), float(j));
			float present = h21(cc + seed);
			if (present > density) continue;
			vec2 o = h22(cc * 1.7 + seed);
			vec2 centre = (cc + 0.15 + o * 0.7) * c;
			float d = length(pos - centre);
			float size = r * (0.55 + o.x * 0.9) * (1.0 + breath * 0.12);
			float core = smoothstep(size, size * 0.25, d);
			float halo = exp(-d * d / (size * size * 9.0)) * 0.35;
			float ph = o.y * 6.2831;
			float tw = mix(1.0, 0.55 + 0.45 * sin(t * (0.6 + o.x * 1.3) + ph), twinkle);
			vec4 col = pick(h21(cc + 9.1 + seed));
			acc += col.rgb * (core + halo) * tw * k;
		}
	}
	return acc;
}

void fragment() {
	vec2 px = UV * view_size;
	vec3 c = vec3(0.0);
	if (foreground) {
		c += sheet(px, 1.45, 150.0, 5.0, 0.32, 7.0);
	} else {
		c += sheet(px, 0.30, 24.0, 0.9, 0.85, 1.0);
		c += sheet(px, 0.55, 40.0, 1.3, 0.80, 2.0);
		c += sheet(px, 0.85, 64.0, 1.9, 0.70, 3.0);
	}
	COLOR = vec4(c * intensity, 1.0);
}
