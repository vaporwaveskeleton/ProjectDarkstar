extends Control
## The Ruins of the Ninth Sky, first arrival (GDD §6.4), adrift in a dimmed aether (ART-001 §16) — a stub: the hub exists outside the loop,
## so this is where the player lands after THE PRETENCE. Arrival goes to RunSession (TECH-001 §4.2a):
## the one Act 0 bank, the Iteration start and the `ruins_entry` saves all happen there (Q-T142);
## this stub never touches Ember or a save slot. Ruins UI is a later PR: the bank is readable through the
## `run/session` automation id.
## The golden path (TECH-001 §2.1): reached from the first Unmaking (route &"aether"); `ui_accept` (or a click)
## launches PM-01 through RunSession (`start_run`, `enter_seam`, then `go_to(&"sector", …)`, §4.2a);
## `ui_cancel` returns to the title.
## TODO(M2 onboarding, beats 7–16): the cold open, Chalk Desk, ticket pay-out, Codex desk, Lantern Tree
## and the physical hangar-mouth launch (research/act1_vertical_slice.md §2) replace this prompt;
## keep `launch()` as the one place a run starts from the Ruins.
## TODO(#73 RuinsLook): the Ruins first-visit look (a child scene this Ruins instances through an
## exported reference; the look only, no input) replaces the dimmed %Aether rect below. `_apply_look()`
## is the hook; TECH-001 §2.9 part C.

var _t := 0.0
var _font: Font
var _ready_for_input := false
## Route params, kept until the deferred arrival (SceneRouter calls on_route_entered after _ready).
var _params: Dictionary = {}
## Who receives the route request (SceneRouter unless a test stubs it): needs go_to(id, params).
var router: Object
## The run core launches go through (RunSession.core unless a test injects one).
var session: RunSessionCore
## True once a launch has been requested: one launch per visit.
var launched := false

const SECTOR_ROUTE := &"sector"
const TITLE_ROUTE := &"attract"


func _ready() -> void:
	Look.t = 1.0                       # past the Pretence: the Aether (ART-001 §16)
	RenderingServer.set_default_clear_color(Pal.VOID_0)
	_font = ThemeDB.fallback_font
	if router == null:
		router = get_node_or_null(^"/root/SceneRouter")
	if session == null:
		var rs := get_node_or_null(^"/root/RunSession")
		if rs != null:
			session = rs.get("core") as RunSessionCore
	_apply_look()
	mouse_filter = Control.MOUSE_FILTER_STOP
	# Deferred: runs once, after on_route_entered (or without it when the scene is run directly).
	_arrive.call_deferred()
	AudioService.set_chant(0.08)
	get_tree().create_timer(3.0).timeout.connect(func() -> void: _ready_for_input = true)


func on_route_entered(params: Dictionary) -> void:
	_params = params


func _arrive() -> void:
	if session != null:
		session.arrive_at_ruins(_params)


## Hook for #73 (RuinsLook): today the dimmed aether rect is the whole look.
func _apply_look() -> void:
	pass


## Start a run at Seam 1 and enter it: PM-01 "First Vigil" in the sector (beat 12). Returns false when
## nothing was launched (already launched, no session, or the router refused).
func launch() -> bool:
	if launched or session == null or router == null:
		return false
	if not session.run().is_active():   # a live run (e.g. after a quit to title) is re-entered, not replaced
		session.start_run()
	var params := session.enter_seam()
	if params.is_empty():
		return false
	launched = bool(router.call("go_to", SECTOR_ROUTE, params))
	return launched


func _exit_tree() -> void:
	AudioService.set_chant(0.0)


func _process(delta: float) -> void:
	_t += delta
	# the aether, dimmed: the first sky has gone dark (ART-001 §16)
	((%Aether as ColorRect).material as ShaderMaterial).set_shader_parameter(&"time_s", _t)
	queue_redraw()


func _unhandled_input(event: InputEvent) -> void:
	if not _ready_for_input:
		return
	if event.is_action_pressed(&"ui_cancel") and not event.is_echo():
		get_viewport().set_input_as_handled()
		if router != null:
			router.call("go_to", TITLE_ROUTE)
	elif (event.is_action_pressed(&"ui_accept") and not event.is_echo()) 			or (event is InputEventMouseButton and event.is_pressed()):
		get_viewport().set_input_as_handled()
		launch()


func _centered(y: float, s: String, size: int, col: Color) -> void:
	var w := _font.get_string_size(s, HORIZONTAL_ALIGNMENT_LEFT, -1, size).x
	draw_string(_font, Vector2(roundf(320.0 - w * 0.5), y), s, HORIZONTAL_ALIGNMENT_LEFT, -1, size, col)


func _draw() -> void:
	var k := clampf(_t / 4.0, 0.0, 1.0)
	# the Lantern Tree as a sapling: one brass stem, one lamp, in the only light there is
	var base := Vector2(320, 250)
	var top := base + Vector2(0, -60.0)   # stem and lamp stand from frame 0: the first focal subject
	draw_circle(top.round(), 18.0, Color(Pal.GAS_1, 0.25))   # banded gas-lamp halo (stepped, no gradient)
	draw_circle(top.round(), 12.0, Color(Pal.GAS_1, 0.4))
	draw_line(base, top.round(), Pal.GAS_2, 2.0)
	for i in 3:
		var y := lerpf(base.y, top.y, 0.35 + i * 0.2)
		var dir := -1.0 if i % 2 == 0 else 1.0
		draw_line(Vector2(320, y).round(), (Vector2(320 + dir * 14.0 * k, y - 10.0 * k)).round(), Pal.GAS_1, 1.0)
	var flicker := 1.0 if int(_t * 7.0) % 9 != 0 else 0.0
	draw_circle(top.round(), 4.0, Pal.GAS_3)
	draw_circle(top.round(), 2.0 if flicker > 0.0 else 1.0, Pal.GAS_5)
	if _t > 1.0:
		_centered(90, tr("RUINS_TITLE"), 14, Pal.BONE_4)
	if _t > 2.5:
		_centered(290, tr("RUINS_LINE_1"), 8, Pal.BONE_2)
	if _ready_for_input and int(_t * 1.5) % 2 == 0:
		_centered(330, tr("RUINS_LAUNCH"), 8, Pal.BONE_1)
