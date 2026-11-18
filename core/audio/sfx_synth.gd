class_name SfxSynth
extends RefCounted
## Builds the game's sounds as AudioStreamWAV in code — DARKSTAR ships no recorded audio
## (GDD-001 D-14, AUDIO-001 §11). These are the T0 arcade voices; the horror tiers sweep the same
## parameters (detune, formants, noise, bit depth) rather than swapping samples.
## Deterministic: the same recipe always produces the same samples.

const RATE := 22050

enum Wave { SQUARE, SAW, TRIANGLE, SINE, NOISE }


## A recipe: frequency sweeps from f0 to f1 over `dur` seconds with an attack/decay envelope.
static func tone(wave: Wave, f0: float, f1: float, dur: float, vol: float = 0.5,
		attack: float = 0.005, duty: float = 0.5, vibrato_hz: float = 0.0, vibrato_amt: float = 0.0,
		seed: int = 1) -> AudioStreamWAV:
	var n := int(dur * RATE)
	var data := PackedByteArray()
	data.resize(n * 2)
	var phase := 0.0
	var rng := RandomNumberGenerator.new()
	rng.seed = seed
	var noise_hold := 0.0
	var noise_phase := 0.0
	for i in n:
		var t := float(i) / RATE
		var k := t / dur
		var f := lerpf(f0, f1, k)
		if vibrato_hz > 0.0:
			f *= 1.0 + vibrato_amt * sin(TAU * vibrato_hz * t)
		phase = fmod(phase + f / RATE, 1.0)
		var s := 0.0
		match wave:
			Wave.SQUARE:
				s = 1.0 if phase < duty else -1.0
			Wave.SAW:
				s = phase * 2.0 - 1.0
			Wave.TRIANGLE:
				s = 1.0 - 4.0 * absf(phase - 0.5)
			Wave.SINE:
				s = sin(TAU * phase)
			Wave.NOISE:
				noise_phase += f / RATE
				if noise_phase >= 1.0:
					noise_phase -= 1.0
					noise_hold = rng.randf_range(-1.0, 1.0)
				s = noise_hold
		var env := minf(1.0, t / maxf(attack, 0.0001)) * pow(1.0 - k, 2.0)
		var v := int(clampf(s * env * vol, -1.0, 1.0) * 32767.0)
		data.encode_s16(i * 2, v)
	return _wav(data)


## Several recipes summed (each a Dictionary of tone() arguments), for chords and layered hits.
static func mix(parts: Array[AudioStreamWAV]) -> AudioStreamWAV:
	var n := 0
	for p in parts:
		n = maxi(n, p.data.size())
	var out := PackedByteArray()
	out.resize(n)
	for i in range(0, n, 2):
		var acc := 0
		for p in parts:
			if i < p.data.size():
				acc += p.data.decode_s16(i)
		out.encode_s16(i, clampi(acc, -32768, 32767))
	return _wav(out)


static func _wav(data: PackedByteArray) -> AudioStreamWAV:
	var w := AudioStreamWAV.new()
	w.format = AudioStreamWAV.FORMAT_16_BITS
	w.mix_rate = RATE
	w.stereo = false
	w.data = data
	return w


