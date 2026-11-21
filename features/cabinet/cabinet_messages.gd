class_name CabinetMessages
extends Control
## Text over the play view (the grid below the HUD strip, clipped to it): the READY card, centre banners, the caption line (GDD §10:
## the chant is audio-critical, so it is always captioned), the cabinet credits roll, and the
## entity's big type (ART-001 §11.5: NULL band above the centre, never animated per letter). Long lines wrap
## at spaces to the 256 px screen; nothing is shrunk below its role scale.

var _ready_title := ""
var _ready_sub := ""
var _ready_zone := ""            ## zone name line above the READY title ("" = none)
var _ready_t := 0.0
var _banner := ""
var _banner_t := 0.0
var _caption := ""
var _caption_t := 0.0
var _line := ""
var _line_t := 0.0
var credits: PackedStringArray = PackedStringArray()
var credits_t := -1.0            ## < 0 = no credits roll
var credits_frozen := false
var _stat_indices := PackedInt32Array()   ## entries of `credits` that are service-record lines
var _stats_emitted: Dictionary = {}          ## stat-line index -> true once credits_stat_shown fired
var glitch := 0.0                ## 0..1 the Pretence Tear corrupts the credits
var demo := false                ## attract demo: INSERT CREDIT over the field
var _t := 0.0

## The Decay's honour-roll page (ART-001 §12.7b, NARR-001 §4.5): the machine goes back to attract after the
## last credits. It only ever LOSES glyphs and bulbs; nothing here writes new words.
var roll_page := false
var roll_header := ""
var roll_rows: PackedStringArray = PackedStringArray()   ## the last row is the player's own (eroded last)
var roll_glyphs_lost := 0        ## glyphs blanked so far across header, rows and INSERT CREDIT
var roll_bulbs_dead := 0.0       ## dark bulbs, fractional = the next one dimming out
var roll_blink_period := 1.0     ## s, INSERT CREDIT's blink period (0 = steady)
var roll_seed := 9               ## ✱ the order glyphs are lost in is fixed per seed (deterministic captures)
var _roll_t := 0.0
var _hold := ""                  ## ending 5 (NARR-001 §9.5): one held screen of Theodora's message, "" = none
var _hold_prompt := false         ## the held screen waits for a press: show the press-fire line under it

signal credits_stat_shown(index: int)       ## stat line `index` (0..3) just scrolled into view

@export var spec: CabinetScreenSpec
@export var fx_tuning: CabinetFxTuning   ## credits scroll speed (data/cabinet/cabinet_fx_tuning.tres)

const MARGIN := 4.0              ## text keeps this far from the screen edge
const ZONE_GAP := 6.0            ## ✱ px between the zone line and the READY title below it
const READY_CLEAR := 14.0     ## ✱ px between the READY card and the play-view centre (Vigil hull 12 px + margin)
const CREDIT_LINE_H := float(PixelText.H * 2)   ## a credits line's glyph height (scale 2)
const CREDIT_PITCH := 18.0       ## px from one credits line to the next (unchanged layout pitch)
const CREDIT_ENTRY_GAP := 4.0    ## extra px between credits entries


func _ready() -> void:
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	# the play view only: text clips at the HUD strip instead of running over it
	var s := spec if spec != null else (load("res://data/cabinet/cabinet_screen.tres") as CabinetScreenSpec)
	set_anchors_preset(Control.PRESET_TOP_LEFT)
	position = s.play_rect().position
	size = s.play_rect().size
	clip_contents = true


## The READY card. `zone` (optional) is the zone name line, drawn small above the title.
func show_ready(title: String, sub: String, seconds: float, zone: String = "") -> void:
	_ready_title = title
	_ready_sub = sub
	_ready_zone = zone
	_ready_t = seconds


## Top of the READY title, and of the zone line above it (play-view y). One layout for _draw and tests.
## The whole card sits above the play view centre, where the Vigil spawns (Reviewer, PR #57): its
## bottom (the READY line) ends READY_CLEAR px above the centre.
func ready_title_top() -> float:
	var h := block_height(_ready_title, 3) + 2.0 + block_height(_ready_sub, 1) + 12.0 + float(PixelText.H * 2)
	return size.y * 0.5 - READY_CLEAR - h


## Bottom of the READY line (play-view y).
func ready_bottom() -> float:
	return ready_title_top() + block_height(_ready_title, 3) + 2.0 + block_height(_ready_sub, 1) + 12.0 + float(PixelText.H * 2)


