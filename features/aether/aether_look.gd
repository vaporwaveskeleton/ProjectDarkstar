class_name AetherLook
extends TunableResource
## One look of the Aether (the world after the Pretence, ART-001 §15–§16) for one biome and tier.
## Palette role picks are Pal entries chosen in the .tres; shaders receive them as uniforms.
## Every number here is a dev-gallery placeholder: engineering params carry ✱, design params are
## marked "owner to set". None of them is a game number until SYS-001 says so.

## Fidelity tier (ART-001 §15): 1 Pale Marches … 5 The Black.
@export_range(1, 5) var tier: int = 1
## Glossary-free biome slug, used for the ds_ namespace (e.g. "pale_marches").
@export var biome: String = ""

@export_group("Palette roles (Pal entries only)")
## Deepest fog tone; the far band's floor before the VOID_0 clamp.
@export var fog_deep: Color = Pal.VOID_1
@export var fog_mid: Color = Pal.VOID_3
@export var fog_high: Color = Pal.VOID_5
## Crystal-sphere seam and refraction tint (PHOS = truth).
@export var sphere_glass: Color = Pal.PHOS_4
## Aether-life glow (PHOS).
@export var life_glow: Color = Pal.PHOS_3
## Secondary life tone (motes, spores).
@export var life_secondary: Color = Pal.BONE_4
## Far silhouettes (leviathan, distant smudge): VOID tones, never NULL.
@export var far_silhouette: Color = Pal.VOID_2
## Far-band incense tint. CHOIR only at tier 4; alpha 0 means none.
@export var far_band_tint: Color = Color(Pal.VOID_0, 0.0)
## Sky-crack fracture edge (PHOS_5 / BONE_5).
@export var crack_edge: Color = Pal.PHOS_5
## The Aether behind the Aether, seen through the cracks.
@export var behind_a: Color = Pal.PHOS_4
@export var behind_b: Color = Pal.BONE_5
## God-ray tint.
@export var shaft_tint: Color = Pal.BONE_4
## Brass ribs of the lamp's interior (T4 only).
@export var rib_colour: Color = Pal.BONE_1
@export var rib_accent: Color = Pal.BONE_1   ## GAS-0/1 only at T4 (ART-001 §4 lamp-interior exception)
## Highlight of the luminous fog band inside the sphere shell (the tier's dominant hue, lit).
@export var fog_glow: Color = Pal.VOID_5
## Far-field stars.
@export var star_colour: Color = Pal.BONE_4
## Brass of the sphere's meridian bands and the far set pieces (BONE; never GAS off the lamp).
@export var brass: Color = Pal.BONE_2
## The Presence: rim where the god-rays catch its back (VOID_5 / BONE_2) and its flank lights (PHOS).
@export var leviathan_rim: Color = Pal.VOID_5
@export var leviathan_lights: Color = Pal.PHOS_4
## The tier's accent hue (one per tier; pass 2 colour law).
@export var accent: Color = Pal.PHOS_4

@export_group("Rungs")
@export var lantern_light: bool = true
## ✱ number of fog bands drawn (1–5); the far band is always band 0.
@export_range(1, 5) var fog_band_count: int = 3
@export var emitters_bloom: bool = false
@export var god_rays: bool = false
@export var refraction: bool = false
@export var leviathan: bool = false
@export var sky_cracks: bool = false
@export var subtraction: bool = false
@export var life: bool = true
@export var motes: bool = true
@export var jellies: bool = false
@export var spores: bool = false
@export var school: bool = false
@export var orrery: bool = false
## A far smudge that does not move with the fog (T1 wrongness).
@export var still_smudge: bool = false
## Far set pieces (runtime vector, far band, fogged), one silhouette family per tier (pass 3):
## brass orrery armillary rings (T1).
@export var set_orrery_rings: bool = false
## Gaslit lattice fragments: riveted girders with tiny warm windows (unused since pass 3).
@export var set_lattice: bool = false
## A drowned observatory dome and telescope housing (T3).
@export var set_dome: bool = false
## A gaslit greenhouse: pointed glasshouse ribs overgrown with spore fuzz (T2).
@export var set_greenhouse: bool = false
## Broken armillary ring fragments drifting apart (T5).
@export var set_ring_fragments: bool = false
## Holes of true black in the far field (T5).
@export var black_holes: bool = false
## Crisp engraved Roman numerals I–XII on the brass meridian band (pass 4, Q-T92; decorative
## engraving, not UI text). Off = graduations only. Pending PM approval.
@export var meridian_numerals: bool = true

@export_group("Design (owner to set)")
## owner to set (design number; placeholder for the dev gallery only). Fog density multiplier in the central play area, 0–1.
@export var play_fog_ceiling: float = 0.35
## owner to set (design number; placeholder for the dev gallery only). Lantern PointLight2D energy.
@export var lantern_energy: float = 1.6
## owner to set (design number; placeholder for the dev gallery only). Lantern light radius in logical px.
@export var lantern_radius: float = 120.0
## owner to set (design number; placeholder for the dev gallery only). Multiplier on life particle counts.
@export var life_density: float = 1.0

