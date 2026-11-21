shader_type canvas_item;
#include "res://shaders/crt_common.gdshaderinc"
// Act 0 cabinet costume (WARP-001 W0-01, ART-001 §7) on the arcade screen: it reads the screen's own
// SubViewport texture (TEXTURE), so it can never touch the bezel. `costume` 1 → 0 is W0-08
// "Costume Removal" (curvature drops, scanlines fade). Scanline rows come from the `rows` uniform.
// `collapse` 0 → 1 is the power-off (pass 2c): the picture squeezes to a bright horizontal line, the line
// shrinks to a dot, the dot fades. `collapse_fade` 1 swaps that for a plain quick fade to black
// (photosensitivity / reduced motion): nothing flashes and nothing moves.

uniform float collapse : hint_range(0.0, 1.0) = 0.0;
uniform float collapse_fade : hint_range(0.0, 1.0) = 0.0;
// The Decay (ART-001 §12.7b, SYS-001 §9 ds_cabinet.decay.*): all 0 at rest, so attract and play are unchanged.
// `ghost` = phosphor persistence (a trail of the picture behind itself, never a flash), `bleed` = CRT bloom
// bleed radius in grid px, `sag` = share of the picture height lost to a sagging raster.
uniform float ghost : hint_range(0.0, 1.0) = 0.0;
uniform float bleed : hint_range(0.0, 8.0) = 0.0;
uniform float sag : hint_range(0.0, 0.5) = 0.0;
// The Decay wears the play view only: rows above `play_top` (the HUD strip, UV y) stay honest and at home.
uniform float play_top : hint_range(0.0, 1.0) = 0.0;
// The cursed turn (WARP-001 W0-07, TECH-001 Q-T260): the Cabinet looks back. `focus` (screen UV) is where
// the glass bulges toward the player and where the picture collapses to its dot, off-centre; the tear opens
// from it. `bulge` 0 → 1 swells the glass there (a lens, never a new shape). Defaults keep the power-off centred.
uniform vec2 focus = vec2(0.5, 0.5);
uniform float bulge : hint_range(0.0, 1.0) = 0.0;
uniform float bulge_radius : hint_range(0.01, 1.0) = 0.22;

// The stage hand-off (TECH-001 Q-T457): a shock ring spreads from `shock_centre` (screen UV), pushing the whole play view
// radially (pixel-snapped: it only moves texels) and a register slip doubles the picture 1-2 texels to the right
// (picks one of two sampled registers: no new colour). All 0 outside the hand-off and under photosensitivity / reduced motion.
uniform vec2 shock_centre = vec2(0.5, 0.5);
uniform float shock_r : hint_range(0.0, 3.0) = 0.0;     // ring radius, in screen heights
uniform float shock_w : hint_range(0.01, 0.5) = 0.09;   // ring half-width, in screen heights
uniform float shock_amp : hint_range(-40.0, 40.0) = 0.0; // push in texels (negative = inward)
uniform float slip : hint_range(0.0, 8.0) = 0.0;        // register slip in texels

const float LINE_END = 0.55;        // share of `collapse` spent squeezing to the line; the rest shrinks and fades the dot
const float LINE_H = 0.005;         // the line's half height (screen height = 1)

// The dot phase: the line's half width shrinks toward the middle, then the dot fades.
vec3 crt_dot_phase(vec2 suv, float asp) {
	vec2 q = suv - focus;
	float k2 = clamp((collapse - LINE_END) / (1.0 - LINE_END), 0.0, 1.0);
	float w = mix(0.5, 0.0, k2 * k2);
	vec2 d = vec2(q.x / max(w, 0.004), q.y / LINE_H);
	float body = exp(-dot(d, d) * 0.5);
	vec2 sq = vec2(q.x * asp, q.y);
	float spot = exp(-dot(sq, sq) / (0.00012 + 0.0008 * (1.0 - k2)));
	float fade = 1.0 - smoothstep(0.35, 1.0, k2);
	return vec3(0.8, 0.92, 1.0) * (body * 1.5 * (1.0 - k2 * 0.6) + spot * 1.4) * fade;
}

