// Shared noise, entity-shape and sphere helpers for the Aether shaders (ART-001 §16). Code only, no textures.
// Entity uniforms: xy = screen position in logical px, z = radius px, w = 1 when active.
// The entity SUBTRACTS (pass 2): around its torn edge the world loses its layers in crisp, torn
// stages (near fog, then mid fog, then stars / life / far detail) and its colour goes cold. It is
// never a darkening gradient toward black: the only black is the entity's own shape.

uniform vec2 screen_size = vec2(640.0, 360.0);
uniform vec4 entity_0 = vec4(0.0);
uniform vec4 entity_1 = vec4(0.0);
uniform vec4 entity_2 = vec4(0.0);
uniform vec4 entity_3 = vec4(0.0);
uniform vec4 entity_seeds = vec4(0.7, 3.1, 5.9, 8.4);
uniform float entity_time = 0.0;
// The hero sphere seam on screen: xy centre (logical px), z radius.
uniform vec3 sphere_screen = vec3(320.0, 1000.0, 900.0);

float a_hash(vec2 p) {
	vec3 p3 = fract(vec3(p.xyx) * 0.1031);
	p3 += dot(p3, p3.yzx + 33.33);
	return fract((p3.x + p3.y) * p3.z);
}

float a_noise(vec2 p) {
	vec2 i = floor(p);
	vec2 f = fract(p);
	vec2 u = f * f * (3.0 - 2.0 * f);
	return mix(mix(a_hash(i), a_hash(i + vec2(1.0, 0.0)), u.x),
		mix(a_hash(i + vec2(0.0, 1.0)), a_hash(i + vec2(1.0, 1.0)), u.x), u.y);
}

float a_fbm(vec2 p, int octaves) {
	float v = 0.0;
	float a = 0.5;
	mat2 rot = mat2(vec2(0.8, 0.6), vec2(-0.6, 0.8));
	for (int i = 0; i < 7; i++) {
		if (i >= octaves) {
			break;
		}
		v += a * a_noise(p);
		p = rot * p * 2.03 + vec2(1.7, 9.2);
		a *= 0.5;
	}
	return v;
}

// Pass 4 pareidolia guard (ART-001 rule, adopted: no closed holes in organic shapes near the play
// centre). Over the play core the fog is built from STRIP fields only, so no threshold of it can
// enclose a hole (an eye socket, a skull):
//   w.x = across-flow position + a slow meander along the flow: any function of w.x alone has level
//         sets that are graphs over the flow axis — strands that run out of the frame, never rings;
//   w.y = along-flow position (stretched A_FOG_STREAK x) + a slow meander across it: transverse strips.
// A field f = min(g(w.x), e(w.y), ...) has every sublevel set {f < t} = a union of strips, each
// reaching the border, so its background is always border-connected. Mirrored on the CPU in
// features/aether/tests/test_aether_pass4.gd, which flood-fills it for enclosed holes.
// ✱ how far the fog is stretched along its drift over the play core.
const float A_FOG_STREAK = 3.2;
// ✱ the play core (pure strip field) and the ring where it blends back to the free fog, as a
// fraction of the screen height from the screen centre.
const float A_PLAY_CORE = 0.22;
const float A_PLAY_RING = 0.5;
// ✱ pass 5 (Q-T94): play-core weight at which the translucent bands are the strip field outright
// (the free fog is not computed there).
const float A_STRIP_FULL = 0.8;

vec2 a_strip_coords(vec2 p, vec2 dir, float sd) {
	vec2 fd = normalize(dir);
	float al = dot(p, fd);
	float ac = dot(p, vec2(-fd.y, fd.x));
	return vec2(ac + 0.7 * a_noise(vec2(al * 0.45, sd * 5.0)) + 0.22 * a_noise(vec2(al * 1.9, sd * 5.0 + 3.0)),
		al / A_FOG_STREAK + 0.9 * a_noise(vec2(ac * 0.6, sd * 3.0 + 9.0)) + 0.45 * a_noise(vec2(ac * 2.1, sd * 3.0 + 1.0)));
}

