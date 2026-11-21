class_name BezelTexture
extends TextureRect
## The ComfyUI-generated bezel (BezelArtMode, ART-001 §14.9): a 640×360 rig-unit image laid over the printed
## sheet, transparent outside the sheet and exactly transparent over the screen hole (tools/comfyui/make_bezel.py
## fits it to CabinetBezel.hole()). Only built when `BezelArtMode.generated_active()`. It carries no lettering.

func _ready() -> void:
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	var m := BezelArtMode.default() as BezelArtMode
	texture = load(BezelArtMode.FOLDER + m.texture) as Texture2D
	expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	stretch_mode = TextureRect.STRETCH_SCALE
	texture_filter = CanvasItem.TEXTURE_FILTER_LINEAR_WITH_MIPMAPS
	position = Vector2.ZERO
	size = Vector2(ScreenFit.REF)
