class_name UiTheme
extends RefCounted
## Applies settings (text scale) to the project Theme. Font sizes are engineering values ✱
## until ART-001 defines the bitmap font (TECH-001 §11).

const THEME_PATH := "res://data/ui/darkstar_theme.tres"
const BASE_FONT_SIZE := 14     ## ✱
const BASE_HEADER_SIZE := 28   ## ✱


static func get_theme() -> Theme:
	var t := ThemeDB.get_project_theme()
	return t if t else load(THEME_PATH) as Theme


static func apply_text_scale(scale: float, theme: Theme = null) -> void:
	var t := theme if theme else get_theme()
	if t == null:
		return
	t.default_font_size = roundi(BASE_FONT_SIZE * scale)
	t.set_font_size(&"font_size", &"HeaderLabel", roundi(BASE_HEADER_SIZE * scale))
