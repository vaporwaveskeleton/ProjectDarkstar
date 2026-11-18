class_name LocFormat
extends RefCounted
## Formatting for numbers shown to players. English only for now (L10N-001 §1): other languages
## are deferred, so there are no per-locale tables. When a language is added, its rules go here.
## Internal values (saves, telemetry, seeds) always use invariant formatting, never these.

const GROUP_SEPARATOR := ","
const DECIMAL_SEPARATOR := "."


static func format_int(value: int) -> String:
	var digits := str(absi(value))
	var out := ""
	var count := 0
	for i in range(digits.length() - 1, -1, -1):
		out = digits[i] + out
		count += 1
		if count % 3 == 0 and i > 0:
			out = GROUP_SEPARATOR + out
	return ("-" if value < 0 else "") + out


static func format_decimal(value: float, places: int) -> String:
	var fixed := ("%." + str(places) + "f") % absf(value)
	var parts := fixed.split(".")
	var whole := format_int(int(parts[0]))
	var s := whole if places == 0 else whole + DECIMAL_SEPARATOR + parts[1]
	return ("-" if value < 0.0 and fixed.to_float() != 0.0 else "") + s


## Plural-aware text with a {count} placeholder (gettext plural forms from the .po header).
static func tr_count(key: String, count: int) -> String:
	var text := TranslationServer.translate_plural(key, key + "_PLURAL", count)
	return text.replace("{count}", format_int(count))
