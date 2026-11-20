class_name BezelArt
extends RefCounted
## The Cabinet bezel's printed art as data (owner decision D-B; TECH-001 §1.3): `build_left()` and
## `build_right()` return the sorted BezelPiece list for one CabinetBezel.SIDE × 360 column (152 × 360 since
## the surround pass, 2026-11-19), in column-local coordinates. The two columns are the side halves of ONE
## printed sheet (PR C pass 2): no floating art cards; each is a full-bleed illustration whose characters,
## ships, planets and crags run off the column's outer, top and bottom edges (BezelPrint clips to the column),
## with a small tidy how-to card printed in the lower outer corner (real-bezel proportions: about an eighth of
## the sheet's width, fine-print type) and a triple pinstripe border down each outer edge. The marquee is the
## only title (Fable review 2026-11-20). Everything is hand-placed and deterministic: scatter uses a pure
## integer hash, never an RNG. The lists are the seam the later "zoom destruction" (peel, crack, curl, decay)
## drives piece by piece: each piece has an id, a z and a pivot.
##
## Left: the Vigil as the hero, diving big past a ringed planet, its Arc-Lance striking a Glass geode, more
## geodes adrift, and the how-to card. Right: the tagline burst, a plain ringed world (no eye: the entity never
## has eyes, ART-001 §12.7a / N4), the hero Oubliette Grub holding Mourning Glass overhead and facing the
## screen with its swarm, the Choir's procession climbing a geode crag, the coin door seated in a printed
## cut-out, the sticker and the maker's badge.
##
## Period print (1983 spot-colour screenprint, Fable review 2026-11-20): at most six inks plus key black
## (PRINT_INKS; other ink names are mapped onto them as they are added), no soft glows or airbrush, every
## shape keylined in key black at one width (KEYLINE), and shading as tone ramps that the print shader steps
## into a coarse two-step dot screen. The 2 px nearest the screen is a key-black lip.

const L := &"left"
const R := &"right"

## The how-to-play card's lines (en.po). Each must fit the card (tested).
const HOWTO_KEYS: Array[String] = ["CAB_HOWTO_1", "CAB_HOWTO_2", "CAB_HOWTO_3", "CAB_HOWTO_4"]
## Which how-to lines start a bulleted item (line 4 continues line 3).
const HOWTO_BULLET: Array[bool] = [true, true, true, false]
## Every other string the sheet prints (all drawn with VectorText through tr()).
const SHEET_KEYS: Array[String] = ["CAB_HOWTO_TITLE", "CAB_BEZEL_SLOGAN", "CAB_BEZEL_TAG_1", "CAB_BEZEL_TAG_2", "CAB_BEZEL_MAKER"]

## The six spot inks the side art is printed in, plus key black (Fable review 2026-11-20: true 1983 screenprint).
const PRINT_INKS: Array[StringName] = [&"navy", &"cyan", &"magenta", &"warm_red", &"yellow", &"cream", &"key_black"]
## Other BezelInks names mapped onto the six as pieces are added (a printer with six screens).
const INK_MAP := {&"process_blue": &"cyan", &"orange": &"warm_red", &"chrome_dark": &"navy", &"chrome_light": &"cream", &"brass": &"yellow"}
const KEYLINE := 1.2   ## ✱ the one keyline width, rig units (3.6 px at 1920×1080, 4.8 px at 3440×1440)

const Z_BG := 0
const Z_STARS := 5
const Z_ART := 20          ## illustrations use Z_ART … Z_ART + 50
const Z_CARD := 82          ## above the pinstripes: the card is printed over the border
const Z_WINDOW := 70
const Z_CAP := 80
const Z_LIP := 92
const Z_GLARE := 100

const W := CabinetBezel.SIDE   ## column width, rig units
const HOWTO_TITLE_CAP := 4.4   ## ✱ how-to card title cap height (real-bezel fine print: about 1.2 % of the sheet's height)
const HOWTO_CAP := 3.6         ## ✱ how-to card line cap height (about 1 % of the sheet's height)
const HOWTO_LEAD := 6.6        ## ✱ line pitch on the card
const STRIPE_X: Array[float] = [13.0, 15.5, 17.5]   ## ✱ the outer pinstripes' distance from the outer edge (inside the bolts)
## Right column, column-local: the crag's summit where a haunt figure can stand (feet on the bottom edge). Empty sky against the moon.
const FIGURE_STAND := Rect2(128.0, 148.0, 14.0, 30.0)
## Right column: the ringed world (no eye) and the hero Grub's feet (behind the NEW! sticker), column-local.
const WORLD_C := Vector2(116.0, 104.0)
const WORLD_R := 30.0
const GRUB_FEET := Vector2(50.0, 226.0)
const GRUB_SCALE := 0.8        ## ✱ hero Grub scale: about 112 units tall with its Glass, the Vigil's size
## Left column: the Vigil illustration's placement (drawn in the old 80-column frame, enlarged to be the hero).
const VIGIL_SCALE := 2.6
const VIGIL_OFFSET := Vector2(-66.0, -328.7)



