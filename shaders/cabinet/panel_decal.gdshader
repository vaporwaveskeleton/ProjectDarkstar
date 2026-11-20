shader_type canvas_item;
// Decal lettering on the control panel (pass 2c): the printed ink wears off where thumbs and palms rub. Draws the
// label's own vertex colour; only its alpha is changed. `rub` 0..1 is how much ink is gone; `bias` leans the loss
// toward the left of the label (hands arrive from the left); `focus_k` lights the label, which stays whole.
// Worn but legible (Fable review 2026-11-20): the rub is fine grain that thins the ink, never whole chunks of a
// letter, and a rubbed spot keeps a faded trace of its ink (`keep`).
#include "res://shaders/cabinet/cabinet_material.gdshaderinc"

uniform vec2 rig_origin = vec2(0.0);
uniform float label_x = 0.0;                   // rig x of the label's left edge
uniform float label_w = 20.0;
uniform float rub : hint_range(0.0, 1.0) = 0.0;
uniform float bias : hint_range(0.0, 1.0) = 0.0;
uniform float focus_k : hint_range(0.0, 1.0) = 0.0;
uniform float keep : hint_range(0.0, 1.0) = 0.4;          // the faded ink a rubbed spot keeps

varying vec2 lp;

void vertex() {
	lp = VERTEX + rig_origin;
}

void fragment() {
	float px = max(max(fwidth(lp.x), fwidth(lp.y)), 1e-4);
	float x = clamp((lp.x - label_x) / max(label_w, 1.0), 0.0, 1.0);
	float lean = mix(0.5, 1.0 - x, bias);
	float amt = rub * (0.45 + 0.65 * lean) * (1.0 - 0.7 * focus_k);
	float n = 0.55 * fbm(lp * 3.0 + 21.0, 0.75, px) + 0.45 * vnoise(lp * vec2(5.1, 6.9) + 4.0);
	float worn = smoothstep(amt * 0.95 - 0.06, amt * 0.95 + 0.06, n);
	float scuff = 0.8 + 0.2 * vnoise(lp * 5.0);
	COLOR.a *= mix(1.0, mix(keep, 1.0, worn) * scuff, step(0.001, rub));
}
