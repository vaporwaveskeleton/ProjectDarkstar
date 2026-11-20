class_name ChalkButton
extends Button
## A post-Act 0 button whose caption is a VectorLabel (TECH-001 §2.9a), drawn in the UI-001 §5
## control states from Pal: idle VOID-1 fill + BONE-1 keyline, hover VOID-2 + BONE-3, focus a 2 px
## GAS-3 outline (the lamp cursor, R-09), pressed VOID-3 + a GAS-2 bottom keyline, disabled VOID-0 +
## BONE-0. The Button's own `text` stays empty; the caption is `key` (a tr() key).

## ✱ caption cap height and stroke at text scale 1 (logical px).
const CAPTION_SIZE := 6.0
const CAPTION_STROKE := 0.9
## ✱ inner padding around the caption (logical px).
const PAD := Vector2(10, 7)

var caption: VectorLabel


func _init() -> void:
	flat = true
	focus_mode = Control.FOCUS_ALL
	add_theme_stylebox_override(&"focus", StyleBoxEmpty.new())   # drawn in _draw (UI-001 §5)
	caption = VectorLabel.new()
	caption.name = "Caption"
	caption.mouse_filter = Control.MOUSE_FILTER_IGNORE
	caption.alignment = VectorText.Align.CENTER
	caption.color = Pal.BONE_5
	add_child(caption)


## Sets the caption key and the face for a text scale (1 or 2, SettingsService `text_scale`).
func setup(key: StringName, text_scale: float = 1.0) -> void:
	caption.key = key
	caption.face = VectorText.default_face().duplicate_with(CAPTION_SIZE * text_scale, CAPTION_STROKE * text_scale)
	var ink := caption.get_combined_minimum_size()
	custom_minimum_size = Vector2(maxf(ink.x + PAD.x * 2.0, 64.0), maxf(ink.y + PAD.y * 2.0, 22.0))
	size = custom_minimum_size
	_place_caption()


func _notification(what: int) -> void:
	match what:
		NOTIFICATION_RESIZED:
			_place_caption()
		NOTIFICATION_FOCUS_ENTER, NOTIFICATION_FOCUS_EXIT, NOTIFICATION_MOUSE_ENTER, NOTIFICATION_MOUSE_EXIT:
			queue_redraw()


func _place_caption() -> void:
	if caption == null:
		return
	var ink := caption.get_combined_minimum_size()
	caption.size = Vector2(size.x, ink.y)
	caption.position = Vector2(0, (size.y - ink.y) * 0.5)
	caption.color = Pal.BONE_1 if disabled else Pal.BONE_5


func _draw() -> void:
	var r := Rect2(Vector2.ZERO, size)
	var fill := Pal.VOID_1
	var line := Pal.BONE_1
	if disabled:
		fill = Pal.VOID_0
		line = Pal.BONE_0
	elif button_pressed or get_draw_mode() == DRAW_PRESSED:
		fill = Pal.VOID_3
	elif is_hovered():
		fill = Pal.VOID_2
		line = Pal.BONE_3
	draw_rect(r, fill)
	draw_rect(r, line, false, 1.0)
	if not disabled and get_draw_mode() == DRAW_PRESSED:
		draw_line(Vector2(1, size.y - 1), Vector2(size.x - 1, size.y - 1), Pal.GAS_2, 2.0)
	if has_focus():
		draw_rect(r.grow(2.0), Pal.GAS_3, false, 2.0)
