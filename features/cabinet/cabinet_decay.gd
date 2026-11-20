class_name CabinetDecay
extends Node
## THE DECAY (GDD-001 §6.1 A0-5; WARP-001 W0-07; ART-001 §12.7b; AUDIO-001 §12.18; NARR-001 §4.5). After the
## last credits the machine goes back to attract and wears out, with no words: D1 back to attract, D2 tired
## phosphor, D3 the skin fails, D4 the picture collapses to a dot. Then `finished` and PretenceReveal opens
## the tear from the dot. Every value is CabinetDecayTuning (SYS-001 §9 `ds_cabinet.decay.*`).
##
## Rules this node keeps (tests: features/cabinet/tests/test_cabinet_decay.gd):
## - subtract, never write: the only text is the honour-roll page the player already knows, losing glyphs;
## - the costume only: the HUD strip is never touched; only registers 1–6 drift, one RGB332 step each;
## - no flicker: every value moves one way; photosensitivity / reduced motion use a fade, not a squeeze.
## `apply(t)` is a pure function of decay time t, so captures and tests can seek.

signal finished

const COLLAPSE_HOLD := 0.72            ## ✱ CRT `collapse` value where the dot is held (crt.gdshader: before its fade)

var tuning: CabinetDecayTuning
var messages: CabinetMessages
var crt: ShaderMaterial
var registers: VideoRegisters
var bezel: BezelDecay
var audio: CabinetDecayAudio
var still := false                      ## photosensitivity or reduced motion (ArcadeButton.is_still)
var play_top := 0.0                     ## UV y of the HUD strip's bottom: the Decay never wears above it (WARP-001 §4.2)

var t := 0.0
var running := false
var _base_regs: Dictionary = {}         ## reg -> its colour when the Decay began
var _glyph_total := 0
var _bulbs_ticked := 0
var _crt_off_done := false
var _silenced := false


## Wire the parts and start at D1. `hi` and `score` fill the honour roll (the page the machine shows in attract).
func begin(hi: int, score: int) -> void:
	t = 0.0
	running = true
	_bulbs_ticked = 0
	_crt_off_done = false
	_silenced = false
	_base_regs.clear()
	if registers != null:
		for r in tuning.drift_registers:
			_base_regs[r] = registers.read(r)
	if messages != null:
		messages.clear()
		messages.roll_page = true
		messages.roll_header = tr("CAB_HONOUR_ROLL")
		messages.roll_rows = PackedStringArray([
			"%s  %s" % [tr("CAB_HI"), LocFormat.format_int(maxi(hi, score))],
			"%s  %s" % [tr("CAB_ROLL_PLAYER"), LocFormat.format_int(score)],
		])
		messages.roll_glyphs_lost = 0
		messages.roll_bulbs_dead = 0.0
		_glyph_total = _count_glyphs(messages)
	if crt != null:
		crt.set_shader_parameter(&"collapse_fade", 1.0 if still else 0.0)
		crt.set_shader_parameter(&"play_top", play_top)
	if bezel != null:
		bezel.still = still
	if audio != null:
		audio.start()
	apply(0.0)
	set_process(true)


func _process(delta: float) -> void:
	if not running:
		return
	t += delta
	apply(t)
	if t >= tuning.total_s():
		running = false
		set_process(false)
		finished.emit()


