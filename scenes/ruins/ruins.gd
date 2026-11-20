extends Control
## The Ruins of the Ninth Sky (GDD §6.4): the hub outside the loop, where the player lands after THE
## PRETENCE and after every run. The first visit is the game's diegetic onboarding (LOOP-001 §10.5;
## NARR-001 §5.7; SLICE beats 7–11): no tutorial text, no menu; every interaction is a place.
##
## The look is RuinsLook (TECH-001 §2.9 part C), instanced from `look_scene` on a canvas layer
## behind the chalk. The rules of the visit are RuinsOnboarding (pure, tested); this scene feeds it
## input, mirrors its state into the lit hall (pilot lamp, station chalk, tickets, Tree lamp,
## Hourglass sand) and writes its chalk with VectorLabel.
##
## Arrival goes to RunSession (TECH-001 §4.2a): the Act 0 bank, the Iteration start and the
## `ruins_entry` saves all happen there (Q-T142); this scene never writes Ember or a save slot.
## The first visit is the visit that banks Act 0, or one the Unmaking marks `first_visit`.
## Clock (Q-T162, settled 2026-11-19): on the first visit the Hourglass holds its sand
## (pause reason `first_glass`) until the launch; on later visits it runs here as everywhere.
##
## Launch (beat 11): the hangar mouth is dark until a Lantern Tree lamp is lit; the pilot lamp
## gutters at the dark and will not pass. Walking it into the lit mouth calls `launch()`, the one
## place a run starts from the Ruins. `ui_cancel` closes the Codex page; otherwise it (or `pause`) opens the
## pause screen (Q-T190, ruled): Resume, Settings, Leave for the Title with a confirm; the clock and the
## tree are held while it is open (`ruins_menu`).
##
## Sound hooks (Q-T194, ruled; the Aether sound chat fills them): the hall bed `AMBIENCE_ID` (set on
## entry; AudioService ignores an id it has no bed for), and the one-shot cues in `CUES`, played only
## when the cue exists. Chalk has its own cue, never `lie_tell_chalk`.
##
## Lantern Tree station (Q-T191, built for the tier-1 handling nodes): using the Tree buys the next
## unbought node of `tree_stock` at the SYS-001 §7.7 tier-1 price (RunSessionCore.buy_tree_node, one
## `tree_purchase` profile write) and lights that node's lamp (`look.light_lamp`). Nothing affordable
## buys nothing and lights nothing. The gate rule (`RuinsOnboarding.gate_open`) stays: a lamp burns.

const STATS := preload("res://data/interactions/ruins_onboarding.tres")
const TREE_STOCK := preload("res://data/lantern_tree/tier1_stock.tres")
const SECTOR_ROUTE := &"sector"
const TITLE_ROUTE := &"attract"
## ✱ seconds before ui_cancel can leave for the title (a stray press on arrival never quits).
const PAUSE_SCENE := preload("res://scenes/sector/pause_screen.tscn")
## The Ruins hall's ambience bed id (AUDIO-001; Q-T194). Level drops with the pilot lamp down.
const AMBIENCE_ID := &"ruins_hall"
## ✱ ambience level with the lamp up and with it down (the hall leans in when you go dark).
const AMBIENCE_LEVEL := 0.8
const AMBIENCE_LEVEL_DARK := 0.45
## Every one-shot cue the Ruins calls (Q-T194): chalk stroke, payout clatter, tickets settling, the
## lamp guttering at the dark, a Tree lamp catching, a Codex page turning, the hidden chalk showing,
## a station coming into reach.
const CUES: Array[StringName] = [&"ruins_chalk_write", &"ruins_ticket_payout", &"ruins_tickets_land",
	&"ruins_lamp_gutter", &"ruins_tree_lamp", &"ruins_codex_page", &"ruins_dark_chalk", &"ruins_station_near"]
