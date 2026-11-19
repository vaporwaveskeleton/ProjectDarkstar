class_name AetherFogBand
extends AetherShaderRect
## One fog band of the Aether at a fixed depth. Turns an AetherLook into this band's uniforms.
## Band 0 is the opaque far band (engraving hatch, CHOIR haze at T4); nearer bands are translucent.

## 0 = far … 4 = nearest.
@export var band_index: int = 0


func configure(look: AetherLook) -> void:
	var i := band_index
	var far := i == 0
	set_param(&"col_deep", look.fog_deep if far else look.fog_mid.lerp(look.fog_deep, 0.5))
	set_param(&"col_mid", look.fog_mid)
	set_param(&"col_high", look.fog_high)
	set_param(&"floor_col", Pal.VOID_0)
	set_param(&"tint", look.far_band_tint if far else Color(Pal.VOID_0, 0.0))
	set_param(&"is_far", 1.0 if far else 0.0)
	set_param(&"octaves", maxi(2, look.fog_octaves - i))
	set_param(&"fog_scale", look.fog_scale * (1.0 + 0.45 * float(i)))
	set_param(&"drift_speed", look.fog_drift_speed * (1.0 + 0.6 * float(i)))
	set_param(&"drift_dir", Vector2(1.0, 0.22 - 0.1 * float(i)))
	set_param(&"flow_strength", look.flow_strength)
	set_param(&"alpha_max", look.band_alpha * (1.0 - 0.12 * float(i)))
	set_param(&"play_fog_ceiling", look.play_fog_ceiling)
	set_param(&"hatch_strength", look.hatch_strength if far else 0.0)
	set_param(&"seed", 1.37 * float(i) + 0.5)
	set_param(&"lift", 0.45 if far else 0.25)
	set_param(&"tier", look.tier)


## Colour uniforms this band holds (tests check the floor).
func colour_params() -> Array[StringName]:
	return [&"col_deep", &"col_mid", &"col_high", &"floor_col"]
