class_name VectorGlyphSet
extends Resource
## The stroke face for VectorText: every glyph is a few polylines in em units, no font file (D-13).
## One em here is the CAP HEIGHT: cap top y = 0, baseline y = 1 (y points down), descenders go below 1.
## Data is authored as compact strings in `glyphs` (char -> "advance|stroke;stroke;...") on a design
## grid of `grid_units` per em. A stroke is space-separated points "x,y" and/or elliptical arcs
## "@cx,cy,rx,ry,a0,a1" (degrees, 0 = right, 90 = down; a1 < a0 sweeps the other way). A stroke
## of a single point draws a dot. Parsed once, cached as PackedVector2Array in em units.

@export var glyphs: Dictionary = {}          ## String char -> "advance|strokes" (grid units)
@export var kerning: Dictionary = {}         ## String pair "AV" -> float, grid units (negative = tighter)
@export var grid_units: float = 10.0         ## design-grid units per em (= cap height)
@export var cap_height: float = 1.0          ## em
@export var x_height: float = 0.7            ## em
@export var baseline: float = 1.0            ## em, measured down from the cap top
@export var descent: float = 0.3             ## em below the baseline reserved for descenders
@export var line_gap: float = 0.3            ## em between a line's descent and the next line's cap top
@export var fallback_advance: float = 9.0    ## grid units, the missing-glyph box

const ARC_STEP_DEG := 15.0

var _strokes: Dictionary = {}                ## char -> Array[PackedVector2Array] (em)
var _advances: Dictionary = {}               ## char -> float (em)
var _rights: Dictionary = {}                 ## char -> float (em), right edge of the ink
var _kern_em: Dictionary = {}                ## pair -> float (em)
var _parsed := false


func has_glyph(ch: String) -> bool:
	return glyphs.has(ch)


## The characters this set can draw.
func characters() -> PackedStringArray:
	var out := PackedStringArray()
	for k: Variant in glyphs.keys():
		out.append(str(k))
	return out


func get_strokes(ch: String) -> Array[PackedVector2Array]:
	_ensure()
	var s: Array[PackedVector2Array] = []
	if _strokes.has(ch):
		s.assign(_strokes[ch])
	else:
		s.assign(_fallback_strokes())
	return s


func get_advance(ch: String) -> float:
	_ensure()
	if _advances.has(ch):
		return float(_advances[ch])
	return fallback_advance / grid_units


## X of the right edge of the ink (em), used so trailing bearing does not count as width.
func get_ink_right(ch: String) -> float:
	_ensure()
	if _rights.has(ch):
		return float(_rights[ch])
	return (fallback_advance - 3.0) / grid_units


func get_kerning(prev: String, ch: String) -> float:
	_ensure()
	return float(_kern_em.get(prev + ch, 0.0))


func _fallback_strokes() -> Array[PackedVector2Array]:
	var w: float = (fallback_advance - 3.0) / grid_units
	var out: Array[PackedVector2Array] = []
	out.append(PackedVector2Array([Vector2(0, 0), Vector2(w, 0), Vector2(w, 1.0), Vector2(0, 1.0), Vector2(0, 0)]))
	return out


func _ensure() -> void:
	if _parsed:
		return
	_parsed = true
	_strokes.clear()
	_advances.clear()
	_rights.clear()
	_kern_em.clear()
	for k: Variant in glyphs.keys():
		var ch: String = str(k)
		var def: String = str(glyphs[k])
		var bar: int = def.find("|")
		var adv: float = float(def.substr(0, bar)) if bar >= 0 else grid_units * 0.7
		var body: String = def.substr(bar + 1) if bar >= 0 else ""
		var strokes: Array[PackedVector2Array] = parse_strokes(body, grid_units)
		_strokes[ch] = strokes
		_advances[ch] = adv / grid_units
		var right := 0.0
		for st in strokes:
			for p in st:
				right = maxf(right, p.x)
		_rights[ch] = right
	for k: Variant in kerning.keys():
		_kern_em[str(k)] = float(kerning[k]) / grid_units


## Parses "x,y x,y ; @cx,cy,rx,ry,a0,a1 x,y" into em-unit polylines (design units / `units`).
static func parse_strokes(body: String, units: float) -> Array[PackedVector2Array]:
	var out: Array[PackedVector2Array] = []
	for stroke_text in body.split(";", false):
		var pts := PackedVector2Array()
		for tok in stroke_text.strip_edges().split(" ", false):
			if tok.begins_with("@"):
				var n: PackedStringArray = tok.substr(1).split(",")
				if n.size() < 6:
					continue
				var cx: float = float(n[0])
				var cy: float = float(n[1])
				var rx: float = float(n[2])
				var ry: float = float(n[3])
				var a0: float = float(n[4])
				var a1: float = float(n[5])
				var steps: int = maxi(2, ceili(absf(a1 - a0) / ARC_STEP_DEG))
				for i in steps + 1:
					var a: float = deg_to_rad(lerpf(a0, a1, float(i) / float(steps)))
					_push(pts, Vector2(cx + rx * cos(a), cy + ry * sin(a)) / units)
			else:
				var xy: PackedStringArray = tok.split(",")
				if xy.size() >= 2:
					_push(pts, Vector2(float(xy[0]), float(xy[1])) / units)
		if pts.size() > 0:
			out.append(pts)
	return out


static func _push(pts: PackedVector2Array, p: Vector2) -> void:
	if pts.size() > 0 and pts[pts.size() - 1].distance_squared_to(p) < 1e-9:
		return
	pts.append(p)
