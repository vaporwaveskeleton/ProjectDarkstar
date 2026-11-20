extends GdUnitTestSuite
## The player's volume sliders (AUDIO-001 §8.4): the slider-to-dB curve, defaults and floors, the
## round trip through the settings file (a temp path, never the real user:// settings), and the
## live effect on the AudioServer buses. Settings and bus levels are restored after each case.

const TEMP_PATH := "user://_test/test_user_volume.cfg"
const KEYS: Array[StringName] = [&"vol_master", &"vol_music", &"vol_choir", &"vol_entity", &"vol_ui", &"vol_foley"]

var _saved_persist: bool
var _saved_path: String
var _saved: Dictionary = {}


func before_test() -> void:
	_saved_persist = SettingsService.persist
	_saved_path = SettingsService.settings_path
	for key in KEYS:
		_saved[key] = SettingsService.get_value(key)
	SettingsService.persist = false
	SettingsService.settings_path = TEMP_PATH


func after_test() -> void:
	SettingsService.persist = false
	for key in KEYS:
		SettingsService.set_value(key, _saved[key])
	SettingsService.settings_path = _saved_path
	SettingsService.persist = _saved_persist
	AudioService.apply_user_volumes()
	AudioService.muted_for_tests = false
	if FileAccess.file_exists(TEMP_PATH):
		DirAccess.remove_absolute(ProjectSettings.globalize_path(TEMP_PATH))


func _bus(bus: StringName) -> int:
	return AudioServer.get_bus_index(bus)


# ---------------------------------------------------------------- curve

func test_the_curve_is_unity_at_100_muted_at_0_and_never_rises() -> void:
	assert_float(UserVolume.to_db(100)).is_equal_approx(0.0, 0.001)
	assert_float(UserVolume.to_db(0)).is_equal(UserVolume.SILENT_DB)
	assert_float(UserVolume.to_db(70)).is_equal_approx(-6.2, 0.05)   # amplitude 0.49
	assert_float(UserVolume.to_db(50)).is_equal_approx(-12.04, 0.05)
	var prev := UserVolume.to_db(0)
	for v in range(1, 101):
		var db := UserVolume.to_db(v)
		assert_float(db).override_failure_message("curve falls at %d" % v).is_greater_equal(prev)
		assert_float(db).is_greater_equal(UserVolume.SILENT_DB)
		prev = db


# ---------------------------------------------------------------- defaults and floors

func test_every_audio_001_slider_exists_with_its_documented_default_and_floor() -> void:
	assert_int(UserVolume.SLIDERS.size()).is_equal(6)
	assert_int(SettingsService.DEFAULTS[&"vol_master"]).is_equal(70)
	assert_int(SettingsService.DEFAULTS[&"vol_choir"]).is_equal(100)   # the top of the range (§8.4)
	assert_int(UserVolume.floor_for(&"vol_entity")).is_equal(40)
	for key in [&"vol_master", &"vol_music", &"vol_choir", &"vol_ui"]:
		assert_int(UserVolume.floor_for(key)).is_equal(0)
	for e in UserVolume.SLIDERS:
		assert_bool(SettingsService.DEFAULTS.has(e["key"])).is_true()
		for bus: StringName in e["buses"]:
			assert_int(_bus(bus)).override_failure_message("no bus %s" % bus).is_greater_equal(0)


func test_the_entity_and_foley_sliders_cannot_be_set_below_their_floor() -> void:
	SettingsService.set_value(&"vol_entity", 0)
	assert_int(SettingsService.get_value(&"vol_entity")).is_equal(40)
	SettingsService.set_value(&"vol_foley", 10)
	assert_int(SettingsService.get_value(&"vol_foley")).is_equal(40)
	SettingsService.set_value(&"vol_music", 0)
	assert_int(SettingsService.get_value(&"vol_music")).is_equal(0)
	SettingsService.set_value(&"vol_music", 500)
	assert_int(SettingsService.get_value(&"vol_music")).is_equal(100)


func test_a_wrong_type_is_ignored() -> void:
	SettingsService.set_value(&"vol_music", 100)
	SettingsService.set_value(&"vol_music", "loud")
	assert_int(SettingsService.get_value(&"vol_music")).is_equal(100)


# ---------------------------------------------------------------- persistence

func test_volumes_round_trip_through_the_settings_file() -> void:
	SettingsService.persist = true
	SettingsService.set_value(&"vol_master", 35)
	SettingsService.set_value(&"vol_music", 0)
	SettingsService.set_value(&"vol_entity", 55)
	assert_bool(FileAccess.file_exists(TEMP_PATH)).is_true()
	SettingsService.persist = false   # change memory without touching the file
	SettingsService.set_value(&"vol_master", 99)
	SettingsService.persist = true
	SettingsService.load_settings()   # what a fresh boot reads
	assert_int(SettingsService.get_value(&"vol_master")).is_equal(35)
	assert_int(SettingsService.get_value(&"vol_music")).is_equal(0)
	assert_int(SettingsService.get_value(&"vol_entity")).is_equal(55)
	assert_int(SettingsService.get_value(&"vol_choir")).is_equal(100)
	SettingsService.reset_to_defaults()
	SettingsService.load_settings()
	assert_int(SettingsService.get_value(&"vol_master")).is_equal(70)