func ready_zone_top() -> float:
	return ready_title_top() - ZONE_GAP - block_height(_ready_zone, 1)


func ready_zone() -> String:
	return _ready_zone if _ready_t > 0.0 else ""


func banner(text: String, seconds: float) -> void:
	_banner = text
	_banner_t = seconds


func caption(text: String, seconds: float = 4.0) -> void:
	_caption = text
	_caption_t = seconds


func entity_line(text: String, seconds: float = 3.0) -> void:
	_line = text
	_line_t = seconds


func roll_credits(lines: PackedStringArray, stat_indices: PackedInt32Array = PackedInt32Array()) -> void:
	credits = lines
	_stat_indices = stat_indices
	_stats_emitted.clear()
	credits_t = 0.0
	credits_frozen = false


## Ending 5: hold one screen (≤ 2 lines, Cabinet face) until replaced; "" clears it.
func hold_screen(text: String, awaiting_press: bool = false) -> void:
	_hold = text
	_hold_prompt = awaiting_press and not text.is_empty()


func held_screen() -> String:
	return _hold


## True while the held screen waits for a press (the PRESS FIRE line is drawn under it).
func held_prompt() -> bool:
	return _hold_prompt


func clear() -> void:
	_brief = {}
	roll_page = false
	_hold = ""
	_hold_prompt = false
	_ready_t = 0.0
	_banner_t = 0.0
	_caption_t = 0.0
	_line_t = 0.0
	credits_t = -1.0
	_stats_emitted.clear()


func _process(delta: float) -> void:
	_t += delta
	_ready_t = maxf(0.0, _ready_t - delta)
	_banner_t = maxf(0.0, _banner_t - delta)
	_caption_t = maxf(0.0, _caption_t - delta)
	_line_t = maxf(0.0, _line_t - delta)
	if roll_page:
		_roll_t += delta
	if credits_t >= 0.0 and not credits_frozen:
		credits_t += delta
		_emit_stat_lines()
	queue_redraw()


## Cabinet face, centred in the play view; `y` is the top of the glyphs; `scale` is an integer (ART-001 §11).
func _centered(y: float, s: String, scale: int, col: Color) -> void:
	PixelText.draw_centered(self, size.x * 0.5, y, s, col, scale)


## Wrapped, centred lines from `y`; returns the y just below the block.
func _block(y: float, s: String, scale: int, col: Color) -> float:
	var step := float(PixelText.H * scale + 3 * scale)
	for line in PixelText.wrap(s, scale, size.x - 2.0 * MARGIN):
		_centered(y, line, scale, col)
		y += step
	return y


## Height of `_block` for `s`.
func block_height(s: String, scale: int) -> float:
	return PixelText.wrap(s, scale, size.x - 2.0 * MARGIN).size() * float(PixelText.H * scale + 3 * scale)


# --- The stage card (SYS-001 §1.7, UI-001 §11) ------------------------------------------------------
# Drawn in the play view with PixelText and the existing Look.c(Pal.*) registers; never over the marquee
# (the marquee is a bezel screenprint, outside the screen). One layout for _draw and the tests.

const BRIEF_ROW_H := 20.0        ## ✱ px per unit row (the tallest icon, the Acolyte, is 15 px)
const BRIEF_ICON_X := 74.0       ## ✱ icon column centre
const BRIEF_NAME_X := 94.0       ## ✱ unit name starts here
const BRIEF_COUNT_RIGHT := 182.0 ## ✱ counts are right-aligned to here
const BRIEF_PROMPT_UP := 34.0    ## px from the view foot to the prompt's top (clear of the maker band)
const BRIEF_TOP := 8.0           ## ✱ px above the zone line

var _brief := {}                 ## the open card: {zone, title, order, reminders, roster, rows, unmakings, prompt, blink_hz, tuning}; empty = none
var _brief_icons_t: CabinetTuning


## Open the stage card. `card` keys: zone, title, order, reminders (PackedStringArray), roster (heading),
## rows (Array of {kind: StringName, name: String, count: int}), unmakings ("" = none), prompt, blink_hz.
func show_brief(card: Dictionary, tuning: CabinetTuning) -> void:
	_brief = card
	_brief_icons_t = tuning


func hide_brief() -> void:
	_brief = {}


func brief_open() -> bool:
	return not _brief.is_empty()


## The open card's data (empty when none): tests read the rows and lines from it.
func brief() -> Dictionary:
	return _brief


