class_name BezelField
extends Control
## The printed sheet round the screen hole (PR C pass 2: one sheet with the two columns), reverse-printed on glass. Navy print
## ink over the whole window in rig units (ScreenFit.bezel_rect, so no bars at any aspect) except the
## hole itself, with the key-black tube-mask edge hugging the hole above and below; the two columns
## (BezelPrint) sit on top of it, flush against the hole's sides. It is drawn as four rectangles
## around the hole, so nothing it paints can ever touch the screen. Redrawn only when the window
## changes or the costume peels.

@export var rig: ScreenRig           ## tells the field the window rect (bezel_rect)
@export var inks: BezelInks

## 0 → 1: the field slides away with the costume (the columns slide sideways, the bands up and down).
var peel := 0.0:
	set(v):
		peel = v
		visible = peel < 1.0
		queue_redraw()

var _area := Rect2()          ## the whole window in rig units; set by the rig


func _ready() -> void:
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	show_behind_parent = true
	if inks == null:
		inks = BezelInks.default() as BezelInks
	material = CabinetLighting.print_material(CabinetSurface.default() as CabinetSurface, Vector2.ZERO, true)
	if rig != null:
		rig.refitted.connect(set_area)
		set_area(rig.bezel_rect())


## The bezel's drawable area in rig units (ScreenRig.bezel_rect()).
func set_area(r: Rect2) -> void:
	_area = r
	queue_redraw()


## The four print rectangles (before peel): top band, bottom band, left of the left column, right of
## the right column. Together with the hole and the two columns they tile the whole area.
func bands() -> Array[Rect2]:
	return bands_for(_area)


## The four bands of any window rect `area` (rig units).
static func bands_for(area: Rect2) -> Array[Rect2]:
	var h := CabinetBezel.hole()
	var a := area
	if a.size == Vector2.ZERO:
		a = Rect2(Vector2.ZERO, Vector2(ScreenFit.REF))
	var out: Array[Rect2] = []
	out.append(Rect2(a.position.x, a.position.y, a.size.x, h.position.y - a.position.y))
	out.append(Rect2(a.position.x, h.end.y, a.size.x, a.end.y - h.end.y))
	out.append(Rect2(a.position.x, h.position.y, CabinetBezel.left_x() - a.position.x, h.size.y))
	out.append(Rect2(CabinetBezel.right_x() + CabinetBezel.SIDE, h.position.y, a.end.x - CabinetBezel.right_x() - CabinetBezel.SIDE, h.size.y))
	return out


## The key-black edge strips just outside the hole (top, bottom).
func edges() -> Array[Rect2]:
	var h := CabinetBezel.hole()
	return [Rect2(h.position.x, h.position.y - CabinetBezel.EDGE, h.size.x, CabinetBezel.EDGE),
		Rect2(h.position.x, h.end.y, h.size.x, CabinetBezel.EDGE)]


## Every rectangle this field paints, after the peel shift.
func painted() -> Array[Rect2]:
	var out: Array[Rect2] = []
	var b := bands()
	var travel := CabinetBezel.SIDE + 20.0
	out.append(_shift(b[0], Vector2(0.0, -peel * (b[0].size.y + 20.0))))
	out.append(_shift(b[1], Vector2(0.0, peel * (b[1].size.y + 20.0))))
	out.append(_shift(b[2], Vector2(-peel * travel, 0.0)))
	out.append(_shift(b[3], Vector2(peel * travel, 0.0)))
	var e := edges()
	out.append(_shift(e[0], Vector2(0.0, -peel * (b[0].size.y + 20.0))))
	out.append(_shift(e[1], Vector2(0.0, peel * (b[1].size.y + 20.0))))
	return out


## Every rectangle the glass covers at `peel`: the four bands and the two columns, all shifted with the
## costume. Together with the hole they tile `area`; none ever touches the hole.
static func glass_rects(area: Rect2, peel: float) -> Array[Rect2]:
	var h := CabinetBezel.hole()
	var b := bands_for(area)
	var travel := CabinetBezel.SIDE + 20.0
	var out: Array[Rect2] = []
	out.append(_shift(b[0], Vector2(0.0, -peel * (b[0].size.y + 20.0))))
	out.append(_shift(b[1], Vector2(0.0, peel * (b[1].size.y + 20.0))))
	out.append(_shift(b[2], Vector2(-peel * travel, 0.0)))
	out.append(_shift(b[3], Vector2(peel * travel, 0.0)))
	out.append(Rect2(CabinetBezel.left_x() - peel * travel, h.position.y, CabinetBezel.SIDE, h.size.y))
	out.append(Rect2(CabinetBezel.right_x() + peel * travel, h.position.y, CabinetBezel.SIDE, h.size.y))
	return out


static func _shift(r: Rect2, d: Vector2) -> Rect2:
	return Rect2(r.position + d, r.size)


func _draw() -> void:
	# the sheet: the top and bottom bands within the sheet's width (the sides beyond it are the room,
	# CabinetRoom, dark), then the key-black tube-mask edges
	var rs := painted()
	var sx := CabinetBezel.sheet_x()
	for i in 2:
		var r := rs[i]
		var x0 := maxf(r.position.x, sx.x)
		var x1 := minf(r.end.x, sx.y)
		if x1 > x0:
			draw_rect(Rect2(x0, r.position.y, x1 - x0, r.size.y), inks.ink(&"navy"))
	for i in range(4, 6):
		draw_rect(rs[i], inks.ink(&"key_black"))
