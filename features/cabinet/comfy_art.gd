class_name ComfyArt
extends TunableResource
## Data switches for the two ComfyUI-generated "real world" images the Cabinet ships (owner picks 2026-11-20,
## ART-001 §14.9, TECH-001 §2.10): the worn masking tape over the coin slot (CoinSlot's TapeStrip) and the warm
## arcade backdrop (ArcadeBackdrop's shader). Both default ON; off restores the code-drawn hazard tape and the
## code-drawn arcade exactly as before. The files live in res://assets/art/comfyui/ (manifest-checked). Edit
## data/cabinet/comfy_art.tres to flip. Engineering presentation data (✱), not a game number.

const FOLDER := "res://assets/art/comfyui/"
const _DEFAULT_PATH := "res://data/cabinet/comfy_art.tres"

@export var tape_enabled: bool = true                    ## ✱ the generated masking tape over the coin slit (off = the code-drawn hazard tape)
@export var tape_file: String = "tape_3.png"             ## ✱ file name under assets/art/comfyui/
@export var backdrop_enabled: bool = true                ## ✱ the generated arcade photo under the room shading (off = the code-drawn arcade)
@export var backdrop_file: String = "backdrop_2.png"     ## ✱ file name under assets/art/comfyui/
@export_range(0.0, 2.0) var backdrop_exposure: float = 0.75   ## ✱ photo brightness before the room's own exposure/shadow/dim
@export_range(0.0, 1.0) var backdrop_sour: float = 0.6        ## ✱ how far the photo desaturates and cools toward the cursed turn (`dark` 1)


## Returns Resource on purpose (see CabinetSurface.default).
static func default() -> Resource:
	return load(_DEFAULT_PATH)


## The texture in `file` under the folder, or null when it is missing (the caller then falls back to the code art).
static func texture(file: String) -> Texture2D:
	var path := FOLDER + file
	return load(path) as Texture2D if ResourceLoader.exists(path) else null