## Is the PRESS FIRE prompt lit right now? Steady under photosensitivity or reduced motion, else it blinks at blink_hz.
func brief_prompt_lit() -> bool:
	if _brief.is_empty():
		return false
	if bool(SettingsService.get_value(&"photosensitivity")) or bool(SettingsService.get_value(&"reduced_motion")):
		return true
	return fmod(_t * float(_brief.get("blink_hz", 1.5)), 1.0) < float(_brief.get("duty", 0.7))


## The y of the card's elements, top to bottom (play-view px), for _draw and the fit test. `bottom` is the
## bottom of the last unit row (or of the roster heading when there are no rows).
func brief_layout() -> Dictionary:
	var out := {}
	var y := BRIEF_TOP
	var zone: String = _brief.get("zone", "")
	if not zone.is_empty():
		out["zone"] = y
		y += block_height(zone, 1) + ZONE_GAP
	out["title"] = y
	y += block_height(str(_brief.get("title", "")), 2) + 6.0
	out["order"] = y
	y += block_height(str(_brief.get("order", "")), 1) + 6.0
	var rem: PackedStringArray = _brief.get("reminders", PackedStringArray())
	var rem_y := PackedFloat32Array()
	for r in rem:
		rem_y.append(y)
		y += block_height(r, 1)
	out["reminders"] = rem_y
	y += 8.0
	out["roster"] = y
	y += block_height(str(_brief.get("roster", "")), 1) + 6.0
	var rows: Array = _brief.get("rows", [])
	out["rows"] = y
	y += BRIEF_ROW_H * rows.size()
	out["bottom"] = y
	out["unmakings"] = size.y - BRIEF_PROMPT_UP - 14.0
	out["prompt"] = size.y - BRIEF_PROMPT_UP
	return out


func _draw_brief() -> void:
	draw_rect(Rect2(Vector2.ZERO, size), Look.c(Pal.VOID_0))     # a pause: the field is not on the tube behind the card
	var lay := brief_layout()
	var zone: String = _brief.get("zone", "")
	if not zone.is_empty():
		_block(float(lay["zone"]), zone, 1, Look.c(Pal.GAS_4))
	_block(float(lay["title"]), str(_brief["title"]), 2, Look.c(Pal.BONE_5))
	_block(float(lay["order"]), str(_brief["order"]), 1, Look.c(Pal.PHOS_4))      # phosphor = truth
	var rem: PackedStringArray = _brief.get("reminders", PackedStringArray())
	var rem_y: PackedFloat32Array = lay["reminders"]
	for i in rem.size():
		_block(rem_y[i], rem[i], 1, Look.c(Pal.BONE_3))
	_block(float(lay["roster"]), str(_brief["roster"]), 1, Look.c(Pal.GAS_4))
	var rows: Array = _brief.get("rows", [])
	var y := float(lay["rows"])
	for row: Dictionary in rows:
		var mid := y + BRIEF_ROW_H * 0.5
		CabinetBriefIcons.draw(self, row["kind"], Vector2(BRIEF_ICON_X, mid), _brief_icons_t)
		PixelText.draw(self, Vector2(BRIEF_NAME_X, mid - PixelText.H * 0.5), str(row["name"]), Look.c(Pal.BONE_5))
		var cnt := str(row["count"])
		PixelText.draw(self, Vector2(BRIEF_COUNT_RIGHT - PixelText.width(cnt), mid - PixelText.H * 0.5), cnt, Look.c(Pal.BONE_4))
		y += BRIEF_ROW_H
	var unm: String = _brief.get("unmakings", "")
	if not unm.is_empty():
		_centered(float(lay["unmakings"]), unm, 1, Look.c(Pal.BONE_2))
	if brief_prompt_lit():
		_centered(float(lay["prompt"]), str(_brief["prompt"]), 1, Look.c(Pal.GAS_4))


