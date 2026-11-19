extends GdUnitTestSuite
## The Weapon Muzzle Flash accessibility setting (S4 owner ruling 2026-11-18): ships ON, persists,
## and has a row in the settings screen on the focus ring. Never touches the real settings file.

const SCREEN := preload("res://scenes/settings/settings_screen.tscn")
const TEMP_PATH := "user://test_settings_muzzle_flash.cfg"

var _saved_persist: bool
var _saved_path: String
var _saved_values: Dictionary = {}


func before_test() -> void:
	_saved_persist = SettingsService.persist
	_saved_path = SettingsService.settings_path
	for key in SettingsService.DEFAULTS:
		_saved_values[key] = SettingsService.get_value(key)
	SettingsService.persist = false
	SettingsService.settings_path = TEMP_PATH


func after_test() -> void:
	SettingsService.persist = false
	for key in _saved_values:
		SettingsService.set_value(key, _saved_values[key])
	SettingsService.settings_path = _saved_path
	SettingsService.persist = _saved_persist
	if FileAccess.file_exists(TEMP_PATH):
		DirAccess.remove_absolute(ProjectSettings.globalize_path(TEMP_PATH))


func test_muzzle_flash_ships_on() -> void:
	assert_bool(SettingsService.DEFAULTS[&"muzzle_flash"]).is_true()


func test_muzzle_flash_round_trips_through_the_settings_file() -> void:
	SettingsService.persist = true
	SettingsService.set_value(&"muzzle_flash", false)
	assert_bool(FileAccess.file_exists(TEMP_PATH)).is_true()
	SettingsService.load_settings()
	assert_bool(SettingsService.get_value(&"muzzle_flash")).is_false()
	SettingsService.reset_to_defaults()
	SettingsService.load_settings()
	assert_bool(SettingsService.get_value(&"muzzle_flash")).is_true()


func test_wrong_type_is_ignored() -> void:
	SettingsService.set_value(&"muzzle_flash", "no")
	assert_bool(SettingsService.get_value(&"muzzle_flash")).is_true()


func _screen() -> Control:
	var s: Control = auto_free(SCREEN.instantiate())
	add_child(s)
	return s


func test_row_reflects_and_writes_the_setting() -> void:
	SettingsService.set_value(&"muzzle_flash", true)
	var s := _screen()
	var row: CheckButton = s.get_node("%MuzzleFlash")
	assert_bool(row.button_pressed).is_true()
	assert_str(row.text).is_equal("SETTINGS_MUZZLE_FLASH")
	row.button_pressed = false
	assert_bool(SettingsService.get_value(&"muzzle_flash")).is_false()
	SettingsService.set_value(&"muzzle_flash", true)
	s.refresh()
	assert_bool(row.button_pressed).is_true()


func test_row_has_text_and_tooltip_translations() -> void:
	assert_str(tr("SETTINGS_MUZZLE_FLASH")).is_equal("Weapon Muzzle Flash")
	assert_str(tr("SETTINGS_MUZZLE_FLASH_DESC")).is_not_equal("SETTINGS_MUZZLE_FLASH_DESC")
	var row: CheckButton = _screen().get_node("%MuzzleFlash")
	assert_str(row.tooltip_text).is_equal("SETTINGS_MUZZLE_FLASH_DESC")


func test_focus_neighbours_form_a_closed_wrapping_ring() -> void:
	var s := _screen()
	var ring: Array[String] = ["LargeText", "ReducedMotion", "Photosensitivity", "SteadyLedger", "MuzzleFlash", "Back"]
	for i in ring.size():
		var c: Control = s.get_node("%" + ring[i])
		var next: Control = s.get_node("%" + ring[(i + 1) % ring.size()])
		var prev: Control = s.get_node("%" + ring[(i - 1 + ring.size()) % ring.size()])
		assert_object(c.get_node(c.focus_neighbor_bottom)).is_same(next)
		assert_object(c.get_node(c.focus_neighbor_top)).is_same(prev)
	assert_str(s.default_focus.name).is_equal("Back")
	assert_bool(s.cancel_closes).is_true()
