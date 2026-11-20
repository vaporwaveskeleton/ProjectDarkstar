class_name RuinsObjects
extends Node2D
## The Ruins' objects as lamp-lit Victorian runtime vector art (TECH-001 Q-T193, ART-001 §16.6j):
## the Chalk Desk, the Cabinet (it pays out the tickets), the Codex desk, the Hourglass and the hangar
## gate. Drawn in RuinsLook's lit hall at the existing markers, so the hall lantern, the Tree lamps and
## the object lights fall on them; they draw no light of their own except the Cabinet's phosphor glass.
## No text (the chalk and the marquee words are the Ruins scene's), no gameplay, no collision. The
## Tree is not here: it lands with the Tree feature (Q-T193); RuinsPlaceholders keeps its stand-in.
## Never black (the only true black is the entity, ART-001 §16): the darkest fill is VOID_2.
## Motion is slow and never flickers: sand grains fall, the Cabinet's glass rolls one soft band, the
## Codex ribbon sways; reduced motion holds all of it still. Every number here is ✱.

## ✱ sand grains in the falling stream, and their fall speed (px/s).
const GRAINS := 5
const GRAIN_SPEED := 9.0
## ✱ the Cabinet glass's rolling band: seconds per pass and its strength (constant luminance overall).
const ROLL_S := 7.0
const ROLL_K := 0.12
## ✱ the Codex ribbon's sway: seconds per swing and its reach (px).
const SWAY_S := 6.0
const SWAY_PX := 1.2
## ✱ how far each folded gate leaf reaches in from its track (px) and its lattice cells.
const GATE_FOLD_PX := 12.0
const GATE_CELLS := 7
## ✱ smallest sand change that redraws the Hourglass (well under one pixel of pile).
const SAND_STEP := 0.002

var chalk_desk := Vector2(204, 300)
var cabinet := Vector2(74, 214)
var codex_desk := Vector2(300, 300)
var hourglass := Vector2(438, 300)
var mouth := Rect2(484, 116, 132, 186)
var floor_y := 300.0
var brass := Pal.BONE_2
var brass_hi := Pal.BONE_4
var brass_shadow := Pal.VOID_3
var wood := Pal.BONE_1
var wood_dark := Pal.BONE_0
var chalk := Pal.BONE_4
var slate := Pal.VOID_2
var paper := Pal.BONE_4
var paper_shade := Pal.BONE_3
var ink := Pal.VOID_3
var velvet := Pal.AETHER_1
var glass := Pal.PHOS_1
var glass_lit := Pal.PHOS_3
var glint := Pal.BONE_5
var sand_col := Pal.BONE_3
## The Hourglass's sand above the neck, 0…1 (the Ruins sets it from RunSession; 1 = full).
var sand := 1.0:
	set(v):
		var nv := clampf(v, 0.0, 1.0)
		if absf(nv - sand) < SAND_STEP and not (nv == 0.0 and sand != 0.0):
			return
		sand = nv
		_redraw_live()
## Sand is falling (the clock runs): grains stream through the neck.
var sand_falling := false:
	set(v):
		if v == sand_falling:
			return
		sand_falling = v
		_redraw_live()
var still := false
var _t := 0.0
## Perf (Q-T248, Ruins): the objects are drawn once on this node; only what moves (the Cabinet's
## rolling band, the Codex ribbon, the Hourglass sand and its glass) lives on this child and redraws.
var _live: Node2D


func _ready() -> void:
	_live = Node2D.new()
	_live.name = "Live"
	add_child(_live)
	_live.draw.connect(_draw_live)
	if SettingsService.DEFAULTS.has(&"reduced_motion"):
		still = bool(SettingsService.get_value(&"reduced_motion"))


func configure(data: RuinsLookData) -> void:
	brass = data.brass
	brass_hi = data.brass_hi
	brass_shadow = data.brass_shadow
	chalk = data.chalk
	queue_redraw()


func set_markers(p_chalk: Vector2, p_cabinet: Vector2, p_codex: Vector2, p_hourglass: Vector2, p_mouth: Rect2,
		p_floor_y: float) -> void:
	chalk_desk = p_chalk
	cabinet = p_cabinet
	codex_desk = p_codex
	hourglass = p_hourglass
	mouth = p_mouth
	floor_y = p_floor_y
	queue_redraw()


func set_time(t: float) -> void:
	if still:
		return
	_t = t
	_redraw_live()


func _redraw_live() -> void:
	if _live != null:
		_live.queue_redraw()


func _notification(what: int) -> void:
	if what == NOTIFICATION_DRAW:
		_redraw_live()