func _draw() -> void:
	var cy := size.y * 0.5
	# the machine is back in attract (or showing Theodora's screens): the paused field is not on the tube
	if roll_page or not _hold.is_empty():
		draw_rect(Rect2(Vector2.ZERO, size), Look.c(Pal.VOID_0))
	if roll_page:
		_draw_roll()
	if not _hold.is_empty():
		_block(cy - block_height(_hold, 1) * 0.5, _hold, 1, Look.c(Pal.BONE_5))
		if _hold_prompt:
			_centered(cy + block_height(_hold, 1) * 0.5 + 14.0, tr("CAB_BRIEF_PRESS_FIRE"), 1, Look.c(Pal.GAS_4))
	if not _brief.is_empty():
		_draw_brief()
	if _ready_t > 0.0:
		if not _ready_zone.is_empty():
			_block(ready_zone_top(), _ready_zone, 1, Look.c(Pal.GAS_4))
		var y := _block(ready_title_top(), _ready_title, 3, Look.c(Pal.BONE_5)) + 2.0
		y = _block(y, _ready_sub, 1, Look.c(Pal.BONE_2)) + 12.0
		if int(_t * 3.0) % 2 == 0:
			_centered(y, tr("CAB_READY"), 2, Look.c(Pal.GAS_4))
	if _banner_t > 0.0:
		_block(cy - 8.0 - (block_height(_banner, 2) - 18.0) * 0.5, _banner, 2, Look.c(Pal.BONE_5))
	if credits_t >= 0.0:
		_draw_credits()
	if _caption_t > 0.0:
		_block(size.y - 34.0, _caption, 1, Look.c(Pal.BONE_3))
	if demo and int(_t * 1.6) % 2 == 0:
		_centered(size.y - 22.0, tr("CAB_CREDIT"), 1, Look.c(Pal.BONE_5))
	if _line_t > 0.0:
		# the entity's big type: a hole torn in the frame (ART-001 §11.5); the band grows with the lines
		var h := block_height(_line, 3) + 2.0 * 8.0 - 9.0
		var top := cy - 60.0 - h * 0.5
		draw_rect(Rect2(0, top, size.x, h), Look.c(Pal.NULL))
		_block(top + 8.0, _line, 3, Look.c(Pal.BONE_5))


## The honour-roll page as the Decay leaves it: every string eroded by `roll_glyphs_lost`.
func _draw_roll() -> void:
	var lines := PackedStringArray([roll_header])
	lines.append_array(roll_rows)
	lines.append(tr("CAB_CREDIT"))
	var protect := 1 + roll_rows.size() - 1   # the player's own row goes last
	var eroded := CabinetMessages.erode(lines, roll_glyphs_lost, roll_seed, protect)
	_draw_roll_bulbs()
	_centered(14.0, eroded[0], 1, Look.c(Pal.VOID_5))
	var y := 40.0
	for i in roll_rows.size():
		var col := Look.c(Pal.GAS_4) if i == roll_rows.size() - 1 else Look.c(Pal.BONE_5)
		_centered(y, eroded[1 + i], 1, col)
		y += 14.0
	var on := roll_blink_period <= 0.0 or fmod(_roll_t, roll_blink_period) < roll_blink_period * 0.5
	if on:
		_centered(size.y - 40.0, eroded[eroded.size() - 1], 1, Look.c(Pal.BONE_5))   # clear of the maker line


## The attract card's chasing bulbs, dying from the last one back (a dim-out, never a flicker).
func _draw_roll_bulbs() -> void:
	var pts := CabinetMessages.bulb_points(Rect2(Vector2(2, 2), size - Vector2(4, 4)))
	var still: bool = SettingsService.get_value(&"reduced_motion") or SettingsService.get_value(&"photosensitivity")
	var step := 0 if still else int(_roll_t * 6.0)
	var n := pts.size()
	for i in n:
		var from_end := n - 1 - i
		var dead := clampf(roll_bulbs_dead - float(from_end), 0.0, 1.0)
		var lit := (i + step) % 4 == 0
		var c := Look.c(Pal.GAS_4) if lit else Look.c(Pal.GAS_1)
		c = c.lerp(Look.c(Pal.VOID_0), dead)
		draw_rect(Rect2(pts[i] - Vector2.ONE, Vector2(2, 2)), c)


## Bulb centres round `r`, every 8 px (the attract card's layout, scenes/attract/attract_pages.gd).
static func bulb_points(r: Rect2) -> Array[Vector2]:
	var pts: Array[Vector2] = []
	for x in range(int(r.position.x), int(r.end.x), 8):
		pts.append(Vector2(x, r.position.y))
	for y in range(int(r.position.y), int(r.end.y), 8):
		pts.append(Vector2(r.end.x, y))
	for x in range(int(r.end.x), int(r.position.x), -8):
		pts.append(Vector2(x, r.end.y))
	for y in range(int(r.end.y), int(r.position.y), -8):
		pts.append(Vector2(r.position.x, y))
	return pts