## ✱ seconds the Cabinet's marquee shows SCORE BANKED before INSERT CREDIT returns.
const MARQUEE_BANKED_S := 5.0
## ✱ chalk face: cap height and stroke (logical px) for the slate, the floor and the marquee.
const SLATE_SIZE := 7.0
const FLOOR_SIZE := 5.0
const SLATE_ORIGIN := Vector2(128.0, 150.0)
const SLATE_LINE_PX := 15.0
const SLATE_WIDTH := 220.0

var _t := 0.0
## Route params, kept until the deferred arrival (SceneRouter calls on_route_entered after _ready).
var _params: Dictionary = {}
## Who receives the route request (SceneRouter unless a test stubs it): needs go_to(id, params).
var router: Object
## The run core launches go through (RunSession.core unless a test injects one).
var session: RunSessionCore
## True once a launch has been requested: one launch per visit.
var launched := false
## The Ruins look (features/aether/ruins_look.tscn). Null = the dimmed-aether stand-in.
@export var look_scene: PackedScene
@export var stats: RuinsOnboardingStats = STATS
## The nodes the Tree station sells, in order, and their price (data/lantern_tree/tier1_stock.tres).
@export var tree_stock: LanternTreeStock = TREE_STOCK
## The instanced look, or null.
var look: RuinsLook
## The rules of this visit (built on arrival).
var onboarding: RuinsOnboarding
## Ember the Act 0 bank paid on this arrival.
var paid := 0
var _arrived := false
var _holding_clock := false
var _lamp: PilotLamp
var _tickets: TicketFlight
var _marks: Dictionary = {}
var _slate: Array[VectorLabel] = []
var _tree_chalk: VectorLabel
var _glass_chalk: VectorLabel
var _plate: VectorLabel
var _marquee: VectorLabel
var _dark_chalk: VectorLabel
var _page_title: VectorLabel
var _page_body: VectorLabel
var _page_header: VectorLabel
var _marquee_t := -1.0
var _dark_alpha := 0.0
var _chalk_face: VectorFace
var _floor_face: VectorFace
var _dust: DustMotes
var _menu_paused := false
var _last_focus: StringName = &""
@onready var _overlays: ScreenStack = %Overlays

# --- automation reads (core/automation/ui_view.gd `ruins/onboarding`): scalars only ---------------
var beat: String:
	get: return String(onboarding.phase) if onboarding else ""
var focus_id: String:
	get: return String(onboarding.focus()) if onboarding else ""
var lamp_x: float:
	get: return onboarding.lamp_x if onboarding else 0.0
var gate_open: bool:
	get: return onboarding.gate_open() if onboarding else false
var tickets_landed: bool:
	get: return onboarding.tickets_landed if onboarding else false
var codex_open: bool:
	get: return onboarding.codex_open if onboarding else false
var codex_read: bool:
	get: return onboarding.codex_read if onboarding else false
var chalk_lines: int:
	get: return onboarding.line_index if onboarding else 0
var first_visit: bool:
	get: return onboarding.first_visit if onboarding else false
var clock_held: bool:
	get: return _holding_clock
var paid_ember: int:
	get: return paid
var dark_revealed: bool:
	get: return onboarding.dark_revealed if onboarding else false


func _ready() -> void:
	Look.t = 1.0                       # past the Pretence: the Aether (ART-001 §16)
	RenderingServer.set_default_clear_color(Pal.VOID_0)
	if router == null:
		router = get_node_or_null(^"/root/SceneRouter")
	if session == null:
		var rs := get_node_or_null(^"/root/RunSession")
		if rs != null:
			session = rs.get("core") as RunSessionCore
	# Hold the sand from the first frame; the arrival lets it go again on a later visit.
	_hold_clock(true)
	_apply_look()
	_build_text()
	mouse_filter = Control.MOUSE_FILTER_STOP
	# Deferred: runs once, after on_route_entered (or without it when the scene is run directly).
	_arrive.call_deferred()
	AudioService.set_chant(0.08)
	AudioService.set_ambience(AMBIENCE_ID, AMBIENCE_LEVEL)
	_overlays.emptied.connect(_on_overlays_emptied)


