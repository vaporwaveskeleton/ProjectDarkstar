shader_type canvas_item;
render_mode unshaded;
// The Pale Marches Presence (ZONES-001 §2.3, T1): "a frost-drifting thing like a migrating ice
// shelf, with a slow heartbeat of light". Far layer only; never a hitbox; never black.
// Anatomy: a vast pale shelf whose calving FRONT (straight ice facets on a slow living swell) runs
// diagonally across the top of the frame; the body lies beyond it, off-frame, in low-contrast strata
// parallel to the front, cut by long crevasses running back from the front. Its light is a
// HEARTBEAT: a lub-dub of glass light (PHOS) that travels outward from a heart deep in the body
// along the crevasses (one beat per beat_period, two soft bumps: well under 1 Hz, no flash).
// Lantern up: a vague mass in the fog, only the veins near the heart faintly lit. Lantern down
// (`reveal` 1): its full lit pattern. Everything stays under the lantern's pool (rim and lights are
// dim colours, guarded near the lantern) and the entity subtracts it like every far layer.
// Colours arrive from GDScript (Pal); defaults are overwritten at runtime.

#include "res://shaders/aether/aether_common.gdshaderinc"

uniform vec3 body_col : source_color = vec3(0.11, 0.13, 0.25);    // far_silhouette (VOID)
uniform vec3 pearl_col : source_color = vec3(0.91, 0.86, 0.85);   // AETHER-4 pearl
uniform vec3 frost_col : source_color = vec3(0.73, 0.72, 0.68);   // BONE-3 frost rim
uniform vec3 light_col : source_color = vec3(0.38, 0.81, 0.66);   // PHOS-4 glass light
uniform vec3 floor_col : source_color = vec3(0.039, 0.039, 0.07);
uniform vec2 quad_size = vec2(1700.0, 1000.0);
uniform float front_y = 640.0;          // local y of the calving front's mean line
uniform vec2 heart = vec2(470.0, 360.0); // local px: where the heartbeat starts
uniform float time_s = 0.0;
uniform float beat_period = 4.0;        // s per beat (lub-dub)
uniform float wave_speed = 150.0;       // px/s the beat travels along the veins
uniform float presence : hint_range(0.0, 1.0) = 1.0;
uniform float reveal : hint_range(0.0, 1.0) = 0.0;
uniform float drain = 0.0;
uniform float steady = 0.0;             // 1 = no pulse (reduced motion / photosensitivity)
uniform float max_alpha = 0.66;
uniform int edge_octaves = 3;
uniform vec2 lantern_px = vec2(320.0, 202.0);
uniform float lantern_r = 120.0;

varying vec2 v_px;

void vertex() {
	v_px = VERTEX;
}

// The calving front's y at local x: straight facets (ice), on a slow swell (alive). A line, never a
// closed shape (pareidolia rule, ART-001 §16.6c).
float front(float x, float t) {
	float c = floor(x / 96.0);
	float f = fract(x / 96.0);
	float facet = mix(a_hash(vec2(c, 4.2)), a_hash(vec2(c + 1.0, 4.2)), f) * 34.0;
	float swell = 30.0 * sin(x / 310.0 + t * 0.05) + 12.0 * sin(x / 137.0 - t * 0.031);
	return front_y + swell - facet;
}

// One heartbeat over phase 0..1: two soft bumps (lub, dub), then rest.
float beat(float ph) {
	return exp(-pow((ph - 0.08) / 0.05, 2.0)) + 0.55 * exp(-pow((ph - 0.27) / 0.06, 2.0));
}