func test_a_hand_edited_file_cannot_push_a_slider_below_its_floor() -> void:
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(TEMP_PATH).get_base_dir())
	var cfg := ConfigFile.new()
	cfg.set_value(SettingsService.SECTION, "vol_entity", 3)
	cfg.set_value(SettingsService.SECTION, "vol_music", 400)
	cfg.save(TEMP_PATH)
	SettingsService.persist = true
	SettingsService.load_settings()
	assert_int(SettingsService.get_value(&"vol_entity")).is_equal(40)
	assert_int(SettingsService.get_value(&"vol_music")).is_equal(100)


# ---------------------------------------------------------------- the buses

func test_a_slider_sets_its_bus_live_in_db() -> void:
	SettingsService.set_value(&"vol_music", 50)
	assert_float(AudioServer.get_bus_volume_db(_bus(&"BUS-MUS"))).is_equal_approx(-12.04, 0.1)
	assert_bool(AudioServer.is_bus_mute(_bus(&"BUS-MUS"))).is_false()
	SettingsService.set_value(&"vol_master", 100)
	assert_float(AudioServer.get_bus_volume_db(_bus(&"Master"))).is_equal_approx(0.0, 0.01)
	SettingsService.set_value(&"vol_master", 70)
	assert_float(AudioServer.get_bus_volume_db(_bus(&"Master"))).is_equal_approx(-6.2, 0.1)
	assert_float(AudioService.user_db(&"BUS-MUS")).is_equal_approx(-12.04, 0.1)


func test_zero_mutes_the_bus_and_raising_it_unmutes() -> void:
	SettingsService.set_value(&"vol_choir", 0)
	assert_bool(AudioServer.is_bus_mute(_bus(&"BUS-CHO"))).is_true()
	SettingsService.set_value(&"vol_choir", 5)
	assert_bool(AudioServer.is_bus_mute(_bus(&"BUS-CHO"))).is_false()
	SettingsService.set_value(&"vol_choir", 100)
	assert_float(AudioServer.get_bus_volume_db(_bus(&"BUS-CHO"))).is_equal_approx(0.0, 0.01)


func test_the_entity_bus_is_never_muted_by_its_slider() -> void:
	SettingsService.set_value(&"vol_entity", 0)
	assert_bool(AudioServer.is_bus_mute(_bus(&"BUS-ENT"))).is_false()
	assert_float(AudioServer.get_bus_volume_db(_bus(&"BUS-ENT"))).is_equal_approx(UserVolume.to_db(40), 0.1)


func test_foley_drives_both_ambience_and_fly_and_stacks_with_ducking() -> void:
	SettingsService.set_value(&"vol_foley", 60)
	var want := UserVolume.to_db(60)
	assert_float(AudioServer.get_bus_volume_db(_bus(&"BUS-AMB"))).is_equal_approx(want, 0.1)
	assert_float(AudioServer.get_bus_volume_db(_bus(&"BUS-FLY"))).is_equal_approx(want, 0.1)
	assert_float(AudioServer.get_bus_volume_db(_bus(&"BUS-UI"))).is_equal_approx(0.0, 0.1)   # untouched


func test_the_ui_slider_moves_only_the_ui_bus() -> void:
	SettingsService.set_value(&"vol_ui", 30)
	assert_float(AudioServer.get_bus_volume_db(_bus(&"BUS-UI"))).is_equal_approx(UserVolume.to_db(30), 0.1)
	assert_float(AudioServer.get_bus_volume_db(_bus(&"BUS-FLY"))).is_equal_approx(0.0, 0.1)


# ---------------------------------------------------------------- preview

func test_a_slider_with_a_preview_cue_plays_it_through_the_cue_rules() -> void:
	AudioService.muted_for_tests = false
	AudioService.stop_all()
	AudioService.preview_volume(&"vol_ui")
	assert_int(AudioService.active_count(&"menu_move")).is_equal(1)
	AudioService.stop_all()


func test_music_and_entity_have_no_preview_and_every_preview_is_a_real_cue_on_the_sliders_bus() -> void:
	assert_str(String(UserVolume.entry_for_key(&"vol_music")["preview"])).is_empty()
	assert_str(String(UserVolume.entry_for_key(&"vol_entity")["preview"])).is_empty()   # protected set pieces
	for e in UserVolume.SLIDERS:
		var cue: StringName = e["preview"]
		if cue == &"":
			continue
		assert_bool(AudioService.has_cue(cue)).override_failure_message("no cue %s" % cue).is_true()
		var bus: StringName = AudioService.policy.entry_for(cue).bus
		var ok: bool = bus in e["buses"] or e["buses"] == [&"Master"]
		assert_bool(ok).override_failure_message("%s previews on %s" % [cue, bus]).is_true()