func on_route_entered(params: Dictionary) -> void:
	_params = params
	if look != null:
		look.set_first_visit(_bool_param(params, "first_visit"))


static func _bool_param(params: Dictionary, key: String) -> bool:
	for k: Variant in [key, StringName(key)]:
		if params.has(k):
			var v: Variant = params[k]
			return typeof(v) == TYPE_BOOL and bool(v)
	return false


func _arrive() -> void:
	if _arrived:
		return
	_arrived = true
	var vi := -1
	if session != null:
		paid = session.arrive_at_ruins(_params)
		if paid > 0:
			vi = session.act0_vi_banked
	var first := _bool_param(_params, "first_visit") or paid > 0
	if look != null:
		look.set_first_visit(first)
	onboarding = RuinsOnboarding.new(stats)
	onboarding.begin(first, paid, _lines(first, vi), _stations(), _mouth_x())
	if session != null:
		onboarding.tree_buyer = _buy_tree
		onboarding.tree_lit = not session.profile().tree_nodes.is_empty()
	if not first:
		_hold_clock(false)
	if onboarding.tree_lit:
		_light_tree(true)
	_tickets.from = _cabinet_pos() + Vector2(0, -8)
	_tickets.to = _tree_pos() + Vector2(0, -56)


## The chalk for this visit (NARR-001 §5.7): two Sable lines and the tally on the first, one after.
func _lines(first: bool, vi: int) -> PackedStringArray:
	var out := PackedStringArray()
	if first:
		out.append(tr("NARR_SABLE_FIRST_1"))
		out.append(tr("NARR_SABLE_FIRST_2"))
		if vi >= 0:
			out.append(tr("NARR_SABLE_TALLY").format({"n": vi}))
	else:
		out.append(tr("NARR_SABLE_RETURN_1"))
	return out


func _stations() -> Dictionary:
	return {
		RuinsOnboarding.CHALK_DESK: look.chalk_desk_pos.x if look else 204.0,
		RuinsOnboarding.CODEX_DESK: look.codex_desk_pos.x if look else 300.0,
		RuinsOnboarding.TREE: _tree_pos().x,
		RuinsOnboarding.HOURGLASS: look.hourglass_pos.x if look else 438.0,
	}


func _mouth_x() -> float:
	return look.hangar_mouth_rect.position.x if look else 484.0


func _tree_pos() -> Vector2:
	return look.placeholder_tree_pos if look else Vector2(392, 300)


func _cabinet_pos() -> Vector2:
	return look.cabinet_pos if look else Vector2(74, 214)


func _floor_y() -> float:
	return look.floor_y if look else 300.0


## Instance RuinsLook behind the chalk; its stand-in objects are the Ruins' objects for now
## (Q-T193), and the lit props of the visit go on its stage.
func _apply_look() -> void:
	_lamp = PilotLamp.new()
	_lamp.name = "PilotLamp"
	_lamp.steady = bool(SettingsService.get_value(&"photosensitivity"))
	_tickets = TicketFlight.new()
	_tickets.name = "Tickets"
	_tickets.instant = bool(SettingsService.get_value(&"reduced_motion"))
	for id: StringName in RuinsOnboarding.STATIONS:
		var m := StationMark.new()
		m.name = "Mark_%s" % id
		_marks[id] = m
	var page := StationMark.new()
	page.name = "Mark_page"
	page.style = StationMark.Style.PAGE
	_marks[&"page"] = page
	if bool(SettingsService.get_value(&"reduced_motion")):
		for k: Variant in _marks.keys():
			(_marks[k] as StationMark).breath_hz = 0.0
	if look_scene == null:
		for n: Node in [_lamp, _tickets]:
			add_child(n)
		for k: Variant in _marks.keys():
			add_child(_marks[k] as Node)
		return
	look = look_scene.instantiate() as RuinsLook
	if look == null:
		return
	look.show_placeholders = true
	look.set_first_visit(false)
	var layer := CanvasLayer.new()
	layer.name = "LookLayer"
	layer.layer = -1
	add_child(layer)
	layer.add_child(look)
	(%Aether as CanvasItem).visible = false
	var fy := look.floor_y
	look.add_prop(&"mark_chalk_desk", _marks[RuinsOnboarding.CHALK_DESK], Vector2(look.chalk_desk_pos.x, fy + 6))
	look.add_prop(&"mark_codex_desk", _marks[RuinsOnboarding.CODEX_DESK], Vector2(look.codex_desk_pos.x, fy + 6))
	look.add_prop(&"mark_tree", _marks[RuinsOnboarding.TREE], Vector2(look.placeholder_tree_pos.x, fy + 6))
	look.add_prop(&"mark_hourglass", _marks[RuinsOnboarding.HOURGLASS], Vector2(look.hourglass_pos.x, fy + 6))
	look.add_prop(&"mark_page", _marks[&"page"], look.codex_desk_pos + Vector2(0, -36))
	look.add_prop(&"tickets", _tickets, Vector2.ZERO)
	look.add_prop(&"pilot_lamp", _lamp, Vector2(stats.lamp_start_x, fy - 2))
	_dust = DustMotes.new()
	_dust.name = "Dust"
	_dust.still = bool(SettingsService.get_value(&"reduced_motion"))
	look.add_prop(&"dust", _dust, Vector2.ZERO)


