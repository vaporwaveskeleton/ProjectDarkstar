class_name AetherFogBand
extends AetherShaderRect
## One fog band of the Aether at a fixed depth. Turns an AetherLook (and the quality rung) into
## this band's uniforms. Band 0 is the opaque far band (stars, engraving hatch, CHOIR haze at T4);
## nearer bands are translucent and capped over the play area at every quality rung.

## 0 = far … 4 = nearest.
@export var band_index: int = 0


func configure(look: AetherLook, quality: AetherQuality = null) -> void:
	var i := band_index
	var far := i == 0
	var drop := quality.fog_octave_drop if quality != null else 0
	set_param(&"col_deep", look.fog_deep)
	set_param(&"col_mid", look.fog_mid)
	set_param(&"col_high", look.fog_high)
	set_param(&"col_glow", look.fog_glow)
	set_param(&"floor_col", Pal.VOID_0)
	set_param(&"void_lo", Pal.VOID_1)
	set_param(&"void_hi", Pal.VOID_4)
	set_param(&"star_col", look.star_colour)
	set_param(&"tint", look.far_band_tint if far else Color(Pal.VOID_0, 0.0))
	set_param(&"is_far", 1.0 if far else 0.0)
	set_param(&"loss_stage", 0.0 if far else (1.0 if i < 3 else 2.0))
	set_param(&"octaves", maxi(3 if far else 2, look.fog_octaves - i - drop))
	set_param(&"warp_octaves", quality.warp_octaves if quality != null else 3)
	set_param(&"two_sample", quality.two_sample_advection if quality != null else 1)
	set_param(&"silver", float(quality.silver_lining) if quality != null else 1.0)
	set_param(&"fog_scale", look.fog_scale * (1.0 + 0.45 * float(i)))
	set_param(&"drift_speed", look.fog_drift_speed * (1.0 + 0.6 * float(i)))
	set_param(&"drift_dir", Vector2(1.0, 0.22 - 0.1 * float(i)))
	set_param(&"flow_strength", look.flow_strength)
	set_param(&"alpha_max", look.band_alpha * (1.0 - 0.12 * float(i)))
	set_param(&"play_fog_ceiling", look.play_fog_ceiling)
	set_param(&"hatch_strength", look.hatch_strength if far else 0.0)
	set_param(&"stars", look.star_strength if far else 0.0)
	set_param(&"deep_k", look.value_deep if far else minf(look.value_deep * 1.25, 1.0))
	set_param(&"glow_band_px", look.glow_band_px)
	set_param(&"glow_band_inset", look.glow_band_inset)
	set_param(&"seed", 1.37 * float(i) + 0.5)
	set_param(&"lift", 0.45 if far else 0.25)
	set_param(&"scatter", look.lantern_scatter * (1.0 if far else 1.4))
	set_param(&"tier", look.tier)


## Colour uniforms this band holds (tests check the floor).
func colour_params() -> Array[StringName]:
	return [&"col_deep", &"col_mid", &"col_high", &"col_glow", &"floor_col", &"void_lo", &"void_hi"]
