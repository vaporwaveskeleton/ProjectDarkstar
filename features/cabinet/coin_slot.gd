class_name CoinSlot
extends Control
## The coin door on the Cabinet's bezel (WARP-001 W0-01; owner request 2026-11-18, TECH-001
## §11.2). A new cabinet has hazard tape over the slit, as if coins were forbidden. After a few
## moments a prompt teaches the two inputs the attract screen needs:
##   tape  — drag it off with the mouse, or hold accept (gamepad / keys) while the door has focus;
##   coin  — click the slit, or press accept: one credit, spent by New Vigil.
## Placed at CabinetBezel.coin_plate(). Draws its own prompt on the print beside the door (never over the screen), pointing at it.
## Holds no saved state: the attract screen saves "tape peeled" when `tape_peeled` fires.

signal tape_peeled
signal credit_inserted

enum Phase { TAPED, FALLING, OPEN, DROPPING, CREDITED }

## Tape strip end points, local to the plate (it crosses the slit diagonally).
const TAPE_A := Vector2(-3, 38)
const TAPE_B := Vector2(59, 10)
const TAPE_W := 11.0
const STRIPE := 6.0                ## px per hazard stripe along the tape

@export var tuning: CabinetBootTuning

var phase: int = Phase.TAPED
var peel := 0.0                    ## 0 stuck … 1 off
var hint_armed := false            ## the attract screen arms the prompt delay once it is interactive
var hint_visible := false
var gamepad := false               ## the attract screen sets this from its InputModeTracker
var _hint_t := 0.0
var _holding := false
var _dragging := false
var _drag_from := Vector2.ZERO
var _grab := Vector2.ZERO
var _anim := 0.0
var _await_release := false
var _t := 0.0
var _face: CoinDoorFace
var _text_cache: Dictionary = {}


func _ready() -> void:
	focus_mode = Control.FOCUS_ALL
	mouse_filter = Control.MOUSE_FILTER_STOP
	mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND
	position = CabinetBezel.coin_plate().position
	size = CabinetBezel.coin_plate().size
	_face = CoinDoorFace.new()
	add_child(_face)
	_face.fit_to(Rect2(Vector2.ZERO, size))


## The tape came off on an earlier visit (profile `cabinet_tape_peeled`).
func set_peeled() -> void:
	peel = 1.0
	phase = Phase.OPEN


## The drawn door (a child behind this control's own drawing), for tests and captures.
func door_face() -> CoinDoorFace:
	return _face


func has_credit() -> bool:
	return phase == Phase.CREDITED


## True while the player is mid-gesture or a credit is waiting: attract must not leave for the demo.
func is_busy() -> bool:
	return _holding or _dragging or phase in [Phase.FALLING, Phase.DROPPING, Phase.CREDITED]


## Drop a coin. Only an open, empty slot takes one.
func insert() -> bool:
	if phase != Phase.OPEN:
		return false
	phase = Phase.DROPPING
	_anim = 0.0
	hint_visible = false
	AudioService.play(&"coin")
	return true


## New Vigil spent the credit; the slot takes coins again.
func spend() -> void:
	if phase == Phase.CREDITED:
		phase = Phase.OPEN


func _process(delta: float) -> void:
	_t += delta
	if hint_armed and not hint_visible and phase in [Phase.TAPED, Phase.OPEN]:
		_hint_t += delta
		if _hint_t >= tuning.tape_hint_delay:
			hint_visible = true
	match phase:
		Phase.TAPED:
			if _holding and has_focus():
				_set_peel(peel + delta / tuning.tape_hold_seconds)
		Phase.FALLING:
			_anim += delta
			if _anim >= tuning.tape_fall_seconds:
				phase = Phase.OPEN
		Phase.DROPPING:
			_anim += delta
			if _anim >= tuning.coin_drop_seconds:
				phase = Phase.CREDITED
				credit_inserted.emit()
	queue_redraw()


