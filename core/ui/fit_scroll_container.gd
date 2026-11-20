class_name FitScrollContainer
extends ScrollContainer
## Vertical scroller that is exactly as tall as its content until the content would leave the
## safe area, then scrolls (follows focus, so controller users never lose the cursor).
## Used by every overlay panel so 200 % text never pushes controls off screen (SYS-001 §9).

## Logical pixels kept free above and below the panel (✱ engineering value).
@export var safe_margin: float = 16.0
## Extra vertical space taken by the parent panel's own margins/borders.
@export var chrome: float = 14.0
## Fixed controls outside this container's own VBox (e.g. a title above a tab rail) whose height is
## also kept on screen: their minimum height plus their parent box's separation comes off the limit.
@export var also_reserve: Array[Control] = []
## In a VBoxContainer the siblings (a fixed header such as the panel title) are kept on screen and
## their height is taken off the limit, so 200 % text scrolls the rows, never the title (Q-T244).


func _ready() -> void:
	follow_focus = true
	horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	get_viewport().size_changed.connect(refit)
	for c in get_children():
		if c is Control:
			(c as Control).minimum_size_changed.connect(refit)
	for s in _header_siblings():
		s.minimum_size_changed.connect(refit)
	for r in also_reserve:
		if r != null:
			r.minimum_size_changed.connect(refit)
	refit.call_deferred()


## Visible Control siblings when the parent is a VBoxContainer (fixed headers above or below).
func _header_siblings() -> Array[Control]:
	var out: Array[Control] = []
	var box := get_parent() as VBoxContainer
	if box == null:
		return out
	for c in box.get_children():
		if c != self and c is Control and (c as Control).visible:
			out.append(c as Control)
	return out


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
	var header := 0.0
	var box := get_parent() as VBoxContainer
	for s in _header_siblings():
		header += s.get_combined_minimum_size().y + float(box.get_theme_constant(&"separation"))
	for r in also_reserve:
		if r != null and r.visible:
			var rb := r.get_parent() as BoxContainer
			header += r.get_combined_minimum_size().y + (float(rb.get_theme_constant(&"separation")) if rb else 0.0)
	var limit := get_viewport_rect().size.y - safe_margin * 2.0 - chrome - header
	custom_minimum_size = Vector2(width, minf(content, limit))