// Play-core wisps: long open strands (an across-flow fbm) cut into lengths by an along-flow envelope.
float a_fog_streak(vec2 w, float sd, int oct) {
	float g = a_fbm(vec2(w.x * 2.6, sd * 3.0), oct);
	float e = a_fbm(vec2(w.y * 1.3, sd * 3.0 + 17.0), 2);
	return 0.5 + (min(g, e + 0.25) - 0.5) * 0.75;   // monotone: same level-set topology, softer
}

// T5 chalk: strokes across the flow coordinate only (open, directional; never contour rings of the
// fog, which closed into loops with holes and read as skulls beside the lantern).
// Irregular spacing and width (a 1D fbm across the flow), so they never read as ribs or stripes.
float a_chalk_strand(float wx, float sd) {
	return smoothstep(0.42, 0.62, a_fbm(vec2(wx * 4.2, sd * 7.0 + 2.0), 3));
}

// Pass 5 (satin fix): the play-core strands are cut along their length into SHORT RAGGED STREAKS.
// A function of ph = w.y * A_FOG_DASH + h(w.x) only: every level set of it is a graph over the
// across-flow axis (it crosses the whole frame), so min()-ing it into the strip field keeps the
// no-enclosed-hole property (mirrored + flood-filled in test_aether_pass5.gd). h(w.x) staggers the
// cuts strand by strand and frays their ends.
// ✱ dash frequency along the strand (per strip unit; about 50–100 px streaks at fog_scale 150).
const float A_FOG_DASH = 9.0;

float a_dash_phase(vec2 w, float sd) {
	return w.y * A_FOG_DASH + 1.8 * a_noise(vec2(w.x * 7.0, sd * 2.0 + 5.0)) + 0.5 * a_noise(vec2(w.x * 23.0, sd * 2.0 + 8.0));
}

float a_fog_dash(float ph, float sd) {
	return smoothstep(0.28, 0.6, a_noise(vec2(ph, sd * 4.0 + 11.0)));
}

// Streak SHADE: flat, varied only ALONG the strand (the dash phase), never across it — a gradient
// across the strand's width is what read as satin sheets / bedding (pass 4 critique).
float a_streak_shade(float ph, float sd) {
	return 0.4 + 0.12 * a_noise(vec2(ph * 0.37, sd * 4.0 + 29.0));
}

// Pass 5, law 4 (nothing outshines the lantern; ART-001 §16.3): over the play core every fog band's
// own light (before the lantern's in-scatter) is capped at this luminance, faded out across the play
// ring. test_aether_pass5.gd bounds the result against the lantern pool for every look.
// ✱ fog luminance cap over the play core.
const float A_PLAY_FOG_LUMA = 0.14;

float a_luma(vec3 c) {
	return dot(c, vec3(0.299, 0.587, 0.114));
}

vec3 a_cap_luma(vec3 c, float cap, float w) {
	float l = dot(c, vec3(0.299, 0.587, 0.114));
	return l > cap ? mix(c, c * (cap / l), w) : c;
}

// Ridged noise in -0.5..0.5: sharp creases (V's), never smooth swells.
float a_ridge(vec2 p) {
	return abs(a_noise(p) - 0.5) * 2.0 - 0.5;
}

// Pass 4 (boxy-coastline fix): every bite is a wedge whose two flanks lean by their own angles, and
// its opening is either ACUTE or OBTUSE, never near a right angle (radians; 0.55..1.15 = 32°..66°,
// 2.0..2.3 = 115°..132°). Obtuse bites are shallow and lean less (each flank stays < 90° from the
// radial), so they stay bites, not bays.
const vec2 A_BITE_ACUTE = vec2(0.55, 1.15);
const vec2 A_BITE_OBTUSE = vec2(2.0, 2.3);
// The entity's edge fractures (N7: no limbs) live only in 0 < s < A_ENT_CRACK_BAND * grow.
const float A_ENT_CRACK_BAND = 0.24;

// A wedge bite out of the rim at angle `ang` (< 0 inside the bite): apex `depth` inside the rim,
// opening `open` radians, flanks leaned by `lean` (-0.25..0.25 of the opening) so no two match.
float a_bite(vec2 p, float ang, float depth, float open, float lean) {
	vec2 rad = vec2(cos(ang), sin(ang));
	vec2 q = p - rad * (1.02 - depth);
	float a1 = open * (0.5 + lean);
	float a2 = open * (0.5 - lean);
	vec2 d1 = vec2(cos(ang + a1), sin(ang + a1));
	vec2 d2 = vec2(cos(ang - a2), sin(ang - a2));
	float e1 = dot(q, vec2(d1.y, -d1.x));
	float e2 = dot(q, vec2(-d2.y, d2.x));
	return -min(e1, e2);
}