@export_group("Engineering")
## ✱ fbm octaves for the far band (nearer bands use one or two fewer).
@export var fog_octaves: int = 5
## ✱ fog drift speed (noise units per second).
@export var fog_drift_speed: float = 0.02
## ✱ flow-field advection strength (how visible the currents are).
@export var flow_strength: float = 0.6
## ✱ fog feature size in logical px per noise unit.
@export var fog_scale: float = 150.0
## ✱ opacity of the mid/near bands at full density.
@export var band_alpha: float = 0.55
## ✱ Parallax2D scroll_scale per band (far → near).
@export var band_scroll_0: float = 0.04
## ✱
@export var band_scroll_1: float = 0.15
## ✱
@export var band_scroll_2: float = 0.35
## ✱
@export var band_scroll_3: float = 0.7
## ✱
@export var band_scroll_4: float = 1.1
## ✱ engraving cross-hatch strength on the far band (0–1, subtle).
@export var hatch_strength: float = 0.25
## ✱ strength of the second, "wrong" sphere seam.
@export var wrong_seam_strength: float = 0.0
## ✱ refraction offset in logical px.
@export var refraction_strength: float = 0.0
## ✱ god-ray intensity (kept well below the lantern).
@export var shaft_intensity: float = 0.0
## ✱ sky-crack coverage 0–1.
@export var crack_amount: float = 0.0
## ✱ sphere shatter mask 0–1 (T5).
@export var sphere_crack: float = 0.0
## ✱ chromatic subtraction 0–1 (T5).
@export var subtraction_amount: float = 0.0
## ✱ particle counts before life_density.
@export var mote_count: int = 140
## ✱
@export var jelly_count: int = 0
## ✱
@export var spore_count: int = 0
## ✱
@export var school_count: int = 0
## ✱ particle speed sign/scale (negative = reversed, T5).
@export var life_speed: float = 1.0
## ✱ WorldEnvironment glow HDR threshold.
@export var glow_threshold: float = 0.95
## ✱ glow intensity.
@export var glow_intensity: float = 0.6
## ✱ glow bloom amount.
@export var glow_bloom: float = 0.0
## ✱ leviathan crossing time in seconds.
@export var leviathan_cross_s: float = 20.0
## ✱ leviathan pass period in seconds (crossing + absence).
@export var leviathan_period_s: float = 34.0
## ✱ seconds into the period at exhibit start.
@export var leviathan_phase_s: float = 4.0
## ✱ camera drift amplitude in logical px.
@export var camera_drift_px: float = 18.0
## ✱ drain applied from the start (T5 has the world already partly drunk).
@export var base_drain: float = 0.0
## ✱ star field strength in the far band (0 = none).
@export var star_strength: float = 0.8
## ✱ brightness of the far fog away from the luminous band (value structure: deep far field).
@export var value_deep: float = 0.35
## ✱ half-width of the luminous fog band inside the sphere shell, logical px.
@export var glow_band_px: float = 70.0
## ✱ inset of the luminous band's peak below the seam, logical px.
@export var glow_band_inset: float = 55.0
## ✱ lantern light scattered by the fog (how warm the pool reads).
@export var lantern_scatter: float = 0.3
## ✱ vast, far, cropped jelly-lanterns (very dim).
@export var vast_jelly_count: int = 0


func tunable_properties() -> PackedStringArray:
	return PackedStringArray([
		"tier", "fog_band_count", "play_fog_ceiling", "lantern_energy", "lantern_radius", "life_density",
		"fog_octaves", "fog_drift_speed", "flow_strength", "fog_scale", "band_alpha",
		"band_scroll_0", "band_scroll_1", "band_scroll_2", "band_scroll_3", "band_scroll_4",
		"hatch_strength", "wrong_seam_strength", "refraction_strength", "shaft_intensity",
		"crack_amount", "sphere_crack", "subtraction_amount",
		"mote_count", "jelly_count", "spore_count", "school_count", "life_speed",
		"glow_threshold", "glow_intensity", "glow_bloom",
		"leviathan_cross_s", "leviathan_period_s", "leviathan_phase_s", "camera_drift_px", "base_drain",
		"star_strength", "value_deep", "glow_band_px", "glow_band_inset", "lantern_scatter", "vast_jelly_count",
	])


## Scroll scale of band `i` (0 = far).
func band_scroll(i: int) -> float:
	var s: Array[float] = [band_scroll_0, band_scroll_1, band_scroll_2, band_scroll_3, band_scroll_4]
	return s[clampi(i, 0, s.size() - 1)]


## Every Color field, by name (tests walk these).
func colour_fields() -> PackedStringArray:
	return PackedStringArray(["fog_deep", "fog_mid", "fog_high", "sphere_glass", "life_glow", "life_secondary",
		"far_silhouette", "far_band_tint", "crack_edge", "behind_a", "behind_b", "shaft_tint", "rib_colour", "rib_accent",
		"fog_glow", "star_colour", "brass", "accent", "leviathan_rim", "leviathan_lights"])
