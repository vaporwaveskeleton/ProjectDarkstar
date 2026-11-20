class_name RuinsOnboarding
extends RefCounted
## The rules of a Ruins visit as diegetic onboarding (LOOP-001 §10.5; NARR-001 §5.7; SLICE beats
## 7–11). Pure state: no nodes, no input, no text lookup, no saves. The Ruins scene feeds it the
## already-translated chalk lines, the station positions and the walk axis each frame, and turns the
## events it returns into light, sound and chalk. Tests drive it directly.
##
## Order on a first visit: cold open → the chalk writes (movement unlocks on the first stroke) →
## the Cabinet pays out (tickets fly to the Tree) → free: the player walks the pilot lamp between
## the places. The hangar mouth is dark until a Tree lamp is lit: the lamp gutters at the dark and
## will not pass (the gate is the world's rule). Walking into the lit mouth launches.
## A later visit skips the cold open and the payout; the Tree's lamp is already lit.

const PHASE_COLD_OPEN := &"cold_open"
const PHASE_CHALK := &"chalk"
const PHASE_PAYOUT := &"payout"
const PHASE_FREE := &"free"
const PHASE_LAUNCHED := &"launched"

const CHALK_DESK := &"chalk_desk"
const CODEX_DESK := &"codex_desk"
const TREE := &"tree"
const HOURGLASS := &"hourglass"
## The places the pilot lamp can stand at and use, in floor order.
const STATIONS: Array[StringName] = [CHALK_DESK, CODEX_DESK, TREE, HOURGLASS]

## Events step() and use() return (the scene reacts; tests assert).
const EV_CHALK_STROKE := &"chalk_stroke"          # the first stroke of a line
const EV_CHALK_LINE := &"chalk_line"              # a line finished
const EV_PAYOUT := &"payout"                      # the Cabinet clatters
const EV_TICKETS_LANDED := &"tickets_landed"
const EV_REACHED := &"reached"                    # first time the lamp reaches a station (arg: id)
const EV_GUTTER := &"gutter"                      # the lamp met the dark mouth
const EV_TREE_LIT := &"tree_lit"
const EV_CODEX_OPEN := &"codex_open"
const EV_CODEX_CLOSED := &"codex_closed"
const EV_DARK_REVEAL := &"dark_reveal"
const EV_LAUNCH := &"launch"

var stats: RuinsOnboardingStats
var first_visit := false
## Ember the Act 0 bank paid on this arrival (tickets); 0 = no payout.
var paid := 0
var phase: StringName = PHASE_COLD_OPEN
var t := 0.0
## The chalk lines for this visit, already translated; index and characters written.
var lines: PackedStringArray = []
var line_index := 0
var chars := 0.0
var _rest := 0.0
var payout_t := 0.0
var tickets_landed := false
var can_move := false
var lamp_x := 0.0
## Click-to-walk target (logical x), or NAN.
var walk_target := NAN
var lamp_down := false
var dark_t := 0.0
var dark_revealed := false
var tree_lit := false
## The Tree station's purchase: a Callable () -> StringName returning the node bought, or &"" when
## nothing was (Q-T191). Invalid = the legacy free first lamp (stand-alone tests).
var tree_buyer: Callable
## The node the last Tree use bought ("" when none).
var last_node: StringName = &""
var codex_open := false
var codex_read := false
var guttered := false
## Station id → logical x.
var station_x: Dictionary = {}
## Station ids the lamp has reached at least once.
var reached: Dictionary = {}
## Station ids used at least once.
var used: Dictionary = {}
## The hangar mouth's left edge (logical x); the dark stops the lamp before it.
var mouth_x := 484.0


func _init(p_stats: RuinsOnboardingStats) -> void:
	stats = p_stats


## Set up one visit. `p_lines`: the chalk lines in order (translated). `p_stations`: id → x.
func begin(p_first_visit: bool, p_paid: int, p_lines: PackedStringArray, p_stations: Dictionary, p_mouth_x: float) -> void:
	first_visit = p_first_visit
	paid = maxi(0, p_paid)
	lines = p_lines
	station_x = p_stations.duplicate()
	mouth_x = p_mouth_x
	lamp_x = stats.lamp_start_x
	t = 0.0
	line_index = 0
	chars = 0.0
	tickets_landed = paid == 0
	tree_lit = not first_visit       # a later visit: the lamp bought before is lit (interim, Q-T191)
	phase = PHASE_COLD_OPEN if first_visit else PHASE_CHALK
	can_move = not first_visit


