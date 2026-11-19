extends GdUnitTestSuite
## BrassHud (TECH-001 §5.4): honest values, hull line only past one hit (D-08), and the Hourglass
## (Q-T210) at its WARP-001 §4.1 home anchor, shown under Steady Ledger or past the show threshold.


func _hud() -> BrassHud:
	var h := BrassHud.new()
	h.size = Vector2(640, 360)
	add_child(h)
	auto_free(h)
	return h


func test_values_and_redraw_only_on_change() -> void:
	var h := _hud()
	assert_bool(h.set_values(800, 3, 5, 1, 5, 1, 1, 1, false)).is_true()
	assert_bool(h.set_values(800, 3, 5, 1, 5, 1, 1, 1, false)).is_false()
	assert_int(h.charges).is_equal(3)
	assert_bool(h.hull_label.visible).is_false()   # one-hit hull: no hull line


func test_hull_line_shows_past_one_hit_and_on_breach() -> void:
	var h := _hud()
	h.set_values(0, 0, 5, 1, 5, 1, 2, 3, false)
	assert_bool(h.hull_label.visible).is_true()
	h.set_values(0, 0, 5, 1, 5, 1, 0, 1, true)
	assert_str(h.hull_label.text).is_equal("Hull breached")


func test_hourglass_shows_under_steady_ledger_and_tracks_the_budget() -> void:
	var h := _hud()
	var was: Variant = SettingsService.get_value(&"steady_ledger")
	SettingsService.set_value(&"steady_ledger", true)
	assert_bool(h.set_hourglass(0.75, false)).is_true()
	assert_bool(h.hourglass_shown).is_true()
	assert_float(h.hourglass_frac).is_equal_approx(0.75, 0.001)
	assert_bool(h.set_hourglass(0.75, false)).is_false()
	SettingsService.set_value(&"steady_ledger", false)
	h.set_hourglass(0.75, false)
	assert_bool(h.hourglass_shown).is_false()            # default HUD: hidden above the threshold
	h.set_hourglass(0.1, true)
	assert_bool(h.hourglass_shown).is_true()             # past the SYS-001 §6 show threshold
	SettingsService.set_value(&"steady_ledger", was)


func test_handling_plate_hides_without_aether_handling() -> void:
	var h := _hud()
	assert_bool(h.handling_shown()).is_false()
	assert_bool(h.set_handling(0, 0, true)).is_false()
	assert_bool(h.get_node("SurgeLabel").visible).is_false()


func test_surgelight_pips_count_ready_and_max_and_redraw_only_on_change() -> void:
	var h := _hud()
	assert_bool(h.set_handling(1, 2, true)).is_true()
	assert_bool(h.handling_shown()).is_true()
	assert_int(h.surge_max).is_equal(2)
	assert_int(h.surge_ready).is_equal(1)   # lit = ready, the other pip recharging
	assert_bool(h.get_node("SurgeLabel").visible).is_true()
	assert_bool(h.set_handling(1, 2, true)).is_false()
	assert_bool(h.set_handling(2, 2, true)).is_true()
	h.set_handling(9, 2, true)   # never reads past the max
	assert_int(h.surge_ready).is_equal(2)
	var w2 := h.handling_rect().size.x
	h.set_handling(1, 3, true)
	assert_float(h.handling_rect().size.x).is_greater(w2)


func test_lantern_glyph_follows_the_state_and_the_plate_clears_the_seam_plate() -> void:
	var h := _hud()
	h.set_handling(1, 1, true)
	assert_bool(h.lantern_up).is_true()
	assert_bool(h.set_handling(1, 1, false)).is_true()
	assert_bool(h.lantern_up).is_false()
	assert_float(h.handling_rect().position.x).is_greater(h.seam_rect().end.x)
	var n := h.draw_count
	await get_tree().process_frame
	assert_int(h.draw_count).is_greater_equal(n)   # draws in both states