func _build_text() -> void:
	var base := VectorText.default_face()
	_chalk_face = base.duplicate_with(SLATE_SIZE, 1.0)
	_chalk_face.jitter = 0.35
	_chalk_face.grain = 0.25
	_chalk_face.seed = 7
	_floor_face = base.duplicate_with(FLOOR_SIZE, 0.8)
	_floor_face.jitter = 0.3
	_floor_face.grain = 0.2
	_floor_face.seed = 11
	for i in 3:
		var l := _label("Slate%d" % i, _chalk_face, Pal.BONE_4, SLATE_ORIGIN + Vector2(0, SLATE_LINE_PX * i),
			SLATE_WIDTH, VectorText.Align.LEFT)
		_slate.append(l)
	var fy := _floor_y()
	_tree_chalk = _label("TreeChalk", _floor_face, Pal.BONE_4, Vector2(_tree_pos().x - 90, fy + 12), 180.0,
		VectorText.Align.CENTER)
	_tree_chalk.key = &"NARR_SABLE_TREE"
	_plate = _label("TicketPlate", _floor_face, Pal.GAS_4, Vector2(_tree_pos().x - 60, fy + 24), 120.0,
		VectorText.Align.CENTER)
	_glass_chalk = _label("GlassChalk", _floor_face, Pal.BONE_4, Vector2(395, fy + 36), 150.0, VectorText.Align.CENTER)
	_marquee = _label("Marquee", _floor_face, Pal.PHOS_4, _cabinet_pos() + Vector2(-60, -46), 120.0,
		VectorText.Align.CENTER)
	_dark_chalk = _label("DarkChalk", _floor_face, Pal.BONE_3, Vector2(120, fy + 36), 260.0, VectorText.Align.CENTER)
	_dark_chalk.key = &"NARR_SABLE_DARK_1"
	var page_face := base.duplicate_with(7.0, 1.0)
	_page_header = _label("PageHeader", base.duplicate_with(5.0, 0.8), Pal.VOID_3, Vector2(200, 82), 240.0,
		VectorText.Align.CENTER)
	_page_header.key = &"RUINS_CODEX_HEADER"
	_page_title = _label("PageTitle", page_face, Pal.VOID_1, Vector2(200, 100), 240.0, VectorText.Align.CENTER)
	_page_title.key = &"CX_PLACE_ACT0_3_TITLE"
	_page_body = _label("PageBody", base.duplicate_with(6.0, 0.9), Pal.VOID_2, Vector2(212, 126), 216.0,
		VectorText.Align.LEFT)
	_page_body.key = &"CX_PLACE_ACT0_3_BODY"
	for l: VectorLabel in [_tree_chalk, _plate, _glass_chalk, _marquee, _dark_chalk, _page_header, _page_title, _page_body]:
		l.modulate.a = 0.0


