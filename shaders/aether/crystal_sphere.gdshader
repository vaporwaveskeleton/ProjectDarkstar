shader_type canvas_item;
render_mode unshaded;
// The crystal sphere (ART-001 §16) as an orrery: the vast curve of a glass sky across the frame.
// A thin bright seam (the hero), an engraved brass meridian band riding just inside it with
// graduation ticks, faint meridians fading into the fog below, and up to two nested shells at
// other depths (their own parallax, thinner, fogged). A broad soft refraction band bends the fog
// behind it (screen texture, quality-switchable), a slow glint travels along the seam, and a faint
// second seam should not be there (strength by tier). Where the entity is, the line BREAKS: a crisp
// gap with its ends displaced. T5: straight glass fractures struck into the seam.
// Colours arrive from GDScript (Pal); defaults are overwritten at runtime.

#include "res://shaders/aether/aether_common.gdshaderinc"

uniform sampler2D screen_tex : hint_screen_texture, filter_linear_mipmap;
uniform vec3 glass_col : source_color = vec3(0.38, 0.81, 0.66);
uniform vec3 seam_col : source_color = vec3(0.66, 0.94, 0.82);
uniform vec3 crack_col : source_color = vec3(0.89, 0.87, 0.82);
uniform vec3 brass_col : source_color = vec3(0.54, 0.55, 0.58);
uniform vec3 floor_col : source_color = vec3(0.039, 0.039, 0.07);
uniform vec2 centre = vec2(400.0, 1500.0);    // local px
uniform float radius = 1380.0;
uniform float band_px = 46.0;
uniform float refraction_px = 0.0;
uniform int shells = 2;
uniform float brass_strength = 0.55;
uniform float wrong_strength = 0.0;
uniform vec2 wrong_offset = vec2(-26.0, 14.0);
uniform float glint_angle = 0.0;              // radians from straight up, clockwise
uniform float glint_strength = 0.75;
uniform float crack_amount = 0.0;
uniform vec2 camera_offset = vec2(0.0);       // camera drift, px
uniform float time_s = 0.0;
uniform float drain = 0.0;
uniform float sky_tint = 0.07;

varying vec2 v_px;

void vertex() {
	v_px = VERTEX;
}

// the engraved brass band riding inside a seam at signed distance d, arc length `arc`
float brass_band(float d, float arc, float fw) {
	float l1 = 1.0 - smoothstep(0.35, 0.35 + fw * 1.5, abs(d + 7.0));
	float l2 = 1.0 - smoothstep(0.35, 0.35 + fw * 1.5, abs(d + 13.0));
	float tick_x = abs(fract(arc / 9.0) - 0.5) * 9.0;
	float major = step(0.8, fract(arc / 45.0 + 0.1));
	float tick = (1.0 - smoothstep(0.3, 0.3 + fw * 1.5, tick_x)) * step(-13.0, d) * step(d, mix(-8.0, -4.0, major));
	return max(max(l1, l2) * 0.9, tick * 0.7);
}