## The hangar mouth is lit: a Tree lamp burns.
func gate_open() -> bool:
	return tree_lit


## The Hourglass holds its sand on the first visit until the launch (beat 11; Q-T162 settled).
func clock_held() -> bool:
	return first_visit and phase != PHASE_LAUNCHED


## The text of chalk line `i` as written so far ("" before it starts).
func chalk_text(i: int) -> String:
	if i < 0 or i >= lines.size() or i > line_index:
		return ""
	if i < line_index:
		return lines[i]
	return lines[i].substr(0, ceili(chars))


func chalk_done() -> bool:
	return line_index >= lines.size()


## The station in reach of the pilot lamp, or &"" (nearest wins). Usable stations only.
func focus() -> StringName:
	if not can_move or codex_open or phase == PHASE_LAUNCHED:
		return &""
	var best: StringName = &""
	var best_d := stats.lamp_reach_px
	for id: StringName in STATIONS:
		if not station_x.has(id) or not usable(id):
			continue
		var d := absf(float(station_x[id]) - lamp_x)
		if d <= best_d:
			best_d = d
			best = id
	return best


## A station can be used now. The Tree waits for its tickets; the chalk desk and the Hourglass
## only re-read (they are places to stand, the chalk is the content).
func usable(id: StringName) -> bool:
	match id:
		TREE:
			return tickets_landed and (not tree_lit or tree_buyer.is_valid())
		CODEX_DESK:
			return true
		CHALK_DESK, HOURGLASS:
			return true
	return false


## One frame. `axis` −1…1 from move_left/move_right. Returns the events of this frame.
func step(delta: float, axis: float) -> Array[StringName]:
	var ev: Array[StringName] = []
	if phase == PHASE_LAUNCHED:
		return ev
	t += delta
	_step_chalk(delta, ev)
	_step_payout(delta, ev)
	_step_walk(delta, axis, ev)
	_step_dark(delta, ev)
	return ev


func _step_chalk(delta: float, ev: Array[StringName]) -> void:
	if phase == PHASE_COLD_OPEN:
		if t < stats.chalk_start_s:
			return
		phase = PHASE_CHALK
	if chalk_done():
		if phase == PHASE_CHALK:
			_after_chalk(ev)
		return
	if _rest > 0.0:
		_rest -= delta
		return
	var before := chars
	chars = minf(chars + delta * stats.chalk_chars_per_s, float(lines[line_index].length()))
	if before == 0.0 and chars > 0.0:
		ev.append(EV_CHALK_STROKE)
		can_move = true                      # movement unlocks on the first chalk stroke (beat 7)
	if chars >= float(lines[line_index].length()):
		_finish_line(ev)


func _finish_line(ev: Array[StringName]) -> void:
	line_index += 1
	chars = 0.0
	_rest = stats.chalk_line_rest_s
	ev.append(EV_CHALK_LINE)
	if chalk_done() and phase == PHASE_CHALK:
		_after_chalk(ev)


func _after_chalk(ev: Array[StringName]) -> void:
	can_move = true
	if paid > 0 and not tickets_landed:
		phase = PHASE_PAYOUT
		payout_t = 0.0
		ev.append(EV_PAYOUT)
	else:
		phase = PHASE_FREE


## Seconds the whole payout takes (the last ticket lands).
func payout_length_s() -> float:
	return stats.ticket_flight_s + stats.ticket_stagger_s * float(maxi(0, tickets_drawn() - 1))


## Tickets drawn in flight (1 ticket = 1 Ember, capped for the eye; the plate shows the total).
func tickets_drawn() -> int:
	return mini(paid, stats.tickets_drawn_max)


func _step_payout(delta: float, ev: Array[StringName]) -> void:
	if phase != PHASE_PAYOUT:
		return
	payout_t += delta
	if payout_t >= payout_length_s():
		tickets_landed = true
		phase = PHASE_FREE
		ev.append(EV_TICKETS_LANDED)


