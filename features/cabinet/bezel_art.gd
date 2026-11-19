class_name BezelArt
extends RefCounted
## The Cabinet bezel's printed art as data (owner decision D-B; TECH-001 §1.3): `build_left()` and
## `build_right()` return the sorted BezelPiece list for one 80 × 360 column, in column-local
## coordinates. Everything is hand-placed and deterministic: scatter uses a pure integer hash,
## never an RNG. The lists are the seam the later "zoom destruction" (peel, crack, curl, decay)
## drives piece by piece: each piece has an id, a z and a pivot.
##
## Left: the Vigil as a rocket-skiff and the how-to-play card. Right: the Sepulchre as a reliquary moon
## with one slit eye, the starburst sticker and the coin-door backing. No readout windows: the live
## readouts are lit on the screen strip. The 2 px nearest the screen is a key-black lip.

const L := &"left"
const R := &"right"

## The how-to-play card's lines (en.po). Each must fit the card's 72 px at 1× (tested).
const HOWTO_KEYS: Array[String] = ["CAB_HOWTO_1", "CAB_HOWTO_2", "CAB_HOWTO_3", "CAB_HOWTO_4"]

const Z_BG := 0
const Z_STARS := 5
const Z_ART := 20          ## illustrations use Z_ART … Z_ART + 40
const Z_CARD := 30
const Z_WINDOW := 70
const Z_CAP := 80
const Z_LIP := 90
const Z_GLARE := 100


## Collects pieces for one column and keeps the build order for stable sorting.
class _Acc extends RefCounted:
	var col: StringName
	var items: Array[BezelPiece] = []

	func _init(p_col: StringName) -> void:
		col = p_col

	func add(id: StringName, kind: int, pts: PackedVector2Array, ink: StringName, z: int, width: float = 1.0) -> BezelPiece:
		var b := BezelPiece.make(StringName("%s_%s" % [col, id]), col, kind, pts, ink, z)
		b.width = width
		b.order = items.size()
		items.append(b)
		return b

	func fill(id: StringName, pts: PackedVector2Array, ink: StringName, z: int) -> void:
		add(id, BezelPiece.Kind.FILL, pts, ink, z)

	func rect(id: StringName, r: Rect2, ink: StringName, z: int) -> void:
		add(id, BezelPiece.Kind.FILL, PackedVector2Array([r.position, Vector2(r.end.x, r.position.y), r.end, Vector2(r.position.x, r.end.y)]), ink, z)

	func outline(id: StringName, pts: PackedVector2Array, ink: StringName, z: int) -> void:
		add(id, BezelPiece.Kind.OUTLINE, pts, ink, z)

	func stroke(id: StringName, pts: PackedVector2Array, ink: StringName, z: int, width: float = 1.0) -> void:
		add(id, BezelPiece.Kind.STROKE, pts, ink, z, width)

	func halftone(id: StringName, pts: PackedVector2Array, ink: StringName, z: int) -> void:
		add(id, BezelPiece.Kind.HALFTONE, pts, ink, z)

	func pixels(id: StringName, pts: PackedVector2Array, ink: StringName, z: int, size: float = 1.0) -> void:
		add(id, BezelPiece.Kind.PIXELS, pts, ink, z, size)

	## Centred 1× PixelText: `anchor` is (centre x, top y); the string comes from tr(key) at draw time.
	func text(id: StringName, key: String, anchor: Vector2, ink: StringName, z: int) -> void:
		var b := add(id, BezelPiece.Kind.TEXT, PackedVector2Array([anchor]), ink, z)
		b.text_key = key
		b.centered = true


static func build_left() -> Array[BezelPiece]:
	var a := _Acc.new(L)
	var covered: Array[Rect2] = [CabinetBezel.LEFT_ART, CabinetBezel.LEFT_HOWTO]
	_background(a, covered)
	_vigil_illustration(a, CabinetBezel.LEFT_ART)
	_howto_card(a, CabinetBezel.LEFT_HOWTO)
	_lip(a, 78.0)
	return sorted(a.items)


static func build_right() -> Array[BezelPiece]:
	var a := _Acc.new(R)
	var covered: Array[Rect2] = [CabinetBezel.RIGHT_ART, CabinetBezel.RIGHT_STICKER, Rect2(6, 249, 68, 100)]
	_background(a, covered)
	_sepulchre_illustration(a, CabinetBezel.RIGHT_ART)
	_coin_door_backing(a)
	_lip(a, 0.0)
	return sorted(a.items)


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