// The entity's outline in its own normalised space (p = offset / radius). < 0 inside.
// Pass 3 (N4, NARR-001 §3.4: the entity never has a face): only a GENTLE large-scale warp, because
// big smooth bulges along an edge read as a brow / nose / lips / chin in profile. The tear lives in
// ridged (creased) noise at mid and fine scales plus angular, sheared bites: jagged fray, eaten
// corners, no smooth concave / convex alternation. One ruled cut, TERRACED into straight steps,
// and one impossible sharp inner corner: geometry that should not exist in fog. Pass 4: no right
// angles anywhere on the coastline (bites acute or obtuse, slanted terrace risers, a 62° notch).
float a_entity_shape_b(vec2 p, float seed, float t, int oct, int bite_step) {
	vec2 w = p + 0.14 * vec2(a_noise(p * 0.8 + vec2(seed, t * 0.03)) - 0.5,
		a_noise(p * 0.8 + vec2(seed + 4.1, -t * 0.025)) - 0.5);
	float d = length(w * vec2(1.0, 1.12)) - 1.0;
	d += 0.075 * a_ridge(w * 3.4 + vec2(seed * 3.0, t * 0.02));
	if (oct > 2) {
		d += 0.065 * a_ridge(w * 9.5 + seed);
	}
	if (oct > 3) {
		d += 0.03 * (a_noise(w * 24.0 - seed) - 0.5);
		d += 0.016 * (a_noise(w * 61.0 + seed * 2.0) - 0.5);
	}
	// angular eaten bites (pass 4): acute and obtuse wedges alternate by hash, each leaned its own
	// way, so the coastline never makes a square notch
	for (int i = 0; i < 8; i++) {
		if (i % bite_step != 0) {
			continue;   // pass 5 (Q-T94): the loss mask carries every other bite only
		}
		float h1 = a_hash(vec2(seed, float(i) * 1.7 + 0.2));
		float h2 = a_hash(vec2(float(i) + 5.3, seed * 0.7));
		float h3 = a_hash(vec2(float(i) * 3.1 + seed, 4.4));
		float ang = 6.2831853 * (float(i) + 0.7 * h1) / 8.0 + seed;
		bool acute = h3 < 0.55;
		float open = acute ? mix(A_BITE_ACUTE.x, A_BITE_ACUTE.y, h1) : mix(A_BITE_OBTUSE.x, A_BITE_OBTUSE.y, h1);
		float depth = acute ? 0.08 + 0.14 * h2 : 0.035 + 0.045 * h2;
		d = max(d, -a_bite(p, ang, depth, open, (h2 - 0.5) * (acute ? 0.5 : 0.2)));
	}
	// the ruled cut, terraced: straight treads, each tilted its own way, with SLANTED risers (pass 4:
	// no right-angle steps; the corners alternate acute / obtuse)
	float ca = seed * 2.4;
	vec2 cn = vec2(cos(ca), sin(ca));
	vec2 ct = vec2(-cn.y, cn.x);
	float tx = dot(p, ct) + 0.62 * dot(p, cn);
	float terrace = floor(tx / 0.31 + seed * 3.0);
	float th = a_hash(vec2(terrace, seed + 2.0));
	d = max(d, dot(p, cn) - 0.74 - 0.09 * (th - 0.5) - 0.28 * (th - 0.5) * (fract(tx / 0.31 + seed * 3.0) - 0.5) * 0.31);
	// the impossible inner corner: a SHARP (62°) notch bitten into the rim, leaned to one side
	float cb = seed * 1.7 + 2.2;
	vec2 c = vec2(cos(cb), sin(cb)) * 0.86;
	vec2 a1 = vec2(cos(cb + 1.2), sin(cb + 1.2));
	vec2 a2 = vec2(cos(cb - 0.89), sin(cb - 0.89));
	d = max(d, min(dot(p - c, a1), dot(p - c, a2)));
	return d;
}

