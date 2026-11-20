shader_type canvas_item;
// The Aether Vigil's hammered-brass plating (ART-001 §14.8a, §15.1a T1; owner direction 2026-11-19: dents,
// tarnish and a moving specular from its lantern must read at 1280×720). Drawn on AetherVigilRig's Plating layer
// with a CanvasTexture (loom ds_vigil_brass: albedo in TEXTURE, OpenGL normal map in NORMAL_TEXTURE). UV is
// hull-local px / tile, so the whole light model lives in the hull's own frame: the lamp is a point light at
// lamp_hull, the Aether's sky key is a direction the rig rotates by -heading every frame (so the highlights
// slide across the dents as the skiff turns). COLOR already holds band colour x albedo.

uniform float tile = 40.0;                      // hull px per texture repeat (AetherVigilLook.brass_tile)
uniform vec2 lamp_hull = vec2(0.0);             // the lamp, hull-local px
uniform vec3 lamp_color : source_color = vec3(1.0, 0.8, 0.4);
uniform float lamp_energy = 1.0;                // 0 when the lantern is out
uniform float lamp_radius = 40.0;
uniform float lamp_height = 10.0;
uniform vec2 sky_hull = vec2(-0.6, -0.8);       // the sky key's direction (toward the light), hull frame
uniform vec3 sky_color : source_color = vec3(0.9, 0.88, 1.0);
uniform float sky_gain = 0.35;
uniform float ambient = 0.75;
uniform float normal_strength = 1.6;
uniform float diffuse_gain = 0.7;
uniform float spec_gain = 1.1;
uniform float spec_power = 22.0;

void fragment() {
	vec3 tn = texture(NORMAL_TEXTURE, UV).rgb * 2.0 - 1.0;
	vec3 n = normalize(vec3(tn.x * normal_strength, -tn.y * normal_strength, max(tn.z, 0.05)));   // green up -> hull y down
	float polish = clamp((dot(texture(TEXTURE, UV).rgb, vec3(0.333)) - 0.45) / 0.5, 0.0, 1.0);      // tarnish = 0, bright crowns = 1
	vec2 p = UV * tile;
	vec3 lp = vec3(lamp_hull - p, lamp_height);
	vec3 L = normalize(lp);
	float att = lamp_energy * clamp(1.0 - length(lp.xy) / max(lamp_radius, 1.0), 0.0, 1.0);
	vec3 S = normalize(vec3(sky_hull, 0.9));
	vec3 V = vec3(0.0, 0.0, 1.0);
	float dl = max(dot(n, L), 0.0);
	float ds = max(dot(n, S), 0.0);
	float sl = pow(max(dot(n, normalize(L + V)), 0.0), spec_power);
	float ss = pow(max(dot(n, normalize(S + V)), 0.0), spec_power);
	vec3 base = COLOR.rgb;
	vec3 c = base * (ambient * (0.6 + 0.4 * n.z) + lamp_color * dl * att * diffuse_gain + sky_color * ds * sky_gain);
	c += (lamp_color * sl * att + sky_color * ss * sky_gain * 0.6) * spec_gain * (0.25 + 0.75 * polish);
	COLOR.rgb = c;
}
