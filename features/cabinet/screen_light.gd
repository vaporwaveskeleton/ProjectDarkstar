class_name ScreenLight
extends Node
## The screen lights the cabinet (PR C pass 2). Every `spill_interval` seconds it takes the AVERAGE colour of
## what the tube shows, from a strided read of a small image (never the whole texture), turns it into a
## light (rgb = the colour at full strength, a = intensity from its luminance) and eases the cabinet's one
## live light toward it (`spill_smooth`), so the bezel, the glass, the sticker and the coin door all
## breathe with the picture. It only READS: it never writes into the screen or any viewport.
## Source: `source` is the arcade screen's own SubViewport (256 × 304 texels, cheap): the game and the attract screen alike.
## The read is a GPU read-back of that small texture, so it runs at the slow `spill_interval`, and not at all headless
## or with no source. With `photosensitivity` on the light is held at a fixed steady value (no change at all).

const STRIDE := 6            ## sample every STRIDE-th texel each way

@export var surface: CabinetSurface
var source: SubViewport = null     ## the arcade screen's SubViewport; null: no sampling (the light stays steady)

var light := Color(0, 0, 0, 0)     ## the current (eased) live light: rgb colour, a intensity
var _target := Color(0, 0, 0, 0)
var _t := 0.0
var samples := 0                   ## how many reads have been taken (tests, profiling)


func _ready() -> void:
	if surface == null:
		surface = CabinetSurface.default() as CabinetSurface
	_target = steady(surface)
	light = _target
	CabinetLighting.set_screen_light(light)


func _process(delta: float) -> void:
	if bool(SettingsService.get_value(&"photosensitivity")):
		light = steady(surface)
		_target = light
		CabinetLighting.set_screen_light(light)
		return
	_t += delta
	if _t >= surface.spill_interval:
		_t = 0.0
		_sample()
	var k := 1.0 - exp(-delta / maxf(surface.spill_smooth, 0.001))
	light = light.lerp(_target, k)
	CabinetLighting.set_screen_light(light)


## The fixed light used with photosensitivity on.
static func steady(s: CabinetSurface) -> Color:
	return Color(s.spill_steady_color.r, s.spill_steady_color.g, s.spill_steady_color.b, s.spill_steady_amount)


## The average colour of `img` over `region` (whole image when empty), reading every `stride`-th texel.
## Pure: the image is never modified.
static func average(img: Image, region: Rect2i = Rect2i(), stride: int = STRIDE) -> Color:
	if img == null or img.is_empty():
		return Color(0, 0, 0, 1)
	var r := region if region.size != Vector2i.ZERO else Rect2i(Vector2i.ZERO, img.get_size())
	r = r.intersection(Rect2i(Vector2i.ZERO, img.get_size()))
	var sum := Vector3.ZERO
	var n := 0
	var y := r.position.y
	while y < r.end.y:
		var x := r.position.x
		while x < r.end.x:
			var c := img.get_pixel(x, y)
			sum += Vector3(c.r, c.g, c.b)
			n += 1
			x += stride
		y += stride
	if n == 0:
		return Color(0, 0, 0, 1)
	sum /= float(n)
	return Color(sum.x, sum.y, sum.z, 1.0)


## An average colour as a light: rgb is the colour stretched to full strength, a the intensity from its
## luminance times the surface's boost (clamped 0..1).
static func to_light(avg: Color, s: CabinetSurface) -> Color:
	var mx := maxf(avg.r, maxf(avg.g, avg.b))
	var lum := avg.r * 0.3 + avg.g * 0.59 + avg.b * 0.11
	if mx < 0.002:
		return Color(0.5, 0.6, 0.85, 0.0)
	return Color(avg.r / mx, avg.g / mx, avg.b / mx, clampf(pow(lum * s.spill_boost, s.spill_curve), 0.0, 1.0))


func _sample() -> void:
	if source == null or DisplayServer.get_name() == "headless":
		return
	var tex := source.get_texture()
	if tex == null:
		return
	var img := tex.get_image()
	if img == null or img.is_empty():
		return
	samples += 1
	_target = to_light(average(img), surface)