## Every colour this layer can draw with (tests: Pal roles only, never black, no GAS/CHOIR/SIGNAL).
func colours_used() -> Array[Color]:
	return [brass, brass_hi, brass_shadow, wood, wood_dark, chalk, slate, paper, paper_shade, ink, velvet,
		glass, glass_lit, glint, sand_col]


## The rect each object covers (RuinsLook-local logical px), for layout tests and focus mirrors.
func object_rects() -> Dictionary:
	return {
		&"chalk_desk": Rect2(chalk_desk + Vector2(-30, -46), Vector2(60, 46)),
		&"cabinet": Rect2(cabinet + Vector2(-18, -44), Vector2(36, 76)),
		&"codex_desk": Rect2(codex_desk + Vector2(-20, -40), Vector2(40, 40)),
		&"hourglass": Rect2(hourglass + Vector2(-12, -38), Vector2(24, 38)),
	}


func _draw() -> void:
	_draw_gate()
	_draw_cabinet()
	_draw_chalk_desk()
	_draw_codex_desk()
	_draw_hourglass()


func _draw_live() -> void:
	_draw_cabinet_live()
	_draw_codex_live()
	_draw_hourglass_live()


# --- the hangar gate: a folding brass lattice gate gathered back on its tracks, an arched header ------

func _draw_gate() -> void:
	var top := mouth.position.y + mouth.size.y * 0.35
	for side in [-1.0, 1.0]:
		var x0: float = mouth.position.x - 5.0 if side < 0.0 else mouth.end.x + 5.0
		var x1: float = x0 + side * GATE_FOLD_PX   # gathered outward, clear of the mouth
		# the folded leaf: X lattice between two stiles
		for x in [x0, x1]:
			draw_line(Vector2(x, top), Vector2(x, floor_y), brass_shadow, 2.4)
			draw_line(Vector2(x, top), Vector2(x, floor_y), brass, 1.0, true)
		var h := (floor_y - top) / float(GATE_CELLS)
		for k in GATE_CELLS:
			var y := top + h * float(k)
			draw_line(Vector2(x0, y), Vector2(x1, y + h), Color(brass, 0.85), 0.8, true)
			draw_line(Vector2(x1, y), Vector2(x0, y + h), Color(brass, 0.85), 0.8, true)
			draw_circle(Vector2((x0 + x1) * 0.5, y + h * 0.5), 0.9, brass_hi)
		# a finial spear on each stile
		for x in [x0, x1]:
			draw_colored_polygon(PackedVector2Array([Vector2(x - 1.6, top), Vector2(x, top - 5.0),
				Vector2(x + 1.6, top)]), brass)
	# the arched header over the mouth: a riveted brass band with a keystone
	var pts := PackedVector2Array()
	var c := Vector2(mouth.get_center().x, mouth.position.y + 10.0)
	var rx := mouth.size.x * 0.5 + 8.0
	for k in 25:
		var a := PI + PI * float(k) / 24.0
		pts.append(c + Vector2(cos(a) * rx, sin(a) * 16.0))
	draw_polyline(pts, brass_shadow, 4.0, true)
	draw_polyline(pts, brass, 2.0, true)
	for k in range(2, 24, 3):
		draw_circle(pts[k], 0.9, brass_hi)
	var ks := c + Vector2(0, -16.0)
	draw_colored_polygon(PackedVector2Array([ks + Vector2(-5, -4), ks + Vector2(5, -4), ks + Vector2(3.5, 5),
		ks + Vector2(-3.5, 5)]), brass)
	draw_line(ks + Vector2(-5, -4), ks + Vector2(5, -4), brass_hi, 1.0)


# --- the Cabinet: a mahogany-and-brass automaton cabinet, phosphor glass, crest, payout tray ----------