## Subtract-only erosion (NARR-001 §4.5): blank `lost` non-space glyphs across `lines` in a fixed seeded
## order; line `protect` (or -1) loses its glyphs only after every other glyph is gone. Never adds or moves one.
static func erode(lines: PackedStringArray, lost: int, seed: int, protect: int = -1) -> PackedStringArray:
	var first: Array[Vector2i] = []
	var last: Array[Vector2i] = []
	for li in lines.size():
		for ci in lines[li].length():
			if lines[li][ci] != " ":
				(last if li == protect else first).append(Vector2i(li, ci))
	var rng := RandomNumberGenerator.new()
	rng.seed = seed
	_shuffle(first, rng)
	_shuffle(last, rng)
	var order: Array[Vector2i] = first + last
	var out := lines.duplicate()
	for k in mini(maxi(lost, 0), order.size()):
		var p := order[k]
		var s := out[p.x]
		out[p.x] = s.substr(0, p.y) + " " + s.substr(p.y + 1)
	return out


static func _shuffle(a: Array[Vector2i], rng: RandomNumberGenerator) -> void:
	for i in range(a.size() - 1, 0, -1):
		var j := rng.randi_range(0, i)
		var t := a[i]
		a[i] = a[j]
		a[j] = t


## The credits window (play-view y): from MARGIN below the HUD rule down to READY_CLEAR above the
## play-view centre, where the Vigil sits, the same clearance as the READY card. A credits line is
## drawn only while it is wholly inside it, so the roll never crosses the HUD rule, the Vigil or the
## footer (Reviewer v2 §I; PM under owner autonomy grant, 2026-11-19).
func credits_top() -> float:
	return MARGIN


func credits_bottom() -> float:
	return size.y * 0.5 - READY_CLEAR



## Top edge (play-view y) of credits entry `i` when the roll has run `t` seconds. One layout for
## drawing and for `credits_stat_shown`, so they cannot disagree (wrap and pitch match _draw_credits).
## Entries rise from the window's bottom edge.
func credit_entry_top(i: int, t: float) -> float:
	var y := credits_bottom() - t * _tuning().credits_scroll_px_per_s
	for k in mini(i, credits.size()):
		y += PixelText.wrap(credits[k], 2, size.x - 2.0 * MARGIN).size() * CREDIT_PITCH + CREDIT_ENTRY_GAP
	return y


## True when a credits line whose glyphs start at `y` is wholly inside the credits window.
func credit_line_visible(y: float) -> bool:
	return y >= credits_top() and y + CREDIT_LINE_H <= credits_bottom()


## Every credits line drawn at roll time `t`, as play-view rects (the glyph box, full width).
func visible_credit_rects(t: float) -> Array[Rect2]:
	var out: Array[Rect2] = []
	for i in credits.size():
		var y := credit_entry_top(i, t)
		for line in PixelText.wrap(credits[i], 2, size.x - 2.0 * MARGIN):
			if credit_line_visible(y):
				var w := float(PixelText.width(line, 2))
				out.append(Rect2((size.x - w) * 0.5, y, w, CREDIT_LINE_H))
			y += CREDIT_PITCH
	return out


func _draw_credits() -> void:
	for i in credits.size():
		var y := credit_entry_top(i, credits_t)
		var col := Look.c(Pal.BONE_4) if glitch < 0.5 or i % 2 == 0 else Look.c(Pal.PHOS_4)
		var x_shift := 0.0
		if glitch > 0.0 and (i * 7 + int(_t * 8.0)) % 3 == 0:
			x_shift = (sin(_t * 40.0 + i) * 12.0) * glitch
		for line in PixelText.wrap(credits[i], 2, size.x - 2.0 * MARGIN):
			if credit_line_visible(y):
				PixelText.draw_centered(self, size.x * 0.5 + x_shift, y, line, col, 2)
			y += CREDIT_PITCH


## The stat lines announce themselves the first time they show (wholly inside the credits window).
func _emit_stat_lines() -> void:
	for n in _stat_indices.size():
		if _stats_emitted.has(n):
			continue
		if credit_entry_top(_stat_indices[n], credits_t) + CREDIT_LINE_H <= credits_bottom():
			_stats_emitted[n] = true
			credits_stat_shown.emit(n)


func _tuning() -> CabinetFxTuning:
	if fx_tuning == null:
		fx_tuning = load("res://data/cabinet/cabinet_fx_tuning.tres") as CabinetFxTuning
	return fx_tuning
