extends Node
## SettingsService (autoload) — why global: text scale and accessibility must be applied before
## the first frame and stay valid across every scene. TECH-001 §2.8.
## Persists to user://settings.cfg (device-level, ruling R-05). Keys are invariant IDs, never
## display text. Accessibility settings must never lie (WARP-001 §4.7).
## Language: English only for now (L10N-001 §1); there is no language setting.

signal setting_changed(key: StringName, value: Variant)

const PATH := "user://settings.cfg"
const SECTION := "settings"

## The game ships in English only (L10N-001 §1). Adding a language later: L10N-001 §7.
const FALLBACK_LOCALE := "en"

const DEFAULTS := {
	&"text_scale": 1.0,            # 1.0 or 2.0 (GDD §10: 200 % text scaling)
	&"reduced_motion": false,
	&"photosensitivity": false,    # kills flicker/strobe; never hides information (GDD §10)
	&"steady_ledger": true,        # WARP-001 §4.4: ships ON
	&"muzzle_flash": true,         # S4 owner ruling 2026-11-18: ships ON; the player may turn it off
}

var _values: Dictionary = {}
var persist: bool = true   # tests turn this off
var settings_path: String = PATH   # tests point this at a temp file


func _ready() -> void:
	settings_path = TestMode.settings_path()
	load_settings()


func load_settings() -> void:
	_values = DEFAULTS.duplicate()
	if persist:
		var cfg := ConfigFile.new()
		if cfg.load(settings_path) == OK:
			for key in DEFAULTS:
				var v: Variant = cfg.get_value(SECTION, String(key), DEFAULTS[key])
				if typeof(v) == typeof(DEFAULTS[key]):
					_values[key] = v
	_apply_locale()
	UiTheme.apply_text_scale(float(_values[&"text_scale"]))


func get_value(key: StringName) -> Variant:
	return _values.get(key, DEFAULTS.get(key))


func set_value(key: StringName, value: Variant) -> void:
	if not DEFAULTS.has(key):
		push_warning("SettingsService: unknown key %s" % key)
		return
	if typeof(value) != typeof(DEFAULTS[key]):
		push_warning("SettingsService: wrong type for %s" % key)
		return
	if key == &"text_scale":
		value = clampf(value, 1.0, 2.0)
	if _values.get(key) == value:
		return
	_values[key] = value
	if key == &"text_scale":
		UiTheme.apply_text_scale(value)
	_save()
	setting_changed.emit(key, value)


func reset_to_defaults() -> void:
	for key in DEFAULTS:
		set_value(key, DEFAULTS[key])


func _apply_locale() -> void:
	TranslationServer.set_locale(FALLBACK_LOCALE)


func _save() -> void:
	if not persist:
		return
	var cfg := ConfigFile.new()
	for key in _values:
		cfg.set_value(SECTION, String(key), _values[key])
	if not TestMode.allow_write(settings_path):
		return
	DirAccess.make_dir_recursive_absolute(settings_path.get_base_dir())
	var err := cfg.save(settings_path)
	if err != OK:
		push_warning("SettingsService: could not write settings (%d)" % err)
