class_name MenuSkin
extends RefCounted
## The two costumes of the overlay menus (Settings, Pause, Confirm; UI-001 §10, TECH-001 §2.9b).
## CABINET (Act 0, Look.t < 0.5): the cabinet's operator service mode, a period test-mode screen:
##   neon on black, upper-case stroke text, ruled lines, a tube-shaped frame with registration marks,
##   a convergence crosshatch and a colour-bar strip, a block cursor on the focused row.
## BRASS (the Aether): the sector HUD's Victorian instrument plates (Brass, ART-001 §16.6h): riveted
##   bevelled brass around a smoked-glass face, engraved double rules, glass lamps for toggles.
## Role laws hold in both: focus = GAS, an honest ON state = phosphor, never SIGNAL (ART-001 §4, R-09).
## Runtime vector only, Pal colours only, cabinet colours through Look.c (D-13, ART-001 §15).
## Static helpers; geometry and text sizes are engineering values ✱, not tunables.

enum Kind { CABINET, BRASS }
enum Role { TITLE, ROW, HINT, VALUE, SMALL }

## ✱ Cap heights (logical px) at 100 % text; Large Text doubles them like the Theme (UiTheme).
const SIZES := {Role.TITLE: 13.0, Role.ROW: 7.0, Role.HINT: 6.0, Role.VALUE: 7.0, Role.SMALL: 5.0}
const STROKES := {Role.TITLE: 1.6, Role.ROW: 1.15, Role.HINT: 1.0, Role.VALUE: 1.15, Role.SMALL: 0.9}
const TRACKING := {Role.TITLE: 1.6, Role.ROW: 0.5, Role.HINT: 0.3, Role.VALUE: 0.6, Role.SMALL: 0.6}
## ✱ Row padding (logical px).
const ROW_PAD := Vector2(10.0, 4.0)
## ✱ Cursor blink half-period (s); steady under reduced motion or photosensitivity.
const BLINK_S := 0.45
## ✱ Crosshatch pitch of the cabinet test card (logical px).
const GRID := 16.0

## Tests force a costume (-1 = follow Look.t).
static var forced := -1


## The costume for where the menu opens: the neon cabinet until THE PRETENCE, brass after it.
static func current() -> Kind:
	if forced >= 0:
		return forced as Kind
	return Kind.BRASS if Look.t >= 0.5 else Kind.CABINET


## The costume for node `n`: the ScreenStack it sits on may name one (the sector and the Ruins say BRASS,
## TECH-001 §2.9b); otherwise the fidelity ladder decides (current()).
static func for_node(n: Node) -> Kind:
	if forced >= 0:
		return forced as Kind
	var p := n
	while p != null:
		if p is ScreenStack and (p as ScreenStack).costume > 0:
			return ((p as ScreenStack).costume - 1) as Kind
		p = p.get_parent()
	return current()


static func text_scale() -> float:
	return clampf(float(SettingsService.get_value(&"text_scale")), 1.0, 2.0)


## No blinking or moving decoration (reduced motion or photosensitivity; GDD §10).
static func still() -> bool:
	return bool(SettingsService.get_value(&"photosensitivity")) or bool(SettingsService.get_value(&"reduced_motion"))


static func face(role: Role, scale: float = -1.0) -> VectorFace:
	var s := text_scale() if scale <= 0.0 else scale
	var f := VectorFace.new()
	f.size = float(SIZES[role]) * s
	f.stroke_width = float(STROKES[role]) * (1.0 + (s - 1.0) * 0.6)
	f.tracking = float(TRACKING[role]) * s
	return f


## Cabinet text is upper case (the cabinet face has none, ART-001 §11).
static func shown(s: String, kind: Kind) -> String:
	return s.to_upper() if kind == Kind.CABINET else s


# ---------------------------------------------------------------- colours

static func c(kind: Kind, base: Color) -> Color:
	return Look.c(base) if kind == Kind.CABINET else base


static func ink(kind: Kind, role: Role) -> Color:
	match role:
		Role.TITLE:
			return c(kind, Pal.GAS_4) if kind == Kind.CABINET else Pal.GAS_5
		Role.HINT, Role.SMALL:
			return c(kind, Pal.BONE_3) if kind == Kind.CABINET else Pal.BONE_3
		_:
			return c(kind, Pal.BONE_4) if kind == Kind.CABINET else Pal.BONE_5


static func focus_ink(kind: Kind) -> Color:
	return c(kind, Pal.GAS_4)


static func on_ink(kind: Kind) -> Color:
	return c(kind, Pal.PHOS_4)


static func off_ink(kind: Kind) -> Color:
	return c(kind, Pal.BONE_2)


static func disabled_ink(kind: Kind) -> Color:
	return c(kind, Pal.BONE_1)


# ---------------------------------------------------------------- frame

## The panel behind a whole menu.
static func frame(ci: CanvasItem, r: Rect2, kind: Kind) -> void:
	if kind == Kind.BRASS:
		_brass_frame(ci, r)
	else:
		_cabinet_frame(ci, r)


