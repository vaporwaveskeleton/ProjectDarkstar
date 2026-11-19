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
