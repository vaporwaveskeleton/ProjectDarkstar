class_name CabinetHum
extends Node
## The Cabinet's mains hum (AUDIO-001 §2.1 "extra" row, §12.19; TECH-001 Q-T255, Q-T264): the chirp render
## `cabinet_hum` on its own quiet player under attract and the shift, so the machine is never quite silent.
## W0-11 Wear adds a faint second partial a hair sharp, so the hum starts to beat as the machine ages.
## W0-12 `breath`: once, the hum swells and falls like a transformer drawing breath (`haunt_breath` under it).
## Costume sound only: no readout, no timing. Not started while AudioService is muted for tests.

const ID := &"cabinet_hum"
const BEAT_DETUNE := 1.008            ## ✱ the Wear partial runs this much sharp: a slow beat (≈ 0.4 Hz at 50 Hz)

@export var tuning: CabinetHauntTuning
var base_db := -30.0                  ## ✱ AUDIO-001 §2.1: under everything, felt more than heard
var wear_level := 0
var _hum: AudioStreamPlayer
var _beat: AudioStreamPlayer
var _breath_t := -1.0                 ## s into the current breath; < 0 = none


func _ready() -> void:
	if tuning == null:
		tuning = load("res://data/cabinet/cabinet_haunt.tres") as CabinetHauntTuning
	var stream := AudioService.chirp_stream(ID)
	_hum = _player(stream)
	_beat = _player(stream)
	_beat.pitch_scale = BEAT_DETUNE


func _player(stream: AudioStream) -> AudioStreamPlayer:
	var p := AudioStreamPlayer.new()
	p.bus = &"BUS-AMB" if AudioServer.get_bus_index(&"BUS-AMB") >= 0 else &"Master"
	p.stream = stream
	add_child(p)
	return p


func start() -> void:
	if AudioService.muted_for_tests or _hum == null or _hum.stream == null:
		return
	if not _hum.playing:
		_hum.play()
		_beat.play()
	_apply()


func stop() -> void:
	for p: AudioStreamPlayer in [_hum, _beat]:
		if p != null and p.playing:
			p.stop()
	_breath_t = -1.0


## W0-11: the beating partial for wear `level` (0 = none).
func set_wear(level: int) -> void:
	wear_level = maxi(level, 0)
	_apply()


## W0-12 breath: one swell and fall of the hum, with the transformer's breath under it.
func breathe() -> void:
	_breath_t = 0.0
	AudioService.play(&"haunt_breath")


func is_breathing() -> bool:
	return _breath_t >= 0.0


## The dB the hum sits at right now (base + breath), for tests.
func level_db() -> float:
	return base_db + (tuning.breath_gain_db(_breath_t) if _breath_t >= 0.0 else 0.0)


func _process(delta: float) -> void:
	if _breath_t >= 0.0:
		_breath_t += delta
		if _breath_t >= tuning.breath_s:
			_breath_t = -1.0
		_apply()


func _apply() -> void:
	if _hum == null:
		return
	_hum.volume_db = level_db()
	_beat.volume_db = -80.0 if wear_level <= 0 else level_db() - 14.0 + 2.0 * float(wear_level)
