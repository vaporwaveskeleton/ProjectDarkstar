shader_type canvas_item;
render_mode unshaded;
// Presents the Aether world's HDR SubViewport in the sRGB root: an HDR 2D viewport renders in
// linear space and is only converted to sRGB when it blits to the screen itself, so a texture of
// it must be converted here.
// Pass 8 (ART-001 §16.6k): the far layer's final grade is folded into this pass (it runs anyway,
// so the grade costs no extra back-buffer copy). In linear space, before the sRGB conversion:
//   value cap (Q-T296): luma above cap_knee compressed by cap_slope, desaturated by cap_desat, a fog
//     veil (veil_col) mixed in by cap_veil; the lantern pool is spared;
//   night (Q-T310): lantern down, the dark and middle values are crushed toward VOID and cooled while
//     the lights (the distant glow, rims, photophores, the eye) keep their value: darker and colder.
// Exact black (the entity) stays exact black; everything else stays at or above floor_col.
// cap_knee 0 and night 0 = the plain conversion. Colours arrive from GDScript (Pal).

uniform bool to_srgb = true;
uniform float cap_knee = 0.0;
uniform float cap_slope = 1.0;
uniform float cap_desat = 0.0;
uniform float cap_veil = 0.0;
// veil_col and floor_col are LINEAR (this pass runs in the sRGB root, where source_color is not
// converted): GDScript passes Pal colours through srgb_to_linear().
uniform vec3 veil_col = vec3(0.0065, 0.0070, 0.0215);
uniform vec3 floor_col = vec3(0.003, 0.003, 0.006);
uniform float night = 0.0;
uniform vec3 night_floor = vec3(0.008, 0.005, 0.041);   // LINEAR: AETHER-0 × 0.35 (deep indigo)
// pass 8 c (Q-T322): split tone of the far layer in the normal state, so lavender is one of three
// hues: teal in the deep fog (tone_deep, AETHER-5's hue), a rose-pearl warmth on lit fog away from the
// lantern (tone_lit, AETHER-4's hue) and amber in the lantern's own pool (tone_pool, GAS-3's hue: the
// lantern's light). All LINEAR hue vectors; tone_k 0 = off.
uniform float tone_k = 0.0;
uniform vec3 tone_deep = vec3(0.216, 0.552, 0.631);
uniform vec3 tone_lit = vec3(0.807, 0.716, 0.686);
uniform vec3 tone_pool = vec3(0.693, 0.323, 0.027);
uniform vec2 logical_size = vec2(640.0, 360.0);
uniform vec2 lantern_px = vec2(320.0, 200.0);
uniform float lantern_r = 120.0;

// ✱ night curve: values under NIGHT_LO keep NIGHT_KEEP of their light; above NIGHT_HI they keep all
// of it; NIGHT_COLD is how far the crushed values turn toward cold blue.
const float NIGHT_KEEP = 0.1;
const float NIGHT_LO = 0.2;
const float NIGHT_HI = 0.6;
const float NIGHT_COLD = 0.55;

vec3 linear_to_srgb(vec3 c) {
	c = clamp(c, vec3(0.0), vec3(1.0));
	return mix(c * 12.92, 1.055 * pow(c, vec3(1.0 / 2.4)) - 0.055, step(vec3(0.0031308), c));
}

float luma(vec3 c) {
	return dot(c, vec3(0.2126, 0.7152, 0.0722));
}

void fragment() {
	vec3 c = texture(TEXTURE, UV).rgb;
	bool entity = max(c.r, max(c.g, c.b)) <= 0.0;
	if (!entity && (cap_knee > 0.0 || night > 0.0 || tone_k > 0.0)) {
		vec2 px = UV * logical_size;
		float spare = pow(1.0 - smoothstep(0.0, lantern_r * 2.4, length(px - lantern_px)), 1.5);
		if (cap_knee > 0.0) {
			float keep = 1.0 - spare * 0.85;
			float l0 = luma(c);
			float lc = l0 > cap_knee ? cap_knee + (l0 - cap_knee) * cap_slope : l0;
			c *= mix(1.0, lc / max(l0, 1e-4), keep);
			c = mix(c, vec3(luma(c)), cap_desat * keep);
			c = mix(c, veil_col, cap_veil * keep);
		}
		if (tone_k > 0.0) {
			float lt = luma(c);
			float day = tone_k * (1.0 - night);
			vec3 lc = vec3(lt);
			float w_deep = 0.45 * (1.0 - smoothstep(0.012, 0.07, lt)) * (1.0 - spare);
			float w_lit = 0.3 * smoothstep(0.05, 0.25, lt) * (1.0 - spare);
			float w_pool = 0.35 * spare * smoothstep(0.03, 0.2, lt);
			c = mix(c, lc * tone_deep / max(luma(tone_deep), 0.0001), w_deep * day);
			c = mix(c, lc * tone_lit / max(luma(tone_lit), 0.0001), w_lit * day);
			c = mix(c, lc * tone_pool / max(luma(tone_pool), 0.0001), w_pool * day);
		}
		if (night > 0.0) {
			float l = luma(c);
			float k = mix(NIGHT_KEEP, 1.0, smoothstep(NIGHT_LO, NIGHT_HI, l));
			float n = night * (1.0 - smoothstep(NIGHT_LO, NIGHT_HI * 0.6, l));   // lights keep their hue (PHOS stays truth)
			c *= mix(1.0, k, night);
			// pass 8 c (Q-T321): the crushed fog turns deep indigo (night_floor's hue), never neutral
			// near-black: the Aether is never a black vacuum. A floor of that hue is lifted under the
			// fog, less under what was already dark (the vast bodies stay darker than the fog).
			vec3 hue = night_floor / max(luma(night_floor), 0.0001);
			c = mix(c, vec3(luma(c)) * hue, NIGHT_COLD * n);
			c += night_floor * night * (0.5 + 0.5 * smoothstep(0.01, 0.1, l));
		}
		c = max(c, floor_col);
	}
	COLOR = vec4(to_srgb ? linear_to_srgb(c) : c, 1.0);
}
