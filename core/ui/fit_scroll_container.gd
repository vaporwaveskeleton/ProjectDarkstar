class_name FitScrollContainer
extends ScrollContainer
## Vertical scroller that is exactly as tall as its content until the content would leave the
## safe area, then scrolls (follows focus, so controller users never lose the cursor).
## Used by every overlay panel so 200 % text never pushes controls off screen (SYS-001 §9).

## Logical pixels kept free above and below the panel (✱ engineering value).
@export var safe_margin: float = 16.0
## Extra vertical space taken by the parent panel's own margins/borders.
@export var chrome: float = 14.0


func _ready() -> void:
	follow_focus = true
	horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	get_viewport().size_changed.connect(refit)
	for c in get_children():
		if c is Control:
			(c as Control).minimum_size_changed.connect(refit)
	refit.call_deferred()


func refit() -> void:
	if not is_inside_tree():
		return
	var content := 0.0
	var width := 0.0
	for c in get_children():
		if c is Control:
			var m := (c as Control).get_combined_minimum_size()
			content = maxf(content, m.y)
			width = maxf(width, m.x)
	var limit := get_viewport_rect().size.y - safe_margin * 2.0 - chrome
	custom_minimum_size = Vector2(width, minf(content, limit))