## Collects pieces for one column and keeps the build order for stable sorting. `sc` / `off` place a
## whole illustration (scale about the origin, then shift) so one drawing can be enlarged to bleed.
class _Acc extends RefCounted:
	var col: StringName
	var items: Array[BezelPiece] = []
	var sc := 1.0
	var off := Vector2.ZERO

	func _init(p_col: StringName) -> void:
		col = p_col

	func place(p_sc: float, p_off: Vector2) -> void:
		sc = p_sc
		off = p_off

	func _pts(pts: PackedVector2Array) -> PackedVector2Array:
		if sc == 1.0 and off == Vector2.ZERO:
			return pts
		var out := PackedVector2Array()
		for q in pts:
			out.append(q * sc + off)
		return out

	func add(id: StringName, kind: int, pts: PackedVector2Array, ink: StringName, z: int, width: float = 1.0) -> BezelPiece:
		var printed: StringName = BezelArt.INK_MAP.get(ink, ink)
		var b := BezelPiece.make(StringName("%s_%s" % [col, id]), col, kind, _pts(pts), printed, z)
		b.width = width * sc if kind != BezelPiece.Kind.PIXELS else width
		if kind == BezelPiece.Kind.OUTLINE:
			b.width = BezelArt.KEYLINE
		b.order = items.size()
		items.append(b)
		return b

	## A flat ink shape; `keyed` adds its key-black keyline (every printed shape has one but inner details).
	func fill(id: StringName, pts: PackedVector2Array, ink: StringName, z: int, keyed: bool = true) -> void:
		add(id, BezelPiece.Kind.FILL, pts, ink, z)
		if keyed and ink != &"key_black":
			outline(StringName("%s_key" % id), pts, &"key_black", z)

	## A stroke `w` wide (before placement) laid on a key-black stroke one KEYLINE wider each side.
	func keyed_stroke(id: StringName, pts: PackedVector2Array, ink: StringName, z: int, w: float) -> void:
		var k := add(StringName("%s_key" % id), BezelPiece.Kind.STROKE, pts, &"key_black", z, w)
		k.width = w * sc + 2.0 * BezelArt.KEYLINE
		add(id, BezelPiece.Kind.STROKE, pts, ink, z + 1, w)

	func rect(id: StringName, r: Rect2, ink: StringName, z: int) -> void:
		add(id, BezelPiece.Kind.FILL, PackedVector2Array([r.position, Vector2(r.end.x, r.position.y), r.end, Vector2(r.position.x, r.end.y)]), ink, z)

	func outline(id: StringName, pts: PackedVector2Array, ink: StringName, z: int) -> void:
		add(id, BezelPiece.Kind.OUTLINE, pts, ink, z, 1.0)

	func stroke(id: StringName, pts: PackedVector2Array, ink: StringName, z: int, width: float = 1.0) -> void:
		add(id, BezelPiece.Kind.STROKE, pts, ink, z, width)

	func pixels(id: StringName, pts: PackedVector2Array, ink: StringName, z: int, size: float = 1.0) -> void:
		add(id, BezelPiece.Kind.PIXELS, pts, ink, z, size)

	## A screened tone along a line: tone t0 at `from` to t1 at `to` (the polygon is printed as round dots).
	func tone_linear(id: StringName, pts: PackedVector2Array, ink: StringName, z: int, from: Vector2, to: Vector2, t0: float = 1.0, t1: float = 0.0) -> void:
		var b := add(id, BezelPiece.Kind.HALFTONE, pts, ink, z)
		b.tone_mode = BezelPiece.TONE_LINEAR
		b.tone_a = from * sc + off
		b.tone_b = to * sc + off
		b.tone0 = t0
		b.tone1 = t1

	## A screened tone round `c`: t0 at radius r0 to t1 at r1 (r0 = 0 is a glow printed as a fan).
	func tone_radial(id: StringName, pts: PackedVector2Array, ink: StringName, z: int, c: Vector2, r0: float, r1: float, t0: float, t1: float) -> void:
		var b := add(id, BezelPiece.Kind.HALFTONE, pts, ink, z)
		b.tone_mode = BezelPiece.TONE_RADIAL
		b.tone_a = c * sc + off
		b.tone_b = Vector2(r0, r1) * sc
		b.tone0 = t0
		b.tone1 = t1

	## VectorText lettering: `anchor` is (centre x or left x, cap-top y), `cap` the cap height, from tr(key).
	func text(id: StringName, key: String, anchor: Vector2, ink: StringName, z: int, cap: float, stroke_w: float,
			centered: bool = true, tracking: float = 0.0, part: int = 0, rot: float = 0.0) -> BezelPiece:
		var b := add(id, BezelPiece.Kind.TEXT, PackedVector2Array([anchor]), ink, z, cap)
		b.text_key = key
		b.centered = centered
		b.stroke_w = stroke_w
		b.tracking = tracking
		b.text_part = part
		b.rot = rot
		return b


static func build_left() -> Array[BezelPiece]:
	var a := _Acc.new(L)
	_background(a)
	_pinstripes(a)
	a.place(VIGIL_SCALE, VIGIL_OFFSET)
	_vigil_illustration(a)
	a.place(1.0, Vector2.ZERO)
	_left_geodes(a, vigil_bolt_end())
	_howto_panel(a, CabinetBezel.LEFT_HOWTO)
	_lip(a, W - 2.0)
	return sorted(a.items)


static func build_right() -> Array[BezelPiece]:
	var a := _Acc.new(R)
	_background(a)
	_pinstripes(a)
	_tagline_burst(a)
	_ringed_world(a)
	_crag(a)
	_choir_procession(a)
	_grub_swarm(a)
	_coin_door_backing(a)
	_maker_badge(a)
	_lip(a, 0.0)
	return sorted(a.items)


## Where the Arc-Lance bolt ends in the left column (the geode strike sits there), from the Vigil's placement.
static func vigil_bolt_end() -> Vector2:
	return Vector2(75.4, 217.2) * VIGIL_SCALE + VIGIL_OFFSET


## Where the haunt overlays (the cursed turn, ART-001 §12.7b) may attach to the printed art, in rig units
## (bezel space, the 640 × 360 reference the bezel is drawn in): Rect2 values keyed
## `wear_origin` (the ringed world's middle band on the right column: where the cursed turn's wear-through
## starts; it was `eye` until the Fable review, 2026-11-20: the world has no eye now, N4),
## `figure` (a standing place on the crag's summit: feet on the rect's bottom edge),
## `marquee_letters` (the marquee's printed title) and `how_to_play` (the instruction card). Read-only data;
## the overlays draw over the bezel and never edit it. Derived from the built pieces, so it follows the art.
static func haunt_anchors() -> Dictionary:
	var wear := Rect2()
	for p in build_right():
		if p.id == &"right_world_band_1":
			var lo := Vector2(INF, INF)
			var hi := Vector2(-INF, -INF)
			for q in p.points:
				lo = lo.min(q)
				hi = hi.max(q)
			wear = CabinetBezel.to_screen(R, Rect2(lo, hi - lo).grow(p.width * 0.5))
	return {
		&"wear_origin": wear,
		&"figure": CabinetBezel.to_screen(R, FIGURE_STAND),
		&"marquee_letters": BezelMarquee.lettering_rect(),
		&"how_to_play": CabinetBezel.to_screen(L, CabinetBezel.LEFT_HOWTO),
	}


