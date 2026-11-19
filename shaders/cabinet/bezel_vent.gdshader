shader_type canvas_item;
// A perforated black-painted metal speaker / vent grille on the bezel: a staggered hole pattern (SDF),
// lit by the cabinet light, with dust caught on the upper rim of each hole and a few worn edges.
#include "res://shaders/cabinet/cabinet_material.gdshaderinc"

uniform vec2 vent_size = vec2(78.0, 10.0);
uniform vec2 rig_origin = vec2(0.0);
uniform vec4 paint_color = vec4(0.055, 0.055, 0.063, 1.0);
uniform vec4 bare_steel_color = vec4(0.43, 0.42, 0.39, 1.0);
uniform float cell = 2.7;
uniform float hole_r = 0.78;
uniform float vent_dust : hint_range(0.0, 1.0) = 0.6;
uniform float wear : hint_range(0.0, 1.0) = 0.8;

void fragment() {
	vec2 p = UV * vent_size;
	vec2 rp = rig_origin + p;
	float px = max(max(fwidth(p.x), fwidth(p.y)), 1e-4);
	float dp = rbox(p, vent_size * 0.5, vent_size * 0.5, 1.2);
	float cover = cov(dp, px);
	// staggered holes inside a margin
	vec2 inner = vent_size - vec2(6.0, 3.2);
	vec2 g = (p - vec2(3.0, 1.6)) / cell;
	float row = floor(g.y + 0.5);
	vec2 gp = vec2(g.x - (mod(row, 2.0) == 0.0 ? 0.0 : 0.5), g.y);
	vec2 id = vec2(floor(gp.x + 0.5), row);
	vec2 hc = (id + vec2(mod(row, 2.0) == 0.0 ? 0.0 : 0.5, 0.0)) * cell + vec2(3.0, 1.6);
	float inside = step(0.0, min(min(hc.x, inner.x + 3.0 - hc.x), min(hc.y, inner.y + 1.6 - hc.y)));
	float dh = (length(p - hc) - hole_r) * inside + (1.0 - inside) * 10.0;
	float m_hole = cov(dh, px);
	// height: a slightly raised rolled rim round each hole
	float rim = smoothstep(0.7, 0.0, abs(dh - 0.15)) * (1.0 - m_hole) * inside;
	vec2 dir = normalize(p - hc + vec2(1e-4));
	vec3 n = normalize(vec3(-dir * rim * 0.9 * 0.8, 1.0));
	float nz = fbm(p, 1.6, px);
	float grain = smoothstep(1.5, 3.5, 1.0 / (9.0 * px));
	vec3 col = paint_color.rgb * (0.9 + 0.35 * nz) * (1.0 + (vnoise(p * 15.0) - 0.5) * 0.3 * grain);
	// dust caught on the upper rim of each hole
	float top = smoothstep(0.1, -0.7, dir.y) * rim;
	float dust_k = vent_dust * (top * 0.9 + 0.25 * rim) * (0.45 + 0.8 * vnoise(p * 2.7 + 4.0));
	col = mix(col, vec3(0.5, 0.48, 0.43), clamp(dust_k, 0.0, 0.8));
	// bare steel at the plate's edge (worn by handling and the paint chipping)
	float edge = smoothstep(0.8, 0.0, -dp) * smoothstep(0.55, 0.8, fbm(p + 20.0, 1.4, px)) * wear;
	col = mix(col, bare_steel_color.rgb * 1.3, edge * 0.8);
	// grime in the plate's corners
	col *= 1.0 - 0.5 * smoothstep(2.5, 0.0, -dp) * (0.4 + 0.8 * nz);
	vec3 lit = col * cab_lightc(n, rp);
	float spec = pow(max(dot(n, normalize(cab_key_dir(rp) + vec3(0.0, 0.0, 1.0))), 0.0), 18.0);
	lit += cab_key(rp) * spec * 0.12 * rim;
	// the hole: dark, with the faintest lift at its far wall
	vec3 hole_col = vec3(0.006, 0.006, 0.008) + cab_key(rp) * 0.015 * smoothstep(0.0, -hole_r, dh);
	lit = mix(lit, hole_col, m_hole);
	COLOR = vec4(clamp(lit, 0.0, 1.0), cover);
}
