class_name CabinetDecayAudio
extends Node
## The Cabinet's own sound failing during the Decay (AUDIO-001 §12.18): the attract shell (lead + bass) sags
## flat and loses its voices, the 50 Hz cabinet hum sags and beats against itself, bulbs tick as they die,
## and the tube whines off. Everything is synthesised here at runtime (D-14; it must morph continuously), on
## its own players, so AudioService.silence() never cuts it by accident. No sting, no riser, no hit (§1.4).

const RATE := 22050
const LEAD_NOTES: Array[float] = [440.0, 659.26, 440.0, 554.37, 659.26, 880.0, 659.26, 554.37]   ## ✱ the litany's rhythm, major fifth
const BASS_NOTES: Array[float] = [110.0, 110.0, 164.81, 110.0]                                      ## ✱ quarter notes
const LOOP_S := 2.0                    ## ✱ 8 bars would be 16 s; one 2 s cell loops (120 BPM eighths)
const BEAT_DETUNE := 0.008             ## ✱ the hum's second partial runs this much sharp: a slow beat

var tuning: CabinetDecayTuning
var _lead: AudioStreamPlayer
var _bass: AudioStreamPlayer
var _hum: AudioStreamPlayer
var _hum_beat: AudioStreamPlayer
var _fx: AudioStreamPlayer
var _tick: AudioStreamWAV
var _crt_off: AudioStreamWAV
var _on := false


func _ready() -> void:
	_lead = _player(&"BUS-MUS", _loop(_notes(LEAD_NOTES, 0.25, 0.25, 0.22)))
	_bass = _player(&"BUS-MUS", _loop(_notes(BASS_NOTES, 0.5, 0.5, 0.28)))
	var hum := _loop(_hum_pcm())
	_hum = _player(&"BUS-AMB", hum)
	_hum_beat = _player(&"BUS-AMB", hum)
	_fx = _player(&"BUS-FLY", null)
	_tick = SfxSynth.tone(SfxSynth.Wave.NOISE, 4000.0, 2500.0, 0.03, 0.12)
	_crt_off = SfxSynth.tone(SfxSynth.Wave.SINE, 9000.0, 700.0, 0.6, 0.06, 0.02)


func _player(bus: StringName, stream: AudioStream) -> AudioStreamPlayer:
	var p := AudioStreamPlayer.new()
	p.bus = bus if AudioServer.get_bus_index(bus) >= 0 else &"Master"
	p.stream = stream
	add_child(p)
	return p


## Start the shell and the hum (D1). Nothing plays while AudioService is muted for tests.
func start() -> void:
	if AudioService.muted_for_tests or tuning == null:
		return
	_on = true
	_lead.volume_db = tuning.shell_db
	_bass.volume_db = tuning.shell_db - 3.0
	_hum.volume_db = tuning.hum_db
	_hum_beat.volume_db = -80.0
	_lead.play()
	_bass.play()
	_hum.play()
	_hum_beat.play()


## Shape the sound for decay time `t` (pure function of t: seeking is safe).
func apply(t: float) -> void:
	if not _on:
		return
	var m := tuning.marks()
	var sag_k := clampf((t - m[1]) / (m[3] - m[1]), 0.0, 1.0)   # across D2–D3
	var pitch := CabinetDecayTuning.cents_to_pitch(tuning.shell_detune_cents_end * sag_k)
	_lead.pitch_scale = pitch
	_bass.pitch_scale = pitch
	var hz := lerpf(tuning.hum_hz_start, tuning.hum_hz_end, sag_k)
	_hum.pitch_scale = hz / tuning.hum_hz_start
	_hum_beat.pitch_scale = _hum.pitch_scale * (1.0 + BEAT_DETUNE)
	_hum_beat.volume_db = lerpf(-60.0, tuning.hum_db - 4.0, tuning.phosphor_k(t))
	# the cursed turn: the hum breathes (TECH-001 Q-T265) — a slow swell and fall, like a transformer drawing breath
	var b := breath_db(tuning, t)
	_hum.volume_db = tuning.hum_db + b
	_hum_beat.volume_db += b
	var sk := tuning.skin_k(t)
	# the melody goes first, then the harmony; the bass keeps a bar that never resolves, then stops
	_lead.volume_db = lerpf(tuning.shell_db, -60.0, clampf(sk / 0.4, 0.0, 1.0))
	_bass.volume_db = lerpf(tuning.shell_db - 3.0, -60.0, clampf((sk - 0.6) / 0.4, 0.0, 1.0))
	if t >= m[3]:
		_stop_loops()


## dB added to the hum at decay time `t`: 0 outside D2–D3; inside, in-breaths of `breath_db` at `breath_hz`,
## the first one starting at D2 (a smooth sin² swell: no onset, §1.4).
static func breath_db(tun: CabinetDecayTuning, t: float) -> float:
	var m := tun.marks()
	if t < m[1] or t >= m[3]:
		return 0.0
	var s := sin(PI * tun.breath_hz * (t - m[1]))
	return tun.breath_db * s * s


func bulb_tick() -> void:
	if _on:
		_fx.stream = _tick
		_fx.play()


func crt_off() -> void:
	if _on:
		_fx.stream = _crt_off
		_fx.play()


func stop() -> void:
	_stop_loops()
	if _fx != null:
		_fx.stop()
	_on = false


func _stop_loops() -> void:
	for p: AudioStreamPlayer in [_lead, _bass, _hum, _hum_beat]:
		if p != null and p.playing:
			p.stop()


## Square-wave notes, `step` s apart, `dur` s each, with a short click-free envelope.
static func _notes(freqs: Array[float], step: float, dur: float, vol: float) -> PackedByteArray:
	var n := int(LOOP_S * RATE)
	var data := PackedByteArray()
	data.resize(n * 2)
	for i in n:
		var t := float(i) / RATE
		var idx := int(t / step) % freqs.size()
		var lt := fmod(t, step)
		var env := minf(1.0, lt / 0.004) * minf(1.0, maxf(0.0, dur - lt) / 0.02) * (1.0 - 0.5 * lt / dur)
		var ph := fmod(lt * freqs[idx], 1.0)
		var s := (1.0 if ph < 0.25 else -1.0) * env * vol
		data.encode_s16(i * 2, int(clampf(s, -1.0, 1.0) * 32767.0))
	return data


## One second of mains hum: 50 Hz with its second and third harmonics (whole cycles: loops clean).
func _hum_pcm() -> PackedByteArray:
	var n := RATE
	var data := PackedByteArray()
	data.resize(n * 2)
	var f := tuning.hum_hz_start if tuning != null else 50.0
	for i in n:
		var t := float(i) / RATE
		var s := 0.5 * sin(TAU * f * t) + 0.3 * sin(TAU * 2.0 * f * t) + 0.12 * sin(TAU * 3.0 * f * t)
		data.encode_s16(i * 2, int(clampf(s * 0.5, -1.0, 1.0) * 32767.0))
	return data


static func _loop(data: PackedByteArray) -> AudioStreamWAV:
	var w := AudioStreamWAV.new()
	w.format = AudioStreamWAV.FORMAT_16_BITS
	w.mix_rate = RATE
	w.stereo = false
	w.data = data
	w.loop_mode = AudioStreamWAV.LOOP_FORWARD
	w.loop_begin = 0
	w.loop_end = data.size() >> 1
	return w
