shader_type canvas_item;
render_mode blend_mul, unshaded;
// The PM-02 dark kit's veil (TECH-001 §2.9 SectorDarkness): multiplies the play layer by a VOID-tinted
// ambient (never black) and lifts it back to full brightness inside soft lit discs: geodes, glass, the
// lantern, the Acolyte's ember, the light pocket. Screen px = the 640x360 logical space.

uniform vec4 ambient : source_color = vec4(0.5, 0.52, 0.66, 1.0);
// xy = screen px, z = radius px, w = strength 0..1
uniform vec4 lit[32];
uniform int lit_count = 0;
// the unlit corridor: x = top y, y = bottom y (screen px), z = extra dimming multiplier (1 = none)
uniform vec3 corridor = vec3(0.0, 0.0, 1.0);

varying vec2 pos;

void vertex() {
	pos = VERTEX;
}

void fragment() {
	float l = 0.0;
	for (int i = 0; i < lit_count; i++) {
		float d = distance(pos, lit[i].xy);
		l = max(l, lit[i].w * (1.0 - smoothstep(lit[i].z * 0.3, lit[i].z, d)));
	}
	float band = smoothstep(corridor.x - 6.0, corridor.x + 6.0, pos.y) * (1.0 - smoothstep(corridor.y - 6.0, corridor.y + 6.0, pos.y));
	vec3 base = ambient.rgb * mix(1.0, corridor.z, band);
	COLOR = vec4(mix(base, vec3(1.0), l), 1.0);
}