static func _cabinet_frame(ci: CanvasItem, r: Rect2) -> void:
	var bg := c(Kind.CABINET, Pal.VOID_0)
	ci.draw_rect(r, Color(bg, 0.96), true)
	# the test card's convergence crosshatch, faint, inside the tube
	var tube := r.grow(-6.0)
	var hatch := Color(c(Kind.CABINET, Pal.VOID_3), 0.45)
	var x := tube.position.x + fmod(tube.size.x * 0.5, GRID)
	while x < tube.end.x:
		ci.draw_line(Vector2(x, tube.position.y + 4.0), Vector2(x, tube.end.y - 4.0), hatch, 1.0)
		x += GRID
	var y := tube.position.y + fmod(tube.size.y * 0.5, GRID)
	while y < tube.end.y:
		ci.draw_line(Vector2(tube.position.x + 4.0, y), Vector2(tube.end.x - 4.0, y), hatch, 1.0)
		y += GRID
	# scan lines (static)
	var scan := Color(c(Kind.CABINET, Pal.VOID_0), 0.35)
	y = tube.position.y + 1.0
	while y < tube.end.y:
		ci.draw_line(Vector2(tube.position.x, y), Vector2(tube.end.x, y), scan, 1.0)
		y += 3.0
	# the tube's rounded edge and the cabinet's moulded frame around it
	_round_rect(ci, r.grow(-1.0), 9.0, c(Kind.CABINET, Pal.BONE_1), 2.0)
	_round_rect(ci, tube, 7.0, c(Kind.CABINET, Pal.VOID_4), 1.0)
	_round_rect(ci, tube.grow(-2.0), 6.0, Color(c(Kind.CABINET, Pal.VOID_5), 0.35), 1.0)
	# registration crosses in the corners of the test card
	var mark := c(Kind.CABINET, Pal.BONE_2)
	for p: Vector2 in [tube.position + Vector2(9, 9), Vector2(tube.end.x - 9, tube.position.y + 9),
			Vector2(tube.position.x + 9, tube.end.y - 9), tube.end - Vector2(9, 9)]:
		ci.draw_line(p - Vector2(3, 0), p + Vector2(3, 0), mark, 1.0)
		ci.draw_line(p - Vector2(0, 3), p + Vector2(0, 3), mark, 1.0)
		ci.draw_arc(p, 2.0, 0.0, TAU, 12, mark, 1.0)


static func _brass_frame(ci: CanvasItem, r: Rect2) -> void:
	# the smoky Aether shows through the edges; the plate is an instrument case
	Brass.plate(ci, r, Pal.VOID_1)
	var face := r.grow(-Brass.RIVET_INSET - 2.0)
	# engraved inner line and corner filigree
	ci.draw_rect(face.grow(-3.0), Color(Pal.GAS_2, 0.55), false, 1.0)
	for i in 4:
		var corner: Vector2 = [face.position, Vector2(face.end.x, face.position.y), face.end, Vector2(face.position.x, face.end.y)][i]
		var a0 := float(i) * PI * 0.5
		ci.draw_arc(corner, 9.0, a0, a0 + PI * 0.5, 10, Color(Pal.GAS_3, 0.8), 1.0)
		ci.draw_arc(corner, 6.0, a0, a0 + PI * 0.5, 8, Color(Pal.GAS_2, 0.7), 1.0)
	# rivets along the long edges
	var step := 48.0
	var x := r.position.x + step
	while x < r.end.x - step * 0.5:
		Brass.rivet(ci, Vector2(x, r.position.y + Brass.RIVET_INSET))
		Brass.rivet(ci, Vector2(x, r.end.y - Brass.RIVET_INSET))
		x += step
	# faint glass sheen across the face
	ci.draw_line(face.position + Vector2(14, 4), Vector2(face.position.x + face.size.x * 0.45, face.position.y + 4),
		Color(Pal.BONE_5, 0.06), 2.0)


# ---------------------------------------------------------------- rules

