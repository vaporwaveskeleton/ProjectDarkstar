class_name AetherVigilLook
extends TunableResource
## Engineering tunables (✱) and palette picks for the Aether Vigil rig (ART-001 §16.7, ART-002 §4.1).
## Brass is a BONE/VOID mix; GAS only in flames, glass and light; no CHOIR, no SIGNAL, PHOS not used
## here (the Charge lamps and ring belong to the HUD-truth work). Edit the .tres, not the rig.

@export_group("Brass (BONE/VOID mixes only)")
@export var brass_shadow: Color = Pal.VOID_1.lerp(Pal.BONE_0, 0.5)
@export var brass_dark: Color = Pal.BONE_0
@export var brass_mid: Color = Pal.BONE_1
@export var brass_light: Color = Pal.BONE_2
@export var brass_high: Color = Pal.BONE_3
@export var brass_gleam: Color = Pal.BONE_4
@export var engraving: Color = Pal.VOID_2.lerp(Pal.BONE_0, 0.5)
@export var rivet: Color = Pal.BONE_3

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

@export_group("Brass plating ✱ (loom ds_vigil_brass, ART-001 §14.8a)")
@export var brass_tile: float = 40.0                   ## px of hull per texture repeat
@export var brass_specular: Color = Pal.BONE_4          ## CanvasTexture specular colour (the lamp's glint on the plate)
@export_range(0.0, 1.0) var brass_shininess: float = 0.6
@export var brass_light_energy: float = 0.9            ## the lantern's own light on the plating (lit lamp = 1)
@export var brass_light_radius: float = 48.0           ## px
@export var brass_light_height: float = 12.0           ## px above the hull, for the normal map

@export_group("Glow ✱")
@export var lamp_glow_radius: float = 26.0
@export var lamp_glow_alpha: float = 0.45
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
