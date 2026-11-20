class_name MenuRule
extends Control
## A ruled line between menu sections (MenuSkin.rule). Horizontal by default; `vertical` draws a
## column divider. `heavy` = the header rule (cabinet colour bars, brass double line).

@export var heavy := false
@export var vertical := false

var kind: MenuSkin.Kind = MenuSkin.Kind.CABINET


func _ready() -> void:
	kind = MenuSkin.for_node(self)
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	custom_minimum_size = Vector2(7.0, 0.0) if vertical else Vector2(0.0, 7.0 if heavy else 5.0)
	resized.connect(queue_redraw)


func _draw() -> void:
	if vertical:
		var x := size.x * 0.5
		if kind == MenuSkin.Kind.BRASS:
			draw_line(Vector2(x, 2), Vector2(x, size.y - 2), Pal.GAS_0, 1.0)
			draw_line(Vector2(x + 1, 2), Vector2(x + 1, size.y - 2), Pal.GAS_3, 1.0)
		else:
			var y := 2.0
			while y < size.y - 2.0:
				draw_line(Vector2(x, y), Vector2(x, minf(y + 4.0, size.y - 2.0)), MenuSkin.c(kind, Pal.VOID_4), 1.0)
				y += 6.0
		return
	MenuSkin.rule(self, Vector2(0.0, floorf(size.y * 0.5)), size.x, kind, heavy)
