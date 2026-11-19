extends GdUnitTestSuite
## Guards: a test run must never touch the player's real user:// settings or saves.

const T := "user://_test"


func test_test_mode_is_active() -> void:
	assert_bool(TestMode.active()) \
		.override_failure_message("test mode is not active: a test run could touch real player files") \
		.is_true()


func test_every_door_is_redirected() -> void:
	assert_str(SettingsService.settings_path).starts_with(T)
	assert_str(TestMode.settings_path()).starts_with(T)
	assert_str(TestMode.saves_root()).starts_with(T)
	assert_str(FileSaveBackend.new().root).starts_with(T)
	assert_str(SettingsService.settings_path).is_not_equal(TestMode.REAL_SETTINGS)
	assert_str(TestMode.saves_root()).is_not_equal(TestMode.REAL_SAVES)
	if SaveService.backend is FileSaveBackend:
		assert_str((SaveService.backend as FileSaveBackend).root).starts_with(T)


func test_persisting_a_setting_stays_under_test_root() -> void:
	var prev_persist: bool = SettingsService.persist
	var prev_scale: float = float(SettingsService.get_value(&"text_scale"))
	SettingsService.persist = true
	SettingsService.set_value(&"text_scale", 2.0 if prev_scale < 2.0 else 1.0)
	assert_bool(FileAccess.file_exists(SettingsService.settings_path)).is_true()
	assert_str(SettingsService.settings_path).starts_with(T)
	assert_array(TestMode.blocked_writes).is_empty()
	SettingsService.set_value(&"text_scale", prev_scale)
	SettingsService.persist = prev_persist


func test_allow_write_refuses_real_paths_and_records_them() -> void:
	var before: int = TestMode.blocked_writes.size()
	assert_bool(TestMode.allow_write("user://settings.cfg")).is_false()
	assert_bool(TestMode.allow_write("user://saves/slot_a.json.bak")).is_false()
	assert_int(TestMode.blocked_writes.size()).is_equal(before + 2)
	assert_str(TestMode.blocked_writes[before]).is_equal("user://settings.cfg")
	TestMode.blocked_writes.clear()   # the deliberate probe must not trip the zz canary
	assert_bool(TestMode.allow_write("user://_test/settings.cfg")).is_true()
	assert_bool(TestMode.allow_write("user://_test/saves/a.json")).is_true()
	assert_array(TestMode.blocked_writes).is_empty()


func test_allow_write_is_open_outside_test_mode() -> void:
	TestMode.force(false)
	var ok: bool = TestMode.allow_write("user://settings.cfg")
	TestMode.force(true)
	assert_bool(ok).is_true()
	assert_array(TestMode.blocked_writes).is_empty()


func test_decide_truth_table() -> void:
	var gd := PackedStringArray(["-s", "addons/gdUnit4/bin/GdUnitCmdTool.gd"])
	var plain := PackedStringArray(["--smoke"])
	assert_bool(TestMode.decide(false, "1", gd)).is_false()
	assert_bool(TestMode.decide(false, "", plain)).is_false()
	assert_bool(TestMode.decide(true, "1", plain)).is_true()
	assert_bool(TestMode.decide(true, "", gd)).is_true()
	assert_bool(TestMode.decide(true, "", plain)).is_false()
	assert_bool(TestMode.decide(true, "0", plain)).is_false()