func _label(n: String, face: VectorFace, col: Color, pos: Vector2, width: float, align: VectorText.Align) -> VectorLabel:
	var l := VectorLabel.new()
	l.name = n
	l.unique_name_in_owner = false
	l.face = face
	l.color = col
	l.alignment = align
	l.max_width = width
	l.position = pos
	l.size = Vector2(width, 40)
	l.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(l)
	return l


## Start a run at Seam 1 and enter it: PM-01 "First Vigil" in the sector (beat 12). Returns false when
## nothing was launched (already launched, no session, or the router refused). The gate is the
## walk (the dark mouth); this is the one place a run starts from the Ruins.
func launch() -> bool:
	if launched or session == null or router == null:
		return false
	if not session.run().is_active():   # a live run (e.g. after a quit to title) is re-entered, not replaced
		session.start_run()
	_hold_clock(false)                  # the sand starts when you leave (beat 11)
	var params := session.enter_seam()
	if params.is_empty():
		return false
	launched = bool(router.call("go_to", SECTOR_ROUTE, params))
	return launched


func _hold_clock(on: bool) -> void:
	if on == _holding_clock or session == null:
		return
	_holding_clock = on
	if on:
		session.pause_clock(RunSessionCore.PAUSE_FIRST_GLASS)
	else:
		session.resume_clock(RunSessionCore.PAUSE_FIRST_GLASS)


func _set_codex_paused(on: bool) -> void:
	if session == null:
		return
	if on:
		session.pause_clock(RunSessionCore.PAUSE_CODEX)
	else:
		session.resume_clock(RunSessionCore.PAUSE_CODEX)


func _exit_tree() -> void:
	AudioService.set_chant(0.0)
	AudioService.set_ambience(&"")
	_release_menu_pause()
	if onboarding != null and onboarding.codex_open:
		_set_codex_paused(false)
	_hold_clock(false)


func _process(delta: float) -> void:
	_t += delta
	if look == null:
		((%Aether as ColorRect).material as ShaderMaterial).set_shader_parameter(&"time_s", _t)
	if onboarding == null:
		return
	var axis := Input.get_axis(&"move_left", &"move_right")
	_react(onboarding.step(delta, axis))
	_mirror(delta)
	queue_redraw()


func _react(events: Array[StringName]) -> void:
	for e: StringName in events:
		match e:
			RuinsOnboarding.EV_CHALK_STROKE:
				_cue(&"ruins_chalk_write")
			RuinsOnboarding.EV_PAYOUT:
				_tickets.play(onboarding.tickets_drawn(), stats.ticket_flight_s, stats.ticket_stagger_s)
				_marquee.key = &"NARR_CAB_SCORE_BANKED"
				_marquee_t = 0.0
				_cue(&"ruins_ticket_payout")
			RuinsOnboarding.EV_TICKETS_LANDED:
				_cue(&"ruins_tickets_land")
			RuinsOnboarding.EV_GUTTER:
				_lamp.gutter()
				_cue(&"ruins_lamp_gutter")
			RuinsOnboarding.EV_TREE_LIT:
				_light_tree(false)
			RuinsOnboarding.EV_CODEX_OPEN:
				_set_codex_paused(true)
				_cue(&"ruins_codex_page")
			RuinsOnboarding.EV_CODEX_CLOSED:
				_set_codex_paused(false)
			RuinsOnboarding.EV_DARK_REVEAL:
				_cue(&"ruins_dark_chalk")
			RuinsOnboarding.EV_LAUNCH:
				launch()


## Plays a Ruins cue when the audio set has it (the Aether sound chat owns them; AUDIO-001).
func _cue(id: StringName) -> void:
	if AudioService.has_cue(id):
		AudioService.play(id)


## The Tree station's purchase (RuinsOnboarding.tree_buyer): the node bought, or &"".
func _buy_tree() -> StringName:
	return session.buy_tree_node(tree_stock) if session != null else &""