## Everything the Decay shows and plays at decay time `t`.
func apply(at: float) -> void:
	var pk := tuning.phosphor_k(at)
	var sk := tuning.skin_k(at)
	var m := tuning.marks()
	# --- the screen (CRT pass: persistence, bleed, raster sag, collapse) ---
	if crt != null:
		crt.set_shader_parameter(&"ghost", tuning.persistence_max * pk)
		crt.set_shader_parameter(&"bleed", tuning.bloom_bleed_px_max * sk)
		crt.set_shader_parameter(&"sag", 0.0 if still else tuning.raster_shrink_max * sk)
		var ck := tuning.collapse_k(at)
		crt.set_shader_parameter(&"collapse", ck if still else ck * COLLAPSE_HOLD)
	# --- the registers: VOID and BONE only, one step each, round-robin ---
	if registers != null:
		var writes := drift_writes(at)
		var regs := tuning.drift_registers
		for i in regs.size():
			var r := regs[i]
			if not _base_regs.has(r):
				continue
			var base: Color = _base_regs[r]
			registers.write(r, CabinetDecay.drift_colour(base, r, tuning.register_drift_steps) if i < writes else base)
	# --- the honour-roll page ---
	if messages != null:
		messages.roll_blink_period = 0.0 if still else tuning.blink_period(at)
		messages.roll_glyphs_lost = glyphs_lost(at)
		messages.roll_bulbs_dead = bulbs_dead(at)
		messages.roll_page = at < m[3] + tuning.collapse_squeeze_s or still
	var dead := int(bulbs_dead(at))
	while _bulbs_ticked < dead:
		_bulbs_ticked += 1
		if audio != null:
			audio.bulb_tick()
	# --- the bezel ---
	if bezel != null:
		bezel.smear = pk
		bezel.bleach = tuning.print_bleach_max * sk
		bezel.light = tuning.worn_through_light_max * sk
		bezel.grow = sk
	# --- the sound ---
	if audio != null:
		audio.apply(at)
		if at >= m[3] and not _crt_off_done:
			_crt_off_done = true
			audio.crt_off()
	if at >= m[3] + tuning.collapse_squeeze_s and not _silenced:
		_silenced = true
		AudioService.silence(tuning.collapse_silence_s)


## How many drift writes have happened by `at` (D2 start + one per interval, at most one per register).
func drift_writes(at: float) -> int:
	var m := tuning.marks()
	if at < m[1]:
		return 0
	var n := 1 + int((at - m[1]) / tuning.register_drift_interval_s)
	return mini(n, tuning.drift_registers.size())


## Glyphs blanked by `at`: one per completed INSERT CREDIT blink across D2 (the blink slows), then the
## rest of the page across D3 so it is empty when the picture collapses. Photosensitivity: on a clock.
func glyphs_lost(at: float) -> int:
	var m := tuning.marks()
	if at < m[1]:
		return 0
	var d2 := minf(at, m[2]) - m[1]
	var blinks := 0.0
	if still:
		blinks = d2 / tuning.glyph_drop_still_interval_s
	else:
		var p0 := tuning.blink_period_start_s
		var p1 := tuning.blink_period_end_s
		var k := d2 / tuning.phosphor_s
		blinks = tuning.phosphor_s / (p1 - p0) * log((p0 + (p1 - p0) * k) / p0) if not is_equal_approx(p0, p1) else d2 / p0
	var lost := int(blinks) * tuning.glyph_drop_per_blink
	var rest := maxi(_glyph_total - lost, 0)
	return lost + int(ceilf(rest * tuning.skin_k(at)))


## Dark bulbs at `at` (D3 only), fractional while the next one dims out.
func bulbs_dead(at: float) -> float:
	var m := tuning.marks()
	if at < m[2]:
		return 0.0
	var x := minf(at, m[3]) - m[2]
	var whole := floorf(x / tuning.bulb_die_interval_s)
	var part := clampf((x - whole * tuning.bulb_die_interval_s) / tuning.bulb_dim_s, 0.0, 1.0)
	return whole + part


## Seek, for captures and tests.
func seek(at: float) -> void:
	t = at
	apply(at)


func stop() -> void:
	running = false
	set_process(false)
	if audio != null:
		audio.stop()
	if messages != null:
		messages.roll_page = false


## One RGB332 step on one channel (chosen by register number), toward the middle of the range so it
## never clips: a slip, not a new colour. Pure: same input, same output.
static func drift_colour(c: Color, reg: int, steps: int) -> Color:
	var q := ScreenRegisters.to_rgb332(c)
	var ch := reg % 3
	var levels := 3.0 if ch == 2 else 7.0
	var v := [q.r, q.g, q.b][ch] as float
	var lvl := roundf(v * levels)
	var dir := 1.0 if lvl < levels * 0.5 else -1.0
	lvl = clampf(lvl + dir * float(steps), 0.0, levels)
	var out := q
	match ch:
		0:
			out.r = lvl / levels
		1:
			out.g = lvl / levels
		_:
			out.b = lvl / levels
	return ScreenRegisters.to_rgb332(out)


static func _count_glyphs(msg: CabinetMessages) -> int:
	var n := 0
	var all := PackedStringArray([msg.roll_header])
	all.append_array(msg.roll_rows)
	all.append(msg.tr("CAB_CREDIT"))
	for s in all:
		n += s.replace(" ", "").length()
	return n