void fragment() {
	vec2 p = v_px;
	vec2 spx = SCREEN_UV * screen_size;
	float t = time_s;
	float n = a_fbm(p / 130.0 + vec2(t * 0.004, 0.0), edge_octaves);
	float s = front(p.x, t) - p.y + (n - 0.5) * 9.0;     // depth into the shelf (px); < 0 outside
	float body = smoothstep(-2.5, 3.5, s);
	// the quad's own edges dissolve into the fog (the frame crops it; drift never shows an edge)
	float fade_q = smoothstep(0.0, 260.0, p.x) * smoothstep(0.0, 260.0, quad_size.x - p.x) * smoothstep(0.0, 200.0, p.y);
	// deep in the body it sinks back into the far fog (it is vast and far, not a wall): the front is
	// the lightest part, so the frame keeps its deep background band
	float sink = 1.0 - 0.6 * smoothstep(30.0, 230.0, s);
	float near_front = 1.0 - smoothstep(20.0, 200.0, s);
	vec3 col = mix(body_col, pearl_col, 0.1 + 0.22 * near_front + 0.1 * n);
	// pressure ridges parallel to the front: thin crisp lines of old ice, clearest near the front
	float sl = abs(fract((s + (n - 0.5) * 14.0) / 23.0) - 0.5) * 23.0;
	float sline = (1.0 - smoothstep(0.4, 1.4, sl)) * smoothstep(3.0, 12.0, s) * near_front;
	col = mix(col, frost_col, sline * 0.4);
	// crevasses: long fractures running back from the front, straight segments with sharp turns
	// (linear-interpolated value noise: faceted, not draped), each its own strength; open lines only
	vec2 wq = vec2(p.x / 140.0, p.y / 64.0) + 3.1;
	vec2 wi = floor(wq);
	vec2 wf = fract(wq);
	float lin = mix(mix(a_hash(wi), a_hash(wi + vec2(1.0, 0.0)), wf.x),
		mix(a_hash(wi + vec2(0.0, 1.0)), a_hash(wi + vec2(1.0, 1.0)), wf.x), wf.y);
	float wander = (lin - 0.5) * 34.0 + s * 0.12;
	float phase = (p.x + wander) / 31.0;
	float line_id = floor(phase);
	float line_k = step(0.42, a_hash(vec2(line_id, 7.7))) * (0.5 + 0.5 * a_hash(vec2(line_id, 1.3)));
	float ridge = 1.0 - abs(fract(phase) - 0.5) * 2.0;    // 1 on the line's centre
	float crev = pow(ridge, 12.0) * line_k * smoothstep(4.0, 40.0, s);
	col = mix(col, body_col, crev * 0.7);
	// the frost rim along the front (fog backscatter on the ice edge) and frost spray drifting off it
	float rim = exp(-abs(s - 1.5) / 2.2) * step(-3.0, s);
	float spray = exp(s / 22.0) * step(s, 0.0) * (0.55 + 0.45 * a_noise(vec2(p.x / 30.0 - t * 0.05, s / 14.0)));
	col = mix(col, frost_col, clamp(rim, 0.0, 1.0) * 0.8);
	col = mix(col, frost_col, spray * (1.0 - body) * 0.6);
	float a = body * max_alpha * sink;
	a = max(a, clamp(rim, 0.0, 1.0) * 0.62);
	a = max(a, spray * 0.16);
	// the heartbeat: a wave of glass light leaving the heart, through the ice and along the crevasses
	float d = length(p - heart);
	float ph = fract((t - d / wave_speed) / beat_period);
	float b = mix(0.3 + 0.7 * beat(ph), 0.42, steady);
	float reach = mix(210.0, 1500.0, reveal);                 // lantern down: the full pattern
	float lit = 1.0 - smoothstep(reach * 0.5, reach, d);
	// the light runs in the crevasse cores; lantern down, more of them carry it (the full pattern)
	float vein = pow(ridge, mix(26.0, 14.0, reveal)) * line_k * smoothstep(10.0, 60.0, s);
	vein *= mix(step(0.75, line_k), 1.0, reveal);
	float glow = exp(-pow(d / mix(170.0, 420.0, reveal), 2.0)) * smoothstep(20.0, 160.0, s);
	float light = (vein * mix(0.7, 1.0, reveal) + glow * mix(0.34, 0.45, reveal)) * b * lit * body;
	col = mix(col, light_col, clamp(light, 0.0, 1.0));
	a = max(a, clamp(light, 0.0, 1.0) * 0.9);
	// no light in the play layer: veiled to a vague mass near the lantern's pool
	float dl = length(spx - lantern_px);
	a *= mix(0.12, 1.0, smoothstep(lantern_r * 1.1, lantern_r * 2.4, dl));
	vec4 loss = a_loss(spx);
	a *= fade_q * presence * (1.0 - loss.y);
	col = mix(col, vec3(a_luma(col)), drain * 0.5);
	col = max(col, floor_col);
	COLOR = vec4(col, clamp(a, 0.0, 1.0));
}