static func _background(a: _Acc, covered: Array[Rect2]) -> void:
	a.rect(&"field", Rect2(0, 0, 80, 360), &"navy", Z_BG)
	var avoid: Array[Rect2] = []
	for r in covered:
		avoid.append(r.grow(2))
	avoid.append(Rect2(0, 0, 80, 12))
	avoid.append(Rect2(0, 348, 80, 12))
	var seed_i := 1 if a.col == L else 2
	a.pixels(&"stars_cream", scatter(Rect2(0, 0, 80, 360), 14, seed_i, avoid), &"cream", Z_STARS)
	a.pixels(&"stars_yellow", scatter(Rect2(0, 0, 80, 360), 8, seed_i + 10, avoid), &"yellow", Z_STARS)
	var burst_y: Array[float] = [63.5, 106.0, 234.0]
	if a.col != L:
		burst_y = [63.5, 122.0, 180.0]
	for i in burst_y.size():
		a.fill(StringName("sparkle_%d" % i), star_pts(Vector2(40, burst_y[i]), 2.5, 0.6, 4), &"yellow", Z_STARS + 1)


## The key-black screen lip: the 2 px strip nearest the field.
static func _lip(a: _Acc, x: float) -> void:
	a.rect(&"lip", Rect2(x, 0, 2, 360), &"key_black", Z_LIP)


## A 1 px framed panel for an illustration: background and frame.
static func _panel(a: _Acc, id: StringName, r: Rect2) -> void:
	a.rect(StringName("%s_bg" % id), r, &"navy", Z_ART)
	a.outline(StringName("%s_frame" % id), rect_pts(Rect2(r.position, r.size - Vector2.ONE)), &"key_black", Z_ART + 38)


## A Choir monk about 8 px tall. `face`: -1 / +1 hood in profile toward that side, 0 faces the player.
static func _monk(a: _Acc, id: StringName, feet: Vector2, face: int, glass_ink: StringName, z: int) -> void:
	var robe: PackedVector2Array
	if face == 0:
		robe = PackedVector2Array([Vector2(-3, 0), Vector2(3, 0), Vector2(3, -3), Vector2(2, -6), Vector2(0, -8), Vector2(-2, -6), Vector2(-3, -3)])
	else:
		var s := float(face)
		robe = PackedVector2Array([Vector2(-3 * s, 0), Vector2(3 * s, 0), Vector2(3 * s, -3), Vector2(2 * s, -5), Vector2(0, -7), Vector2(-1 * s, -8), Vector2(-2 * s, -5)])
	a.fill(StringName("%s_robe" % id), xf(robe, feet, 0.0), &"magenta", z)
	a.outline(StringName("%s_line" % id), xf(robe, feet, 0.0), &"key_black", z + 1)
	if face == 0:
		a.rect(StringName("%s_face" % id), Rect2(feet + Vector2(-2, -6), Vector2(4, 3)), &"key_black", z + 2)
		a.pixels(StringName("%s_eyes" % id), PackedVector2Array([feet + Vector2(-2, -5), feet + Vector2(1, -5)]), &"cream", z + 3)
	else:
		var fx := 1.0 if face > 0 else -2.0
		a.rect(StringName("%s_face" % id), Rect2(feet + Vector2(fx, -5), Vector2(1, 2)), &"key_black", z + 2)
	var glass_at := feet + (Vector2(0, -1) if face == 0 else Vector2(4.0 * face, -2))
	var diamond := PackedVector2Array([glass_at + Vector2(0, -2), glass_at + Vector2(2, 0), glass_at + Vector2(0, 2), glass_at + Vector2(-2, 0)])
	a.fill(StringName("%s_glass" % id), diamond, glass_ink, z + 4)
	a.outline(StringName("%s_glass_line" % id), diamond, &"key_black", z + 5)


# --- LEFT: the Vigil ----------------------------------------------------------------------------

