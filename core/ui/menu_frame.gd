class_name MenuFrame
extends PanelContainer
## The panel of an overlay menu, drawn in its costume (MenuSkin.frame): the cabinet's service-mode
## test card in Act 0, a brass instrument case in the Aether. Replaces the theme's slate panel.

## ✱ Content margins (logical px) inside the drawn frame.
const MARGIN := Vector2(18.0, 14.0)

var kind: MenuSkin.Kind = MenuSkin.Kind.CABINET


func _ready() -> void:
	kind = MenuSkin.for_node(self)
	var box := StyleBoxEmpty.new()
	box.content_margin_left = MARGIN.x
	box.content_margin_right = MARGIN.x
	box.content_margin_top = MARGIN.y
	box.content_margin_bottom = MARGIN.y
	add_theme_stylebox_override(&"panel", box)
	resized.connect(queue_redraw)


func _draw() -> void:
	MenuSkin.frame(self, Rect2(Vector2.ZERO, size), kind)