// The entity's own outline (all eight bites).
float a_entity_shape(vec2 p, float seed, float t, int oct) {
	return a_entity_shape_b(p, seed, t, oct, 1);
}

// Pass 5 (Q-T94 cost): the loss mask is cheap. Bites only ever ADD to d, so the 4-bite outline is
// <= the entity's 8-bite one: the loss steps stay at or outside where they were relative to the
// mass (the crack band stays inside the mid loss step). Beyond A_LOSS_REACH radii every loss step
// is provably 0 (|w - p| <= 0.099, ridge <= 0.0375: s >= |p| - 1.1365, and s_out >= s - 0.0584, so past
// A_LOSS_REACH + aa radii s_out > A_LOSS_REACH - 1.195 + aa > the outer step's furthest edge,
// 0.5 + A_LOSS_ARM + A_LOSS_SOFT + 0.025 + aa), so the shape is not evaluated: proximity comes from
// the round distance instead (a soft cold ring either way). Pass 6: 1.75 → 2.02 for the spiral arms.
// ✱ normalised radius past which the loss steps are skipped.
const float A_LOSS_REACH = 2.02;
// Pass 6 (B1; PM: no closed circles in ORGANIC or FOG shapes near the play centre — orrery rings and
// crystal spheres are geometric and exempt). The pass 5 mid step around a T5 hole was a near-perfect
// circle (an iris round the swirl: it read as an EYE). The near and mid steps now ride TWO SPIRAL
// ARMS: each reaches out by up to A_LOSS_ARM radii along a sawtooth in the angle that BREAKS every
// half turn (a radial torn step), so no arc of either boundary turns past half a turn; and on the
// side facing the frame centre each step's outer edge softens into the fog over A_LOSS_SOFT radii.
// Both only push the steps OUTWARD: the crack band stays inside the mid step (test_aether_pass4).
// ✱ outward reach of the arms, and of the soft side, in entity radii.
const float A_LOSS_ARM = 0.2;
const float A_LOSS_SOFT = 0.08;
// ✱ bites carried by the loss mask: every A_LOSS_BITE_STEP-th of the eight.
const int A_LOSS_BITE_STEP = 2;

// Layer loss around every entity: the STEPPED subtraction boundary (pass 3), three crisp nested
// edges, each slightly offset from the next so they read as eating, not as a glow:
//   outer  — x = near fog gone, y = mid fog / leviathan / rays / seam gone (fog scatter stops);
//   middle — z = stars, life and far detail gone: the far band there is a flat cold VOID;
//   inner  — the entity's own shape, the only black (entity_presence.gdshader).
// w = proximity 0..1 (for the inflow and the cold cast). Cheap outline (2 scales).
vec4 a_loss(vec2 px) {
	vec4 L = vec4(0.0);
	vec4 es[4] = vec4[4](entity_0, entity_1, entity_2, entity_3);
	for (int i = 0; i < 4; i++) {
		vec4 e = es[i];
		if (e.w < 0.5 || e.z < 0.5) {
			continue;
		}
		vec2 p = (px - e.xy) / e.z;
		float pl = length(p * vec2(1.0, 1.12));
		// proximity from the round distance everywhere (continuous across the early-out)
		float prox = clamp(1.0 - (pl - 1.0) / 1.3, 0.0, 1.0);
		if (length(p) > A_LOSS_REACH + 1.2 / e.z) {
			L.w = max(L.w, prox);
			continue;
		}
		float sd = entity_seeds[i];
		float s = a_entity_shape_b(p, sd, entity_time, 2, A_LOSS_BITE_STEP);
		float aa = 1.2 / e.z;
		// each edge its own crisp tear and a small offset (nested, never concentric copies)
		float tear = 0.05 * a_ridge(p * 5.1 + sd * 5.0);
		// the outer edge offset by (0.05, -0.03) radii (first-order shift: no second shape eval)
		float s_out = s - dot(p / max(length(p), 0.001), vec2(0.05, -0.03));
		// pass 6: two half-turn spiral arms (atan / π: the sawtooth wraps twice a turn) and a soft side
		float arm = A_LOSS_ARM * fract(atan(p.y, p.x) * 0.31830989 + sd * 0.37);
		vec2 to_c = normalize(screen_size * 0.5 - e.xy + vec2(0.001));
		float soft = A_LOSS_SOFT * smoothstep(0.1, 0.8, dot(p / max(length(p), 0.001), to_c));
		float near_l = 1.0 - smoothstep(0.5 + arm + tear - aa, 0.5 + arm + tear + aa + soft, s_out);
		float mid_l = 1.0 - smoothstep(0.4 + arm + tear - aa, 0.4 + arm + tear + aa + soft, s_out);
		float far_l = 1.0 - smoothstep(0.19 - tear * 0.6 - aa, 0.19 - tear * 0.6 + aa, s);
		L = max(L, vec4(near_l, mid_l, far_l, prox));
	}
	return L;
}

