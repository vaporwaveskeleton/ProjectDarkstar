class_name VectorText
extends RefCounted
## Pure, static layout for code-generated stroke text (no node, no scene, no RNG streams).
## Text -> polylines in logical px. Sharp at any resolution because the strokes are re-tessellated
## by the renderer, not rasterised here. VectorLabel draws it; the Act 0 bezel and every
## post-Act 0 surface use it (PixelText stays on the 256x304 arcade screen; TECH-001 Q-T23).

enum Align { LEFT, CENTER, RIGHT }

const DEFAULT_GLYPHS_PATH := "res://data/ui/vector_glyphs.tres"
const DEFAULT_FACE_PATH := "res://data/ui/vector_face.tres"
const GRAIN_STEP := 2.5          ## px between grain points on a stroke
const JOIN_TURN := 0.1           ## radians; smaller turns need no round join
const CAP_SEGMENTS := 16
const MIN_PHYSICAL_STROKE := 1.25   ## px on screen; thinner strokes can miss every pixel centre

static var _default_glyphs: VectorGlyphSet
static var _default_face: VectorFace


## One placed character after the glyph filter has been applied.
class Cell extends RefCounted:
	var ch := ""                              ## shown character
	var index := 0                            ## index in the source text
	var strokes: Array[PackedVector2Array] = []
	var adv := 0.0                            ## em
	var right := 0.0                          ## em, ink right edge
	var is_space := false
	var has_glyph := true


static func default_glyphs() -> VectorGlyphSet:
	if _default_glyphs == null:
		_default_glyphs = load(DEFAULT_GLYPHS_PATH) as VectorGlyphSet
	return _default_glyphs


static func default_face() -> VectorFace:
	if _default_face == null:
		_default_face = load(DEFAULT_FACE_PATH) as VectorFace
	return _default_face


## Ink size of the text, wrapping at max_width px when > 0.
static func measure(text: String, glyphs: VectorGlyphSet, face: VectorFace, max_width: float = 0.0, glyph_filter: Callable = Callable()) -> Vector2:
	return _layout(text, glyphs, face, Align.LEFT, max_width, glyph_filter, false).size


## Lays the text out as polylines in logical px. Lines break on a newline and, if max_width > 0, at
## spaces. glyph_filter(ch, index) may return a replacement char (String), replacement strokes
## (Array[PackedVector2Array], em units) or null to keep the glyph (the glyph-lie seam).
static func layout(text: String, glyphs: VectorGlyphSet, face: VectorFace, align: int = Align.LEFT, max_width: float = 0.0, glyph_filter: Callable = Callable()) -> VectorLayout:
	return _layout(text, glyphs, face, align, max_width, glyph_filter, true)


static func _layout(text: String, glyphs: VectorGlyphSet, face: VectorFace, align: int, max_width: float, glyph_filter: Callable, build: bool) -> VectorLayout:
	var out := VectorLayout.new()
	var size: float = face.size
	out.ascent = glyphs.baseline * size
	out.descent = glyphs.descent * size
	out.line_height = (glyphs.baseline + glyphs.descent + glyphs.line_gap) * size

	# 1. Resolve every character, then split into paragraphs at line breaks.
	var paragraphs: Array = [[]]
	for i in text.length():
		var c: String = text[i]
		if c == "\r":
			continue
		if c == "\n":
			paragraphs.append([])
			continue
		var cell: Cell = _resolve(c, i, glyphs, glyph_filter)
		if not cell.has_glyph and not out.missing.has(c):
			out.missing.append(c)
		(paragraphs[paragraphs.size() - 1] as Array).append(cell)

	# 2. Wrap each paragraph into lines.
	var lines: Array = []
	for para: Array in paragraphs:
		if max_width > 0.0:
			lines.append_array(_wrap(para, glyphs, face, max_width))
		else:
			lines.append(para)

	# 3. Measure lines, then place them.
	var widest := 0.0
	var widths: Array[float] = []
	for line: Array in lines:
		var w: float = _line_width(line, glyphs, face)
		widths.append(w)
		widest = maxf(widest, w)
	out.box_width = max_width if max_width > 0.0 else widest
	var factor: float = 0.0
	if align == Align.CENTER:
		factor = 0.5
	elif align == Align.RIGHT:
		factor = 1.0
	for li in lines.size():
		var line: Array = lines[li]
		out.line_widths.append(widths[li])
		out.lines.append(_line_text(line))
		if not build:
			continue
		var pen: float = (out.box_width - widths[li]) * factor
		var base_y: float = float(li) * out.line_height
		var prev: Cell = null
		for cell: Cell in line:
			if prev != null:
				pen += glyphs.get_kerning(prev.ch, cell.ch) * size + face.tracking
			_place(out, cell, pen, base_y, face)
			pen += cell.adv * size
			prev = cell
	out.size = Vector2(widest, out.ascent + out.descent + float(maxi(lines.size() - 1, 0)) * out.line_height)
	return out


