shader_type canvas_item;
render_mode unshaded;
// The entity's presence (ART-001 §16): the only true black. A NULL mass with an irregular, slowly
// breathing edge. No outline, no rim, no glow of its own: inside is exactly vec4(0,0,0,1),
// outside is discarded. The world going out around it is done by the layers that read the
// entity mask (entity_0..3), not here.

uniform float radius = 40.0;          // px
uniform vec2 half_size = vec2(200.0);  // half of the quad, px
uniform float time_s = 0.0;
uniform float seed = 0.0;
uniform float wobble = 0.16;          // edge irregularity as a fraction of radius

float e_hash(vec2 p) {
	vec3 p3 = fract(vec3(p.xyx) * 0.1031);
	p3 += dot(p3, p3.yzx + 33.33);
	return fract((p3.x + p3.y) * p3.z);
}

float e_noise(vec2 p) {
	vec2 i = floor(p);
	vec2 f = fract(p);
	vec2 u = f * f * (3.0 - 2.0 * f);
	return mix(mix(e_hash(i), e_hash(i + vec2(1.0, 0.0)), u.x),
		mix(e_hash(i + vec2(0.0, 1.0)), e_hash(i + vec2(1.0, 1.0)), u.x), u.y);
}

void fragment() {
	vec2 rel = (UV - 0.5) * half_size * 2.0;
	float ang = atan(rel.y, rel.x);
	vec2 ring = vec2(cos(ang), sin(ang)) * 1.6 + seed;
	float breath = 0.5 + 0.5 * sin(time_s * 0.4 + seed);   // 0.064 Hz
	float n = e_noise(ring + vec2(time_s * 0.05)) * 0.5 + e_noise(ring * 2.7 - vec2(time_s * 0.08)) * 0.3
		+ e_noise(ring * 7.0 + vec2(time_s * 0.03)) * 0.2;
	float r = radius * (1.0 + wobble * (n - 0.5) * 2.0 + 0.04 * breath);
	if (length(rel) > r || radius < 0.5) {
		discard;
	}
	COLOR = vec4(0.0, 0.0, 0.0, 1.0);
}
