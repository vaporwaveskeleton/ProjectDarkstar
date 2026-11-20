shader_type canvas_item;
// The Aether menus' fogged-glass face (MenuFrame, BRASS costume; TECH-001 §2.9b, UI-001 §10).
// Smoked glass with fog drifting slowly behind it, at low contrast so the text stays clear, plus a
// vignette towards the brass. Colours come from Pal as uniforms (no literals). `drift` is the time
// in seconds, set by MenuFrame; it holds still under Reduced Motion or Photosensitivity.
// All values are presentation values (✱), not tunables.

uniform vec4 glass : source_color;        // the smoked glass (Pal.VOID_1)
uniform vec4 fog_a : source_color;        // fog, cool (Pal.CHOIR_1)
uniform vec4 fog_b : source_color;        // fog, warm (Pal.GAS_1)
uniform float contrast = 0.08;            // fog amplitude over the glass (5..10 %)
uniform float vignette = 0.35;            // darkening at the edges
uniform float drift = 0.0;                // seconds
uniform vec2 rect_size = vec2(400.0, 240.0);

float hash(vec2 p) {
	return fract(sin(dot(p, vec2(127.1, 311.7))) * 43758.5453);
}

float noise(vec2 p) {
	vec2 i = floor(p);
	vec2 f = fract(p);
	vec2 u = f * f * (3.0 - 2.0 * f);
	return mix(mix(hash(i), hash(i + vec2(1.0, 0.0)), u.x), mix(hash(i + vec2(0.0, 1.0)), hash(i + vec2(1.0, 1.0)), u.x), u.y);
}

float fbm(vec2 p) {
	float v = 0.0;
	float a = 0.5;
	for (int k = 0; k < 4; k++) {
		v += a * noise(p);
		p = p * 2.03 + vec2(17.0, 9.0);
		a *= 0.5;
	}
	return v;
}

void fragment() {
	vec2 px = UV * rect_size;
	vec2 p = px / 90.0;
	float t = drift * 0.025;
	float n1 = fbm(p + vec2(t, t * 0.4));
	float n2 = fbm(p * 1.7 - vec2(t * 0.6, -t * 0.3) + 4.0);
	vec3 fog = mix(fog_a.rgb, fog_b.rgb, smoothstep(0.35, 0.75, n2));
	vec3 col = mix(glass.rgb, fog, contrast * 2.0 * smoothstep(0.25, 0.85, n1) + contrast * 0.5);
	vec2 d = abs(UV - 0.5) * 2.0;
	float edge = pow(max(d.x * 0.85, d.y), 3.0);
	col *= 1.0 - vignette * edge;
	COLOR = vec4(col, glass.a);
}