## Lights the Tree's lamps: every owned node's lamp on arrival (`instant`), the new one on a purchase.
func _light_tree(instant: bool) -> void:
	if look == null:
		return
	var at := look.placeholder_lamp_positions()
	var owned := session.profile().tree_nodes.size() if session != null else 1
	owned = clampi(owned, 1, at.size())
	if at.size() > 0:
		for i in (owned if instant else 0):
			look.light_lamp(at[i], true)
		if not instant:
			look.light_lamp(at[owned - 1], false)
	if not instant:
		_cue(&"ruins_tree_lamp")


## Mirror the rules into the lit hall and the chalk.
func _mirror(delta: float) -> void:
	var ob := onboarding
	var fy := _floor_y()
	_lamp.visible = ob.can_move
	for k: Variant in _marks.keys():
		(_marks[k] as StationMark).visible = ob.can_move   # Sable's marks show with the lamp
	_lamp.down = ob.lamp_down
	_lamp.walk_speed = Input.get_axis(&"move_left", &"move_right") if ob.can_move and not ob.codex_open else 0.0
	AudioService.set_ambience(AMBIENCE_ID, AMBIENCE_LEVEL_DARK if ob.lamp_down else AMBIENCE_LEVEL)
	var near := ob.focus()
	if near != _last_focus and near != &"":
		_cue(&"ruins_station_near")
	_last_focus = near
	if look != null:
		_lamp.position = Vector2(ob.lamp_x, fy - 2)
		if _dust != null:
			_dust.lights = PackedVector2Array([look.hall_lantern_pos, _lamp.position + Vector2(0, -14)])
			_dust.light_down = ob.lamp_down
		var f := ob.focus()
		for id: StringName in RuinsOnboarding.STATIONS:
			var state := RuinsLook.PROP_IDLE
			if f == id:
				state = RuinsLook.PROP_FOCUSED
			elif ob.used.has(id) or (id == RuinsOnboarding.TREE and ob.tree_lit):
				state = RuinsLook.PROP_USED
			look.set_prop_state(StringName("mark_%s" % id), state)
		look.set_prop_state(&"mark_page", RuinsLook.PROP_USED if ob.codex_read else
			(RuinsLook.PROP_FOCUSED if f == RuinsOnboarding.CODEX_DESK else RuinsLook.PROP_IDLE))
		if session != null:
			var budget := session.stats.iteration_budget_loop_min
			look.set_sand(session.loop_min_left() / budget if budget > 0.0 else 1.0,
				not session.is_clock_paused() and session.iteration().started)
	_tickets.visible = ob.phase == RuinsOnboarding.PHASE_PAYOUT or ob.tickets_landed and ob.paid > 0
	# the slate: Sable's lines as written so far
	var y := SLATE_ORIGIN.y
	for i in _slate.size():
		_slate[i].text = ob.chalk_text(i)
		_slate[i].position.y = y
		if _slate[i].text != "":
			y += maxf(SLATE_LINE_PX, _slate[i].get_combined_minimum_size().y + 4.0)
	# chalk that writes itself where the lamp has been: under the Tree once its tickets hang there,
	# by the Hourglass once the lamp has stood at it
	_fade(_tree_chalk, ob.first_visit and ob.tickets_landed, delta)
	_plate.text = tr("RUINS_TICKET_PLATE").format({"n": _ember_now()})
	_fade(_plate, ob.tickets_landed and (ob.paid > 0 or not ob.first_visit), delta)
	_glass_chalk.key = &"NARR_SABLE_GLASS" if ob.first_visit else &"NARR_SABLE_GLASS_RETURN"
	_fade(_glass_chalk, ob.reached.has(RuinsOnboarding.HOURGLASS), delta)
	# the marquee: SCORE BANKED for a while, then the Cabinet's own attract line again
	if _marquee_t >= 0.0:
		_marquee_t += delta
		if _marquee_t > MARQUEE_BANKED_S:
			_marquee.key = &"NARR_CAB_ATTRACT_1"
	elif ob.line_index > 0:
		_marquee.key = &"NARR_CAB_ATTRACT_1"
	_fade(_marquee, _marquee.key != &"", delta)
	# the beat 15 pre-echo: chalk you can only read in the dark
	var want_dark := 1.0 if ob.lamp_down and ob.dark_revealed else 0.0
	_dark_alpha = move_toward(_dark_alpha, want_dark, delta * 0.6)
	_dark_chalk.modulate.a = _dark_alpha * 0.8
	for l: VectorLabel in [_page_header, _page_title, _page_body]:
		l.modulate.a = 1.0 if ob.codex_open else 0.0


