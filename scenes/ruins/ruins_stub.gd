extends Control
## The Ruins of the Ninth Sky, first arrival (GDD §6.4), adrift in a dimmed aether (ART-001 §16) — a stub: the hub exists outside the loop,
## so this is where the player lands after THE PRETENCE. It saves the anchored profile at the
## allowed `ruins_entry` reason (SYS-001 §8) and returns to the cabinet's title.

var _t := 0.0
var _font: Font
var _ready_for_input := false


func _ready() -> void:
	Look.t = 1.0                       # past the Pretence: the Aether (ART-001 §16)
	RenderingServer.set_default_clear_color(Pal.VOID_0)
	_font = ThemeDB.fallback_font
	mouse_filter = Control.MOUSE_FILTER_STOP
	var loaded := SaveService.load_slot(&"profile")
	var profile: Dictionary = loaded.payload if loaded.ok else {}
	profile["act0_complete"] = true
	profile["pretence_seen"] = true
	SaveService.save_slot(&"profile", profile, &"ruins_entry")
	AudioService.set_chant(0.08)
	get_tree().create_timer(3.0).timeout.connect(func() -> void: _ready_for_input = true)


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
	var top := base + Vector2(0, -60.0 * k)
	draw_line(base, top.round(), Pal.GAS_2, 2.0)
	for i in 3:
		var y := lerpf(base.y, top.y, 0.35 + i * 0.2)
		var dir := -1.0 if i % 2 == 0 else 1.0
		draw_line(Vector2(320, y).round(), (Vector2(320 + dir * 14.0 * k, y - 10.0 * k)).round(), Pal.GAS_1, 1.0)
	if k >= 1.0:
		var flicker := 1.0 if int(_t * 7.0) % 9 != 0 else 0.0
		draw_circle(top.round(), 4.0, Pal.GAS_3)
		draw_circle(top.round(), 2.0 if flicker > 0.0 else 1.0, Pal.GAS_5)
	if _t > 1.0:
		_centered(90, tr("RUINS_TITLE"), 14, Pal.BONE_4)
	if _t > 2.5:
		_centered(290, tr("RUINS_LINE_1"), 8, Pal.BONE_2)
	if _ready_for_input and int(_t * 1.5) % 2 == 0:
		_centered(330, tr("RUINS_CONTINUE"), 8, Pal.BONE_1)