func _draw_cabinet() -> void:
	var c := cabinet
	# body with side pilasters and a crest pediment
	var body := Rect2(c.x - 14, c.y - 32, 28, 62)
	draw_rect(body, wood_dark)
	draw_rect(Rect2(body.position.x + 2, body.position.y + 2, 24, 58), wood)
	for x in [body.position.x - 2.0, body.end.x - 1.0]:
		draw_rect(Rect2(x, body.position.y - 2, 3, 66), brass_shadow)
		draw_line(Vector2(x + 1, body.position.y - 2), Vector2(x + 1, body.end.y + 2), brass, 1.0)
		draw_circle(Vector2(x + 1.5, body.position.y - 3), 1.6, brass_hi)
	var crest := PackedVector2Array()
	for k in 13:
		var a := PI + PI * float(k) / 12.0
		crest.append(Vector2(c.x, body.position.y) + Vector2(cos(a) * 15.0, sin(a) * 9.0))
	draw_colored_polygon(crest, wood_dark)
	draw_polyline(crest, brass, 1.4, true)
	draw_polyline(crest, Color(brass_hi, 0.6), 0.6, true)
	draw_circle(Vector2(c.x, body.position.y - 6), 2.2, brass)       # the crest's brass boss
	draw_circle(Vector2(c.x - 0.6, body.position.y - 6.6), 0.8, glint)
	# marquee panel (its words are the Ruins scene's): brass-framed, dark inlay
	var mq := Rect2(c.x - 11, c.y - 29, 22, 7)
	draw_rect(mq, slate)
	draw_rect(mq, brass, false, 0.8)
	# the phosphor glass: rounded bezel, a soft rolling band, a curved glint
	var scr := Rect2(c.x - 9, c.y - 19, 18, 15)
	draw_rect(scr.grow(1.5), brass_shadow)
	draw_rect(scr.grow(0.6), brass)
	draw_rect(scr, glass)
	draw_rect(scr.grow(-2.0), Color(glass_lit, 0.35))
	# control deck: two brass buttons and a ball-top stick
	draw_colored_polygon(PackedVector2Array([Vector2(c.x - 12, c.y + 1), Vector2(c.x + 12, c.y + 1),
		Vector2(c.x + 13, c.y + 6), Vector2(c.x - 13, c.y + 6)]), wood_dark)
	draw_line(Vector2(c.x - 12, c.y + 1), Vector2(c.x + 12, c.y + 1), brass_hi, 0.8)
	draw_line(Vector2(c.x - 6, c.y + 3), Vector2(c.x - 6, c.y - 1), brass, 1.0)
	draw_circle(Vector2(c.x - 6, c.y - 1.5), 1.6, velvet)
	draw_circle(Vector2(c.x + 3, c.y + 3), 1.3, brass)
	draw_circle(Vector2(c.x + 7, c.y + 3), 1.3, brass)
	# coin plate and the payout tray at the foot (the tickets fly from the glass; the tray catches)
	draw_rect(Rect2(c.x - 3, c.y + 10, 6, 5), brass_shadow)
	draw_line(Vector2(c.x, c.y + 11), Vector2(c.x, c.y + 14), brass_hi, 0.8)
	draw_colored_polygon(PackedVector2Array([Vector2(c.x - 8, c.y + 22), Vector2(c.x + 8, c.y + 22),
		Vector2(c.x + 6, c.y + 27), Vector2(c.x - 6, c.y + 27)]), brass)
	draw_line(Vector2(c.x - 8, c.y + 22), Vector2(c.x + 8, c.y + 22), brass_hi, 1.0)
	# inlaid panel lines
	draw_rect(Rect2(c.x - 9, c.y + 8, 18, 11), brass_shadow, false, 0.6)


# --- the Chalk Desk: a schoolmaster's slant desk, turned legs, a framed slate, chalk on the ledge ------