## The string a TEXT piece prints: the whole translation, or one stacked half of it.
static func text_of(p: BezelPiece, s: String) -> String:
	if p.text_part == 0:
		return s
	var n := s.length()
	var cut := int(ceil(n * 0.5))
	return s.substr(0, cut) if p.text_part == 1 else s.substr(cut)


## The largest cap height (≤ `cap_max`) at which `text` painted with `stroke_ratio` * cap fits `max_w`.
static func fit_cap(text: String, max_w: float, cap_max: float, stroke_ratio: float, tracking: float = 0.0) -> float:
	var cap := cap_max
	while cap > 2.0:
		if BezelText.painted_size(text, cap, cap * stroke_ratio, tracking).x <= max_w:
			return cap
		cap -= 0.25
	return cap


## Stable sort: z, then build order.
static func sorted(items: Array[BezelPiece]) -> Array[BezelPiece]:
	var out: Array[BezelPiece] = items.duplicate()
	out.sort_custom(func(p: BezelPiece, q: BezelPiece) -> bool:
		return p.order < q.order if p.z == q.z else p.z < q.z)
	return out
# --- shape helpers ------------------------------------------------------------------------------

static func rect_pts(r: Rect2) -> PackedVector2Array:
	return PackedVector2Array([r.position, Vector2(r.end.x, r.position.y), r.end, Vector2(r.position.x, r.end.y)])


static func circle_pts(c: Vector2, r: float, n: int = 28) -> PackedVector2Array:
	return ellipse_pts(c, r, r, 0.0, n)


static func ellipse_pts(c: Vector2, rx: float, ry: float, rot: float, n: int = 28) -> PackedVector2Array:
	var out := PackedVector2Array()
	for i in n:
		var ang := TAU * i / n
		out.append(c + Vector2(cos(ang) * rx, sin(ang) * ry).rotated(rot))
	return out


## An open arc of an ellipse, parameter angles a0 → a1.
static func arc_pts(c: Vector2, rx: float, ry: float, rot: float, a0: float, a1: float, n: int = 16) -> PackedVector2Array:
	var out := PackedVector2Array()
	for i in n + 1:
		var ang := lerpf(a0, a1, float(i) / n)
		out.append(c + Vector2(cos(ang) * rx, sin(ang) * ry).rotated(rot))
	return out


## An n-pointed star: alternating outer / inner radius, optionally squashed (ellipse starburst).
static func star_pts(c: Vector2, r_out: float, r_in: float, points: int, rot: float = 0.0, squash: float = 1.0) -> PackedVector2Array:
	var out := PackedVector2Array()
	for i in points * 2:
		var r := r_out if i % 2 == 0 else r_in
		var ang := rot + PI * i / points
		out.append(c + Vector2(cos(ang) * r, sin(ang) * r * squash))
	return out


## Points moved by rotation `rot` then translation `pos` (local art drawn nose-up).
static func xf(pts: PackedVector2Array, pos: Vector2, rot: float) -> PackedVector2Array:
	var out := PackedVector2Array()
	for p in pts:
		out.append(pos + p.rotated(rot))
	return out


## A crescent on one side of a circle: the shaded side of a sphere. `depth` px at its fattest.
static func crescent_pts(c: Vector2, r: float, a0: float, a1: float, depth: float, n: int = 14) -> PackedVector2Array:
	var out := PackedVector2Array()
	for i in n + 1:
		var ang := lerpf(a0, a1, float(i) / n)
		out.append(c + Vector2(cos(ang), sin(ang)) * r)
	for i in range(n, -1, -1):
		var k := float(i) / n
		var ang := lerpf(a0, a1, k)
		out.append(c + Vector2(cos(ang), sin(ang)) * (r - depth * sin(k * PI)))
	return out


## Pure integer hash (no RNG state): the same index always gives the same value.
static func hash_int(i: int) -> int:
	var x: int = (i * 0x9E3779B1 + 0x7F4A7C15) & 0xFFFFFFFF
	x = ((x ^ (x >> 15)) * 0x2C1B3C6D) & 0xFFFFFFFF
	x = ((x ^ (x >> 12)) * 0x297A2D39) & 0xFFFFFFFF
	return (x ^ (x >> 15)) & 0x7FFFFFFF


## Sparse 1 px stars inside `area`, skipping the `avoid` rects. Hand-seeded by `seed_i`.
static func scatter(area: Rect2, count: int, seed_i: int, avoid: Array[Rect2]) -> PackedVector2Array:
	var out := PackedVector2Array()
	var i := 0
	while out.size() < count and i < count * 8:
		var x := area.position.x + float(hash_int(seed_i * 977 + i * 2) % maxi(1, int(area.size.x)))
		var y := area.position.y + float(hash_int(seed_i * 977 + i * 2 + 1) % maxi(1, int(area.size.y)))
		i += 1
		var p := Vector2(x, y)
		var hidden := false
		for r in avoid:
			if r.has_point(p):
				hidden = true
				break
		if not hidden:
			out.append(p)
	return out


# --- shared furniture ---------------------------------------------------------------------------

## The outer edge of a column in column-local x (0 on the left column, W on the right).
static func _outer(a: _Acc) -> float:
	return 0.0 if a.col == L else W


## Mirror a column-local x across the column so the right column can reuse a left-column layout.
static func _mx(a: _Acc, x: float) -> float:
	return x if a.col == L else W - x