func _set_peel(value: float) -> void:
	if phase != Phase.TAPED:
		return
	peel = clampf(maxf(peel, value), 0.0, 1.0)
	if peel >= 1.0:
		phase = Phase.FALLING
		_anim = 0.0
		_holding = false
		_dragging = false
		_await_release = true          # the hold that peeled must not also drop the coin
		hint_visible = hint_armed      # the next step's prompt follows at once
		AudioService.play(&"tape_peel")
		tape_peeled.emit()


func _gui_input(event: InputEvent) -> void:
	if event is InputEventMouseButton and (event as InputEventMouseButton).button_index == MOUSE_BUTTON_LEFT:
		var mb := event as InputEventMouseButton
		if mb.pressed:
			grab_focus()
			if phase == Phase.TAPED and _on_tape(mb.position):
				_dragging = true
				_drag_from = mb.position
				_grab = mb.position
			elif phase == Phase.OPEN and CabinetBezel.slit(Rect2(Vector2.ZERO, size)).grow(10).has_point(mb.position):
				insert()
		else:
			_dragging = false
		accept_event()
	elif event is InputEventMouseMotion and _dragging:
		_grab = (event as InputEventMouseMotion).position
		_set_peel(_grab.distance_to(_drag_from) / tuning.tape_drag_px)
		accept_event()
	elif InputLabels.is_accept(event):
		if event.is_echo():
			accept_event()
			return
		if event.is_pressed():
			if not _await_release:
				if phase == Phase.TAPED:
					_holding = true
				elif phase == Phase.OPEN:
					insert()
		else:
			_holding = false
			_await_release = false
		accept_event()


func _notification(what: int) -> void:
	if what == NOTIFICATION_FOCUS_EXIT:
		_holding = false


func _on_tape(p: Vector2) -> bool:
	return Geometry2D.get_closest_point_to_segment(p, TAPE_A, TAPE_B).distance_to(p) <= TAPE_W


# --- drawing ---

func _draw() -> void:
	var plate := Rect2(Vector2.ZERO, size)
	var ready_glow := 0.0
	if phase == Phase.OPEN and hint_visible:
		ready_glow = 0.5 + 0.5 * sin(_t * 5.0)
	elif phase == Phase.CREDITED:
		ready_glow = 1.0
	_face.glow = ready_glow
	CabinetBezel.draw_price(self, _text_cache, plate, tr("CAB_COIN_PRICE"))
	if phase == Phase.DROPPING:
		_draw_coin(clampf(_anim / tuning.coin_drop_seconds, 0.0, 1.0))
	match phase:
		Phase.TAPED:
			_draw_tape_stuck()
		Phase.FALLING:
			_draw_tape_falling(_anim / tuning.tape_fall_seconds)
	if has_focus():
		draw_rect(plate.grow(2), Look.c(Pal.GAS_4), false, 1.0)
	if hint_visible and phase in [Phase.TAPED, Phase.OPEN, Phase.FALLING]:
		_draw_hint()


## A coin glides into the slit edge-on and vanishes.
func _draw_coin(k: float) -> void:
	var s := CabinetBezel.slit(Rect2(Vector2.ZERO, size))
	var c := Vector2(s.get_center().x, lerpf(-14.0, s.get_center().y, k * k))
	var w := lerpf(7.0, 1.0, k)
	draw_rect(Rect2(c - Vector2(w, 7), Vector2(w * 2.0, 14)), Look.c(Pal.GAS_3))
	draw_rect(Rect2(c - Vector2(w, 7), Vector2(w * 2.0, 14)), Look.c(Pal.GAS_5), false, 1.0)