static func _vigil_illustration(a: _Acc, r: Rect2) -> void:
	_panel(a, &"vigil", r)
	var z := Z_ART + 1
	var keep_clear: Array[Rect2] = [Rect2(14, 140, 40, 40)]
	# vignette: key-black halftone in two corners
	a.halftone(&"vigil_vignette_tl", PackedVector2Array([r.position, r.position + Vector2(30, 0), r.position + Vector2(0, 30)]), &"key_black", z)
	a.halftone(&"vigil_vignette_br", PackedVector2Array([r.end, r.end - Vector2(34, 0), r.end - Vector2(0, 34)]), &"key_black", z)
	a.pixels(&"vigil_stars", scatter(r.grow(-2), 16, 21, keep_clear), &"cream", z + 1)
	a.pixels(&"vigil_stars_y", scatter(r.grow(-2), 6, 31, keep_clear), &"yellow", z + 1)
	# starbursts
	a.fill(&"vigil_burst_a", star_pts(Vector2(66, 124), 6, 1.6, 4), &"yellow", z + 2)
	a.outline(&"vigil_burst_a_line", star_pts(Vector2(66, 124), 6, 1.6, 4), &"key_black", z + 3)
	a.fill(&"vigil_burst_b", star_pts(Vector2(10, 206), 4, 1.2, 4), &"yellow", z + 2)
	a.fill(&"vigil_burst_c", star_pts(Vector2(68, 220), 4, 1.2, 4), &"yellow", z + 2)
	# hidden wrongness: one of the "stars" is a black hole with a thin cream ring
	a.fill(&"vigil_hole", circle_pts(Vector2(52, 118), 3.0, 14), &"key_black", z + 2)
	a.outline(&"vigil_hole_ring", circle_pts(Vector2(52, 118), 4.0, 16), &"cream", z + 3)
	# the ringed planet, small and up-left so the skiff silhouette reads on open navy
	var pc := Vector2(23, 129)
	var ring_rot := -0.38
	a.stroke(&"vigil_ring_back_line", arc_pts(pc, 18, 5, ring_rot, PI, TAU, 18), &"key_black", z + 4, 5.0)
	a.stroke(&"vigil_ring_back", arc_pts(pc, 18, 5, ring_rot, PI, TAU, 18), &"magenta", z + 5, 3.0)
	a.fill(&"vigil_planet", circle_pts(pc, 11, 22), &"process_blue", z + 6)
	a.halftone(&"vigil_planet_shade_wide", crescent_pts(pc, 11, -0.4, 2.6, 9), &"navy", z + 7)
	a.fill(&"vigil_planet_shade", crescent_pts(pc, 11, -0.2, 2.4, 4.5), &"navy", z + 8)
	a.halftone(&"vigil_planet_shade_deep", crescent_pts(pc, 11, 0.1, 2.1, 2.5), &"key_black", z + 9)
	a.outline(&"vigil_planet_line", circle_pts(pc, 11, 22), &"key_black", z + 10)
	a.stroke(&"vigil_ring_front_line", arc_pts(pc, 18, 5, ring_rot, 0.0, PI, 18), &"key_black", z + 11, 5.0)
	a.stroke(&"vigil_ring_front", arc_pts(pc, 18, 5, ring_rot, 0.0, PI, 18), &"magenta", z + 12, 3.0)
	# the Vigil, diving nose-first down and to the right
	var d := Vector2(0.6, 0.8)
	var centre := Vector2(46, 178)
	var rot := Vector2(0, -1).angle_to(d)
	# speed lines trail up-left
	var perp := Vector2(0.8, -0.6)
	var offs: Array[float] = [-16.0, -8.0, 0.0, 8.0, 16.0]
	var lens: Array[float] = [14.0, 22.0, 26.0, 18.0, 14.0]
	for i in offs.size():
		var s0 := centre - d * 20.0 + perp * offs[i]
		a.stroke(StringName("vigil_speed_%d" % i), PackedVector2Array([s0, s0 - d * lens[i]]), &"cream" if i % 2 == 0 else &"yellow", z + 13, 1.0)
	a.fill(&"vigil_flame", xf(PackedVector2Array([Vector2(-6, 9), Vector2(0, 32), Vector2(6, 9)]), centre, rot), &"orange", z + 14)
	a.fill(&"vigil_flame_core", xf(PackedVector2Array([Vector2(-3, 9), Vector2(0, 22), Vector2(3, 9)]), centre, rot), &"yellow", z + 15)
	var hull := PackedVector2Array([Vector2(0, -26), Vector2(20, 16), Vector2(0, 8), Vector2(-20, 16)])
	a.fill(&"vigil_hull", xf(hull, centre, rot), &"yellow", z + 16)
	a.halftone(&"vigil_hull_shade", xf(PackedVector2Array([Vector2(0, -26), Vector2(20, 16), Vector2(0, 8)]), centre, rot), &"warm_red", z + 17)
	a.fill(&"vigil_fin_r", xf(PackedVector2Array([Vector2(12, -1), Vector2(20, 16), Vector2(0, 8), Vector2(5, 3)]), centre, rot), &"warm_red", z + 18)
	a.fill(&"vigil_fin_l", xf(PackedVector2Array([Vector2(-12, -1), Vector2(-20, 16), Vector2(0, 8), Vector2(-5, 3)]), centre, rot), &"warm_red", z + 18)
	a.outline(&"vigil_hull_line", xf(hull, centre, rot), &"key_black", z + 19)
	a.stroke(&"vigil_keel", xf(PackedVector2Array([Vector2(0, -20), Vector2(0, 7)]), centre, rot), &"key_black", z + 19)
	var cockpit := centre + Vector2(0, -4).rotated(rot)
	a.fill(&"vigil_cockpit", circle_pts(cockpit, 5, 14), &"chrome_dark", z + 20)
	a.fill(&"vigil_cockpit_glint", circle_pts(cockpit + Vector2(-1.5, -1.5), 2.5, 10), &"chrome_light", z + 21)
	a.outline(&"vigil_cockpit_line", circle_pts(cockpit, 5, 14), &"key_black", z + 22)
	a.pixels(&"vigil_cockpit_spark", PackedVector2Array([cockpit + Vector2(-2, -3)]), &"cream", z + 23)
	# the cyan lance bolt from the nose toward the screen
	var nose := centre + d * 26.0
	var bolt := PackedVector2Array([nose, nose + d * 8.0 + perp * 3.0, nose + d * 15.0 - perp * 3.0, nose + d * 23.0])
	a.stroke(&"vigil_bolt_line", bolt, &"key_black", z + 24, 5.0)
	a.stroke(&"vigil_bolt", bolt, &"cyan", z + 25, 3.0)
	a.stroke(&"vigil_bolt_core", bolt, &"cream", z + 26, 1.0)
	a.fill(&"vigil_muzzle", star_pts(nose, 5, 1.5, 4, 0.3), &"cream", z + 27)