static func _background(a: _Acc) -> void:
	a.rect(&"field", Rect2(-8, -8, W + 16, 376), &"navy", Z_BG)
	var avoid: Array[Rect2] = [Rect2(0, 0, W, 12), Rect2(0, 348, W, 12)]
	var seed_i := 1 if a.col == L else 2
	# one diagonal band of screened tone (a period Ben-Day band, not an airbrushed nebula), so the field is never empty
	a.tone_linear(&"nebula_band", PackedVector2Array([Vector2(-8, 150), Vector2(W + 8, 96), Vector2(W + 8, 136), Vector2(-8, 190)]), &"cyan", Z_BG + 2,
		Vector2(0, 170), Vector2(0, 136), 0.18, 0.0)
	a.pixels(&"stars_cream", scatter(Rect2(0, 0, W, 360), 46, seed_i, avoid), &"cream", Z_STARS)
	a.pixels(&"stars_yellow", scatter(Rect2(0, 0, W, 360), 18, seed_i + 10, avoid), &"yellow", Z_STARS)
	a.pixels(&"stars_cyan", scatter(Rect2(0, 0, W, 360), 10, seed_i + 20, avoid), &"cyan", Z_STARS)
	var burst: Array[Vector2] = [Vector2(28, 98), Vector2(128, 242), Vector2(58, 258), Vector2(140, 22)]
	if a.col != L:
		burst = [Vector2(40, 196), Vector2(138, 70), Vector2(74, 98), Vector2(30, 120)]
	for i in burst.size():
		a.fill(StringName("sparkle_%d" % i), star_pts(burst[i], 3.0, 0.7, 4), &"yellow", Z_STARS + 1, false)


## A triple pinstripe (yellow, red, magenta) down the outer edge, inside the bezel bolts: the sheet's border.
static func _pinstripes(a: _Acc) -> void:
	var inks: Array[StringName] = [&"yellow", &"warm_red", &"magenta"]
	var widths: Array[float] = [1.6, 1.0, 1.0]
	for i in STRIPE_X.size():
		var x := absf(_outer(a) - STRIPE_X[i])
		a.stroke(StringName("stripe_%d" % i), PackedVector2Array([Vector2(x, -8), Vector2(x, 368)]), inks[i], Z_CAP - 2, widths[i])


## The key-black screen lip: the 2 px strip nearest the opening.
static func _lip(a: _Acc, x: float) -> void:
	a.rect(&"lip", Rect2(x, -8, 2, 376), &"key_black", Z_LIP)


## A Choir monk about 8 px tall. `face`: -1 / +1 hood in profile toward that side, 0 faces the player.
static func _monk(a: _Acc, id: StringName, feet: Vector2, face: int, glass_ink: StringName, z: int) -> void:
	var robe: PackedVector2Array
	if face == 0:
		robe = PackedVector2Array([Vector2(-3, 0), Vector2(3, 0), Vector2(3, -3), Vector2(2, -6), Vector2(0, -8), Vector2(-2, -6), Vector2(-3, -3)])
	else:
		var s := float(face)
		robe = PackedVector2Array([Vector2(-3 * s, 0), Vector2(3 * s, 0), Vector2(3 * s, -3), Vector2(2 * s, -5), Vector2(0, -7), Vector2(-1 * s, -8), Vector2(-2 * s, -5)])
	a.fill(StringName("%s_robe" % id), xf(robe, feet, 0.0), &"magenta", z, false)
	a.outline(StringName("%s_line" % id), xf(robe, feet, 0.0), &"key_black", z + 1)
	if face == 0:
		a.rect(StringName("%s_face" % id), Rect2(feet + Vector2(-2, -6), Vector2(4, 3)), &"key_black", z + 2)
		a.pixels(StringName("%s_eyes" % id), PackedVector2Array([feet + Vector2(-2, -5), feet + Vector2(1, -5)]), &"cream", z + 3)
	else:
		var fx := 1.0 if face > 0 else -2.0
		a.rect(StringName("%s_face" % id), Rect2(feet + Vector2(fx, -5), Vector2(1, 2)), &"key_black", z + 2)
	var glass_at := feet + (Vector2(0, -1) if face == 0 else Vector2(4.0 * face, -2))
	var diamond := PackedVector2Array([glass_at + Vector2(0, -2), glass_at + Vector2(2, 0), glass_at + Vector2(0, 2), glass_at + Vector2(-2, 0)])
	a.fill(StringName("%s_glass" % id), diamond, glass_ink, z + 4, false)
	a.outline(StringName("%s_glass_line" % id), diamond, &"key_black", z + 5)


## A Glass geode: a lumpy rock cracked open on a cavity of cyan crystal, outlined in key black. `r` is the
## rock's radius, `rot` turns the cavity's opening. Deterministic (hash of `seed_i`).
static func _geode(a: _Acc, id: String, c: Vector2, r: float, rot: float, seed_i: int, z: int) -> void:
	var rock := PackedVector2Array()
	var n := 11
	for i in n:
		var ang := TAU * i / n
		var k := 0.82 + 0.3 * float(hash_int(seed_i * 31 + i) % 100) / 100.0
		rock.append(c + Vector2(cos(ang), sin(ang)) * r * k)
	a.fill(StringName("%s_rock" % id), rock, &"cream", z, false)
	a.tone_radial(StringName("%s_rock_shade" % id), rock, &"magenta", z + 1, c + Vector2(-r * 0.35, -r * 0.4), r * 0.5, r * 1.2, 0.0, 0.45)
	a.outline(StringName("%s_rock_line" % id), rock, &"key_black", z + 2)
	# the cavity, turned toward `rot`: navy, with a stepped cyan screen (no glow)
	var cav_c := c + Vector2(cos(rot), sin(rot)) * r * 0.18
	var cav := ellipse_pts(cav_c, r * 0.62, r * 0.46, rot, 16)
	a.fill(StringName("%s_cavity" % id), cav, &"navy", z + 3, false)
	a.tone_radial(StringName("%s_cavity_screen" % id), cav, &"cyan", z + 3, cav_c, r * 0.1, r * 0.62, 0.8, 0.2)
	a.outline(StringName("%s_cavity_rim" % id), cav, &"key_black", z + 4)
	# crystal shards fanning out of the cavity
	for i in 5:
		var ang := rot - 1.1 + 0.55 * i
		var ln := r * (0.55 + 0.25 * float(hash_int(seed_i * 53 + i) % 100) / 100.0)
		var base := cav_c + Vector2(cos(ang), sin(ang)) * r * 0.08
		var dir := Vector2(cos(ang), sin(ang))
		var side := dir.orthogonal() * r * 0.11
		var shard := PackedVector2Array([base - side, base + dir * ln, base + side])
		a.fill(StringName("%s_shard_%d" % [id, i]), shard, &"cyan", z + 5, false)
		a.stroke(StringName("%s_shard_%d_glint" % [id, i]), PackedVector2Array([base, base + dir * ln * 0.8]), &"cream", z + 6, 0.8)
		a.outline(StringName("%s_shard_%d_line" % [id, i]), shard, &"key_black", z + 7)
	var tip := cav_c + Vector2(cos(rot), sin(rot)) * r * 0.75
	a.fill(StringName("%s_spark" % id), star_pts(tip, r * 0.3, r * 0.07, 4, 0.4), &"cream", z + 8, false)


