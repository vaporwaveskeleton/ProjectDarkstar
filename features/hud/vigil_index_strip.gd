class_name VigilIndexStrip
extends Control
## Vigil Index (score strip) at the `top-right` anchor (WARP-001 §4.1): the run's score in VectorLabel
## stroke digits (TECH-001 §2.9a). Honest by default. W1-10 Ledger Smudge reaches it only through
## `liar` (HudLiar, Glyph class): one digit renders as a close neighbour while `value` stays correct;
## with Steady Ledger on the liar returns nothing (WARP-001 §4.4).

const DIGITS := 6   ## ✱ shown width, zero-padded

## The true score. The only input; no warp code writes it.
var value: int = 0:
	set(v):
		value = maxi(0, v)
		_refresh()
var liar: HudLiar = null:
	set(v):
		liar = v
		_refresh()

var _label: VectorLabel
var _glyph_was_live := false


func _ready() -> void:
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	_label = VectorLabel.new()
	_label.name = &"Digits"
	_label.face = load("res://data/ui/vector_face.tres") as VectorFace
	_label.glyphs = load("res://data/ui/vector_glyphs.tres") as VectorGlyphSet
	_label.color = Pal.BONE_4
	_label.alignment = VectorText.Align.RIGHT
	_label.set_anchors_preset(Control.PRESET_FULL_RECT)
	_label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(_label)
	_refresh()


func _process(_delta: float) -> void:
	var live := liar != null and liar.glyph_live()
	if live != _glyph_was_live:
		_refresh()


## The digits as drawn before any glyph filter (always the true value).
func shown_text() -> String:
	return str(value).pad_zeros(DIGITS)


## True while a W1-10 glyph is drawn on the strip.
func smudged() -> bool:
	return _glyph_was_live


func _refresh() -> void:
	if _label == null:
		return
	var txt := shown_text()
	_label.text = txt
	_glyph_was_live = liar != null and liar.glyph_live() and not HudModel.steady_ledger_on()
	if _glyph_was_live:
		var l := liar
		var n := txt.length()
		_label.glyph_filter = func(ch: String, index: int) -> Variant: return l.glyph_for(ch, index, n)
	else:
		_label.glyph_filter = Callable()