# --- LEFT: how to play --------------------------------------------------------------------------

static func _howto_card(a: _Acc, r: Rect2) -> void:
	var z := Z_CARD
	var cut := PackedVector2Array([r.position, Vector2(r.end.x - 6, r.position.y), Vector2(r.end.x, r.position.y + 6), r.end, Vector2(r.position.x, r.end.y)])
	a.fill(&"howto_shadow", xf(cut, Vector2(1, 1), 0.0), &"key_black", z)
	a.fill(&"howto_card", cut, &"cream", z + 1)
	a.outline(&"howto_line", cut, &"key_black", z + 2)
	a.rect(&"howto_band", Rect2(r.position + Vector2(1, 1), Vector2(r.size.x - 8, 14)), &"yellow", z + 2)
	a.text(&"howto_title", "CAB_HOWTO_TITLE", Vector2(r.position.x + 1.0 + (r.size.x - 8.0) * 0.5, r.position.y + 5), &"key_black", z + 3)
	a.rect(&"howto_rule", Rect2(r.position + Vector2(4, 18), Vector2(r.size.x - 8, 1)), &"key_black", z + 3)
	for i in HOWTO_KEYS.size():
		a.text(StringName("howto_line_%d" % (i + 1)), HOWTO_KEYS[i], Vector2(r.get_center().x, r.position.y + 24 + i * 10), &"key_black", z + 3)
	# the pictogram strip: glass -> charge -> Sepulchre
	var y := r.end.y - 14.0
	var glass := PackedVector2Array([Vector2(16, y - 4), Vector2(20, y), Vector2(16, y + 4), Vector2(12, y)])
	a.fill(&"howto_pic_glass", glass, &"cyan", z + 3)
	a.outline(&"howto_pic_glass_line", glass, &"key_black", z + 4)
	a.stroke(&"howto_pic_arrow_1", PackedVector2Array([Vector2(24, y), Vector2(31, y)]), &"key_black", z + 3)
	a.fill(&"howto_pic_charge", star_pts(Vector2(40, y), 5, 2, 4), &"orange", z + 3)
	a.outline(&"howto_pic_charge_line", star_pts(Vector2(40, y), 5, 2, 4), &"key_black", z + 4)
	a.stroke(&"howto_pic_arrow_2", PackedVector2Array([Vector2(48, y), Vector2(55, y)]), &"key_black", z + 3)
	a.fill(&"howto_pic_moon", circle_pts(Vector2(64, y), 4.5, 12), &"process_blue", z + 3)
	a.outline(&"howto_pic_moon_line", circle_pts(Vector2(64, y), 4.5, 12), &"key_black", z + 4)
	a.rect(&"howto_pic_moon_eye", Rect2(60, y - 1, 8, 1), &"key_black", z + 5)


# --- RIGHT: the Sepulchre -----------------------------------------------------------------------