## The stuck length runs from the peel point to TAPE_B; the peeled flap hangs from the peel point
## toward the hand (or droops when let go), adhesive side out.
func _draw_tape_stuck() -> void:
	var p := TAPE_A.lerp(TAPE_B, peel)
	_strip(p, TAPE_B, true)
	if peel <= 0.0:
		return
	var flap_len := TAPE_A.distance_to(TAPE_B) * peel
	var dir := Vector2(-0.35, 1.0).normalized().rotated(sin(_t * 2.0) * 0.08)
	if _dragging and _grab.distance_to(p) > 1.0:
		dir = (_grab - p).normalized()
	_strip(p, p + dir * flap_len, false)


func _draw_tape_falling(k: float) -> void:
	var drop := Vector2(-6.0 * k, 220.0 * k * k)
	var rot := 0.9 * k
	var mid := (TAPE_A + TAPE_B) * 0.5
	var a := mid + (TAPE_A - mid).rotated(rot) + drop
	var b := mid + (TAPE_B - mid).rotated(rot) + drop
	_strip(a, b, true)


## One length of tape from `a` to `b`: hazard stripes on the face, plain on the adhesive side.
func _strip(a: Vector2, b: Vector2, face: bool) -> void:
	var length := a.distance_to(b)
	if length < 0.5:
		return
	var along := (b - a) / length
	var n := along.orthogonal() * TAPE_W * 0.5
	if not face:
		var quad := PackedVector2Array([a + n, b + n, b - n, a - n])
		draw_colored_polygon(quad, Look.c(Pal.BONE_3))
		Pal.glow_polyline(self, quad, Look.c(Pal.BONE_4), Look.c(Pal.BONE_1))
		return
	var d := 0.0
	var i := 0
	while d < length:
		var e := minf(d + STRIPE, length)
		var s0 := a + along * d
		var s1 := a + along * e
		var col := Look.c(Pal.GAS_4) if i % 2 == 0 else Look.c(Pal.VOID_0)
		draw_colored_polygon(PackedVector2Array([s0 + n, s1 + n, s1 - n, s0 - n]), col)
		d = e
		i += 1
	draw_polyline(PackedVector2Array([a + n, b + n, b - n, a - n, a + n]), Look.c(Pal.GAS_2), 1.0)


const HINT_X := 78.0               ## plate-local x where the prompt starts: just right of the printed column
const HINT_W := 96.0               ## px: the print beside the column is at least this wide at every aspect


## The prompt sits on the print to the right of the door's column (never over the screen), wrapped to
## fit, with an arrow back to the door.
func _draw_hint() -> void:
	var text := hint_text()
	if text == "":
		return
	var blink: bool = int(_t * 1.5) % 2 == 0 or bool(SettingsService.get_value(&"photosensitivity"))
	var col := Look.c(Pal.GAS_4) if blink else Look.c(Pal.GAS_2)
	var sf := CabinetSurface.default() as CabinetSurface
	var cap := sf.price_cap * 1.1
	var n := BezelText.line_count(text, cap, sf.price_stroke, sf.price_tracking, HINT_W)
	var pitch := cap * 1.7
	var y := size.y * 0.5 - n * pitch * 0.5
	BezelText.draw(self, _text_cache, text, Vector2(HINT_X, y), false, cap, sf.price_stroke, sf.price_tracking, col, 0.0, HINT_W)
	var tail := Vector2(HINT_X - 4.0, size.y * 0.5)
	var tip := Vector2(size.x + 14.0, tail.y)
	draw_line(tail, tip, col, 1.0)
	draw_line(tip, tip + Vector2(4, -4), col, 1.0)
	draw_line(tip, tip + Vector2(4, 4), col, 1.0)


## The current prompt, worded for the device in use.
func hint_text() -> String:
	var accept := InputLabels.accept(gamepad)
	match phase:
		Phase.TAPED:
			return tr("CAB_HINT_PEEL_HOLD") % accept if gamepad else tr("CAB_HINT_PEEL_DRAG")
		Phase.OPEN, Phase.FALLING:
			return tr("CAB_HINT_INSERT_PRESS") % accept if gamepad else tr("CAB_HINT_INSERT_CLICK")
	return ""
