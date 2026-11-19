shader_type canvas_item;
render_mode unshaded;
// Draws one Aether-life particle procedurally from its quad UV (no image files, D-13):
// 0 glass mote, 1 jelly-lantern (bell + trailing filaments, slow pulse), 2 spore, 3 school sliver.
// The colour comes from the particle (COLOR, a Pal entry set by GDScript); `glow` > 1 lets an
// emitter reach the bloom threshold, always below the lantern.

uniform int shape = 0;
uniform float glow = 1.0;
uniform float time_s = 0.0;

varying float v_phase;

void vertex() {
	v_phase = INSTANCE_CUSTOM.x;
}

void fragment() {
	vec2 uv = UV;
	float a = 0.0;
	float bright = 1.0;
	if (shape == 0) {
		float r = length(uv - 0.5) * 2.0;
		a = exp(-r * r * 7.0) + 0.6 * exp(-r * r * 40.0);
	} else if (shape == 1) {
		float pulse = 0.6 + 0.4 * sin(time_s * 1.4 + v_phase);    // 0.22 Hz
		vec2 b = (uv - vec2(0.5, 0.33)) / vec2(0.3, 0.2);
		float bell = (1.0 - smoothstep(0.85, 1.0, length(b))) * step(uv.y, 0.36);
		float rim = smoothstep(0.7, 0.95, length(b)) * bell;
		float inner = exp(-dot(b, b) * 2.5) * step(uv.y, 0.36);
		float fil = 0.0;
		for (int i = 0; i < 5; i++) {
			float fx = 0.5 + (float(i) - 2.0) * 0.06;
			float y = uv.y - 0.36;
			float wav = sin(uv.y * 12.0 - time_s * 1.1 + v_phase + float(i)) * 0.025 * y * 3.0;
			float line = exp(-pow((uv.x - fx - wav) / 0.008, 2.0));
			fil += line * step(0.0, y) * (1.0 - smoothstep(0.2, 0.62, y));
		}
		a = bell * 0.35 + rim * 0.5 + inner * 0.6 * pulse + clamp(fil, 0.0, 1.0) * 0.45;
		bright = 0.7 + 0.5 * pulse;
	} else if (shape == 2) {
		float r = length(uv - 0.5) * 2.0;
		float fuzz = exp(-r * r * 5.0);
		float ring = exp(-pow((r - 0.55) / 0.12, 2.0)) * 0.5;
		a = fuzz * 0.6 + ring;
	} else {
		vec2 q = (uv - 0.5) * vec2(2.0, 6.0);
		a = exp(-dot(q, q) * 1.5);
		bright = 1.1;
	}
	COLOR = vec4(COLOR.rgb * bright * glow, COLOR.a * clamp(a, 0.0, 1.0));
}