static func _resolve(c: String, index: int, glyphs: VectorGlyphSet, glyph_filter: Callable) -> Cell:
	var cell := Cell.new()
	cell.index = index
	cell.ch = c
	cell.is_space = c == " "
	cell.has_glyph = glyphs.has_glyph(c)
	cell.adv = glyphs.get_advance(c)
	cell.right = glyphs.get_ink_right(c)
	cell.strokes = glyphs.get_strokes(c)
	if glyph_filter.is_valid():
		var r: Variant = glyph_filter.call(c, index)
		if r is String:
			var rs: String = r
			if rs.length() > 0:
				cell.ch = rs.substr(0, 1)
				cell.is_space = cell.ch == " "
				cell.has_glyph = glyphs.has_glyph(cell.ch)
				cell.adv = glyphs.get_advance(cell.ch)
				cell.right = glyphs.get_ink_right(cell.ch)
				cell.strokes = glyphs.get_strokes(cell.ch)
		elif r is Array:
			var arr: Array = r
			var strokes: Array[PackedVector2Array] = []
			var right := 0.0
			for e: Variant in arr:
				if e is PackedVector2Array:
					var pv: PackedVector2Array = e
					strokes.append(pv)
					for p in pv:
						right = maxf(right, p.x)
			cell.strokes = strokes
			cell.right = right
			cell.has_glyph = true
	if cell.is_space:
		cell.right = 0.0
	return cell


static func _line_width(line: Array, glyphs: VectorGlyphSet, face: VectorFace) -> float:
	var pen := 0.0
	var width := 0.0
	var prev: Cell = null
	for cell: Cell in line:
		if prev != null:
			pen += glyphs.get_kerning(prev.ch, cell.ch) * face.size + face.tracking
		if not cell.is_space:
			width = maxf(width, pen + cell.right * face.size)
		pen += cell.adv * face.size
		prev = cell
	return width


static func _line_text(line: Array) -> String:
	var s := ""
	for cell: Cell in line:
		s += cell.ch
	return s


## Greedy word wrap of one paragraph. A word longer than the width gets a line to itself.
static func _wrap(para: Array, glyphs: VectorGlyphSet, face: VectorFace, max_width: float) -> Array:
	var lines: Array = []
	var cur: Array = []
	var i := 0
	var n: int = para.size()
	while i < n:
		var spaces: Array = []
		while i < n and (para[i] as Cell).is_space:
			spaces.append(para[i])
			i += 1
		var word: Array = []
		while i < n and not (para[i] as Cell).is_space:
			word.append(para[i])
			i += 1
		if word.is_empty():
			if cur.is_empty():
				cur.append_array(spaces)   # a paragraph of only spaces keeps them
			break
		if cur.is_empty():
			cur = spaces.duplicate()
			cur.append_array(word)
			continue
		var trial: Array = cur.duplicate()
		trial.append_array(spaces)
		trial.append_array(word)
		if _line_width(trial, glyphs, face) <= max_width:
			cur = trial
		else:
			lines.append(cur)
			cur = word
	lines.append(cur)
	return lines