func _draw_chalk_desk() -> void:
	var b := chalk_desk
	# turned legs with brass feet
	for x in [-22.0, 18.0]:
		draw_rect(Rect2(b.x + x, b.y - 20, 3, 20), wood_dark)
		draw_circle(Vector2(b.x + x + 1.5, b.y - 12), 2.0, wood)
		draw_circle(Vector2(b.x + x + 1.5, b.y - 1), 2.0, brass)
	draw_line(b + Vector2(-20, -7), b + Vector2(19, -7), wood_dark, 1.6)      # stretcher
	# the slant top with a brass edge
	var top := PackedVector2Array([b + Vector2(-27, -20), b + Vector2(24, -25), b + Vector2(24, -20),
		b + Vector2(-27, -15)])
	draw_colored_polygon(top, wood)
	draw_line(top[0], top[1], brass_hi, 1.0, true)
	draw_line(top[3], top[2], brass_shadow, 1.0, true)
	# the slate on its easel arm, in a brass frame
	draw_line(b + Vector2(-2, -22), b + Vector2(-2, -30), brass, 1.2)
	var sl := PackedVector2Array([b + Vector2(-19, -27), b + Vector2(16, -31), b + Vector2(16, -45),
		b + Vector2(-19, -41)])
	draw_colored_polygon(sl, slate)
	var frame := sl.duplicate()
	frame.append(sl[0])
	draw_polyline(frame, wood_dark, 2.4, true)
	draw_polyline(frame, brass, 0.9, true)
	# an old chalk sketch on the slate (no words): an orbit round a dot, two stars and a tick
	var sc := b + Vector2(-3, -36)
	draw_arc(sc, 5.0, 0.4, TAU - 0.3, 18, Color(chalk, 0.32), 0.7, true)
	draw_circle(sc, 0.9, Color(chalk, 0.4))
	draw_circle(sc + Vector2(5.0, -1.6), 0.7, Color(chalk, 0.45))
	for st: Vector2 in [Vector2(-12, -38), Vector2(10, -40)]:
		draw_line(b + st + Vector2(-1.2, 0), b + st + Vector2(1.2, 0), Color(chalk, 0.3), 0.6)
		draw_line(b + st + Vector2(0, -1.2), b + st + Vector2(0, 1.2), Color(chalk, 0.3), 0.6)
	# brass corner caps on the frame
	for k in 4:
		draw_circle(sl[k], 1.3, brass)
	# the chalk ledge: three sticks and an ink well with a quill
	draw_line(b + Vector2(-19, -27), b + Vector2(16, -31), brass, 1.4, true)
	for k in 3:
		var p := b + Vector2(-12 + 7 * k, -28.5 - 0.6 * k)
		draw_line(p, p + Vector2(4, -0.4), chalk, 1.4)
	draw_circle(b + Vector2(19, -26), 2.2, ink)
	draw_arc(b + Vector2(19, -26), 2.2, -PI, 0.0, 8, brass, 0.8, true)
	draw_line(b + Vector2(19, -27), b + Vector2(24, -36), paper_shade, 0.9, true)


# --- the Codex desk: a lectern on a fluted column, claw feet, the great book open, ribbon, glass -------

func _draw_codex_desk() -> void:
	var b := codex_desk
	# claw feet and the fluted column
	for x in [-9.0, 9.0]:
		draw_colored_polygon(PackedVector2Array([b + Vector2(x - 3, 0), b + Vector2(x + 3, 0),
			b + Vector2(x * 0.3 + 1, -6), b + Vector2(x * 0.3 - 1, -6)]), brass)
	draw_rect(Rect2(b.x - 3.5, b.y - 26, 7, 21), wood_dark)
	for x in [-2.0, 0.0, 2.0]:
		draw_line(b + Vector2(x, -25), b + Vector2(x, -6), wood, 0.7)
	draw_rect(Rect2(b.x - 5, b.y - 7, 10, 2), brass)
	draw_rect(Rect2(b.x - 5, b.y - 27, 10, 2), brass)
	# the slanted reading board
	var board := PackedVector2Array([b + Vector2(-18, -27), b + Vector2(18, -31), b + Vector2(18, -27),
		b + Vector2(-18, -23)])
	draw_colored_polygon(board, wood)
	draw_line(board[0], board[1], brass_hi, 0.9, true)
	# the great book: two pages that curl up at the spine, page-edge stack, a ribbon that sways
	var spine := b + Vector2(0, -30)
	draw_colored_polygon(PackedVector2Array([b + Vector2(-15, -27), spine + Vector2(0, -3), spine,
		b + Vector2(-15, -24)]), paper)
	draw_colored_polygon(PackedVector2Array([spine + Vector2(0, -3), b + Vector2(15, -33), b + Vector2(15, -30),
		spine]), paper_shade)
	draw_line(b + Vector2(-15, -24), spine, paper_shade, 0.8, true)
	draw_line(spine, b + Vector2(15, -30), ink, 0.6, true)
	for k in 3:
		draw_line(b + Vector2(-13 + 4 * k, -26.5 - 0.6 * k), b + Vector2(-5 + 4 * k, -28.6 - 0.6 * k),
			Color(ink, 0.35), 0.5)
	# the reading glass on its chain
	var lens := b + Vector2(12, -21)
	draw_line(b + Vector2(17, -27), lens + Vector2(1, -2), brass, 0.6, true)
	draw_arc(lens, 2.6, 0.0, TAU, 14, brass, 0.9, true)
	draw_circle(lens, 2.0, Color(glass_lit, 0.25))
	draw_arc(lens, 1.6, -2.4, -1.4, 6, Color(glint, 0.7), 0.6, true)


# --- the Hourglass: finialled brass plates, three turned spindles, two glass bulbs, falling grains ------