# --- LEFT: the Vigil ----------------------------------------------------------------------------

## The hero (the marquee is the only title, so the Vigil takes the upper art): drawn in the original 80-column
## frame and enlarged by `a.place(VIGIL_SCALE, VIGIL_OFFSET)` (build_left) so the ship and its planet bleed off
## the top and outer edges. Flat inks with keylines; shading is tone ramps the print steps into dots.
static func _vigil_illustration(a: _Acc) -> void:
	var z := Z_ART + 1
	# the ringed planet, up-left and bleeding off the outer edge and the top
	var pc := Vector2(23, 129)
	var ring_rot := -0.38
	a.keyed_stroke(&"vigil_ring_back", arc_pts(pc, 18, 5, ring_rot, PI, TAU, 18), &"magenta", z + 4, 3.0)
	a.fill(&"vigil_planet", circle_pts(pc, 11, 22), &"cyan", z + 6, false)
	a.tone_radial(&"vigil_planet_shade_wide", crescent_pts(pc, 11, -0.4, 2.6, 9), &"navy", z + 7, pc, 2.0, 11.0, 0.0, 0.95)
	a.fill(&"vigil_planet_shade", crescent_pts(pc, 11, -0.2, 2.4, 4.5), &"navy", z + 8, false)
	a.stroke(&"vigil_planet_band", arc_pts(pc, 10, 3, -0.38, 0.3, 2.8, 10), &"cream", z + 9, 1.0)
	a.outline(&"vigil_planet_line", circle_pts(pc, 11, 22), &"key_black", z + 10)
	a.keyed_stroke(&"vigil_ring_front", arc_pts(pc, 18, 5, ring_rot, 0.0, PI, 18), &"magenta", z + 11, 3.0)
	# the Vigil, diving nose-first down and to the right, toward the screen
	var d := Vector2(0.6, 0.8)
	var centre := Vector2(46, 178)
	var rot := Vector2(0, -1).angle_to(d)
	# speed lines trail up-left
	var perp := Vector2(0.8, -0.6)
	var offs: Array[float] = [-16.0, -8.0, 0.0, 8.0, 16.0]
	var lens: Array[float] = [14.0, 22.0, 26.0, 18.0, 14.0]
	for i in offs.size():
		var s0 := centre - d * 20.0 + perp * offs[i]
		a.keyed_stroke(StringName("vigil_speed_%d" % i), PackedVector2Array([s0, s0 - d * lens[i]]), &"cream" if i % 2 == 0 else &"yellow", z + 13, 0.8)
	a.fill(&"vigil_flame", xf(PackedVector2Array([Vector2(-6, 9), Vector2(0, 32), Vector2(6, 9)]), centre, rot), &"warm_red", z + 15)
	a.fill(&"vigil_flame_core", xf(PackedVector2Array([Vector2(-3, 9), Vector2(0, 22), Vector2(3, 9)]), centre, rot), &"yellow", z + 16, false)
	var hull := PackedVector2Array([Vector2(0, -26), Vector2(20, 16), Vector2(0, 8), Vector2(-20, 16)])
	a.fill(&"vigil_hull", xf(hull, centre, rot), &"yellow", z + 17, false)
	a.tone_linear(&"vigil_hull_shade", xf(PackedVector2Array([Vector2(0, -26), Vector2(20, 16), Vector2(0, 8)]), centre, rot), &"warm_red", z + 18,
		centre + Vector2(0, 14).rotated(rot), centre + Vector2(0, -22).rotated(rot), 0.95, 0.12)
	a.fill(&"vigil_fin_r", xf(PackedVector2Array([Vector2(12, -1), Vector2(20, 16), Vector2(0, 8), Vector2(5, 3)]), centre, rot), &"warm_red", z + 19)
	a.fill(&"vigil_fin_l", xf(PackedVector2Array([Vector2(-12, -1), Vector2(-20, 16), Vector2(0, 8), Vector2(-5, 3)]), centre, rot), &"warm_red", z + 19)
	a.outline(&"vigil_hull_line", xf(hull, centre, rot), &"key_black", z + 20)
	a.stroke(&"vigil_keel", xf(PackedVector2Array([Vector2(0, -20), Vector2(0, 7)]), centre, rot), &"key_black", z + 20, 0.5)
	var cockpit := centre + Vector2(0, -4).rotated(rot)
	a.fill(&"vigil_cockpit", circle_pts(cockpit, 5, 14), &"navy", z + 21)
	a.fill(&"vigil_cockpit_glint", circle_pts(cockpit + Vector2(-1.5, -1.5), 2.0, 10), &"cream", z + 22, false)
	# the cyan Arc-Lance bolt from the nose down to the geode it is mining (vigil_bolt_end, LEFT geodes)
	var nose := centre + d * 26.0
	var bolt := PackedVector2Array([nose, nose + d * 8.0 + perp * 3.0, nose + d * 15.0 - perp * 3.0, nose + d * 23.0])
	a.keyed_stroke(&"vigil_bolt", bolt, &"cyan", z + 24, 2.4)
	a.stroke(&"vigil_bolt_core", bolt, &"cream", z + 26, 0.7)
	a.fill(&"vigil_muzzle", star_pts(nose, 5, 1.5, 4, 0.3), &"cream", z + 27)