static func _sepulchre_illustration(a: _Acc, r: Rect2) -> void:
	_panel(a, &"sep", r)
	var z := Z_ART + 1
	var keep_clear: Array[Rect2] = [Rect2(14, 128, 48, 48)]
	a.halftone(&"sep_vignette_tl", PackedVector2Array([r.position, r.position + Vector2(22, 0), r.position + Vector2(0, 22)]), &"key_black", z)
	a.halftone(&"sep_vignette_br", PackedVector2Array([r.end, r.end - Vector2(22, 0), r.end - Vector2(0, 22)]), &"key_black", z)
	a.pixels(&"sep_stars", scatter(r.grow(-2), 12, 41, keep_clear), &"cream", z + 1)
	a.pixels(&"sep_stars_y", scatter(r.grow(-2), 4, 51, keep_clear), &"yellow", z + 1)
	var c := Vector2(38, 152)
	var rad := 21.0
	a.fill(&"sep_moon", circle_pts(c, rad, 32), &"process_blue", z + 2)
	a.halftone(&"sep_moon_shade_wide", crescent_pts(c, rad, -0.5, 2.7, 17), &"navy", z + 3)
	a.fill(&"sep_moon_shade", crescent_pts(c, rad, -0.3, 2.5, 9), &"navy", z + 4)
	a.halftone(&"sep_moon_shade_deep", crescent_pts(c, rad, 0.0, 2.2, 5), &"key_black", z + 5)
	a.stroke(&"sep_moon_glint", arc_pts(c, rad - 3, rad - 3, 0.0, 3.6, 4.4, 5), &"cream", z + 6)
	# two brass reliquary bands crossing it (front halves of tilted rings)
	for i in 2:
		var tilt := 0.45 if i == 0 else -0.45
		var band := arc_pts(c, 23, 8, tilt, 0.0, PI, 18)
		a.stroke(StringName("sep_band_%d_line" % i), band, &"key_black", z + 7, 5.0)
		a.stroke(StringName("sep_band_%d" % i), band, &"brass", z + 8, 3.0)
		a.stroke(StringName("sep_band_%d_light" % i), arc_pts(c + Vector2(0, -1), 23, 8, tilt, 0.1, PI - 0.1, 18), &"yellow", z + 9, 1.0)
	a.pixels(&"sep_studs", PackedVector2Array([c + Vector2(0, 7), c + Vector2(-9, 4), c + Vector2(9, 4)]), &"cream", z + 10, 1.0)
	a.outline(&"sep_moon_line", circle_pts(c, rad, 32), &"key_black", z + 11)
	# ONE horizontal slit eye: key black with a warm_red lid line
	var eye_c := c + Vector2(0, -6)
	var eye := PackedVector2Array()
	for i in 13:
		var k := float(i) / 12.0
		eye.append(eye_c + Vector2(lerpf(-11, 11, k), -sin(k * PI) * 2.5))
	for i in range(12, -1, -1):
		var k := float(i) / 12.0
		eye.append(eye_c + Vector2(lerpf(-11, 11, k), sin(k * PI) * 2.0))
	a.fill(&"sep_eye", eye, &"key_black", z + 12)
	var lid := PackedVector2Array()
	for i in 13:
		var k := float(i) / 12.0
		lid.append(eye_c + Vector2(lerpf(-11, 11, k), -sin(k * PI) * 2.5 - 1.0))
	a.stroke(&"sep_eye_lid", lid, &"warm_red", z + 13)
	# the Choir monks climb toward it; the third faces the player
	var monk_x: Array[float] = [10.0, 17.0, 66.0, 60.0, 12.0]
	var monk_y: Array[float] = [172.0, 161.0, 173.0, 163.0, 146.0]
	var monk_face: Array[int] = [1, 1, 0, -1, 1]
	var monk_glass: Array[StringName] = [&"cream", &"cyan", &"cream", &"cyan", &"cream"]
	for i in monk_x.size():
		_monk(a, StringName("sep_monk_%d" % (i + 1)), Vector2(monk_x[i], monk_y[i]), monk_face[i], monk_glass[i], z + 20 + i * 6)
	# one more monk, standing on the coin door's top edge
	_monk(a, &"door_monk", Vector2(16, 252), -1, &"cyan", Z_WINDOW + 5)



static func _coin_door_backing(a: _Acc) -> void:
	var z := Z_ART
	a.rect(&"door_frame", Rect2(6, 249, 68, 87), &"key_black", z)
	a.rect(&"door_frame_face", Rect2(7, 250, 66, 85), &"key_black", z + 1)
