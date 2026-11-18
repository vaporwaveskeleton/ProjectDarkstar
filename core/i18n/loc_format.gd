class_name LocFormat
extends RefCounted
## Locale-aware formatting for numbers shown to players. Godot has no ICU, so rules live here.
## Internal values (saves, telemetry, seeds) always use invariant formatting, never these.

## Digit-group separator per language. Add a row when a locale is added (L10N-001 §5).
const GROUP_SEPARATORS := {
	"en": ",", "de": ".", "fr": " ", "es": ".", "pt": ".", "zh": ",", "ja": ",",
}
const DECIMAL_SEPARATORS := {
	"en": ".", "de": ",", "fr": ",", "es": ",", "pt": ",", "zh": ".", "ja": ".",
}


static func _lang(locale: String) -> String:
	if locale == "":
		locale = TranslationServer.get_locale()
	return locale.split("_")[0].split("-")[0]


static func format_int(value: int, locale: String = "") -> String:
	var sep: String = GROUP_SEPARATORS.get(_lang(locale), ",")
	var digits := str(absi(value))
	var out := ""
	var count := 0
	for i in range(digits.length() - 1, -1, -1):
		out = digits[i] + out
		count += 1
		if count % 3 == 0 and i > 0:
			out = sep + out
	return ("-" if value < 0 else "") + out


static func format_decimal(value: float, places: int, locale: String = "") -> String:
	var lang := _lang(locale)
	var fixed := ("%." + str(places) + "f") % absf(value)
	var parts := fixed.split(".")
	var whole := format_int(int(parts[0]), lang)
	var s := whole if places == 0 else whole + str(DECIMAL_SEPARATORS.get(lang, ".")) + parts[1]
	return ("-" if value < 0.0 and fixed.to_float() != 0.0 else "") + s


## Plural-aware translation with a {count} placeholder (gettext plural forms from the .po header).
static func tr_count(key: String, count: int, locale: String = "") -> String:
	var text := TranslationServer.translate_plural(key, key + "_PLURAL", count)
	return text.replace("{count}", format_int(count, locale))