void fragment() {
	vec2 suv0 = UV;
	float keep = 1.0;
	bool in_play = UV.y >= play_top;
	if (sag > 0.0 && in_play) {
		// the play view's raster loses height toward its own middle; outside it the tube is dark
		float c = (play_top + 1.0) * 0.5;
		float half_h = (1.0 - play_top) * 0.5;
		float q = (UV.y - c) / (half_h * max(1.0 - sag, 0.05));
		suv0 = vec2(UV.x, c + q * half_h);
		keep = step(abs(q), 1.0);
	}
	if (bulge > 0.0 && in_play) {
		// the glass swells toward the player round `focus`: the picture there is magnified and pushed out,
		// as if something behind the tube leaned on it (aspect-correct, smooth fall-off; no flash)
		vec2 ts0 = vec2(textureSize(TEXTURE, 0));
		vec2 d = suv0 - focus;
		vec2 da = vec2(d.x * ts0.x / ts0.y, d.y);
		float k = bulge * exp(-dot(da, da) / (bulge_radius * bulge_radius));
		suv0 = focus + d * (1.0 - 0.42 * k);
		suv0.y = max(suv0.y, play_top);
	}
	if (shock_amp != 0.0 && in_play) {
		vec2 ts1 = vec2(textureSize(TEXTURE, 0));
		vec2 da = (suv0 - shock_centre) * vec2(ts1.x / ts1.y, 1.0);
		float dist = length(da);
		float x = (dist - shock_r) / shock_w;
		float prof = exp(-x * x) + 0.35 * sin(x * 4.0) * exp(-x * x * 0.2);   // the ring and a few ripples behind it
		vec2 dir = da / max(dist, 0.0001);
		suv0 -= dir * shock_amp * prof / ts1;
		suv0 = (floor(suv0 * ts1) + 0.5) / ts1;               // pixel-snapped
		suv0.y = max(suv0.y, play_top);
	}
	vec2 uv = crt_sample_uv(suv0);
	if (in_play && play_top > 0.0 && uv.y < play_top) {
		keep = 0.0;   // curvature or sag would reach into the HUD strip: dark tube instead
	}
	vec3 col;
	if (in_play) {
		// the Decay's persistence and bleed, quantised so the register limits hold
		// (inline: a canvas shader cannot pass TEXTURE to a function)
		vec3 pick = crt_quantize(texture(TEXTURE, uv).rgb);
		if (slip > 0.0) {
			vec3 other = crt_quantize(texture(TEXTURE, uv - vec2(floor(slip) / float(textureSize(TEXTURE, 0).x), 0.0)).rgb);
			pick = dot(other, vec3(1.0)) > dot(pick, vec3(1.0)) ? other : pick;   // the brighter register of the pair: a doubled picture
		}
		if (ghost > 0.0 || bleed > 0.0) {
			vec2 px = 1.0 / vec2(textureSize(TEXTURE, 0));
			if (ghost > 0.0) {
				// the phosphor still glows where the picture was a few lines ago (a raster-direction trail)
				for (int i = 1; i <= 4; i++) {
					vec2 su = uv - vec2(0.0, px.y * float(i) * 1.5);
					if (su.y >= play_top) {   // never trail the HUD strip into the play view
						pick = max(pick, crt_quantize(texture(TEXTURE, su).rgb) * ghost * (1.0 - float(i) * 0.2));
					}
				}
			}
			if (bleed > 0.0) {
				vec3 bl = texture(TEXTURE, uv + vec2(px.x * bleed, 0.0)).rgb;
				bl += texture(TEXTURE, uv - vec2(px.x * bleed, 0.0)).rgb;
				bl += texture(TEXTURE, uv + vec2(0.0, px.y * bleed)).rgb;
				bl += texture(TEXTURE, vec2(uv.x, max(uv.y - px.y * bleed, play_top))).rgb;
				pick += crt_quantize(bl * 0.25) * 0.18 * bleed;
			}
		}
		col = crt_finish(pick, suv0, uv) * keep;
	} else {
		col = crt_finish(crt_quantize(texture(TEXTURE, uv).rgb), suv0, uv);   // the HUD strip: untouched
	}
	if (collapse > 0.0) {
		if (collapse_fade > 0.5) {
			col *= 1.0 - collapse;
		} else if (collapse >= LINE_END) {
			vec2 ts = vec2(textureSize(TEXTURE, 0));
			col = crt_dot_phase(UV, ts.x / ts.y);
		} else {
			float k1 = collapse / LINE_END;
			float q = UV.y - focus.y;
			float h = mix(0.5, LINE_H, k1 * k1);                // visible half height of the picture
			vec2 suv2 = vec2(UV.x, focus.y + q * 0.5 / h);
			vec2 uv2 = crt_sample_uv(suv2);
			vec3 c2 = vec3(0.0);
			if (suv2.y >= 0.0 && suv2.y <= 1.0) {
				c2 = crt_finish(crt_quantize(texture(TEXTURE, uv2).rgb), suv2, uv2);
			}
			float edge = smoothstep(h + 0.004, h - 0.002, abs(q));
			float glow = exp(-abs(q) / (h * 0.5 + 0.004)) * 0.5 * k1;
			col = (c2 * (1.0 + 2.5 * k1) + vec3(0.7, 0.85, 1.0) * glow * (0.4 + k1)) * edge;
		}
	}
	COLOR = vec4(col, 1.0);
}
