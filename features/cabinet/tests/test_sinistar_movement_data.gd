extends GdUnitTestSuite
## Q-T444: the two movement literals the Sinistar movement pass moved into data keep their old values
## (no behaviour change), and they are real tunables (never code constants).


func test_movement_literals_are_data_with_unchanged_values() -> void:
	var t: CabinetTuning = load("res://data/cabinet/cabinet_tuning.tres")
	assert_float(t.entity_turn_rad_s).is_equal(2.2)
	assert_float(t.grub_ease_rate).is_equal(5.0)


func test_no_movement_literals_left_in_the_sims() -> void:
	var ritual := FileAccess.get_file_as_string("res://features/cabinet/sim/sepulchre_ritual.gd")
	var flock := FileAccess.get_file_as_string("res://features/cabinet/sim/grub_flock.gd")
	assert_bool(ritual.contains("ENTITY_TURN")).is_false()
	assert_bool(flock.contains("clampf(delta * 5.0, 0.0, 1.0)")).is_false()