## Glass geodes adrift round the Vigil; the big one by the screen takes the Arc-Lance hit at `hit`.
static func _left_geodes(a: _Acc, hit: Vector2) -> void:
	_geode(a, "geode_big", hit + Vector2(-6, 18), 19.0, -2.3, 3, Z_ART + 42)
	a.fill(&"geode_hit", star_pts(hit, 9.0, 2.2, 6, 0.2), &"yellow", Z_ART + 50)
	a.fill(&"geode_hit_core", star_pts(hit, 4.5, 1.2, 4, 0.6), &"cream", Z_ART + 52, false)
	# chips of Glass flying off the strike
	var chips: Array[Vector2] = [hit + Vector2(-18, -14), hit + Vector2(-4, -22), hit + Vector2(-22, 2), hit + Vector2(-26, 24)]
	for i in chips.size():
		var c := chips[i]
		var dm := PackedVector2Array([c + Vector2(0, -2.5), c + Vector2(1.6, 0), c + Vector2(0, 2.5), c + Vector2(-1.6, 0)])
		a.fill(StringName("geode_chip_%d" % i), dm, &"cyan", Z_ART + 50)
	_geode(a, "geode_drift_a", Vector2(20, 248), 10.0, -0.6, 7, Z_ART + 30)
	_geode(a, "geode_drift_b", Vector2(118, 318), 12.0, 2.4, 11, Z_ART + 30)
	# hidden wrongness (carries no gameplay information): one "star" is a key-black hole with a thin cream ring
	a.fill(&"vigil_hole", circle_pts(Vector2(134, 34), 3.0, 14), &"key_black", Z_STARS + 2)
	a.outline(&"vigil_hole_ring", circle_pts(Vector2(134, 34), 4.2, 16), &"cream", Z_STARS + 3)
	a.fill(&"vigil_burst", star_pts(Vector2(100, 290), 5, 1.4, 4), &"yellow", Z_STARS + 1, false)



# --- LEFT: how to play --------------------------------------------------------------------------

## The instruction card printed in the lower outer corner: small and tidy like a real 1983 bezel's (title band,
## bulleted fine print, a pictogram strip, a red keyline), not a poster.
static func _howto_panel(a: _Acc, r: Rect2) -> void:
	var z := Z_CARD
	a.rect(&"howto_card", r, &"cream", z)
	a.rect(&"howto_band", Rect2(r.position.x, r.position.y, r.size.x, 9.0), &"yellow", z + 2)
	a.rect(&"howto_rule", Rect2(r.position.x, r.position.y + 9.0, r.size.x, 0.8), &"key_black", z + 3)
	a.outline(&"howto_border", rect_pts(r.grow(-1.5)), &"warm_red", z + 3)
	a.outline(&"howto_edge", rect_pts(r), &"key_black", z + 4)
	var cx := r.position.x + r.size.x * 0.5
	var tcap := minf(HOWTO_TITLE_CAP, howto_cap(["CAB_HOWTO_TITLE"], r.size.x - 8.0, HOWTO_TITLE_CAP))
	a.text(&"howto_title", "CAB_HOWTO_TITLE", Vector2(cx, r.position.y + (9.0 - tcap) * 0.5), &"key_black", z + 4, tcap, 0.95, true, 0.6)
	var lcap := howto_cap(HOWTO_KEYS, howto_line_width(), HOWTO_CAP)
	var tx := r.position.x + 11.0
	for i in HOWTO_KEYS.size():
		var y := r.position.y + 13.5 + i * HOWTO_LEAD
		a.text(StringName("howto_line_%d" % (i + 1)), HOWTO_KEYS[i], Vector2(tx, y), &"key_black", z + 4, lcap, 0.8, false, 0.5)
		if HOWTO_BULLET[i]:
			var b := Vector2(r.position.x + 6.0, y + lcap * 0.5)
			a.fill(StringName("howto_bullet_%d" % (i + 1)), PackedVector2Array([b + Vector2(0, -1.4), b + Vector2(1.4, 0), b + Vector2(0, 1.4), b + Vector2(-1.4, 0)]), &"warm_red", z + 4, false)
	# the pictogram strip: glass -> charge -> Sepulchre
	var y := r.end.y - 8.5
	var x0 := cx - 24.0
	var glass := PackedVector2Array([Vector2(x0, y - 3), Vector2(x0 + 2.5, y), Vector2(x0, y + 3), Vector2(x0 - 2.5, y)])
	a.fill(&"howto_pic_glass", glass, &"cyan", z + 4, false)
	a.outline(&"howto_pic_glass_line", glass, &"key_black", z + 5)
	a.stroke(&"howto_pic_arrow_1", PackedVector2Array([Vector2(x0 + 6, y), Vector2(x0 + 14, y)]), &"key_black", z + 4, 0.8)
	a.fill(&"howto_pic_charge", star_pts(Vector2(x0 + 24, y), 4, 1.5, 4), &"warm_red", z + 4, false)
	a.outline(&"howto_pic_charge_line", star_pts(Vector2(x0 + 24, y), 4, 1.5, 4), &"key_black", z + 5)
	a.stroke(&"howto_pic_arrow_2", PackedVector2Array([Vector2(x0 + 33, y), Vector2(x0 + 41, y)]), &"key_black", z + 4, 0.8)
	# the Sepulchre: an altar of fused vertebrae (three stacked bones; no face, no eye)
	for i in 3:
		a.fill(StringName("howto_pic_altar_%d" % i), ellipse_pts(Vector2(x0 + 48, y + 2.4 - i * 2.4), 3.4 - i * 0.6, 1.1, 0.0, 10), &"navy", z + 4 + i)


## The width a how-to line may use: the card less the bullet gutter and the right margin.
static func howto_line_width() -> float:
	return CabinetBezel.LEFT_HOWTO.size.x - 15.0


## The common cap height (up to `cap_max`) at which every translated line of `keys` fits `max_w`.
static func howto_cap(keys: Array, max_w: float, cap_max: float) -> float:
	var cap := cap_max
	for k in keys:
		cap = minf(cap, fit_cap(TranslationServer.translate(String(k)), max_w, cap_max, 0.2, 0.5))
	return cap


# --- RIGHT: the tagline burst, the ringed world and the Grub ------------------------------------

