shader_type canvas_item;
render_mode unshaded;
// Draws one Aether-life particle procedurally from its quad UV (no image files, D-13):
// 0 glass mote, 1 jelly-lantern (bioluminescent: translucent bell with an inner glow core that
// fades to a clear rim, a brighter rim line, a soft halo, swaying filaments that fade out),
// 2 spore, 3 school glint (a tiny bright point with a soft tail). Depth comes from the particle's
// size (INSTANCE_CUSTOM.z relative to `size_mid`): small ones are dim and fogged, large ones near.
// The colour comes from the particle (COLOR, a Pal entry set by GDScript); `glow` > 1 lets an
// emitter reach the bloom threshold, always below the lantern.

uniform int shape = 0;
uniform float glow = 1.0;
uniform float time_s = 0.0;
uniform float size_mid = 1.0;            // particle scale that counts as "mid depth"
uniform vec3 fog_col : source_color = vec3(0.16, 0.19, 0.34);

varying float v_phase;
varying float v_depth;

void vertex() {
	v_phase = INSTANCE_CUSTOM.x;
	v_depth = clamp(INSTANCE_CUSTOM.z / max(size_mid, 0.0001), 0.2, 2.5);
}

void fragment() {
	vec2 uv = UV;
	float a = 0.0;
	float bright = 1.0;
	float near = smoothstep(0.4, 1.6, v_depth);      // 0 far … 1 near
	if (shape == 0) {
		float r = length(uv - 0.5) * 2.0;
		a = exp(-r * r * 7.0) + 0.6 * exp(-r * r * 40.0);
	} else if (shape == 1) {
		float pulse = 0.6 + 0.4 * sin(time_s * 1.4 + v_phase);    // 0.22 Hz
		vec2 b = (uv - vec2(0.5, 0.3)) / vec2(0.24, 0.17);
		float rb = length(b);
		float dome = step(uv.y, 0.32 + 0.02 * sin(uv.x * 18.0 + time_s));
		float bell = (1.0 - smoothstep(0.88, 1.0, rb)) * dome;
		float rim = exp(-pow((rb - 0.93) / 0.07, 2.0)) * dome;
		float core = exp(-dot(b * vec2(1.0, 1.3), b * vec2(1.0, 1.3)) * 3.0) * dome;
		float halo = exp(-rb * rb * 0.9) * 0.22;
		float fil = 0.0;
		for (int i = 0; i < 6; i++) {
			float fx = 0.5 + (float(i) - 2.5) * 0.045;
			float y = uv.y - 0.31;
			float wav = sin(y * 22.0 - time_s * 1.1 + v_phase + float(i) * 1.3) * 0.03 * y * 2.5;
			float line = exp(-pow((uv.x - fx - wav) / 0.006, 2.0));
			fil += line * step(0.0, y) * (1.0 - smoothstep(0.05, 0.66, y)) * (0.6 + 0.4 * sin(float(i) * 2.1));
		}
		a = bell * 0.12 + rim * 0.55 + core * 0.75 * pulse + halo + clamp(fil, 0.0, 1.0) * 0.4;
		bright = 0.75 + 0.55 * pulse + core * 0.6;
	} else if (shape == 2) {
		float r = length(uv - 0.5) * 2.0;
		float fuzz = exp(-r * r * 5.0);
		float ring = exp(-pow((r - 0.55) / 0.12, 2.0)) * 0.5;
		a = fuzz * 0.6 + ring;
	} else {
		// a glint: a hot point at the head and a soft tail behind it (the quad faces the motion)
		vec2 q = uv - vec2(0.72, 0.5);
		float head = exp(-dot(q, q) * 900.0);
		float tail = exp(-pow(q.y / 0.035, 2.0)) * smoothstep(-0.6, 0.0, q.x) * step(q.x, 0.02) * (1.0 + q.x / 0.6);
		a = head + tail * 0.35;
		bright = 1.0 + head * 0.5;
	}
	vec3 c = COLOR.rgb * bright * glow;
	// depth: far life is dim and swallowed by the fog
	c = mix(fog_col, c, 0.45 + 0.55 * near);
	COLOR = vec4(c, COLOR.a * clamp(a, 0.0, 1.0) * (0.35 + 0.65 * near));
}
