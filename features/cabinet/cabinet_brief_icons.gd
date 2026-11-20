class_name CabinetBriefIcons
extends RefCounted
## The unit icons on the Act 0 stage card (UI-001 §11): the geode, Grub, Acolyte and Sepulchre drawn small, in the
## same line-art and `Pal` registers as their sim layers (GeodeField, GrubFlock, AcolyteSquad, SepulchreRitual).
## They are faithful mini copies, not calls into the layers: the layers draw through the live world's camera.
## Sizes come from CabinetTuning (SYS-001 §1.7), so the card never disagrees with the field.

const GEODE := &"geode"
const GRUB := &"grub"
const ACOLYTE := &"acolyte"
const SEPULCHRE := &"sepulchre"

const SEPULCHRE_ICON_RADIUS := 8.0    ## px ✱ the Sepulchre is drawn as a small disc: its real body is 60 px, far too big for a card row


## Draw the icon for `kind` centred on `c` (canvas pixels). Unknown kinds draw nothing.
static func draw(ci: CanvasItem, kind: StringName, c: Vector2, t: CabinetTuning) -> void:
	c = c.round()
	match kind:
		GEODE:
			_geode(ci, c, t.size_geode_radii[0])
		GRUB:
			_grub(ci, c, t.size_grub_px)
		ACOLYTE:
			_acolyte(ci, c, t.size_acolyte_px)
		SEPULCHRE:
			_sepulchre(ci, c)


## The longest drawn extent of an icon (px): a row is tall enough for it.
static func extent(kind: StringName, t: CabinetTuning) -> float:
	match kind:
		GEODE:
			return t.size_geode_radii[0] * 2.0
		GRUB:
			return t.size_grub_px
		ACOLYTE:
			return t.size_acolyte_px
		SEPULCHRE:
			return SEPULCHRE_ICON_RADIUS * 2.0
	return 0.0


static func _geode(ci: CanvasItem, c: Vector2, radius: float) -> void:
	var pts := PackedVector2Array()
	for k in 8:
		var r := radius * (0.86 if k % 2 == 0 else 1.0)    # a fixed jaggedness: no RNG on a card
		pts.append((c + Vector2.from_angle(TAU * k / 8.0) * r).round())
	Pal.glow_polyline(ci, pts, Look.c(Pal.BONE_3), Look.c(Pal.BONE_0))
	for g in [Vector2(-2, -1), Vector2(2, 2)]:
		var q: Vector2 = (c + g).round()
		ci.draw_rect(Rect2(q - Vector2(1, 1), Vector2(2, 2)), Look.c(Pal.PHOS_3))
		ci.draw_rect(Rect2(q, Vector2.ONE), Look.c(Pal.PHOS_4))


static func _grub(ci: CanvasItem, c: Vector2, size: float) -> void:
	var heading := Vector2.RIGHT
	var side := Vector2.DOWN
	var body := Look.c(Pal.CHOIR_3)
	var r0 := size * 0.22
	var r_last := size * 0.1
	var span := size - r0 - r_last
	for k in 4:
		var rk := lerpf(r0, r_last, k / 3.0)
		var q := c + heading * (size * 0.5 - r0) - heading * (span * k / 3.0)
		ci.draw_arc(q.round(), rk, 0.0, TAU, 10, body, 1.0)
		if k == 1 or k == 2:
			ci.draw_line((q + side * rk).round(), (q + side * (rk + 1.5)).round(), Look.c(Pal.CHOIR_2))
			ci.draw_line((q - side * rk).round(), (q - side * (rk + 1.5)).round(), Look.c(Pal.CHOIR_2))
	var head := c + heading * (size * 0.5 - r0)
	ci.draw_rect(Rect2((head + heading * 2.0).round(), Vector2.ONE), Look.c(Pal.CHOIR_5))
	ci.draw_line(head.round(), (head - heading * span).round(), Look.c(Pal.CHOIR_1))


static func _acolyte(ci: CanvasItem, c: Vector2, size: float) -> void:
	var u := size / 15.0
	var spike := PackedVector2Array([c + Vector2(0, -7) * u, c + Vector2(5, 7) * u, c + Vector2(-5, 7) * u])
	Pal.glow_polyline(ci, spike, Look.c(Pal.CHOIR_3), Look.c(Pal.CHOIR_1))
	ci.draw_line((c + Vector2(0, -3) * u).round(), (c + Vector2(0, 7) * u).round(), Look.c(Pal.CHOIR_2))
	ci.draw_line((c + Vector2(-3, 4) * u).round(), (c + Vector2(3, 4) * u).round(), Look.c(Pal.CHOIR_2))
	ci.draw_rect(Rect2((c + Vector2(-1, -4) * u).round(), Vector2(2, 2)), Look.c(Pal.BONE_4))
	var arm := (c + Vector2.RIGHT * size * 0.37).round()
	ci.draw_line(c, arm, Look.c(Pal.CHOIR_2))
	ci.draw_circle(arm, size * 0.13, Look.c(Pal.CHOIR_4))


static func _sepulchre(ci: CanvasItem, c: Vector2) -> void:
	ci.draw_circle(c, SEPULCHRE_ICON_RADIUS, SepulchreRitual.TRUE_FRAME_FILL)
	ci.draw_arc(c, SEPULCHRE_ICON_RADIUS, 0.0, TAU, 16, SepulchreRitual.TRUE_FRAME_LINE, 1.0)
	ci.draw_arc(c, SEPULCHRE_ICON_RADIUS * 0.5, 0.0, TAU, 12, Look.c(Pal.BONE_1), 1.0)