func _ember_now() -> int:
	return session.profile().ember_banked if session != null else paid


func _fade(l: VectorLabel, on: bool, delta: float) -> void:
	l.modulate.a = move_toward(l.modulate.a, 1.0 if on else 0.0, delta * 1.5)


func _unhandled_input(event: InputEvent) -> void:
	if onboarding == null or launched:
		return
	if event.is_action_pressed(&"ui_cancel") and not event.is_echo():
		get_viewport().set_input_as_handled()
		if onboarding.close_codex():
			_set_codex_paused(false)
		else:
			open_pause()
	elif event.is_action_pressed(&"pause") and not event.is_echo():
		get_viewport().set_input_as_handled()
		open_pause()
	elif event.is_action_pressed(&"ui_accept") and not event.is_echo():
		get_viewport().set_input_as_handled()
		_react(onboarding.use())
	elif event.is_action_pressed(&"lantern_toggle") and not event.is_echo():
		get_viewport().set_input_as_handled()
		onboarding.toggle_lamp()
	elif event is InputEventMouseButton and event.is_pressed() \
			and (event as InputEventMouseButton).button_index == MOUSE_BUTTON_LEFT:
		get_viewport().set_input_as_handled()
		_click((event as InputEventMouseButton).position)


## A click: closes an open page, uses the station under the lamp if the click is on it, else walks
## the lamp there (mouse play, X-4 assist A3).
func _click(screen_pos: Vector2) -> void:
	if onboarding.codex_open:
		_react(onboarding.use())
		return
	var x := (get_global_transform_with_canvas().affine_inverse() * screen_pos).x
	var f := onboarding.focus()
	if f != &"" and absf(float(onboarding.station_x[f]) - x) <= stats.lamp_reach_px:
		_react(onboarding.use())
	else:
		onboarding.walk_to(x)


func _draw() -> void:
	if onboarding != null and onboarding.codex_open:
		# the page, close up: parchment in the lamp's light (not a menu: the world, nearer)
		var r := Rect2(196, 70, 248, 118)
		draw_rect(r.grow(2), Pal.GAS_1)
		draw_rect(r, Pal.BONE_4)
		draw_rect(r.grow(-6), Pal.BONE_3, false, 0.6)
		draw_circle(r.position + Vector2(r.size.x - 22, r.size.y - 22), 8.0, Color(Pal.PHOS_3, 0.8))


## The pause screen (Q-T190, ruled): the tree and the clock hold while it is open.
func open_pause() -> Screen:
	if _overlays == null or not _overlays.is_empty():
		return null
	get_tree().paused = true
	if session != null and not _menu_paused:
		session.pause_clock(RunSessionCore.PAUSE_RUINS_MENU)
		_menu_paused = true
	var pause: Screen = PAUSE_SCENE.instantiate()
	pause.set("leave_to_title", true)
	pause.connect(&"title_requested", _on_title_requested)
	return _overlays.push(pause)


func _on_overlays_emptied() -> void:
	get_tree().paused = false
	_release_menu_pause()


func _release_menu_pause() -> void:
	if _menu_paused and session != null:
		session.resume_clock(RunSessionCore.PAUSE_RUINS_MENU)
	_menu_paused = false


func _on_title_requested() -> void:
	get_tree().paused = false
	_release_menu_pause()
	if router != null:
		router.call("go_to", TITLE_ROUTE)