func _draw_hourglass() -> void:
	var b := hourglass
	# plates with finials
	for y in [-3.0, -32.0]:
		draw_rect(Rect2(b.x - 10, b.y + y, 20, 3), brass)
		draw_line(b + Vector2(-10, y), b + Vector2(10, y), brass_hi, 0.8)
	draw_circle(b + Vector2(0, -35), 2.0, brass)
	draw_circle(b + Vector2(-0.6, -35.6), 0.7, glint)
	for x in [-10.0, 10.0]:
		draw_circle(b + Vector2(x, -1.5), 1.6, brass)
	# three turned spindles (the middle one behind the glass)
	for x in [-8.5, 8.5]:
		draw_line(b + Vector2(x, -29), b + Vector2(x, -3), brass_shadow, 2.0)
		draw_line(b + Vector2(x, -29), b + Vector2(x, -3), brass, 1.0)
		for y in [-23.0, -16.0, -9.0]:
			draw_circle(b + Vector2(x, y), 1.4, brass)
	# the two glass bulbs
	var bulb := PackedVector2Array([b + Vector2(-6, -29), b + Vector2(6, -29), b + Vector2(5, -22),
		b + Vector2(0.9, -16), b + Vector2(5, -10), b + Vector2(6, -3), b + Vector2(-6, -3), b + Vector2(-5, -10),
		b + Vector2(-0.9, -16), b + Vector2(-5, -22)])
	draw_colored_polygon(bulb, Color(glass, 0.3))


# --- the live layer: the parts that move ------------------------------------------------------------

func _draw_cabinet_live() -> void:
	var c := cabinet
	var scr := Rect2(c.x - 9, c.y - 19, 18, 15)
	var roll := fposmod(_t / ROLL_S, 1.0)
	var by := scr.position.y + scr.size.y * roll
	_live.draw_rect(Rect2(scr.position.x, maxf(by - 2.0, scr.position.y), scr.size.x, minf(4.0, scr.end.y - by + 2.0)),
		Color(glass_lit, ROLL_K * 2.0))
	_live.draw_arc(scr.get_center() + Vector2(-3, -3), 7.0, -2.6, -1.8, 8, Color(glint, 0.5), 0.8, true)


func _draw_codex_live() -> void:
	var spine := codex_desk + Vector2(0, -30)
	var sway := sin(TAU * _t / SWAY_S) * SWAY_PX
	_live.draw_polyline(PackedVector2Array([spine, spine + Vector2(0.5, 5), spine + Vector2(sway, 10)]), velvet, 1.1,
		true)


func _draw_hourglass_live() -> void:
	var b := hourglass
	var bulb := PackedVector2Array([b + Vector2(-6, -29), b + Vector2(6, -29), b + Vector2(5, -22),
		b + Vector2(0.9, -16), b + Vector2(5, -10), b + Vector2(6, -3), b + Vector2(-6, -3), b + Vector2(-5, -10),
		b + Vector2(-0.9, -16), b + Vector2(-5, -22)])
	# the sand above the neck shrinks toward it as the clock is spent; the rest heaps below
	var top := lerpf(-16.5, -27.0, sand)
	var w := lerpf(0.9, 5.0, sand)
	if sand > 0.03:
		_live.draw_colored_polygon(PackedVector2Array([b + Vector2(-w, top), b + Vector2(w, top), b + Vector2(0.9, -16.5),
			b + Vector2(-0.9, -16.5)]), sand_col)
	var low := 1.0 - sand
	if low > 0.03:
		var h := lerpf(0.0, 11.0, low)
		var hw := lerpf(1.0, 4.6, low)
		_live.draw_colored_polygon(PackedVector2Array([b + Vector2(-5.5, -3.5), b + Vector2(5.5, -3.5),
			b + Vector2(hw * 0.5, -3.5 - h), b + Vector2(-hw * 0.5, -3.5 - h)]), sand_col)
	if sand_falling and sand > 0.0:
		_live.draw_line(b + Vector2(0, -16), b + Vector2(0, -4), Color(sand_col, 0.55), 0.5)
		for k in GRAINS:
			var y := -16.0 + fposmod(_t * GRAIN_SPEED + float(k) * 12.0 / float(GRAINS), 12.0)
			_live.draw_circle(b + Vector2(0, y), 0.55, sand_col)
	# the glass: a rim and two curved glints
	var rim := bulb.duplicate()
	rim.append(bulb[0])
	_live.draw_polyline(rim, Color(glass_lit, 0.45), 0.7, true)
	_live.draw_line(b + Vector2(-4, -27), b + Vector2(-3.2, -22), Color(glint, 0.55), 0.6, true)
	_live.draw_line(b + Vector2(-4, -9), b + Vector2(-4.6, -5), Color(glint, 0.4), 0.6, true)