void fragment() {
	vec2 spx = SCREEN_UV * screen_size;
	vec4 loss = a_loss(spx);
	vec2 rel = v_px - centre;
	float r = length(rel);
	float d = r - radius;                      // < 0 inside the sphere (where we are)
	// near the entity the seam's ends are displaced before the line stops
	d += 10.0 * loss.w * loss.w;
	float keep = 1.0 - loss.y;                  // crisp gap: the line just... stops
	vec2 nrm = rel / max(r, 1.0);
	float fw = max(fwidth(v_px.x), 0.2);
	float band = exp(-abs(d) / band_px);
	float core = exp(-abs(d) / 1.1);
	float halo = exp(-abs(d) / 5.0);
	float ang = atan(rel.x, -rel.y);
	float arc = ang * radius;
	vec2 off = vec2(0.0);
	float crack = 0.0;
	if (crack_amount > 0.0) {
		// the sphere itself breaking: straight glass fractures struck into the seam
		for (int i = 0; i < 3; i++) {
			float th = -0.42 + 0.4 * float(i) + 0.05 * sin(float(i) * 7.0);
			vec2 hit = centre + radius * vec2(sin(th), -cos(th));
			vec2 tang = vec2(cos(th), sin(th));
			vec2 g = a_glass(v_px, hit, 190.0 * crack_amount * (1.0 - 0.25 * float(i == 1)), 2.3 + float(i) * 3.1, tang, 0.5);
			crack = max(crack, (1.0 - smoothstep(0.5 * fw, 1.6 * fw, g.x)) * 0.45);
			off += normalize(v_px - hit + vec2(0.01)) * g.y * 6.0;
		}
	}
	vec3 col = vec3(0.0);
	float a = 0.0;
	vec3 glass_add = seam_col * core * 0.55 + glass_col * halo * 0.12;
	if (refraction_px > 0.0) {
		// refraction: a lens across the seam, plus a drift that runs against the camera
		off += nrm * refraction_px * band * clamp(d / band_px, -1.0, 1.0);
		off += -camera_offset * 0.35 * band;
		vec3 behind = textureLod(screen_tex, SCREEN_UV + off / screen_size, 0.0).rgb;
		col = mix(behind, behind * 0.85 + glass_col * 0.15, band * 0.6 * keep);
		col = mix(col, col * 0.9 + glass_col * 0.1, sky_tint * step(0.0, d) * 6.0 * keep);
		a = clamp(band * 1.4 + sky_tint * 4.0 * step(0.0, d), 0.0, 1.0);
	} else {
		col = glass_col * 0.5;
		a = (band * 0.18 + sky_tint * step(0.0, d)) * keep;
	}
	// brass meridian band and graduation (engraved, fogged: below the seam's brightness)
	float br = brass_band(d, arc, fw) * brass_strength;
	// faint meridians fading down into the fog, and one dashed parallel
	float mer_x = abs(fract(ang / 0.09) - 0.5) * 0.09 * radius;
	float mer = (1.0 - smoothstep(0.3, 0.3 + fw * 1.5, mer_x)) * smoothstep(-130.0, -16.0, d) * step(d, -14.0) * 0.35;
	float par = (1.0 - smoothstep(0.3, 0.3 + fw * 1.5, abs(d + 44.0))) * step(0.45, fract(arc / 14.0)) * 0.4;
	br = max(br, max(mer, par) * brass_strength);
	// nested shells: other depths, other parallax, thinner and fogged
	for (int k = 1; k <= 2; k++) {
		if (k > shells) {
			break;
		}
		float fk = float(k);
		vec2 c2 = centre + camera_offset * (0.1 * fk) + vec2(50.0 * fk, -14.0 * fk);
		float d2 = length(v_px - c2) - radius * (1.0 + 0.05 * fk);
		float s2 = exp(-abs(d2) / 0.8) * (0.28 / fk) + exp(-abs(d2) / 6.0) * 0.04;
		glass_add += glass_col * s2;
		br = max(br, (1.0 - smoothstep(0.3, 0.3 + fw * 1.5, abs(d2 + 6.0))) * brass_strength * 0.45 / fk);
		a = max(a, s2 * 0.8);
	}
	col = mix(col, brass_col, br * keep);
	a = max(a, br * keep);
	col += glass_add * keep;
	a = max(a, clamp(core + halo * 0.6, 0.0, 1.0) * keep);
	// the glint, travelling along the seam
	float glint = exp(-pow((ang - glint_angle) * radius / 70.0, 2.0)) * exp(-abs(d) / 3.0) * glint_strength * keep;
	col += seam_col * glint;
	a = max(a, glint);
	// the second seam, offset and breathing; it should not exist
	if (wrong_strength > 0.0) {
		float r2 = length(v_px - centre - wrong_offset * (1.0 + 0.2 * sin(time_s * 0.09)));
		float dw = r2 - radius * 1.004;
		float w = exp(-abs(dw) / 1.3) * wrong_strength * 0.35 * keep;
		col += glass_col * w;
		a = max(a, w);
	}
	col = mix(col, crack_col, crack);
	a = max(a, crack);
	col = mix(col, vec3(a_luma(col)), drain * 0.6);
	col = max(col, floor_col);
	COLOR = vec4(col, clamp(a, 0.0, 1.0));
}