## The Cabinet's sound set. Keys are cue ids; AUDIO-001 §6.2 ids are noted where one exists.
static func build_cabinet_set() -> Dictionary:
	return {
		&"lance": tone(Wave.SQUARE, 1400.0, 520.0, 0.07, 0.22, 0.001, 0.25),
		&"geode_hit": tone(Wave.NOISE, 3200.0, 1800.0, 0.04, 0.25),
		&"geode_break": mix([tone(Wave.NOISE, 1800.0, 200.0, 0.45, 0.5, 0.001, 0.5, 0, 0, 7),
			tone(Wave.SQUARE, 180.0, 50.0, 0.35, 0.3)]),
		&"shard_chime": mix([tone(Wave.TRIANGLE, 1567.0, 1567.0, 0.18, 0.3),
			tone(Wave.TRIANGLE, 2349.0, 2349.0, 0.22, 0.18, 0.02)]),
		&"charge_fire": tone(Wave.SAW, 220.0, 880.0, 0.25, 0.35, 0.01),
		&"charge_lost": mix([tone(Wave.TRIANGLE, 2093.0, 1975.0, 0.6, 0.3, 0.001, 0.5, 6.0, 0.01),
			tone(Wave.TRIANGLE, 1396.0, 1318.0, 0.7, 0.2, 0.01)]),
		&"charge_hit": mix([tone(Wave.NOISE, 900.0, 60.0, 0.8, 0.6, 0.001, 0.5, 0, 0, 3),
			tone(Wave.SINE, 90.0, 30.0, 0.8, 0.7)]),
		&"segment_deposit": mix([tone(Wave.SINE, 70.0, 40.0, 0.35, 0.8), tone(Wave.NOISE, 400.0, 100.0, 0.12, 0.3, 0.001, 0.5, 0, 0, 11)]),
		&"segment_knocked": mix([tone(Wave.SQUARE, 330.0, 110.0, 0.3, 0.3), tone(Wave.NOISE, 2400.0, 300.0, 0.25, 0.35, 0.001, 0.5, 0, 0, 5)]),
		&"grub_keen": tone(Wave.SINE, 880.0, 620.0, 0.5, 0.18, 0.05, 0.5, 7.0, 0.04),
		&"grub_die": tone(Wave.SQUARE, 660.0, 120.0, 0.2, 0.25, 0.001, 0.3),
		&"acolyte_fire": tone(Wave.SQUARE, 300.0, 180.0, 0.12, 0.2, 0.001, 0.4),
		&"acolyte_die": mix([tone(Wave.NOISE, 1200.0, 100.0, 0.5, 0.5, 0.001, 0.5, 0, 0, 9), tone(Wave.SQUARE, 220.0, 55.0, 0.5, 0.3)]),
		&"vigil_die": mix([tone(Wave.NOISE, 2000.0, 40.0, 1.4, 0.7, 0.001, 0.5, 0, 0, 13),
			tone(Wave.SAW, 440.0, 30.0, 1.2, 0.35)]),
		&"extra_life": mix([tone(Wave.SQUARE, 523.0, 523.0, 0.1, 0.25), tone(Wave.SQUARE, 784.0, 784.0, 0.25, 0.25, 0.09)]),
		&"quota": mix([tone(Wave.SQUARE, 523.0, 523.0, 0.12, 0.22), tone(Wave.SQUARE, 659.0, 659.0, 0.24, 0.22, 0.1),
			tone(Wave.SQUARE, 1046.0, 1046.0, 0.5, 0.22, 0.22)]),
		&"wake_hit": mix([tone(Wave.SINE, 55.0, 22.0, 2.5, 0.95, 0.001), tone(Wave.NOISE, 300.0, 40.0, 2.0, 0.5, 0.001, 0.5, 0, 0, 21),
			tone(Wave.SAW, 110.0, 27.5, 2.2, 0.35, 0.001)]),
		&"entity_unmade": mix([tone(Wave.SINE, 40.0, 20.0, 3.5, 0.9), tone(Wave.NOISE, 3000.0, 20.0, 3.0, 0.6, 0.001, 0.5, 0, 0, 23),
			tone(Wave.TRIANGLE, 1046.0, 261.0, 3.0, 0.25, 0.3)]),
		&"menu_move": tone(Wave.SQUARE, 880.0, 880.0, 0.03, 0.12),
		&"menu_accept": tone(Wave.SQUARE, 660.0, 990.0, 0.08, 0.18),
	}


## A looping drone: the Choir's chant bed (AUDIO-001 §5) reduced to a held minor chord.
static func build_chant_loop() -> AudioStreamWAV:
	var dur := 4.0
	var parts: Array[AudioStreamWAV] = [
		tone(Wave.SAW, 73.42, 73.42, dur, 0.16, 0.5, 0.5, 0.25, 0.006),
		tone(Wave.TRIANGLE, 110.0, 110.0, dur, 0.16, 0.5, 0.5, 0.31, 0.008),
		tone(Wave.TRIANGLE, 130.81, 130.81, dur, 0.12, 0.5, 0.5, 0.19, 0.01),
		tone(Wave.SINE, 220.0, 220.0, dur, 0.10, 0.8, 0.5, 5.5, 0.02),
	]
	# a looping bed should not fade out: rebuild without the decay envelope
	var w := mix(parts)
	_flatten_tail(w)
	w.loop_mode = AudioStreamWAV.LOOP_FORWARD
	w.loop_begin = 0
	w.loop_end = int(dur * RATE)
	return w


## Sustain a sound to full level after its attack, so loops do not pulse.
static func _flatten_tail(w: AudioStreamWAV) -> void:
	var n := w.data.size() / 2
	var peak := 1
	for i in n:
		peak = maxi(peak, absi(w.data.decode_s16(i * 2)))
	# normalise each 1/20th window to the global peak to undo the decay curve
	var win := n / 20
	for b in 20:
		var local := 1
		for i in range(b * win, (b + 1) * win):
			local = maxi(local, absi(w.data.decode_s16(i * 2)))
		var g := minf(6.0, float(peak) / local)
		for i in range(b * win, (b + 1) * win):
			w.data.encode_s16(i * 2, clampi(int(w.data.decode_s16(i * 2) * g * 0.8), -32768, 32767))
