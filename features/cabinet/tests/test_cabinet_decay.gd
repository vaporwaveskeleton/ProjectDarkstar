extends GdUnitTestSuite
## The Decay (GDD-001 §6.1 A0-5; WARP-001 W0-07, W0-11; ART-001 §12.7b; SYS-001 §9 ds_cabinet.decay.*):
## the numbers match SYS-001, it only subtracts (no new text), it only drifts registers 1–6 by one RGB332
## step, everything moves one way (no flicker), and the reveal has no title card and no entity line.

const TUNING := "res://data/cabinet/cabinet_decay.tres"


func _tuning() -> CabinetDecayTuning:
	return load(TUNING) as CabinetDecayTuning


func test_the_numbers_are_sys001s() -> void:
	var t := _tuning()
	assert_str(t.ds_namespace).is_equal("ds_cabinet.decay")
	assert_float(t.attract_s).is_equal(2.0)
	assert_float(t.phosphor_s).is_equal(4.0)
	assert_float(t.skin_s).is_equal(5.0)
	assert_float(t.collapse_s).is_equal(2.0)
	assert_float(t.total_s()).is_equal(13.0)
	assert_float(t.collapse_silence_s).is_equal(1.2)
	assert_float(t.persistence_max).is_equal(0.6)
	assert_float(t.bloom_bleed_px_max).is_equal(2.0)
	assert_float(t.raster_shrink_max).is_equal(0.15)
	assert_int(t.register_drift_steps).is_equal(1)
	assert_float(t.register_drift_interval_s).is_equal(0.8)
	assert_float(t.blink_period_end_s).is_equal(2.4)
	assert_int(t.glyph_drop_per_blink).is_equal(1)
	assert_float(t.bulb_die_interval_s).is_equal(0.06)
	assert_float(t.print_bleach_max).is_equal(0.7)
	assert_float(t.worn_through_light_max).is_equal(0.9)
	assert_float(t.shell_detune_cents_end).is_equal(-40.0)
	assert_float(t.hum_hz_end).is_equal(47.0)
	assert_float(t.ending5_line_hold_s).is_equal(4.0)
	assert_array(Array(t.wear_level_by_stage)).is_equal([1, 2, 3])
	assert_float(t.wear_detune_cents_per_level).is_equal(-2.0)
	assert_int(t.wear_dead_bulbs_per_level).is_equal(1)


func test_beats_are_in_order_and_end_at_the_tear() -> void:
	var t := _tuning()
	assert_int(t.beat_at(0.0)).is_equal(1)
	assert_int(t.beat_at(2.5)).is_equal(2)
	assert_int(t.beat_at(6.5)).is_equal(3)
	assert_int(t.beat_at(11.5)).is_equal(4)
	assert_int(t.beat_at(13.0)).is_equal(5)


func test_only_void_and_bone_registers_drift() -> void:
	# ART-001 §15.2a: 0 is black, 7–15 carry the role colours (CHOIR, PHOS, GAS, SIGNAL); they never move
	assert_array(Array(_tuning().drift_registers)).is_equal([1, 2, 3, 4, 5, 6])


func test_a_drift_is_one_rgb332_step_on_one_channel() -> void:
	var regs := load("res://data/cabinet/screen_registers.tres") as ScreenRegisters
	for r in range(1, 7):
		var base := ScreenRegisters.to_rgb332(regs.defaults[r])
		var d := CabinetDecay.drift_colour(base, r, 1)
		assert_object(d).is_equal(ScreenRegisters.to_rgb332(d))
		var steps := absf(roundf(d.r * 7.0) - roundf(base.r * 7.0)) + absf(roundf(d.g * 7.0) - roundf(base.g * 7.0)) \
			+ absf(roundf(d.b * 3.0) - roundf(base.b * 3.0))
		assert_float(steps).is_equal(1.0)