static func _tagline_burst(a: _Acc) -> void:
	var c := Vector2(50, 44)
	var burst := star_pts(c, 42, 33, 18, 0.2, 0.62)
	a.fill(&"tag_shadow", xf(burst, Vector2(1.8, 2.2), 0.0), &"key_black", Z_ART + 46)
	a.fill(&"tag_burst", burst, &"yellow", Z_ART + 47, false)
	a.tone_radial(&"tag_burst_shade", burst, &"warm_red", Z_ART + 48, c + Vector2(-7, -9), 9.0, 44.0, 0.0, 0.55)
	a.outline(&"tag_burst_line", burst, &"key_black", Z_ART + 49)
	var cap := howto_cap(["CAB_BEZEL_TAG_1", "CAB_BEZEL_TAG_2"], 60.0, 7.0)
	a.text(&"tag_line_1", "CAB_BEZEL_TAG_1", Vector2(c.x, c.y - cap - 1.5), &"key_black", Z_ART + 50, cap, cap * 0.22, true, 0.6)
	a.text(&"tag_line_2", "CAB_BEZEL_TAG_2", Vector2(c.x, c.y + 2.0), &"key_black", Z_ART + 50, cap, cap * 0.22, true, 0.6)


## A plain ringed world, upper right, bleeding off the outer edge: magenta with three latitude bands and a
## yellow ring. It has no eye, no slit and no lid (the entity never has eyes: Fable review N4, 2026-11-20);
## its middle band is where the cursed turn's wear-through starts (haunt_anchors `wear_origin`).
static func _ringed_world(a: _Acc) -> void:
	var z := Z_ART + 1
	var c := WORLD_C
	var r := WORLD_R
	var tilt := -0.3
	a.keyed_stroke(&"world_ring_back", arc_pts(c, 52, 11, tilt, PI, TAU, 22), &"yellow", z, 4.0)
	a.fill(&"world", circle_pts(c, r, 36), &"magenta", z + 2, false)
	var bands: Array[float] = [-15.0, 0.0, 13.0]
	var band_ink: Array[StringName] = [&"warm_red", &"cream", &"warm_red"]
	var band_w: Array[float] = [3.5, 4.5, 3.0]
	for i in bands.size():
		var bc := c + Vector2(0, bands[i]).rotated(tilt)
		var rx := sqrt(r * r - bands[i] * bands[i]) - 1.0
		a.stroke(StringName("world_band_%d" % i), arc_pts(bc, rx, 4.0, tilt, 0.0, PI, 16), band_ink[i], z + 3, band_w[i])
	a.tone_radial(&"world_shade_wide", crescent_pts(c, r, -0.5, 2.7, 22), &"navy", z + 4, c, 6.0, r, 0.0, 0.95)
	a.fill(&"world_shade", crescent_pts(c, r, -0.3, 2.5, 9), &"navy", z + 5, false)
	a.outline(&"world_line", circle_pts(c, r, 36), &"key_black", z + 6)
	a.keyed_stroke(&"world_ring_front", arc_pts(c, 52, 11, tilt, 0.0, PI, 22), &"yellow", z + 7, 4.0)
	a.stroke(&"world_ring_shine", arc_pts(c, 50, 9.6, tilt, 0.4, PI - 0.4, 18), &"cream", z + 9, 0.9)


## The Choir's road: a dark crag of Glass-veined rock rising from the lower outer corner.
static func _crag(a: _Acc) -> void:
	var z := Z_ART + 30
	var crag := PackedVector2Array([Vector2(70, 368), Vector2(76, 326), Vector2(86, 300), Vector2(90, 272), Vector2(100, 250),
		Vector2(104, 226), Vector2(118, 206), Vector2(128, 186), Vector2(W + 8, 170), Vector2(W + 8, 368)])
	a.fill(&"crag", crag, &"navy", z, false)
	a.tone_linear(&"crag_light", crag, &"cyan", z + 1, Vector2(150, 180), Vector2(100, 330), 0.4, 0.0)
	a.tone_linear(&"crag_dark", crag, &"key_black", z + 1, Vector2(150, 300), Vector2(110, 200), 0.85, 0.0)
	a.keyed_stroke(&"crag_rim", crag.slice(0, 9), &"cyan", z + 2, 1.4)
	_geode(a, "crag_geode_a", Vector2(134, 228), 12.0, -1.9, 13, z + 4)
	_geode(a, "crag_geode_b", Vector2(120, 300), 10.0, -2.6, 17, z + 4)
	_geode(a, "crag_geode_c", Vector2(84, 238), 8.0, -0.9, 19, z + 4)


## The Choir's procession up the crag, printed bigger than life (2× a monk).
static func _choir_procession(a: _Acc) -> void:
	var z := Z_ART + 46
	var feet: Array[Vector2] = [Vector2(82, 324), Vector2(90, 298), Vector2(96, 272), Vector2(106, 248), Vector2(124, 206)]
	var face: Array[int] = [1, 1, 0, 1, 1]
	var glass: Array[StringName] = [&"cyan", &"cream", &"cyan", &"cream", &"cyan"]
	a.place(2.0, Vector2.ZERO)
	for i in feet.size():
		_monk(a, StringName("march_monk_%d" % (i + 1)), feet[i] * 0.5, face[i], glass[i], z + i * 6)
	a.place(1.0, Vector2.ZERO)


## The right column's hero: a big Oubliette Grub (ART-001 §2: teardrop, four small limbs, a shard held
## overhead) facing the screen with Mourning Glass raised, its swarm trailing behind. A hooded hollow for a face:
## no eyes on the print near the world (N4 caution). Feet hidden behind the NEW! sticker.
static func _grub_swarm(a: _Acc) -> void:
	_grub(a, "grub_hero", GRUB_FEET, GRUB_SCALE, Z_ART + 40, true)
	var feet: Array[Vector2] = [Vector2(88, 214), Vector2(104, 196), Vector2(80, 182)]
	var sc: Array[float] = [0.2, 0.16, 0.14]
	for i in feet.size():
		_grub(a, "grub_swarm_%d" % i, feet[i], sc[i], Z_ART + 34 + i, false)