static func _place(out: VectorLayout, cell: Cell, pen: float, base_y: float, face: VectorFace) -> void:
	var size: float = face.size
	var origin := Vector2(pen, base_y)
	for si in cell.strokes.size():
		var src: PackedVector2Array = cell.strokes[si]
		var pts := PackedVector2Array()
		for k in src.size():
			var p: Vector2 = origin + src[k] * size
			if face.jitter != 0.0:
				p += _wobble(face.seed, cell.index, si, k, 0) * face.jitter
			pts.append(p)
		if face.grain != 0.0 and pts.size() > 1:
			pts = _grain(pts, face, cell.index, si)
		out.strokes.append(pts)


## Hash of (seed, a, b, c, d) -> two values in [-1, 1]. Deterministic, never touches an RNG stream.
static func _wobble(seed: int, a: int, b: int, c: int, d: int) -> Vector2:
	var h: int = seed * 668265263 + a * 374761393 + b * 2246822519 + c * 3266489917 + d * 1442695041
	h = (h ^ (h >> 13)) * 1274126177
	h = h ^ (h >> 16)
	var x: float = float(h & 0xFFFF) / 32767.5 - 1.0
	h = (h * 2654435761) ^ (h >> 11)
	var y: float = float(h & 0xFFFF) / 32767.5 - 1.0
	return Vector2(x, y)


static func _grain(pts: PackedVector2Array, face: VectorFace, a: int, b: int) -> PackedVector2Array:
	var out := PackedVector2Array()
	out.append(pts[0])
	for k in range(1, pts.size()):
		var p0: Vector2 = pts[k - 1]
		var p1: Vector2 = pts[k]
		var n: int = maxi(1, ceili(p0.distance_to(p1) / GRAIN_STEP))
		for j in range(1, n):
			var q: Vector2 = p0.lerp(p1, float(j) / float(n))
			q += _wobble(face.seed, a, b, k, j + 1) * face.grain
			out.append(q)
		out.append(p1)
	return out


## Stroke width to draw with: never thinner than MIN_PHYSICAL_STROKE physical px at scale
## (the canvas-to-screen scale), so a thin diagonal can never rasterise to nothing.
static func effective_stroke_width(stroke_width: float, scale: float) -> float:
	return maxf(stroke_width, MIN_PHYSICAL_STROKE / maxf(scale, 0.01))


## Tessellates a layout into one triangle mesh with round caps and joins (one draw call, clean
## edges under 2D MSAA at any scale). Returns null when there is nothing to draw.
static func build_mesh(lay: VectorLayout, stroke_width: float) -> ArrayMesh:
	var verts := PackedVector2Array()
	var r: float = stroke_width * 0.5
	for st in lay.strokes:
		var n: int = st.size()
		if n == 0:
			continue
		if n == 1:
			_disc(verts, st[0], r)
			continue
		for i in n - 1:
			var a: Vector2 = st[i]
			var b: Vector2 = st[i + 1]
			var d: Vector2 = b - a
			if d.length_squared() < 1e-10:
				continue
			var nrm: Vector2 = Vector2(-d.y, d.x).normalized() * r
			verts.append_array(PackedVector2Array([a + nrm, a - nrm, b - nrm, a + nrm, b - nrm, b + nrm]))
		for i in n:
			var round_it: bool = i == 0 or i == n - 1
			if not round_it:
				var d0: Vector2 = (st[i] - st[i - 1]).normalized()
				var d1: Vector2 = (st[i + 1] - st[i]).normalized()
				round_it = absf(d0.angle_to(d1)) > JOIN_TURN
			if round_it:
				_disc(verts, st[i], r)
	if verts.is_empty():
		return null
	var arrays: Array = []
	arrays.resize(Mesh.ARRAY_MAX)
	arrays[Mesh.ARRAY_VERTEX] = verts
	var mesh := ArrayMesh.new()
	mesh.add_surface_from_arrays(Mesh.PRIMITIVE_TRIANGLES, arrays)
	return mesh


static func _disc(verts: PackedVector2Array, c: Vector2, r: float) -> void:
	var prev: Vector2 = c + Vector2(r, 0.0)
	for k in range(1, CAP_SEGMENTS + 1):
		var a: float = TAU * float(k) / float(CAP_SEGMENTS)
		var cur: Vector2 = c + Vector2(cos(a), sin(a)) * r
		verts.append(c)
		verts.append(prev)
		verts.append(cur)
		prev = cur