func _step_walk(delta: float, axis: float, ev: Array[StringName]) -> void:
	if not can_move or codex_open:
		return
	var dir := clampf(axis, -1.0, 1.0)
	if absf(dir) > 0.01:
		walk_target = NAN                    # the keys take over from a click
	elif not is_nan(walk_target):
		var gap := walk_target - lamp_x
		if absf(gap) <= 1.0:
			walk_target = NAN
		else:
			dir = signf(gap)
	var step_px := dir * stats.lamp_speed_px_s * delta
	if not is_nan(walk_target) and absf(walk_target - lamp_x) < absf(step_px):
		step_px = walk_target - lamp_x
	var x := clampf(lamp_x + step_px, stats.lamp_min_x, stats.lamp_max_x)
	if not gate_open() and x > stats.dark_threshold_x:
		x = stats.dark_threshold_x           # the dark will not let the lamp pass
		if not guttered:
			guttered = true
			ev.append(EV_GUTTER)
		walk_target = NAN
	elif x < stats.dark_threshold_x - stats.lamp_reach_px:
		guttered = false
	lamp_x = x
	for id: StringName in STATIONS:
		if station_x.has(id) and not reached.has(id) and absf(float(station_x[id]) - lamp_x) <= stats.lamp_reach_px:
			reached[id] = true
			ev.append(EV_REACHED)
	if gate_open() and lamp_x >= stats.launch_x and phase == PHASE_FREE:
		phase = PHASE_LAUNCHED
		ev.append(EV_LAUNCH)


func _step_dark(delta: float, ev: Array[StringName]) -> void:
	if lamp_down and can_move:
		dark_t += delta
		if not dark_revealed and dark_t >= stats.dark_reveal_s:
			dark_revealed = true
			ev.append(EV_DARK_REVEAL)
	else:
		dark_t = 0.0


## The interact press: closes an open Codex page; at the Chalk Desk or nowhere, completes a chalk
## line being written (assist A1); else uses the station in reach. Returns the events.
func use() -> Array[StringName]:
	var ev: Array[StringName] = []
	if phase == PHASE_LAUNCHED:
		return ev
	if codex_open:
		codex_open = false
		ev.append(EV_CODEX_CLOSED)
		return ev
	var id := focus()
	var writing := (phase == PHASE_CHALK or phase == PHASE_COLD_OPEN) and not chalk_done() and chars > 0.0
	if writing and (id == &"" or id == CHALK_DESK):
		chars = float(lines[line_index].length())
		_finish_line(ev)
		_rest = 0.0
		return ev
	match id:
		TREE:
			var bought: StringName = &"lamp"
			if tree_buyer.is_valid():
				bought = StringName(tree_buyer.call())
			if bought != &"":
				last_node = bought
				tree_lit = true
				ev.append(EV_TREE_LIT)
		CODEX_DESK:
			codex_open = true
			codex_read = true
			ev.append(EV_CODEX_OPEN)
	if id != &"":
		used[id] = true
	return ev


## A purchase made at the Tree station screen (Q-T326): the `tree_buyer` opened the screen and
## returned nothing; the scene reports the node here once it is bought. Lights the gate.
func note_tree_bought(id: StringName) -> Array[StringName]:
	var ev: Array[StringName] = []
	if id == &"" or phase == PHASE_LAUNCHED:
		return ev
	last_node = id
	tree_lit = true
	used[TREE] = true
	ev.append(EV_TREE_LIT)
	return ev


## Close the Codex page without using anything (ui_cancel). True when a page was open.
func close_codex() -> bool:
	if not codex_open:
		return false
	codex_open = false
	return true


## Lantern up/down in the Ruins (lantern_toggle): the beat 15 pre-echo.
func toggle_lamp() -> void:
	lamp_down = not lamp_down


## Walk the lamp toward logical `x` (a click). Ignored before movement unlocks.
func walk_to(x: float) -> void:
	if can_move and not codex_open:
		walk_target = clampf(x, stats.lamp_min_x, stats.lamp_max_x)
