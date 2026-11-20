class_name PretenceReveal
extends Node
## THE PRETENCE (GDD §6.1 A0-5, WARP-001 W0-07 "Pretence Tear" and W0-08 "Costume Removal").
## There is no title card (owner direction 2026-11-19; TECH-001 §11.2). After the last credits the costume
## wears out with no words — THE DECAY (CabinetDecay: back to attract, tired phosphor, the skin fails, the
## picture collapses to a dot) — and the tear opens from the dot. The cursed turn (TECH-001 Q-T260–Q-T262):
## the dot is off-centre, where the glass bulged toward the player, and the glass gives as the tear opens.
## The bezels crack and fall away, the scanlines and curvature drain off, the neon turns to the Aether's
## colour and fog rises; a torn hole opens at that dot (the same erasure as the Aether half, never a centred
## disc, never a face) and drinks the sky, the readouts and the light; the spine stars settle on a column
## running out of it and go out one by one, leaving the body as an absence. From the tear to the hand-off
## is 8 s (beat sheet 0:04 → 0:12; Q-T183 B).
## Ending 5 (The Pretence Kept, NARR-001 §9.5): a clean-hands shift first shows Theodora Lune's ten screens,
## each held until a button is pressed, then the Cabinet's last screen THAT WAS A PRETENCE. — the only place
## it is ever shown — and then the Decay as on every clear.
## Input is never required on a normal clear (agency window 0 s). Skippable once seen (GDD §10): one skip
## covers the Decay and the tear.

signal finished

@export var maw: MawView
@export var aether: ColorRect

const ENDING5_KEYS: Array[String] = ["CAB_E5_SCREEN_01", "CAB_E5_SCREEN_02", "CAB_E5_SCREEN_03", "CAB_E5_SCREEN_04", "CAB_E5_SCREEN_05",
	"CAB_E5_SCREEN_06", "CAB_E5_SCREEN_07", "CAB_E5_SCREEN_08", "CAB_E5_SCREEN_09", "CAB_E5_SCREEN_10"]
const ENDING5_AUTO_S := 3.0          ## ✱ dev capture only (`--autopilot`): a held screen advances by itself

## The tear → hand-off, 8.0 s in all (✱ split of the ruled 8 s).
const CRACK_S := 0.6
const PEEL_S := 2.2
const MAW_S := 2.5                    ## the maw opens; test_star_spine relies on maw.reveal starting 2.5 s into stars.pull
const BODY_S := 1.2
const CLOSE_S := 1.5

var decay: CabinetDecay
var _game: Node
var _skippable := false
var _running := false
var _tweens: Array[Tween] = []
var _aether_time := 0.0
var _awaiting_press := false
var _pressed := false
var ending5_shown := false            ## read by CabinetGame for the reveal's boundary save (LOOP-001 §11.6)


## The tear → hand-off length (s), for tests and the timeline docs.
static func tear_to_handoff_s() -> float:
	return CRACK_S + PEEL_S + MAW_S + BODY_S + CLOSE_S


