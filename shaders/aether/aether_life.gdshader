shader_type particles;
// Aether-life motion (ART-001 §16). Mode 0: a drifting field (glass motes, jelly-lanterns, spores)
// carried by a shared slow current, so the whole field turns as one. Mode 1: a school holding
// formation around a centre that GDScript steers; `scatter` blows it apart from an empty patch.
// Near the entity every particle drifts toward it, dims and is gone past a crisp boundary;
// as the world is drunk, life fades and stops. Positions are emitter-local.
// Particles never die (huge lifetime) and fade in over `fade_in_s`: zero startle.

uniform int mode = 0;
uniform vec2 extents = vec2(420.0, 260.0);
uniform vec2 drift = vec2(4.0, -1.5);          // px/s
uniform float current_strength = 10.0;         // px/s from the shared current
uniform float current_heading = 0.0;           // radians, shared by every particle (turns as one)
uniform float swirl = 6.0;                     // px/s of local turbulence
uniform float speed_scale = 1.0;               // negative: reversed (T5)
uniform vec2 size_range = vec2(1.0, 2.0);      // px
uniform vec4 tint : source_color = vec4(1.0);
uniform float alpha_max = 0.8;
uniform float fade_in_s = 3.0;
uniform float life_fade = 1.0;                 // 1 alive … 0 gone (drain)
uniform vec2 flee_pos = vec2(9999.0);           // emitter-local px
uniform float flee_radius = 0.0;
uniform float flee_strength = 16.0;           // px/s drift toward the entity
uniform vec2 school_centre = vec2(0.0);
uniform float school_heading = 0.0;
uniform vec2 school_spread = vec2(70.0, 24.0);
uniform float scatter = 0.0;
uniform float align = 1.0;                     // 1: face the motion; 0: hang and sway (jellies)
uniform vec2 scatter_pos = vec2(0.0);
// Long flights (Q-T127 option B): the camera's parallax velocity for this layer (px/s, emitter-local).
// The field streams past and wraps inside its own box (off-frame), so no world offset ever reaches it.
uniform vec2 scroll_velocity = vec2(0.0);

float l_rand(inout uint s) {
	s = s * 747796405u + 2891336453u;
	uint w = ((s >> ((s >> 28u) + 4u)) ^ s) * 277803737u;
	w = (w >> 22u) ^ w;
	return float(w) / 4294967295.0;
}

float l_noise(vec2 p) {
	vec2 i = floor(p);
	vec2 f = fract(p);
	vec2 u = f * f * (3.0 - 2.0 * f);
	vec4 h = fract(sin(vec4(dot(i, vec2(127.1, 311.7)), dot(i + vec2(1.0, 0.0), vec2(127.1, 311.7)),
		dot(i + vec2(0.0, 1.0), vec2(127.1, 311.7)), dot(i + vec2(1.0, 1.0), vec2(127.1, 311.7)))) * 43758.5453);
	return mix(mix(h.x, h.y, u.x), mix(h.z, h.w, u.x), u.y);
}

vec2 rot(vec2 v, float a) {
	return vec2(v.x * cos(a) - v.y * sin(a), v.x * sin(a) + v.y * cos(a));
}

void start() {
	uint s = uint(INDEX) * 1973u + RANDOM_SEED;
	float rx = l_rand(s);
	float ry = l_rand(s);
	CUSTOM = vec4(l_rand(s) * 6.2831, 0.0, mix(size_range.x, size_range.y, l_rand(s)), l_rand(s));
	vec2 p = (vec2(rx, ry) * 2.0 - 1.0) * extents;
	if (mode == 1) {
		p = school_centre + rot((vec2(rx, ry) * 2.0 - 1.0) * school_spread, school_heading);
	}
	TRANSFORM = mat4(vec4(CUSTOM.z, 0.0, 0.0, 0.0), vec4(0.0, CUSTOM.z, 0.0, 0.0), vec4(0.0, 0.0, 1.0, 0.0), vec4(p, 0.0, 1.0));
	VELOCITY = vec3(0.0);
	COLOR = vec4(tint.rgb, 0.0);
}

void process() {
	CUSTOM.y += DELTA;
	vec2 p = TRANSFORM[3].xy;
	float ang = school_heading;
	if (mode == 0) {
		vec2 cur = vec2(cos(current_heading), sin(current_heading)) * current_strength;
		float n = l_noise(p / 140.0 + vec2(CUSTOM.y * 0.02, CUSTOM.x));
		vec2 turb = vec2(cos(n * 6.2831), sin(n * 6.2831)) * swirl;
		vec2 v = (drift + cur + turb) * speed_scale * life_fade;   // drained life stops
		p += v * DELTA - scroll_velocity * DELTA;
		p = mod(p + extents, extents * 2.0) - extents;
		ang = atan(v.y, v.x);
	} else {
		uint s = uint(INDEX) * 1973u + RANDOM_SEED;
		float rx = l_rand(s);
		float ry = l_rand(s);
		vec2 slot = rot((vec2(rx, ry) * 2.0 - 1.0) * school_spread, school_heading);
		slot += vec2(sin(CUSTOM.y * 0.7 + CUSTOM.x), cos(CUSTOM.y * 0.5 + CUSTOM.x)) * 3.0;
		vec2 target = school_centre + slot;
		float hold = 1.0 - clamp(scatter, 0.0, 1.0);
		p = mix(p, target, 1.0 - exp(-DELTA * 2.5 * hold));
		vec2 away = p - scatter_pos;
		p += normalize(away + vec2(0.001)) * scatter * 160.0 * DELTA * smoothstep(260.0, 0.0, length(away));
	}
	// drawn slowly toward the entity (the world flows into it), dimming, then simply gone
	if (flee_radius > 0.5) {
		vec2 d = flee_pos - p;
		float dist = length(d);
		float pull = smoothstep(flee_radius * 3.5, flee_radius * 1.3, dist);
		p += normalize(d + vec2(0.001)) * pull * flee_strength * DELTA;
	}
	float fade = smoothstep(0.0, fade_in_s, CUSTOM.y) * life_fade;
	if (flee_radius > 0.5) {
		float de = length(p - flee_pos);
		fade *= step(flee_radius * 1.45, de) * mix(0.35, 1.0, smoothstep(flee_radius * 1.45, flee_radius * 2.6, de));
	}
	float tw = 0.75 + 0.25 * sin(TIME * 2.0 + CUSTOM.x);   // 0.32 Hz shimmer
	COLOR = vec4(tint.rgb, tint.a * alpha_max * fade * tw);
	if (align < 0.5) {
		ang = 0.18 * sin(CUSTOM.y * 0.4 + CUSTOM.x);
	}
	float sz = CUSTOM.z;
	TRANSFORM[0] = vec4(cos(ang) * sz, sin(ang) * sz, 0.0, 0.0);
	TRANSFORM[1] = vec4(-sin(ang) * sz, cos(ang) * sz, 0.0, 0.0);
	TRANSFORM[3] = vec4(p, 0.0, 1.0);
	VELOCITY = vec3(0.0);
}
