class_name PanelCaption
extends RefCounted
## The plain-language caption beside a control-panel control (pass 2c): a small dark plate with a lit rim and
## cream VectorText, drawn on the bezel next to the control while it has keyboard / pad focus or the mouse is
## over it ("Settings" by SERVICE, "Quit game" by POWER), so nobody has to guess what a period-true decal does.
## It scales with the player's text size (1 to 2 times), always sits on the panel strip or the sheet (never over
## the screen), and is drawn through the host's own CanvasItem. Sizes are ✱ presentation data (CabinetSurface).

const FADE_SECONDS := 0.12


static func _surface() -> CabinetSurface:
	return CabinetSurface.default() as CabinetSurface


## The player's text size, clamped to the 1 to 2 range the settings offer.
static func text_scale() -> float:
	return clampf(float(SettingsService.get_value(&"text_scale")), 1.0, 2.0)


## The lettering's painted size.
static func text_size(text: String) -> Vector2:
	var s := _surface()
	var k := text_scale()
	return BezelText.ink_size(text, s.caption_cap * k, s.caption_stroke * k, s.caption_tracking * k)


## The plate's size: the lettering plus the margin.
static func plate_size(text: String) -> Vector2:
	return text_size(text) + _surface().caption_pad * 2.0 * text_scale()


## The plate's rect when its left-centre (or right-centre, `right_aligned`) is at `anchor`.
static func rect(text: String, anchor: Vector2, right_aligned: bool) -> Rect2:
	var sz := plate_size(text)
	return Rect2(Vector2(anchor.x - (sz.x if right_aligned else 0.0), anchor.y - sz.y * 0.5), sz)


## Draws the caption at strength `k` (0 hidden .. 1 shown) and returns the plate's rect (host-local).
static func draw(ci: CanvasItem, cache: Dictionary, text: String, anchor: Vector2, right_aligned: bool, k: float) -> Rect2:
	var r := rect(text, anchor, right_aligned)
	if k <= 0.0 or text == "":
		return r
	var s := _surface()
	var inks := BezelInks.default() as BezelInks
	var sc := text_scale()
	var plate := cache.get(&"plate") as StyleBoxFlat
	if plate == null:
		plate = StyleBoxFlat.new()
		plate.set_corner_radius_all(2)
		plate.set_border_width_all(1)
		plate.anti_aliasing = true
		cache[&"plate"] = plate
	plate.bg_color = Color(0.02, 0.02, 0.03, 0.9 * k)
	plate.border_color = Color(inks.yellow.lightened(0.2), k)
	ci.draw_style_box(plate, r)
	var cap := s.caption_cap * sc
	var stroke := s.caption_stroke * sc
	var top := r.position.y + s.caption_pad.y * sc + stroke * 0.5
	BezelText.draw(ci, cache, text, Vector2(r.position.x + s.caption_pad.x * sc + stroke * 0.5, top), false, cap, stroke, s.caption_tracking * sc,
		Color(inks.cream.lightened(0.35), k))
	return r
