extends Node
## SettingsService (autoload) — why global: language, text scale and accessibility must be
## applied before the first frame and stay valid across every scene. TECH-001 §2.8.
## Persists to user://settings.cfg (device-level). Keys are invariant IDs, never display text.
## OPEN (TECH-001 §11): LOOP-001 §2 puts accessibility in the profile slot; WARP-001 §4.4 says
## "save-scoped". Until the owner rules, accessibility lives here and must never lie (WARP-001 §4.7).

signal setting_changed(key: StringName, value: Variant)

const PATH := "user://settings.cfg"
const SECTION := "settings"

## Launch locale set (L10N-001). Add a locale here only after its .po passes validation.
const SUPPORTED_LOCALES := ["en"]
const FALLBACK_LOCALE := "en"

const DEFAULTS := {
	&"locale": "",                 # "" = follow OS if supported, else fallback
	&"text_scale": 1.0,            # 1.0 or 2.0 (GDD §10: 200 % text scaling)
	&"reduced_motion": false,
	&"photosensitivity": false,    # kills flicker/strobe; never hides information (GDD §10)
	&"steady_ledger": true,        # WARP-001 §4.4: ships ON
}

var _values: Dictionary = {}
var persist: bool = true   # tests turn this off


func _ready() -> void:
	load_settings()


func load_settings() -> void:
	_values = DEFAULTS.duplicate()
	if persist:
		var cfg := ConfigFile.new()
		if cfg.load(PATH) == OK:
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
	if key == &"locale":
		_apply_locale()
	elif key == &"text_scale":
		UiTheme.apply_text_scale(value)
	_save()
	setting_changed.emit(key, value)


func reset_to_defaults() -> void:
	for key in DEFAULTS:
		set_value(key, DEFAULTS[key])


## The locale actually in use after fallback.
func resolve_locale(requested: String) -> String:
	if requested == "":
		requested = OS.get_locale_language()
	if SUPPORTED_LOCALES.has(requested):
		return requested
	var lang := requested.split("_")[0]
	if SUPPORTED_LOCALES.has(lang):
		return lang
	return FALLBACK_LOCALE


func _apply_locale() -> void:
	TranslationServer.set_locale(resolve_locale(str(_values.get(&"locale", ""))))


func _save() -> void:
	if not persist:
		return
	var cfg := ConfigFile.new()
	for key in _values:
		cfg.set_value(SECTION, String(key), _values[key])
	var err := cfg.save(PATH)
	if err != OK:
		push_warning("SettingsService: could not write settings (%d)" % err)