// Direction (screen px, normalised) toward the nearest active entity, and its proximity in w.
vec3 a_toward_entity(vec2 px) {
	vec3 best = vec3(0.0);
	float best_d = 1e9;
	vec4 es[4] = vec4[4](entity_0, entity_1, entity_2, entity_3);
	for (int i = 0; i < 4; i++) {
		vec4 e = es[i];
		if (e.w < 0.5 || e.z < 0.5) {
			continue;
		}
		vec2 rel = e.xy - px;
		float d = length(rel) / e.z;
		if (d < best_d) {
			best_d = d;
			best = vec3(rel / max(length(rel), 0.001), clamp(1.0 - (d - 1.0) / 1.6, 0.0, 1.0));
		}
	}
	return best;
}

// Legacy round reach (kept for cheap callers): 0 far away, 1 at an entity's edge.
float a_drunk(vec2 px) {
	return a_loss(px).z;
}

// Signed distance (logical px) from the hero sphere seam; < 0 inside (where we are).
float a_sphere_d(vec2 spx) {
	return length(spx - sphere_screen.xy) - sphere_screen.z;
}

// Pass 6 (G-2 tier sort): ONE monotonic "missing" cue per look (`missing` 0..1, ✱: T1 0 … T5 0.85)
// drives the backdrop's saturation drain and the VOID SHARE of the frame together. The void share
// is a slice of the far layer that is simply not there: a flat cold VOID (never black — only the
// entity is) along a far seam, the engraved parallel A_MISS_SEAM px inside the hero seam. It starts
// OFF-CENTRE (A_MISS_X, left of the play core) and grows from inside the picture: a hairline at T2,
// wider and longer each tier; it never reaches the frame edge (NARR N8). Its edges are torn into a
// stepped staircase along the seam (no smooth lens: a tapered slit read as an eye).
// ✱ the slice's seam (px inside the hero seam: the engraved parallel), its start (logical px across
// the 640-wide frame), its half-length and half-width at missing = m:
//   half-length A_MISS_LEN.x + A_MISS_LEN.y m (px along the seam; the side toward the centre is
//   A_MISS_INWARD as long), half-width A_MISS_W.x + A_MISS_W.y m² (px).
const float A_MISS_SEAM = -44.0;
const float A_MISS_X = 170.0;
const vec2 A_MISS_LEN = vec2(30.0, 130.0);
const float A_MISS_INWARD = 0.4;
const vec2 A_MISS_W = vec2(0.7, 16.0);
// ✱ the saturation the backdrop loses at missing = 1 (fog and sphere; the lantern pool is spared).
const float A_MISS_DESAT = 0.9;

float a_missing(vec2 spx, float m) {
	if (m <= 0.0) {
		return 0.0;
	}
	float hw = A_MISS_W.x + A_MISS_W.y * m * m;
	float sd = a_sphere_d(spx) - A_MISS_SEAM;
	if (abs(sd) > hw * 1.5 + 2.0) {
		return 0.0;
	}
	float rr = sphere_screen.z + A_MISS_SEAM;
	vec2 rel = spx - sphere_screen.xy;
	float arc = atan(rel.x, -rel.y) * rr;
	float arc0 = asin(clamp((A_MISS_X - sphere_screen.x) / rr, -1.0, 1.0)) * rr;
	float u = (arc - arc0) / (A_MISS_LEN.x + A_MISS_LEN.y * m);
	u = u < 0.0 ? -u : u / A_MISS_INWARD;
	if (u >= 1.0) {
		return 0.0;
	}
	// torn staircase: the width steps every 9 px along the seam, each step rounded its own way
	float cellx = floor(arc / 9.0);
	float taper = pow(1.0 - u * u, 0.7);
	float w = max(hw * clamp(floor(taper * 3.0 + a_hash(vec2(cellx, 2.0))) / 3.0 + 0.12, 0.0, 1.0), A_MISS_W.x);
	float tear = hw * 0.35 * (a_hash(vec2(cellx, 5.0)) - 0.5);
	return 1.0 - smoothstep(w - 0.6, w + 0.6, abs(sd + tear));
}

