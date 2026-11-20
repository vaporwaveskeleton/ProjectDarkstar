class_name AetherVigilLook
extends TunableResource
## Engineering tunables (✱) and palette picks for the Aether Vigil rig (ART-001 §16.7, ART-002 §4.1).
## The hull is the player's brass: GASLIGHT GAS-0..GAS-3 (ART-001 §4, the HUD's brass), dark tarnish from VOID/GAS
## mixes, pale-gold gleams below GAS-5 (the lantern core stays the brightest warm pixel). Silver (BONE) only on the
## prow fittings. No CHOIR, no SIGNAL, PHOS not used here (the Charge lamps and ring belong to the HUD-truth work).
## Edit the .tres, not the rig.

@export_group("Brass (the player's GASLIGHT; art review 2026-11-20)")
@export var brass_shadow: Color = Pal.GAS_0.lerp(Pal.VOID_1, 0.45)
@export var brass_dark: Color = Pal.GAS_1
@export var brass_mid: Color = Pal.GAS_2
@export var brass_light: Color = Pal.GAS_2.lerp(Pal.GAS_3, 0.5)
@export var brass_high: Color = Pal.GAS_3
@export var brass_gleam: Color = Pal.GAS_4.lerp(Pal.BONE_4, 0.45)
@export var engraving: Color = Pal.VOID_1.lerp(Pal.GAS_0, 0.4)
@export var rivet: Color = Pal.GAS_3
@export var hull_outline: Color = Pal.VOID_0.lerp(Pal.GAS_0, 0.3)

@export_group("Prow fittings (silver: BONE)")
@export var prow_dark: Color = Pal.BONE_1
@export var prow_metal: Color = Pal.BONE_3
@export var prow_gleam: Color = Pal.BONE_4

@export_group("Light and glass (GAS: flames, glass, light only)")
@export var lamp_core: Color = Pal.GAS_5
@export var lamp_glass_hi: Color = Pal.GAS_4
@export var lamp_glass: Color = Pal.GAS_3
@export var lamp_ember: Color = Pal.GAS_1
@export var window_glass: Color = Pal.GAS_2
@export var run_lamp: Color = Pal.GAS_2
@export var flue_hot: Color = Pal.GAS_4
@export var flue_core: Color = Pal.GAS_5
@export var flue_ember: Color = Pal.GAS_1
@export var spark: Color = Pal.GAS_4
@export var bloom: Color = Pal.GAS_3

@export_group("Wake tints")
@export var wake_a: Color = Pal.BONE_3
@export var wake_b: Color = Pal.AETHER_3

@export_group("Shape ✱ (px, hull local +X is the nose)")
@export var hull_stern_x: float = 30.0
@export var hull_nose_x: float = 34.0
@export var hull_half_width: float = 11.0
@export var vane_span: float = 19.0
@export var vane_angle_max_deg: float = 24.0
@export var vane_accel_ref: float = 400.0
@export var globe_radius: float = 6.0
@export var globe_large_radius: float = 8.0
@export var gimbal_radius: float = 9.0

@export_group("Motion ✱")
@export var gimbal_accel_ref: float = 400.0
@export var gimbal_max_px: float = 4.0
@export var gimbal_stiffness: float = 180.0
@export var gimbal_damping: float = 14.0
@export var lamp_dim_level: float = 0.15
@export var lamp_ease_rate: float = 8.0
@export var shutter_rate: float = 10.0
@export var shutter_open_deg: float = 75.0
@export var vane_rate: float = 8.0
@export var bellows_base_hz: float = 0.8
@export var bellows_thrust_hz: float = 3.0
@export var bellows_surge_hz: float = 5.0
@export var bellows_amp: float = 0.18
@export var flue_len_base: float = 3.0
@export var flue_len_thrust: float = 9.0
@export var flue_len_surge: float = 8.0
@export var flue_flicker: float = 0.25
@export var flue_noise_hz: float = 14.0
@export var surge_bloom_s: float = 0.25

@export_group("Brass plating ✱ (loom ds_vigil_brass + vigil_plating.gdshader, ART-001 §14.8a, owner 2026-11-19)")
@export var brass_tile: float = 40.0                   ## px of hull per texture repeat
@export var rivet_radius: float = 1.0                  ## rivet head radius, px (rim and glint drawn round it)
@export var plating_lamp_energy: float = 1.0           ## the lamp's light on the plates at full lamp (scaled by the lamp level)
@export var plating_lamp_radius: float = 40.0          ## px
@export var plating_lamp_height: float = 9.0           ## px above the hull; lower = longer raking highlights
@export var plating_sky_dir: Vector2 = Vector2(-0.6, -0.8)   ## the Aether sky key, world direction toward the light
@export var plating_sky_color: Color = Pal.BONE_5
@export var plating_sky_gain: float = 0.35
@export var plating_ambient: float = 0.55                ## low, so the lantern does the lighting and Lantern Down leaves a dark brass shape
@export var plating_normal_strength: float = 1.6
@export var plating_diffuse_gain: float = 1.1
@export var plating_spec_gain: float = 1.2
@export var plating_spec_power: float = 22.0

@export_group("Detail level ✱ (art review 2026-11-20)")
@export var close_detail_zoom: float = 1.75            ## canvas scale at or above which the hull draws its close-up detail (filigree, edge rivets, all ribs)
@export var rim_light_alpha: float = 0.9               ## the light rim along the hull's lit side (sky key), gameplay read

@export_group("Glow ✱")
@export var lamp_glow_radius: float = 13.0             ## held inside the orb cage (gimbal_radius 9): the lamp lights the hull, it does not wash it out
@export var lamp_glow_alpha: float = 0.5
@export var window_glow_radius: float = 6.0
@export var flue_glow_radius: float = 16.0
@export var surge_glow_radius: float = 44.0
@export var run_lamp_glow_radius: float = 7.0

@export_group("Wake ✱")
@export var wake_max_points: int = 28
@export var wake_spacing: float = 5.0
@export var wake_life_s: float = 0.7
@export var wake_width: float = 7.0
@export var wake_alpha: float = 0.25
@export var wake_min_speed: float = 30.0

@export_group("Breach ✱")
@export var breach_gutter_s: float = 0.6
@export var breach_dark_s: float = 0.8
@export var spark_count: int = 10
@export var spark_speed: float = 60.0
@export var spark_life_s: float = 0.5


## Every palette colour this look holds (tests: no CHOIR, no SIGNAL).
func all_colors() -> Array[Color]:
	var out: Array[Color] = []
	for p in get_property_list():
		if int(p["type"]) == TYPE_COLOR:
			out.append(get(p["name"]) as Color)
	return out


func tunable_properties() -> PackedStringArray:
	var out := PackedStringArray()
	for p in get_property_list():
		if (int(p["usage"]) & PROPERTY_USAGE_SCRIPT_VARIABLE) != 0 and int(p["type"]) != TYPE_COLOR \
				and p["name"] != "ds_namespace" and p["name"] != "source_section":
			out.append(p["name"] as String)
	return out