func test_the_decay_never_touches_black_or_role_registers() -> void:
	var vr := VideoRegisters.new()
	vr.spec = load("res://data/cabinet/screen_registers.tres") as ScreenRegisters
	add_child(vr)
	var before := PackedColorArray()
	for i in ScreenRegisters.REGISTER_COUNT:
		before.append(vr.read(i))
	var d := _decay()
	d.registers = vr
	d.begin(1000, 500)
	d.stop()
	var at := 0.0
	while at <= 13.0:
		d.apply(at)
		for i: int in [0, 7, 8, 9, 10, 11, 12, 13, 14, 15]:
			assert_object(vr.read(i)).is_equal(before[i])
		at += 0.25
	d.apply(13.0)
	var moved := 0
	for i in range(1, 7):
		if vr.read(i) != before[i]:
			moved += 1
	assert_int(moved).is_equal(6)
	vr.queue_free()
	d.free()


func test_erosion_only_subtracts_and_spares_the_players_row_until_last() -> void:
	var lines := PackedStringArray(["HONOUR ROLL", "HI  1,000", "PLAYER 1  500", "INSERT CREDIT"])
	var total := 0
	for s in lines:
		total += s.replace(" ", "").length()
	var prev := total
	for lost in range(0, total + 3):
		var out := CabinetMessages.erode(lines, lost, 9, 2)
		var left := 0
		for li in out.size():
			assert_int(out[li].length()).is_equal(lines[li].length())
			for ci in out[li].length():
				assert_bool(out[li][ci] == lines[li][ci] or out[li][ci] == " ").is_true()   # never a new glyph
			left += out[li].replace(" ", "").length()
		assert_int(left).is_equal(maxi(total - lost, 0))
		assert_int(left).is_less_equal(prev)
		prev = left
		var others := total - lines[2].replace(" ", "").length()
		if lost < others:
			assert_str(out[2]).is_equal(lines[2])   # the player's own row is the last to go


func test_glyphs_bulbs_and_skin_only_move_one_way() -> void:
	var d := _decay()
	d.begin(1000, 500)
	d.stop()
	var last_g := -1
	var last_b := -1.0
	var at := 0.0
	while at <= 13.0:
		var g := d.glyphs_lost(at)
		var b := d.bulbs_dead(at)
		assert_int(g).is_greater_equal(last_g)
		assert_float(b).is_greater_equal(last_b)
		last_g = g
		last_b = b
		at += 0.05
	assert_int(d.glyphs_lost(11.0)).is_greater_equal(d._glyph_total)   # the page is empty when the picture collapses
	assert_int(d.glyphs_lost(2.0)).is_equal(0)                          # D1 is the clean page
	d.free()


func test_the_decay_writes_no_new_text() -> void:
	var m := CabinetMessages.new()
	add_child(m)
	var d := _decay()
	d.messages = m
	d.begin(1000, 500)
	d.stop()
	var page := PackedStringArray([m.roll_header])
	page.append_array(m.roll_rows)
	var at := 0.0
	while at <= 13.0:
		d.apply(at)
		assert_str(m.roll_header).is_equal(page[0])        # the strings never change; only the mask grows
		assert_str(m.held_screen()).is_empty()
		at += 0.5
	m.queue_free()
	d.free()


func test_the_tear_to_the_hand_off_is_eight_seconds() -> void:
	# beat sheet: the tear 0:04 → the hand-off 0:12 (TECH-001 Q-T183 B)
	assert_float(PretenceReveal.tear_to_handoff_s()).is_equal_approx(8.0, 0.001)


func test_the_reveal_has_no_title_card_and_no_entity_line() -> void:
	var src := FileAccess.get_file_as_string("res://features/cabinet/pretence_reveal.gd")
	assert_bool(src.contains("entity_line(")).is_false()
	assert_bool(src.contains("REVEAL_ONE_SKY_LESS")).is_false()
	# the line exists only on the ending 5 path, after Theodora's screens
	var at_line := src.find("tr(\"REVEAL_PRETENCE\")")
	assert_int(at_line).is_greater(src.find("func _ending5"))


func test_wear_rises_per_stage_from_1_and_never_lights_the_print() -> void:
	var t := _tuning()
	assert_int(t.wear_level(0)).is_equal(1)
	assert_int(t.wear_level(1)).is_equal(2)
	assert_int(t.wear_level(2)).is_equal(3)
	assert_int(t.wear_level(3)).is_equal(0)   # past the roster: no wear
	assert_float(t.wear_bleach_per_level * 3.0).is_less(t.print_bleach_max)


func _decay() -> CabinetDecay:
	var d := CabinetDecay.new()
	d.tuning = _tuning()
	d.still = false
	return d
