class_name HudLiar
extends RefCounted
## HudLiar (TECH-001 §5.2 filter stage), the T1 slice: the two T1 deviations, both non-lies
## (WARP-001 §4.2 class table): W1-09 Smudged Blip (Smear: a compass blip shows its own position from
## `lag_s` ago, drawn as a streak to where it is now) and W1-10 Ledger Smudge (Glyph: one Vigil Index
## digit is drawn as a close neighbour; the value never changes).
##
## Laws held here: per-sector deviation and lie caps by tier (WARP-001 §4.2 table: T1 = 2 and 0);
## L4 one deviation per state at a time; the own-position readout never deviates (§4.7); Steady Ledger
## on = nothing (HudModel.presented() never calls `apply`, and `glyph_for` checks it again). Lies
## (class Lie) are not built: `begin_lie` does not exist yet, so no lie path exists (T3+, M5).

## WARP-001 §4.2 per-sector caps by tier T0..T5 ✱ (deviations total, of which lies).
const DEVIATIONS_BY_TIER: Array[int] = [1, 2, 2, 4, 5, 2]
const LIES_BY_TIER: Array[int] = [0, 0, 0, 2, 2, 0]
## Close-neighbour glyphs for W1-10 (Glyph family: "replaced by a close neighbour").
const NEIGHBOUR := {"0": "8", "1": "7", "2": "7", "3": "8", "4": "9", "5": "6", "6": "5",
	"7": "1", "8": "3", "9": "4"}
const HISTORY_S := 3.0   ## ✱ how much compass history is kept for a smear

var tier: int = 1
var deviations_used: int = 0
## Clock (s) the liar is advanced with by its owner (the WarpComposer).
var now_s: float = 0.0

## Smear (W1-09): the marker slot it applies to (never 0, the Vigil), its lag and its end.
var smear_slot: int = -1
var smear_lag_s: float = 0.0
var smear_until: float = -1.0
## Glyph (W1-10): which digit (counted from the right) and until when.
var glyph_digit: int = -1
var glyph_until: float = -1.0

var _hist_t: PackedFloat32Array = PackedFloat32Array()
var _hist: Array[PackedVector2Array] = []


func cap() -> int:
	return DEVIATIONS_BY_TIER[clampi(tier, 0, DEVIATIONS_BY_TIER.size() - 1)]


func lie_cap() -> int:
	return LIES_BY_TIER[clampi(tier, 0, LIES_BY_TIER.size() - 1)]


func smear_live() -> bool:
	return smear_slot > 0 and now_s < smear_until


func glyph_live() -> bool:
	return glyph_digit >= 0 and now_s < glyph_until


## Starts W1-09 on compass slot `slot` (>= 1). False when refused (cap spent, already live, or the
## own-position slot 0).
func begin_smear(slot: int, lag_s: float, duration_s: float) -> bool:
	if slot < 1 or smear_live() or deviations_used >= cap():
		return false
	deviations_used += 1
	smear_slot = slot
	smear_lag_s = lag_s
	smear_until = now_s + duration_s
	return true


## Starts W1-10 on the `digit`-th digit from the right of the Vigil Index. False when refused.
func begin_glyph(digit: int, duration_s: float) -> bool:
	if digit < 0 or glyph_live() or deviations_used >= cap():
		return false
	deviations_used += 1
	glyph_digit = digit
	glyph_until = now_s + duration_s
	return true


func end_all() -> void:
	smear_until = -1.0
	glyph_until = -1.0


## The filter (HudModel.presented() with Steady Ledger off). Records the honest positions, then
## returns a copy with the smeared slot moved to its position `smear_lag_s` ago.
func apply(model: HudModel) -> HudModel:
	_record(model.marker_world)
	var out := HudModel.new()
	out.own_position = model.own_position
	out.has_own_position = model.has_own_position
	out.marker_world = model.marker_world.duplicate()
	out.marker_kinds = model.marker_kinds.duplicate()
	out.entity_marker_visible = model.entity_marker_visible
	out.sector_list_cells = model.sector_list_cells
	if smear_live() and smear_slot < out.marker_world.size():
		var past := _past(smear_slot, now_s - smear_lag_s)
		if past.x == past.x:   # not NaN: history covers the lag
			out.smear_slot = smear_slot
			out.smear_tail = out.marker_world[smear_slot]
			out.marker_world[smear_slot] = past
	return out


## The VectorLabel glyph seam for the Vigil Index (W1-10). `text` is the shown string; the target is
## the `glyph_digit`-th digit from the right, counting digits only (group separators are skipped).
func glyph_for(ch: String, index: int, text: String) -> Variant:
	if not glyph_live() or HudModel.steady_ledger_on() or not NEIGHBOUR.has(ch):
		return null
	var n := 0
	for i in range(text.length() - 1, -1, -1):
		if NEIGHBOUR.has(text[i]):
			if n == glyph_digit:
				return NEIGHBOUR[ch] if i == index else null
			n += 1
	return null


func _record(world: PackedVector2Array) -> void:
	_hist_t.append(now_s)
	_hist.append(world.duplicate())
	while _hist_t.size() > 2 and now_s - _hist_t[0] > HISTORY_S:
		_hist_t.remove_at(0)
		_hist.remove_at(0)


func _past(slot: int, at: float) -> Vector2:
	for i in range(_hist_t.size() - 1, -1, -1):
		if _hist_t[i] <= at:
			var row := _hist[i]
			return row[slot] if slot < row.size() else Vector2(NAN, NAN)
	return Vector2(NAN, NAN)
