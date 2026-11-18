extends Node
## AudioService (autoload) — why global: sound must survive scene changes and one owner must
## enforce the silence budget and the chant bed (AUDIO-001 §1.4, §5, §7). TECH-001 §2.8.
## Until recorded audio exists the cues are synthesised by SfxSynth (placeholders by design).
## Gameplay never decides mixing: it asks for a cue, the chant level, or a silence.

const VOICES := 24                     ## ✱ one-shot voice pool
const CHANT_MAX_DB := -14.0            ## ✱ chant bed level at full build

var _cues: Dictionary = {}             # StringName -> AudioStream
var _voices: Array[AudioStreamPlayer] = []
var _next := 0
var _chant: AudioStreamPlayer
var _chant_level := 0.0
var _silence := 0.0
var muted_for_tests := false


func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	_cues = SfxSynth.build_cabinet_set()
	for i in VOICES:
		var p := AudioStreamPlayer.new()
		p.bus = &"BUS-FLY"
		add_child(p)
		_voices.append(p)
	_chant = AudioStreamPlayer.new()
	_chant.bus = &"BUS-CHO"
	_chant.stream = SfxSynth.build_chant_loop()
	_chant.volume_db = -80.0
	add_child(_chant)


func play(id: StringName, volume_db: float = 0.0) -> void:
	if muted_for_tests or _silence > 0.0 or not _cues.has(id):
		return
	var p := _voices[_next]
	_next = (_next + 1) % _voices.size()
	p.stream = _cues[id]
	p.volume_db = volume_db - 6.0
	p.pitch_scale = 1.0
	p.play()


## Chant bed level 0..1 (AUDIO-001 §5). Positional loudness is folded in by the caller.
func set_chant(level: float) -> void:
	_chant_level = clampf(level, 0.0, 1.0)
	if _chant_level > 0.0 and not _chant.playing and not muted_for_tests:
		_chant.play()


## Total silence for `seconds`: every voice and the chant stop (the scare chord, GDD §12).
func silence(seconds: float) -> void:
	_silence = seconds
	for p in _voices:
		p.stop()


## Release every stream at shutdown so no playback outlives the engine (no leaks at exit).
func _exit_tree() -> void:
	for p in _voices:
		p.stop()
		p.stream = null
	_chant.stop()
	_chant.stream = null


func stop_all() -> void:
	for p in _voices:
		p.stop()
	_chant_level = 0.0
	_chant.stop()


func _process(delta: float) -> void:
	_silence = maxf(0.0, _silence - delta)
	var target := -80.0
	if _chant_level > 0.0 and _silence <= 0.0:
		target = lerpf(-40.0, CHANT_MAX_DB, _chant_level)
	_chant.volume_db = lerpf(_chant.volume_db, target, clampf(delta * 4.0, 0.0, 1.0))
	if _chant.volume_db < -79.0 and _chant.playing and _chant_level <= 0.0:
		_chant.stop()
