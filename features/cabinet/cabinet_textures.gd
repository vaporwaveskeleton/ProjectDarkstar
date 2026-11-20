class_name CabinetTextures
extends RefCounted
## loom renders for the Cabinet's physical surfaces (ART-001 §14.8a and the §15.1 T0 bezel row; source
## art/src/cabinet_textures.tx.js, never hand-edited). Bezel hardware only: nothing here touches the screen.
## Laminate and steel are neutral detail maps: the shader reads their albedo as luminance around MEAN and
## multiplies the CabinetSurface colour by it, so the real-object colours stay in CabinetSurface. The side
## panel's albedo is its full colour (Pal roles). Every normal map is OpenGL (green up). Presentation only (✱).

const LAMINATE_ALBEDO := preload("res://assets/art/generated/textures/ds_cab_laminate/ds_cab_laminate_albedo.png")
const LAMINATE_NORMAL := preload("res://assets/art/generated/textures/ds_cab_laminate/ds_cab_laminate_normal.png")
const SIDE_ALBEDO := preload("res://assets/art/generated/textures/ds_cab_side/ds_cab_side_albedo.png")
const SIDE_NORMAL := preload("res://assets/art/generated/textures/ds_cab_side/ds_cab_side_normal.png")
const STEEL_ALBEDO := preload("res://assets/art/generated/textures/ds_cab_steel/ds_cab_steel_albedo.png")
const STEEL_NORMAL := preload("res://assets/art/generated/textures/ds_cab_steel/ds_cab_steel_normal.png")

const BRUSHED_ALBEDO := preload("res://assets/art/generated/textures/ds_cab_brushed/ds_cab_brushed_albedo.png")
const GLASS_SMUDGE := preload("res://assets/art/generated/textures/ds_cab_glass_smudge/ds_cab_glass_smudge_albedo.png")

## ✱ mean albedo luma of each neutral detail map, from `loom info` (rebuild the texture → update these).
const LAMINATE_MEAN := 0.86
const STEEL_MEAN := 0.80
const BRUSHED_MEAN := 0.86


## Bind the brushed-metal trim map to `mat`'s `trim_*` uniforms (cabinet_detail.gdshaderinc).
static func bind_trim(mat: ShaderMaterial, tile: float) -> void:
	mat.set_shader_parameter(&"trim_albedo", BRUSHED_ALBEDO)
	mat.set_shader_parameter(&"trim_tile", tile)
	mat.set_shader_parameter(&"trim_mean", BRUSHED_MEAN)


## Bind one albedo/normal pair to `mat`'s `detail_*` uniforms. `tile` = rig units per texture repeat.
static func bind(mat: ShaderMaterial, albedo: Texture2D, normal: Texture2D, tile: float, mean: float, gain: float) -> void:
	mat.set_shader_parameter(&"detail_albedo", albedo)
	mat.set_shader_parameter(&"detail_normal", normal)
	mat.set_shader_parameter(&"detail_tile", tile)
	mat.set_shader_parameter(&"detail_mean", mean)
	mat.set_shader_parameter(&"detail_gain", gain)
