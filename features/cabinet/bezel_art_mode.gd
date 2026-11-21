class_name BezelArtMode
extends TunableResource
## The data switch between the code-built bezel and a ComfyUI-generated texture (owner ruling 2026-11-20,
## ART-001 §14.9, TECH-001 §2.10). `mode` CODE (default) draws the printed sheet in code exactly as before;
## GENERATED lays one image from `res://assets/art/comfyui/` (`texture`, a file name listed in that folder's
## manifest.json) over the sheet in 640×360 rig units, with the screen hole transparent. Compare in-game by
## editing data/cabinet/bezel_art_mode.tres (`mode = 1`, pick `texture`); the coin door, control panel, glass
## and tube still draw over it. Engineering presentation data (✱), not a game number.

enum Mode { CODE, GENERATED }
const FOLDER := "res://assets/art/comfyui/"
const _DEFAULT_PATH := "res://data/cabinet/bezel_art_mode.tres"

@export var mode: Mode = Mode.CODE             ## ✱ CODE = the code-built bezel (default); GENERATED = the texture below
@export var texture: String = "bezel_navy.png"  ## ✱ file name under assets/art/comfyui/ (bezel_navy, bezel_oxblood, bezel_black)


## Returns Resource on purpose (see CabinetSurface.default).
static func default() -> Resource:
	return load(_DEFAULT_PATH)


## True when the generated bezel is switched on and its file exists.
func generated_active() -> bool:
	return mode == Mode.GENERATED and ResourceLoader.exists(FOLDER + texture)
