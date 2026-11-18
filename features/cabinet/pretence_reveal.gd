class_name PretenceReveal
extends Node
## THE PRETENCE (GDD §6.1 A0-3, WARP-001 W0-07 "Pretence Tear" and W0-08 "Costume Removal").
## The arcade showed a black vacuum; that was the lie. When the costume falls the Aether rises — space as
## it really is, full of coloured fog and drifting life (ART-001 §16) — and then the entity drinks it.
## The cabinet's credits stutter, the sound dies, "THAT WAS A PRETENCE." The bezels crack and
## fall away and the field opens to its true width; the scanlines and curvature drain off; a hole
## opens where a star should be and drinks the sky, the readouts and the light — and inside it,
## for the first time, the thing is drawn as it really is: the same generated body, horror dial up (ART-001 §14).
## Input is never required (agency window 0 s). Skippable once seen (GDD §10).

signal finished

@export var maw: MawView
@export var aether: ColorRect

var _game: Node
var _skippable := false
var _running := false
var _tweens: Array[Tween] = []
var _aether_time := 0.0


func play(game: Node, skippable: bool) -> void:
	_game = game
	_skippable = skippable
	_running = true
	var world: ArcadeWorld = game.world
	var hud: CabinetHud = game.hud
	var messages: CabinetMessages = game.messages
	var crt := (game.crt as ColorRect).material as ShaderMaterial
	world.paused_sim = true
	world.vigil.input_enabled = false
	set_process(true)

	# 1 — the credits stutter and the sound dies
	messages.credits_frozen = true
	_tween().tween_property(messages, "glitch", 1.0, 1.0)
	_tween().tween_method(func(v: float) -> void: crt.set_shader_parameter(&"tear", v), 0.0, 0.7, 1.2)
	AudioService.silence(1.3)
	await _wait(1.4)
	if not _running:
		return
	# 2 — the line
	messages.clear()
	messages.entity_line(tr("REVEAL_PRETENCE"), 3.4)
	AudioService.play(&"wake_hit")
	await _wait(3.4)
	if not _running:
		return
	# 3 — the costume comes off (W0-08)
	_tween().tween_property(hud, "crack", 1.0, 0.5)
	AudioService.play(&"geode_break")
	await _wait(0.6)
	if not _running:
		return
	AudioService.play(&"segment_knocked")
	_tween().tween_property(hud, "peel", 1.0, 1.4).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_IN)
	_tween().tween_method(func(v: float) -> void: crt.set_shader_parameter(&"costume", v), 1.0, 0.0, 2.2)
	_tween().tween_method(func(v: float) -> void: crt.set_shader_parameter(&"tear", v), 0.7, 0.0, 1.6)
	# the neon gives way, entry by entry, to the base palette, and the AETHER rises into the vacuum (ART-001 §15–§16)
	var fog := aether.material as ShaderMaterial
	_tween().tween_method(func(v: float) -> void: Look.t = v, 0.0, 1.0, 2.6).set_trans(Tween.TRANS_SINE)
	_tween().tween_method(func(v: float) -> void: fog.set_shader_parameter(&"amount", v), 0.0, 1.0, 3.2).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_OUT)
	world.stars.show_seams = false
	await _wait(2.2)
	if not _running:
		return
	# 4 — the hole where a star should be drinks the sky, the readouts and the light
	maw.visible = true
	AudioService.play(&"entity_unmade", -6.0)
	_tween().tween_property(maw, "radius", 96.0, 6.0).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_OUT)
	_tween().tween_property(world.stars, "pull", 1.0, 8.0).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_IN)
	_tween().tween_property(hud, "eaten", 1.0, 6.0)
	# the only true black is the entity: it drinks the aether's colour and fog (ART-001 §16.1)
	_tween().tween_method(func(v: float) -> void: fog.set_shader_parameter(&"drain", v), 0.0, 1.0, 9.0).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_IN)
	await _wait(2.5)
	if not _running:
		return
	_tween().tween_property(maw, "reveal", 1.0, 4.0)
	await _wait(2.5)
	if not _running:
		return
	messages.entity_line(tr("REVEAL_ONE_SKY_LESS"), 3.2)
	AudioService.play(&"wake_hit", -4.0)
	await _wait(4.0)
	if not _running:
		return
	# 5 — the dark closes over everything
	_tween().tween_property(maw, "radius", 420.0, 2.0).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_IN)
	await _wait(3.0)
	_finish()


func _process(_delta: float) -> void:
	if not _running or _game == null:
		return
	var world: ArcadeWorld = _game.world
	world.stars.queue_redraw()
	_aether_time += _delta
	(aether.material as ShaderMaterial).set_shader_parameter(&"time_s", _aether_time)


func _unhandled_input(event: InputEvent) -> void:
	if not _running or not _skippable:
		return
	if event.is_action_pressed(&"ui_accept") or event.is_action_pressed(&"ui_cancel") or event.is_action_pressed(&"pause"):
		get_viewport().set_input_as_handled()
		_finish()


func _finish() -> void:
	if not _running:
		return
	_running = false
	Look.t = 1.0
	for t in _tweens:
		if t.is_valid():
			t.kill()
	finished.emit()


func _tween() -> Tween:
	var t := create_tween()
	_tweens.append(t)
	return t


func _wait(seconds: float) -> Signal:
	return get_tree().create_timer(seconds).timeout