## One Grub drawn feet-at-origin facing left (toward the screen), scaled by `s` about its feet.
static func _grub(a: _Acc, id: String, feet: Vector2, s: float, z: int, hero: bool) -> void:
	var body := arc_pts(Vector2(0, -30), 28, 28, 0.0, -0.75, PI + 0.75, 18)
	body.append_array(PackedVector2Array([Vector2(-14, -70), Vector2(0, -88), Vector2(14, -96), Vector2(20, -80), Vector2(22, -62)]))
	a.keyed_stroke(StringName("%s_arm_back" % id), _gx([Vector2(8, -70), Vector2(2, -90), Vector2(-6, -104)], feet, s), &"magenta", z, 3.5 * s / 0.8)
	a.fill(StringName("%s_leg_a" % id), _gx([Vector2(-13, -4), Vector2(-7, -4), Vector2(-6, 1), Vector2(-14, 1)], feet, s), &"navy", z + 1)
	a.fill(StringName("%s_leg_b" % id), _gx([Vector2(5, -4), Vector2(11, -4), Vector2(12, 1), Vector2(4, 1)], feet, s), &"navy", z + 1)
	a.fill(StringName("%s_body" % id), _gx(Array(body), feet, s), &"magenta", z + 2)
	if hero:
		a.fill(StringName("%s_belly" % id), _gx(Array(crescent_pts(Vector2(0, -30), 28, PI * 0.5, PI * 1.15, 9, 12)), feet, s), &"cream", z + 3, false)
	a.tone_linear(StringName("%s_body_shade" % id), _gx(Array(body), feet, s), &"navy", z + 3, feet + Vector2(4, -40) * s, feet + Vector2(26, -40) * s, 0.0, 0.7)
	a.fill(StringName("%s_hood" % id), _gx([Vector2(-19, -58), Vector2(-14, -71), Vector2(-3, -77), Vector2(1, -67), Vector2(-3, -57), Vector2(-12, -52)], feet, s), &"key_black", z + 4)
	a.keyed_stroke(StringName("%s_arm_front" % id), _gx([Vector2(-17, -50), Vector2(-26, -78), Vector2(-18, -102)], feet, s), &"magenta", z + 5, 3.5 * s / 0.8)
	var shard := _gx([Vector2(-12, -142), Vector2(-1, -120), Vector2(-8, -100), Vector2(-20, -104), Vector2(-25, -124)], feet, s)
	a.fill(StringName("%s_glass" % id), shard, &"cyan", z + 7)
	if not hero:
		return
	a.stroke(StringName("%s_hood_rim" % id), _gx([Vector2(-21, -58), Vector2(-15, -73), Vector2(-3, -79)], feet, s), &"cream", z + 6, 1.4)
	a.tone_linear(StringName("%s_glass_shade" % id), _gx([Vector2(-12, -142), Vector2(-1, -120), Vector2(-8, -100)], feet, s), &"navy", z + 8,
		feet + Vector2(-2, -118) * s, feet + Vector2(-12, -120) * s, 0.8, 0.0)
	a.stroke(StringName("%s_glass_glint" % id), _gx([Vector2(-15, -133), Vector2(-17, -110)], feet, s), &"cream", z + 9, 1.4)
	a.fill(StringName("%s_spark_a" % id), star_pts(feet + Vector2(-32, -140) * s, 5.0, 1.2, 4), &"cream", z + 9, false)
	a.fill(StringName("%s_spark_b" % id), star_pts(feet + Vector2(6, -134) * s, 3.5, 0.9, 4, 0.5), &"yellow", z + 9, false)


## Grub-local points to column-local: scaled by `s` about the feet.
static func _gx(pts: Array, feet: Vector2, s: float) -> PackedVector2Array:
	var out := PackedVector2Array()
	for p: Vector2 in pts:
		out.append(feet + p * s)
	return out


## The coin door seated in a printed cut-out: a yellow and red band round the opening with a key-black
## keyline (period bezels frame the door; Fable review 2026-11-20). The NEW! sticker sits clear above it.
static func _coin_door_backing(a: _Acc) -> void:
	var z := Z_ART + 52
	var hole := Rect2(6, 249, 68, 87)
	var outer := hole.grow_individual(5.0, 7.0, 5.0, 0.0)
	a.rect(&"door_cutout_band", outer, &"yellow", z)
	a.rect(&"door_cutout_inner", hole.grow_individual(2.5, 3.5, 2.5, 0.0), &"warm_red", z + 1)
	a.outline(&"door_cutout_key", rect_pts(outer), &"key_black", z + 2)
	a.rect(&"door_frame", hole, &"key_black", z + 3)


## The maker's badge, bottom right (period bezels carry the manufacturer's mark): a lantern glyph and the
## maker's name in cream on a key-black plate.
static func _maker_badge(a: _Acc) -> void:
	var z := Z_WINDOW + 10
	var x0 := CabinetBezel.POWER_LOCAL.end.x + 3.0                   # right of the POWER rocker
	var x1 := W - STRIPE_X[STRIPE_X.size() - 1] - 3.0               # inside the pinstripes
	var cap := howto_cap(["CAB_BEZEL_MAKER"], x1 - x0 - 13.0, 3.6)
	var sz := BezelText.painted_size(TranslationServer.translate("CAB_BEZEL_MAKER"), cap, 0.8, 0.6)
	var plate := Rect2(x0, 333.0, minf(sz.x + 13.0, x1 - x0), 12.0)
	a.rect(&"maker_plate", plate, &"key_black", z)
	a.outline(&"maker_plate_rim", rect_pts(plate.grow(-1.2)), &"brass", z + 1)
	var lx := plate.position.x + 5.0
	var ly := plate.get_center().y
	var lantern := PackedVector2Array([Vector2(lx - 2, ly - 3), Vector2(lx + 2, ly - 3), Vector2(lx + 2.6, ly + 3), Vector2(lx - 2.6, ly + 3)])
	a.fill(&"maker_lantern", lantern, &"yellow", z + 2)
	a.rect(&"maker_lantern_cap", Rect2(lx - 1.2, ly - 4.6, 2.4, 1.4), &"brass", z + 2)
	a.text(&"maker_name", "CAB_BEZEL_MAKER", Vector2(lx + 5.0, ly - cap * 0.5), &"cream", z + 3, cap, 0.8, false, 0.6)
