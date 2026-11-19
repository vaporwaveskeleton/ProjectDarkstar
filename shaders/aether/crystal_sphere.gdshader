shader_type canvas_item;
render_mode unshaded;
// The crystal sphere (ART-001 §16): the vast curve of a glass sky across the frame. A thin bright
// seam, a broad soft refraction band that bends the fog behind it (screen texture), a slow glint
// travelling along the seam, and a faint second seam that should not be there (strength by tier).
// The refraction drifts against the camera — the wrong way. T5: a shatter mask cracks the glass.
// Colours arrive from GDScript (Pal); defaults are overwritten at runtime.

#include "res://shaders/aether/aether_common.gdshaderinc"

uniform sampler2D screen_tex : hint_screen_texture, filter_linear_mipmap;
uniform vec3 glass_col : source_color = vec3(0.38, 0.81, 0.66);
uniform vec3 seam_col : source_color = vec3(0.66, 0.94, 0.82);
uniform vec3 crack_col : source_color = vec3(0.89, 0.87, 0.82);
uniform vec3 floor_col : source_color = vec3(0.039, 0.039, 0.07);
uniform vec2 centre = vec2(400.0, 1500.0);    // local px
uniform float radius = 1380.0;
uniform float band_px = 46.0;
uniform float refraction_px = 0.0;
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

void fragment() {
	vec2 rel = v_px - centre;
	float r = length(rel);
	float d = r - radius;                      // < 0 inside the sphere (where we are)
	vec2 nrm = rel / max(r, 1.0);
	float band = exp(-abs(d) / band_px);
	float core = exp(-abs(d) / 1.1);
	float halo = exp(-abs(d) / 5.0);
	// refraction: a lens across the seam, plus a drift that runs against the camera
	vec2 off = nrm * refraction_px * band * clamp(d / band_px, -1.0, 1.0);
	off += -camera_offset * 0.35 * band * step(0.01, refraction_px);
	float crack = 0.0;
	if (crack_amount > 0.0) {
		// the sphere itself breaking: fractures struck into the seam
		for (int i = 0; i < 3; i++) {
			float th = -0.42 + 0.4 * float(i) + 0.05 * sin(float(i) * 7.0);
			vec2 hit = centre + radius * vec2(sin(th), -cos(th));
			vec2 f = a_fracture(v_px, hit, 190.0 * crack_amount * (1.0 - 0.25 * float(i == 1)), 2.3 + float(i) * 3.1);
			crack = max(crack, f.x);
			off += normalize(v_px - hit + vec2(0.01)) * f.y * 6.0;
		}
	}
	vec2 suv = SCREEN_UV + off / screen_size;
	vec3 behind = textureLod(screen_tex, suv, 0.0).rgb;
	vec3 col = behind;
	col = mix(col, col * 0.85 + glass_col * 0.15, band * 0.6);
	// the sky beyond the sphere: the same Aether, colder, as if seen through a pane
	col = mix(col, col * 0.9 + glass_col * 0.1, sky_tint * step(0.0, d) * 6.0);
	col += seam_col * core * 0.55 + glass_col * halo * 0.12;
	// the glint, travelling along the seam
	float ang = atan(rel.x, -rel.y);
	float arc = (ang - glint_angle) * radius;
	float glint = exp(-pow(arc / 70.0, 2.0)) * exp(-abs(d) / 3.0) * glint_strength;
	col += seam_col * glint;
	// the second seam, offset and breathing; it should not exist
	if (wrong_strength > 0.0) {
		float r2 = length(v_px - centre - wrong_offset * (1.0 + 0.2 * sin(time_s * 0.09)));
		float d2 = r2 - radius * 1.004;
		col += glass_col * exp(-abs(d2) / 1.3) * wrong_strength * 0.35;
	}
	col = mix(col, crack_col, crack * 0.8);
	col = mix(col, vec3(a_luma(col)), drain * 0.85);
	float drunk = a_drunk(SCREEN_UV * screen_size);
	col = mix(col, floor_col, drunk);
	col = max(col, floor_col);
	float a = clamp(band * 1.4 + core + halo + glint + crack + sky_tint * 4.0 * step(0.0, d), 0.0, 1.0);
	COLOR = vec4(col, a);
}
