shader_type canvas_item;
// The marquee: a thin backlit translucent sign above the screen. A black plastic rim round a milky yellow
// face lit by two fluorescent tubes: the light is uneven along the sign (cooler and dimmer at the ends where
// the tube caps shade it), one stretch is a DEAD TUBE band (only the other tube's glow reaches it), and
// dust has settled along the top edge. The lettering is printed on the lens by BezelMarquee (VectorText
// through the print material) over this face.
#include "res://shaders/cabinet/cabinet_material.gdshaderinc"

uniform vec2 sign_size = vec2(264.0, 23.0);
uniform vec2 rig_origin = vec2(0.0);
uniform float unevenness : hint_range(0.0, 1.0) = 0.55;
uniform float dead_from = 0.56;                   // the dead band, as fractions of the sign's width
uniform float dead_to = 0.71;
uniform vec3 backlight = vec3(1.0, 0.9, 0.62);
uniform float dust : hint_range(0.0, 1.0) = 0.7;

void fragment() {
	vec2 p = UV * sign_size;
	vec2 rp = rig_origin + p;
	float px = max(max(fwidth(p.x), fwidth(p.y)), 1e-4);
	vec2 hs = sign_size * 0.5;
	float d_out = rbox(p, hs, hs, 2.4);
	float cover = cov(d_out, px);
	float rim = 1.4;
	float d_face = rbox(p, hs, hs - vec2(rim), 1.2);
	float face = cov(d_face, px);

	// two tubes lengthways: soft bright bands, with the milky plastic spreading them
	float t1 = exp(-pow((p.y - sign_size.y * 0.3) / 4.4, 2.0));
	float t2 = exp(-pow((p.y - sign_size.y * 0.72) / 4.4, 2.0));
	float bright = 0.86 + 0.3 * (t1 + t2);
	// uneven along the sign: slow swells, shaded ends
	float swell = fbm(vec2(p.x * 0.5, 4.0), 0.06, px);
	float ends = smoothstep(0.0, 22.0, p.x) * smoothstep(0.0, 22.0, sign_size.x - p.x);
	bright *= 1.0 - unevenness * (0.55 * (1.0 - swell) + 0.4 * (1.0 - ends));
	// the dead tube: a stretch with a ragged edge where only the neighbouring tube's glow reaches
	float xf = p.x / sign_size.x;
	float rag = (vnoise(vec2(p.y * 0.6, 2.0)) - 0.5) * 0.012;
	float dead = smoothstep(dead_from - 0.02, dead_from + 0.004, xf + rag) * (1.0 - smoothstep(dead_to - 0.004, dead_to + 0.02, xf + rag));
	float lamp = mix(1.0, 0.2 + 0.3 * t2, dead * (0.6 + 0.4 * t1));
	bright *= lamp;
	vec3 col = backlight * bright;
	col = mix(col, vec3(dot(col, vec3(0.33))) * vec3(0.8, 0.74, 0.62), dead * 0.7);
	// milky grain and a yellowed film
	col *= 0.94 + 0.1 * vnoise(p * vec2(1.2, 2.4) + 3.0);
	col *= 1.0 - 0.18 * smoothstep(0.5, 0.9, fbm(p + 40.0, 0.08, px));
	// dust settled on the top edge of the face: pale specks catching the light and a grey film
	float ty = p.y - rim;
	float top_band = smoothstep(4.2, 0.0, ty) * step(0.0, ty);
	float specks = smoothstep(0.62, 0.9, vnoise(p * vec2(1.6, 2.6) + 7.0)) * top_band;
	float filmd = smoothstep(0.4, 0.8, fbm(p + 11.0, 0.12, px)) * top_band;
	col = mix(col, vec3(0.78, 0.74, 0.66) * (0.5 + 0.7 * bright), clamp(specks * 0.75 * dust, 0.0, 0.8));
	col = mix(col, col * 0.62 + vec3(0.04), clamp(filmd * 0.6 * dust, 0.0, 0.6));

	// the black plastic rim, lit by the cabinet light, a thin bright edge catching it on top
	vec3 rim_c = vec3(0.028, 0.028, 0.032) * (cab_amb(rp) + cab_key(rp) * 0.9) + vec3(0.5, 0.52, 0.55) * smoothstep(1.2, 0.0, abs(p.y - 0.6)) * 0.07 * (cab_amb(rp) + cab_key(rp));
	// the face is its own light, so it is barely touched by the room; a little of the screen spill on the glass
	vec3 face_c = col + cab_spill(rp) * 0.05;
	// the face's inner shadow under the rim
	face_c *= 1.0 - 0.45 * smoothstep(2.4, 0.0, -d_face);
	COLOR = vec4(mix(rim_c, face_c, face), cover);
}