float a_seg(vec2 p, vec2 a, vec2 b) {
	vec2 pa = p - a;
	vec2 ba = b - a;
	float h = clamp(dot(pa, ba) / max(dot(ba, ba), 0.0001), 0.0, 1.0);
	return length(pa - ba * h);
}

// Glass fracture, not lightning: straight segments from an impact `c`, each ray kinked once,
// a few straight chords between neighbouring rays (shards), foreshortened along the sphere
// (`tang` = seam tangent; the normal component is squashed by `fore`). Returns x = distance to
// the nearest fracture line (logical px), y = gap coverage (a sliver opening along the main rays,
// `gap_w` px wide at the impact).
vec2 a_glass(vec2 px, vec2 c, float reach, float seed, vec2 tang, float fore, float gap_w) {
	if (reach < 1.0 || length(px - c) > reach * 1.3) {
		return vec2(1e4, 0.0);
	}
	vec2 nrm = vec2(-tang.y, tang.x);
	float line = 1e4;
	float gap = 0.0;
	vec2 prev_a = c;
	vec2 prev_b = c;
	for (int i = 0; i < 8; i++) {
		float h1 = a_hash(vec2(float(i) + 0.5, seed));
		float h2 = a_hash(vec2(seed, float(i) + 3.1));
		float ang = (float(i) + 0.7 * h1) * 1.0471976 + seed;
		vec2 dir = normalize(tang * cos(ang) + nrm * sin(ang) * fore);
		float l1 = reach * (0.3 + 0.45 * h2);
		vec2 k = c + dir * l1;
		float ang2 = ang + (h1 - 0.5) * 0.8;
		vec2 dir2 = normalize(tang * cos(ang2) + nrm * sin(ang2) * fore);
		vec2 e = k + dir2 * reach * (0.2 + 0.45 * h1) * step(0.25, h2);
		float s1 = a_seg(px, c, k);
		line = min(line, min(s1, a_seg(px, k, e)));
		if (h2 > 0.5) {
			float tpos = clamp(dot(px - c, dir) / l1, 0.0, 1.0);
			float w = gap_w * (1.0 - tpos) * (1.0 - tpos * 0.3);
			gap = max(gap, (1.0 - smoothstep(w * 0.5, w + 0.01, s1)) * step(0.02, w));
		}
		vec2 ca = c + dir * l1 * 0.45;
		vec2 cb = c + dir * l1 * 0.8;
		if (i > 0 && h1 > 0.45) {
			line = min(line, a_seg(px, prev_a, ca));
		}
		if (i > 0 && h2 < 0.3) {
			line = min(line, a_seg(px, prev_b, cb));
		}
		prev_a = ca;
		prev_b = cb;
	}
	return vec2(line, gap);
}

// The Presence (leviathan) body line in its own quad: x local px -> (centre y, thickness).
// Shared by the leviathan and the god-rays it shadows. Pass 3: a long tapering head (no blunt
// round "cave mouth"), a slow undulation (the belly is one long curve, visibly bending within a
// frame width) and an
// asymmetric section — the back takes A_LEV_BACK of the thickness above the centre line, the
// belly A_LEV_BELLY below it.
const float A_LEV_BACK = 0.6;
const float A_LEV_BELLY = 0.4;

vec2 a_lev_profile(float x, float t, vec2 quad, float thick) {
	float len = quad.x * 0.92;
	float u = (x - quad.x * 0.04) / len;
	float uc = clamp(u, 0.0, 1.0);
	float wave = sin(uc * 5.0 - t * 0.1 + 0.6) * 26.0 * (0.5 + uc);
	float th = thick * pow(clamp(u / 0.26, 0.0, 1.0), 0.58) * pow(max(1.0 - uc, 0.0), 0.8);
	return vec2(quad.y * 0.5 + wave, th * step(0.0, u) * step(u, 1.0));
}