func play(game: Node, skippable: bool, clean_hands: bool = false) -> void:
	_game = game
	_skippable = skippable
	_running = true
	ending5_shown = false
	var world: ArcadeWorld = game.world
	var hud: CabinetHud = game.hud
	var messages: CabinetMessages = game.messages
	var crt: ShaderMaterial = (game.screen as ArcadeScreen).crt_material()
	world.paused_sim = true
	world.vigil.input_enabled = false
	set_process(true)
	messages.credits_frozen = true

	# 0 — ending 5: Theodora's screens and the line (NARR-001 §9.5)
	if clean_hands:
		ending5_shown = true
		await _ending5(messages)
		if not _running:
			return

	# 1 — THE DECAY: the costume wears out, no words (D1–D4)
	decay = _make_decay(game)
	decay.begin(int(hud.hi_score), int(hud.score))
	await decay.finished
	if not _running:
		return
	decay.stop()

	# 2 — the tear opens from the dot; the costume comes off (W0-08)
	messages.clear()
	crt.set_shader_parameter(&"ghost", 0.0)
	crt.set_shader_parameter(&"bleed", 0.0)
	crt.set_shader_parameter(&"sag", 0.0)
	crt.set_shader_parameter(&"collapse_fade", 0.0)
	# the glass that leaned out toward the player gives as the tear opens (Q-T260); the focus stays put
	var lean_v: Variant = crt.get_shader_parameter(&"bulge")
	var lean := 0.0
	if lean_v != null:
		lean = float(lean_v)
	_tween().tween_method(func(v: float) -> void: crt.set_shader_parameter(&"bulge", v), lean, 0.0, CRACK_S)
	_tween().tween_method(func(v: float) -> void: crt.set_shader_parameter(&"collapse", v), CabinetDecay.COLLAPSE_HOLD, 0.0, CRACK_S)
	_tween().tween_method(func(v: float) -> void: crt.set_shader_parameter(&"tear", v), 0.0, 0.7, CRACK_S)
	_tween().tween_property(hud, "crack", 1.0, CRACK_S)
	AudioService.play(&"geode_break")
	await _wait(CRACK_S)
	if not _running:
		return
	AudioService.play(&"segment_knocked")
	var bezel_decay: BezelDecay = game.bezel_decay
	_tween().tween_property(hud, "peel", 1.0, 1.4).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_IN)
	if bezel_decay != null:
		_tween().tween_property(bezel_decay, "fade", 0.0, 1.0)
	_tween().tween_method(func(v: float) -> void: crt.set_shader_parameter(&"costume", v), 1.0, 0.0, PEEL_S)
	_tween().tween_method(func(v: float) -> void: crt.set_shader_parameter(&"tear", v), 0.7, 0.0, 1.6)
	# the neon gives way, entry by entry, to the base palette, and the AETHER rises into the vacuum (ART-001 §15–§16)
	var fog := aether.material as ShaderMaterial
	_tween().tween_method(func(v: float) -> void: Look.t = v, 0.0, 1.0, 2.6).set_trans(Tween.TRANS_SINE)
	_tween().tween_method(func(v: float) -> void: fog.set_shader_parameter(&"amount", v), 0.0, 1.0, 3.2).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_OUT)
	world.stars.show_seams = false
	await _wait(PEEL_S)
	if not _running:
		return

	# 3 — the torn hole, off-centre at the dot, drinks the sky, the readouts and the light. No words (Q-T182),
	# no disc, no eye (Q-T262).
	maw.visible = true
	AudioService.play(&"entity_unmade", -6.0)
	# the wound stays small while the body shows (WOUND_BODY_R), so the column of absences reads below it (Q-T262)
	_tween().tween_property(maw, "radius", MawView.WOUND_BODY_R, 6.0).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_OUT)
	_tween().tween_property(world.stars, "pull", 1.0, 8.0).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_IN)
	_tween().tween_property(hud, "eaten", 1.0, 6.0)
	# the only true black is the entity: it drinks the aether's colour and fog (ART-001 §16.1)
	_tween().tween_method(func(v: float) -> void: fog.set_shader_parameter(&"drain", v), 0.0, 1.0, 9.0).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_IN)
	await _wait(MAW_S)
	if not _running:
		return
	_tween().tween_property(maw, "reveal", 1.0, BODY_S + CLOSE_S)
	await _wait(BODY_S)
	if not _running:
		return
	# 4 — the dark closes over everything
	_tween().tween_property(maw, "radius", MawView.WOUND_CLOSE_R, CLOSE_S).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_IN)
	await _wait(CLOSE_S)
	_finish()


## Theodora's ten screens, each held until a button is pressed, then the line (SYS-001 ending5_line_hold_s).
func _ending5(messages: CabinetMessages) -> void:
	messages.clear()
	var auto := OS.get_cmdline_user_args().has("--autopilot")
	for key in ENDING5_KEYS:
		messages.hold_screen(tr(key))
		_pressed = false
		_awaiting_press = true
		var waited := 0.0
		await get_tree().process_frame   # the press that showed this screen must not also dismiss it
		while _running and not _pressed and not (auto and waited >= ENDING5_AUTO_S):
			await get_tree().process_frame
			waited += get_process_delta_time()
			if Input.is_action_just_pressed(&"ui_accept"):
				_pressed = true
		_awaiting_press = false
		if not _running:
			return
	var tuning := load("res://data/cabinet/cabinet_decay.tres") as CabinetDecayTuning
	messages.hold_screen(tr("REVEAL_PRETENCE"))
	await _wait(tuning.ending5_line_hold_s)
	messages.hold_screen("")


func _make_decay(game: Node) -> CabinetDecay:
	var d := CabinetDecay.new()
	d.name = "Decay"
	d.tuning = load("res://data/cabinet/cabinet_decay.tres") as CabinetDecayTuning
	d.messages = game.messages
	d.crt = (game.screen as ArcadeScreen).crt_material()
	d.registers = (game.screen as ArcadeScreen).get_node_or_null("Registers") as VideoRegisters
	d.bezel = game.bezel_decay
	var m := CabinetHaunts.find_marquee(game) as BezelMarquee
	if m != null:
		d.marquee_drift = CabinetMarqueeDrift.new()
		d.marquee_drift.attach(m)
	d.backdrop = CabinetHaunts.find_backdrop(game)
	d.still = ArcadeButton.is_still()
	var spec := load("res://data/cabinet/cabinet_screen.tres") as CabinetScreenSpec
	d.play_top = spec.strip_rect().end.y / float(spec.grid.y)
	var a := CabinetDecayAudio.new()
	a.name = "DecayAudio"
	a.tuning = d.tuning
	d.add_child(a)
	d.audio = a
	add_child(d)
	return d


func _process(_delta: float) -> void:
	if not _running or _game == null:
		return
	var world: ArcadeWorld = _game.world
	world.stars.queue_redraw()
	_aether_time += _delta
	(aether.material as ShaderMaterial).set_shader_parameter(&"time_s", _aether_time)


func _unhandled_input(event: InputEvent) -> void:
	if not _running:
		return
	var press := event.is_action_pressed(&"ui_accept") or event.is_action_pressed(&"ui_cancel") or event.is_action_pressed(&"pause")
	if not press:
		return
	if _awaiting_press:
		get_viewport().set_input_as_handled()
		_pressed = true
		return
	if _skippable:
		get_viewport().set_input_as_handled()
		_finish()


func _finish() -> void:
	if not _running:
		return
	_running = false
	if decay != null:
		decay.stop()
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
