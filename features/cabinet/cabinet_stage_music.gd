class_name CabinetStageMusic
extends Node
## The Act 0 stage loop (TECH-001 Q-T188, ruled built here under Q-T264; AUDIO-001 §12.19): a stage with
## `music` (a0_4, a0_5) plays that chirp loop on BUS-MUS from its READY card to its end, quietly, under the
## chant. W0-11 Wear detunes it by `wear_detune_cents_per_level` per wear level (−4 at a0_4, −6 at a0_5), so
## the machine's tune is already a little sour when the Decay sags it the rest of the way. Slow-motion bends
## it with the chant bed. Not started while AudioService is muted for tests.

const LEVEL_DB := -20.0               ## ✱ under the chant (AUDIO-001 §2.1 layer A sits at −14; the loop is thinner)

@export var decay_tuning: CabinetDecayTuning
var id := &""
var detune_cents := 0.0
var _slowmo := 1.0
var _player: AudioStreamPlayer


func _ready() -> void:
	if decay_tuning == null:
		decay_tuning = load("res://data/cabinet/cabinet_decay.tres") as CabinetDecayTuning
	_player = AudioStreamPlayer.new()
	_player.bus = &"BUS-MUS" if AudioServer.get_bus_index(&"BUS-MUS") >= 0 else &"Master"
	_player.volume_db = LEVEL_DB
	add_child(_player)


## Start `music` (a chirp loop id; &"" stops) at W0-11 wear `level`. The same id keeps playing, retuned.
func play_stage(music: StringName, level: int) -> void:
	detune_cents = decay_tuning.wear_detune_cents_per_level * float(level)
	if music == &"":
		stop()
		return
	_apply_pitch()
	if music == id and _player.playing:
		return
	id = music
	if AudioService.muted_for_tests:
		return
	var s := AudioService.chirp_stream(music)
	if s == null:
		return
	_player.stream = s
	_player.play()


func stop() -> void:
	id = &""
	if _player != null and _player.playing:
		_player.stop()


func set_slowmo(scale: float) -> void:
	_slowmo = scale
	_apply_pitch()


## The pitch scale the loop plays at (wear detune × slow motion), for tests.
func pitch_scale() -> float:
	return CabinetDecayTuning.cents_to_pitch(detune_cents) * _slowmo


func _apply_pitch() -> void:
	if _player != null:
		_player.pitch_scale = maxf(pitch_scale(), 0.05)


## Release the loop at teardown (see CabinetHum._exit_tree; TECH-001 Q-T79).
func _exit_tree() -> void:
	var was := _player != null and _player.playing
	if _player != null:
		_player.stop()
		_player.stream = null
	if was:
		OS.delay_msec(AudioService.SHUTDOWN_DRAIN_MS)
