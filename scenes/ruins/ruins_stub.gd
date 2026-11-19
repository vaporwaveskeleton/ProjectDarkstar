extends Control
## The Ruins of the Ninth Sky, first arrival (GDD §6.4), adrift in a dimmed aether (ART-001 §16) — a stub: the hub exists outside the loop,
## so this is where the player lands after THE PRETENCE. Arrival goes to RunSession (TECH-001 §4.2a):
## the one Act 0 bank, the Iteration start and the `ruins_entry` saves all happen there (Q-T142);
## this stub never touches Ember or a save slot. It returns to the cabinet's title.
## Ruins UI is a later PR: the bank is readable through the `run/session` automation id.

var _t := 0.0
var _font: Font
var _ready_for_input := false
## Route params, kept until the deferred arrival (SceneRouter calls on_route_entered after _ready).
var _params: Dictionary = {}


func _ready() -> void:
	Look.t = 1.0                       # past the Pretence: the Aether (ART-001 §16)
	RenderingServer.set_default_clear_color(Pal.VOID_0)
	_font = ThemeDB.fallback_font
	mouse_filter = Control.MOUSE_FILTER_STOP
	# Deferred: runs once, after on_route_entered (or without it when the scene is run directly).
	_arrive.call_deferred()
	AudioService.set_chant(0.08)
	get_tree().create_timer(3.0).timeout.connect(func() -> void: _ready_for_input = true)


func on_route_entered(params: Dictionary) -> void:
	_params = params


func _arrive() -> void:
	RunSession.core.arrive_at_ruins(_params)


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
	if (event is InputEventKey or event is InputEventJoypadButton or event is InputEventMouseButton) and event.is_pressed():
		get_viewport().set_input_as_handled()
		SceneRouter.go_to(&"attract")


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
		_centered(330, tr("RUINS_CONTINUE"), 8, Pal.BONE_1)