## A horizontal rule across `w` at `y`. `heavy` = the header rule: the colour-bar strip on the
## cabinet, a double engraved brass line in the Aether.
static func rule(ci: CanvasItem, from: Vector2, w: float, kind: Kind, heavy: bool) -> void:
	if kind == Kind.BRASS:
		ci.draw_line(from, from + Vector2(w, 0), Pal.GAS_0, 1.0)
		ci.draw_line(from + Vector2(0, 1), from + Vector2(w, 1), Pal.GAS_3, 1.0)
		if heavy:
			ci.draw_line(from + Vector2(0, 3), from + Vector2(w, 3), Pal.GAS_2, 1.0)
			var mid := from + Vector2(w * 0.5, 1.5)
			ci.draw_colored_polygon(PackedVector2Array([mid + Vector2(-5, 0), mid + Vector2(0, -2.5),
				mid + Vector2(5, 0), mid + Vector2(0, 2.5)]), Pal.GAS_4)
		return
	if heavy:
		# the 16-register colour bars of a period test screen (no SIGNAL: ART-001 SIGNAL budget)
		var bars: Array[Color] = [Pal.BONE_5, Pal.GAS_4, Pal.PHOS_4, Pal.GAS_3, Pal.CHOIR_4, Pal.VOID_5,
			Pal.PHOS_2, Pal.GAS_2, Pal.CHOIR_3, Pal.VOID_4, Pal.BONE_3, Pal.PHOS_3, Pal.CHOIR_2, Pal.BONE_1,
			Pal.VOID_2, Pal.VOID_0]
		var bw := w / float(bars.size())
		for i in bars.size():
			ci.draw_rect(Rect2(from + Vector2(bw * i, -1.0), Vector2(ceilf(bw), 3.0)), c(Kind.CABINET, bars[i]), true)
		return
	var dash := c(Kind.CABINET, Pal.VOID_4)
	var x := 0.0
	while x < w:
		ci.draw_line(from + Vector2(x, 0), from + Vector2(minf(x + 4.0, w), 0), dash, 1.0)
		x += 6.0


# ---------------------------------------------------------------- rows

enum State { NORMAL, HOVER, FOCUS, PRESSED, DISABLED }


## Behind a row. `cursor_on` = the cabinet's blinking block cursor is in its lit half.
static func row_back(ci: CanvasItem, r: Rect2, kind: Kind, state: State, tab_active: bool, cursor_on: bool) -> void:
	if kind == Kind.BRASS:
		if tab_active:
			Brass.plate(ci, r, Pal.GAS_1)
		elif state == State.FOCUS or state == State.PRESSED:
			ci.draw_rect(r.grow(-1.0), Color(Pal.GAS_1, 0.55), true)
		elif state == State.HOVER:
			ci.draw_rect(r.grow(-1.0), Color(Pal.GAS_0, 0.6), true)
		if state == State.FOCUS or state == State.PRESSED:
			ci.draw_rect(r.grow(-0.5), Pal.GAS_4, false, 1.5)
			Brass.rivet(ci, Vector2(r.position.x + 4.0, r.get_center().y))
			Brass.rivet(ci, Vector2(r.end.x - 4.0, r.get_center().y))
		return
	if tab_active:
		ci.draw_rect(r.grow(-1.0), c(kind, Pal.VOID_3), true)
		ci.draw_rect(Rect2(r.position + Vector2(1, 1), Vector2(3.0, r.size.y - 2.0)), c(kind, Pal.GAS_3), true)
	if state == State.HOVER:
		ci.draw_rect(r.grow(-1.0), Color(c(kind, Pal.VOID_2), 0.8), true)
	if state == State.FOCUS or state == State.PRESSED:
		ci.draw_rect(r.grow(-1.0), Color(c(kind, Pal.VOID_2), 0.9), true)
		ci.draw_rect(r.grow(-0.5), c(kind, Pal.GAS_3), false, 2.0)
		if cursor_on:
			# the service-menu cursor: a solid block arrow at the row's left
			var y := r.get_center().y
			var h := clampf(r.size.y * 0.28, 3.0, 8.0)
			ci.draw_colored_polygon(PackedVector2Array([Vector2(r.position.x + 3.0, y - h),
				Vector2(r.position.x + 3.0 + h, y), Vector2(r.position.x + 3.0, y + h)]), c(kind, Pal.GAS_4))


## The ON/OFF indicator in front of a toggle's value: a glass lamp (brass) or an LED block (cabinet).
static func indicator(ci: CanvasItem, center: Vector2, radius: float, kind: Kind, on: bool) -> void:
	if kind == Kind.BRASS:
		Brass.lamp(ci, center, radius, on)
		return
	var r := Rect2(center - Vector2(radius, radius), Vector2(radius, radius) * 2.0)
	ci.draw_rect(r, c(kind, Pal.PHOS_3) if on else c(kind, Pal.VOID_2), true)
	ci.draw_rect(r, c(kind, Pal.BONE_1), false, 1.0)


static func _round_rect(ci: CanvasItem, r: Rect2, rad: float, col: Color, width: float) -> void:
	var k := minf(rad, minf(r.size.x, r.size.y) * 0.5)
	var pts := PackedVector2Array()
	var corners := [Vector2(r.end.x - k, r.position.y + k), Vector2(r.end.x - k, r.end.y - k),
		Vector2(r.position.x + k, r.end.y - k), Vector2(r.position.x + k, r.position.y + k)]
	for i in 4:
		var a0 := -PI * 0.5 + float(i) * PI * 0.5
		for s in 7:
			var a := a0 + PI * 0.5 * float(s) / 6.0
			pts.append((corners[i] as Vector2) + Vector2(cos(a), sin(a)) * k)
	pts.append(pts[0])
	ci.draw_polyline(pts, col, width, true)
